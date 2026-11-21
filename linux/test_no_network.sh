#!/usr/bin/env bash
# Privacy check: the sound filter (file and stream paths) and the women's-singing detector open no internet
# connection. Every program runs with build/no-network.so preloaded, which refuses IPv4/IPv6/raw sockets and logs
# each attempt; the log must stay empty. A positive control first proves the shim catches a real attempt.
#   make all build/test-detector build/no-network.so && linux/test_no_network.sh
set -euo pipefail
cd "$(dirname "$0")/.."
SHIM="$PWD/build/no-network.so"
MODEL=models/dfn3/dfn3_stream_int8.onnx
DET=models/detector/detector_v1.onnx
for f in "$SHIM" build/im-process build/im-stream build/test-detector "$MODEL"; do
    [ -e "$f" ] || { echo "missing $f (make all build/test-detector build/no-network.so)" >&2; exit 1; }
done
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
LOG="$T/net.log"
run() { WAAIYA_NET_LOG="$LOG" LD_PRELOAD="$SHIM" LD_LIBRARY_PATH="$PWD/third_party/onnxruntime/lib" "$@"; }
fails=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }

# positive control: a program that does open an internet socket is caught
run python3 -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM)' 2>/dev/null || true
check "the shim catches an internet socket (control)" '[ -s "$LOG" ]'
: > "$LOG"

# 6 s of a voiced sound, stereo 48 kHz, as WAV and as raw float32
python3 - "$T/in.wav" "$T/in.f32" <<'PY'
import math, struct, sys, wave
sr, n = 48000, 48000 * 6
frames = [0.15 * sum(math.sin(2 * math.pi * 220 * h * i / sr) / h for h in range(1, 9)) for i in range(n)]
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes(b"".join(struct.pack("<hh", int(32767 * x), int(32767 * x)) for x in frames))
with open(sys.argv[2], "wb") as f:
    f.write(b"".join(struct.pack("<ff", x, x) for x in frames))
PY

run build/im-process -m "$MODEL" "$T/in.wav" "$T/out.wav" >/dev/null
check "im-process (file filter) ran" '[ -s "$T/out.wav" ]'
run build/im-process -m "$MODEL" --raw < "$T/in.f32" > "$T/out.f32" 2>/dev/null
check "im-process --raw (stream used to save links) ran" '[ "$(stat -c %s "$T/out.f32")" = "$(stat -c %s "$T/in.f32")" ]'
run build/im-stream -m "$MODEL" --max-backlog 0 < "$T/in.f32" > "$T/live.f32" 2>/dev/null || true
check "im-stream (live filter) ran" '[ -s "$T/live.f32" ]'
if [ -f "$DET" ]; then
    run build/im-process -m "$MODEL" -d "$DET" --mute-female-singing --fail-closed "$T/in.wav" "$T/det.wav" >/dev/null
    check "im-process with the women's-singing detector ran" '[ -s "$T/det.wav" ]'
else
    echo "FAIL $DET missing (scripts/fetch_deps.sh detector)"; fails=$((fails + 1))
fi
SING=models/voice/v3/voice_v1_fp16.onnx  # "keep singing" (scripts/fetch_deps.sh models)
if [ -f "$SING" ]; then
    run build/im-stream -m "$SING" --max-backlog 0 < "$T/in.f32" > "$T/sing.f32" 2>/dev/null || true
    check "im-stream with the keep-singing model ran" '[ -s "$T/sing.f32" ]'
else
    echo "FAIL $SING missing (scripts/fetch_deps.sh models)"; fails=$((fails + 1))
fi
check "no internet socket was opened by any of them" '[ ! -s "$LOG" ]'
[ -s "$LOG" ] && cat "$LOG"
[ $fails = 0 ] && echo "no-network: all checks passed" || { echo "no-network: $fails failed"; exit 1; }
