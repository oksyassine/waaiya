# Latency measurement (Linux)

Scripts used for `eval/results/latency.md`. `rec2.py` records two PulseAudio monitors on one clock;
`align.py` cross-correlates them; `bench.c` times one engine hop; `burn.py` loads the CPU for the "hot" runs.
`meas_pipe.sh` / `meas_move.sh` / `meas_hot.sh` use temporary null sinks; `real_run.sh` uses the real sound card
(keep the speakers at -60 dB). Outputs go next to the scripts unless `IM_LAT_DIR` is set.
Run Python with the project venv and `PYTHONNOUSERSITE=1`.

`meas_pipe.sh pulse 0 TARGET 0 null PLAYFILE TAG` measures `build/im-pulse --target-ms TARGET` the same way as the
pipeline (`meas_pipe.sh im 10 30 480 null ...`). Options (environment): `STALLS="6 12 18 24" STALL_MS=60` freezes the
filter process (SIGSTOP) at those seconds to force underruns; `LOAD=1` runs `burn.py` during the run; `PLAYLAT=50`
makes the player ask for a 50 ms buffer instead of paplay's 2 s. `meas_pipe.sh` asks `align.py` for windowed delays
within ±150 ms (`IM_ALIGN_SEARCH_MS`, default 25 when `align.py` is run by hand) so that delay steps are tracked.
`IM_PULSE_TRACE=1` makes im-pulse print its controller decisions for every hop.
