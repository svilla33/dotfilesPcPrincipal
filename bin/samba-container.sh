#!/usr/bin/env bash
set -euo pipefail

SHARE_DIR="/home/suli/smb"
IMAGE_NAME="samba-local"

mkdir -p "$SHARE_DIR"

if ! podman image exists "$IMAGE_NAME" 2>/dev/null; then
    echo "Construyendo imagen $IMAGE_NAME..."
    podman build -t "$IMAGE_NAME" "$SHARE_DIR"
fi

IP=$(ip route get 1 | awk '{print $7; exit}')

echo "=== Samba Container ==="
echo "  Imagen:    $IMAGE_NAME"
echo "  Puerto:    4445"
echo "  Share:     //$IP/smbshare"
echo "  Usuario:   suli"
echo "  Pass:      suli"
echo "======================="
echo ""

exec podman run --rm --replace \
    --name samba-server \
    -v "$SHARE_DIR":/smb:Z \
    -v "$SHARE_DIR/smb.conf":/etc/samba/smb.conf:ro \
    -p 4445:445 \
    "$IMAGE_NAME"
