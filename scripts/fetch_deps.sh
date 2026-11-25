#!/usr/bin/env bash
# Download what a fresh clone needs to build, with checksums:
#   scripts/fetch_deps.sh ort       ONNX Runtime 1.19.2 for Linux x64 -> third_party/onnxruntime/ (headers, lib, licences)
#   scripts/fetch_deps.sh models    default voice model (DeepFilterNet3 streaming, int8) -> models/dfn3/, and the
#                                   "keep singing" model (voice_v1, fp16 weights) -> models/voice/v3/
#   scripts/fetch_deps.sh vision    screen-blur models (people, woman/man, nudity, person outline) -> models/vision/
#   scripts/fetch_deps.sh detector  women's-singing detector -> models/detector/, only if a release has it (none yet);
#                                   otherwise a notice, never an error (builds work without it)
#   scripts/fetch_deps.sh ort-win   ONNX Runtime 1.19.2 for Windows x64 -> third_party/onnxruntime-win/ (Windows builds)
#   scripts/fetch_deps.sh mingw     llvm-mingw (Linux x64 host) -> third_party/llvm-mingw/: cross-compiles the Windows
#                                   programs (windows/Makefile); not part of "all"
#   scripts/fetch_deps.sh links-win yt-dlp.exe and QuickJS-ng (qjs.exe) with their licence texts -> third_party/links-win/:
#                                   the Windows app's "save a link without music" (ffmpeg: scripts/build_ffmpeg_win.sh);
#                                   not part of "all", never in the Microsoft Store package
#   scripts/fetch_deps.sh           ort, models, vision, detector
# Models are release assets (docs/MODELS.md), not git files. Set WAAIYA_REPO=owner/name to fetch from a fork.
# A model file already in place is kept if it matches the release's SHA256SUMS; otherwise it is downloaded again.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="${WAAIYA_REPO:-oksyassine/waaiya}"
MODELS_TAG=models-v1
VISION_TAG=models-vision-v1
VISION_FILES=(person_yolox_nano.onnx gender_v2.onnx nsfw_marqo_int8.onnx seg.onnx)
DETECTOR=detector_v1.onnx
ORT_VERSION=1.19.2
# ONNX Runtime comes from Microsoft's NuGet package (the GitHub release archives answer 404 since 2026-11-18). The
# package holds the Linux x64 and Windows x64 libraries, the headers and the licence texts; its libonnxruntime.so is
# byte for byte the one of the GitHub archive this project used before (sha256 9c8139e1...).
ORT_NUPKG_SHA256=fa133c8fe6238445a0dd3e8447baa5c7d16f418caa8e576c7e253ba77b27b61b
# The Android app uses onnxruntime-android 1.20.0 (android/app/build.gradle.kts ortVersion: the first release with
# 16 KB-aligned libraries). The AAR has no licence texts: they come from the same version's PyPI wheel.
ORT_ANDROID_VERSION=1.20.0
ORT_ANDROID_WHEEL=https://files.pythonhosted.org/packages/53/d8/93706484c8e0db2dfde8559e74b5a9ab74d203a0471671121188c212f7cb/onnxruntime-1.20.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
ORT_ANDROID_WHEEL_SHA256=041fefe60af844ebd90f344c84f908201490555cd0a6d78dd0a7acdc27b59972
MINGW_VERSION=20261104
MINGW_SHA256=919380403de87dca3c581c2053230cd298af5e891286628ba0613b7fed370926
# Links on Windows (docs/HANDOFF_WINDOWS.md). yt-dlp.exe's checksum is the one of the release's SHA2-256SUMS.
YTDLP_VERSION=2026.10.26
YTDLP_SHA256=f5389d3698ecde4ef06f4e6b1ce0294fe9ac1396228c8990b8d3416d6d177a7d
YTDLP_LICENSE_SHA256=7e12e5df4bae12cb21581ba157ced20e1986a0508dd10d0e8a4ab9a4cf94e85c
YTDLP_THIRD_SHA256=472aefe951c7db35e1657c1d13fd337140511ed6f2b329205105ad441c5a02b7
QJS_VERSION=v0.18.0
QJS_SHA256=ff03398d74ea6e6bd3a8e58058f7003225abcac229d7d57775b7aaae812a49c7
QJS_LICENSE_SHA256=96f73f9d2a16c21a36b418f06073be26e7d6d5e7c1bc99756b21a4f2c74ef171

# One scratch directory for the whole run (a `trap ... RETURN` per function is global in bash and nested calls
# would remove each other's directories).
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }

# GitHub Actions shows ::notice:: lines in the run summary.
notice() { if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::notice::$*"; else echo "notice: $*"; fi; }

# ort_nupkg: downloads and checks the NuGet package once per run; prints its path.
ort_nupkg() {
    local f="$WORK/onnxruntime-$ORT_VERSION.nupkg"
    if [ ! -f "$f" ]; then
        # explicit returns: this runs inside $(...), where a failed command would not stop the script by itself
        fetch "https://api.nuget.org/v3-flatcontainer/microsoft.ml.onnxruntime/$ORT_VERSION/microsoft.ml.onnxruntime.$ORT_VERSION.nupkg" "$f.part" || return 1
        echo "$ORT_NUPKG_SHA256  $f.part" | sha256sum -c --quiet || { echo "ONNX Runtime package: checksum mismatch" >&2; return 1; }
        mv "$f.part" "$f" || return 1
    fi
    echo "$f"
}

# ort_unpack PLATFORM DEST: the package's files for linux-x64 or win-x64 in the layout of Microsoft's release
# archives (include/, lib/, LICENSE, ThirdPartyNotices.txt, VERSION_NUMBER), which the Makefiles and scripts use.
ort_unpack() {
    local pkg tmp
    pkg="$(ort_nupkg)" || exit 1
    tmp="$(mktemp -d -p "$WORK")"
    python3 -I - "$pkg" "$1" "$tmp/ort" "$ORT_VERSION" <<'PY'
import os, sys, zipfile
pkg, plat, dest, ver = sys.argv[1:]
z = zipfile.ZipFile(pkg)
os.makedirs(dest + "/include"); os.makedirs(dest + "/lib")
def put(name, path):
    with open(path, "wb") as f:
        f.write(z.read(name).replace(b"\r\n", b"\n") if path.endswith((".h", ".txt", "LICENSE")) else z.read(name))
for n in z.namelist():
    if n.startswith("build/native/include/") and n.endswith(".h"):
        put(n, dest + "/include/" + n.rsplit("/", 1)[1])
    elif n.startswith(f"runtimes/{plat}/native/") and not n.endswith("/"):
        put(n, dest + "/lib/" + n.rsplit("/", 1)[1])
put("LICENSE", dest + "/LICENSE"); put("ThirdPartyNotices.txt", dest + "/ThirdPartyNotices.txt")
open(dest + "/VERSION_NUMBER", "w").write(ver + "\n")
if plat == "linux-x64":  # the archive's names: libonnxruntime.so -> .so.1 -> .so.<version> (SONAME libonnxruntime.so.1)
    lib = dest + "/lib/"
    os.rename(lib + "libonnxruntime.so", lib + f"libonnxruntime.so.{ver}")
    os.chmod(lib + f"libonnxruntime.so.{ver}", 0o755); os.chmod(lib + "libonnxruntime_providers_shared.so", 0o755)
    os.symlink(f"libonnxruntime.so.{ver}", lib + "libonnxruntime.so.1")
    os.symlink("libonnxruntime.so.1", lib + "libonnxruntime.so")
PY
    rm -rf "$2" && mkdir -p "$(dirname "$2")" && mv "$tmp/ort" "$2"
}

ort() {
    if [ "$(cat third_party/onnxruntime/VERSION_NUMBER 2>/dev/null)" = "$ORT_VERSION" ]; then
        echo "onnxruntime $ORT_VERSION already in third_party/onnxruntime"; return
    fi
    ort_unpack linux-x64 third_party/onnxruntime
    echo "onnxruntime $ORT_VERSION -> third_party/onnxruntime"
}

# ort_android: LICENSE, ThirdPartyNotices.txt and VERSION_NUMBER of the Android app's ONNX Runtime ->
# third_party/onnxruntime-android/ (the Android build's open-source licences screen ships them).
ort_android() {
    local d=third_party/onnxruntime-android
    if [ "$(cat $d/VERSION_NUMBER 2>/dev/null)" = "$ORT_ANDROID_VERSION" ]; then
        echo "onnxruntime $ORT_ANDROID_VERSION licence texts already in $d"; return
    fi
    fetch "$ORT_ANDROID_WHEEL" "$WORK/ort.whl"
    echo "$ORT_ANDROID_WHEEL_SHA256  $WORK/ort.whl" | sha256sum -c --quiet || { echo "ONNX Runtime wheel: checksum mismatch" >&2; exit 1; }
    rm -rf "$d" && mkdir -p "$d"
    python3 -I - "$WORK/ort.whl" "$d" "$ORT_ANDROID_VERSION" <<'PY'
import sys, zipfile
whl, dest, ver = sys.argv[1:]
z = zipfile.ZipFile(whl)
for name in ("LICENSE", "ThirdPartyNotices.txt"):
    open(f"{dest}/{name}", "wb").write(z.read(f"onnxruntime/{name}").replace(b"\r\n", b"\n"))
open(f"{dest}/VERSION_NUMBER", "w").write(ver + "\n")
PY
    echo "onnxruntime $ORT_ANDROID_VERSION licence texts -> $d"
}

# get_asset TAG NAME DIR: downloads one release asset into DIR/NAME.
get_asset() {
    fetch "https://github.com/$REPO/releases/download/$1/$2" "$3/$2" 2>/dev/null && return 0
    # Private fork or CI before the repository is public: the GitHub CLI (with GH_TOKEN) can still read it.
    command -v gh >/dev/null || { echo "cannot download $1/$2 from $REPO (install gh and log in for a private repo)" >&2; return 1; }
    rm -f "$3/$2"
    gh release download "$1" --repo "$REPO" -p "$2" -D "$3" || return 1
}

# release_files TAG DIR FILE...: makes each DIR/FILE equal to the release asset listed in TAG's SHA256SUMS.
# Every requested file must be listed there (a file missing from SHA256SUMS would otherwise pass unchecked).
# A file already in DIR with the listed checksum is kept; others are downloaded, checked, then moved in.
# Returns 1 on any failure without touching DIR (explicit returns: callers may run it under `if`, where set -e is off).
release_files() {
    local tag="$1" dir="$2"; shift 2
    local tmp f want have need=() kept=0
    tmp="$(mktemp -d -p "$WORK")" || return 1
    get_asset "$tag" SHA256SUMS "$tmp" || return 1
    for f in "$@"; do
        want="$(awk -v f="$f" '{ n = $2; sub(/^\*/, "", n); if (n == f) { print $1; exit } }' "$tmp/SHA256SUMS")"
        [ -n "$want" ] || { echo "$f is not in $tag/SHA256SUMS" >&2; return 1; }
        have=""; [ -f "$dir/$f" ] && have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
        if [ "$have" = "$want" ]; then kept=$((kept + 1)); else need+=("$f"); fi
    done
    for f in "${need[@]}"; do
        get_asset "$tag" "$f" "$tmp" || return 1
        want="$(awk -v f="$f" '{ n = $2; sub(/^\*/, "", n); if (n == f) { print $1; exit } }' "$tmp/SHA256SUMS")"
        have="$(sha256sum < "$tmp/$f" | cut -d' ' -f1)"
        [ "$have" = "$want" ] || { echo "$tag/$f: checksum mismatch (got $have, SHA256SUMS says $want)" >&2; return 1; }
    done
    mkdir -p "$dir" || return 1
    for f in "${need[@]}"; do mv -f "$tmp/$f" "$dir/$f" || return 1; done
    echo "$tag -> $dir/: $kept already there and matching, ${#need[@]} downloaded"
}

ort_win() {
    if [ "$(cat third_party/onnxruntime-win/VERSION_NUMBER 2>/dev/null)" = "$ORT_VERSION" ]; then
        echo "onnxruntime $ORT_VERSION (Windows) already in third_party/onnxruntime-win"; return
    fi
    ort_unpack win-x64 third_party/onnxruntime-win
    echo "onnxruntime $ORT_VERSION (Windows) -> third_party/onnxruntime-win"
}

mingw() {
    if [ "$(cat third_party/llvm-mingw/VERSION 2>/dev/null)" = "$MINGW_VERSION" ]; then
        echo "llvm-mingw $MINGW_VERSION already in third_party/llvm-mingw"; return
    fi
    local tmp name="llvm-mingw-$MINGW_VERSION-ucrt-ubuntu-22.04-x86_64"
    tmp="$(mktemp -d -p "$WORK")"
    fetch "https://github.com/mstorsjo/llvm-mingw/releases/download/$MINGW_VERSION/$name.tar.xz" "$tmp/m.tar.xz"
    echo "$MINGW_SHA256  $tmp/m.tar.xz" | sha256sum -c --quiet
    tar -C "$tmp" -xJf "$tmp/m.tar.xz"
    rm -rf third_party/llvm-mingw && mkdir -p third_party && mv "$tmp/$name" third_party/llvm-mingw
    echo "$MINGW_VERSION" > third_party/llvm-mingw/VERSION
    echo "llvm-mingw $MINGW_VERSION -> third_party/llvm-mingw"
}

# checked FILE URL SHA256: downloads URL into FILE only if its checksum matches.
checked() {
    fetch "$2" "$1.part"
    echo "$3  $1.part" | sha256sum -c --quiet || { echo "$2: checksum mismatch" >&2; rm -f "$1.part"; exit 1; }
    mv "$1.part" "$1"
}

links_win() {
    local d=third_party/links-win
    if [ "$(cat "$d/VERSION" 2>/dev/null)" = "$YTDLP_VERSION $QJS_VERSION" ]; then
        echo "yt-dlp $YTDLP_VERSION and QuickJS-ng $QJS_VERSION already in $d"; return
    fi
    rm -rf "$d" && mkdir -p "$d"
    checked "$d/yt-dlp.exe" "https://github.com/yt-dlp/yt-dlp/releases/download/$YTDLP_VERSION/yt-dlp.exe" "$YTDLP_SHA256"
    checked "$d/yt-dlp-LICENSE.txt" "https://raw.githubusercontent.com/yt-dlp/yt-dlp/$YTDLP_VERSION/LICENSE" "$YTDLP_LICENSE_SHA256"
    checked "$d/yt-dlp-THIRD_PARTY_LICENSES.txt"         "https://raw.githubusercontent.com/yt-dlp/yt-dlp/$YTDLP_VERSION/THIRD_PARTY_LICENSES.txt" "$YTDLP_THIRD_SHA256"
    checked "$d/qjs.exe" "https://github.com/quickjs-ng/quickjs/releases/download/$QJS_VERSION/qjs-windows-x86_64.exe" "$QJS_SHA256"
    checked "$d/QuickJS-ng-LICENSE.txt" "https://raw.githubusercontent.com/quickjs-ng/quickjs/$QJS_VERSION/LICENSE" "$QJS_LICENSE_SHA256"
    echo "$YTDLP_VERSION $QJS_VERSION" > "$d/VERSION"
    echo "yt-dlp $YTDLP_VERSION and QuickJS-ng $QJS_VERSION -> $d"
}

# The "keep singing" model (setting keep_singing): bundled by the APK and the desktop engine like the default one.
SINGING_FILES=(voice_v1_fp16.onnx voice_v1_fp16.state_init.bin)

models() {
    release_files "$MODELS_TAG" models/dfn3 dfn3_stream_int8.onnx dfn3_stream_int8.state_init.bin
    release_files "$MODELS_TAG" models/voice/v3 "${SINGING_FILES[@]}"
    # "Check for music" (Android): the AudioSet tagger, made by models/music/export_tagger.py (in models-v1 since 0.2.18)
    release_files "$MODELS_TAG" models/music tagger_mn04.onnx
}

vision() { release_files "$VISION_TAG" models/vision "${VISION_FILES[@]}"; }

# detector_release: prints the tag of the newest published release that has $DETECTOR as an asset, nothing if none.
# Returns 1 if the release list could not be read.
detector_release() {
    local json=""
    if command -v gh >/dev/null; then json="$(gh api "repos/$REPO/releases?per_page=100" 2>/dev/null)" || json=""; fi
    if [ -z "$json" ]; then
        json="$(curl -fsSL --retry 3 "https://api.github.com/repos/$REPO/releases?per_page=100" 2>/dev/null)" || return 1
    fi
    command -v python3 >/dev/null || return 1
    printf '%s' "$json" | python3 -c '
import json, sys
for r in json.load(sys.stdin):  # newest first
    if not r.get("draft") and any(a.get("name") == sys.argv[1] for a in r.get("assets", [])):
        print(r["tag_name"])
        break
' "$DETECTOR" 2>/dev/null || return 1
}

# The women's-singing detector (in the models-v1 release since 0.2.12). Never fails the run here: a local build
# without it only loses women's singing; CI checks for the file itself and fails without it.
detector() {
    local tag
    if ! tag="$(detector_release)"; then
        notice "could not list the releases of $REPO: the women's-singing detector ($DETECTOR) is not fetched"
    elif [ -z "$tag" ]; then
        notice "no release of $REPO has $DETECTOR yet: builds from this checkout have no women's-singing filter"
    elif release_files "$tag" models/detector "$DETECTOR"; then
        return 0
    else
        notice "$DETECTOR from $tag could not be downloaded or checked: left out (no women's-singing filter)"
    fi
    if [ -f "models/detector/$DETECTOR" ]; then echo "  keeping the local models/detector/$DETECTOR (not checked against a release)"; fi
    return 0
}

case "${1:-all}" in
    ort) ort ;;
    ort-android) ort_android ;;
    ort-win) ort_win ;;
    mingw) mingw ;;
    links-win) links_win ;;
    models) models ;;
    vision) vision ;;
    detector) detector ;;
    all) ort; ort_android; models; vision; detector ;;
    *) echo "usage: $0 [ort|ort-android|ort-win|mingw|links-win|models|vision|detector|all]" >&2; exit 2 ;;
esac
