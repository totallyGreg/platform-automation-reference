#!/bin/bash -e

if [ -z "$MINIO_ACCESS_KEY" ]; then
    echo "Must provide environment variable MINIO_ACCESS_KEY"
    exit 1
fi

if [ -z "$MINIO_SECRET_KEY" ]; then
    echo "Must provide environment variable MINIO_SECRET_KEY"
    exit 1
fi

mkdir -p ~/.config/rclone
cat << EOF > ~/.config/rclone/rclone.conf
[minio]
type = s3
provider = Minio
env_auth = false
access_key_id = ${MINIO_ACCESS_KEY}
secret_access_key = ${MINIO_SECRET_KEY}
region = us-east-1
endpoint = https://minio.haas-415.pez.pivotal.io:443
location_constraint =
server_side_encryption =
EOF

tmpdir=$(mktemp -d)
pushd ${tmpdir}
  mkdir -p vsphere/dev
  touch vsphere/dev/0-state.yml
  touch vsphere/dev/0-installation.zip
  rclone --no-check-certificate copy --progress . minio:state
popd

rm ~/.config/rclone/rclone.conf
