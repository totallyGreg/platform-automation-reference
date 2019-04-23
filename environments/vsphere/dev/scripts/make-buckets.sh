#!/bin/bash -e

if [ -z "$MINIO_ACCESS_KEY" ]; then
    echo "Must provide environment variable MINIO_ACCESS_KEY"
    exit 1
fi

if [ -z "$MINIO_SECRET_KEY" ]; then
    echo "Must provide environment variable MINIO_SECRET_KEY"
    exit 1
fi

export MC_HOSTS_myminio=https://$MINIO_ACCESS_KEY:$MINIO_SECRET_KEY@minio.haas-415.pez.pivotal.io:443
mc --insecure mb -p myminio/state
