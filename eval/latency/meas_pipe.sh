#!/usr/bin/env bash
# usage: meas_pipe.sh FILTER(im|cat|pulse) IN_LAT OUT_LAT BLOCK OUTSINK(null|<real sink name>) PLAYFILE TAG [extra filter args]
#   im/cat: parec IN_LAT ms | im-stream --block BLOCK (or cat) | pacat OUT_LAT ms
#   pulse:  build/im-pulse --target-ms OUT_LAT (IN_LAT and BLOCK unused)
# env: STALLS="6 12 18" stop the filter process (im-stream / im-pulse) for STALL_MS (default 60) ms at those
#      seconds after playback starts (forces underruns); LOAD=1 runs burn.py (LOAD_N busy processes, default 8) during the run;
#      PLAYLAT=50 makes paplay request a 50 ms buffer like a video player (default: paplay's 2 s).
S="${IM_LAT_DIR:-$(cd "$(dirname "$0")" && pwd)}"  # scripts + outputs (set IM_LAT_DIR to write elsewhere)
H="$(cd "$(dirname "$0")" && pwd)"                  # rec2.py, align.py, burn.py
R="$(cd "$(dirname "$0")/../.." && pwd)"; PY="env PYTHONNOUSERSITE=1 $R/.venv/bin/python"
F=$1; IL=$2; OL=$3; BL=$4; OS=$5; PLAY=$6; TAG=$7; shift 7
A=$(pactl load-module module-null-sink sink_name=im_lat_in rate=48000 channels=2 sink_properties=device.description=im_lat_in)
B=""; OUT=$OS
if [ "$OS" = null ]; then B=$(pactl load-module module-null-sink sink_name=im_lat_out rate=48000 channels=2 sink_properties=device.description=im_lat_out); OUT=im_lat_out; fi
PIPE=""; BURN=""; STL=""
cleanup() {
    [ -n "$STL" ] && kill $STL 2>/dev/null; [ -n "$BURN" ] && kill $BURN 2>/dev/null
    [ -n "$PIPE" ] && { pkill -CONT -s $PIPE 2>/dev/null; kill -TERM -- "-$PIPE" 2>/dev/null; }
    sleep 0.3; pactl unload-module $A; [ -n "$B" ] && pactl unload-module $B
}
trap cleanup EXIT
pactl set-sink-volume im_lat_in 100%; [ -n "$B" ] && pactl set-sink-volume im_lat_out 100%
FMT=(--raw --format=float32le --rate=48000 --channels=2)
MODEL=$R/models/dfn3/dfn3_stream.onnx
if [ "$F" = pulse ]; then
    PROC=im-pulse
    setsid bash -c "exec env LD_LIBRARY_PATH=$R/build ${IMP:-$R/build/im-pulse} -m $MODEL --source im_lat_in.monitor --sink $OUT --target-ms $OL $*" 2>$S/$TAG.pipe.log &
else
    PROC=im-stream
    if [ "$F" = im ]; then FILT="LD_LIBRARY_PATH=$R/build ${IMB:-$R/build/im-stream} -m $MODEL --block $BL $*"; else FILT="cat"; fi
    setsid bash -c "parec -v -d im_lat_in.monitor ${FMT[*]} --latency-msec=$IL | $FILT | pacat -v -d $OUT ${FMT[*]} --latency-msec=$OL" 2>$S/$TAG.pipe.log &
fi
PIPE=$!
DUR=$($PY -c "import soundfile as sf;print(int(sf.info('$PLAY').duration))")
[ -n "${LOAD:-}" ] && { $PY $H/burn.py $((DUR + 6)) ${LOAD_N:-8} & BURN=$!; }
sleep 1.5
$PY $H/rec2.py im_lat_in.monitor $OUT.monitor $((DUR + 3)) $S/$TAG > /dev/null 2>&1 & REC=$!
sleep 0.8
if [ -n "${STALLS:-}" ]; then
    (t0=$(date +%s.%N); FP=$(pgrep -s $PIPE -x $PROC)
     for t in $STALLS; do
         sleep "$(echo "$t0 + $t - $(date +%s.%N)" | bc)"
         kill -STOP $FP; sleep "$(echo "${STALL_MS:-60} / 1000" | bc -l)"; kill -CONT $FP
     done) & STL=$!
fi
paplay ${PLAYLAT:+--latency-msec=$PLAYLAT} --device=im_lat_in "$PLAY"
wait $REC
IM_ALIGN_SEARCH_MS=${IM_ALIGN_SEARCH_MS:-150} $PY $H/align.py $S/$TAG ref windows
pactl list sinks | awk -v o="$OUT" '/^\tName:/{n=$2} /^\tLatency:/{if(n==o) print "   reported sink latency " $0}'
if [ "$F" = pulse ]; then
    kill -TERM $PIPE 2>/dev/null; sleep 0.5
    grep "totals:" $S/$TAG.pipe.log | tail -1 | sed 's/.*totals: /   im-pulse totals: /'
else
    sed 's/\x1b\[K//g' $S/$TAG.pipe.log | tr '\r' '\n' | grep -ci "underrun" | sed 's/^/   underrun msgs: /'
    sed 's/\x1b\[K//g' $S/$TAG.pipe.log | tr '\r' '\n' | grep -ci "overrun\|overflow" | sed 's/^/   overrun msgs: /'
fi
