# Rootless Android Real-Time Interception, Modification, and Replacement of All Other Apps' Audio (Android 10 → late-2026 releases)

Scope: non-root only. Facts are tagged with the Android version they apply to. Exact permission names, API names, and manifest attributes are quoted. "Late 2026" status: Android 16 (API 36) is the current stable release; Android 17 exists only in beta/QPR reporting and is flagged as provisional.

---

## Key Question 1: AudioPlaybackCapture API — exact requirements, which apps opt out, and per-version changes

### Takeaway
AudioPlaybackCapture (Android 10 / API 29+) lets a non-root app copy audio from other apps, but only after MediaProjection user consent, only via a `mediaProjection` foreground service, and only for players whose `AudioAttributes` usage is `USAGE_MEDIA`, `USAGE_GAME`, or `USAGE_UNKNOWN` AND whose capture policy is `ALLOW_CAPTURE_BY_ALL`. Capturing does **not** silence the original — that is the core problem (addressed in Q2). Many music/video/DRM apps opt out, so they come out silent/unprocessed.

### Cited Findings — exact requirements
- The API "gives apps the ability to copy the audio being played by other apps... introduced in Android 10." To capture, an app MUST: (1) hold the [`RECORD_AUDIO`](https://developer.android.com/reference/android/Manifest.permission#RECORD_AUDIO) permission; (2) "bring up the prompt displayed by `MediaProjectionManager.createScreenCaptureIntent()`, and the user must approve it"; (3) the capturing and playing apps must be in the same user profile — [Android AV capture guide](https://developer.android.com/media/platform/av-capture).
- Build an [`AudioRecord`](https://developer.android.com/reference/android/media/AudioRecord) and attach an [`AudioPlaybackCaptureConfiguration`](https://developer.android.com/reference/android/media/AudioPlaybackCaptureConfiguration) via `AudioRecord.Builder.setAudioPlaybackCaptureConfig(...)` — [AV capture guide](https://developer.android.com/media/platform/av-capture).
- Capturable usages: the player "must set its usage to `USAGE_MEDIA`, `USAGE_GAME`, or `USAGE_UNKNOWN`." All other usages cannot be captured. Confirmed verbatim in AOSP source: `AudioPlaybackCaptureConfiguration.java` doc states "the usage value MUST be `USAGE_UNKNOWN` or `USAGE_GAME` or `USAGE_MEDIA`. All other usages CAN NOT be captured." — [AV capture guide](https://developer.android.com/media/platform/av-capture); AOSP `frameworks/base/media/java/android/media/AudioPlaybackCaptureConfiguration.java` (fetched via android.googlesource.com).
- Config filter methods (choose matching OR excluding, never both for a given axis): `addMatchingUsage(int)`, `excludeUsage(int)`, `addMatchingUid(int)`, `excludeUid(int)`. "You cannot use `addMatchingUsage()` and `excludeUsage()` together... you cannot use `addMatchingUid()` and `excludeUid()` at the same time." — [AV capture guide](https://developer.android.com/media/platform/av-capture).
- Capture-policy opt-in/opt-out (source app side):
  - Manifest attribute `android:allowAudioPlaybackCapture="true"` / `="false"` in the player app's `manifest.xml`.
  - Or `AudioManager.setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_ALL)`.
  - Or per-player `AudioAttributes.Builder.setAllowedCapturePolicy(...)`; AAudio: `AAudioStreamBuilder_setAllowedCapturePolicy(AAUDIO_ALLOW_CAPTURE_BY_ALL)`.
  - Policy values: `ALLOW_CAPTURE_BY_ALL`, `ALLOW_CAPTURE_BY_SYSTEM`, `ALLOW_CAPTURE_BY_NONE`. "The most restrictive capture policy is always applied." — [AV capture guide](https://developer.android.com/media/platform/av-capture).
- targetSdk default: "apps that target Android 10 (API level 29) or higher allow their audio to be captured" by default; apps targeting ≤ Android 9 do NOT permit capture unless they add `allowAudioPlaybackCapture="true"`. — [AV capture guide](https://developer.android.com/media/platform/av-capture).
- System components can capture by default regardless (used for accessibility/captioning); an app can block even the system with `ALLOW_CAPTURE_BY_NONE`. — [AV capture guide](https://developer.android.com/media/platform/av-capture).
- DRM/encrypted content: "DRM-protected apps may produce silent or garbled recordings because the audio is only decrypted for playback, not for capture." (secondary/forum summary) — [EaseUS/search summary]; consistent with the general rule.
- Capture "does not affect the latency of the app whose audio is being captured" — i.e., capture is non-destructive/read-only; it does NOT stop or mute the original. — [AV capture guide](https://developer.android.com/media/platform/av-capture).

### Cited Findings — foreground service type (Android 14+ mandatory)
- Apps targeting Android 14 (API 34)+ must declare `android:foregroundServiceType="mediaProjection"` on the service, declare `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />` (plus `FOREGROUND_SERVICE`), and pass `FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION` to `startForeground()`. — [FGS types doc](https://developer.android.com/develop/background-work/services/fg-service-types); [Media projection doc](https://developer.android.com/media/grow/media-projection).
- Runtime order: "Call `createScreenCaptureIntent()`... before starting the foreground service... After you have created the foreground service, you can call `MediaProjectionManager.getMediaProjection()`." — [FGS types doc](https://developer.android.com/develop/background-work/services/fg-service-types).
- If no FGS type is declared, system throws `MissingForegroundServiceTypeException`. — [Media projection doc](https://developer.android.com/media/grow/media-projection).
- `microphone` FGS type exists separately (`FOREGROUND_SERVICE_MICROPHONE`, `RECORD_AUDIO`); but AudioPlaybackCapture is covered by the `mediaProjection` type, not `microphone`.

### Cited Findings — per-version changes
- **Android 10 (API 29):** AudioPlaybackCapture introduced. — [AV capture guide](https://developer.android.com/media/platform/av-capture).
- **Android 11 (API 30):** `EFFECT_POST_PROCESSING` / `EFFECT_PRE_PROCESSING` connection modes added (relevant to effect attachment). `WindowMetrics` APIs for projection sizing. — [AudioEffect ref](https://developer.android.com/reference/android/media/audiofx/AudioEffect); [Media projection doc](https://developer.android.com/media/grow/media-projection).
- **Android 12L (API 32):** projection surface scaling maintains aspect ratio. — [Media projection doc](https://developer.android.com/media/grow/media-projection).
- **Android 14 (API 34):** (a) `mediaProjection` FGS type + `FOREGROUND_SERVICE_MEDIA_PROJECTION` become mandatory; (b) **single-app ("app screen sharing")** — users can share one app window instead of the whole screen, enabled by default; opt out via `createScreenCaptureIntent(MediaProjectionConfig)` with `createConfigForDefaultDisplay()`; (c) `createVirtualDisplay()` throws `SecurityException` if the screen-capture `Intent` from `createScreenCaptureIntent()` is passed to `getMediaProjection()` more than once, or if `createVirtualDisplay()` is called more than once on the same `MediaProjection`. A consent is single-use. — [Media projection doc](https://developer.android.com/media/grow/media-projection).
- **Android 15 (API 35):** (a) **Screenshare/sensitive-content protection** — notification content hidden during screen sharing; sensitive fields (password inputs) hidden; developers can mark views with `View.setContentSensitivity(...)`; a **Developer Options** toggle **"Disable screen share protections"** exempts demo/test. (b) **Media projection status bar chip + auto-stop on lock** (ships in **Android 15 QPR1** or higher): a prominent chip alerts the user, and "screen projection automatically stops when the device screen is locked"; app must handle `MediaProjection.Callback.onStop()`. (c) Apps targeting Android 15+ cannot launch a `mediaProjection` (or mediaPlayback/dataSync/phoneCall) FGS from a `BOOT_COMPLETED` receiver. — [Android 15 behavior-changes-all](https://developer.android.com/about/versions/15/behavior-changes-all).
- **Android 15 — screen-recording detection:** new `DETECT_SCREEN_RECORDING` permission and a screen-recording callback API let apps detect when they are being recorded (present in AOSP Shell manifest as `android.permission.DETECT_SCREEN_RECORDING`); a security vendor notes "a screen recording callback will also detect any app using the MediaProjection binary." — [Guardsquare](https://guardsquare.com/blog/android-15-screen-spying-protection); AOSP `packages/Shell/AndroidManifest.xml`.
- **Android 16 (API 36):** No MediaProjection/AudioPlaybackCapture-specific behavior change found in the official behavior-changes-all page. Notable adjacent change: "Direct and offload audio playback invalidates previously open direct or offload audio tracks when resource limits are reached." ART internal-structure changes may break libraries relying on non-SDK interfaces (relevant to Shizuku hidden-API use). — [Android 16 behavior-changes-all](https://developer.android.com/about/versions/16/behavior-changes-all).
- **Android 17 (beta / provisional, 2026):** QPR1 Beta 3 reporting says the system screen recorder defaults to the last-used app and uses quick toggles for device/mic audio; a blog mentions an unverified compat flag `MEDIA_PROJECTION_PREVENTS_REUSING_CONSENT` (incomplete in beta). Not in official stable release notes — treat as unconfirmed. — [search summary / news.qq.com, cloudspress].

### Cited Findings — which popular apps opt OUT (concrete evidence)
- RootlessJamesDSP README "Unsupported apps include: **Spotify** (patch exists), **Google Chrome**, **SoundCloud**." Explanation: "Apps such as Spotify block internal audio capture (they don't want people to record their songs)." — [RootlessJamesDSP README](https://github.com/thepbone/RootlessJamesDSP).
- README "Apps confirmed working: **YouTube**, **YouTube Music**, Amazon Music, Deezer, Poweramp, Substreamer, **Twitch**, Spotify ReVanced (patch), **Apple Music**, Vinyl Music Player." So YouTube's native app is capturable; Chrome (and thus web YouTube/Netflix in-browser) is not. — [RootlessJamesDSP README](https://github.com/thepbone/RootlessJamesDSP).
- Spotify opt-out is defeated by the **ReVanced "Remove screen capture restriction" patch** (universal, re-signs the APK; cannot defeat apps using the **native AAudio C++ API** for playback). — [RootlessJamesDSP README](https://github.com/thepbone/RootlessJamesDSP).
- A developer forum report: capture works for games, the YouTube native app, and Spotify (pre-patch era), but **Chrome comes out silent** — [Reddit/dev thread via search summary].
- Netflix and other DRM streaming: video is blacked out and "sometimes the audio too... intentionally blocked by the streaming service" (forum/vendor summaries, anecdotal) — [search summary: macrumors/EaseUS].

### Inferences
- Any always-on rootless processor built on AudioPlaybackCapture will inherently fail to process audio from DRM/streaming apps that set `ALLOW_CAPTURE_BY_NONE` or route web audio through Chrome; the only non-root fixes are per-app APK patching (ReVanced) which is not shippable on Play and breaks DRM/anti-tamper.
- The Android 15 QPR1 "auto-stop on screen lock" is a hard functional break for an always-on processor: when the screen locks, the MediaProjection stops, so capture (and thus the processed output) halts until re-consented. This is likely the single biggest post-2024 reliability problem for this architecture.

### Gaps
- I did not decompile manifests of Instagram, TikTok, WhatsApp, Telegram, Facebook, X, Snapchat, Netflix to read their literal `allowAudioPlaybackCapture` value; no primary decompiled evidence per app was found. The general rule (apps targeting API 29+ default to capturable unless they set `="false"` or use `ALLOW_CAPTURE_BY_NONE`/AAudio) applies, but exact per-app flags are unverified. Messaging/VoIP apps typically use `USAGE_VOICE_COMMUNICATION`, which is NOT capturable regardless of flag — so WhatsApp/Telegram call audio is intrinsically un-capturable by this API.

---

## Key Question 2: How RootlessJamesDSP actually mutes/replaces the original so the user hears ONLY the processed audio

### Takeaway
RootlessJamesDSP does NOT use any per-app volume API to silence the original. The trick: it (1) uses the shell-granted `android.permission.DUMP` permission to `dumpsys` the audio services and enumerate every other app's **live audio session ID, UID, usage, and capture policy**; (2) for each such session it attaches a **high-priority insert `AudioEffect` that drives the gain to silence** (effectively muting the original in place); and simultaneously (3) captures that same audio via AudioPlaybackCapture, runs JamesDSP on it, and re-emits it through its own `AudioTrack`. The user hears only the processed copy. No `CAPTURE_AUDIO_OUTPUT` is granted (impossible rootless) — only `DUMP` (+ MediaProjection consent, +AppOps on 15+).

### Cited Findings — the muting mechanism (from source)
- The muting is done by `MutedAudioEffectFactory` attaching an `AudioEffect` to each **other app's session ID** (`sid`), created with priority `Int.MAX_VALUE` so it seizes control of the effect engine. Two effect types:
  - **DynamicsProcessing**: `DynamicsProcessing(Int.MAX_VALUE, sid, null)` then `setInputGainAllChannelsTo(-200f)` — -200 dB input gain = silence. (Requires API 28 / Android P.)
  - **Hidden "Volume" effect** (`AudioEffectHidden`, type UUID `09e8ede0-ddde-11db-b4f6-0002a5d5c51b`): `setParameter(VolumeParams.MUTE.ordinal, 1)` and `setParameter(VolumeParams.LEVEL.ordinal, -96)`.
  — RootlessJamesDSP `app/src/main/java/.../utils/MutedAudioEffectFactory.kt` (cloned from [github.com/thepbone/RootlessJamesDSP](https://github.com/thepbone/RootlessJamesDSP)).
- The muting effect self-heals: `setEnableStatusListener` re-enables and re-applies `setInputGainAllChannelsTo(-200f)` if another app toggles it off; `setControlStatusListener` fires `sessionLossListener` when control is lost (so it can re-mute or mark the session). — `MutedAudioEffectFactory.kt`.
- Why this is legal for a normal app: attaching an `AudioEffect` to a **non-zero** session ID that you know does NOT require any special permission in AudioFlinger. AOSP `AudioFlinger::createEffect` only calls `settingsAllowed()` (i.e., requires `MODIFY_AUDIO_SETTINGS`) for `AUDIO_SESSION_OUTPUT_MIX` (session 0); for a "general sessionId" there is no permission check — only a TODO comment about verifying the caller owns a track in that session. So any app that discovers another app's session ID can insert an effect into it. — AOSP `frameworks/av/services/audioflinger/AudioFlinger.cpp` (createEffect, ~line 4334: "check audio settings permission for global effects ... if (sessionId == AUDIO_SESSION_OUTPUT_MIX) { if (!settingsAllowed()) ... PERMISSION_DENIED }").
- Discovering session IDs is the part that needs privilege: RootlessJamesDSP dumps system services and regex-parses them. Detection methods in the app: **"AudioService dump (recommended)"** and **"AudioPolicyService dump"**. It calls `serviceBinder.dumpAsync(writePipe.fileDescriptor, args)` on the system service binder (requires `DUMP`). Target service string: `media.audio_policy`. Regexes parse `Session Id:`, `UID:`, `Content type:`, `Usage:`, and `allowPlaybackCapture=<bool> ... packageName=<pkg>`. — `session/dump/provider/AudioPolicyServiceDumpProvider.kt`, `session/dump/utils/DumpUtils.kt`, `session/dump/DumpManager.kt`.
- The capture+replay path: `RootlessAudioProcessorService.kt` builds `AudioPlaybackCaptureConfiguration.Builder(mediaProjection)` with `.addMatchingUsage(USAGE_MEDIA)`, `.addMatchingUsage(USAGE_GAME)`, `.addMatchingUsage(USAGE_UNKNOWN)`, plus `configBuilder.excludeUid(it)` for excluded/unsupported UIDs; it reads via `AudioRecord`, processes with the JamesDSP engine, and writes to an `AudioTrack` built with `.setUsage(AudioAttributes.USAGE_UNKNOWN)`, `MODE_STREAM`, `WRITE_BLOCKING`. — `service/RootlessAudioProcessorService.kt`.
- Foreground service: `startForeground(..., ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)`; `getMediaProjection(...)`; `MediaProjection.Callback.onStop()` handled. Manifest declares `android:foregroundServiceType="mediaProjection"`. — `RootlessAudioProcessorService.kt`, `app/src/main/AndroidManifest.xml`.

### Cited Findings — exact permissions granted via ADB/Shizuku
- Manifest `uses-permission` (rootless flavor): `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PROJECTION`, `FOREGROUND_SERVICE_DATA_SYNC`, `SYSTEM_ALERT_WINDOW`, **`MODIFY_AUDIO_SETTINGS`** (normal), `RECORD_AUDIO`, and **`android.permission.DUMP`** (with `tools:ignore="ProtectedPermissions"`). — `app/src/main/AndroidManifest.xml`.
- The ONE privileged permission it needs granted out-of-band is **`android.permission.DUMP`**. Manual/ADB method string shown in-app: `pm grant %s android.permission.DUMP` ("Navigate to 'Interactive Shell' and execute: `pm grant <pkg> android.permission.DUMP`"). Via Shizuku it calls `PermissionManager_grantRuntimePermission(packageName, permissionName, ...)` or falls back to `exec("pm grant " + packageName + " " + permissionName)`. — `strings.xml` (onboarding), `hidden-api-impl/.../ShizukuSystemServerApi.java`, `fragment/OnboardingFragment.kt` ("Granting DUMP via Shizuku").
- It does **NOT** grant `CAPTURE_AUDIO_OUTPUT`. (Confirmed impossible — see Q3; `DUMP` is `signature|privileged|development`, so shell/`pm grant` can grant it; `CAPTURE_AUDIO_OUTPUT` is `signature|privileged|role` and cannot be granted by shell.) — AOSP `core/res/AndroidManifest.xml` protectionLevels.
- Shizuku helper also exposes `AppOpsService_setMode(...)` with op `PROJECT_MEDIA` (AppOps `PROJECT_MEDIA`) and `AudioPolicyService_setAllowedCapturePolicy(uid, flags)`. Changelog #49: "Request users to grant the 'PROJECT_MEDIA' permission on Android 15+ due to new screen sharing restrictions" — i.e., on 15+ it pre-grants the PROJECT_MEDIA AppOp (via shell/Shizuku) so the projection consent is smoother/persistent. — `ShizukuSystemServerApi.java`, `fastlane/.../changelogs/49.txt`.
- Setup methods offered: **Shizuku** (Android 11+, no PC) or **manual ADB** (`pm grant ... DUMP` from a computer or on-device wireless-debugging shell). — `strings.xml` onboarding; `OnboardingFragment.kt`.

### Cited Findings — reported latency and problems
- README limitations: "**Increased audio latency**"; "Apps blocking internal audio capture remain unprocessed (e.g., Spotify, Google Chrome)"; "**Cannot coexist with (some) other audio effect apps** (e.g., Wavelet and other apps that make use of the `DynamicsProcessing` Android API)." — [RootlessJamesDSP README](https://github.com/thepbone/RootlessJamesDSP). (Conflict with Wavelet is direct: both try to grab the `DynamicsProcessing` engine on sessions.)
- In-app strings quantify two distinct delays:
  - **Session-detection delay / double audio**: "After an app has opened a new media session to playback audio, you may hear **duplicated or cut-off audio** for a very short period (**about <250ms**)." (This is the window between the original starting and the mute effect being attached.) — `strings.xml` (`limit_detect_delay`).
  - **Processing latency / AV-desync**: "This app may add some delay to the audio stream. You can add movie/video apps to the exclusion list to prevent **AV-desync** by not processing them." — `strings.xml` (`limit_latency`).
- Real-world latency report: GitHub issue #201 (Nothing Phone 2, Shizuku) reports a consistent ~**half-second (≈500 ms)** audio delay watching video; buffer-size slider had no effect; a commenter attributes most latency to the capture path, "basically not fixable." (community report, not an official measurement). — [RootlessJamesDSP issue #201](https://github.com/timschneeb/RootlessJamesDSP/issues/201).
- **Echo**: changelog #44 "**Prevent audio echo on some devices**" — confirms echo/double-audio was a real device-specific bug class. — `fastlane/.../changelogs/44.txt`.
- **Bluetooth**: a Surface Duo 2 Reddit thread recommends the app for device audio lag but says "not to use it with Bluetooth earphones." (community, device-specific). — [redlib mirror of r/surfaceduo](https://redlib.ssps.io/r/surfaceduo/comments/1c2kp3w/).
- **OEM / Android-version breakage**: changelogs show repeated breakage requiring fixes on Android 14 (quick-tile crash, FGS/backup crash, setup-wizard crash) and Android 15 (Shizuku setup crash, screen-sharing restriction warning, PROJECT_MEDIA grant). — `fastlane/.../changelogs/46-50.txt`.
- Tested devices: Samsung Galaxy S20+ (Android 12, OneUI 4.0), AOSP emulator (10–13), Pixel 6 Pro (13), Pixel 6a. — README.
- Distribution: the rootless app is on **Google Play** and **F-Droid**. — README.

### Cited Findings — "legacy mode" / "enhanced processing"
- Neither term appears in the RootlessJamesDSP README or the fetched sources. "Legacy mode" is a **Wavelet** concept, not a RootlessJamesDSP one (see Q4). RootlessJamesDSP's own wording for its approach is "uses a bunch of tricks to gain full access to the audio stream of other apps... via Android's internal audio capture." — [RootlessJamesDSP README](https://github.com/thepbone/RootlessJamesDSP).

### Inferences
- The muting is per-session and reactive: it depends on polling the dumps to find a new session and then attaching the silencing effect. The documented "<250 ms" double-audio window and the self-healing listeners are direct evidence that the original is only silenced *after* detection — there is always a brief passthrough of the unmodified original. A perfectly clean "user hears only modified audio" is therefore not achievable; a short leak at each track start is inherent.
- Because muting rides on the `DynamicsProcessing`/Volume insert effect, apps that themselves grab that effect (Wavelet) or that are not detectable in the dump (or that block capture) cannot be muted-and-replaced cleanly.

### Gaps
- Exact end-to-end processing latency of the JamesDSP engine alone (separate from capture latency) is not published; only the ~500 ms total field report and the "<250 ms" detection window are documented.

---

## Key Question 3: Shizuku / Sui / Dhizuku / ADB shell (UID 2000) — which audio hidden APIs become usable; can shell grant CAPTURE_AUDIO_OUTPUT?

### Takeaway
Shell (UID 2000, `com.android.shell`) holds a fixed set of audio permissions and can grant `development`-flagged permissions like `DUMP` to other apps via `pm grant`. Shell **cannot** grant `CAPTURE_AUDIO_OUTPUT`, `MODIFY_AUDIO_ROUTING`, `CAPTURE_MEDIA_OUTPUT`, or `MANAGE_AUDIO_POLICY` to a third-party app (they are `signature|privileged|role` or `signature`). What Shizuku realistically unlocks: `DUMP` (session discovery), AppOps toggles (`PROJECT_MEDIA`), and hidden `IAudioService`/`AudioPolicyService`/`IPlayer` methods callable while impersonating shell — enabling per-app/per-player volume control and per-UID capture policy changes.

### Cited Findings — shell's own audio permissions, per Android release (AOSP `packages/Shell/AndroidManifest.xml`)
- android-10: `DUMP`, `MANAGE_AUDIO_POLICY`.
- android-11: adds `CAPTURE_AUDIO_OUTPUT`, `RECORD_AUDIO` (+ DUMP, MANAGE_AUDIO_POLICY).
- android-12: same as 11.
- android-13: adds `MODIFY_AUDIO_ROUTING`.
- android-14: adds `CAPTURE_MEDIA_OUTPUT`.
- android-15 and android-16: same set as 14: `CAPTURE_AUDIO_OUTPUT`, `CAPTURE_MEDIA_OUTPUT`, `DUMP`, `MANAGE_AUDIO_POLICY`, `MODIFY_AUDIO_ROUTING`, `RECORD_AUDIO`.
  — AOSP `frameworks/base/packages/Shell/AndroidManifest.xml` at tags android-10.0.0_r1 … android-16.0.0_r1 (fetched via android.googlesource.com).
- Key consequence: the shell *process itself* holds `CAPTURE_AUDIO_OUTPUT` and `MODIFY_AUDIO_ROUTING` from Android 11/13 onward. A Shizuku/Sui-backed binder call executes *as that process*, so hidden APIs guarded by those permissions can be invoked through Shizuku — but the third-party APK is never itself granted those permissions.

### Cited Findings — protection levels (why shell can/can't grant each)
From AOSP `frameworks/base/core/res/AndroidManifest.xml`:
- `DUMP`: `protectionLevel="signature|privileged|development"` → grantable by shell via `pm grant` (the `development` flag is what lets ADB/Shizuku grant it). This is exactly what RootlessJamesDSP uses.
- `CAPTURE_AUDIO_OUTPUT`: `signature|privileged|role` → **NOT** grantable by shell/`pm grant` (no `development` flag). Confirmed: shell cannot give this to a normal app.
- `CAPTURE_MEDIA_OUTPUT`: `signature|privileged|role` → not shell-grantable.
- `MODIFY_AUDIO_ROUTING`: `signature|privileged|role` → not shell-grantable.
- `MODIFY_AUDIO_SETTINGS`: `normal` → any app gets it by declaring it.
- `MODIFY_AUDIO_SETTINGS_PRIVILEGED`: `signature|privileged` → not shell-grantable.
- `MANAGE_AUDIO_POLICY`: `signature` → not shell-grantable.
- `MODIFY_DEFAULT_AUDIO_EFFECTS`: `signature|privileged` → not shell-grantable (needed for effects on `AUDIO_SESSION_OUTPUT_STAGE`/`AUDIO_SESSION_DEVICE`).
  — AOSP `core/res/AndroidManifest.xml` (fetched).

### Cited Findings — hidden audio APIs usable with shell privilege
- **Per-player volume** (used by yume-chan **Volume Manager**, Shizuku-based): `AudioManager.getActivePlaybackConfigurations()` → `AudioPlaybackConfiguration.getPlayerProxy()` → `PlayerProxy.setVolume(float)` (which calls `IPlayer.setVolume()` in `frameworks/av`). Requires Android **13** minimum. `PlayerProxy` is `@SystemApi @hide` with `start()/pause()/stop()/setVolume(float)/setPan(float)/setStartDelayMs(int)/applyVolumeShaper(...)`. `AudioPlaybackConfiguration.getPlayerProxy()`, `getClientUid()`, `getSessionId()` are `@SystemApi`. — [VolumeManager README](https://github.com/yume-chan/VolumeManager); AOSP `AudioPlaybackConfiguration.java`, `PlayerProxy.java`.
- **NoMixer/AppMixer** fork: uses `AudioManager.registerAudioPlaybackCallback()` to catch new `AudioPlaybackConfiguration`s and re-apply volume; README notes "this API can only set volume, not read" and says it is "the same API as MIUI's 'Adjust media sound in multiple apps'." Android 13 min. — [AppMixer](https://github.com/0NLyM/AppMixer) (search summary).
- There is **no public `AudioManager.setAppVolume(...)`** method confirmed by name in these sources; the per-app volume path in practice is `getActivePlaybackConfigurations()` → `getPlayerProxy().setVolume()`. (The "App Volume Control"-style apps use this PlayerProxy mechanism, not a single `setAppVolume` symbol.) — see Gaps.
- **Per-UID capture policy**: RootlessJamesDSP's Shizuku helper exposes `AudioPolicyService_setAllowedCapturePolicy(int uid, int flags)` (hidden `IAudioPolicyService` method) — callable as shell. — `ShizukuSystemServerApi.java`.
- **AppOps**: `IAppOpsService.setMode(...)` with op `PROJECT_MEDIA` (string op) to pre-authorize media projection on Android 15+. — `ShizukuSystemServerApi.java`.
- **dumpsys**: `dumpsys audio` / `media.audio_policy` / `media.audio_flinger` binder `dumpAsync()` requires `DUMP`; yields session IDs, UIDs, usages, and `allowPlaybackCapture` flags. — RootlessJamesDSP dump providers.
- `cmd media_session` and `AudioManager.setStreamVolume()` on other streams are shell-executable but are blunt (whole-stream, not per-app) — not evidenced as used by these projects for selective replacement.

### Inferences
- The maximum a rootless+Shizuku app can achieve on the "silence the original" problem without the insert-effect trick is **per-player volume = 0** via `PlayerProxy.setVolume(0f)` (Android 13+). That is cleaner than the effect trick for muting but still cannot silence capture-blocking apps and still can't *replace* audio by itself (you still need AudioPlaybackCapture + your own AudioTrack for the processed stream).
- Confirmed: **No**, shell cannot grant `CAPTURE_AUDIO_OUTPUT` (or MODIFY_AUDIO_ROUTING / CAPTURE_MEDIA_OUTPUT / MANAGE_AUDIO_POLICY) to a third-party app. Capture of arbitrary output without MediaProjection is only possible for the shell process itself (so scrcpy-style "run as shell" works, but a normally-installed app cannot inherit it).

### Gaps
- Whether any OEM (e.g., Samsung One UI, MIUI/HyperOS) exposes a literal `AudioManager.setAppVolume(...)` hidden symbol usable by third parties is unconfirmed; sources only confirm the `PlayerProxy.setVolume` route. Dhizuku (device-owner based) vs Shizuku differences for these specific audio calls were not separately documented in the sources found.

---

## Key Question 4: Global AudioEffect on session 0 and the ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION mechanism

### Takeaway
Attaching an insert effect to session 0 (global output mix) is deprecated since API 24 and only requires the `normal` permission `MODIFY_AUDIO_SETTINGS`, but it is limited to the platform's built-in effects (Equalizer, BassBoost, Virtualizer, PresetReverb/EnvironmentalReverb, LoudnessEnhancer, DynamicsProcessing, HapticGenerator) — you cannot register a custom/arbitrary DSP or neural net there. The `ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION` broadcast only tells an effect-control app *which session ID* to attach those same built-in effects to; it cannot inject custom code. This is why Wavelet/Poweramp-EQ-style apps can only offer parametric EQ etc., not arbitrary processing.

### Cited Findings
- "NOTE: attaching insert effects (equalizer, bass boost, virtualizer) to the global audio output mix by use of session 0 is deprecated." (The reference's note; the broader deprecation of global/output-mix effects dates to API 24.) — [AudioEffect reference](https://developer.android.com/reference/android/media/audiofx/AudioEffect).
- Permission for a global (session 0 = `AUDIO_SESSION_OUTPUT_MIX`) effect is `MODIFY_AUDIO_SETTINGS` (AudioFlinger `createEffect` calls `settingsAllowed()` only for `AUDIO_SESSION_OUTPUT_MIX`). `MODIFY_AUDIO_SETTINGS` is `protectionLevel="normal"`. — AOSP `AudioFlinger.cpp`; `core/res/AndroidManifest.xml`.
- Available effect subclasses (the ONLY things you can instantiate): `AcousticEchoCanceler`, `AutomaticGainControl`, `BassBoost`, `DynamicsProcessing`, `EnvironmentalReverb`, `Equalizer`, `HapticGenerator`, `LoudnessEnhancer`, `NoiseSuppressor`, `PresetReverb`, `Virtualizer`. "Applications should not use the AudioEffect class directly but one of its derived classes." `Virtualizer` deprecated in API 35 (use `Spatializer`). — [AudioEffect reference](https://developer.android.com/reference/android/media/audiofx/AudioEffect).
- `queryEffects()` returns only effects "available on the platform" — i.e., there is no API to add a new effect implementation from an app. Custom native effects require a `libeffects` entry in the system image (root/OEM only). — [AudioEffect reference](https://developer.android.com/reference/android/media/audiofx/AudioEffect).
- Broadcast mechanism (how Wavelet / Poweramp EQ hook players): players broadcast `ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION` (const `"android.media.action.OPEN_AUDIO_EFFECT_CONTROL_SESSION"`) with mandatory extras `EXTRA_AUDIO_SESSION` (`"android.media.extra.AUDIO_SESSION"`, the int session ID) and `EXTRA_PACKAGE_NAME` (`"android.media.extra.PACKAGE_NAME"`); `ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION` on stop; `ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL` to show a UI; optional `EXTRA_CONTENT_TYPE`. The effect-control app then "create[s] all required audio effects and appl[ies] the effect settings to the specified audio session." — [AudioEffect reference](https://developer.android.com/reference/android/media/audiofx/AudioEffect).
- Wavelet relies on this broadcast; players that do NOT broadcast (Tidal, Pandora, YouTube, SoundCloud, Qobuz, VLC, Plexamp, foobar2000, many preinstalled apps) show no effect. Wavelet's **"Legacy mode"** (off by default) and a reflected `dumpsys audio` parse are fallbacks to pick up non-broadcasting sessions; legacy-mode behaviour "depends on your device manufacturer's audio framework implementation." Enabling "clipping reduction" processes in a bigger time frame (**170 ms vs 22 ms**), trading latency for fewer clicks. — [Wavelet fork README](https://github.com/damianos133eu/Wavelet); [XDA Wavelet thread](https://forum.xda-developers.com/t/app-9-0-wavelet-headphone-specific-equalization.4097957/).

### Inferences
- Can the `ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION` / session-0 mechanism be used to apply a *custom* effect (DSP/NN)? **No.** It only selects which built-in platform effect is attached to which session. For arbitrary custom processing you must leave this mechanism entirely and go the capture-process-replay route (AudioPlaybackCapture) — which is precisely why RootlessJamesDSP exists and why it (ab)uses `DynamicsProcessing` only as a *mute* tool, not as its actual DSP.
- `DynamicsProcessing` (API 28) is the most flexible built-in (multiband EQ + compressor + limiter) and can be attached to session 0 with only `MODIFY_AUDIO_SETTINGS`; but it is still fixed-function, not programmable with arbitrary filters or a neural net.

### Gaps
- None material.

---

## Key Question 5: Alternative rootless tricks (A2DP sink, USB loopback, casting, VPN, AccessibilityService, OEM-only APIs)

### Takeaway
None of the alternatives give a clean, general, rootless "intercept-all → modify → hear only modified" path on a stock phone. A2DP sink is not implementable rootless; AccessibilityService cannot capture audio; VPN intercepts only network, not audio; casting to a same-device receiver is impractical and DRM-blocked; Samsung's per-app sound/Audio Eraser features are consumer UI with no documented third-party API.

### Cited Findings
- **Bluetooth A2DP sink (phone receives audio as if it were a speaker):** Not possible rootless. "Android does not implement the API calls to BlueZ regarding A2DP sink capabilities... trying to write an Android application that handles this will not be the solution for the A2DP sink role." Google's `sample-bluetooth-audio` A2DP sink runs on **Android Things** hardware, not a normal phone app. — [StackOverflow A2DP-sink](https://kaweah.freedombox.rocks/kiwix/content/stackoverflow.com_en_all_2023-11/questions/76873522/) ; [androidthings/sample-bluetooth-audio](https://github.com/androidthings/sample-bluetooth-audio). (And even if it worked, it only covers the one source device's A2DP stream, not on-device app audio.)
- **AccessibilityService:** No audio-capture capability exists in the AccessibilityService API (it exposes UI tree, gestures, and events only). No source found grants it audio interception; it cannot be used for this. (Absence of any capability in the AccessibilityService reference; no counter-evidence found.)
- **VPN (VpnService):** Intercepts IP packets only; it has no relationship to the audio pipeline. Not applicable (self-evident; no source claims otherwise).
- **Casting / Chromecast receiver on the same phone:** No evidence of a practical same-device loopback; DRM/streaming apps block casting of protected content, and there is no stock API to register the phone as its own Cast sink. — no supporting primary source found (treat as not viable).
- **"Audio over USB" loopback:** USB audio accessory/host routing exists for external DACs/interfaces, but there is no rootless API to loop the device's own mixed output back into an app for processing. No source found demonstrating it. — Gap.
- **Samsung "Separate app sound":** Consumer One UI feature that routes one chosen app's sound to a Bluetooth/second output while other apps stay on the main output. "limited to the Samsung Galaxy series." Samsung's **Sound Assistant** (Good Lock plugin, by Samsung) can create separate app sounds and per-app controls. No public developer-facing `SemAudioManager` / Separate-App-Sound API for third parties was found. — [TechAdvisor](https://www.techadvisor.com/article/1503256/how-to-use-samsungs-separate-app-sound.html); [Samsung Community](https://r2.community.samsung.com/t5/Galaxy-M/Separate-app-sound-is-not-stable-amp-settings-not-persistent/td-p/10789133).
- **scrcpy (contrast case, shows what shell can do but an app can't):** scrcpy captures whole-system output using an `AudioRecord` with source `REMOTE_SUBMIX` because its server "is NOT an App, it's a Java application started from Android shell" (UID 2000). `REMOTE_SUBMIX` capture "disables playback on the device" (it reroutes, i.e., it *does* silence the original) — but this requires running as shell, which a normally-installed app cannot do. On Android 11 it must briefly open the shell's `com.android.shell.HeapDumpActivity` to appear foreground; `android.permission.RECORD_AUDIO` was added to shell in Android 11; Android 10 and earlier cannot capture. scrcpy also has `--audio-dup` (`playback` source + `ROUTE_FLAG_LOOP_BACK_RENDER`) to keep playing on-device while capturing, via `AudioPolicy.createAudioRecordSink` with hidden `AudioMix`/`AudioMixingRule` (needs `MODIFY_AUDIO_ROUTING` or a MediaProjection that can project audio). — [scrcpy doc/audio.md](https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md); [rom1v blog](https://blog.rom1v.com/2023/03/scrcpy-2-0-with-audio/); scrcpy `AudioPlaybackCapture.java`/`AudioDirectCapture.java`.
- AOSP confirms the privilege rule for the scrcpy `--audio-dup` loopback path: `AudioPolicy.Builder.setMediaProjection()` doc: "A MediaProjection that can project audio allows to register an audio policy LOOPBACK|RENDER **without the MODIFY_AUDIO_ROUTING permission**"; otherwise `AudioPolicy` registration needs `MODIFY_AUDIO_ROUTING`. — AOSP `media/java/android/media/audiopolicy/AudioPolicy.java`. The hidden route flag `ROUTE_FLAG_LOOP_BACK_RENDER` is `@hide` and its doc warns "The captured audio is an approximation of the played audio. Effects and volume are not applied... not suitable for echo cancelling." — AOSP `AudioMix.java`.

### Inferences
- The scrcpy `REMOTE_SUBMIX`/loopback approach is the "cleanest" rootless-capable silence-and-replace path *in principle* (it reroutes rather than just copies), but it is only reachable by a process running with shell UID. A standard app therefore cannot use it; the Shizuku model does not turn your app into a shell-UID process for AudioRecord purposes (AudioRecord attributes the record to your app's UID, which lacks the needed capture permission unless it uses MediaProjection). This is why RootlessJamesDSP uses MediaProjection AudioPlaybackCapture + the insert-effect mute, not REMOTE_SUBMIX.
- No OEM third-party API shortcut exists; Samsung's features are not programmable by other apps.

### Gaps
- Samsung's newer "Audio Eraser" (Galaxy AI) has no documented third-party API; I found no primary source exposing it to developers. USB output loopback viability rootless is unconfirmed (no demonstrating source).

---

## Key Question 6: Google Play policy for an always-on MediaProjection audio processor; sideload/F-Droid

### Takeaway
It is distributable on Google Play (RootlessJamesDSP itself ships there), but it requires declaring the `mediaProjection` foreground service type in Play Console with a description and a demo video, must satisfy prominent-disclosure/consent for recording, and is subject to review; F-Droid/sideload avoids the Play declaration entirely but still faces the OS-level consent and Android 15 restrictions.

### Cited Findings
- Apps targeting Android 14+ "must declare... foreground service types in the Play Console's app content page (Policy > App content)." — [FGS types doc](https://developer.android.com/develop/background-work/services/fg-service-types).
- Play Console requires, per FGS type: a description of the feature, the user impact if deferred/interrupted, a **link to a demo video**, and a chosen use case. For **media projection** the video must "Show the user initiating an app capturing, recording, or streaming of the device screen to an external display." Stated permitted use: "Project media to non-primary display or external devices using the MediaProjection APIs, including streaming." "All foreground service types are subject to review" and must comply with the Device and Network Abuse policy. — [Play support: foreground service & full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821).
- Prominent disclosure (User Data policy): required when "data collection occurs in the background when the user is not engaging with your app." The in-app disclosure must appear during normal use (not only in settings/privacy policy), describe the data and its use, immediately precede the consent request, and require affirmative action. "An app that records a user's screen" is given as personal/sensitive data subject to the policy; "microphone... and other sensitive device or usage data" are personal/sensitive. — [Play User Data policy / prominent disclosure](https://support.google.com/googleplay/android-developer/answer/10144311).
- Concrete proof of Play-distributability: RootlessJamesDSP (`me.timschneeberger.rootlessjamesdsp`) "is available for free on **Google Play**" and on **F-Droid**. — [RootlessJamesDSP README](https://github.com/thepbone/RootlessJamesDSP).

### Inferences
- A MediaProjection-based always-on processor can pass review if it presents the projection as user-initiated with a clear persistent notification and a demo video, and discloses the audio capture. The riskier parts for Play are: (a) requiring users to grant `DUMP` via ADB/Shizuku (out-of-store privilege escalation) — RootlessJamesDSP keeps that as an optional onboarding step, not a Play permission; (b) the ReVanced patching advice (clearly sideload-only). F-Droid builds avoid the FGS declaration and video review, which is why RootlessJamesDSP maintains an F-Droid flavor.

### Gaps
- No explicit Google statement that "always-on, continuous" media projection audio processing is prohibited was found; review appears case-by-case under the FGS/Device-and-Network-Abuse policies. The precise reviewer bar for a non-recording "processing" use of projection is not documented.

---

## Key Question 7: Latency numbers (capture→process→playback), NN overhead, lip-sync tolerance

### Takeaway
A well-tuned low-latency Oboe/AAudio round trip is ~20 ms, and fleet-average round-trip latency is under ~40 ms — but a MediaProjection capture→process→AudioTrack loop is far worse in practice (hundreds of ms; a RootlessJamesDSP field report is ~500 ms), because the capture path and blocking AudioTrack buffering dominate and the low-latency MMAP path is not available to captured/processed streams. A neural net adds its own frame/block latency on top. For video, audio lagging up to ~125 ms is below the detectability threshold and up to ~185 ms below the acceptability threshold (ITU-R BT.1359-1), so ~500 ms capture latency clearly breaks lip-sync — which is exactly why RootlessJamesDSP tells users to exclude video apps.

### Cited Findings
- Oboe/AAudio round-trip (OboeTester): ~**20 ms** with all low-latency recommendations; ~**21 ms** on an MMAP path skipping the output callback vs ~**62 ms** without MMAP; shared (not exclusive) ~26 ms; default performance mode ~205 ms; max buffer ~53 ms. "If you use blocking writes and you are on a device that does not support the AAudio MMAP mode, latency might be much higher." — [Oboe low-latency guide](https://developer.android.com/games/sdk/oboe/low-latency-audio).
- Fleet latency: "average latency of the most popular Android phones has dropped to under 40ms"; cited 39 ms round-trip (down from 109 ms in 2017); Pixel 3a was first Android phone at 10 ms; pro-audio target is 20 ms round-trip, long-term goal 10 ms. — [9to5Google](https://9to5google.com/?p=411357).
- RootlessJamesDSP field latency: ~**500 ms** watching video (issue #201); documented session-detection/double-audio window "**about <250 ms**"; the app warns to exclude video apps to avoid AV-desync. — [issue #201](https://github.com/timschneeb/RootlessJamesDSP/issues/201); RootlessJamesDSP `strings.xml`.
- Lip-sync tolerance (ITU-R BT.1359-1): detectability thresholds ≈ **+45 ms (audio leads)** to **−125 ms (audio lags)**; acceptability ≈ **+90 ms** to **−185 ms**. ATSC is tighter (lead ≤15 ms, lag ≤45 ms). Positive = audio precedes video. — [Wikipedia: Audio-to-video sync](https://en.wikipedia.org/wiki/Audio-to-video_synchronization); [ITU-R BT.1359-1 PDF](https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!MSW-E.doc).
- RootlessJamesDSP sets its own output `AudioTrack` with `USAGE_UNKNOWN`, `MODE_STREAM`, `WRITE_BLOCKING`, sample rate clamped 44100–48000, user-configurable buffer size in samples (with a low-buffer clipping warning) — i.e., it uses the normal (non-MMAP, blocking) Java `AudioTrack` path, which is inherently higher-latency than Oboe/AAudio exclusive MMAP. — RootlessJamesDSP `RootlessAudioProcessorService.kt`, `strings.xml`.

### Inferences
- Realistic capture→process→replay latency on this architecture is on the order of a few hundred ms (capture buffering + blocking AudioTrack + any processing), not the ~20 ms Oboe best case, because: (a) the captured stream and the re-emitted stream each carry their own buffers; (b) AudioPlaybackCapture/AudioRecord does not get the exclusive MMAP low-latency path; (c) the detection delay adds startup glitching. A neural net operating on, e.g., 10–40 ms frames adds at least one block of algorithmic latency plus inference time on top.
- For music-only use this is tolerable; for anything with video it is not (far exceeds the −185 ms acceptability bound), confirming the app's own guidance to exclude video apps. A rootless design that must stay lip-synced with video is not achievable with this capture path.

### Gaps
- No published, device-by-device latency table specifically for AudioPlaybackCapture; the ~500 ms figure is a single community report. The 9to5Google fleet numbers (~2021) and the OboeTester numbers are best/round-trip figures for direct low-latency paths, not for the capture-replay path, so they bound the problem rather than measure it.
