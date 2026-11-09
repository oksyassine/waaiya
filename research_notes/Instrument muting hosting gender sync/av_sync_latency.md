# A/V sync and latency for a system-wide "capture, then neural processing, then re-output" audio filter (per platform, as of Nov 2026)

Scope: keep lip-sync acceptable when an instrument-removal model sits between video apps and the speaker or headphones. The aims are to (a) keep the added delay as low as possible and (b) wherever the platform allows, make the video app compensate by having the platform report the added delay.

Notation used throughout: **Δ** = how much later the user hears the processed audio than the video app thinks it is being heard. Δ is the uncompensated lip-sync error. Positive Δ means audio is late.

Method: most Android, Media3, PipeWire, mpv, PulseAudio, BlackHole, cubeb and Chromium claims below were checked against current source files (main or master branches, downloaded 2026-11-09), with line numbers where useful. Measured figures are labelled **[measured]**. Values derived from source constants are labelled **[from source]**. Everything else is labelled **[estimate]**. Overlap with the earlier notes in `research_notes/System wide instrument muting app/` is kept to what this sync question needs.

---

## 1. Perception limits: how much delay is acceptable?

### Takeaway
Audio arriving **late** is tolerated much better than audio arriving early. The broadcast-grade target for audio lag is about **45–60 ms** (ATSC IS-191 at encoder input: lag ≤ 45 ms; EBU R37 end-to-end: lag ≤ 60 ms). ITU-R BT.1359 puts the threshold where expert viewers start to **detect** lag at **125 ms**. The **acceptability** threshold for lag is about **185–190 ms** (secondary sources disagree on the exact figure). A system-wide filter should therefore aim for Δ ≤ 45–60 ms, which nobody notices; treat about 125 ms as a hard ceiling and never go past about 185 ms. Never let audio lead the video by more than about 15–40 ms. Over-compensating, which makes audio early, is worse than under-compensating.

### Cited Findings
- ITU-R BT.1359-1: "the threshold for detectability is 45 ms lead to 125 ms lag", from controlled tests with expert viewers — [Wikipedia: Audio-to-video synchronization](https://en.wikipedia.org/wiki/Audio-to-video_synchronization)
- BT.1359 acceptability is about +90 ms (audio early) to −185 ms (audio late) — [Wikipedia (as cited in earlier project notes)](https://en.wikipedia.org/wiki/Audio-to-video_synchronization), [ITU-R BT.1359-1](https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!MSW-E.doc). Another secondary source gives −190 ms for audio late: [Forasoft, "lip sync ITU-R BT.1359 tolerance windows"](https://www.forasoft.com/learn/audio-for-video/articles-audio/lip-sync-itu-r-bt-1359-tolerance-windows). **Conflict:** −185 vs −190 ms. The ITU PDF figure was not re-read in this session.
- EBU R37: "end-to-end audio/video sync should be within +40 ms and -60 ms (audio before/after video, respectively)" and "each stage should be within +5 ms and -15 ms" — [Wikipedia](https://en.wikipedia.org/wiki/Audio-to-video_synchronization). A 2009 NAB summary gives an EBU R37-2007 distribution tolerance of +22.5/−30 ms — [NAB TV TechCheck 2009-10-05](https://nab.org/xert/scitech/2009/TVTechCheck/TV100509.asp). The EBU primary text was not retrieved.
- ATSC IS-191: "audio should lead video by no more than 15 ms" and "audio should lag video by no more than 45 ms" (measured at encoder input) — [Wikipedia](https://en.wikipedia.org/wiki/Audio-to-video_synchronization); [TV Technology: ATSC Recommends AV Sync Rules](https://tvtechnology.com/opinions/atsc-recommends-av-sync-rules). A search summary of the TV Technology article reported a broader end-to-end figure of +30/−90 ms from the working group. I did not verify that against the article text.
- Film: "acceptable lip sync is considered to be no more than 22 milliseconds in either direction" — [Wikipedia](https://en.wikipedia.org/wiki/Audio-to-video_synchronization)
- Older adults have higher detection and tolerance thresholds for auditory-visual asynchrony than younger adults (2009 study) — [scite summary "hearing by eye"](https://www.scite.ai/reports/hearing-by-eye-how-much-kKrkYa); a study of conference interpreters found detectability thresholds higher than the recommended ones — search result only (publication year not confirmed).

### Inferences
- Use **≤ 45 ms** of uncompensated audio lag (ATSC) as the "invisible" design target and **≤ 125 ms** (BT.1359 detectability) as the hard ceiling. Over about 185 ms counts as broken.
- Because audio leading is penalised about 3× more, any compensation must be **conservative**. If the platform lets us report delay, report at most the true delay, never more.
- Small phone screens and lower video quality probably raise the thresholds a little. No quantitative mobile-specific threshold was found (see Gaps), so the broadcast numbers stay the design basis.

### Gaps
- No peer-reviewed lip-sync threshold study specific to smartphone or tablet viewing (2020–2026) was found in the searches. The ITU PDF and EBU R37 primary texts were not re-read, so the acceptability figure (−185 vs −190 ms) remains a secondary-source conflict.

---

## 2. Android rootless pipeline: where the delay comes from, and the realistic minimum

Pipeline: AudioPlaybackCapture (MediaProjection) → AudioRecord → our processing → AudioTrack or Oboe/AAudio → device.

### Takeaway
The capture leg alone is dominated by the **remote-submix MonoPipe**. The pipe is 4096 frames (85.3 ms at 48 kHz), and a write throttle keeps its **average fill near 11/16 of that, about 2816 frames ≈ 58.7 ms**. The record thread also delivers audio in **1024-frame (21.3 ms) periods**. Stock Android therefore cannot capture other apps' audio with less than about **60–85 ms** of latency, and no unprivileged API changes the pipe size. Add the model's algorithmic latency (10–40 ms for speech-style models, 23–92 ms for music-separation models) plus a compute margin, plus our output buffer. The realistic **best case for Δ on a modern phone is about 90–150 ms**; typical is about 150–300 ms. The only field report for an existing app (RootlessJamesDSP) is about 500 ms. The rootless route therefore cannot meet the 45 ms target, and only a carefully tuned build stays under the 125 ms detectability limit.

### Cited Findings — AOSP remote submix (the capture floor) [from source]
- Legacy HAL `audio_hw.cpp`: `#define DEFAULT_PIPE_SIZE_IN_FRAMES (1024*4) // size at default sample rate`; `#define DEFAULT_PIPE_PERIOD_COUNT 4`. The comments say "The maximum latency of the device is the size of the MonoPipe's buffer; the minimum latency is the MonoPipe buffer size divided by this value." The pipe is "rounded up to the nearest power of 2 by MonoPipe()" (lines 65–70). `out_get_latency()` returns the **whole pipe size** in ms (lines 711–724) — [AOSP libhardware audio_remote_submix/audio_hw.cpp](https://android.googlesource.com/platform/hardware/libhardware/+/refs/heads/main/modules/audio_remote_submix/audio_hw.cpp)
- The AIDL default HAL (the Android 14+ path) uses the same constants: `kDefaultSampleRateHz = 48000`, `kDefaultPipePeriodCount = 4`, `kDefaultPipeSizeInFrames = 1024 * kDefaultPipePeriodCount` (SubmixRoute.h lines 42–49). The pipe is scaled by `sampleRate / 48000` and created as `MonoPipe(pipeSizeInFrames, format, true /*writeCanBlock*/)` (SubmixRoute.cpp lines 193–200) — [SubmixRoute.h](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/r_submix/SubmixRoute.h), [SubmixRoute.cpp](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/r_submix/SubmixRoute.cpp)
- AIDL `StreamRemoteSubmix::transfer` reports `*latencyMs = getDelayInUsForFrameCount(getStreamPipeSizeInFrames()) / 1000`, which is the full pipe (line 140). Input reads sleep to emulate real time, using `kReadAttemptSleepUs = 5000` and `kMaxReadFailureAttempts = 3` — [StreamRemoteSubmix.cpp](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/r_submix/StreamRemoteSubmix.cpp), [StreamRemoteSubmix.h](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/include/core-impl/StreamRemoteSubmix.h). The legacy comment is: "3 * 5ms = 15ms < 1024 frames * 1000 / 48000 = 21.333ms" (audio_hw.cpp lines 71–75).
- **Steady-state pipe depth:** in `MonoPipe.cpp`, `mSetpoint((reqFrames * 11) / 16)` (line 41). When `mWriteCanBlock` is true, the writer "simulate[s] blocking I/O by sleeping at different rates... The throttle tries to keep the mean pipe depth near the setpoint". The writer fills at 0.5× nominal duration when the pipe is ≤ setpoint/2 and at 1.75× when it is severely overflowing (lines 88–118) — [MonoPipe.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/media/libnbaio/MonoPipe.cpp). **Calculation:** 4096 × 11/16 = 2816 frames = **58.7 ms at 48 kHz**. That is the expected average time a sample spends in the pipe whenever a reader is active.
- Write-side behaviour: "If the write to the sink would block, flush enough frames from the pipe to make space to write the most recent data. We DO NOT block if no peer input stream is present [or] the peer input is in standby AFTER having been active. We DO block if the input was never activated to avoid discarding first frames" (legacy lines ~773–790; AIDL `SubmixRoute::shouldBlockWrite()` lines 135–141). The pipe therefore never holds more than about 85 ms, but a reader that falls behind loses the oldest audio. — [audio_hw.cpp](https://android.googlesource.com/platform/hardware/libhardware/+/refs/heads/main/modules/audio_remote_submix/audio_hw.cpp), [SubmixRoute.cpp](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/r_submix/SubmixRoute.cpp)
- Input HAL buffer = one period: `in_get_buffer_size()` returns `buffer_period_size_frames` = pipe/4 = 1024 frames ≈ 21.3 ms (legacy lines 961–973, 411–413). The AudioFlinger RecordThread therefore pulls the submix in about 21 ms chunks.

### Cited Findings — capture/read and output sizing in real tools
- scrcpy (which captures REMOTE_SUBMIX as the shell user): "Never read more than 1024 samples, even if the buffer is bigger (that would increase latency)" (`MAX_READ_SIZE = 1024 * CHANNELS * BYTES_PER_SAMPLE`) — [scrcpy AudioConfig.java](https://github.com/Genymobile/scrcpy/blob/master/server/src/main/java/com/genymobile/scrcpy/audio/AudioConfig.java). The AudioRecord buffer is `8 * minBufferSize` with the comment "This buffer size does not impact latency" — [AudioDirectCapture.java](https://github.com/Genymobile/scrcpy/blob/master/server/src/main/java/com/genymobile/scrcpy/audio/AudioDirectCapture.java). In other words, **AudioRecord buffer capacity does not add latency; only how much you read at a time and how promptly you read does.**
- scrcpy client side: "The default buffer size is set to 50ms" (`--audio-buffer`), and "another audio buffer (the audio output buffer), by default set to 10ms. Do not change this setting unless you have a good reason" (`--audio-output-buffer`) — [scrcpy doc/audio.md](https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md). scrcpy's author reported that on the devices he tested, "audio blocks were produced only every 20 ms, which introduces a latency of 20 ms" — [rom1v blog, scrcpy 2.0 with audio (search summary)](https://blog.rom1v.com/2023/03/scrcpy-2-0-with-audio/). This is consistent with the 1024-frame/21.3 ms submix period. **[measured, single observation]**
- RootlessJamesDSP: issue #201 (Nothing Phone 2, Shizuku) reports a consistent ~**500 ms** audio delay while watching video, and the buffer-size slider had no effect **[measured, community report]**. The app's own text says it "may add some delay... add movie/video apps to the exclusion list to prevent AV-desync". Its output is a Java `AudioTrack`, `MODE_STREAM`, `WRITE_BLOCKING`, which is not the low-latency path — [RootlessJamesDSP issue #201](https://github.com/timschneeb/RootlessJamesDSP/issues/201); earlier notes `android_rootless_interception.md` (RootlessAudioProcessorService.kt, strings.xml).
- Oboe/AAudio output: the round trip is about **20 ms** with all low-latency recommendations, about 21 ms with MMAP vs about 62 ms without MMAP, about 205 ms in the default (non-low-latency) performance mode. "If you use blocking writes and you are on a device that does not support the AAudio MMAP mode, latency might be much higher." — [Android: Oboe low-latency audio](https://developer.android.com/games/sdk/oboe/low-latency-audio) **[measured by Google, round trip, not this pipeline]**

### Inferences
- **The Δ equation on Android (playback-capture mode, original muted by a volume effect):**
  Δ = T_capture + T_model + T_compute_margin + L_ours − L_orig
  - L_ours and L_orig are the times from AudioFlinger mixing to sound leaving the device, for our track and for the original app's track. The original (muted) app's AudioTrack timestamp already contains L_orig, so the app delays its video by L_orig. The device and Bluetooth part of L cancels out (Section 3).
  - If our output is a **FAST/MMAP low-latency track** while the original sits on the deep-buffer media output (normal for video apps), L_ours − L_orig can be **negative** (we get back the deep-buffer depth). This is the only "free" latency on Android, so always open the output as low-latency (Oboe `PerformanceMode::LowLatency`, or `AudioTrack.PERFORMANCE_MODE_LOW_LATENCY`, `MODE_STREAM`, small buffer). **[estimate]**
- **Capture floor [from source + estimate]:** pipe ≈ 58.7 ms average (up to 85.3 ms) + RecordThread period granularity of up to 21.3 ms. T_capture ≈ **60–85 ms**. It cannot go lower without replacing the submix HAL, which needs root (Section 4).
- **Per-stage budget [estimate], best realistic on a 2024–2026 flagship:** capture 65 ms + model 20–40 ms (for example a 10 ms hop with 1–2 frames of look-ahead) + compute margin of one hop (about 10 ms) + output buffer of 2 bursts (about 4–10 ms on MMAP) − deep-buffer gain (0–20 ms). Δ ≈ **90–130 ms**. Typical with a Java AudioTrack and a 92 ms music-separation model: 200–300 ms. A RootlessJamesDSP-style blocking implementation measured about 500 ms.
- Concrete rules for the rootless build: read with `READ_NON_BLOCKING` or read ≤ 1 hop at a time; never let the capture ring buffer grow (drop the oldest frames if the model falls behind, rather than queueing); keep exactly one hop of compute slack; output through AAudio exclusive MMAP if available, else shared low-latency; keep the AudioTrack buffer at 2× burst; run inference on a dedicated SCHED_FIFO-like thread (Oboe callback thread or a high-priority thread).
- If Δ ≤ 125 ms cannot be met, the product should **offer a per-app "video" exclusion** (as RootlessJamesDSP does) or route the content into our own player (Section 5). There a perfect sync is possible.

### Gaps
- No published device-by-device measurement of AudioPlaybackCapture latency was found. The MonoPipe-setpoint figure (58.7 ms) is derived from code, not measured. OEM builds could ship a modified r_submix (vendor overlays), which was not checked.
- AudioRelay, SoundWire and sndcpy latency figures were not retrieved in this session (no primary measurements found within budget). sndcpy predates scrcpy 2.0 and uses the same REMOTE_SUBMIX/playback-capture mechanisms.
- Whether a playback-capture AudioRecord can get a "fast" RecordThread (no): the submix input is a normal record thread with a 1024-frame period per source, but AudioFlinger's FastCapture eligibility for remote submix was not checked in Threads.cpp.

---

## 3. Bluetooth, and how ExoPlayer/Media3 (and YouTube) sync video to `AudioTrack.getTimestamp()`

### Takeaway
Yes. The muted original app's AudioTrack timestamp **includes the Bluetooth delay**, because the Bluetooth audio HAL subtracts the headset's AVDTP delay report from the presented-frame count. ExoPlayer-style players drive the video clock from `AudioTrack.getTimestamp()` (with a fallback to the playback head minus `getLatency()`), so they already delay video by the BT latency. Our extra offset on BT is therefore only capture + processing + (our output path − the original's output path). The 150–250 ms of A2DP latency cancels. The same holds for any route where both tracks end at the same device.

### Cited Findings
- AOSP Bluetooth audio HAL `out_calculate_feeding_delay_ms()`: "delay_report is the audio delay from the remote headset receiving data to the headset playing sound". It reads `GetPresentationPosition(&delay_report_ns, &absorbed_bytes, &absorbed_timestamp)` and accepts it if `kMinimumDelayMs (50) < delay < kMaximumDelayMs (1000)`. Otherwise it falls back to `frames_count_*1000/sample_rate_ + kExtraAudioSyncMs` with `kExtraAudioSyncMs = 200`. Then "suppose frames would be queued in the headset buffer for delay_report period, so those frames in buffers should not be included in the number of presented frames": `*frames -= latency_frames`. `out_get_latency_ms()` returns the same delay (stream_apis.cc lines 41–43, 51–125, 489–494) — [AOSP packages/modules/Bluetooth system/audio_bluetooth_hw/stream_apis.cc](https://android.googlesource.com/platform/packages/modules/Bluetooth/+/refs/heads/main/system/audio_bluetooth_hw/stream_apis.cc) **[from source]**
- Media3 `AudioTrackPositionTracker`: "If the device supports it, use the playback timestamp from AudioTrack.getTimestamp. Otherwise, derive a smoothed position by sampling the track's frame position." (`useGetTimestampMode = audioTimestampPoller.hasAdvancingTimestamp()`, lines 243–249). In fallback mode it calls the hidden `AudioTrack.getLatency()` by reflection: "Compute the audio track latency, excluding the latency due to the buffer (leaving latency due to the mixer and audio hardware driver)": `latencyUs = getLatency()*1000 − bufferSizeUs`, rejected if > 10 s (`MAX_LATENCY_US`). Then `positionUs = max(0, positionUs − latencyUs)` (lines 106, 423–468) — [Media3 AudioTrackPositionTracker.java](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/audio/AudioTrackPositionTracker.java) **[from source]**
- Media3 `DefaultAudioSink.getCurrentPositionUs()`: `positionUs = audioOutput.getPositionUs(); positionUs = min(positionUs, framesToDurationUs(getWrittenFrames())); return applySkipping(applyMediaPositionParameters(positionUs));` (lines 728–735). The audio renderer is the player's media clock, and the video renderer releases frames against it — [Media3 DefaultAudioSink.java](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/audio/DefaultAudioSink.java)
- AudioFlinger fetches the HAL presentation position every loop ("Always query HAL timestamp and update timestamp verifier", Threads.cpp around line 4745). That is the source of `AudioTrack.getTimestamp()` — [Threads.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/services/audioflinger/Threads.cpp)

### Inferences
- **On BT**, Δ = T_capture + T_model + margin + (L_ours − L_orig), and the A2DP/LE-Audio delay drops out because both tracks reach the same BT sink and the original app's timestamp already includes the delay report. This holds only while the original app's track is still **routed to the real device** (playback-capture plus a mute effect, as RootlessJamesDSP does). It does **not** hold in the "reroute" (LOOP_BACK) mode described in Section 4.
- Mute via a Volume effect or player volume (PlayerProxy.setVolume) keeps the original track running, so its timestamps stay valid. **Pausing or stopping** the original would break the app's clock. Muting is the right choice.
- **YouTube**: the Android app is closed source. It is widely understood to use an ExoPlayer-derived stack, but I found no primary source in this session. It should be assumed to compensate for device latency through `getTimestamp()` like Media3, but it **cannot** know about our extra Δ.

### Gaps
- Whether `getTimestamp()` on the A2DP **offload** path (the HAL in the DSP rather than the software BT HAL) applies the same delay-report subtraction depends on the vendor. The AIDL BT HAL `BluetoothAudioSession::GetPresentationPosition` was not opened.
- No measured A2DP delay-report values for specific headsets were collected. The 50–1000 ms validity window and the 200 ms fallback are code constants.

---

## 4. Can other apps' video be made to compensate on Android?

### Takeaway
**Rootless: no.** There is no public or hidden API for an app to raise another app's reported latency. **Shell/Shizuku:** you can **reroute** apps with an AudioPolicy `ROUTE_FLAG_LOOP_BACK` mix, as scrcpy does. The victim app's timestamp then comes from the submix HAL, which subtracts the frames still in the pipe, so the app automatically compensates for the pipe (~59 ms) but no longer sees speaker or Bluetooth latency. That gives a better result on wired or speaker output and a worse one on BT. **Root:** a primary-HAL wrapper or custom HAL that reports `get_latency` and `get_presentation_position` lagged by the model delay makes **every** app (ExoPlayer, YouTube, browsers) compensate. This is the only full fix. AudioFlinger has a built-in "downstream software-patch latency" correction, but it is wired only for MSD/`AUDIO_DEVICE_OUT_BUS` devices behind a system property.

### Cited Findings
- **Submix presentation position subtracts pipe content** (what an app routed to the submix sees). Legacy: `*frames = out->frames_written - frames_in_pipe` (audio_hw.cpp lines 845–877). AIDL: `refinePosition()`: for output, `position->frames -= framesInPipe` (StreamRemoteSubmix.cpp lines 167–181) — [audio_hw.cpp](https://android.googlesource.com/platform/hardware/libhardware/+/refs/heads/main/modules/audio_remote_submix/audio_hw.cpp), [StreamRemoteSubmix.cpp](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/r_submix/StreamRemoteSubmix.cpp) **[from source]**
- scrcpy registers the AudioPolicy with `"ROUTE_FLAG_LOOP_BACK_RENDER"` when keeping playback on the device and `"ROUTE_FLAG_LOOP_BACK"` otherwise (reroute, so the device goes silent) (`AudioPlaybackCapture.java` line 89), running as the shell user — [scrcpy AudioPlaybackCapture.java](https://github.com/Genymobile/scrcpy/blob/master/server/src/main/java/com/genymobile/scrcpy/audio/AudioPlaybackCapture.java). AOSP `AudioPolicy.Builder.setMediaProjection()`: "A MediaProjection that can project audio allows to register an audio policy LOOPBACK|RENDER **without** the MODIFY_AUDIO_ROUTING permission". Plain LOOPBACK (reroute) requires MODIFY_AUDIO_ROUTING — earlier notes, `android_rootless_interception.md` (AOSP AudioPolicy.java).
- **AudioFlinger downstream-latency correction** (Threads.cpp lines ~4115–4147): "If the device is AUDIO_DEVICE_OUT_BUS, check for downstream latency." It reads `getDownstreamSoftwarePatches(...)` and `swPatches[0].getLatencyMs_l(&latencyMs)`, clamped to 0–5000 ms and averaged in `mDownstreamLatencyStatMs`. Lines ~4766–4776: "Note: Downstream latency only added if timestamp correction enabled." `timestamp.mPosition[KERNEL] -= mean(downstreamLatency) * sampleRate`. Enabling is controlled by `property_get_int64("audio.timestamp.corrected_output_device", mIsMsdDevice ? AUDIO_DEVICE_OUT_BUS : AUDIO_DEVICE_NONE)` (lines ~2228–2232), and `isTimestampCorrectionEnabled_l()` requires that device to be the thread's output device (Threads.h line 1161) — [Threads.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/services/audioflinger/Threads.cpp), [Threads.h](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/services/audioflinger/Threads.h) **[from source]**
- Media3 subtracts `AudioTrack.getLatency()` only in the non-timestamp fallback and trusts `getTimestamp()` otherwise (Section 3). A HAL that delays its presentation position is therefore what makes ExoPlayer-class apps compensate — [AudioTrackPositionTracker.java](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/audio/AudioTrackPositionTracker.java)

### Inferences
- **Shell/Shizuku reroute mode** (an AudioMixingRule matching UIDs or usages with LOOP_BACK, read by a shell-UID process the way scrcpy does):
  - The original is truly silenced, so the volume-effect mute hack and its "<250 ms double audio" window go away.
  - The app's clock is pipe-compensated, giving Δ ≈ RecordThread granularity (≤ 21 ms) + T_model + margin + L_ours (our full output latency, including speaker or BT).
  - Wired or speaker: Δ ≈ 10 + 30 + 10 + 15 ≈ **~65 ms best case [estimate]**. That is better than the ~90–130 ms of playback-capture mode.
  - Bluetooth: L_ours includes about 150–250 ms of A2DP delay that the app no longer sees, so Δ gets much worse. **Choose the mode by output route:** reroute on wired or speaker, capture-plus-mute on BT.
  - Note: the earlier project notes argued a Shizuku app cannot capture as the shell user. However, a Shizuku *UserService* runs in a shell-UID `app_process` like scrcpy's server, so the scrcpy technique (FakeContext with package `com.android.shell`) should carry over. This is unverified and needs a prototype.
- **Root options, best first:**
  1. **Audio HAL shim** (wrap the vendor primary HAL, or replace the remote submix with a small-pipe build). Run the model inside the HAL write path, or delay-line it, and report `get_latency()` + D and `get_presentation_position()` − D·fs. Every app then compensates exactly, because getTimestamp reflects it. This also removes the 58.7 ms pipe entirely.
  2. A **rebuilt r_submix** with `kDefaultPipeSizeInFrames` = 1024 and period count 4 gives a 21.3 ms pipe with ~14.7 ms setpoint (via a Magisk module overlaying `audio.r_submix.default.so` or the AIDL module). That cuts T_capture by about 45 ms, with no compensation.
  3. The **MSD/BUS downstream-patch** mechanism (`setprop audio.timestamp.corrected_output_device`) already does "subtract downstream processing latency from app timestamps", but it requires a BUS output device plus a software patch. That is automotive-style plumbing and impractical on phones.
- I found nothing showing that the AudioFlinger **effect framework** propagates an effect's processing latency into track timestamps. Insert effects (the JamesDSP/Wavelet style) appear to be latency-unaware; see Gaps.

### Gaps
- Not verified: whether `audio_policy_configuration.xml` mix or device ports have a usable "latency" attribute. I found no evidence, and the downloaded Threads.cpp uses HAL-reported latency only. Also not verified: whether AIDL effect descriptors (Android 14+) carry a processing-latency field that AudioFlinger uses.
- No public project was found that ships a latency-reporting HAL shim for this purpose. Viper4Android and JamesDSP use effects, not HAL shims.

---

## 5. Our own player (Media3 ExoPlayer plus a buffering AudioProcessor): perfect-sync design for a share-target player

### Takeaway
`DefaultAudioSink` derives media time from **output frames actually played** by the AudioTrack. It maps them back through `getMediaDuration()` (for speed changes) and skipped-silence counts. It has **no notion of processor latency**. A processor that emits D frames of start-up silence or "latency padding" would make audio late by D. A processor that **does not emit its look-ahead priming**, i.e. output frame k corresponds to input frame k, gives **sample-exact sync whatever the model latency**. The model latency then only adds to start-up and seek time, because ExoPlayer decodes ahead of real time. This is the only setting where Δ = 0 is achievable on Android.

### Cited Findings
- `getCurrentPositionUs`: `positionUs = audioOutput.getPositionUs(); positionUs = min(positionUs, framesToDurationUs(getWrittenFrames()))`. `getWrittenFrames()` = `writtenPcmBytes / outputPcmFrameSize` (frames after processors). `getSubmittedFrames()` = `submittedPcmBytes / inputPcmFrameSize` (DefaultAudioSink.java lines 728–735, 1825–1835) — [DefaultAudioSink.java](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/audio/DefaultAudioSink.java)
- `applyMediaPositionParameters()` turns playout duration into media duration with `audioProcessorChain.getMediaDuration(playoutDurationSinceLastCheckpointUs)`, which accounts for Sonic speed changes only. `applySkipping()` adds `audioProcessorChain.getSkippedOutputFrameCount()` (silence skipping). Neither has a latency or delay term (lines 1765–1810).
- The `AudioProcessor` interface has `getDurationAfterProcessorApplied(long durationUs)` ("Returns the expected duration of the output stream when the processor is applied", default identity, line 280), plus `queueEndOfStream()` / `isEnded()` / `flush(StreamMetadata)`. There is **no latency getter** — [AudioProcessor.java](https://github.com/androidx/media/blob/release/libraries/common/src/main/java/androidx/media3/common/audio/AudioProcessor.java)
- Encoder delay and padding are handled by trimming (`TrimmingAudioProcessor`, `inputFormat.encoderDelay`, `encoderPadding`; DefaultAudioSink line ~770, 1038). This is the same "drop the priming samples" pattern a latency-bearing processor should follow — [DefaultAudioSink.java](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/audio/DefaultAudioSink.java)

### Inferences — design rules for a perfect-sync share-target player
1. **Make the processor delay-compensated:** after `flush()`, swallow the first D = (window − hop + lookahead·hop) output samples. Do not output zeros for them. On `queueEndOfStream()`, push D samples of zeros through the model so the tail drains, then report `isEnded()`. Output then lines up sample-for-sample with input, so the sink's frame-count clock is correct. Δ = 0 by construction, and BT and device latency are still handled by `getTimestamp()`.
2. Keep `getDurationAfterProcessorApplied` as identity, since output length = input length.
3. **Decouple compute from the playback thread:** `queueInput` copies into a ring buffer, a worker thread runs inference, and `getOutput` returns whatever is ready (possibly empty). ExoPlayer tolerates a processor that returns no output yet. The sink keeps about 100–250 ms queued in the AudioTrack, which absorbs inference jitter. Throughput must be > 1× real time with headroom. Latency does not matter for sync.
4. Seeks and `flush()`: reset model state (GRU/LSTM hidden state) and the priming counter. Expect about D + one inference of extra start-up time per seek. That is invisible next to network buffering.
5. Speed changes: put our processor **before** Sonic in the chain so the model always sees 1× audio, or accept Sonic's mapping. Media3 handles Sonic's media and playout mapping itself.
6. Fallback if a model cannot be made output-aligned: delay **video** by D. The only sanctioned hook is the audio clock. A custom `AudioSink` wrapper (`ForwardingAudioSink`) whose `getCurrentPositionUs()` returns `super − D` is the simplest way to tell the renderer about D. That is an inference from the API shape; I did not verify that `ForwardingAudioSink` exists in the current release.
7. For a share target (a URL or file shared from YouTube or a browser), this path gives **exact lip-sync on every output route**, at the cost of leaving the source app. It is the recommended mode for video content.

### Gaps
- No Media3 issue or doc stating guidance on latency-introducing AudioProcessors was retrieved. The rules above come from reading the source.

---

## 6. Desktop: latency reporting and whether players compensate

### Takeaway
- **Linux/PipeWire: yes, end-to-end.** filter-chain sums plugin latency ports and publishes `ProcessLatency`, PipeWire propagates `Latency` through the graph, `pw_stream_get_time().delay` includes it, and mpv's PipeWire output uses it. Chrome and Firefox read sink latency through the Pulse API.
- **PulseAudio `module-ladspa-sink`: no.** It ignores plugin latency (an explicit TODO in the source).
- **macOS: yes, with a virtual device (AudioServerPlugIn)** that reports `kAudioDevicePropertyLatency` and `kAudioStreamPropertyLatency`. Chrome and Firefox add those to their A/V clock. BlackHole reports 0. A **Core Audio process tap gives no compensation**: the tapped app keeps timing against the real device and never learns about our delay.
- **Windows: yes in principle, at driver level.** A WaveRT virtual render driver can report a presentation position that lags by the processing delay ("so upper layers can synchronize video"), and players using `IAudioClock` (Chrome) follow it. User-mode virtual cables (VB-CABLE-style) report their own buffer only.

### Cited Findings — Linux/PipeWire
- filter-graph latency propagation: a node port with `SPA_FGA_HINT_LATENCY` becomes `node->latency_index` (filter-graph.c lines 1582–1583). "calculate latency": each node's min/max latency = max over upstream links + `port->control_data[0]` of its latency port (lines 1847–1867). The graph exports a `"latency"` prop = (min+max)/2 (lines 275–305) — [PipeWire spa/plugins/filter-graph/filter-graph.c](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/filter-graph/filter-graph.c) **[from source]**
- module-filter-chain: on the graph's `"latency"` prop, `impl->process_latency.rate = (int32_t)latency; update_latencies(impl, true)` (lines 1889–1894). `update_latency()` adds `process_latency` into the port `Latency` and also publishes `SPA_PARAM_ProcessLatency` (lines 1455–1475). Builtin `convolver`, `delay` and `sofa` nodes take a `latency` config ("the latency introduced by the filter, default 0"; for convolver, "The extra latency in seconds to report") (doc comments lines 456–507, 768) — [module-filter-chain.c](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-filter-chain.c)
- PipeWire docs: ProcessLatency "is a per node property and applies to the latency introduced by the node logic itself". PipeWire "will automatically propagate Latency objects from ports to all linked ports in the graph", and "the Latency param will be updated with 1 extra quantum when they travel over an async link" — [PipeWire latency docs](https://docs.pipewire.org/page_latency.html). Manual override: `pw-cli set-param <id> ProcessLatency {rate: N}` — [Ardour forum](https://discourse.ardour.org/t/where-to-set-compensation-latency-pipewire/111425)
- Client side: `pw_stream_get_time_n()` adds the link latency into `time->delay` (`(min_quantum+max_quantum)/2*quantum + (min_rate+max_rate)/2 + ns`, stream.c lines 2495–2498) — [stream.c](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/pipewire/stream.c). mpv `ao_pipewire.c`: `end_time += MP_TIME_S_TO_NS(time.delay) * time.rate.num / time.rate.denom` (line 197). mpv's A/V sync therefore includes downstream graph latency — [mpv ao_pipewire.c](https://github.com/mpv-player/mpv/blob/master/audio/out/ao_pipewire.c). mpv `ao_pulse.c` uses `pa_stream_get_latency()` (line ~666) — [ao_pulse.c](https://github.com/mpv-player/mpv/blob/master/audio/out/ao_pulse.c).
- Chromium Linux: `GetHardwareLatency(pa_stream*)` calls `pa_stream_get_latency` (pulse_util.cc lines 427–431) — [Chromium pulse_util.cc](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/media/audio/pulse/pulse_util.cc)
- HushMic (DPDFNet in a filter-chain): "Processing adds 80 ms of latency... On PipeWire 1.6 and later, apps like OBS can compensate" — [HushMic README](https://raw.githubusercontent.com/Fovty/HushMic/main/README.md) (via earlier notes `linux_desktop_daemons.md`)
- PulseAudio `module-ladspa-sink.c` lines 20–21: "TODO: Some plugins cause latency, and some even report it by using a control out port. We don't currently use the latency information." `GET_LATENCY` = master sink latency + our sink-input's internal latency + resampler latency (lines 345–364) — [PulseAudio module-ladspa-sink.c](https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/blob/master/src/modules/module-ladspa-sink.c) **[from source]**

### Cited Findings — macOS
- BlackHole: `kAudioDevicePropertyLatency` → "the presentation latency of the device. For this device, the value is 0 due to the fact that it always vends silence" (`*outData = 0`). `kAudioDevicePropertySafetyOffset` → `kLatency_Frame_Size` (default 0) (BlackHole.c lines 235–236, 2661–2667, 2741–2745) — [BlackHole.c](https://github.com/ExistentialAudio/BlackHole/blob/master/BlackHole/BlackHole.c)
- Firefox (cubeb) `audiounit_get_device_presentation_latency()` returns `dev + stream`, i.e. `kAudioDevicePropertyLatency` + `kAudioStreamPropertyLatency` (cubeb_audiounit.cpp lines 3283–3306) — [cubeb_audiounit.cpp](https://github.com/mozilla/cubeb/blob/master/src/cubeb_audiounit.cpp)
- Chromium macOS: `CoreAudioUtilMac::GetHardwareLatency()` reads `kAudioDevicePropertyLatency` (line ~520) and `kAudioStreamPropertyLatency` (line ~546), used by the AUHAL output stream (`hardware_latency_ = CoreAudioUtilMac::GetHardwareLatency(...)`, audio_auhal.cc line 253) — [core_audio_util_mac.cc](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/media/audio/mac/core_audio_util_mac.cc), [audio_auhal.cc](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/media/audio/apple/audio_auhal.cc)
- Apple mailing list: the output latency property should be the time between when audio is "consumed" by the AudioServerPlugIn and when it "hits the speaker" — [coreaudio-api 2015-04 "AudioServer plugin: how to calculate latency?"](https://lists.apple.com/archives/coreaudio-api/2015/Apr/msg00058.html)
- Core Audio taps: `CATapMuteBehavior.muted` / `.mutedWhenTapped` silence the source process's hardware output while the tap is read — [Apple: CATapMuteBehavior](https://developer.apple.com/documentation/coreaudio/catapmutebehavior) (via earlier notes `windows_macos_system_audio.md`)

### Cited Findings — Windows
- `IMiniportWaveRTOutputStream::GetOutputStreamPresentationPosition` fills `KSAUDIO_PRESENTATION_POSITION` "about samples presented at the output of the system". The OS may "periodically get this property... so upper layers can synchronize video or other activity with the audio". Windows 10+ — [Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/portcls/nf-portcls-iminiportwavertoutputstream-getoutputstreampresentationposition); see also [KSPROPERTY_RTAUDIO_PRESENTATION_POSITION](https://learn.microsoft.com/en-sg/WINDOWS-HARDWARE/DRIVERS/audio/ksproperty-rtaudio-presentation-position)
- `IAudioProcessingObject::GetLatency`: "the amount of time it takes a frame to traverse the processing pass of an APO" (HNSTIME). "To get the total latency of the entire audio signal processing stream, the client must query every APO in the processing chain and add up the results." — [Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/audioenginebaseapo/nf-audioenginebaseapo-iaudioprocessingobject-getlatency)
- Chromium Windows output computes delay from `IAudioClock::GetPosition(&device_position, &qpc_position)` (audio_low_latency_output_win.cc lines ~957–986) — [Chromium audio_low_latency_output_win.cc](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/media/audio/win/audio_low_latency_output_win.cc)
- VB-Audio: Voicemeeter's Virtual ASIO Insert "adds one buffer" — [VB-Audio forum](https://forum.vb-audio.com/viewtopic.php?p=4232) (via earlier notes)

### Inferences
- **Linux design:** ship the model as a LADSPA or LV2 plugin with a **latency control output port** (LV2 `lv2:reportsLatency`, LADSPA port named "latency") that reports D in samples. Load it in a `module-filter-chain` virtual sink. PipeWire then tells mpv (native) the true delay, plus Chrome, Firefox and OBS through pipewire-pulse. Those players will **fully compensate**: Δ ≈ 0 for players, though games and calls still hear D. Avoid PulseAudio `module-ladspa-sink` (no reporting) and avoid a separate pw-record/pw-play daemon, which costs two extra streams at a default of about 100 ms each and reports nothing.
- **macOS design:** for automatic compensation, use an **AudioServerPlugIn virtual output device** (a BlackHole-derived driver) that reports `kAudioDevicePropertyLatency` = D_model + (real device latency + safety offset + IO buffer) in frames. A companion process reads the device, runs the model and plays to the real output. Chrome and Firefox will compensate, and probably AVFoundation and Safari too (unverified, see Gaps). A Core Audio tap is simpler (no driver install), but every player shows Δ = full processing delay.
- **Windows design:** only a **kernel WaveRT virtual render driver** that reports a lagged presentation position or position register, or an **APO** whose `GetLatency` is honoured, can make players compensate. Both need a signed driver package. A user-mode loopback-plus-re-render design (WASAPI loopback, VB-CABLE-style) gives Δ = capture period + model + render buffer, uncompensated.
- Low-latency desktop numbers: PipeWire quantum 256 @48 kHz = 5.3 ms per hop, one extra quantum per async link, plus D_model. With compensation, players are perfect. Without it (taps or cables), Δ ≈ 10–20 ms of buffering + D_model **[estimate]**.

### Gaps
- Not confirmed in source this session: VLC's PipeWire/Pulse output use of the reported delay (VLC 3.x/4.x `pulse.c` / `pipewire.c` not opened), Firefox's `cubeb_pulse` latency use, OBS's handling, and how pipewire-pulse turns graph latency into `pa_stream_get_latency`. The HushMic README statement is the only direct evidence of compensation through pipewire-pulse.
- Not confirmed: AVPlayer/AVFoundation and Safari compensation for a virtual device's `kAudioDevicePropertyLatency` (no Apple doc found).
- Not confirmed: whether the Windows audio engine adds APO `GetLatency` into `IAudioClient::GetStreamLatency` or `IAudioClock` positions, and whether IAudioClock's position follows `GetOutputStreamPresentationPosition` for all render streams (only a mailing-list post describes the relationship).
- PulseAudio/PipeWire port latency offset (`pactl set-port-latency-offset`) is a possible compensation knob for non-PipeWire-native setups, but it was not verified in this session.

---

## 7. Low-latency model design: algorithmic latency at 48 kHz

### Takeaway
For STFT models, algorithmic latency ≈ **analysis window + look-ahead frames × hop**. Real-time scheduling adds about one hop of compute margin. Published causal options:
- 23 ms: HS-TasNet, RT-STT, and ADI at 0 look-ahead (11.6 ms frame).
- 40 ms: DeepFilterNet3 (20 ms window, 10 ms hop, 2-frame look-ahead).
- 92 ms: Band-SCNet (4096 window), whose SDR gain over the 23 ms models is about 2–3 dB.

At 48 kHz, a 1024-sample window / 512 hop (21.3 ms / 10.7 ms) with 0–1 look-ahead frames is the sweet spot: **~21–32 ms algorithmic, ~32–43 ms including compute margin.** Algorithmic latency counts fully in Δ on the system-wide path, but it costs nothing in the own-player path (Section 5).

### Cited Findings (from earlier project notes, which carry the primary links)
- DeepFilterNet3: 48 kHz, 20 ms window, 10 ms hop, 2-frame look-ahead, **40 ms** total; RTF 0.19 on an i5-8250U single thread — [arXiv 2305.08227](https://ar5iv.labs.arxiv.org/html/2305.08227). Its LADSPA build says "The minimum latency is 20 ms (STFT processing)" plus host latency — [DeepFilterNet ladspa README](https://github.com/Rikorose/DeepFilterNet/blob/main/ladspa/README.md)
- ADI causal TFC-TDF U-Net + deep filter: look-ahead Q=0 → 0 ms, Q=2 → 23.2 ms (11.6 ms frames); 131 K params; 10.43 ms per 11.6 ms frame on a 1 GHz SHARC-FX — [arXiv 2609.12201](https://arxiv.org/html/2609.12201v1)
- HS-TasNet: **23 ms** (1024 window / 512 hop at 44.1 kHz); "average inference time on 4 CPU cores should be less than 50% of the hop size" — [L-Acoustics PDF](https://www.l-acoustics.com/wp-content/uploads/2024/04/real_time_demixer_2024_04_19.pdf)
- RT-STT: 23 ms, 383 K params; fp16 brought GPU time from 5.8 to 1.01 ms per 1024 samples — [arXiv 2511.13146](https://arxiv.org/html/2511.13146)
- Online Band-SCNet: 4096 window / 1024 hop "causes a latency of 92 ms"; 2.59 M params; vocals SDR 8.74 dB — [Interspeech 2025 PDF](https://www.isca-archive.org/interspeech_2025/yang25d_interspeech.pdf)
- PercepNet: 10 ms frames + 40 ms look-ahead — [arXiv 2008.04259](https://arxiv.org/pdf/2008.04259)

### Inferences
- **Arithmetic at 48 kHz [from definitions]:**
  - 512 window / 256 hop = 10.7 ms + 0 look-ahead.
  - 960/480 (DFN-style) = 20 ms; with 2 look-ahead frames = 40 ms.
  - 1024/512 = 21.3 ms; with 1 look-ahead frame = 32 ms.
  - 2048/1024 = 42.7 ms.
  - 4096/1024 = 85.3 ms (+ hop ≈ 92 ms at 44.1 kHz in the paper's framing).
- Asymmetric analysis/synthesis windows (a long analysis window with a short synthesis window) can bring the output latency down to about hop + short synthesis window (~5–10 ms) while keeping frequency resolution. This is a known technique, but no music-separation model using it was found. **[estimate]**
- Waveform or encoder-based models (Conv-TasNet-style with a 2–5 ms encoder) have tiny algorithmic latency, but they need per-block inference every few ms. Phone NPUs dislike tiny batches, so a practical block is 5–10 ms, and the scheduling margin dominates. **[estimate]**
- **Look-ahead is the knob that trades quality for sync.** On system-wide paths prefer 0–1 frames. In the own-player path, use the highest-quality model the device can run at more than 1.3× real time, since its latency is free there.

### Gaps
- No public weights exist for causal music-separation models at 23 ms (see earlier notes). Real phone NPU inference times per 10 ms hop for these models were not found.

---

## 8. Per-platform latency budget and design rules

### Takeaway
Only three setups give truly in-sync video. Everything else sits around 60–150 ms on a good day:
1. Our own player on Android or iOS (Δ = 0 by design).
2. A PipeWire filter-chain with a reported latency port (players compensate).
3. Platform drivers that report the delay: a macOS AudioServerPlugIn, a Windows WaveRT driver, or a root HAL shim on Android.

### Budget table (Δ = uncompensated audio lag that the viewer sees). Labels: [S] = from source constants, [M] = measured, [E] = estimate

| Platform / route | Capture | Model (algorithmic + margin) | Output | Compensation by player | Δ best case | Δ typical |
|---|---|---|---|---|---|---|
| Android rootless, playback-capture + mute effect (speaker/wired/BT) | pipe ≈ 58.7 ms avg [S] (≤ 85.3) + ≤ 21.3 ms period [S] | 21–43 ms [E] | low-latency track 5–20 ms, minus the deep-buffer gain [E] | Device and BT latency only (cancels) [S] | **~90–130 ms** [E] | 150–300 ms [E]; **~500 ms** RootlessJamesDSP [M] |
| Android shell/Shizuku, LOOP_BACK reroute, wired/speaker | ≤ 21.3 ms period (pipe is compensated) [S] | 21–43 ms | 5–20 ms + device | Pipe only [S] | **~50–80 ms** [E] | 100–150 ms [E] |
| Android shell/Shizuku reroute, **Bluetooth** | as above | 21–43 ms | + 150–250 ms A2DP (not compensated) | Pipe only | ~200 ms+ [E] | 250–350 ms [E] |
| Android root: HAL shim reporting D | 0 (in-HAL) | 21–43 ms | in HAL | **Full** (getTimestamp) | **≈ 0** [E] | ≈ 0–20 ms |
| Android root: rebuilt r_submix (1024-frame pipe) | ≈ 14.7 ms avg + period [E] | 21–43 ms | 5–20 ms | Device only | ~45–70 ms [E] | 80–120 ms |
| Android own player (Media3, aligned processor) | n/a | hidden (pre-decode) | normal | **Full** [S] | **0** | 0 |
| Linux PipeWire filter-chain + latency port | 1 quantum (5.3 ms @256) [E] | 21–43 ms | 1 quantum + device | **Full** for mpv (verified), Chrome/Firefox/OBS via Pulse API (partly verified) | **≈ 0** for players | ≈ 0; non-compensating apps see ~30–55 ms |
| Linux PulseAudio module-ladspa-sink | – | 21–43 ms | sink | **None** for plugin latency [S] | 21–43 ms | 40–80 ms |
| Linux daemon pw-record → model → pw-play | 100 ms default each way unless `--latency` set | 21–43 ms | ≥ 1 quantum | None | ~35–60 ms (tuned) [E] | 200+ ms (defaults) |
| macOS AudioServerPlugIn reporting latency | IO buffer (128–512 frames = 2.7–10.7 ms) | 21–43 ms | IO buffer | **Full** for Chrome/Firefox [S]; AVFoundation unverified | ≈ 0 (browsers) | ≈ 0–30 ms |
| macOS Core Audio process tap + re-render | aggregate IO buffer | 21–43 ms | IO buffer | **None** | ~30–60 ms [E] | 60–120 ms (100 ms default buffers seen) |
| Windows WaveRT virtual driver reporting presentation position | engine period (~10 ms) [E] | 21–43 ms | ~10 ms | **Full** for IAudioClock users (Chrome) if the engine passes it through (unverified) | ≈ 0 | ≈ 0–30 ms |
| Windows user-mode cable/loopback + re-render | ~10 ms [E] | 21–43 ms | ~10 ms | None | ~40–65 ms [E] | 80–150 ms |

### Concrete design rules (inferences from the findings above)
1. **Targets:** Δ ≤ 45 ms (invisible), Δ ≤ 125 ms (hard ceiling), never audio-early by more than 15 ms. Any reported compensation must be ≤ the true delay.
2. **Prefer "report the delay" over "minimise the delay"** wherever the platform has a channel for it: PipeWire latency port, AudioServerPlugIn `kAudioDevicePropertyLatency`, WaveRT presentation position, Android HAL shim. Compensated delay costs nothing for video.
3. **Android rootless is uncompensatable:** budget about 60–85 ms for capture alone, use a 0–1 look-ahead model (≤ ~32 ms algorithmic), do inference within half a hop, and open the output as **low-latency** (Oboe LowLatency/Exclusive → MMAP), never a blocking Java AudioTrack with large buffers. Read the capture in ≤ 1-hop chunks and drop rather than queue when behind.
4. **Keep the original muted, not paused**, so the original app's clock keeps including device and BT latency (it then cancels from Δ). On BT, never reroute (LOOP_BACK), because that throws away the app's knowledge of the A2DP delay.
5. **Route-aware mode switching on shell/Shizuku:** LOOP_BACK reroute on speaker or wired (pipe gets compensated), capture-plus-mute on Bluetooth.
6. **Offer a "watch in our player" share target for video**, using Media3 with a delay-aligned AudioProcessor: drop D priming samples, drain D at end of stream, reset on flush, infer on a worker thread. This gives sample-exact sync on every route and allows a heavier model.
7. **Auto-measure Δ** at runtime: compare the capture-side timestamps (`AudioRecord.getTimestamp`) with the output `AudioTrack.getTimestamp` to show the user the current lag. If Δ > 125 ms, warn or auto-bypass video apps (RootlessJamesDSP's exclusion-list approach).
8. **Model choice per path:** system-wide paths use ≤ 32 ms algorithmic latency (DFN-class at 10 ms hop, ADI/RT-STT-class at 11.6–23 ms). Own-player and file paths can use 92 ms-class or offline models.

### Gaps
- Most Δ values in the table are estimates built from source constants. Only RootlessJamesDSP's ~500 ms and scrcpy's ~20 ms block period are field measurements. A loopback measurement rig is needed: a phone camera filming the screen plus a click track, or an OboeTester-style tap test through the capture path.
