#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y docker.io jq curl xfsprogs

# (1) Formatear y montar el data disk (LUN 0) en /data
DISK=/dev/disk/azure/scsi1/lun0
mkfs.xfs -f $DISK
mkdir -p /data
echo "$DISK /data xfs defaults,nofail 0 2" >> /etc/fstab
mount -a

# (2) Descubrir tags desde IMDS
META="http://169.254.169.254/metadata"
KV_NAME=$(curl -s -H Metadata:true "$META/instance/compute/tagsList?api-version=2021-02-01" \
  | jq -r '.[] | select(.name=="keyvaultName") | .value')
UAMI_CLIENT_ID=$(curl -s -H Metadata:true "$META/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" \
  >/dev/null; \
  curl -s -H Metadata:true "$META/instance/compute/identity?api-version=2021-02-01" \
  | jq -r '.userAssignedIdentities[0].clientId')

# (3) Token para Key Vault (con UAMI)
KV_TOKEN=$(curl -s -H Metadata:true \
  "$META/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net&client_id=${UAMI_CLIENT_ID}" \
  | jq -r '.access_token')

# (4) Leer secretos
KV_URI="https://${KV_NAME}.vault.azure.net"
MINIO_ROOT_USER=$(curl -s -H "Authorization: Bearer $KV_TOKEN" "$KV_URI/secrets/minio-root-user?api-version=7.4" | jq -r '.value')
MINIO_ROOT_PASSWORD=$(curl -s -H "Authorization: Bearer $KV_TOKEN" "$KV_URI/secrets/minio-root-password?api-version=7.4" | jq -r '.value')

# (5) Lanzar MinIO con reinicio automático
docker run -d \
  --name minio --restart=always \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER="${MINIO_ROOT_USER}" \
  -e MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD}" \
  -v /data/minio/data:/data \
  -v /data/minio/config:/root/.minio \
  minio/minio server /data --console-address ":9001"