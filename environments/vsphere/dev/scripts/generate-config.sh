#!/bin/bash -e
: ${PIVNET_TOKEN?"Need to set PIVNET_TOKEN"}

if [ $# -eq 0 ]; then
  echo "Must supply product name as arg"
  exit 1
fi

product=$1
echo "Generating configuration for product $product"
versionfile="../config/secrets/versions/$product.yml"
if [ ! -f ${versionfile} ]; then
  echo "Must create ${versionfile}"
  exit 1
fi
version=$(bosh interpolate ${versionfile} --path /product-version)
glob=$(bosh interpolate ${versionfile} --path /pivnet-file-glob)
slug=$(bosh interpolate ${versionfile} --path /pivnet-product-slug)

tmpdir=${product}-config
mkdir -p ${tmpdir}
om config-template --output-directory=${tmpdir} --pivnet-api-token ${PIVNET_TOKEN} --pivnet-product-slug  ${slug} --product-version ${version} --product-file-glob ${glob}
wrkdir=$(find ${tmpdir}/${product} -name "${version}*")
if [ ! -f ${wrkdir}/product.yml ]; then
  echo "Something wrong with configuration as expecting ${wrkdir}/product.yml to exist"
  exit 1
fi

ops_files="${product}-operations"
if [ -f ${ops_files} ]; then
  ops_files_args=("")
  while IFS= read -r var
  do
    ops_files_args+=("-o ${wrkdir}/${var}")
  done < "$ops_files"
  bosh int ${wrkdir}/product.yml ${ops_files_args[@]} > ../config/templates/${product}.yml
fi

rm -rf ../config/defaults/${product}.yml
touch ../config/defaults/${product}.yml
if [ -f ${wrkdir}/product-default-vars.yml ]; then
  cat ${wrkdir}/product-default-vars.yml >> ../config/defaults/${product}.yml
fi
if [ -f ${wrkdir}/errand-vars.yml ]; then
  cat ${wrkdir}/errand-vars.yml >> ../config/defaults/${product}.yml
fi
if [ -f ${wrkdir}/resource-vars.yml ]; then
  cat ${wrkdir}/resource-vars.yml >> ../config/defaults/${product}.yml
fi
