#!/bin/bash
cat /var/version && echo ""
set -eux

product=$(bosh int config/${CONFIG_FILE} --path /product-name)
om --env env/"${ENV_FILE}" apply-changes --product-name ${product}

