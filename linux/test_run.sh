#!/usr/bin/env bash
# End-to-end test of "islamic-mute run" against a null sink standing in for the speakers
# (nothing audible, default output untouched). Checks filtering, crash recovery (fail-closed)
# and clean shutdown.
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PY="$REPO/.venv/bin/python"
BIN="$HOME/.local/share/islamic-mute/islamic-mute"
TMP="$(mktemp -d)"
B=$(pactl load-module module-null-sink sink_name=im_test_null rate=48000 sink_properties=device.description=im_test_null)
pactl set-sink-volume im_test_null 100%
cleanup() { [ -n "${RUN:-}" ] && kill "$RUN" 2>/dev/null; wait "${RUN:-}" 2>/dev/null; pactl unload-module "$B" 2>/dev/null; rm -rf "$TMP"; }
trap cleanup EXIT
IM_MASTER=im_test_null "$BIN" run 2>"$TMP/run.log" &
RUN=$!
sleep 2
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" make speech_ar_0_mvr+3 "$TMP/mix.wav"
record_play() {
    parec --device=im_test_null.monitor --rate=48000 --channels=2 --format=float32le --file-format=wav "$1" &
    local rec=$!
    parec --device=islamic_mute.monitor --rate=48000 --channels=2 --format=float32le --file-format=wav "$1.dry.wav" &
    local dry=$!
    sleep 0.5
    paplay --device=islamic_mute --volume=65536 "$TMP/mix.wav" &
    local play=$!
    if [ "${2:-}" = crash ]; then sleep 3; pkill -x im-stream; fi
    wait $play
    sleep 1; kill $rec $dry; wait $rec $dry 2>/dev/null
}
echo "1) normal filtering"
record_play "$TMP/rec1.wav"
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" score speech_ar_0_mvr+3 "$TMP/rec1.wav"
PYTHONNOUSERSITE=1 "$PY" - "$TMP/rec1.wav.dry.wav" "$TMP/rec1.wav" <<'PYEOF'
import sys, numpy as np, soundfile as sf
d = sf.read(sys.argv[1], dtype="float32", always_2d=True)[0].mean(1)
w = sf.read(sys.argv[2], dtype="float32", always_2d=True)[0].mean(1)
n = 1 << int(np.ceil(np.log2(len(d) + len(w))))
cc = np.fft.irfft(np.fft.rfft(w, n) * np.conj(np.fft.rfft(d, n)), n)
lag = int(np.argmax(cc[:48000]))
print(f"   end-to-end added delay (virtual output -> speakers): {lag} samples = {lag/48:.0f} ms (engine itself: 40 ms)")
PYEOF
echo "2) filter killed mid-playback (must restart, never pass unfiltered audio)"
record_play "$TMP/rec2.wav" crash
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" score speech_ar_0_mvr+3 "$TMP/rec2.wav" | head -1
echo "   (pass if instrument suppression stays high: the restart gap is silent by design)"
grep -c "restarting" "$TMP/run.log" | sed 's/^/   restarts logged: /'
echo "3) stop"
kill -TERM "$RUN"; wait "$RUN" 2>/dev/null; RUN=""
pactl list short sinks | awk '{print $2}' | grep -qx islamic_mute && echo "   virtual output still present (BAD)" || echo "   virtual output removed"
tail -2 "$TMP/run.log" | sed 's/^/   /'
