#!/bin/bash -e
: ${PIVNET_TOKEN?"Need to set PIVNET_TOKEN"}

version=$(bosh interpolate ../config/versions/cf.yml --path /product-version)
glob=$(bosh interpolate ../config/versions/cf.yml --path /pivnet-file-glob)
slug=$(bosh interpolate ../config/versions/cf.yml --path /pivnet-product-slug)

tmpdir=cf-config
mkdir -p ${tmpdir}
om config-template --output-directory=${tmpdir} --pivnet-api-token ${PIVNET_TOKEN} --pivnet-product-slug  ${slug} --product-version ${version} --product-file-glob ${glob}
wrkdir=${tmpdir}/cf/${version}
bosh int ${wrkdir}/product.yml \
  -o ${wrkdir}/features/haproxy_forward_tls-disable.yml \
  -o ${wrkdir}/optional/add-control-static_ips.yml \
  -o ${wrkdir}/optional/add-router-static_ips.yml > ../config/templates/cf.yml

rm -rf ../config/defaults/cf.yml
touch ../config/defaults/cf.yml
cat ${wrkdir}/product-default-vars.yml >> ../config/defaults/cf.yml
cat ${wrkdir}/errand-vars.yml >> ../config/defaults/cf.yml
cat ${wrkdir}/resource-vars.yml >> ../config/defaults/cf.yml
