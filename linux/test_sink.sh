#!/usr/bin/env bash
# Live test of the plugin inside the running sound server, fully isolated: a null sink
# stands in for the speakers, so nothing is audible and the default output is untouched.
# Plays a test-set mix into the filter sink, records what reaches the null sink, and scores
# instrument suppression / voice retention on the live recording.
#   linux/test_sink.sh [test_item_id]      e.g. speech_ar_0_mvr+3
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PY="${IM_PYTHON:-$REPO/.venv/bin/python}"
PLUGIN="$REPO/build/islamic_mute_ladspa.so"
ITEM="${1:-speech_ar_0_mvr+3}"
TMP="$(mktemp -d)"
N=""; F=""
cleanup() { [ -n "$F" ] && pactl unload-module "$F" 2>/dev/null; [ -n "$N" ] && pactl unload-module "$N" 2>/dev/null; rm -rf "$TMP"; }
trap cleanup EXIT
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" make "$ITEM" "$TMP/mix.wav"
N=$(pactl load-module module-null-sink sink_name=im_test_null rate=48000 sink_properties=device.description=im_test_null)
F=$(pactl load-module module-ladspa-sink sink_name=im_test_filter sink_master=im_test_null rate=48000 plugin="$PLUGIN" label=islamic_mute_stereo control=1)
pactl set-sink-volume im_test_null 100%; pactl set-sink-volume im_test_filter 100%
sleep 0.5
parec --device=im_test_null.monitor --rate=48000 --channels=2 --format=float32le --file-format=wav "$TMP/rec.wav" &
REC=$!
sleep 0.5
paplay --device=im_test_filter --volume=65536 "$TMP/mix.wav"
sleep 1
kill $REC; wait $REC 2>/dev/null || true
[ -n "${IM_KEEP_REC:-}" ] && cp "$TMP/rec.wav" "$IM_KEEP_REC" && cp "$TMP/mix.wav" "${IM_KEEP_REC%.wav}_mix.wav"
PYTHONNOUSERSITE=1 "$PY" "$REPO/linux/live_score.py" score "$ITEM" "$TMP/rec.wav"
