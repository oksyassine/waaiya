# Windows and macOS ports: scope (not implemented)

Date: 2026-11-09. Scope only: nothing here has been built or run on Windows or macOS. It builds on
`reports/System wide instrument muting app.md` (desktop section) and its source notes in
`research_notes/System wide instrument muting app/windows_macos_system_audio.md`. Those notes are not repeated
here. This report adds new checks, latency budgets, effort figures and a test plan.

## Summary

**macOS: the path is clear.** Use a Core Audio process tap set to mute, read through a private aggregate
device. The app runs the engine in the device IO callback and writes the result to the real output in the
same cycle. It needs no driver, no admin rights and no reboot. It does need a Developer ID signature,
notarization and one "System Audio Recording" prompt. Target macOS 14.4+. Estimated added delay: 45–60 ms.
Estimated effort: 18–27 developer-days to an MVP. The main risk is fail-open on crash. When the app dies,
the tap goes away and unfiltered audio plays until launchd restarts the app.

**Windows: start with a cheap test, then pick one of two routes.** Microsoft's per-app mute cannot be used
the way Android uses muting. A 2026 test found that process-loopback capture of a muted session is digital
silence, and that the capture follows the session's volume exactly ([spytify PR #641](https://github.com/spytify/spytify/pull/641)).
That leads to an untested, driverless idea: **attenuate** every other app's session to about −80 dB instead
of muting it. Capture all other apps with process loopback, add the gain back in float, filter, and render.
It needs no driver and no admin rights, and its estimated delay is 60–75 ms. A 1–2 day CI test can confirm
or kill it. If it fails, the fallback is a virtual-device bridge, as on Linux. To start, users install
VB-CABLE themselves. Later the project ships its own signed driver, which costs an EV certificate and a
Partner Center account. Neither our own APO nor shipping as an Equalizer APO plugin is recommended. Each
fails on signing, robustness or install friction (details below). Estimated effort: 20–28 developer-days
to an MVP, plus 20–30 if the project's own driver is needed.

**Shared code.** All of `engine/` (C11 plus the ONNX Runtime C API) carries over. It needs about 30 lines
of `#ifdef`, chiefly for Unicode file paths on Windows. CPU inference matches Linux (RTF 0.26 stereo or
0.13 with `mono_mix` on one i7-1185G7 thread). GPU and NPU execution providers are not worth it for a
10 ms batch-1 stateful model.

## 1. What the ports must preserve

| Requirement | Linux today | Target on Windows/macOS |
|---|---|---|
| Added delay | 40 ms engine; 59 ms end to end, measured (`linux/test_run.sh`) | ≤ 60–75 ms, under the 125 ms ITU-R BT.1359 detection point (see `reports/Instrument muting hosting gender sync.md`) |
| Always on | systemd user unit, restart on crash | Login item / LaunchAgent (mac), per-user autostart (Windows), watchdog |
| Fail-closed | a dead filter means silence, because apps play into the null sink | Same goal; each route below states what a crash does |
| Women's-singing policy | `im_engine_set_policy` | Same API, no change |

## 2. Windows

### 2.1 Options compared

| Option | Silences the original? | Added delay (estimate) | Install friction / admin | Signing | On crash | Maintenance | Verdict |
|---|---|---|---|---|---|---|---|
| A. Own APO (SFX/MFX/EFX) | Yes, in-graph | ~40 ms (engine only) | Driver package per audio device | APO DLL must load in protected `audiodg.exe`; test-signed APOs need `DisableProtectedAudioDG` | Windows disables effects after 10 load failures, so fail-open | Very high | **Reject** |
| B. Plugin inside Equalizer APO (VST2 or a fork) | Yes, in-graph | ~40–50 ms | User installs Equalizer APO (admin, configurator per device, reboot) | Avoids our signing; relies on `DisableProtectedAudioDG` | Same fail-open risk; exclusive mode bypasses | High (breaks with updates) | Not for the MVP; optional power-user build |
| C1. Per-app **mute** via `IAudioSessionManager2` + process loopback | Yes, but the capture goes silent too | n/a | None | User-mode only | n/a | n/a | **Does not work** (tested by spytify) |
| C2. Per-app **attenuation** (about 1e-4) + process loopback of all other processes | Practically (−80 dB) | 60–75 ms | None; no admin | User-mode only | Volumes persist, so near-silence (fail-closed) | Medium | **MVP candidate, test first** |
| D1. Virtual device (user-installed VB-CABLE) + WASAPI bridge | Yes, by being the default device | 65–90 ms | User installs VB-CABLE once (admin, reboot) | None by us | Silence (fail-closed) | Medium | **Fallback MVP** |
| D2. Own virtual driver (SYSVAD-derived) + bridge | Yes | 50–75 ms; can report delay | Our installer (admin) | Kernel driver: EV cert + Partner Center attestation | Silence | High (kernel code) | Long-term option |

### 2.2 A. Our own APO: not feasible for a device-independent product

Since Windows 10 1809, an APO must be a component of a specific audio device's driver package. It "does not
allow for an APO to be registered globally" ([Microsoft: Implementing APOs](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects)).
Its real-time methods must not block or touch paged memory. An APO that is not "properly signed" fails to
load when the graph carries protected content. After 10 load failures, Windows sets
`PKEY_Endpoint_Disable_SysFx`, which turns effects off for that endpoint, so audio passes unfiltered (same
source). A test-signed APO needs a test-signing boot configuration plus `DisableProtectedAudioDG`. No
end-user product can ask for that. Even a paid EV-attested APO was reported failing to load in protected
`audiodg.exe` ([OSR thread](https://community.osr.com/t/apo-signing-and-installation/55812)).
**Conclusion: not feasible as unsigned or test-signed open-source software, and not device-independent even
when signed.**

### 2.3 B. Equalizer APO as host

Equalizer APO is the existing open-source APO host. The latest release is 1.4.2, from 21 March 2025
([SourceForge files](https://sourceforge.net/projects/equalizerapo/files/)). It works only because its
installer sets `DisableProtectedAudioDG=1` so that unsigned APOs load
([developer docs](https://sourceforge.net/p/equalizerapo/wiki/Developer%20documentation/)). Two routes:

- **VST plugin.** Equalizer APO loads only 64-bit VST2 DLLs ([itch.io post](https://itch.io/post/11306876)).
  Steinberg no longer licenses the VST2 SDK to new developers, so we would need clean-room VST2 headers,
  which is a legal grey area. The wrapper is small: it mirrors `linux/ladspa/im_ladspa.c` (150 lines).
- **Fork with a native filter.** This avoids VST2. Equalizer APO is GPL, so the fork must stay GPL.

Both routes share the same problems:

- The code runs inside `audiodg.exe` as LocalService, on the engine's real-time thread. It has no access to
  the user's profile, so the model must live under Program Files.
- `C:\Windows\System32\onnxruntime.dll` ships with Windows, and loaders have been seen picking it instead of
  the app's copy, which leads to entry-point errors or hangs
  ([vstest #4700](https://github-redirect.dependabot.com/microsoft/vstest/issues/4700),
  [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/2124577/how-to-reference-the-native-onnxruntime-dll-in-my)).
  The engine calls only `OrtGetApiBase`. It could load a renamed ORT DLL by full path and resolve that one
  symbol, which avoids the conflict on every Windows route.
- Exclusive-mode streams and hardware OpenAL bypass it.
- One project reports that the `DisableProtectedAudioDG` override stopped working on build 26200
  ([Veyra](https://github.com/NextGenDev-KSK/veyra/releases/tag/v1.0.0)). Equalizer APO tickets for 26200.7628
  are mixed: one user reports breakage after KB5078127 and another says it still works
  ([ticket list](https://sourceforge.net/p/equalizerapo/tickets/341)).
- Users must run the device configurator again after a new device appears or a feature update resets
  endpoints.

**Latency is the best of any Windows option** (engine 40 ms, processed in place). Install friction and
fragility rule it out as the default. It could become an optional "advanced" build later. Effort: 4–6 days
for the plugin, plus testing on a real PC.

### 2.4 C. Per-app session control (the Android mirror)

**Muting does not work.** spytify measured process loopback on a `windows-2022` GitHub runner with a Scream
virtual output. They found: "A muted session records digital silence, whether the mute comes before the
capture or during it." Volume 0.5 read exactly −6 dB in the capture, and a mute or volume setting persists
in the registry after the setting process exits ([spytify PR #641](https://github.com/spytify/spytify/pull/641)).
**Endpoint** (device) mute and volume, by contrast, act after process loopback
([EarPair PR #3](https://github.com/milkman-wang/EarPair/pull/3)). Muting the device would also silence our
own output, though, so it does not help on a single-output PC.

**Attenuation might work (hypothesis C2, untested).** If the capture scales linearly with session volume, as
spytify's −6 dB at 0.5 suggests, the design is:

1. Enumerate sessions on every render endpoint with `IAudioSessionManager2::GetSessionEnumerator`, and listen
   for new ones with `IAudioSessionNotification`.
2. Set every session except our own to `ISimpleAudioVolume::SetMasterVolume(1e-4)` (−80 dB), remembering the
   user's level.
3. Open one process-loopback capture in `PROCESS_LOOPBACK_MODE_EXCLUDE_TARGET_PROCESS_TREE` on our own PID.
   This gives the mix of all other apps ([AUDIOCLIENT_PROCESS_LOOPBACK_PARAMS](https://learn.microsoft.com/en-us/windows/win32/api/audioclientactivationparams/ns-audioclientactivationparams-audioclient_process_loopback_params)).
4. Multiply by 1e4. Float32 keeps about 24 bits of relative precision at any scale, so this should be close
   to lossless. Run the engine and render to the default device.

What makes it attractive:

- No driver, no admin rights and no default-device change.
- The endpoint volume keys still work.
- On a crash, the persisted −80 dB volumes act as fail-closed.

Risks to test:

- The scaling may be non-linear or clamped near zero.
- The Volume Mixer will show every app near zero, which will confuse users.
- An app that sets its own session volume will undo the attenuation, so we must re-assert it on
  `OnSimpleVolumeChanged`.
- New sessions leak for tens of ms until the notification arrives, much like the Android onset leak.
- Exclusive-mode streams bypass it.
- PlayReady-protected streams may be withheld from loopback, so those apps would go silent rather than
  filtered ([Microsoft: Loopback Recording](https://learn.microsoft.com/en-us/windows/win32/coreaudio/loopback-recording)).
- Windows version: the docs list Windows 10 build 20348 as the minimum for process loopback, while OBS ships
  application audio capture for Windows 10 2004+ and Windows 11
  ([OBS guide](https://obsproject.com/kb/application-audio-capture-guide)).

**This can be tested entirely in GitHub Actions**, because spytify's setup already runs there. That makes it
the first task.

### 2.5 D. Virtual device + user-mode bridge

This is the Linux null-sink design moved to Windows, and the pattern used by NVIDIA Broadcast, Krisp and
Veyra. A virtual render endpoint becomes the default. The bridge captures it, filters, and renders to the
real device. Plain WASAPI loopback cannot replace it, because loopback copies the mix "in addition to" the
hardware ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/coreaudio/loopback-recording)).

- **D1, user-installed VB-CABLE.** VB-CABLE is signed donationware. Bundling or redistributing it needs a
  separate agreement with VB-Audio ([VB-Audio licensing](https://vb-audio.com/Services/licensing.htm)). A
  link on the download page, with the user installing it themselves, avoids that. Our app needs no admin
  rights. Setting the default device in code uses the undocumented `IPolicyConfig`, or the user does it once
  by hand. Two extra jobs:
  - **Clock drift.** The cable runs on its own clock, so the bridge needs an adaptive resampler, for example
    the speexdsp resampler (BSD). PulseAudio handled this for us on Linux.
  - **Restoring the default device on uninstall.**
- **D2, our own driver.** [VirtualDrivers/Virtual-Audio-Driver](https://github.com/VirtualDrivers/Virtual-Audio-Driver)
  is MIT plus MS-PL (derived from SYSVAD). It is a beta that today needs test-signing. Scream (MS-PL) relies
  on old cross-signing, which needs Secure Boot off or a registry exception on clean installs
  ([Scream](https://github.com/duncanthrax/scream)). Shipping a driver to normal users means attestation
  signing through Partner Center, and that requires an EV certificate on the account
  ([Microsoft code-signing requirements](https://learn.microsoft.com/pl-pl/windows-hardware/drivers/dashboard/code-signing-reqs)).
  Azure Trusted/Artifact Signing does not cover drivers
  ([Microsoft Q&A, Apr 2026](https://learn.microsoft.com/en-us/answers/questions/5866910/hardware-program-verification-using-azures-trusted)).
  No user-mode API creates an endpoint that every app sees
  ([OSR](https://community.osr.com/t/seeking-assistance-how-to-create-virtual-input-and-output-devices-in-windows-11/59143)).
  The benefit of our own driver is that its WaveRT position can report the extra delay, so players could
  compensate.

**Latency.** The shared-mode default period is 10 ms. `IAudioClient3` allows 128 frames (2.67 ms) only when
the driver supports it ([IAudioClient3::InitializeSharedAudioStream](https://learn.microsoft.com/en-us/windows/win32/api/audioclient/nf-audioclient-iaudioclient3-initializesharedaudiostream)).
Estimate: 40 ms engine + 10 ms capture + 10–20 ms render + the cable buffer, giving 65–90 ms for VB-CABLE and
50–75 ms for our own driver. Apps pinned to a physical device bypass it (fail-open).

### 2.6 Windows recommendation

1. **Days 1–2, CI test of C2:**
   - Start `audiosrv` on a `windows-2022` or `windows-2025` runner, install Scream, and play a tone from
     PowerShell.
   - Set its session to 1e-4, capture with process loopback (exclude self) and multiply by 1e4.
   - Check linearity, the leak at session start, and what happens after the setting process is killed.
2. **If C2 holds:** build the C2 bridge as the MVP. Design the bridge with a pluggable source so that D1 and
   D2 reuse it:
   - capture thread → lock-free ring → engine (1 thread) → `IAudioClient3` render;
   - `IMMNotificationClient` to follow default-device changes;
   - tray app and per-user autostart (Run key or Task Scheduler);
   - settings, including the women's-singing toggle.
3. **If C2 fails:** build D1 (VB-CABLE bridge) as the MVP. Begin the EV-certificate and Partner Center
   process early, because it takes calendar time, in case D2 is wanted.
4. Sign the user-mode binaries with the SignPath Foundation's free OSS programme, which needs an
   OSI-licensed public repo ([SignPath OSS](https://about.signpath.io/product/open-source)). Without a
   signature, SmartScreen and Smart App Control warnings will block users (EarPair hit Smart App Control
   blocking its unsigned build). Ship with an Inno Setup or WiX installer and winget.

| Windows task | Developer-days |
|---|---|
| CI test of C2 | 1–2 |
| Bridge core (capture, ring, engine, render, device changes) | 5–7 |
| Session manager (enumerate, attenuate, restore, notifications) or, for D1, resampler + default-device handling | 3–5 |
| Tray UI, autostart, settings, watchdog | 3–4 |
| Installer, signing, winget | 2–3 |
| Real-hardware validation and fixes (needs a PC or testers) | 5–8 |
| **MVP total** (excluding the shared work in section 4) | **19–29** |
| Later: own signed driver (D2) | +20–30, plus EV cert and Partner Center lead time |
| Optional: Equalizer APO plugin build | +4–6 |

**Windows risks:**
- C2 rests on one third-party test.
- PlayReady and DRM behaviour is unknown on every route.
- Exclusive-mode apps are fail-open on C2 and B.
- Driver signing costs money and needs a legal entity for D2.
- `onnxruntime.dll` DLL-search conflicts.

## 3. macOS

### 3.1 Options compared

| Option | macOS versions | Silences original? | Added delay (estimate) | Signing / notarization | Prompts / admin | On crash | Verdict |
|---|---|---|---|---|---|---|---|
| T. Process tap (`AudioHardwareCreateProcessTap`), muted, global, excluding self | 14.2+ (14.4+ recommended) | Yes, while the tap is read | 45–60 ms | Developer ID + notarization; stable identity needed for TCC | One "System Audio Recording" prompt; no admin | Tap disappears, so unfiltered audio plays (fail-open) until restart | **MVP** |
| H. AudioServerPlugIn virtual device (BlackHole, libASPL or Apple's NullAudio sample) + bridge | 10.13+ (any supported) | Yes, as the default device | 50–65 ms; delay can be reported | Signed, notarized `.pkg`; macOS 26 may require a paid identity to load | Admin install to `/Library/Audio/Plug-Ins/HAL`, `coreaudiod` restart | Silence (fail-closed), but audio stays dead until the default device changes | Phase 2 / fallback |
| U. Our engine as an Audio Unit inside a third-party system-wide host (SoundSource, Audio Hijack, eqMac Pro) | Host's minimum (SoundSource: 15+) | Host's job | Host buffer + 40 ms | Notarized AU | Install AU, buy the host | Host's behaviour | Cheap extra, not the product |

### 3.2 T. Process taps

The design and its known pitfalls are covered in the earlier report and notes (Apple sample, DGR Labs 2026,
AudioCap). In short:

- **Setup.** Create a `CATapDescription` with `stereoGlobalTapButExcludeProcesses:[ourPID]` and set
  `muteBehavior = muted`. Build a private aggregate whose main sub-device is the real output, with the tap as
  a sub-tap and drift compensation on. Register an IOProc with `AudioDeviceCreateIOProcIDWithBlock`; it runs
  `im_engine_process_interleaved` on the input and writes the output buffers
  ([Apple sample](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps)).
- **Latency.** Set the aggregate buffer to 480 frames (one 10 ms hop) through `kAudioDevicePropertyBufferFrameSize`.
  DGR's default test used 4800 frames per callback
  ([DGR Labs](https://dgrlabs.co/blog/2026-04-25-capturing-system-audio-on-macos-in-2026.html)), so leaving
  the default would add about 100 ms. No measured tap latency has been published; measure it from the IOProc
  timestamps.
- **Real-time safety.** At an RTF near 0.13 per channel, one hop costs about 1.3 ms per channel on the Linux
  CPU, well inside a 10 ms callback. ORT can still allocate memory during `Run`. If profiling shows glitches,
  move the model to a worker thread with a lock-free ring, at the cost of one more hop of delay.
- **Permissions and signing:**
  - You need `NSAudioCaptureUsageDescription` in Info.plist, and the first `AudioDeviceStart` triggers the
    prompt.
  - No public API can check the grant, and a denied app receives zeros
    ([dev.to](https://dev.to/nickdelv/2000-buffers-of-nothing-3i8)), so detect "zeros while apps are
    playing".
  - TCC keys the grant to the signing identity, so ad-hoc builds lose it, or never get the prompt at all.
  - The sandbox is unreliable with taps, so ship outside the Mac App Store as a notarized Developer ID app.
  - Since macOS 15, unnotarized apps can only be opened from System Settings, Privacy & Security, "Open
    Anyway" ([AppleInsider](https://appleinsider.com/articles/24/08/06/apple-removes-control-click-option-for-skipping-gatekeeper-in-macos-sequoia)).
  - The Developer Program costs US$99 a year. Fee waivers exist for nonprofit organisations in some
    countries, but not for individuals ([MacRumors](https://www.macrumors.com/2018/01/03/apple-developer-program-fee-waivers)).
- **Always on.** Use a menu-bar app registered with `SMAppService`, or a LaunchAgent with `KeepAlive` to
  restart it fast. Whether the TCC grant persists for a LaunchAgent is untested.
- **Robustness work:**
  - Rebuild the aggregate when the default output changes (AirPods) and after sleep/wake.
  - Watch for all-zero buffers in long sessions and recreate the tap and aggregate when they appear
    ([Apple forum 825780](https://developer.apple.com/forums/thread/825780)).
  - Compensate the level drop on multi-channel devices
    ([Apple forum 806799](https://developer.apple.com/forums/thread/806799)).
- **Fail-open on crash.** Per ShutUpTheMac and spytify, the tap's mute "undoes itself when the tap goes
  away". The mitigations are a fast launchd restart, plus a test of whether a second, unread `muted` tap held
  by a tiny watchdog process keeps the source silent. Apple's text and ShutUpTheMac disagree on this point.

### 3.3 H. HAL virtual device (AudioServerPlugIn)

This is the pre-tap design, as used by Background Music and eqMac. It still matters for two reasons:

- It works on macOS 13 and earlier.
- The device can publish `kAudioDevicePropertyLatency` and a safety offset. In principle, players can then
  compensate the delay. Whether AVPlayer, Safari and Chrome actually do so is unverified
  ([coreaudio-api list](https://lists.apple.com/archives/coreaudio-api/2015/Apr/msg00058.html)).

Costs:
- Admin install and a `coreaudiod` restart.
- Our app has to manage the default device.
- Known fragility: a crash leaves system audio dead until the default changes
  ([Background Music](https://github.com/kyleneideck/BackgroundMusic)).
- Unclear loading rules on macOS 26. One project says a paid developer identity is required
  ([xcbuild/loopback](https://github.com/xcbuild/loopback)), and a Sonarworks user reports a Developer-ID
  driver that `coreaudiod` never loads
  ([Sonarworks](https://support.sonarworks.com/hc/en-us/community/posts/35929512552978-Fixing-CoreAudio-driver-went-missing)).

**Licences:**
- **BlackHole** is GPL-3.0, and "a license is required for all non-GPLv3 projects"
  ([BlackHole](https://github.com/ExistentialAudio/BlackHole)). The repo has **no LICENSE file yet**. A
  modified BlackHole is fine if the project picks GPL-3.0. That is compatible with ORT (MIT), DeepFilterNet
  (MIT/Apache-2.0) and EfficientAT (MIT). The driver is a separate program that talks through Core Audio, so
  an MIT app beside a GPL driver is arguably mere aggregation, but Existential Audio may see it differently.
- **libASPL** (MIT, C++17) or Apple's NullAudio sample avoid the question
  ([libASPL](https://github.com/gavv/libASPL)).

Recommendation: if H is built, base it on libASPL unless the project chooses GPL-3.0.

### 3.4 U. Audio Unit route

An Audio Unit cannot capture system audio by itself; it needs a host. Our own app cannot use AVAudioEngine
on a tap aggregate either ([DGR Labs](https://dgrlabs.co/blog/2026-04-25-capturing-system-audio-on-macos-in-2026.html)).
So this route is "ship an AUv2 effect" for people who already own SoundSource. SoundSource 6.1.6 applies Audio
Units per app and to all system audio on macOS 15–27 ([Rogue Amoeba](https://rogueamoeba.com/soundsource/)).
The plugin is a wrapper about the size of the LADSPA one, and it reports `kAudioUnitProperty_Latency`. The
cost is 3–5 days plus notarization. Worth doing after the MVP as a zero-capture-code option. It depends on a
paid third-party app, so it cannot be the product.

### 3.5 macOS recommendation

Build T as the MVP for macOS 14.4+ on arm64 and x86_64 (universal2).

| macOS task | Developer-days |
|---|---|
| Tap + aggregate + IOProc host calling the C engine (Swift or Obj-C) | 4–6 |
| Robustness: device change, sleep/wake, zero-buffer watchdog, permission UX, level fix | 4–6 |
| Menu-bar app, `SMAppService`/LaunchAgent, settings | 3–4 |
| Developer ID signing, notarytool in CI, DMG + Homebrew cask | 2–3 |
| Real-hardware validation and fixes (needs a Mac or testers) | 5–8 |
| **MVP total** (excluding the shared work in section 4) | **18–27** |
| Later: HAL device (H) on libASPL for older macOS and delay reporting | +15–25 |
| Optional: AUv2 plugin (U) | +3–5 |

**macOS risks:**
- Fail-open on crash.
- DRM audio (Safari FairPlay, the TV app) under a tap is undocumented and may arrive as silence.
- Long-session zero buffers on 26.x.
- A recurring $99 a year for signing.
- No public permission-status API.

## 4. Shared code and inference

### 4.1 What carries over

| Component | Lines | Reuse | Changes needed |
|---|---|---|---|
| `engine/src/im_engine.c`, `im_detector.c`, `engine/include/im_engine.h` | ~810 | ~100% | Windows passes `ORTCHAR_T*` (= `wchar_t*`) to `CreateSession`, so convert the UTF-8 path with `MultiByteToWideChar` at both call sites (`im_engine.c:181`, `im_detector.c:174`). Use `_wfopen` for `<model>.state_init.bin`. Non-ASCII user names, Arabic included, are likely among these users. Build with MSVC `/std:c11` (no VLAs are used), clang-cl or MinGW. Optionally load ORT by full path and resolve `OrtGetApiBase` (see 2.3). |
| `cli/im_process.c`, `wav.c` | ~150 | ~95% | Replace `clock_gettime` with C11 `timespec_get`. Becomes the cross-platform parity and RTF test tool in CI. |
| `cli/im_stream.c` | 78 | Test tool only | Uses `unistd` `read`/`write`; Windows needs `_setmode(..., _O_BINARY)`. Not used in the desktop data path, because the bridges call the engine in-process. |
| `linux/ladspa/im_ladspa.c` | 149 | Pattern only | Template for the AU and Equalizer APO wrappers. |
| `linux/bin/islamic-mute`, `test_run.sh` | | Design only | Watchdog and fail-closed policy. The cross-correlation delay measurement should become a small C or Python tool that runs in CI on all OSes. |
| `models/`, `eval/`, `testset/`, `kaggle/` | | 100% | Same ONNX files (int8 2.4 MB) on every OS. |
| `Makefile` | | Replace | Move to CMake (or keep the Makefile on Linux and add CMake for Windows/macOS). |

Shared work across both ports, done once: CMake, the Windows path fixes, CI matrix, golden-output fixtures
and the delay tool. Estimate 3–5 developer-days.

### 4.2 ONNX Runtime and execution providers

- **Binaries.** ORT publishes C API release archives for win-x64, win-arm64, osx-arm64, osx-x86_64 and
  universal2. The repo pins 1.19.2 for Linux. CI should fetch the same version, since the local disk has no
  room.
- **CPU (recommended everywhere).** On Linux, `im-process` measured RTF 0.262 stereo (two model instances)
  and 0.13 mono-equivalent on one i7-1185G7 thread. The int8 weights give the same speed
  (`eval/results/shrink.md`). x86 Windows should match, because MLAS kernels are the same. Apple Silicon runs
  MLAS NEON kernels; no figure exists yet, so measure on a `macos-latest` (arm64) runner. Always-on cost is
  about 13% of one core with `mono_mix`, or 26% stereo, plus 2% for the detector. Make `mono_mix` the
  laptop default.
- **DirectML.** It is in sustained engineering, with new work moved to Windows ML
  ([Microsoft](https://learn.microsoft.com/windows/ai/directml)). The DirectML EP requires sequential
  execution and no memory pattern ([ORT DML EP](https://onnxruntime.ai/docs/execution-providers/DirectML-ExecutionProvider.html)).
  For a batch-1 graph run every 10 ms with state tensors, the per-hop dispatch and copy overhead and the GPU
  wake-ups are likely to cost more latency jitter and battery than they save. Not recommended.
- **CoreML EP.** It is included in the macOS arm64 C packages. It recompiles the model unless
  `ModelCacheDirectory` is set, and its op coverage has limits (Slice parameters must be constant, for
  example) ([ORT CoreML EP](https://onnxruntime.ai/docs/execution-providers/CoreML-ExecutionProvider.html)).
  The DFN3 streaming graph's partitioning onto the ANE is unknown. Treat it as a later battery experiment,
  not an MVP path. The same goes for NPUs on Snapdragon Windows (QNN EP).

## 5. What can be tested without the hardware

| Test | Windows (GitHub Actions) | macOS (GitHub Actions) | Needs real hardware |
|---|---|---|---|
| Build engine, CLI, bridge app, installer | `windows-latest` (MSVC) | `macos-latest` (arm64, Xcode, universal2) | |
| Engine parity vs golden WAVs made on Linux | Yes (`im-process` + fixture) | Yes | |
| RTF on runner CPUs | Yes (noisy but indicative) | Yes | Final figures on laptops |
| Audio stack end to end with synthetic tones | Yes: `net start audiosrv` + Scream, as spytify and others do ([spytify](https://github.com/spytify/spytify/pull/641)); test C2 and the bridge, and measure delay by cross-correlation | Partly: `brew install blackhole-2ch` works on runners ([vim CI precedent](https://gerrit.omnirom.org/plugins/gitiles/android_external_vim/+/5d64e28011deab9881072c5e0905a099db536323%5E%21)) for H-style tests. The tap needs a TCC grant: vim's CI granted microphone access on macOS 14 runners, so the same may work for system-audio capture (unverified) | |
| Signing and notarization pipeline | SignPath in CI | notarytool in CI (needs the Apple account) | |
| Speaker and Bluetooth delay, glitches under load, sleep/wake, hot-plug, DRM players (Netflix, Apple TV, Spotify), exclusive-mode apps, 24 h soak, battery | | | **Yes** |

GitHub-hosted runners occasionally come up without audio devices
([runner-images issue](https://mscord.duckdns.org/actions/runner-images/issues/13668)), so audio CI jobs
should check for devices first and retry. Before any public release, find at least one volunteer tester per
OS. A rented cloud Mac has no audio output, so it would only help with builds.

## 6. Order of work

1. Shared: CMake, Windows path fixes, CI matrix with parity and RTF on all three OSes (3–5 days).
2. Windows CI test of C2 (1–2 days). This decides the Windows architecture cheaply.
3. macOS tap MVP (18–27 days). It is the clearest path and has no gating unknown.
4. Windows MVP on C2 or D1 (19–29 days).
5. Later: macOS HAL device with delay reporting, Windows own driver, the AU and Equalizer APO wrappers,
   CoreML/NPU experiments.

Total to two MVPs: about 41–61 developer-days, plus calendar time for real-hardware testing and, on Windows,
any driver-signing lead time.

## Sources added in this report
- [spytify PR #641: process loopback of a muted session](https://github.com/spytify/spytify/pull/641)
- [EarPair PR #3: process loopback before endpoint mute/volume](https://github.com/milkman-wang/EarPair/pull/3)
- [Microsoft: AUDIOCLIENT_PROCESS_LOOPBACK_PARAMS](https://learn.microsoft.com/en-us/windows/win32/api/audioclientactivationparams/ns-audioclientactivationparams-audioclient_process_loopback_params)
- [Microsoft: Loopback Recording](https://learn.microsoft.com/en-us/windows/win32/coreaudio/loopback-recording)
- [Microsoft: IAudioClient3::InitializeSharedAudioStream](https://learn.microsoft.com/en-us/windows/win32/api/audioclient/nf-audioclient-iaudioclient3-initializesharedaudiostream)
- [Microsoft: ISimpleAudioVolume::SetMute](https://learn.microsoft.com/en-us/windows/win32/api/audioclient/nf-audioclient-isimpleaudiovolume-setmute)
- [Microsoft: Implementing APOs](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects)
- [Microsoft: driver code-signing requirements](https://learn.microsoft.com/pl-pl/windows-hardware/drivers/dashboard/code-signing-reqs)
- [Microsoft Q&A: Trusted Signing not usable for hardware attestation](https://learn.microsoft.com/en-us/answers/questions/5866910/hardware-program-verification-using-azures-trusted)
- [Microsoft: code signing options (Artifact Signing, regions)](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options)
- [Microsoft: DirectML status](https://learn.microsoft.com/windows/ai/directml)
- [OBS: Application Audio Capture guide](https://obsproject.com/kb/application-audio-capture-guide)
- [OSR: virtual endpoints need a kernel driver](https://community.osr.com/t/seeking-assistance-how-to-create-virtual-input-and-output-devices-in-windows-11/59143)
- [OSR: APO signing and installation](https://community.osr.com/t/apo-signing-and-installation/55812)
- [Equalizer APO files (1.4.2, March 2025)](https://sourceforge.net/projects/equalizerapo/files/)
- [Equalizer APO developer documentation](https://sourceforge.net/p/equalizerapo/wiki/Developer%20documentation/)
- [Equalizer APO tickets (26200 reports)](https://sourceforge.net/p/equalizerapo/tickets/341)
- [Veyra v1.0.0](https://github.com/NextGenDev-KSK/veyra/releases/tag/v1.0.0)
- [VirtualDrivers/Virtual-Audio-Driver](https://github.com/VirtualDrivers/Virtual-Audio-Driver)
- [Scream](https://github.com/duncanthrax/scream)
- [VB-Audio licensing](https://vb-audio.com/Services/licensing.htm)
- [SignPath for open source](https://about.signpath.io/product/open-source)
- [vstest #4700: System32 onnxruntime.dll precedence](https://github-redirect.dependabot.com/microsoft/vstest/issues/4700)
- [Microsoft Q&A: System32 onnxruntime.dll](https://learn.microsoft.com/en-us/answers/questions/2124577/how-to-reference-the-native-onnxruntime-dll-in-my)
- [ORT DirectML EP](https://onnxruntime.ai/docs/execution-providers/DirectML-ExecutionProvider.html)
- [ORT CoreML EP](https://onnxruntime.ai/docs/execution-providers/CoreML-ExecutionProvider.html)
- [Apple: Capturing system audio with Core Audio taps](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps)
- [DGR Labs: Capturing system audio on macOS in 2026](https://dgrlabs.co/blog/2026-04-25-capturing-system-audio-on-macos-in-2026.html)
- [dev.to: 2000 buffers of nothing](https://dev.to/nickdelv/2000-buffers-of-nothing-3i8)
- [Apple forum 825780 (zero buffers)](https://developer.apple.com/forums/thread/825780)
- [Apple forum 806799 (multi-channel level drop)](https://developer.apple.com/forums/thread/806799)
- [BlackHole](https://github.com/ExistentialAudio/BlackHole)
- [libASPL](https://github.com/gavv/libASPL)
- [Background Music](https://github.com/kyleneideck/BackgroundMusic)
- [xcbuild/loopback (macOS 26 HAL loading claim)](https://github.com/xcbuild/loopback)
- [Sonarworks: Developer-ID driver not loaded on macOS 26](https://support.sonarworks.com/hc/en-us/community/posts/35929512552978-Fixing-CoreAudio-driver-went-missing)
- [coreaudio-api: AudioServerPlugIn latency](https://lists.apple.com/archives/coreaudio-api/2015/Apr/msg00058.html)
- [Rogue Amoeba SoundSource](https://rogueamoeba.com/soundsource/)
- [AppleInsider: Gatekeeper change in macOS 15](https://appleinsider.com/articles/24/08/06/apple-removes-control-click-option-for-skipping-gatekeeper-in-macos-sequoia)
- [MacRumors: Apple developer fee waivers](https://www.macrumors.com/2018/01/03/apple-developer-program-fee-waivers)
- [vim CI: BlackHole and TCC on macOS runners](https://gerrit.omnirom.org/plugins/gitiles/android_external_vim/+/5d64e28011deab9881072c5e0905a099db536323%5E%21)
- [runner-images issue: missing audio devices](https://mscord.duckdns.org/actions/runner-images/issues/13668)
