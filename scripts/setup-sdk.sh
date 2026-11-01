#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Download the Garmin Connect IQ SDK and create the device definitions this app
# targets - no Garmin account / SDK Manager login required.
#
#   scripts/setup-sdk.sh
#
# Environment:
#   CIQ_SDK_VERSION  SDK version to install (default below, "latest" = newest)
#   CIQ_HOME         install directory (default: <repo>/.ciq)
#   CIQ_DEVICES      device definition directory
#                    (default: ~/.Garmin/ConnectIQ/Devices, where monkeyc looks)
#
# By downloading the SDK you accept the Garmin Connect IQ SDK License Agreement:
# https://developer.garmin.com/connect-iq/sdk/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${CIQ_SDK_VERSION:-9.3.0}"
CIQ_HOME="${CIQ_HOME:-$ROOT/.ciq}"
DEVICES="${CIQ_DEVICES:-$HOME/.Garmin/ConnectIQ/Devices}"
BASE="https://developer.garmin.com/downloads/connect-iq/sdks"

for tool in curl unzip java javac python3; do
    command -v "$tool" >/dev/null || { echo "missing required tool: $tool"; exit 1; }
done

mkdir -p "$CIQ_HOME"
curl -fsSL "$BASE/sdks.json" -o "$CIQ_HOME/sdks.json"
ZIP=$(python3 - "$CIQ_HOME/sdks.json" "$VERSION" <<'EOF'
import json, sys
sdks = json.load(open(sys.argv[1]))
want = sys.argv[2]
match = sdks[-1] if want == "latest" else next((s for s in sdks if s["version"] == want), None)
if not match:
    sys.exit("SDK version %s not found" % want)
print(match["linux"])
EOF
)
SDK_DIR="$CIQ_HOME/${ZIP%.zip}"

if [[ ! -x "$SDK_DIR/bin/monkeyc" ]]; then
    echo "Downloading $ZIP"
    curl -fL --retry 3 "$BASE/$ZIP" -o "$CIQ_HOME/$ZIP"
    unzip -q -o "$CIQ_HOME/$ZIP" -d "$SDK_DIR"
    rm -f "$CIQ_HOME/$ZIP"
fi
ln -sfn "$SDK_DIR" "$CIQ_HOME/sdk"
echo "SDK: $SDK_DIR"

# Device definitions for every product in the manifest.
WORK="$CIQ_HOME/gen"
mkdir -p "$WORK"
unzip -p "$SDK_DIR/bin/monkeybrains.jar" com/garmin/monkeybrains/devices/devices.xml > "$WORK/devices.xml"
javac -nowarn -cp "$SDK_DIR/bin/monkeybrains.jar" -d "$WORK" "$ROOT/scripts/GenerateDevices.java"
REGEX="($(paste -sd'|' "$ROOT/products.txt"))"
java -cp "$SDK_DIR/bin/monkeybrains.jar:$WORK" GenerateDevices "$WORK/devices.xml" "$DEVICES" "$REGEX"

echo
echo "Ready. Build with:  scripts/build.sh"
