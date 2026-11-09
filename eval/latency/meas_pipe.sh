#!/usr/bin/env bash
# usage: meas_pipe.sh FILTER(im|cat) IN_LAT OUT_LAT BLOCK OUTSINK(null|<real sink name>) PLAYFILE TAG [extra im-stream args]
S="${IM_LAT_DIR:-$(cd "$(dirname "$0")" && pwd)}"  # scripts + outputs (set IM_LAT_DIR to write elsewhere)
R="$(cd "$(dirname "$0")/../.." && pwd)"; PY="env PYTHONNOUSERSITE=1 $R/.venv/bin/python"
F=$1; IL=$2; OL=$3; BL=$4; OS=$5; PLAY=$6; TAG=$7; shift 7
A=$(pactl load-module module-null-sink sink_name=im_lat_in rate=48000 channels=2 sink_properties=device.description=im_lat_in)
B=""; OUT=$OS
if [ "$OS" = null ]; then B=$(pactl load-module module-null-sink sink_name=im_lat_out rate=48000 channels=2 sink_properties=device.description=im_lat_out); OUT=im_lat_out; fi
PIPE=""
cleanup() { [ -n "$PIPE" ] && kill -TERM -- "-$PIPE" 2>/dev/null; sleep 0.2; pactl unload-module $A; [ -n "$B" ] && pactl unload-module $B; }
trap cleanup EXIT
pactl set-sink-volume im_lat_in 100%; [ -n "$B" ] && pactl set-sink-volume im_lat_out 100%
FMT=(--raw --format=float32le --rate=48000 --channels=2)
if [ "$F" = im ]; then FILT="LD_LIBRARY_PATH=$R/build ${IMB:-$R/build/im-stream} -m $R/models/dfn3/dfn3_stream.onnx --block $BL $*"; else FILT="cat"; fi
setsid bash -c "parec -v -d im_lat_in.monitor ${FMT[*]} --latency-msec=$IL | $FILT | pacat -v -d $OUT ${FMT[*]} --latency-msec=$OL" 2>$S/$TAG.pipe.log &
PIPE=$!
sleep 1.5
$PY $S/rec2.py im_lat_in.monitor $OUT.monitor $(( $($PY -c "import soundfile as sf;print(int(sf.info('$PLAY').duration))") + 3 )) $S/$TAG > /dev/null 2>&1 & REC=$!
sleep 0.8
paplay --device=im_lat_in "$PLAY"
# snapshot of the stream latencies PulseAudio reports while running
wait $REC
$PY $S/align.py $S/$TAG ref
pactl list sinks | awk -v o="$OUT" '/^\tName:/{n=$2} /^\tLatency:/{if(n==o) print "   reported sink latency " $0}'
grep -ci "underrun" $S/$TAG.pipe.log | sed 's/^/   underrun msgs: /'; grep -ci "overrun\|overflow" $S/$TAG.pipe.log | sed 's/^/   overrun msgs: /'
