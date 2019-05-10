#!/bin/bash -e
if [ $# -eq 0 ]; then
  echo "Must supply product name as arg"
  exit 1
fi

product=$1
echo "Validating configuration for product $product"

touch ../environments/vsphere/dev/config/vars/${product}.yml
touch ../environments/vsphere/dev/config/secrets/${product}.yml

bosh int --var-errs --var-errs-unused ../environments/vsphere/dev/config/templates/${product}.yml --vars-file ../environments/vsphere/dev/config/defaults/${product}.yml --vars-file ../environments/vsphere/dev/config/vars/${product}.yml --vars-file ../environments/vsphere/dev/config/secrets/${product}.yml
