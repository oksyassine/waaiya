#!/usr/bin/env bash
# Download what a fresh clone needs to build, with checksums:
#   scripts/fetch_deps.sh ort       ONNX Runtime 1.19.2 for Linux x64 -> third_party/onnxruntime/ (headers, lib, licences)
#   scripts/fetch_deps.sh models    default voice model (DeepFilterNet3 streaming, int8) -> models/dfn3/
#   scripts/fetch_deps.sh vision    screen-blur models (people, woman/man, nudity, person outline) -> models/vision/
#   scripts/fetch_deps.sh detector  women's-singing detector -> models/detector/, only if a release has it (none yet);
#                                   otherwise a notice, never an error (builds work without it)
#   scripts/fetch_deps.sh           all of the above
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
ORT_SHA256=eb00c64e0041f719913c4080e0fed7d9963dc3aa9b54664df6036d8308dbcd33

# One scratch directory for the whole run (a `trap ... RETURN` per function is global in bash and nested calls
# would remove each other's directories).
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }

# GitHub Actions shows ::notice:: lines in the run summary.
notice() { if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::notice::$*"; else echo "notice: $*"; fi; }

ort() {
    if [ "$(cat third_party/onnxruntime/VERSION_NUMBER 2>/dev/null)" = "$ORT_VERSION" ]; then
        echo "onnxruntime $ORT_VERSION already in third_party/onnxruntime"; return
    fi
    local tmp; tmp="$(mktemp -d -p "$WORK")"
    local name="onnxruntime-linux-x64-$ORT_VERSION"
    fetch "https://github.com/microsoft/onnxruntime/releases/download/v$ORT_VERSION/$name.tgz" "$tmp/ort.tgz"
    echo "$ORT_SHA256  $tmp/ort.tgz" | sha256sum -c --quiet
    tar xzf "$tmp/ort.tgz" -C "$tmp"
    rm -rf third_party/onnxruntime && mkdir -p third_party && mv "$tmp/$name" third_party/onnxruntime
    echo "onnxruntime $ORT_VERSION -> third_party/onnxruntime"
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

models() { release_files "$MODELS_TAG" models/dfn3 dfn3_stream_int8.onnx dfn3_stream_int8.state_init.bin; }

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

# The women's-singing detector is optional: no release ships it yet. Never fails the run.
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
    models) models ;;
    vision) vision ;;
    detector) detector ;;
    all) ort; models; vision; detector ;;
    *) echo "usage: $0 [ort|models|vision|detector|all]" >&2; exit 2 ;;
esac
