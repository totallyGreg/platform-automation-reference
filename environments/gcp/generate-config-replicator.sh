#!/bin/bash -e
: ${PIVNET_TOKEN?"Need to set PIVNET_TOKEN"}

INITIAL_FOUNDATION=sbx
if [ ! $# -eq 2 ]; then
  echo "Must supply product name and replicator name as arg"
  exit 1
fi

product=$1
replicator_name=$2
echo "Generating configuration for product $product"
versionfile="${INITIAL_FOUNDATION}/config/versions/$product.yml"
if [ ! -f ${versionfile} ]; then
  echo "Must create ${versionfile}"
  exit 1
fi
version=$(bosh interpolate ${versionfile} --path /product-version)
glob=$(bosh interpolate ${versionfile} --path /pivnet-file-glob)
slug=$(bosh interpolate ${versionfile} --path /pivnet-product-slug)

tmpdir=tile-configs/${product}-config
wrkdir=${tmpdir}/${version}
mkdir -p ${wrkdir}

tmpZipDir=$(mktemp -d)
if [ ! -f ${wrkdir}/replicator-darwin ]; then
  om download-product --output-directory ${tmpZipDir} --pivnet-api-token ${PIVNET_TOKEN} --pivnet-file-glob "replicator-*.zip" --pivnet-product-slug ${slug} --product-version ${version}
  unzip ${tmpZipDir}/*.zip -d ${wrkdir}
  chmod +x ${wrkdir}/replicator-darwin
fi

tmpPivotalFileDir=$(mktemp -d)
mkdir -p ${tmpPivotalFileDir}/metadata
tile-config-generator metadata pivnet --product-slug=${slug}  --product-version=${version}  --product-glob=${glob} --output-file=${tmpPivotalFileDir}/metadata/metadata.yml
pushd ${tmpPivotalFileDir}
  zip -r ${product}.pivotal *
popd

${wrkdir}/replicator-darwin --name ${replicator_name} --path ${tmpPivotalFileDir}/${product}.pivotal --output ${tmpPivotalFileDir}/${product}-${replicator_name}.pivotal
tile-config-generator generate --pivotal-file-path=${tmpPivotalFileDir}/${product}-${replicator_name}.pivotal \
  --base-directory=${wrkdir} --do-not-include-product-version --include-errands

if [ ! -f ${wrkdir}/product.yml ]; then
  echo "Something wrong with configuration as expecting ${wrkdir}/product.yml to exist"
  exit 1
fi

ops_files="${product}-operations"
touch ${ops_files}

ops_files_args=("")
while IFS= read -r var
do
  ops_files_args+=("-o ${wrkdir}/${var}")
done < "$ops_files"
bosh int ${wrkdir}/product.yml ${ops_files_args[@]} > ${INITIAL_FOUNDATION}/config/templates/${product}.yml

generated_product_name=$(bosh int ${INITIAL_FOUNDATION}/config/templates/${product}.yml --path /product-name)

mkdir -p ${INITIAL_FOUNDATION}/config/defaults
rm -rf ${INITIAL_FOUNDATION}/config/defaults/${product}.yml
touch ${INITIAL_FOUNDATION}/config/defaults/${product}.yml
if [ -f ${wrkdir}/product-default-vars.yml ]; then
  cat ${wrkdir}/product-default-vars.yml >> ${INITIAL_FOUNDATION}/config/defaults/${product}.yml
fi
if [ -f ${wrkdir}/errand-vars.yml ]; then
  cat ${wrkdir}/errand-vars.yml >> ${INITIAL_FOUNDATION}/config/defaults/${product}.yml
fi
if [ -f ${wrkdir}/resource-vars.yml ]; then
  cat ${wrkdir}/resource-vars.yml >> ${INITIAL_FOUNDATION}/config/defaults/${product}.yml
fi
