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
#   engine\models\voice\v3\voice_v1_fp16.{onnx,state_init.bin} (keep singing, if present)
#   engine\im-process.exe, engine\links\{yt-dlp,qjs,ffmpeg}.exe: "save a link without music" (desktop/lib/links.dart),
#                    when build-win has them (links/ from scripts/fetch_deps.sh links-win and scripts/build_ffmpeg_win.sh);
#                    make_msix.ps1 leaves them out of the Microsoft Store package (watch only there)
#   engine\VERSION   app version + hash of the engine files (diagnostics)
#   licences\...     shown by the app
# Runs in Git Bash on the Windows runner, or anywhere with bash and sha256sum.
set -euo pipefail
APP="${1:?usage: $0 <Windows app dir (runner/Release)> <build-win dir>}"
BIN="${2:?usage: $0 <Windows app dir> <build-win dir>}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
E="$APP/engine"

VISION=(person_yolox_nano.onnx gender_v3.onnx nsfw_marqo_int8.onnx)
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
# "keep singing" (voice_v1, a test): the filter switches to it while running (setting keep_singing)
if [ -f "$BIN/models/voice/v3/voice_v1_fp16.onnx" ] && [ -f "$BIN/models/voice/v3/voice_v1_fp16.state_init.bin" ]; then
    mkdir -p "$E/models/voice/v3" && cp "$BIN"/models/voice/v3/voice_v1_fp16.{onnx,state_init.bin} "$E/models/voice/v3/"
fi
LINKS=(yt-dlp.exe qjs.exe ffmpeg.exe)
links=1
for f in im-process.exe "${LINKS[@]/#/links/}"; do [ -f "$BIN/$f" ] || links=0; done
if [ "$links" = 1 ]; then
    mkdir -p "$E/links"
    cp "$BIN/im-process.exe" "$E/"
    for f in "${LINKS[@]}"; do cp "$BIN/links/$f" "$E/links/"; done
elif [ -n "${REQUIRE_LINKS:-}" ]; then
    echo "missing the link tools in $BIN (im-process.exe, links/yt-dlp.exe, links/qjs.exe, links/ffmpeg.exe)" >&2; exit 1
else
    echo "no link tools in $BIN: Links can only watch in this build"
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
if [ -d "$E/links" ]; then
    for f in yt-dlp-LICENSE.txt yt-dlp-THIRD_PARTY_LICENSES.txt QuickJS-ng-LICENSE.txt ffmpeg-LGPL-2.1.txt ffmpeg-SOURCE.txt; do
        [ -f "$BIN/links/$f" ] || { echo "missing $BIN/links/$f (licence text of a link tool)" >&2; exit 1; }
        cp "$BIN/links/$f" "$L/"
    done
fi
echo "engine $(cat "$E/VERSION") -> $E"
