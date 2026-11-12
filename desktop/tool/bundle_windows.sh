#!/usr/bin/env bash
# Puts the Windows sound filter, the screen blur and the licence texts into a built Windows desktop app:
#
#   desktop/tool/bundle_windows.sh desktop/build/windows/x64/runner/Release build-win
#
# build-win: the output of `make -f windows/Makefile` with the models next to it (models/dfn3, models/vision,
# optionally models/detector), as the Windows CI job uploads it. Layout (desktop/lib/windows_engine.dart,
# LinuxBlur.findWindows):
#   engine\waaiya-filter.exe  engine\waaiya-blur.exe  engine\onnxruntime.dll
#   engine\models\dfn3\dfn3_stream_int8.{onnx,state_init.bin}  engine\models\vision\*.onnx
#   engine\models\detector\detector_v1.onnx (if present)
#   engine\VERSION   app version + hash of the engine files (diagnostics)
#   licences\...     shown by the app
# Runs in Git Bash on the Windows runner, or anywhere with bash and sha256sum.
set -euo pipefail
APP="${1:?usage: $0 <Windows app dir (runner/Release)> <build-win dir>}"
BIN="${2:?usage: $0 <Windows app dir> <build-win dir>}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
E="$APP/engine"

VISION=(person_yolox_nano.onnx gender_v2.onnx nsfw_marqo_int8.onnx)
for f in waaiya-filter.exe waaiya-blur.exe onnxruntime.dll models/dfn3/dfn3_stream_int8.onnx \
         models/dfn3/dfn3_stream_int8.state_init.bin "${VISION[@]/#/models/vision/}"; do
    [ -f "$BIN/$f" ] || { echo "missing $BIN/$f: build with windows/Makefile and copy the models next to it" >&2; exit 1; }
done

rm -rf "$E"
mkdir -p "$E/models/dfn3" "$E/models/vision"
cp "$BIN/waaiya-filter.exe" "$BIN/waaiya-blur.exe" "$BIN/onnxruntime.dll" "$E/"
cp "$BIN"/models/dfn3/dfn3_stream_int8.onnx "$BIN"/models/dfn3/dfn3_stream_int8.state_init.bin "$E/models/dfn3/"
for f in "${VISION[@]}"; do cp "$BIN/models/vision/$f" "$E/models/vision/"; done
if [ -f "$BIN/models/detector/detector_v1.onnx" ]; then
    mkdir -p "$E/models/detector" && cp "$BIN/models/detector/detector_v1.onnx" "$E/models/detector/"
fi

version="$(sed -n 's/^version: *//p' "$REPO/desktop/pubspec.yaml" | tr -d '\r')"
hash="$(cd "$E" && find . -type f ! -name VERSION -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -c1-12)"
printf '%s-%s\n' "$version" "$hash" > "$E/VERSION"

L="$APP/licences"
mkdir -p "$L"
cp "$REPO/NOTICE" "$L/NOTICE.txt"
cp "$REPO/LICENSE" "$L/LICENSE-AGPL-3.0.txt"
cp "$REPO/THIRD_PARTY_LICENSES.md" "$L/THIRD_PARTY_LICENSES.txt"
cp "$REPO/android/app/licences/DeepFilterNet-LICENSE-MIT.txt" "$L/"
ORT="${ORT:-$REPO/third_party/onnxruntime-win}"
for f in LICENSE ThirdPartyNotices.txt; do
    [ -f "$ORT/$f" ] || { echo "missing $ORT/$f (ONNX Runtime licence texts: scripts/fetch_deps.sh ort-win)" >&2; exit 1; }
    cp "$ORT/$f" "$L/onnxruntime-${f%.txt}.txt"
done
cp "$REPO/models/vision/licences/YOLOX-LICENSE.txt" "$REPO/models/vision/licences/Marqo-nsfw-image-detection-384-NOTICE.txt" "$L/"
cp "$REPO/android/app/licences/Apache-2.0-LICENSE.txt" "$L/"  # the Apache text of YOLOX and Marqo
[ -f "$E/models/detector/detector_v1.onnx" ] && cp "$REPO/models/detector/efficientat/LICENSE" "$L/EfficientAT-LICENSE.txt"
echo "engine $(cat "$E/VERSION") -> $E"
