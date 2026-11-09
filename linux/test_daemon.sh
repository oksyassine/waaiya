#!/usr/bin/env bash
# Live test of the daemon pipeline, isolated: two null sinks stand in for the "Islamic Mute"
# output and for the speakers. Nothing is audible and the default output is untouched.
#   linux/test_daemon.sh [test_item_id]
#   IM_BACKEND=pulse linux/test_daemon.sh   tests build/im-pulse instead of parec | im-stream | pacat
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PY="${IM_PYTHON:-$REPO/.venv/bin/python}"
MODEL="${IM_MODEL:-$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/islamic-mute/model")}"
ITEM="${1:-speech_ar_0_mvr+3}"
TMP="$(mktemp -d)"
A=""; B=""; PIPE_PID=""
cleanup() {
    [ -n "$PIPE_PID" ] && kill -TERM -- "-$PIPE_PID" 2>/dev/null
    [ -n "$A" ] && pactl unload-module "$A" 2>/dev/null; [ -n "$B" ] && pactl unload-module "$B" 2>/dev/null
    rm -rf "$TMP"
}
trap cleanup EXIT
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" make "$ITEM" "$TMP/mix.wav"
A=$(pactl load-module module-null-sink sink_name=im_test_in rate=48000 sink_properties=device.description=im_test_in)
B=$(pactl load-module module-null-sink sink_name=im_test_null rate=48000 sink_properties=device.description=im_test_null)
pactl set-sink-volume im_test_in 100%; pactl set-sink-volume im_test_null 100%
FMT=(--raw --format=float32le --rate=48000 --channels=2)
# own process group, so cleanup can stop exactly this pipeline
if [ "${IM_BACKEND:-pipe}" = pulse ]; then
    setsid "$REPO/build/im-pulse" -m "$MODEL" --source im_test_in.monitor --sink im_test_null 2>"$TMP/pipe.log" &
else
    setsid bash -c 'parec -d im_test_in.monitor "${@:3}" --latency-msec=10 | "$1" -m "$2" | pacat -d im_test_null "${@:3}" --latency-msec=30' \
        _ "$REPO/build/im-stream" "$MODEL" "${FMT[@]}" 2>"$TMP/pipe.log" &
fi
PIPE_PID=$!
sleep 1
parec --device=im_test_null.monitor --rate=48000 --channels=2 --format=float32le --file-format=wav "$TMP/rec.wav" &
REC=$!
sleep 0.5
paplay --device=im_test_in --volume=65536 "$TMP/mix.wav"
sleep 1
kill $REC; wait $REC 2>/dev/null || true
[ "${IM_BACKEND:-pipe}" = pulse ] && { kill -TERM "$PIPE_PID"; wait "$PIPE_PID" 2>/dev/null; PIPE_PID=""; }
grep -v '^$' "$TMP/pipe.log" | grep -v "stats:" | head -3 || true
grep "totals:" "$TMP/pipe.log" | tail -1 || true
[ -n "${IM_KEEP_REC:-}" ] && cp "$TMP/rec.wav" "$IM_KEEP_REC"
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" score "$ITEM" "$TMP/rec.wav"
