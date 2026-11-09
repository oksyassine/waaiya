# iOS feasibility of system-wide audio interception, and alternative architectures that avoid intercepting phone audio (as of November 2026)

Scope note for the report writer: Part A answers whether an iPhone/iPad app can intercept and modify ALL other apps' audio in real time. Part B surveys architectures that reach the user's goal ("hear videos/audio from any app with instruments removed, voice kept") without intercepting system audio on the phone, each with an existence proof and a coverage trade-off. A final section ranks the alternatives. Every finding is cited; unverifiable items are in Gaps.

## A1. Can a third-party iOS app capture or process other apps' audio output in real time? (ReplayKit, AUv3, Inter-App Audio, AVAudioSession)

### Takeaway
No supported path exists on iOS for an app to take other apps' audio, modify it, and play the modified version back in real time. ReplayKit Broadcast Upload Extensions can receive a copy of app audio for streaming, but they run under a ~50 MB memory cap, cannot run an audio graph or play audio, and do not receive audio from AVPlayer, Safari video, or the Music app; AVAudioSession can only duck (lower) or interrupt (stop) other apps, never mute-while-playing; AUv3 effects only run inside host apps that choose to load them.

### Cited Findings
- ReplayKit broadcast extension memory cap: "The memory usage of a ReplayKit Broadcast Extension is limited to 50 MB (as of iOS 12.2)." — [Twilio ReplayKitExample README](https://github.com/twilio/video-quickstart-ios/blob/master/ReplayKitExample)
- No audio graph / no playback inside the extension: "Unfortunately, since we can't operate an Audio Unit graph in an extension, playback is not allowed." — [Twilio ReplayKitExample README](https://github.com/twilio/video-quickstart-ios/blob/master/ReplayKitExample)
- Which app audio is NOT delivered to a broadcast extension: "It is not possible to capture application audio produced by AVPlayer, by Safari video playback (even if no Fairplay DRM is used), or by the Music app." — [Twilio ReplayKitExample README](https://github.com/twilio/video-quickstart-ios/blob/master/ReplayKitExample)
- The extension receives both app and mic audio ("An RPSampleHandler receives both application and microphone audio samples"), and on iOS 12 "application audio samples are significantly delayed." — [Twilio ReplayKitExample README](https://github.com/twilio/video-quickstart-ios/blob/master/ReplayKitExample)
- Developer report (iOS 11.0/11.1): no app audio at all reached the extension; on the iOS 12 beta usable audio came only from YouTube and Photos, while Safari, GarageBand and Timer/Clock delivered zeroed buffers; no Apple staff reply recorded, bug reports filed. — [Apple Developer Forums thread 91322](https://developer.apple.com/forums/thread/91322)
- ReplayKit on iPad "seems to be very memory hungry when the device is processing constrained," pushing the extension past its limit. — [Apple Developer Forums thread 651367](https://developer.apple.com/forums/thread/651367)
- Common mitigation pattern is to offload heavy audio/video processing from the extension to the host app over a local socket, keeping the extension only for encoding. — [besthub.dev ReplayKit guide](https://www.besthub.dev/articles/implementing-system-wide-screen-recording-with-replaykit-on-ios-5b3e196d315b)
- An open-source project found that an audio-only extension (dropping video) stays comfortably inside the ~50 MB budget. — [voice-cat commit notes](https://code.iamtalon.me/Talon/voice-cat/commit/8c90e250f02277d3b3d4ad30db9f048c5f6ff7d7?files=docs)
- AVAudioSession `duckOthers`: "An option that reduces the volume of other audio sessions while audio from this session plays." ... "If you clear this option, activating your session interrupts other audio sessions." ... "Important: Set this option on a temporary basis only. Don't use it to duck the audio of other apps for more than a few seconds." — [Apple duckOthers documentation](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/duckothers)
- Audio session categories either mix with or interrupt "nonmixable app's audio" (e.g., Ambient: No; SoloAmbient/Record/MultiRoute: Yes; Playback/PlayAndRecord: Yes by default, No with the override). There is no category that mutes other apps while letting them keep playing. — [Apple Audio Session Programming Guide (archived)](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html)
- Audio Unit v3: "Deliver custom audio effects, instruments, and other audio behaviors using an Audio Unit v3 app extension." — [Apple Audio Unit v3 Plug-Ins documentation](https://developer.apple.com/documentation/audiotoolbox/audio-unit-v3-plug-ins)
- iOS 26 extends the Photos "Audio Mix" speech/background separation to third-party apps through a new API, but it operates on video "after the video has been recorded"; the original Photos/Camera feature is limited to the iPhone 16 lineup and iPhone 16e with spatial-audio capture enabled. Six extra styles (e.g., isolated speech, mono foreground stem, ambience-only background stem) are API-only. — [iDownloadBlog, June 23 2025](https://www.idownloadblog.com/?p=1042817)

### Inferences
- The only sanctioned system-audio tap on iOS (ReplayKit broadcast) is one-way: it hands copies of samples to an extension that cannot play audio, has ~50 MB RAM, and is designed for streaming to a server. Even if a separation model fit in the budget, the phone would still be playing the original, unprocessed audio in parallel, so the user would hear both unless the original is muted, which iOS gives no API for.
- The AVPlayer/Safari/Music exclusion means exactly the user's most common sources (web video, native streaming apps built on AVPlayer, DRM content like Netflix and Apple Music) are the ones that would be missing, so even a "stream to server and listen on a second device" design based on ReplayKit would have poor coverage on iOS.
- AUv3 effects only exist inside a host that loads them (DAWs, players that opted in); YouTube, Instagram, WhatsApp, Netflix and Spotify are not AUv3 hosts, so AUv3 gives zero coverage of the user's targets.
- Conclusion for iOS: system-wide real-time instrument removal by a third-party App Store app is impossible, not merely hard; ducking/interruption is the only legal influence on other apps' audio.

### Gaps
- Apple's current documentation pages for `AVAudioSession` categories, Audio Unit extension hosting, and `RPScreenRecorder` in-app capture render client-side and could not be fetched; the AUv3 "host app loads it" statement and the claim that `RPScreenRecorder.startCapture` only captures the app's own audio are well established but not quoted from a primary source in this session.
- Inter-App Audio deprecation (iOS 13) was not verified from a primary source in this session.
- No source was found confirming current (iOS 18/26) behavior of broadcast extensions with FairPlay-protected apps (Netflix/Apple TV+), beyond the Twilio statement that AVPlayer/Safari/Music audio is not captured even without DRM. The Twilio README and Apple forum thread are 2018-2020 era; the restriction may have changed, but no newer source was found.
- No Apple source was found on whether iOS lets an app set the system media volume to zero programmatically (unlike Android); treat as unavailable without a documented API.

## A2. Do iOS/AirPods built-in features (Audio Mix, Voice Isolation, Headphone Accommodations, Conversation Awareness/Boost, Live Listen, Background Sounds, Reduce Loud Audio) remove music while keeping voice from app playback?

### Takeaway
None of Apple's shipping features does speech-vs-music separation on arbitrary app playback. Audio Mix works on recorded videos in Photos/third-party apps; Voice Isolation targets calls and (from iOS 26) recording apps' microphone input; Headphone Accommodations is an EQ/amplification layer; Conversation Awareness/Boost and Live Listen act on the microphone/environment, not on media content.

### Cited Findings
- Voice Isolation "reduces background sounds on phone calls"; accessed via Control Center > Mic Mode; recording apps require iOS 26 or later, phone calls iOS 16.4 or later. — [iPhone Life](https://iphonelife.com/content/how-to-enable-voice-isolation-iphone)
- Audio Mix in Photos "uses machine learning to identify and separate background audio and speech," with Standard, In-Frame and Studio options, as a post-recording tool. — [MacRumors](https://www.macrumors.com/how-to/iphone-16-edit-spatial-audio-in-video-audio-mix)
- iOS 26 Audio Mix API for third-party apps applies "after the video has been recorded." — [iDownloadBlog](https://www.idownloadblog.com/?p=1042817)
- Headphone Accommodations "amplifies soft sounds and adjusts certain frequencies," applies to Phone (calls, FaceTime, third-party video calls) and Media (music, movies, podcasts, audiobooks, Siri, voicemail, Live Listen); Conversation Boost "automatically detects when someone is talking to you in front of you and focuses the AirPods on that person." Nothing on separating speech from music in media. — [Apple Support HT211218](https://support.apple.com/en-us/HT211218)
- Conversation Awareness (AirPods Pro 2/3, AirPods 4 ANC, AirPods Max 2): media volume drops when you start speaking and spoken audio like podcasts pauses; it returns to the previous level when the conversation ends. — [Apple Support AirPods guide](https://support.apple.com/en-ng/guide/airpods/dev966f5f818/26/web)
- Reduce Loud Sounds: threshold adjustable from 75 to 100 dB in 5 dB steps under Headphone Safety. — [AppleInsider](https://appleinsider.com/articles/21/10/11/how-to-use-reduce-loud-sounds-in-ios-15-to-help-protect-your-hearing); [MacRumors](https://www.macrumors.com/how-to/reduce-loud-sounds-when-listening-over-headphones/)
- Live Listen turns the iPhone into a directional microphone that transmits to AirPods. — [AppleInsider](https://appleinsider.com/articles/18/06/05/apple-brings-live-listen-accessibility-feature-to-airpods-in-ios-12)

### Inferences
- Apple evidently has on-device speech/background separation (Audio Mix) but exposes it only as an offline per-file effect; a third-party iOS app could use the iOS 26 API on downloaded/recorded video files (e.g., a WhatsApp video saved to Files), which fits the "download then play" architecture in B1, not the live system-wide goal.
- Headphone Accommodations is the closest thing to a system-wide media DSP on iOS, and it is only tone/amplification; there is no user-installable DSP slot.

### Gaps
- Could not fetch Apple support pages for Background Sounds; third-party pages describe it only as playing masking sounds (rain, ocean), unrelated to removing music from media.
- Whether the iOS 26 Audio Mix API accepts arbitrary (non-iPhone-recorded, non-spatial) video/audio files was not confirmed; the Photos feature requires spatial-audio recordings on iPhone 16-class devices.

## A3. Jailbreak route: can tweaks hook mediaserverd/CoreAudio for system-wide DSP, and what is jailbreak status in 2026?

### Takeaway
Jailbreak tweaks proved system-wide audio DSP is possible once the sandbox is gone (EQE system-wide parametric EQ for iOS 7-11; AudioRecorder XS recording "any system audio"), but as of August 2026 there is no public jailbreak for A14+ devices beyond iOS 17.3.1, none for A18/A19 (iPhone 16/17), and iOS 26 support is limited to A12/A13 on 26.0-26.0.1, so this is not a route for a general user base.

### Cited Findings
- EQE is "a free jailbreak tweak by developer r333d that works as a system-wide parametric equalizer," successor to EqualizerEverywhere, for iOS 7-10 (BigBoss repo). — [iDownloadBlog](https://www.idownloadblog.com/?p=557427)
- Developer states EQE is compatible with iOS 7, 8, 9, 10 and 11; the Objective-C core is closed source and only the Lua scripts are published. — [Head-Fi EQE thread](https://www.head-fi.org/threads/eqe-systemwide-parametric-equalizer-for-ios-jailbreak.873876)
- The EQE repo README (search snippet) reloads via `killall -9 eqed mediaserverd backboardd`, indicating a daemon (eqed) plus injection into mediaserverd; the current README says "The source to EQE is private. This repo is extremely out of date." — [GitHub rweichler/EQE](https://github.com/rweichler/EQE)
- AudioRecorder XS (Elias Limneos) is a jailbreak tweak that "can be used to record phone calls, voice memos, system audio, and more," capturing audio that a running app plays through the speaker; iPad lacked system-audio recording. — [iDownloadBlog](https://www.idownloadblog.com/?p=349876)
- AudioRecorder TS is a TrollStore-based (no jailbreak, no tweak injection) call/FaceTime recorder. — [iDownloadBlog, Feb 2024](https://www.idownloadblog.com/2024/02/13/audiorecorder-ts/)
- Jailbreak status (page last updated Aug 7 2026): Dopamine supports A8-A13 through iOS 18.7.1, A12/A13 on iOS 26.0-26.0.1, A14-A17 and M1-M2 only through iOS 17.3.1; A18/A19 (iPhone 16/17) have no public jailbreak; palera1n covers A8-A11; TrollStore works on iOS 14.0-16.6.1 and 17.0 and "does not support iOS 18 or 26"; a June 2026 "usbliter8" BootROM exploit for A12/A13 is a proof of concept, not a jailbreak. — [iClarified jailbreak status](https://www.iclarified.com/jailbreak)
- Dopamine 3.0 (Aug 2026) "is the first public jailbreak to support iOS 26, but only iOS 26.0 and 26.0.1"; no jailbreak for 26.1+. — [AppsHunter](https://appshunter.io/blog/ios-26-jailbreak-dopamine-3)

### Inferences
- Technically, a jailbroken device could host a mediaserverd injection running a small separation model (EQE is the proof that a per-stream DSP hook in mediaserverd works), but the addressable population (A8-A13 devices on old firmware, or iPhone 11-class on 26.0.x) is tiny and shrinking, and nothing can be distributed via the App Store.
- TrollStore (permanent sideload with extra entitlements) is not available on iOS 18/26, so it is also not a route for current devices.

### Gaps
- No source documents exactly how EQE hooks CoreAudio inside mediaserverd (the DSP code is closed source).
- No 2025-2026 tweak was found that performs system-wide audio processing on rootless (Dopamine) jailbreaks; whether EQE-style injection still works on iOS 15-17 rootless was not verified.
- Official Dopamine site was not fetched; status relies on iClarified and AppsHunter, which agree.

## B1. Build-your-own player/client with built-in separation (YouTube clients, ReVanced, share-target "Open with", downloader+player)

### Takeaway
This is the most proven route: Android's Media3/ExoPlayer exposes a pluggable `AudioProcessor` PCM hook (Google even ships a `StudioSoundAudioProcessor` for source separation via Play services), and the commercial app HaramMute already exists as a YouTube-only "paste link, prepare, play with cleaned audio in sync" product on Android, iOS, Chrome and Firefox. Coverage is per-source: YouTube (open clients) and shared video files (WhatsApp/Telegram via Open-with) are reachable; Instagram/TikTok only via download-and-replay; Netflix/Spotify DRM content is unreachable; no ReVanced patch that processes audio was found.

### Cited Findings
- Media3 `AudioProcessor`: "Interface for audio processors, which take audio data as input and transform it, potentially modifying its channel count, encoding and/or sample rate." Known implementations include `StudioSoundAudioProcessor`: "AudioProcessor implementation for audio source separation using the StudioSound Google Play services module." — [Android Media3 AudioProcessor reference](https://developer.android.com/reference/androidx/media3/common/audio/AudioProcessor)
- Existence proof of injecting a custom processor chain into ExoPlayer: Stash v0.8.0 added an equalizer "through a custom audio processor chain inserted into ExoPlayer's renderer factory" (Preamp -> 5-band biquad EQ -> bass shelf); the prior EQ had been a UI shell not wired into the pipeline. — [Stash v0.8.0 release](https://github.com/rawnaldclark/Stash/releases/tag/v0.8.0)
- No ReVanced patch adding an equalizer or audio processing to the YouTube app was found; audio-related patches that exist are "Codecs unlock" (more audio codec options) and inotia00's "Disable DRC audio" (dynamic range compression off) and default-bitrate settings. — [LeddaZ revanced-patches](https://www.github.com/LeddaZ/revanced-patches); [inotia00 revanced-patches](https://github.com/inotia00/revanced-patches); [inotia00 v5.14.1-dev.5 release notes](https://newreleases.io/project/github/inotia00/revanced-patches/release/v5.14.1-dev.5)
- Android apps register as share targets with `ACTION_SEND` intent filters and MIME types such as `video/*`, then read the shared file URI from `EXTRA_STREAM`; receivers ideally support `text/*`, `image/*` and `video/*`. — [Android: Receive data from other apps](https://developer.android.com/training/sharing/receive)
- HaramMute product: Chrome extension, Firefox add-on, Android app on Google Play and iOS app on the App Store; on mobile "you paste or share a public YouTube link, prepare the audio, then watch the original video with the cleaned audio in sync"; "Preparation requires an internet connection"; free tier 60 minutes/week on videos up to 15 minutes; YouTube only, other platforms "coming soon," live streams unsupported. — [haram-mute.com](https://haram-mute.com/)
- HaramMute Chrome listing: ~20,000 users, 4.5 rating from 174 ratings, v1.0.9 updated May 12 2026. — [Chrome Web Store](https://chromewebstore.google.com/detail/bbkbpldbnkoncockinoapcmbiijejgpn)
- HaramMute Firefox listing: v1.0.6 (Apr 26 2026), 452 users, available on Firefox for Android; required permission www.youtube.com; optional permissions localhost/127.0.0.1 ports 8765-8768, api.haram-mute.com and PostHog analytics. — [addons.mozilla.org HaramMute](https://addons.mozilla.org/en-US/firefox/addon/harammute/)
- iOS Safari web extensions (iOS 15+) are distributed as an iOS app extension through the App Store and use Chrome/Firefox-style JavaScript APIs. — [Apple Safari web extensions documentation](https://developer.apple.com/documentation/safariservices/safari-web-extensions)

### Inferences
- Any open-source Android YouTube client built on ExoPlayer/Media3 (NewPipe, LibreTube, Tubular, Grayjay) can host a separation model as an `AudioProcessor` in the audio sink; this is the lowest-risk, highest-quality path for YouTube because the processor sees clean decoded PCM before output and can use look-ahead buffering (latency hidden by delaying video), unlike any capture route.
- HaramMute's design (server-side "preparation" of the whole video, then synced playback) sidesteps real-time constraints entirely and is why it can use a heavy offline model; its reliance on api.haram-mute.com and the "requires internet" note indicate cloud processing, with the quotas (60 min/week) reflecting server cost.
- WhatsApp/Telegram videos are files: an "Open with"/share-target player that separates on the fly (or pre-processes the file, which takes seconds) covers them on Android; on iOS the equivalent is an app declaring video document types for the share sheet (not verified in this session) or the iOS 26 Audio Mix API on the saved file.
- Instagram Reels/TikTok have no third-party clients; the only client-side route is link-sharing to a downloader+player (same pattern as HaramMute's "paste link"), which is fragile against anti-scraping and may violate those platforms' terms.
- Netflix, Spotify and other DRM/closed services cannot be reached by this route at all (no open client, encrypted streams).
- ReVanced/LSPatch could in principle hook YouTube's ExoPlayer `DefaultAudioSink` to insert an `AudioProcessor`, but no such patch exists; it would be a bespoke reverse-engineering effort that breaks with YouTube updates.

### Gaps
- No source confirms what `StudioSoundAudioProcessor` separates (speech enhancement vs. music stems), which devices have the Play services module, or whether third-party apps can use it; only the one-line class description was found.
- HaramMute's Google Play / App Store listings were not fetched (installs, reviews, ratings unknown); whether its mobile apps process on-device or in the cloud is not stated beyond "requires internet."
- No NewPipe/LibreTube/Grayjay issue or feature request about audio effects/equalizer was found in the search performed.
- iOS "Open with" document-type registration for video files was not verified from Apple docs.

## B2. Browser route: WebView/GeckoView or browser extensions routing <video> audio through Web Audio/AudioWorklet with an on-device model

### Takeaway
Real-time in-browser processing of any tab's audio is proven on desktop Chrome (tabCapture + offscreen document, e.g., "AI Noise Cancellation For Listeners", "Wakapippi Vocal Remover") and per-page Web Audio processing of YouTube is proven on Firefox for Android ("YouTube Equalizer"), so a custom browser or Firefox-Android extension running an ONNX/TF.js separation model in an AudioWorklet is feasible for web-delivered video; coverage is limited to sites that work in a browser (YouTube, Instagram/TikTok web, Reddit, Twitter), cross-origin media without CORS headers yields silence, and stock Chrome for Android still has no extensions.

### Cited Findings
- Chrome `tabCapture` gives a tab's audio/video as a MediaStream; it "can only be called after the user invokes an extension" (e.g., clicking its action button). — [Chrome tabCapture API](https://developer.chrome.com/docs/extensions/reference/api/tabCapture?hl=en)
- "AI Noise Cancellation For Listeners" (DAMIKO INC): "removes noise in real-time from everything you listen to on the web," "Cleans audio from any browser tab that plays sound," processing "in real-time right inside your browser, without sending your data to external servers"; ~2,000 users, 4.7/5 from 77 ratings, v1.2.0 updated July 4 2026, 9.9 MiB. — [Chrome Web Store listing](https://chromewebstore.google.com/detail/haalkhejfckbcbheikblbllncbielmke)
- "Wakapippi Vocal Remover Extension" describes itself as a "realtime vocal remover using ML models" (2 ratings). — [Chrome Web Store listing](https://chromewebstore.google.com/detail/wakapippi-vocal-remover-e/mfdkjbkokfdnegolbddbacaafcekijgf)
- Web Audio spec: a `MediaElementAudioSourceNode` fed by a cross-origin resource "MUST output silence" to prevent information leakage, and the affected element also stops producing sound; there is no property to detect whether an element is CORS-restricted. — [WebAudio/web-audio-api issue 2453](https://www.github.com/WebAudio/web-audio-api/issues/2453); [Mozilla bug 937718](https://bugzilla.mozilla.org/show_bug.cgi?id=937718)
- Firefox for Android opened its extension ecosystem in December 2023 with 450+ AMO extensions; Mozilla calls Firefox "the only major Android browser supporting an open extension ecosystem." — [Mozilla blog](https://blog.mozilla.org/en/mozilla/new-extensions-youll-love-now-available-on-firefox-for-android/); [9to5Google](https://9to5google.com/2023/12/15/firefox-for-android-now-supports-over-450-extensions)
- "YouTube Equalizer" add-on: "A live 10-band audio equalizer for YouTube with preamp and custom presets," listed as available on Firefox for Android (experimental, 80 users, updated Feb 28 2026). — [addons.mozilla.org](https://addons.mozilla.org/en-US/android/addon/youtube-equalizer/)
- HaramMute's Firefox add-on is itself listed as available on Firefox for Android (YouTube only). — [addons.mozilla.org HaramMute](https://addons.mozilla.org/en-US/firefox/addon/harammute/)
- Stock Chrome for Android has no extension support as of mid-2026; Chromium commits in March-April 2026 reference "extensions on desktop Android" with no confirmed phone launch; Kiwi Browser shut down in 2025; Chromium forks (Quetta, Helium) and Edge can load extensions. — [extensionbooster 2026 guide](https://extensionbooster.net/blog/chrome-extensions-android-2026-what-works-guide/); [chromium-extensions group thread](https://groups.google.com/a/chromium.org/g/chromium-extensions/c/SXbk35JTjvI); [Android Central](https://www.androidcentral.com/apps-software/chrome-for-android-is-getting-extensions-but-not-like-youd-expect)
- Safari web extensions run on iOS 15+ and are shipped inside an App Store app. — [Apple Safari web extensions documentation](https://developer.apple.com/documentation/safariservices/safari-web-extensions)

### Inferences
- A custom Android browser (WebView/GeckoView) that injects a content script creating a `MediaElementAudioSourceNode` -> AudioWorklet (ONNX Runtime Web / TF.js model) -> destination gives on-device, real-time separation for YouTube web, Instagram/TikTok web, Twitter/X, Reddit and generic HTML5 video; YouTube's media is same-origin MSE blobs, which is why EQ extensions work there.
- Sites serving cross-origin video without CORS headers (common on smaller sites and some CDNs) will go silent under Web Audio; the extension must detect and fall back to pass-through.
- The same content-script approach works in a Safari iOS extension, which is the only realistic on-device iOS path for web video, but it does not touch native apps (YouTube app, Instagram app, WhatsApp).
- Compute budget: an AudioWorklet runs in the browser's audio thread, so model inference must be moved to a Worker with WASM/WebGPU and ring-buffered; browser-side separation on mid-range phones is the main engineering risk, not platform permission.

### Gaps
- No source confirms the internal architecture (model, AudioWorklet, offscreen document) of the two Chrome extensions beyond their store descriptions.
- No benchmark was found for running a music-separation model (as opposed to speech noise suppression) in a mobile browser in real time.
- Whether Instagram/TikTok web players expose `<video>` elements that are same-origin for Web Audio purposes was not verified.

## B3. Bluetooth / hardware route (second device as A2DP sink, Raspberry Pi/ESP32 DSP, Auracast, earbuds with custom DSP)

### Takeaway
Sending all phone audio over Bluetooth to a second device that runs the separation and feeds headphones is architecturally sound and covers everything the phone plays (including DRM apps, since A2DP is just the output), with existence proofs for Raspberry Pi (bluez-alsa), ESP32 (ESP-IDF a2dp_sink) and Windows (Bluetooth Audio Receiver); a stock Android phone cannot act as an A2DP sink without an AOSP rebuild, Android 16 Auracast makes the phone a broadcaster, not a receiver, and no consumer earbuds offer "remove music, keep voice" (they only duck media when the wearer talks). A September 2026 paper shows real-time music separation fitting a 2 MB-SRAM, ~2 GMAC/s audio DSP at 4.70 dB cSDR, so an earbud/dongle-class implementation is possible but is a hardware product, not an app.

### Cited Findings
- Android has had A2DP playback (phone as source) since Android 1.5; the `BluetoothA2dpSink` class exists in the framework but is not in the public SDK. — [Android audio accessories docs](https://source.android.com/docs/core/interaction/accessories/audio?hl=zh-cn); [BluetoothA2dpSink.java (Android 9)](https://code.yawk.at/android/android-9.0.0_r35/android/bluetooth/BluetoothA2dpSink.java)
- Making Android behave "like a Bluetooth speaker for audio output" required patching and recompiling AOSP (patches for Android 5.1 and 8.1). — [GitHub aystshen/Android-A2dpSink](https://github.com/aystshen/Android-A2dpSink)
- Windows 10/11 can act as an A2DP sink via the "Bluetooth Audio Receiver" Store app ("the feature is currently not available via system settings"). — [TheWindowsClub](https://thewindowsclub.com/stream-music-from-phone-to-windows-10-pc-bluetooth-a2dp-sink)
- bluez-alsa (Linux/Raspberry Pi) builds "a Bluetooth speaker by forwarding audio from the BlueALSA capture PCM to a local playback device, with a smartphone as the source" (`bluealsa-aplay`); designed "for use on small, low-powered, dedicated audio or audio/visual systems." — [GitHub arkq/bluez-alsa](https://github.com/arkq/bluez-alsa)
- ESP-IDF ships an `a2dp_sink` example (ESP32 as a Bluetooth speaker; decoded SBC PCM delivered via a data callback to I2S output); one source connection at a time. — [ESP-IDF A2DP API](https://esp-idf.readthedocs.io/en/latest/api-reference/bluetooth/esp_a2dp.html); [a2dp_sink example](https://sourcevu.sysprogs.com/espressif/examples/bluetooth/bluedroid/classic_bt/a2dp_sink)
- Android 16 adds Auracast/LE Audio Audio Sharing: the phone (Pixel 8+ on Android 16 QPR1; Pixel 8a/9a excluded) is the source and broadcasts to LE Audio earbuds/hearing aids; both phone and headphones must support LE Audio with Auracast. — [TechCrunch](https://techcrunch.com/2025/03/13/android-is-adding-auracast-support-which-allows-hearing-aids-to-connect-to-public-audio-broadcasts/); [Android Central](https://www.androidcentral.com/apps-software/android-os/how-to-use-bluetooth-audio-sharing-on-google-pixel)
- Galaxy Buds Pro "Voice Detect": when the wearer talks, the earbuds lower the music and switch to Ambient sound; returns after 5/10/15 s; false triggers from coughing/humming. — [Samsung support](https://www.samsung.com/sg/support/mobile-devices/experience-noise-controls-mode-on-your-galaxy-buds-pro/)
- AirPods "Conversation Awareness": media volume drops when the wearer starts speaking and podcasts pause; restores afterwards. — [Apple Support AirPods guide](https://support.apple.com/en-ng/guide/airpods/dev966f5f818/26/web)
- Real-time music source separation on a commercial audio DSP with 2 MB SRAM and 2.07 GMAC/s: 10.43 ms per frame within an 11.6 ms hop, 4.70 dB cSDR on MUSDB18-HQ (0.5-0.7 dB behind systems that do not fit); RT-STT needs ~5.5x the available MAC rate; block-padded training collapsed to silence within 2 s when run frame by frame. — [arXiv 2609.12201 (Sept 2026)](https://arxiv.org/abs/2609.12201)
- HS-TasNet: real-time separation at 23 ms latency with SDR 4.65 (5.55 with more data) on MusDB; use cases "hearing aids, remixing audio streams and live shows." — [arXiv 2402.17701](https://arxiv.org/abs/2402.17701)
- AudioShake's on-device SDK claims "under 50ms latency or better," "Removes copyrighted background music from live or streamed audio while preserving dialogue and effects," available on iOS/macOS, Android, Windows, Linux and embedded devices; SDK access by contact. — [AudioShake SDK](https://www.audioshake.ai/products/sdk)

### Inferences
- A Raspberry Pi (bluez-alsa sink -> PipeWire/ALSA -> separation model -> wired/BT headphones) is the most complete "no phone interception" design: it covers 100% of phone sources including Netflix/Spotify on both iOS and Android, at the cost of carrying a second device, adding ~100-200 ms Bluetooth plus model latency (audio/video desync on the phone screen), and the Pi running a 23 ms-class model would need a fast CPU/NPU (HS-TasNet numbers are from i7/RTX hardware).
- Using a second Android phone as the sink is not practical (requires custom AOSP build); a Windows laptop with Bluetooth Audio Receiver or a Linux laptop with bluez-alsa is practical and is the same design as B4.
- Auracast does not help: Android 16 phones broadcast, they do not receive, and a receiving earbud still gets the unprocessed mix.
- Consumer earbuds only duck media when the wearer speaks; nothing ships "voice-only" media. The DSP paper shows the compute fits an earbud-class chip, so a custom dongle (ESP32-S3 is likely too weak; a hearing-aid-class DSP or a small Linux SBC is realistic) is a plausible hardware product.

### Gaps
- No source found for a programmable USB-C DAC/dongle that lets users load a neural model (Qudelix/FiiO etc. not researched); no Qualcomm QCC/Nordic SDK source was found describing third-party model deployment on earbuds.
- The arXiv 2609.12201 abstract does not name the DSP vendor/part, so earbud applicability is inferred from the memory/compute class, not stated.
- No latency measurements for a Bluetooth-to-Pi-to-headphones chain were found.
- Whether AudioShake's SDK is obtainable by an individual developer, and its pricing, is unknown ("Contact to access").

## B4. Casting/streaming route: send phone audio to a PC/TV that runs the processing; desktop system-wide solutions

### Takeaway
On Android, scrcpy (Android 11+) and AudioRelay (Android 10+) stream all capturable app audio to a PC with ~50 ms buffering, and Linux PipeWire already runs DeepFilterNet system-wide via a filter-chain sink ("The output will only contain speech"), so a desktop system-wide "voice only" pipeline exists today; coverage excludes apps that opt out of playback capture (DRM/copyrighted-content apps), and on iOS there is no equivalent app-audio stream (AirPlay/ReplayKit exclusions apply), so this route is Android-only unless the Bluetooth sink design (B3) is used.

### Cited Findings
- scrcpy audio forwarding: "supported for devices with Android 11 or higher," enabled by default; on Android 11 the screen must be unlocked at start (a fake popup makes the shell app foreground); audio blocks arrive every 20 ms; default buffer 50 ms (`--audio-buffer`); codecs opus/aac/flac/raw; an alternative "playback" capture method exists for Android 13+. — [scrcpy doc/audio.md](https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md); [rom1v blog, scrcpy 2.0](https://blog.rom1v.com/2023/03/scrcpy-2-0-with-audio/)
- AudioRelay phone-to-PC (or phone-to-phone) app-audio streaming "requires a phone with at least Android 10"; "Some apps disallow their audio from being recorded"; user accepts a capture permission; forum: restrictions "will mostly be apps playing copyrighted material," and the target app must target API 29+ and not opt out. — [AudioRelay docs](https://audiorelay.net/docs/android/stream-audio-from-a-phone-to-a-pc-or-to-another-phone); [AudioRelay community thread](https://community.audiorelay.net/t/audio-capture-no-longer-working-for-some-android-apps/3924)
- DeepFilterNet LADSPA + PipeWire: virtual microphone (`deepfilter-mono-source.conf`) and virtual output sink (`deepfilter-stereo-sink.conf`) where "The output will only contain speech and suppress most of the noise"; "The minimum latency is 20 ms (STFT processing) and additional latency depending on your LADSPA host such as Pipewire." — [DeepFilterNet ladspa README](https://github.com/Rikorose/DeepFilterNet/blob/main/ladspa/README.md)
- RNNoise-based `noise-suppression-for-voice` provides a similar system-wide PipeWire filter-chain node. — [werman/noise-suppression-for-voice (ecosyste.ms mirror)](https://awesome.ecosyste.ms/projects/github.com%2Fwerman%2Fnoise-suppression-for-voice)
- Windows: Voicemeeter Potato 3.0.1.3 added a "K" button on the Virtual AUX input with "4 different real time algorithms to remove the voice on a stereo material" (karaoke, i.e., the inverse of the user's need); VB-CABLE is a virtual audio device for routing. — [Voicemeeter Potato manual (Scribd copy)](https://www.scribd.com/document/487785955/VoicemeeterPotato-UserManual); [VB-CABLE](https://www.filehorse.com/download-vb-cable)
- zplane PEEL STEMS 2 (DAW plugin) does real-time stem separation at "245 ms" DAW-compensated latency at 44.1 kHz. — [Gearspace](https://gearspace.com/gear/zplane-peel-stems.68761/)
- AudioShake SDK targets desktop DAWs as well as mobile and embedded, with on-device inference under 50 ms. — [AudioShake SDK](https://www.audioshake.ai/products/sdk)

### Inferences
- A desktop "voice-only system output" is the easiest full-stack existence proof: PipeWire filter-chain already hosts DeepFilterNet (speech enhancement) system-wide; swapping in a music-separation LADSPA/LV2 plugin (vocals stem) is a plugin-writing task, not a platform fight. This satisfies the user's need only for desktop listening (browser, Spotify desktop, VLC), not phone apps.
- Phone -> PC via scrcpy/AudioRelay then PC processing then headphones works for Android apps that permit playback capture (YouTube, Instagram, TikTok, WhatsApp, Telegram, browsers, most games) and fails for Netflix/Spotify-class apps that opt out; the user hears audio on the PC side, so this is a desk/home scenario, not mobile.
- Casting to Chromecast/Android TV does not help because the TV side runs an unmodifiable receiver; the processing device must be a PC/SBC.
- iOS has no scrcpy/AudioRelay equivalent for app audio; AirPlay to a Mac/PC receiver carries only the apps that AirPlay (and DRM apps restrict it), so the Bluetooth sink (B3) is the iOS-compatible version of this route.

### Gaps
- No source quantifies end-to-end latency for AudioRelay; no Windows/macOS system-wide real-time music-removal (vocal-keep) VST chain was found documented in use (only karaoke-style voice removal and DAW stem plugins).
- Whether AirPlay audio to a third-party receiver (e.g., shairport-sync) carries protected app audio on iOS was not researched.

## B5. Cloud/server route: send audio to a server for separation and stream back

### Takeaway
Cloud separation is proven for offline/"prepare first" use (HaramMute's model, batch APIs like StemSplit) and vendors advertise sub-50 ms on-device and 11 ms "dialogue RT" models, but a live round-trip adds network latency on top of model latency, costs server GPU time per listening minute (HaramMute caps the free tier at 60 min/week), and raises privacy issues since all listened audio leaves the device; it also still requires a capture path on the phone, which Part A shows iOS does not offer.

### Cited Findings
- AudioShake: SDK "On-device inference, no cloud round-trip, under 50ms latency or better"; Dialogue RT "11ms dialogue isolation latency"; cloud API "Same separation quality, cloud-based"; no public pricing. — [AudioShake SDK](https://www.audioshake.ai/products/sdk)
- HANCE 2.0 introduced "models for realtime stem separation" (vocals, drums, bass, piano) via its API. — [HANCE changelog](https://data.safetycli.com/changelogs/hance/)
- StemSplit API is batch: it POSTs to a callback URL when done. — [dev.to StemSplit tutorial](https://dev.to/stevecase430/how-to-build-an-ai-vocal-remover-in-python-with-the-stemsplit-api-2026-4j57)
- HaramMute: "Preparation requires an internet connection"; free 60 minutes/week on videos up to 15 minutes; paid plans for more; permissions include api.haram-mute.com and PostHog; declared data collection includes personally identifiable information and website activity. — [haram-mute.com](https://haram-mute.com/); [addons.mozilla.org HaramMute](https://addons.mozilla.org/en-US/firefox/addon/harammute/)
- HS-TasNet reaches 23 ms algorithmic latency on i7/RTX-class hardware; GPU timings "don't transfer to embedded hardware." — [arXiv 2402.17701](https://arxiv.org/abs/2402.17701); [arXiv 2609.12201](https://arxiv.org/abs/2609.12201)

### Inferences
- For URL-addressable content (YouTube, public Reels/TikTok links, shared video files) the cloud "prepare then play synced" pattern is the pragmatic choice because the server can fetch the media itself (no phone capture needed) and use a heavy non-causal model; this is precisely HaramMute's architecture and the quotas show the cost structure.
- For true live streaming (phone capture -> server -> phone), the phone capture problem is unchanged (impossible on iOS; Android via playback capture with DRM opt-outs), network RTT of 50-200 ms plus 20-50 ms model plus jitter buffers implies 150-400 ms delay, acceptable for audio-only but visible as lip-sync drift on video.
- Privacy: everything the user listens to is uploaded; a religious-use app may find that acceptable with clear disclosure, but it conflicts with offline/private listening.

### Gaps
- No public per-minute pricing for any real-time separation API was found (AudioShake "contact to access").
- No measured end-to-end latency for a phone-to-cloud-to-phone live separation loop was found.

## B6. Fallback: "detection + mute" (mute/duck whenever instruments are detected) using volume control and MediaSession info; does HaramMute do this?

### Takeaway
On Android an app can lower/mute the media stream with no special permission (`adjustStreamVolume`/`setStreamVolume`, except fixed-volume devices and DND transitions) and can learn what is playing via `MediaSessionManager` with a notification-listener grant, but it still needs audio to classify, and the only permission-free signal (`AudioPlaybackConfiguration`) is anonymized and carries only usage/content-type; the user experience is "silence or heavy ducking during any music-bearing segment," which removes the voice too. HaramMute does not do this; it is a per-YouTube-video separation product.

### Cited Findings
- `adjustStreamVolume`: "Adjusts the volume of a particular stream by one step in a direction"; no permission is listed; "This method has no effect if the device implements a fixed volume policy"; "From N onward, ringer mode adjustments that would toggle Do Not Disturb are not allowed unless the app has been granted Notification Policy Access," throwing `SecurityException` otherwise; `ADJUST_MUTE` exists. — [Android AudioManager reference](https://developer.android.com/reference/android/media/AudioManager)
- `getActivePlaybackConfigurations()` "Returns the current active audio playback configurations of the device" (API 26). — [Android AudioManager reference](https://developer.android.com/reference/android/media/AudioManager)
- Auto Mute app classifies audio using "the audio stream's AudioAttributes (specifically the usage and contentType properties)" and notes "Android only passes an anonymized copy of each AudioPlaybackConfiguration to the app," so it cannot tell which app a stream belongs to. — [GitHub sommd/auto-mute](https://github.com/sommd/auto-mute)
- `MediaSessionManager.getActiveSessions` "requires the MEDIA_CONTENT_CONTROL permission be held by the calling app. You may also retrieve this list if your app is an enabled notification listener," returning controllers "in priority order" (metadata, playback state). — [Android MediaSessionManager reference](https://developer.android.com/reference/android/media/session/MediaSessionManager)
- iOS: `duckOthers` reduces other sessions' volume only while the app's session is active and Apple says "Don't use it to duck the audio of other apps for more than a few seconds"; clearing it makes activation interrupt other sessions. — [Apple duckOthers documentation](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/duckothers)
- HaramMute removes/mutes background music from YouTube videos via link preparation and synced playback; it is YouTube-only and not a system-wide mute. — [haram-mute.com](https://haram-mute.com/); [Chrome Web Store](https://chromewebstore.google.com/detail/bbkbpldbnkoncockinoapcmbiijejgpn)

### Inferences
- Android detection+mute is implementable without capture only if detection runs on something other than the audio (e.g., MediaSession metadata: title/artist implies music) which cannot detect background music in a Reel or a WhatsApp video; to actually detect instruments the app needs playback capture (Android 10+, with DRM opt-outs) or a microphone tap, which brings back the same capture limits as the full solution but with a far smaller model (a music/speech classifier instead of a separator).
- UX cost: the user loses the voice during ducked segments; for content where music runs under speech continuously (most Reels, many YouTube videos) the result is near-total silence, so detection+mute only serves users who want to avoid hearing music rather than to keep the dialogue.
- On iOS, even detection+mute is impossible in the background: an app can only duck others while its own session is active and only "for a few seconds," and it has no system volume API; a foreground-only "mute button" is the ceiling.

### Gaps
- `setStreamVolume` detailed text was not captured (page truncated); the permission/DND behavior is quoted from the sibling `adjustStreamVolume` and `adjustVolume` entries.
- No source describes a shipping app that mutes system audio based on live music detection; this is an inferred design.

## Ranking of alternatives by coverage, effort, latency and legality/policy risk (synthesis)

### Takeaway
No single alternative replaces system-wide interception; the best practical portfolio is (1) an own Android player/client with an in-pipeline separator for YouTube and shared files, (2) a link-based "prepare then play" cloud service (HaramMute pattern) for Reels/TikTok/YouTube links on both platforms, and (3) for users who want 100% coverage including DRM apps, a second device (Linux SBC/PC) acting as a Bluetooth sink running the separator. On iOS, only (2), a Safari extension for web video, and (3) are possible.

### Cited Findings
- Coverage limiters used in the ranking: iOS broadcast extensions miss AVPlayer/Safari/Music audio ([Twilio README](https://github.com/twilio/video-quickstart-ios/blob/master/ReplayKitExample)); Android playback capture is refused by opted-out/copyrighted-content apps ([AudioRelay community](https://community.audiorelay.net/t/audio-capture-no-longer-working-for-some-android-apps/3924)); Web Audio outputs silence for cross-origin media ([WebAudio issue 2453](https://www.github.com/WebAudio/web-audio-api/issues/2453)); HaramMute covers YouTube only, no live streams ([haram-mute.com](https://haram-mute.com/)); A2DP sink carries everything the phone outputs ([bluez-alsa](https://github.com/arkq/bluez-alsa)).
- Latency anchors: HS-TasNet 23 ms ([arXiv 2402.17701](https://arxiv.org/abs/2402.17701)); DSP-class model 10.43 ms/frame ([arXiv 2609.12201](https://arxiv.org/abs/2609.12201)); DeepFilterNet minimum 20 ms ([DeepFilterNet README](https://github.com/Rikorose/DeepFilterNet/blob/main/ladspa/README.md)); scrcpy 50 ms default buffer ([scrcpy audio.md](https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md)); AudioShake <50 ms on-device ([AudioShake](https://www.audioshake.ai/products/sdk)); zplane 245 ms DAW plugin ([Gearspace](https://gearspace.com/gear/zplane-peel-stems.68761/)).
- Policy/legal anchors: jailbreak reach is A8-A13 and iOS 26.0.x only ([iClarified](https://www.iclarified.com/jailbreak)); Apple warns against ducking others "for more than a few seconds" ([Apple duckOthers](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/duckothers)); HaramMute is live on the Chrome Web Store with ~20k users and on AMO, and its site says it ships Android and iOS apps ([Chrome Web Store](https://chromewebstore.google.com/detail/bbkbpldbnkoncockinoapcmbiijejgpn); [haram-mute.com](https://haram-mute.com/)).

### Inferences
Ranking (coverage estimates are the researcher's judgment of the user's listed sources: YouTube, Instagram/TikTok reels, WhatsApp/Telegram videos, Netflix, Spotify/podcasts, web browsers, games):

1. Own player/client with in-pipeline separation (Android; Media3 `AudioProcessor`, NewPipe/LibreTube fork, share-target for video files). Coverage: YouTube full, WhatsApp/Telegram videos full (Open with), browser via embedded WebView partial, Reels/TikTok only via link download, Netflix/Spotify/games none; roughly 40-55% of typical listening. Effort: medium (model integration, fork maintenance). Latency: can be zero perceived (delay video to match). Risk: low (App/Play policy fine; YouTube ToS risk for third-party clients, same as NewPipe).
2. Link-based cloud "prepare then play" (HaramMute pattern; works on iOS and Android, browser extension + app). Coverage: YouTube, public Reels/TikTok links, shared files; not live streams, not Netflix/Spotify/games; roughly 35-50%. Effort: medium (backend, downloader maintenance, quotas). Latency: seconds to minutes of preparation, then perfect sync. Risk: medium (platform scraping ToS; ongoing server cost; privacy disclosure).
3. Browser-centric on-device processing (custom Android browser or Firefox-Android/Safari-iOS extension with AudioWorklet model). Coverage: all web-delivered video that is same-origin for Web Audio (YouTube web, Instagram/TikTok web, news sites) but none of the native apps; 25-40% if the user is willing to move to web versions. Effort: medium-high (model in WASM/WebGPU, worker threading). Latency: 20-100 ms plus model. Risk: low.
4. Second device as Bluetooth A2DP sink running the separator (Linux SBC/laptop; Windows Bluetooth Audio Receiver). Coverage: 100% of phone output including Netflix/Spotify/games on iOS and Android. Effort: medium (bluez-alsa/PipeWire + model), but hardware carried by the user. Latency: Bluetooth ~100-200 ms plus model, visible lip-sync drift. Risk: low legally; poor mobility.
5. Phone-to-PC streaming (scrcpy/AudioRelay, Android only) plus desktop PipeWire filter-chain. Coverage: Android apps that allow playback capture (YouTube, social, messaging, browsers, most games; not DRM apps); 60-80% but desk-bound. Effort: low-medium (DeepFilterNet already shows the sink pattern; a separation plugin is needed). Latency: ~50 ms buffer plus model. Risk: low.
6. Detection + mute/duck (Android: no capture permission needed for volume; needs capture or metadata for detection). Coverage: can act on all non-DRM audio but removes the voice too. Effort: low. Latency: n/a. Risk: low; UX poor. iOS: foreground-only, not viable in background.
7. Jailbreak (iOS) / custom earbud or dongle hardware. Coverage: potentially 100%, but jailbreak reaches only A8-A13 devices on old firmware, and a hardware product is a separate business. Effort: very high. Risk: high (no store distribution; hardware certification).

What is impossible vs. hard: impossible on stock iOS is any background modification of other apps' audio, and muting other apps while they play; hard but possible are everything in rows 1-5. On Android the parallel (another researcher's scope) is playback capture with DRM opt-outs, which is "hard with gaps," not impossible.

### Gaps
- Coverage percentages are judgment estimates; no usage-share data for the user's listening mix was collected.
- No source was found for a working ReVanced/LSPatch audio-processing patch, an Android app acting as an A2DP sink without an AOSP rebuild, or a consumer earbud that removes music while keeping speech; their absence is reported as "not found," not proven nonexistent.
