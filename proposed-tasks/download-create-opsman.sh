#/bin/bash
cat /var/version && echo ""
set -eux


generated_state_path="generated-state/$(basename "$STATE_FILE")"
if [ -e "state/$STATE_FILE" ]; then
  cp "state/$STATE_FILE" "$generated_state_path"
  if [ -s "state/$STATE_FILE" ]; then
    echo "state file has contents, assume vm has been created"
    exit 0
  fi
fi

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

# ${vars_files_args[@] needs to be globbed to split properly
# shellcheck disable=SC2068
p-automator create-vm \
--config config/"${OPSMAN_CONFIG_FILE}" \
--image-file "${IMAGE_FILE}"  \
--state-file "$generated_state_path" \
${vars_files_args[@]}
