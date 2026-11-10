#!/usr/bin/env bash
# Download what a fresh clone needs to build, with checksums:
#   scripts/fetch_deps.sh ort      ONNX Runtime 1.19.2 for Linux x64 -> third_party/onnxruntime/ (headers, lib, licences)
#   scripts/fetch_deps.sh models   default voice model (DeepFilterNet3 streaming, int8) -> models/dfn3/
#   scripts/fetch_deps.sh          both
# Models are release assets (docs/MODELS.md), not git files. Set WAAIYA_REPO=owner/name to fetch from a fork.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="${WAAIYA_REPO:-oksyassine/waaiya}"
MODELS_TAG=models-v1
ORT_VERSION=1.19.2
ORT_SHA256=eb00c64e0041f719913c4080e0fed7d9963dc3aa9b54664df6036d8308dbcd33

fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }

ort() {
    if [ "$(cat third_party/onnxruntime/VERSION_NUMBER 2>/dev/null)" = "$ORT_VERSION" ]; then
        echo "onnxruntime $ORT_VERSION already in third_party/onnxruntime"; return
    fi
    local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
    local name="onnxruntime-linux-x64-$ORT_VERSION"
    fetch "https://github.com/microsoft/onnxruntime/releases/download/v$ORT_VERSION/$name.tgz" "$tmp/ort.tgz"
    echo "$ORT_SHA256  $tmp/ort.tgz" | sha256sum -c --quiet
    tar xzf "$tmp/ort.tgz" -C "$tmp"
    rm -rf third_party/onnxruntime && mkdir -p third_party && mv "$tmp/$name" third_party/onnxruntime
    echo "onnxruntime $ORT_VERSION -> third_party/onnxruntime"
}

models() {
    local base="https://github.com/$REPO/releases/download/$MODELS_TAG" tmp
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
    local files=(SHA256SUMS dfn3_stream_int8.onnx dfn3_stream_int8.state_init.bin) f
    if ! (for f in "${files[@]}"; do fetch "$base/$f" "$tmp/$f" || exit 1; done) 2>/dev/null; then
        # Private fork or CI before the repository is public: the GitHub CLI (with GH_TOKEN) can still read it.
        command -v gh >/dev/null || { echo "cannot download $base (install gh and log in for a private repo)" >&2; return 1; }
        rm -f "$tmp"/*; for f in "${files[@]}"; do gh release download "$MODELS_TAG" --repo "$REPO" -p "$f" -D "$tmp"; done
    fi
    (cd "$tmp" && sha256sum -c --quiet --ignore-missing SHA256SUMS)
    mkdir -p models/dfn3 && mv "$tmp"/dfn3_stream_int8.* models/dfn3/
    echo "models ($MODELS_TAG) -> models/dfn3/"
}

case "${1:-all}" in
    ort) ort ;;
    models) models ;;
    all) ort; models ;;
    *) echo "usage: $0 [ort|models|all]" >&2; exit 2 ;;
esac
