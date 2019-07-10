#!/bin/bash
cat /var/version && echo ""
set -eu

if [ -z "$NAME" ]; then
  echo "Must set NAME parameter"
  exit 1
fi

if [ ! -z "$OPSMAN_SSH_PRIVATE_KEY" ]; then
  ssh_key=$(mktemp)
  echo "${OPSMAN_SSH_PRIVATE_KEY}" > ${ssh_key}
  eval "$(om --env env/${ENV_FILE} bosh-env --ssh-private-key ${ssh_key})"
else
  eval "$(om --env env/${ENV_FILE} bosh-env)"
fi

bosh upload-release files/*.tgz

vars_files_args=("")
for vf in ${VARS_FILES}
do
  vars_files_args+=("--vars-file ${vf}")
done

bosh -n update-config --type runtime --name ${NAME} config/${CONFIG_FILE} ${vars_files_args[@]}

