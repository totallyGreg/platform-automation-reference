#!/bin/bash
cat /var/version && echo ""
set -eux

expected_version=$(bosh int download-config/${DOWNLOAD_CONFIG_FILE} --path /product-version)
expected_product=$(bosh int config/${CONFIG_FILE} --path /product-name)

staged_products=$(mktemp)
om --env env/"${ENV_FILE}" staged-products -f json > ${staged_products}

set +e
staged_version=$(bosh int ${staged_products} --path /name=${expected_product}/version)
set -e

vars_files_args=("")
for vf in ${VARS_FILES}
do
  vars_files_args+=("--vars-file ${vf}")
done

if [ "${expected_version}" = "${staged_version}" ]; then
  echo "${expected_version} already staged"
else
  downloaded_files=$(mktemp -d)
  # shellcheck disable=SC2068
  om download-product \
     --config download-config/"${DOWNLOAD_CONFIG_FILE}" \
     --output-directory ${downloaded_files} \
     ${vars_files_args[@]}

  { printf "\nReading product details..."; } 2> /dev/null
  # shellcheck disable=SC2068
  product_slug=$(om interpolate \
     --config download-config/"${DOWNLOAD_CONFIG_FILE}" \
     --path /pivnet-product-slug ${vars_files_args[@]})

  product_file=$(om interpolate \
     --config ${downloaded_files}/download-file.json \
     --path /product_path)

  { printf "\nChecking if product needs winfs injected..."; } 2> /dev/null
  if [ "$product_slug" == "pas-windows" ]; then
     TILE_FILENAME="$(basename "$product_file")"

     # The winfs-injector determines the necessary windows image,
     # and uses the CF-foundation dockerhub repo
     # to pull the appropriate Microsoft-hosted foreign layer.
     winfs-injector \
     --input-tile "$product_file" \
     --output-tile "${downloaded_files}/${TILE_FILENAME}"
  fi

  om --env env/"${ENV_FILE}" upload-product \
     --product ${downloaded_files}/*.pivotal

  product_name="$(om tile-metadata \
     --product-path ${downloaded_files}/*.pivotal \
     --product-name)"

  product_version="$(om tile-metadata \
     --product-path ${downloaded_files}/*.pivotal \
     --product-version)"

  om --env env/"${ENV_FILE}" stage-product \
     --product-name "$product_name" \
     --product-version "$product_version"

  rm -rf ${downloaded_files}
fi

if [ -f "download-config/${DOWNLOAD_STEMCELL_CONFIG_FILE}" ]; then
  expected_stemcell_version=$(bosh int download-config/${DOWNLOAD_STEMCELL_CONFIG_FILE} --path /product-version)
  stemcell_assignments=$(mktemp)
  om --env env/"${ENV_FILE}" curl -p /api/v0/stemcell_assignments > ${stemcell_assignments}
  set +e
  bosh int ${stemcell_assignments} --path /stemcell_library/version=${expected_stemcell_version}
  rc=$?
  set -e
  if [ ${rc} -eq 0 ]; then
    echo "Expected stemcell version ${expected_stemcell_version} already installed"
  else
    downloaded_files=$(mktemp -d)

    om download-product \
       --config download-config/"${DOWNLOAD_STEMCELL_CONFIG_FILE}" \
       --output-directory ${downloaded_files} \
       ${vars_files_args[@]}

    om --env env/"${ENV_FILE}" upload-stemcell \
       --floating=false \
       --stemcell "${downloaded_files}"/*.tgz

    rm -rf ${downloaded_files}
  fi

  om --env env/"${ENV_FILE}" assign-stemcell --product ${expected_product} --stemcell ${expected_stemcell_version}
fi

