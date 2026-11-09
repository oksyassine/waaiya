# Latency measurement (Linux)

Scripts used for `eval/results/latency.md`. `rec2.py` records two PulseAudio monitors on one clock;
`align.py` cross-correlates them; `bench.c` times one engine hop; `burn.py` loads the CPU for the "hot" runs.
`meas_pipe.sh` / `meas_move.sh` / `meas_hot.sh` use temporary null sinks; `real_run.sh` uses the real sound card
(keep the speakers at -60 dB). Outputs go next to the scripts unless `IM_LAT_DIR` is set.
Run Python with the project venv and `PYTHONNOUSERSITE=1`.
