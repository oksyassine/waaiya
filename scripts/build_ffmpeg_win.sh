#!/usr/bin/env bash
# A small LGPL ffmpeg.exe for the Windows app's "save a link without music" (desktop/lib/links.dart), cross-built on
# Linux with llvm-mingw (scripts/fetch_deps.sh mingw), from FFmpeg's pinned source tarball:
#
#   scripts/build_ffmpeg_win.sh        -> third_party/ffmpeg-win/{ffmpeg.exe, ffmpeg-LGPL-2.1.txt, ffmpeg-SOURCE.txt}
#
# Only what the app needs: decode the downloaded sound (AAC, MP3, Opus, Vorbis, FLAC, PCM) to float samples, encode
# AAC, copy the video into MP4/M4A, and yt-dlp's fixups (HLS .ts -> .mp4). No network, no GPL parts, no hardware
# or system libraries (--disable-autodetect): about 3 MB instead of a 100 MB full build. LGPL 2.1 or later: the
# licence text and where the source is go next to it (bundle_windows.sh copies them into licences\).
set -euo pipefail
cd "$(dirname "$0")/.."

FFMPEG_VERSION=9.0.2
FFMPEG_SHA256=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
OUT=third_party/ffmpeg-win
CROSS="${CROSS:-$PWD/third_party/llvm-mingw/bin/x86_64-w64-mingw32-}"
STAMP="$FFMPEG_VERSION $(sha256sum "$0" | cut -c1-16)"

if [ "$(cat "$OUT/VERSION" 2>/dev/null)" = "$STAMP" ] && [ -f "$OUT/ffmpeg.exe" ]; then
    echo "ffmpeg $FFMPEG_VERSION already built in $OUT"; exit 0
fi
[ -x "${CROSS}clang" ] || { echo "llvm-mingw not found (${CROSS}clang): scripts/fetch_deps.sh mingw" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
curl -fsSL --retry 3 -o "$WORK/src.tar.xz" "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz"
echo "$FFMPEG_SHA256  $WORK/src.tar.xz" | sha256sum -c --quiet
tar -C "$WORK" -xJf "$WORK/src.tar.xz"
cd "$WORK/ffmpeg-$FFMPEG_VERSION"

./configure \
    --enable-cross-compile --target-os=mingw32 --arch=x86_64 \
    --cross-prefix="$CROSS" --cc="${CROSS}clang" \
    --pkg-config=false --disable-autodetect --disable-x86asm \
    --enable-static --disable-shared --enable-small \
    --disable-debug --disable-doc --disable-network \
    --disable-ffplay --disable-ffprobe \
    --disable-everything \
    --enable-protocol=file,pipe,fd \
    --enable-decoder=aac,aac_latm,mp3,mp3float,opus,vorbis,flac,pcm_s16le,pcm_s24le,pcm_f32le,pcm_s16be \
    --enable-encoder=aac,pcm_f32le,pcm_s16le \
    --enable-demuxer=mov,matroska,mpegts,mp3,wav,pcm_f32le,aac,flac,ogg \
    --enable-muxer=mp4,ipod,mov,matroska,wav,pcm_f32le,adts \
    --enable-parser=aac,aac_latm,h264,hevc,mpegaudio,opus,vorbis,flac,vp9,av1 \
    --enable-bsf=aac_adtstoasc,extract_extradata,vp9_superframe,h264_mp4toannexb,hevc_mp4toannexb \
    --enable-filter=aresample,aformat,anull,null,format,atrim,trim,asetnsamples \
    --enable-swresample \
    --extra-ldflags="-static"
grep -q 'CONFIG_GPL 0' config.h || { echo "ffmpeg: the build would be GPL" >&2; exit 1; }
make -j"$(nproc)" ffmpeg.exe
"${CROSS}strip" ffmpeg.exe

cd - >/dev/null
rm -rf "$OUT" && mkdir -p "$OUT"
cp "$WORK/ffmpeg-$FFMPEG_VERSION/ffmpeg.exe" "$OUT/"
cp "$WORK/ffmpeg-$FFMPEG_VERSION/COPYING.LGPLv2.1" "$OUT/ffmpeg-LGPL-2.1.txt"
cat > "$OUT/ffmpeg-SOURCE.txt" <<EOF
ffmpeg.exe in Waaiya for Windows is FFmpeg $FFMPEG_VERSION (https://ffmpeg.org), licensed under the GNU Lesser
General Public License version 2.1 or later (ffmpeg-LGPL-2.1.txt). No GPL or non-free parts are enabled.

Source: https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz (sha256 $FFMPEG_SHA256), unmodified.
How it was built: scripts/build_ffmpeg_win.sh in https://github.com/oksyassine/waaiya (configure options there).
EOF
echo "$STAMP" > "$OUT/VERSION"
ls -l "$OUT/ffmpeg.exe"
echo "ffmpeg $FFMPEG_VERSION (LGPL) -> $OUT"
