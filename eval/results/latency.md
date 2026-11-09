# Measured latency: engine and Linux PulseAudio daemon

Date: 2026-11-09. Machine: i7-1185G7 (8 threads), PulseAudio 13.99.1, Intel HDA ALC289 (speakers).
Model: `models/dfn3/dfn3_stream.onnx` (DeepFilterNet3 speech mode). Engine: 1 ONNX Runtime thread, stereo.
These figures replace the earlier single 59 ms estimate. That figure came from two `parec` processes started
separately, so it carried an unknown start-time offset of a few ms.

## Result

**Uncompensated audio lag on the Linux daemon is about 64–67 ms at the virtual-sink to real-sink tap, plus
the sound card's buffer (2–7.5 ms), so about 70 ms at the speaker. It is not stable: each PulseAudio
underrun adds 6–10 ms that stays until the filter restarts.** A video player sees only the virtual sink's
latency, so everything from the virtual sink's render onward is lag the player does not compensate.

| Component | Measured | Method |
|---|---|---|
| Engine algorithmic delay | **40.00 ms** (1920 samples) exactly: 30 ms look-ahead (`im.latency_samples` = 1440) + 10 ms hop (480) | `build/im-process --keep-delay`, cross-correlation input vs output. Speech and speech+clicks give lag 1920 samples at `--block` 480, 256 and 64. A click train alone is removed by the model (output RMS ≈ 0), so speech is the usable probe. |
| Pipe and PulseAudio buffering only (`parec \| cat \| pacat`, 10/30 ms) | **14.3–14.8 ms** (3 runs) | Timestamped dual recording, below |
| Full filter pipeline, default settings (`parec` 10 ms, `im-stream --block 480`, `pacat` 30 ms), virtual sink to output sink, null sinks | **63.1–66.0 ms, median 64.0 ms** (10 runs, before any underrun) | Same |
| So the filter process itself adds | **≈ 50 ms** = 40 ms engine + ≈ 10 ms. The engine double-buffers one hop per sample (`process_core`), and `im-stream` also waits for a whole 10 ms block before calling it. The hop wait is therefore paid twice. | difference of the two rows above |
| Same, real sound card (real `linux/bin/islamic-mute run`, `IM_MASTER` = ALSA sink at −60 dB hardware volume, so inaudible) | **66.8 ms** steady. The first 2 s ran at 58.9 ms, then one +7.9 ms step from an underrun. | Same, real sink monitor |
| Sound-card buffer after the monitor tap (render to DAC) | **2.0–2.5 ms** reported by PulseAudio from the hardware pointer, *with the recorder attached* (its 2 ms request lowers the sink latency). Unperturbed, not measured: see "Could not be measured". The same `pacat` settings configure **7.5 ms** on a null sink. | `pactl list sinks` while running |
| **Uncompensated A/V lag at the speaker, steady state** | **≈ 69–74 ms** (66.8 + 2–7.5) | sum |
| Filter started while audio is already playing (crash restart / output switch) | 64–73 ms (2 runs) | `paplay` started 1 s before the pipeline |
| Playing app moved into the filter (what `run --default` does) | 73–75 ms before the change, 71 ms after | `pactl move-sink-input` |
| **Filter and a new stream start at the same moment** | **1994 and 1998 ms** before the change (2 of 2 runs); **87–98 ms after** | Both pipes held their 64 KB maximum (≈ 165 ms each), and the rest sat in `parec`'s server buffer. Nothing ever drained it. |
| Drift from underruns, idle machine | `pacat` underran in 6 of 12 default 30 s runs (more often when the load average was ~3); each step was +6 to +10 ms, permanent (e.g. 64.6 → 74.6 ms) | `pacat -v` log + 2 s windowed delays |
| Drift under full CPU load (8 busy processes on 8 threads) | 1–31 underruns per 30 s at every output setting tried (20, 30, 50 ms); lag rose to 85–104 ms. The unchanged binary behaved the same (84–86 ms). | Same |

### How the live delay was measured

`parecord` on two monitors cannot be aligned: each recording starts whenever its stream connects.
A small `ctypes` client of `libpulse-simple` therefore records both monitors at once, the virtual sink
(`islamic_mute.monitor`, i.e. what apps play) and the output sink (`<real sink>.monitor`, i.e. what the filter
delivers). For every 2 ms chunk it stores the monotonic clock minus `pa_simple_get_latency`. Delay =
cross-correlation lag + offset between the two capture clocks, refined to sub-sample resolution. The method was validated
in two ways. Two recordings of the same monitor give 0.00–0.03 ms. A deliberate 33 ms connect stagger gives a naive lag of −34.5 ms and a
corrected delay of −0.05 ms. Glitch checks: the wet recording is compared, in 2 s windows, with the offline engine output
of the dry recording (`im-process`), so a dropout appears as a step. `pacat -v` logs underruns.
Test signal: 30 s of the test set's speech+music mixtures at +3 dB. Scripts were kept in the session scratchpad (not in the repo):
`rec2.py`, `align.py`, `meas_pipe.sh`, `meas_hot.sh`, `meas_move.sh`, `real_run.sh`.

## CPU per hop (RTF), current settings

Per-call timing of `im_engine_process_interleaved`, 8 s of speech × 3, one thread:

| block | mean per call | p50 | p99 | p99.9 | max | RTF |
|---|---|---|---|---|---|---|
| 480 (10 ms, daemon default), stereo | 2.86 ms | 2.62 ms | 4.03 ms | 4.28 ms | 4.68 ms | 0.29 |
| 240, stereo | 1.30 ms (a full hop every 2nd call) | 2.36 ms | 3.39 ms | 4.05 ms | 4.68 ms | 0.26 |
| 120, stereo | 0.63 ms | — | 2.86 ms | 3.88 ms | 3.93 ms | 0.25 |
| 480, `--mono` | 1.35 ms | 1.29 ms | 2.12 ms | 3.24 ms | 3.72 ms | 0.135 |

`im-process` reports RTF 0.23–0.27 stereo. A hop costs at most 4.7 ms of its 10 ms budget, so compute is not
what limits the buffer size. Underruns appear only when the scheduler delays the pipeline (see the load test).

## Settings sweep (null sinks, 30 s each, idle machine, before the change)

| `parec` ms / `pacat` ms / block | Delay (monitor to monitor) | Underruns | Sink latency after the tap |
|---|---|---|---|
| **10 / 30 / 480 (default)** | **64.1 ms** | 0 | 7.5 ms |
| 5 / 30 / 480 | 64.6 ms | 0 | 7.5 ms |
| 10 / 20 / 480 | 64.5 ms | 0 | 5 ms |
| 5 / 20 / 480 | 64.4 ms | 0 | 5 ms |
| 5 / 20 / 240 | 55.3 → 62.8 ms | 1 | 5 ms |
| 5 / 15 / 240 | 60.1 ms | 1 | 3.75 ms |
| 2 / 15 / 240 | 53.2 → 67.7 ms | 3 | 3.75 ms |
| 5 / 15 / 480 | 56.9 → 58.7 ms | 10 | 3.75 ms |
| 5 / 10 / 240 | 160.5 ms | 4 | 2.5 ms |

Lowering `parec` latency changes nothing. Lowering `pacat` latency to 20 ms saves only the 2.5 ms of sink buffer.
Under load it underran as often as 30 ms (26 and 16 underruns in two runs, against 25 and 1). Smaller blocks or buffers
start lower but underrun, and each underrun raises the delay past where it started. Raising `pacat` to 50 ms did not stop
underruns under load. **The `parec`/`pacat`/block defaults in `linux/bin/islamic-mute` were therefore left unchanged.**

## Change made: pipe backlog guard in `im-stream`

`cli/im_stream.c` (lines 4–7, 12–13, 39–46, 51, 58, 66, 84–102): new `--max-backlog MS`, default **30**. Before reading
the next block, `im-stream` checks the input pipe (FIONREAD), and before writing it checks the output pipe. If either
holds more than 30 ms, it drops whole blocks until it is back under the limit. The check applies only to pipes (files and
terminals are never trimmed) and never passes unfiltered audio. Drops are logged to stderr (`filter.log`) at most once per
~10 s.

| Case | Before | After |
|---|---|---|
| Filter and a new stream start together | 1994 / 1998 ms | 87–98 ms (4 runs). A 12 ms limit gave 77.7 ms but dropped blocks in normal playback, so 30 ms was kept. |
| Normal start, interleaved A/B (3 + 3 runs) | 64.0, 64.6 → 70.7 (1 underrun), 64.5 ms | 64.4, 63.1, 63.5 ms; 0 drops, 0 underruns |
| Underrun drift (load) | 84–86 ms | 85–104 ms. Not fixed: the excess sits in `pacat`'s server-side buffer, which `im-stream` cannot see. |

Regression after `make`: `linux/test_daemon.sh` → `LIVE OK` (24.1 dB suppression, −5.0 dB voice). `linux/test_run.sh`,
pointed at the repo script and the new `im-stream` through `XDG_DATA_HOME`/`XDG_STATE_HOME` overrides → `LIVE OK`
(24.5 dB, −4.9 dB, naive delay 62 ms). The crash restart kept 23.1 dB suppression with 1 restart logged, and the stop was clean.
The installed copy in `~/.local/share/islamic-mute` is older than the repo (no guard, no women's-singing flags) and
needs `islamic-mute install` to pick this up.

## Could not be measured

- **Acoustic end to end (speaker to microphone).** Not done: it would be audible, and there is no loopback cable.
- **Unperturbed sound-card buffer.** During the run without a recorder, the user's desktop session was locked. logind
  then made PulseAudio suspend the ALSA sink, so the sink reported 0 µs and the hardware figure could not be
  sampled. The 2.0–2.5 ms above was taken while the recorder's 2 ms request was holding the sink latency down. With the
  daemon alone, expect about the 7.5 ms that the same `pacat` request configures on a null sink.
- **Android.** No phone. All Android figures in the report remain estimates.

## Where the remaining lag could go (not done)

1. **Hop-aligned engine call (−10 ms, derived, not measured).** When the caller passes whole hops (as `im-stream` does),
   the engine could return the current hop's output instead of the previous one. That would make the filter's own delay
   30 ms look-ahead + compute. It is an engine API change, so it was left out of this pass.
2. **Talk to PulseAudio directly instead of `parec | … | pacat`.** One process with a libpulse stream could watch its
   own playback latency and drop to a target after an underrun. That would remove the permanent +6–10 ms steps, which pipes cannot see.
3. **PipeWire filter-chain with a latency port**, so players compensate the lag instead of suffering it.

## im-pulse: one process with libpulse (2026-11-09, second pass)

`build/im-pulse` (`cli/im_pulse.c`) replaces `parec | im-stream | pacat`. It records the virtual sink's monitor, runs
the hop-aligned engine (30 ms) in a worker thread, and writes to the real sink. Before each write it holds the
playback latency at `--target-ms` (default 20 then; now 35, see the third pass below) ± half a hop. Above that it drops the oldest input; below it, it writes
silence; while the stream is stopped it fills only to the target. This removes the pipe's permanent underrun creep.
It loads libpulse with `dlopen`, so it builds without `libpulse-dev`. The daemon uses it when it is installed;
`IM_BACKEND=pipe` restores the pipeline.

Same session, null sinks, interleaved runs, 30 s speech+music, `eval/latency/meas_pipe.sh`. The machine was not idle:
a CPU-heavy browser tab and, for part of the session, a 4-core training job. Delay = virtual-sink monitor to output-sink monitor.

| Condition | Pipe (10/30/480, hop-aligned engine) | im-pulse, target 20 ms |
|---|---|---|
| Steady, quiet periods (2 + 2 runs) | 53.2, 53.2 ms; 0 underruns | 54.7, 54.5 ms; 0–1 underruns, 2–5 small corrections |
| Steady, busy periods (2 + 2 runs) | 74.3 ms (2 underruns before the recording); 60.1 → 86.0 ms (3 underruns) | 54.8, 55.6 ms; 0 underruns |
| 4 forced 60 ms stalls (SIGSTOP), 4 runs each | first → last window 52.4 → 70.1, 87.1 → 83.4, 60.2 → 71.4, 54.9 → 73.6 ms; 4–7 underruns | 53.6 → 57.3, 53.0 → 53.9 ms; 9–18 underruns, 0.3–0.5 s of input dropped |
| Player asks for 50 ms (`PLAYLAT=50`) | 60.0 → 68.5 ms; 2 underruns | 54.2 → 56.1 ms; 1 underrun |
| 4 busy processes (`LOAD_N=4`), 2 runs each | 76–86 ms; 6–30 underruns | 56–60 ms; 80–83 underruns (about 1.1 s dropped per 30 s) |
| 8 busy processes (`burn.py`) | not measurable (output correlation 0.03); 323–350 underruns | not measurable; 486–501 underruns |
| Target 15 ms, busy period (1 run) | — | 50.9 ms; 11 underruns |

In short: im-pulse keeps the delay at about 30 ms + target + 3–5 ms and does not creep. On a quiet machine it is
1.5 ms slower than a pipe that has not yet underrun. When the CPU is busy it underruns more than the pipe, because the
pipe's creep acts as a growing safety buffer. A bounded adaptive target (`--max-target-ms`) raised the delay to the
pipe's level (~88 ms) under load and still had 47–55 underruns, so it is off by default.

What was found while building it (kept in the code):
- `pa_stream_get_latency` with automatic timing updates only was ~10 ms off, because PulseAudio backs the updates
  off to 1.5 s. im-pulse requests a timing update after every write.
- Running the engine inside the record callback (3.4 ms per stereo hop) blocked the libpulse mainloop and gave
  59 underruns in 25 s with a 50 ms player buffer. Mono gave 7 and no engine gave 6. A worker thread brought it to
  16–29 in the same test. The pipe gets 1–3 there; why is still open.
- Corrections in whole hops with a band one hop wide oscillated (drop, insert, drop). Corrections are now
  exact in size, and small ones must persist for 100 ms first.
- Dropping input while the stream was stopped after an underrun could deadlock (the stream never restarted).
  While stopped, im-pulse now uses the queue's read and write indices.

## Real sound card: target 20 ms cuts audio (2026-11-09, third pass)

The tables above used null sinks as the output. On the real ALSA sink (i7-1185G7, PulseAudio 15, card latency ~9 ms),
the installed daemon at target 20 ms gave ~20 underruns per second while Chrome played, and dropped ~3 s of audio
per 10 s: the audio "cuts a lot with short breaks". When the virtual sink is idle, the engine skips the model on
digital silence (0.6 ms per hop), so idle stats looked clean. With music a stereo hop costs 2.8 ms at full clock and
~5 ms live (the CPU clocks down at this light load). Reported playback latency includes the card's ~9 ms, so at 20 ms
only 1–2 ms of slack is left before each write. Repro: null sink `im_dbg`, `paplay` music into it, im-pulse from
its monitor to the ALSA sink with its stream volume at 0.

| 8–25 s of music into the monitored sink, output = ALSA sink | underruns |
|---|---|
| im-pulse target 20 (10 s) | 27 |
| im-pulse target 20, `--mono` (10 s) | 30 |
| im-pulse target 30 (10 s) | 5 |
| im-pulse target 35 (25 s) | 1 |
| im-pulse target 40 (25 s) | 1 |
| im-pulse target 30, `--mono` (25 s) | 0 |
| pipe 10/30 ms, `pacat -v` (25 s) | 11 |
| im-pulse target 20, output to a null sink instead (10 s) | 3 |
| im-pulse target 20, music into an unmonitored sink (10 s) | 1 |

The daemon default is now 35 ms (`IM_TARGET_MS`), so app-to-card delay is about 30 + 35 = 65 ms with the 30 ms
model. A look-ahead-0 model would bring it to about 45 ms.
