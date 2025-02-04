#!/bin/bash
cat /var/version && echo ""
set -eu

if [ ! -z "$OPSMAN_SSH_PRIVATE_KEY" ]; then
  ssh_key=$(mktemp)
  echo "${OPSMAN_SSH_PRIVATE_KEY}" > ${ssh_key}
  eval "$(om --env env/${ENV_FILE} bosh-env --ssh-private-key ${ssh_key})"
else
  eval "$(om --env env/${ENV_FILE} bosh-env)"
fi

product=$(bosh int config/${CONFIG_FILE} --path /product-name)
staged_products=$(mktemp)
om --env env/${ENV_FILE} curl -p /api/v0/staged/products  > ${staged_products}
installation=$(bosh int ${staged_products} --path /type=${product}/installation_name)

if [ -z "$INSTANCE" ]; then
  bosh -d ${installation} run-errand ${ERRAND_NAME}
else
  bosh -d ${installation} run-errand ${ERRAND_NAME} --instance ${INSTANCE}
fi
