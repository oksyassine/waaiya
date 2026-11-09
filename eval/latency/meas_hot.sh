#!/usr/bin/env bash
# like meas_pipe.sh but audio is already playing into the virtual sink when the filter starts
# usage: meas_hot.sh IN_LAT OUT_LAT TAG [im-stream binary]
S="${IM_LAT_DIR:-$(cd "$(dirname "$0")" && pwd)}"  # scripts + outputs (set IM_LAT_DIR to write elsewhere)
R="$(cd "$(dirname "$0")/../.." && pwd)"; PY="env PYTHONNOUSERSITE=1 $R/.venv/bin/python"
IL=$1; OL=$2; TAG=$3; IMB=${4:-$R/build/im-stream}
A=$(pactl load-module module-null-sink sink_name=im_lat_in rate=48000 channels=2)
B=$(pactl load-module module-null-sink sink_name=im_lat_out rate=48000 channels=2)
PIPE=""; Q=""
trap '[ -n "$PIPE" ] && kill -TERM -- -$PIPE; [ -n "$Q" ] && kill $Q; sleep 0.3; pactl unload-module $A; pactl unload-module $B' EXIT
FMT="--raw --format=float32le --rate=48000 --channels=2"
paplay --device=im_lat_in $S/long.wav & Q=$!
sleep ${PRE:-1}
setsid bash -c "parec -d im_lat_in.monitor $FMT --latency-msec=$IL | LD_LIBRARY_PATH=$R/build $IMB -m $R/models/dfn3/dfn3_stream.onnx | pacat -v -d im_lat_out $FMT --latency-msec=$OL" 2>$S/$TAG.pipe.log & PIPE=$!
sleep 2
sleep ${WAIT:-0}; $PY $S/rec2.py im_lat_in.monitor im_lat_out.monitor 20 $S/$TAG >/dev/null 2>&1
IM=$(pgrep -s $PIPE -x im-stream); PC=$(pgrep -s $PIPE -x pacat)
$PY $S/pipeprobe.py $IM $PC 0.5
$PY $S/align.py $S/$TAG ref | tail -1
sed 's/\x1b\[K//g' $S/$TAG.pipe.log | tr '\r' '\n' | grep -c -i underrun | sed 's/^/   underruns: /'
