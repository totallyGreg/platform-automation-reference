#!/bin/bash
cat /var/version && echo ""
set -eux

generated_state_path="generated-state/$(basename "$STATE_FILE")"
cp "state/$STATE_FILE" "$generated_state_path"

expected_version=$(bosh int download-config/${DOWNLOAD_CONFIG_FILE} --path /product-version)

staged_products=$(mktemp)
om --env env/"${ENV_FILE}" staged-products -f json > ${staged_products}

set +e
staged_version=$(bosh int ${staged_products} --path /name=p-bosh/version)
set -e

if [[ ${staged_version} == ${expected_version}* ]]; then
  echo "${expected_version} already installed"
  exit 0
else
  vars_files_args=("")
  for vf in ${VARS_FILES}
  do
    vars_files_args+=("--vars-file ${vf}")
  done

  downloaded_files=$(mktemp -d)
  # shellcheck disable=SC2068
  om download-product \
     --config download-config/"${DOWNLOAD_CONFIG_FILE}" \
     --output-directory ${downloaded_files} \
     ${vars_files_args[@]}

  export IMAGE_FILE
  IMAGE_FILE="$(find ${downloaded_files}/*.{yml,ova,raw} 2>/dev/null | head -n1)"

  if [ -z "$IMAGE_FILE" ]; then
    echo "No image file found in image input."
    echo "Contents of image input:"
    ls -al image
    exit 1
  fi

  # ${vars_files_args[@] needs to be globbed to split properly (SC2068)
  # INSTALLATION_FILE needs to be globbed (SC2086)
  # shellcheck disable=SC2068,SC2086
  p-automator upgrade-opsman \
    --config config/"${OPSMAN_CONFIG_FILE}" \
    --env-file env/"${ENV_FILE}" \
    --image-file "${IMAGE_FILE}"  \
    --state-file "$generated_state_path" \
    --installation installation/$INSTALLATION_FILE \
    ${vars_files_args[@]}

  rm -rf ${downloaded_files}
fi

