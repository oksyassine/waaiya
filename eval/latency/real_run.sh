#!/usr/bin/env bash
# real hardware: islamic-mute run -> real ALSA sink at -60 dB hw volume; record both monitors on one clock
S="${IM_LAT_DIR:-$(cd "$(dirname "$0")" && pwd)}"  # scripts + outputs (set IM_LAT_DIR to write elsewhere)
R="$(cd "$(dirname "$0")/../.." && pwd)"; RS="${IM_SINK:-$(pactl get-default-sink)}"; PY="env PYTHONNOUSERSITE=1 $R/.venv/bin/python"
TAG=$1; PLAY=$2; BIN=${BIN:-$R/linux/bin/islamic-mute}
RUN=""
restore() {
  [ -n "$RUN" ] && kill -TERM $RUN 2>/dev/null && wait $RUN 2>/dev/null
  pactl set-source-mute $RS.monitor 1; pactl set-sink-volume $RS 100%; pactl set-sink-mute $RS 0
  cp $S/state_master.bak ~/.local/state/islamic-mute/master
}
trap restore EXIT
pactl set-sink-volume $RS 10%; pactl set-source-mute $RS.monitor 0
IM_MASTER=$RS "$BIN" run 2>$S/$TAG.run.log & RUN=$!
sleep 3
D=$(( $($PY -c "import soundfile as sf;print(int(sf.info('$PLAY').duration))") + 3 ))
$PY $S/rec2.py islamic_mute.monitor $RS.monitor $D $S/$TAG >/dev/null 2>&1 & REC=$!
sleep 0.8
paplay --device=islamic_mute "$PLAY" & P=$!
for i in 1 2 3 4 5; do sleep $(( D / 6 )); pactl list sinks | awk -v o="$RS" '/^\tName:/{n=$2} /^\tLatency:/{if(n==o) print "   real sink latency: " $2/1000 " ms (configured " $5/1000 " ms)"}'; done
pactl list sink-inputs | awk '/^Sink Input/{s=$0} /media.name|application.name = "pacat"/{a=1} /Buffer Latency|Sink Latency/{print "   " $0}' | tail -4
wait $P; wait $REC
$PY $S/align.py $S/$TAG ref
grep -i "underrun\|restart" $S/$TAG.run.log | head
grep -c "" $S/$TAG.run.log | sed 's/^/   run.log lines: /'
