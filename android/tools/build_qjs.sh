#!/bin/bash
# Builds the QuickJS-NG command-line engine (qjs, MIT) for Android, used by yt-dlp to solve YouTube's
# JavaScript challenge. Output: <out>/<abi>/libqjs.so for each ABI (an executable named like a library, so
# Android extracts it to nativeLibraryDir, the only app location allowed to execute files).
# Usage: build_qjs.sh <sdk dir> <ndk dir> <work dir> <out dir> <abi>...
set -euo pipefail
SDK=$1 NDK=$2 WORK=$3 OUT=$4; shift 4
VER=0.18.0
SHA=28bcd89aa3683fd2a946537e5ce3f11cc46b5cbf3383c7561aaef3df5ff9f1dd
CM=$(ls -d "$SDK"/cmake/*/bin | sort -V | tail -1)
STRIP=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip
mkdir -p "$WORK" "$OUT"
TGZ=$WORK/quickjs-$VER.tar.gz
if [ ! -f "$TGZ" ] || ! echo "$SHA  $TGZ" | sha256sum -c --quiet - 2>/dev/null; then
    curl -fsSL -o "$TGZ.part" "https://github.com/quickjs-ng/quickjs/archive/refs/tags/v$VER.tar.gz"
    echo "$SHA  $TGZ.part" | sha256sum -c --quiet - || { echo "quickjs-ng $VER: checksum mismatch" >&2; exit 1; }
    mv "$TGZ.part" "$TGZ"
fi
SRC=$WORK/quickjs-$VER
[ -f "$SRC/CMakeLists.txt" ] || { rm -rf "$SRC"; mkdir -p "$SRC"; tar -xzf "$TGZ" -C "$SRC" --strip-components=1; }
cp "$SRC/LICENSE" "$WORK/quickjs-ng-LICENSE.txt"  # picked up by copyLicences, not packaged as a library
for abi in "$@"; do
    B=$WORK/build-$abi
    "$CM/cmake" -S "$SRC" -B "$B" -G Ninja -DCMAKE_MAKE_PROGRAM="$CM/ninja" \
        -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" -DANDROID_ABI="$abi" \
        -DANDROID_PLATFORM=android-29 -DCMAKE_BUILD_TYPE=Release -DQJS_ENABLE_INSTALL=OFF > "$B.log" 2>&1
    "$CM/ninja" -C "$B" qjs_exe >> "$B.log" 2>&1 || { tail -20 "$B.log" >&2; exit 1; }
    mkdir -p "$OUT/$abi"
    "$STRIP" -o "$OUT/$abi/libqjs.so" "$B/qjs"
done
