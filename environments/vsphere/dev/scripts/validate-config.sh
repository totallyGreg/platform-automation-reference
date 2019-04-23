#!/bin/bash -e
if [ $# -eq 0 ]; then
  echo "Must supply product name as arg"
  exit 1
fi

product=$1
echo "Validating configuration for product $product"

touch ../config/vars/${product}.yml
touch ../config/secret_templates/${product}.yml

bosh int --var-errs --var-errs-unused ../config/templates/${product}.yml --vars-file ../config/defaults/${product}.yml --vars-file ../config/vars/${product}.yml --vars-file ../config/secret_templates/${product}.yml
