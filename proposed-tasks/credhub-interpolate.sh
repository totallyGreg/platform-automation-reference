#!/bin/bash
cat /var/version && echo ""
set -euo pipefail

# NOTE: The credhub cli does not ignore empty/null environment variables.
# https://github.com/cloudfoundry-incubator/credhub-cli/issues/68
if [ -z "$CREDHUB_CA_CERT" ]; then
  unset CREDHUB_CA_CERT
fi

credhub --version

if [ -z "$PREFIX" ]; then
  echo "Please specify a PREFIX. It is required."
  exit 1
fi

# $INTERPOLATION_PATHS needs to be globbed to read multiple files
# shellcheck disable=SC2086
files=$(cd files && find $INTERPOLATION_PATHS -type f -name '*.yml' -follow)

for file in $files; do
  echo "interpolating files/$file"
  mkdir -p interpolated-files/"$(dirname "$file")"
  credhub interpolate --prefix "$PREFIX" \
  --file files/"$file" > interpolated-files/"$file"
done
