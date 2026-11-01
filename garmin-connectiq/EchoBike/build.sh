#!/usr/bin/env bash
# Build the Echo Bike Connect IQ app.
#
#   ./build.sh                 -> bin/<device>/EchoBike.prg for every product + bin/EchoBike.iq
#   ./build.sh fenix7 epix2    -> only these devices (PRG only)
#
# Environment:
#   CIQ_SDK   path to the Connect IQ SDK (default: newest SDK installed by the SDK Manager)
#   CIQ_KEY   developer key (DER, PKCS#8). Generated in ./developer_key.der if missing.
#             Keep this key! Store updates must be signed with the same key.
set -euo pipefail
cd "$(dirname "$0")"

if [[ -z "${CIQ_SDK:-}" ]]; then
    CIQ_SDK=$(ls -d "$HOME"/.Garmin/ConnectIQ/Sdks/connectiq-sdk-* 2>/dev/null | sort -V | tail -1 || true)
fi
MONKEYC="${CIQ_SDK:+$CIQ_SDK/bin/}monkeyc"
command -v "$MONKEYC" >/dev/null || { echo "monkeyc not found - set CIQ_SDK"; exit 1; }

KEY="${CIQ_KEY:-developer_key.der}"
if [[ ! -f "$KEY" ]]; then
    echo "Generating developer key $KEY"
    openssl genrsa -out developer_key.pem 4096
    openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out "$KEY" -nocrypt
fi

if [[ $# -gt 0 ]]; then
    DEVICES=("$@")
else
    mapfile -t DEVICES < products.txt
fi

mkdir -p bin
for d in "${DEVICES[@]}"; do
    mkdir -p "bin/$d"
    echo "== $d"
    "$MONKEYC" -d "$d" -f monkey.jungle -o "bin/$d/EchoBike.prg" -y "$KEY" -r -l 3 \
        2>&1 | grep -v -e JAVA_TOOL_OPTIONS -e "launcher icon" || true
    [[ -f "bin/$d/EchoBike.prg" ]] || { echo "build failed for $d"; exit 1; }
done

if [[ $# -eq 0 ]]; then
    echo "== store package"
    "$MONKEYC" -e -f monkey.jungle -o bin/EchoBike.iq -y "$KEY" -r -l 3 \
        2>&1 | grep -v -e JAVA_TOOL_OPTIONS -e "launcher icon" || true
    [[ -f bin/EchoBike.iq ]] || { echo "store package failed"; exit 1; }
fi
echo "done"
