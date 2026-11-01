#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Build the Echo Bike Connect IQ app.
#
#   scripts/build.sh                 every product -> dist/EchoBike-<device>.prg + dist/EchoBike.iq
#   scripts/build.sh fenix7 epix2    only these devices (PRG only)
#   scripts/build.sh --test fenix7   build the unit-test PRG (run it with monkeydo ... -t)
#
# Environment:
#   CIQ_SDK   Connect IQ SDK directory. Default: <repo>/.ciq/sdk (scripts/setup-sdk.sh),
#             then the newest SDK installed by the SDK Manager, then monkeyc on PATH.
#   CIQ_KEY   developer key (DER, PKCS#8). Generated as ./developer_key.der if missing.
#             Keep it safe: store updates must be signed with the same key.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${CIQ_SDK:-}" ]]; then
    if [[ -x .ciq/sdk/bin/monkeyc ]]; then
        CIQ_SDK="$ROOT/.ciq/sdk"
    else
        CIQ_SDK=$(ls -d "$HOME"/.Garmin/ConnectIQ/Sdks/connectiq-sdk-* 2>/dev/null | sort -V | tail -1 || true)
    fi
fi
MONKEYC="${CIQ_SDK:+$CIQ_SDK/bin/}monkeyc"
command -v "$MONKEYC" >/dev/null || { echo "monkeyc not found - run scripts/setup-sdk.sh or set CIQ_SDK"; exit 1; }

KEY="${CIQ_KEY:-developer_key.der}"
if [[ ! -f "$KEY" ]]; then
    echo "Generating developer key $KEY (keep it if you publish to the store)"
    openssl genrsa -out "${KEY%.der}.pem" 4096 2>/dev/null
    openssl pkcs8 -topk8 -inform PEM -outform DER -in "${KEY%.der}.pem" -out "$KEY" -nocrypt
fi

run() {
    # Hide the JVM proxy banner and the (harmless) launcher icon scaling notice.
    "$MONKEYC" "$@" -f monkey.jungle -y "$KEY" -l 3 2>&1 \
        | grep -v -e JAVA_TOOL_OPTIONS -e "launcher icon" -e "OUT OF .* DEVICES BUILT" || true
}

if [[ "${1:-}" == "--test" ]]; then
    dev="${2:-fenix7}"
    mkdir -p bin
    run -d "$dev" -o "bin/EchoBike-test-$dev.prg" -t
    [[ -f "bin/EchoBike-test-$dev.prg" ]] || { echo "test build failed"; exit 1; }
    echo "Start the simulator ($CIQ_SDK/bin/connectiq), then run:  $CIQ_SDK/bin/monkeydo bin/EchoBike-test-$dev.prg $dev -t"
    exit 0
fi

if [[ $# -gt 0 ]]; then
    DEVICES=("$@")
else
    mapfile -t DEVICES < products.txt
fi

mkdir -p bin dist
for d in "${DEVICES[@]}"; do
    echo "== $d"
    rm -f "bin/$d/EchoBike.prg"
    run -d "$d" -o "bin/$d/EchoBike.prg" -r
    [[ -f "bin/$d/EchoBike.prg" ]] || { echo "build failed for $d"; exit 1; }
    cp "bin/$d/EchoBike.prg" "dist/EchoBike-$d.prg"
done

if [[ $# -eq 0 ]]; then
    echo "== store package (.iq)"
    rm -f dist/EchoBike.iq
    run -e -o dist/EchoBike.iq -r
    [[ -f dist/EchoBike.iq ]] || { echo "store package failed"; exit 1; }
fi
echo "Artifacts in dist/"
