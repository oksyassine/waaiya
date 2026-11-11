#!/usr/bin/env bash
# Puts the Linux audio engine and the licence texts into a built desktop bundle:
#
#   desktop/tool/bundle_engine.sh desktop/build/linux/x64/release/bundle
#
# Needs the engine built first (scripts/fetch_deps.sh && make all; ORT=... for another ONNX Runtime).
# Layout, so the unchanged `engine/linux/bin/waaiya install` works from it ($REPO = engine/):
#   engine/linux/bin/{islamic-mute,waaiya}   engine/linux/systemd/islamic-mute.service.in
#   engine/build/{im-stream,im-pulse,islamic_mute_ladspa.so,libonnxruntime.so*}
#   engine/models/dfn3/dfn3_stream_int8.{onnx,state_init.bin}   (+ models/detector/detector_v1.onnx if present)
#   engine/VERSION   app version + hash of the files above; the app reinstalls when the installed one differs
set -euo pipefail
BUNDLE="${1:?usage: $0 <desktop bundle dir>}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
ORT="${ORT:-$REPO/third_party/onnxruntime}"
E="$BUNDLE/engine"

for f in build/im-stream build/islamic_mute_ladspa.so models/dfn3/dfn3_stream_int8.onnx \
         models/dfn3/dfn3_stream_int8.state_init.bin; do
    [ -f "$REPO/$f" ] || { echo "missing $f: run scripts/fetch_deps.sh and make all first" >&2; exit 1; }
done

rm -rf "$E"
mkdir -p "$E/linux/bin" "$E/linux/systemd" "$E/build" "$E/models/dfn3"
install -m 755 "$REPO/linux/bin/islamic-mute" "$E/linux/bin/islamic-mute"
ln -s islamic-mute "$E/linux/bin/waaiya"
cp "$REPO/linux/systemd/islamic-mute.service.in" "$E/linux/systemd/"
cp -P "$REPO"/build/libonnxruntime.so* "$REPO/build/im-stream" "$REPO/build/islamic_mute_ladspa.so" "$E/build/"
[ -x "$REPO/build/im-pulse" ] && cp "$REPO/build/im-pulse" "$E/build/"
cp "$REPO"/models/dfn3/dfn3_stream_int8.onnx "$REPO"/models/dfn3/dfn3_stream_int8.state_init.bin "$E/models/dfn3/"
if [ -f "$REPO/models/detector/detector_v1.onnx" ]; then
    mkdir -p "$E/models/detector" && cp "$REPO/models/detector/detector_v1.onnx" "$E/models/detector/"
fi

version="$(sed -n 's/^version: *//p' "$REPO/desktop/pubspec.yaml")"
hash="$(cd "$E" && find . -type f ! -name VERSION -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -c1-12)"
echo "$version-$hash" > "$E/VERSION"

# Licence texts shown by the app (DesktopBackend): the project's, and the engine's (ONNX Runtime, DeepFilterNet).
L="$BUNDLE/licences"
mkdir -p "$L"
cp "$REPO/NOTICE" "$L/NOTICE.txt"
cp "$REPO/LICENSE" "$L/LICENSE-Apache-2.0.txt"
cp "$REPO/THIRD_PARTY_LICENSES.md" "$L/THIRD_PARTY_LICENSES.txt"
cp "$REPO/android/app/licences/DeepFilterNet-LICENSE-MIT.txt" "$L/"
for f in LICENSE ThirdPartyNotices.txt; do
    [ -f "$ORT/$f" ] || { echo "missing $ORT/$f (ONNX Runtime licence texts)" >&2; exit 1; }
    cp "$ORT/$f" "$L/onnxruntime-${f%.txt}.txt"
done
[ -f "$E/models/detector/detector_v1.onnx" ] && cp "$REPO/models/detector/efficientat/LICENSE" "$L/EfficientAT-LICENSE.txt"
echo "engine $(cat "$E/VERSION") -> $E"
