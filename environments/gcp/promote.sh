#!/bin/bash -e
if [ ! $# -eq 2 ]; then
  echo "Must supply environment source and target"
  exit 1
fi

environment_source=$1
environment_target=$2
echo "Promoting from ${environment_source} to ${environment_target}"

mkdir -p ${environment_target}/config-director/vars
mkdir -p ${environment_target}/config-director/secrets
mkdir -p ${environment_target}/config-director/versions
mkdir -p ${environment_target}/config-director/templates

mkdir -p ${environment_target}/config/defaults
mkdir -p ${environment_target}/config/vars
mkdir -p ${environment_target}/config/secrets
mkdir -p ${environment_target}/config/versions
mkdir -p ${environment_target}/config/templates


cp -r ${environment_source}/config-director/versions/* ${environment_target}/config-director/versions/.
cp -r ${environment_source}/config-director/templates/* ${environment_target}/config-director/templates/.
cp -r ${environment_source}/config-director/secrets/* ${environment_target}/config-director/secrets/.

cp -r ${environment_source}/pipeline.yml ${environment_target}/pipeline.yml
cp -r ${environment_source}/config/defaults/* ${environment_target}/config/defaults/.
cp -r ${environment_source}/config/versions/* ${environment_target}/config/versions/.
cp -r ${environment_source}/config/templates/* ${environment_target}/config/templates/.
cp -r ${environment_source}/config/secrets/* ${environment_target}/config/secrets/.

./validate-opsman-config.sh ${environment_target}

products=("cf" "p-healthwatch")

for product in ${products[@]}; do
  ./validate-config.sh ${product} ${environment_target}
done
