# Mute instruments system-wide on Android first

Build one on-device streaming voice filter, ship it first on rootless Android, and use a Linux PipeWire sink as the test rig from day one. macOS follows, then Windows. System-wide filtering on stock iOS is impossible, so iOS gets only link-based and in-browser features. No third-party app does this on a phone today: HaramMute is a cloud, YouTube-only, prepare-then-play service, Samsung's real-time Audio Eraser is private to One UI, and Moises Live, the closest match to the goal, runs only on Windows and Mac. The plumbing is largely solved, so the model is the harder problem: no causal (live-capable) vocals-versus-instruments model with public weights exists, so you ship a speech-enhancement model first and train your own model for the real product. Rootless Android will have real holes. Chrome, Spotify and SoundCloud block capture, and the one field report of capture delay is about 500 ms, well past the lip-sync limit for video. Two source checks done for this report improve the outlook: audio-only capture appears exempt from Android's stop-on-lock rule, and a Shizuku helper process runs with the shell privileges scrcpy uses. Both need on-device tests before anyone relies on them. Promise users "greatly reduced instruments on supported apps", never "music-free", because every shipping separator leaves residue.

## Nothing ships this today, but three products prove the parts

**HaramMute proves demand, not system-wide processing.** It takes a YouTube link, runs a cloud job, and plays a clean speech track in sync over the muted video ([haram-mute.com](https://haram-mute.com/)). Its privacy policy names Modal, a serverless GPU cloud, as the processing service ([HaramMute privacy policy](https://haram-mute.com/privacy)). It covers pre-recorded YouTube only, and the mobile apps hold no capture permissions. The free tier is 60 minutes a week on videos up to 15 minutes. The Chrome extension has **20,000 users** ([Chrome Web Store](https://chromewebstore.google.com/detail/harammute-remove-backgrou/bbkbpldbnkoncockinoapcmbiijejgpn)). Users report instruments left in a recitation video and audio that drifts from the picture ([Google Play](https://play.google.com/store/apps/details?id=com.harammute.mobile&hl=en)). The model is undisclosed.

**Samsung proves a phone can do real-time work on other apps' audio, including Netflix.** Since One UI 8.5, a Quick Settings tile processes YouTube, Instagram, Netflix and Prime Video on-device ([9to5Google](https://9to5google.com/2026/02/25/samsung-galaxy-audio-eraser-youtube/)). Hands-on reviews describe only a strength control and a Voice Focus toggle, aimed at background noise, with no mode for music or vocals ([Android Police](https://www.androidpolice.com/galaxy-s26-feature-changed-the-way-i-stream/)). No third-party SDK was found. That is absence of evidence, but nothing suggests you can call it.

**Moises Live is the best existence proof for the desktop goal.** It separates system audio into dialogue, effects and instruments in real time, on-device, with any app, on Windows and Mac ([Moises Live](https://moises.ai/products/live/)). It is a consumer app, not an engine you can license. Its page says it is not available on mobile and does not explain how it captures audio or whether it silences the original. Moises does work with partners: Blackstar's Beam amps gained real-time guitar separation on phones in 2026 ([MIA](https://www.mia.org.uk/2026/08/blackstar-announces-moises-integration-into-beam-products/)), and its developer link now redirects to the Music AI business platform ([Music AI](https://music.ai/)). That platform's page mentions no SDK or on-device option. One enquiry email is worthwhile, but do not plan around it.

**The Muslim-focused extension market is small and browser-bound.** NoMusic says it is "designed specifically for Muslims" and runs a speech-enhancement model in the browser, with about 1,000 users ([Chrome Web Store](https://chromewebstore.google.com/detail/nomusic-watch-any-video-w/fepfnjijcojaoihcekfhonohejglmdbc); [GitHub](https://github.com/mohamedsadiqaguenaou/NoMusic)). Music Remover by IqraWave pairs an extension with a local desktop app and has about 3,000 Chrome users ([Chrome Web Store](https://chromewebstore.google.com/detail/haram-music-remover-super/pljjgbebgcpplkcmggdemopekpennmfc)). Naqi is the most useful open reference: it gates Demucs with YAMNet on Android, offline, under GPL-3.0 ([Naqi](https://github.com/haithamassoli/NaqiHalalVideoFilter)). Which models the companion apps run is undisclosed; Demucs or UVR-class models are an inference only.

## The model decides whether instruments stay hidden

**First decide what "voice" means, because it selects the model family.** Speech-enhancement models keep speech and suppress everything else, so they treat music as noise. They are trained to "preserve primary speaker speech while suppressing everything else" ([Microsoft DNS Challenge](https://www.microsoft.com/en-us/research/academic-program/deep-noise-suppression-challenge-icassp-2023)). No source reports how much singing they retain. Keeping nasheed or sung recitation needs a vocals-versus-accompaniment separation model, which is heavier and has no released live weights. The product therefore needs two modes: Speech, available now, and Voice and singing, which comes later.

The table compares the candidates. SDR (signal-to-distortion ratio) measures how cleanly a stem is recovered, and higher is better. Causal means the model uses no future audio, so it can run live. Figures come from different test setups, so compare them loosely.

| Model | Job | Live-capable | Delay | Size and compute | Quality | Licence and weights |
|---|---|---|---|---|---|---|
| [DeepFilterNet3](https://ar5iv.labs.arxiv.org/html/2305.08227) | Speech vs noise, 48 kHz | Yes | 40 ms in paper, 20 ms in the LADSPA build | About 8 MB; RTF 0.15 on an unnamed Android device ([Soniqo](https://soniqo.audio/guides/denoise/android)) | No music or singing metric published | MIT/Apache, weights included ([GitHub](https://github.com/Rikorose/DeepFilterNet)) |
| [GTCRN](https://github.com/Xiaobin-Rong/gtcrn) | Speech vs noise, 16 kHz | Yes | Not stated | 48.2K parameters, 33 MMAC/s | No music metric; 16 kHz limits fidelity | MIT, weights public |
| [ADI causal U-Net](https://arxiv.org/html/2609.12201v1) | 4-stem music | Yes | 0 to 23.2 ms | 131K parameters, 1.89 GMAC/s | Vocals 5.09 dB cSDR | Weights "will be released" |
| [Band-SCNet](https://www.isca-archive.org/interspeech_2025/yang25d_interspeech.pdf) | 4-stem music | Yes | 92 ms | 2.59M parameters, 17.59 GFLOPs/s; RTF 0.478 on one desktop thread | Vocals 8.74 dB | Not released |
| [HS-TasNet-Small](https://www.l-acoustics.com/wp-content/uploads/2024/04/real_time_demixer_2024_04_19.pdf) | 4-stem music | Yes | 23 ms | 16M parameters | Vocals 5.01 dB | Not released |
| [HT Demucs](https://github.com/facebookresearch/demucs) | 4-stem music | No | 7.8 s segments | 41M parameters | Vocals 7.93 dB without extra data | Code MIT; weights disputed (see below) |
| [Mel-Band RoFormer](https://arxiv.org/pdf/2409.04702) | Vocals | No | Long context | 105M parameters | Vocals 12.08 dB | Community checkpoint stated MIT ([HF](https://huggingface.co/ai-toolkit/melbandroformer)) |
| [AudioShake](https://www.audioshake.ai/products/sdk) | Music removal, dialogue | Vendor claim | Under 50 ms claimed | Models from 9 MB claimed | Unverified vendor claims | Sales-gated; no public price |

**Every causal music-separation paper withholds weights, and none reports a phone measurement.** The notes' estimate of RTF 1 to 2 for Band-SCNet on one phone core is a scaling guess. RTF (real-time factor) is processing time divided by audio time, so anything at or above 1 cannot keep up. Quality is the deeper limit: in HS-TasNet's listening test, offline Demucs v4 scored significantly better than every real-time model ([L-Acoustics](https://www.l-acoustics.com/wp-content/uploads/2024/04/real_time_demixer_2024_04_19.pdf)). Expect audible instrument residue at these scores. You also cannot run an offline model on short chunks: ADI's chunk-trained model collapsed to silence within about 2 seconds when run frame by frame, so streaming state must be part of training ([arXiv 2609.12201](https://arxiv.org/html/2609.12201v1)).

**AudioShake is the one vendor selling this exact job, but treat its numbers as claims.** "Commercial Music Removal" is its product for removing background music from live audio. The often-quoted 11 ms belongs to Dialogue RT, a dialogue product, and is not a music-separation figure ([AudioShake SDK](https://www.audioshake.ai/products/sdk)). Access and pricing go through sales. Its cloud API prices `music_removal` at 10 credits a minute against 1.5 for `dialogue` ([AudioShake models](https://developer.audioshake.ai/models.md)). Ask for a trial and nonprofit terms now, because a licence could replace months of training.

**Recommended model path.** Ship DeepFilterNet3 first, because it combines a permissive licence on code and weights, full 48 kHz audio and existing Android and iOS builds ([KaleyraVideo Android](https://awesome.ecosyste.ms/projects/github.com%2Fkaleyravideo%2Fandroiddeepfilternet)). GTCRN is the lighter fallback at 16 kHz. Benchmark it before committing, because nothing published shows how well it removes music. In parallel, train your own causal model with one job: voice out, everything else discarded. Start from the ADI design, which is the only one demonstrated under a hard real-time deadline. Its GRU layers also look like the safest recurrence for NPU export ([ONNX Runtime QNN](https://github.com/onnxruntime/onnxruntime-qnn/releases/tag/v2.4.0)). Grow capacity toward Band-SCNet as phone measurements allow. A large offline model such as Mel-Band RoFormer can serve as the teacher. Export recurrent state as explicit inputs and outputs, because hidden state silently resets per call on ONNX, LiteRT and ExecuTorch ([anira stateful-lstm](https://huggingface.co/anira-project/stateful-lstm)). ONNX Runtime with CPU inference is the practical single runtime. NNAPI is deprecated since Android 15 ([Android NDK](https://developer.android.com/ndk/guides/neuralnetworks)).

**Training data is a legal blocker the notes did not raise.** MUSDB18 and MUSDB18-HQ, the standard training and benchmark sets, are restricted: the tracks "can only be used for academic purposes", and some carry non-commercial licences ([SigSep](https://sigsep.github.io/datasets/musdb.html)). Do not train a released model on them without legal advice, even for a free app. They are also Western pop and rock, so Arabic speech, Quran recitation and nasheed are out of domain. This inference fits the HaramMute complaint about a recitation video. Commissioning or licensing your own stems buys both legal clearance and domain fit. VocalSet offers singing data under CC BY 4.0 ([arXiv 2009.06122](https://arxiv.org/pdf/2009.06122)).

**A cheap music detector saves battery but leaks music if it gates the filter.** YAMNet takes 12.29 ms per inference on a Pixel 6 CPU, but it needs about one second of audio ([MediaPipe](https://developers.google.com/edge/mediapipe/solutions/audio/audio_classifier)). Naqi's gate is safe because it runs offline. In a live product, the same gate would let up to a second of music through at each onset. Run the light filter continuously, and use the detector only to wake a heavier second stage.

## Android: rootless reaches many apps, and shell may reach more

### Rootless capture works through a mute trick

**Android gives apps a copy of other apps' audio, never control of it.** AudioPlaybackCapture needs `RECORD_AUDIO`, a user-approved MediaProjection prompt and a `mediaProjection` foreground service. It only reaches players using `USAGE_MEDIA`, `USAGE_GAME` or `USAGE_UNKNOWN` whose capture policy allows it ([Android docs](https://developer.android.com/media/platform/av-capture)). It does not silence the original. Custom effects are not an option either: session 0 and the effect-control broadcast only accept built-in effects, so a neural network cannot be attached there ([AudioEffect reference](https://developer.android.com/reference/android/media/audiofx/AudioEffect)).

**RootlessJamesDSP shows the working pattern, read directly from its source.** It uses a shell-granted `DUMP` permission to list live session IDs, then attaches a top-priority effect to each session and drives it to silence, using DynamicsProcessing at -200 dB or a hidden Volume effect. It captures the same audio through AudioPlaybackCapture and replays the processed copy through its own `AudioTrack` ([RootlessJamesDSP](https://github.com/timschneeb/RootlessJamesDSP)). This works because AudioFlinger checks no permission for effects on non-zero sessions, and a code comment notes the ownership check is still a to-do ([AudioFlinger.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/services/audioflinger/AudioFlinger.cpp)). That gap is the design's largest platform dependency, because Google can close it in any release.

Four limits follow from this design.

**Coverage has holes.** The README lists Spotify, Chrome and SoundCloud as unsupported, and YouTube, YouTube Music, Twitch, Deezer and Apple Music as working. Nobody checked the manifests of Instagram, TikTok, WhatsApp or Netflix, so their status is unknown. Call audio uses a non-capturable usage. Spotify's patch route is sideload-only.

**Delay breaks lip-sync.** One community report measured about 500 ms, with a commenter blaming the capture path ([issue #201](https://github.com/timschneeb/RootlessJamesDSP/issues/201)). That is a single device, and the app uses a blocking Java `AudioTrack`, so an Oboe output may do better. Audio lag becomes unacceptable past about 185 ms under ITU-R BT.1359 ([summary](https://en.wikipedia.org/wiki/Audio-to-video_synchronization)). The app itself tells users to exclude video apps. The player cannot compensate, because it does not know the delay exists.

**Music leaks at each start.** The app's own text describes under 250 ms of duplicated audio when a new session opens, because muting happens after detection.

**Lock-screen behaviour looks better than the notes concluded.** Android 15 QPR1 stops projection on lock ([Android 15 changes](https://developer.android.com/about/versions/15/behavior-changes-all)), and the notes called this a hard break. Current AOSP code exempts a projection with no active VirtualDisplay, which is what audio-only capture should be. It also exempts apps holding the `PROJECT_MEDIA` AppOp, which RootlessJamesDSP grants through Shizuku. Starting a new projection while locked stays forbidden without one of the other exemptions, such as that AppOp ([MediaProjectionStopController](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/services/core/java/com/android/server/media/projection/MediaProjectionStopController.java)). This is AOSP main, not a shipped OEM build, so test it. Separately, apps targeting Android 15 cannot start this service from boot, so a reboot needs user action.

**Play distribution is possible but awkward.** RootlessJamesDSP ships on Google Play and F-Droid. Play's demo-video requirement describes capturing the screen to an external display, which does not match this use, and all foreground service types are subject to review ([Play policy](https://support.google.com/googleplay/android-developer/answer/13392821)). Prominent disclosure is required. Keep a direct APK and F-Droid path ready.

### A shell-privileged helper is the most promising untested option

**Shell cannot grant capture permissions to an app, but it can run your code as shell.** `CAPTURE_AUDIO_OUTPUT` and `MODIFY_AUDIO_ROUTING` are not grantable through `pm grant`. The shell process itself holds them, from Android 11 and 13 respectively ([Shell manifest](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/packages/Shell/AndroidManifest.xml)). scrcpy uses exactly this from UID 2000, with no MediaProjection or AppOps trick. Its default `output` source records `REMOTE_SUBMIX` and silences the device, and its `playback` source uses a hidden AudioPolicy mix on Android 13+ ([scrcpy audio docs](https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md)). The notes concluded a phone app cannot reach this. Shizuku's documentation says otherwise: a UserService runs in its own process as UID 2000 when Shizuku was started with adb, though it is not a normal app process and many Context APIs fail ([Shizuku API](https://github.com/RikkaApps/Shizuku-API)). This path needs a live Shizuku session, not just a one-time grant. Expect to restart Shizuku after a reboot, and verify that.

**This could remove three rootless limits at once.** An AudioMix with `ROUTE_FLAG_LOOP_BACK` reroutes matched audio away from the speaker and makes it available to `AudioRecord` ([AudioMix.java](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/media/java/android/media/audiopolicy/AudioMix.java)). That silences at the routing layer, so the session mute trick and its leak window could go away, along with the consent prompt.

**Whether opt-outs apply is the most important open item.** The claim that `allowAudioPlaybackCapture="false"` does not bind `REMOTE_SUBMIX` is inferred from scrcpy's docs and routing code, and "YouTube and Spotify are captured" is inferred, not tested. Reading current `AudioPolicyMix.cpp` adds one data point: the usage and opt-out checks sit only in the branch for loopback-plus-render mixes, so a pure loopback mix does not hit them there ([AudioPolicyMix.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/services/audiopolicy/common/managerdefinitions/src/AudioPolicyMix.cpp)). scrcpy's docs still say apps can opt out of `playback`, and other layers were not read. Treat this as open until Spotify and Chrome are tested on a device.

**The re-injection half is unproven.** No project found captures through AudioMix or `REMOTE_SUBMIX` and plays processed audio back on the same device. Scrcpy and the recorders only forward or save. Your output must avoid being rerouted into the mix, probably through UID exclusion, and that needs testing. Any delay figure for this chain would be a guess, because none has been measured.

### Root adds an in-place effect at a high cost

**A native effect library is the only route with field precedent for in-place processing.** ViPER4Android and JamesDSP declare a `.so` in the vendor effects config, overlaid by a Magisk module. It runs in the vendor audio HAL process and is called once per mixer period of at least 20 ms ([AOSP latency design](https://source.android.com/docs/core/audio/latency/design); [HAL service rc](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/common/all-versions/default/service/android.hardware.audio.service.rc)). There is no capture path, so no double audio and no replay buffer. Fast tracks bypass software global effects, and DIRECT outputs reject them ([Threads.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/services/audioflinger/Threads.cpp)). So this does not reach every stream.

**A neural model strains this environment.** An ADI-sized model is plausible in the callback. A Band-SCNet-sized one would need a separate process over shared memory, costing at least one extra block of delay. No open project has built that. A partial read of AOSP SELinux policy shows no GPU or NNAPI rules for the audio HAL, but device policies were not checked. Weights must be readable by the HAL domain, which likely means shipping them in the module overlay.

**Several things remain unknown.** Bluetooth behaviour is unknown, and ViPER4Android issue #39 was seen by title only. Android 14+ devices using the AIDL effect HAL load libraries differently ([EffectFactory.cpp](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/EffectFactory.cpp)), so legacy effects may fail there. That explanation rests partly on memory, and vendor HALs may differ. Whether a post-processing effect forces offload off is unresolved.

**Root is a small audience with real costs.** No current statistic exists for rooted share. Rooted phones can reach at most basic Play Integrity without spoofing, because the device verdict needs a locked bootloader ([Google](https://developer.android.com/google/play/integrity/improvements)). Samsung's Knox flag reportedly breaks Wallet and Secure Folder, and forum posts describe this as irreversible ([Samsung community](https://r2.community.samsung.com/t5/Galaxy-Note/What-Are-The-Disadvantages-Of-Having-A-Knox-Tripped-Devices/td-p/9884627)). ViPER4Android's maintenance is community-level, and one reporter got it running on a Pixel 6 with Android 16 after a mount fix ([issue #130](https://github.com/AndroidAudioMods/ViPER4AndroidApp/issues/130)). Treat root as a power-user tier that reuses the shell helper, with the effect library as a later option. Third-party code on Qualcomm's audio DSP is out of reach, because it loads only signed modules ([LKML](https://lkml.iu.edu/2511.3/00926.html)).

## iOS forbids the goal, so offer only side routes

**No supported API lets a third-party app capture, modify and replace other apps' audio.** A ReplayKit broadcast extension receives copies, has about 50 MB of memory, cannot play audio, and does not receive AVPlayer, Safari video or Music audio ([Twilio README](https://github.com/twilio/video-quickstart-ios/blob/master/ReplayKitExample)). That source dates from 2018 to 2020, and nothing newer was found. AVAudioSession can only duck or interrupt others, and Apple says not to duck "for more than a few seconds" ([Apple](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/duckothers)). AUv3 effects run only inside hosts that load them. Apple's Audio Mix API works on recorded Spatial Audio assets, not playback ([Apple](https://developer.apple.com/documentation/cinematic/editing-spatial-audio-with-an-audio-mix)).

**Jailbreak is not a product route.** The EQE tweak showed system-wide DSP was once possible, but there is no public jailbreak for iPhone 16 or 17, and iOS 26 support stops at A12/A13 devices on 26.0 to 26.0.1 ([iClarified](https://www.iclarified.com/jailbreak)).

**What remains on iOS** is a link-based service in the HaramMute pattern, an in-app player for files, and possibly a Safari web extension for web video, which reaches no native app. A Bluetooth receiver box is the only way to cover native iOS apps.

## Desktop has cleaner hooks, and macOS has the best one

| Platform | Hook | Silences original? | Background and CLI form | Known bypass or gap |
|---|---|---|---|---|
| Linux | PipeWire filter-chain virtual sink | Yes, apps play into the sink | Config drop-in in `pipewire.service`, or `pipewire -c filter-chain.conf` as a user unit | Apps pinned to a hardware sink; filter streams do not follow default-sink changes |
| macOS 14.4+ | Global Core Audio tap, muted | Yes, while the tap is read | Menu-bar app or LaunchAgent (agent grant persistence untested) | DRM undocumented; crash behaviour needs testing |
| Windows 10/11 | Virtual render device as default, plus user-mode bridge | Yes, by being the default device | Per-user auto-start process | Apps pinned to a physical device; DRM through a virtual device unknown |

### Linux is the fastest place to start

**A voice-only system output exists today with no code.** DeepFilterNet ships `deepfilter-stereo-sink.conf`, which creates a virtual output "leaving mainly speech" ([DeepFilterNet LADSPA](https://github.com/Rikorose/DeepFilterNet/blob/main/ladspa/README.md)). Make it the default sink with `wpctl set-default` and every app routes through it. PipeWire owns the real-time thread, so a Rust LADSPA or LV2 plugin is the most robust home for your engine. HushMic shows the pattern, including a watchdog and a headless systemd mode ([HushMic](https://raw.githubusercontent.com/Fovty/HushMic/main/README.md)).

**PipeWire 1.6 added an `onnx` node** that loads a model into the graph with state feedback ([PipeWire docs](https://docs.pipewire.org/1.6/page_module_filter_chain.html)). The docs only show a model driving a control value, so audio output from a tensor is unconfirmed, and distro builds need libonnxruntime. A standalone daemon is the choice when the model needs a GPU, though `pw-cat` defaults to 100 ms per direction ([pw-cat](https://docs.pipewire.org/page_man_pw-cat_1.html)).

Two traps need testing. WirePlumber does not move filter streams when the default sink changes, so leave the output stream untargeted ([WirePlumber settings](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/settings.html)). An open issue also reports a startup hang when a virtual sink is the saved default ([wireplumber#527](https://gitlab.freedesktop.org/pipewire/wireplumber/-/issues/527)). GStreamer's `demucs` element gives true separation today, but its example buffers 9 seconds ([Centricular](https://centricular.com/devlog/2025-12/demucs/)). That suits a long-delay audio-only mode, not video.

### macOS gives muting as a first-class API

**Core Audio taps do what Android makes you fake.** A global tap can exclude your own process, and its mute behaviour stops the source reaching the hardware ([Apple sample](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps); [CATapMuteBehavior](https://developer.apple.com/documentation/coreaudio/catapmutebehavior)). You read the tap through a private aggregate device driven by the real output, run the model, and write to the output in the same cycle. Rogue Amoeba's current tools very likely rely on this path, which suggests it holds up in production ([SoundSource](https://rogueamoeba.com/soundsource/)).

The known costs are real. Permission cannot be queried by public API and denial returns silent zeros ([AudioCap](https://github.com/insidegui/AudioCap); [dev.to](https://dev.to/nickdelv/2000-buffers-of-nothing-3i8)). Levels drop on multi-channel devices ([Apple forum](https://developer.apple.com/forums/thread/806799)). Long sessions on a macOS 26.5 beta delivered zeros ([Apple forum](https://developer.apple.com/forums/thread/825780)). The aggregate must be rebuilt when the output device changes. One practitioner disabled the App Sandbox as fragile ([DGR Labs](https://dgrlabs.co/blog/2026-04-25-capturing-system-audio-on-macos-in-2026.html)), so plan for a notarized Developer ID app outside the Mac App Store. How protected Safari and TV app audio behaves under a tap is undocumented.

### Windows pushes you to a virtual device

**A virtual default device plus a user-mode bridge is the only sound design.** WASAPI loopback copies audio "in addition to" sending it to the hardware, so the user would hear both ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/coreaudio/loopback-recording)). Process loopback has the same problem. NVIDIA Broadcast and Krisp use the virtual-speaker pattern, and Tom's Hardware found Broadcast stripped a background theme song entirely, while thinning the voice ([NVIDIA](https://www.nvidia.com/en-us/geforce/guides/broadcast-app-setup-guide/); [Tom's Hardware](https://www.tomshardware.com/news/nvidia-broadcast-tested)). Your cost is a signed virtual audio driver. Licensing a third-party cable is the alternative, and terms were not researched.

**Avoid APOs for this.** A custom APO must ride a specific device's driver package and cannot register globally, and its real-time methods must never block ([Microsoft](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/implementing-audio-processing-objects)). That rules out a device-agnostic neural APO. Equalizer APO misses exclusive-mode streams and depends on `DisableProtectedAudioDG`, which one 2026 project reports no longer works on a recent Windows 11 build ([Veyra](https://github.com/NextGenDev-KSK/veyra/releases/tag/v1.0.0)). That report is single-source. Equalizer APO's VST host reportedly loads only 64-bit VST2 ([itch.io post](https://itch.io/post/11306876)), so it cannot load VST3-only products like iZotope RX 12 ([KVR](https://www.kvraudio.com/news/izotope-releases-rx-12-66802)). This limit also comes from a third party, not the project author.

**Commercial plugins are not a shortcut.** iZotope, Waves, Acon and Antinode sell per-seat plugins you cannot redistribute. Their dialogue isolators make no music-removal claim in the sources found. iZotope RX 12 does offer a real-time Music Rebalance plugin that splits vocals, bass, drums and other, and Scene Rebalance separates dialogue, music and effects, though its real-time status is unknown ([iZotope](https://www.izotope.com/community/blog/rx-12)). Both are useful as stage 0 listening references, not as shippable components. Dialogue plugin latency is about 2048 samples for Clarity Vx ([Waves](https://www.waves.com/plugins/clarity-vx-pro)) and 3880 samples at 44.1 kHz for dxRevive ([RecordProduction](https://www.recordproduction.com/reviews/accentize-dxrevive)). On this evidence AudioShake, Krisp and NVIDIA Maxine are the SDK-style options, and Maxine lists no music-removal effect ([NVIDIA AFX](https://docs.nvidia.com/maxine/afx/latest/index.html)).

## Side routes fill the gaps system-wide capture leaves

| Route | Reaches | Delay | Main cost | Verdict |
|---|---|---|---|---|
| Own player on Media3 `AudioProcessor`, with share target | Shared video files; YouTube if you build a client | Can be hidden by delaying video | YouTube terms risk for a client | Build the share-target player; it solves lip-sync on that path |
| Link-based cloud, HaramMute pattern | URL-addressable video, iOS included | Wait, then perfect sync | GPU bills, scraping terms, downloader upkeep | Only for iOS presence; competes head-on with HaramMute |
| Chrome extension using `tabCapture` | Desktop Chromium tabs | Model-dependent | User gesture per tab | Cheap reuse of the engine for desktop users |
| Firefox Android or custom browser | Web video only | Model-dependent | Site hooks; cross-origin silence | Low priority |
| Second device as Bluetooth sink (Pi) | All phone output, iOS and DRM apps included | Bluetooth plus model, so lip-sync drifts | Carrying hardware | Niche offer for strict users |
| Phone to PC with scrcpy | Android apps, desk-bound | About 50 ms buffer plus model | Tethered use | Useful for testing |
| Detect and mute | All capturable audio | About 1 s reaction | Removes voice too | Fallback, not the product |
| Live cloud round trip | Same as capture | Unmeasured | Uploads all listening; still needs capture | Reject |

Media3 exposes a pluggable PCM hook, and Google lists a `StudioSoundAudioProcessor` for source separation through Play services, though what it does and who can use it is unknown ([Media3](https://developer.android.com/reference/androidx/media3/common/audio/AudioProcessor)). In Chrome, `tabCapture` silences the tab and hands you the stream, and NoMusic's open code shows the full chain ([Chrome docs](https://developer.chrome.com/docs/extensions/reference/api/tabCapture)). Wakapippi runs UVR-MDX-NET on WebGPU, one tab at a time ([listing](https://chromewebstore.google.com/detail/wakapippi-vocal-remover-e/mfdkjbkokfdnegolbddbacaafcekijgf)). Firefox's `tabCapture` bug is still open ([Bugzilla 1391223](https://bugzilla.mozilla.org/show_bug.cgi?id=1391223)). No primary source covers `tabCapture` with DRM, so Netflix-class coverage is unverified. Browser latency figures in the notes are inferences, as is the claim that YouTube element hooks work in practice. A Raspberry Pi as a Bluetooth sink is documented by Collabora ([guide](https://www.collabora.com/news-and-blog/blog/2022/09/02/using-a-raspberry-pi-as-a-bluetooth-speaker-with-pipewire-wireplumber)), but no speech-enhancement or separation deployment on Pi NPUs was found.

## Where the research notes disagree

**Resolved, with the source that settled each point.**

| Topic | Disagreement | Resolution |
|---|---|---|
| HaramMute users | One note: about 20K on Chrome. Another: 1,000 or fewer per extension | 20,000 is sourced; rechecked on the [listing](https://chromewebstore.google.com/detail/harammute-remove-backgrou/bbkbpldbnkoncockinoapcmbiijejgpn) (4.3 from 197 ratings, v1.0.19, 2 Nov 2026). The plugins note never retrieved it. A note showing v1.0.9 and 174 ratings used an older snapshot. Firefox has 452 users |
| Muslim-targeted listings | The correction said neither NoMusic nor Halalify says this | Half right. Rechecked: NoMusic's listing does say "designed specifically for Muslims". [Halalify's](https://chromewebstore.google.com/detail/halalify/kkmnioioinpnnebdbgfaabagojibhpok) does not state it. "At least five" stays dropped |
| RootlessJamesDSP muting | One note: undocumented. Another: read from source | Source reading wins: session effects driven to silence |
| RootlessJamesDSP delay | "No figures published"; about 500 ms; a model note's "fits within 100 to 200 ms" | About 500 ms is one community report, not a benchmark. The 100 to 200 ms budget ignored capture buffering |
| Stop on lock | Notes call it a hard break | Overstated per current AOSP; test on devices |
| Shell from an app | Notes say an installed app cannot reach shell capture | True for app UID. A Shizuku UserService does run as shell. Audio use is untested |
| Root reach | One note: root intercepts every stream with no latency penalty | Source reading wins: fast and DIRECT paths bypass, and a model adds delay |
| DeepFilterNet delay | 20 ms vs 40 ms | Both correct: 40 ms is the DFN3 paper with 2-frame lookahead; 20 ms is the LADSPA build's no-lookahead model, plus host latency |
| GTCRN size | 48.2K and 33 MMAC/s vs 23.7K and 39.6M MACs | Use the [project repo](https://github.com/Xiaobin-Rong/gtcrn) figures |
| DeepFilterNet RTF 0.19 | Attributed to different papers | A desktop figure for the family; do not pin it to a version |
| Paper 2609.12201 | One note flagged the ID as unusual | It is a normal September 2026 ID; two other notes read it |
| dxRevive citations | Note attached each claim to the wrong review | Swapped: 3880 samples is in [RecordProduction](https://www.recordproduction.com/reviews/accentize-dxrevive); "too much latency" is in [Sound On Sound](https://www.soundonsound.com/reviews/accentize-dxrevive-pro) |
| Moises Live | The plugins catalogue underplays it; the shortlist omits it | It is the leading desktop proof, though a consumer app. Phone real-time work exists only through Blackstar |

Maxine Speaker Focus and Firefox bug 1866638 were rechecked and hold. The Firefox bug concerns video capture, so it says nothing about audio.

**Still open, so test before relying on either side.**

| Topic | Conflict | Why it matters |
|---|---|---|
| Samsung live mode | Samsung's [newsroom](https://news.samsung.com/global/faster-real-time-enhanced-audio-eraser-with-the-galaxy-s26-series) describes real-time separation into six layers including music (read via search snippets). Reviewers see only strength and Voice Focus on the tile | Do not claim Samsung proves six-way live separation of third-party audio. It proves real-time background reduction |
| Opt-out for loopback mixes and `REMOTE_SUBMIX` | Inference and my source reading vs scrcpy docs; the iOS note assumes opted-out apps fail | Decides whether Spotify and Chrome are reachable |
| Capturable usages | [scrcpy #4380](https://github.com/Genymobile/scrcpy/issues/4380) says notifications, alarms and call audio cannot be captured; the current [AudioPlaybackCapture.java](https://github.com/Genymobile/scrcpy/blob/master/server/src/main/java/com/genymobile/scrcpy/audio/AudioPlaybackCapture.java) matches those usages | The render-branch filter may explain it, unconfirmed |
| Offload and post-processing effects | Framework invalidates offload for non-offloadable global effects, but a later change ignores output-stage effects | Decides whether the root effect sees music tracks |
| YouTube session discovery | Wavelet reportedly cannot find YouTube's session through dumps ([Esper](https://www.esper.io/blog/android-equalizer-apps-inconsistent)), yet RootlessJamesDSP lists YouTube as working | YouTube is the top target |
| Muting opted-out apps | One note says capture-blocking apps cannot be silenced, without evidence | Decides the fail-closed design |
| htdemucs weights | Naqi says MIT; [free-music-demixer](https://github.com/sevagh/free-music-demixer) says proprietary; Demucs states no separate weight licence | Get clarity before shipping Demucs weights |
| macOS mute | Apple's text implies `muted` stands alone; [ShutUpTheMac](https://github.com/oguzzkk/ShutUpTheMac) says an unread tap changes nothing | Decides what happens on a crash |
| Windows Bluetooth | Veyra says only the bridge works on A2DP; Microsoft's sample registers APOs for it | Low impact, since the bridge is the plan anyway |
| Delay compensation | One note leaves A/V sync to the player; another says the player cannot see the delay | On capture paths, assume no compensation. PipeWire 1.6 apps such as OBS can compensate, per HushMic |

## Recommendation

### Architecture and platforms

**Build one engine and thin platform shells.** The engine is a Rust or C++ library: ring buffer, streaming ONNX model with explicit state, and a stable block interface. Every platform then adds only capture and output. Build in this order:

| Stage | Build | Finish when |
|---|---|---|
| 0 | Test set of lectures, Reels, recitation with instruments, nasheed, and Arabic and English speech over music, plus an acceptance bar | Baselines scored for DeepFilterNet3, DPDFNet, GTCRN and offline Demucs, with an AudioShake trial if granted |
| 1 | Linux sink, first as DeepFilterNet config, then your engine as a plugin with a CLI and systemd unit | Runs a week through Bluetooth switching and restarts |
| 2 | Android rootless app, using capture, session mute and an Oboe output, after the tests below | Tests pass on Samsung, Pixel and Xiaomi |
| 2b | Android share-target player using Media3 | WhatsApp and Telegram videos play in sync |
| 3 | Your own causal voice model, in parallel from stage 0, on cleared data | Beats the stage 0 baseline on instrument residue and word retention |
| 4 | macOS tap app | Survives device changes and long sessions |
| 5 | Windows virtual device and bridge | Signed driver installs cleanly |
| 6 | Android advanced mode with shell helper, reused for root | Only if test 6 below passes |

**Android goes before the other desktops because the need is greatest there.** On desktop, a browser extension already reaches most video, while phone apps offer no such route, and no third-party competitor exists. Linux comes first only because it is nearly free and gives you a real measuring rig.

Measure these on real devices before committing to the Android design:

| # | Test | If it fails |
|---|---|---|
| 1 | End-to-end delay with Oboe output, target under 185 ms | Exclude video apps by default; steer video to the player |
| 2 | Read `allowPlaybackCapture` from dumps for Instagram, TikTok, WhatsApp, Telegram, Facebook, X, Snapchat, Netflix | Publish a real coverage table |
| 3 | Mute reliability and leak window on YouTube, Instagram, TikTok | Try `PlayerProxy.setVolume(0)` on Android 13+ ([VolumeManager](https://github.com/yume-chan/VolumeManager)) |
| 4 | Capture survives lock, and restarts while locked, on Android 15 and 16 | Keep-awake guidance, or a restart prompt on unlock |
| 5 | Silence or pause opted-out apps | Show a clear "not filtered" warning |
| 6 | Shell helper: pure loopback mix, re-injection without feedback, Spotify and Chrome | Drop the helper; rootless stays the ceiling |
| 7 | One hour of battery and heat | Lighter model, or heavier stage on demand |

**Fail closed.** Your users want to avoid hearing music, so a filter that silently passes audio is worse than one that goes quiet. Spotify playing untouched while the app shows "active" would damage trust. Where a stream cannot be cleaned, mute or pause it if tests allow, and tell the user. The same logic favours the `muted` tap on macOS, pending the crash test.

**Decide three things yourself.** First, whether singing counts as voice; scholars should settle this, as it sets the model roadmap. Second, whether the app is open source, because RootlessJamesDSP and Naqi are GPL, so reusing their code binds your licence. Third, whether a Shizuku setup step is acceptable for your users. It is the largest onboarding hurdle, and the rootless design needs it for `DUMP`.

### What is impossible

**Impossible on stock iOS:** background modification of other apps' audio, or muting them while they play.

**Impossible on rootless Android:** loading a custom effect into the audio path, giving a normal app `CAPTURE_AUDIO_OUTPUT`, capturing `USAGE_VOICE_COMMUNICATION` calls through AudioPlaybackCapture, patching opt-outs in apps without re-signing them, and acting as a Bluetooth A2DP sink ([AOSP patches required](https://github.com/aystshen/Android-A2dpSink)). AccessibilityService and VPN routes do not touch audio. Calling Samsung's Audio Eraser has no found API.

**Impossible on Windows:** a general-purpose APO across devices under the supported driver model, and loopback capture of protected streams through a trusted driver.

**Impossible for any model today:** running Demucs-class quality live on a phone, and guaranteeing zero instrument residue. Samsung itself warns that accuracy is not guaranteed ([Samsung, via search snippet](https://news.samsung.com/global/faster-real-time-enhanced-audio-eraser-with-the-galaxy-s26-series)).

### Main risks

| Risk | Why it matters | Response |
|---|---|---|
| Residual instruments | Published causal models leave bleed, and this is your core promise | Publish test results; claim reduction, not removal |
| Speech damage | Samsung's file mode removed words during overlaps ([Android Police](https://www.androidpolice.com/samsungs-audio-eraser-saved-noisy-videos-fails-when-sounds-overlap/)) | Score word retention with speech recognition |
| Video delay on Android | About 500 ms would make Reels feel broken | Test 1 first; player route as fallback |
| Google closes the session-effect gap, or tightens projection | The rootless mute depends on an unenforced check; Android 17 reports are provisional | Keep `PlayerProxy` and shell paths as alternatives |
| Play rejection | The use case does not match the declared example | F-Droid and direct APK from launch |
| Training data and weights | MUSDB is academic-only; Demucs weights are disputed | Commission or license data; keep a provenance record |
| Unmeasured battery and heat | No figures exist for always-on inference on phones | Test 7 |
| OEM breakage | Android 14 and 15 repeatedly broke RootlessJamesDSP, and battery optimisers kill services | Budget for continuing maintenance |
| Competition | Samsung could add a music mode; Moises could go mobile; HaramMute is expanding | Lead on religious fit, privacy and honest coverage |
| Fragile desktop audio state | Crashed virtual devices can leave the system silent ([Background Music](https://github.com/kyleneideck/BackgroundMusic)) | Watchdog and clean restore on exit |

## Conclusion

The research started as a search for the right hook into each OS, and the main finding is that each hook is now the smaller problem. Capture is solved or bounded on every platform except iOS, while the voice-versus-instruments model and the legal data behind it are the assets nobody can buy off a shelf at a known price. A labelled test set of recitation, nasheed and speech over music is the most valuable early deliverable. It settles the model choice, gives users honest numbers, and is something competitors do not appear to have.

Build the engine once, prove it on Linux, ship rootless Android with a share-target player, and train your own causal voice model in parallel. Add macOS, then Windows. Leave system-wide iOS out. Run the seven device tests before making any public promise, because test 1 decides the video experience and test 6 could widen coverage to Spotify and Chrome.
