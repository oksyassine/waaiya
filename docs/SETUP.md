# One-time Android setup

Waaiya needs two things that Android only gives to the shell user (ADB):

    cmd package grant org.islamicmute.app android.permission.DUMP     # list other apps' sessions, mute the originals
    cmd appops set org.islamicmute.app PROJECT_MEDIA allow            # no screen-sharing question at every start

and, optionally, one more for the "Notification text" Quick Settings tile (Android 15+):

    cmd package grant org.islamicmute.app android.permission.WRITE_SECURE_SETTINGS

Without the first one the user hears the music and the filtered sound together. Both grants survive reboots and
app updates; they are lost only on uninstall (or `pm revoke`).

## The three routes (setup card, in this order)

1. **On this phone, no extra app (Android 11+).** Waaiya uses Android's own Wireless debugging: it pairs with the
   phone's adbd once, then connects to it and runs the two commands itself. Code: `WirelessSetup.kt` (service,
   notification, mDNS) and the `adb` package (protocol).
2. **Shizuku.** Still offered: on a rooted Android 10 phone it works without a computer, and on Android 12+ its
   shell layer can draw the screen-blur covers (`ShizukuCovers.kt`); Waaiya's own helper does the same without it
   (below).
3. **A computer** with `adb shell` (the commands above). Android 10 has no Wireless debugging pairing, so a
   computer is needed there (directly, or once to start Shizuku).

## Route 1: how it works

1. Start (setup card): asks for notifications (Android 13+), then opens Developer options; About phone when
   Developer options are off. A foreground service (type `dataSync`, at most 10 minutes) starts.
2. The service browses mDNS (`NsdManager`) for `_adb-tls-pairing._tcp` and `_adb-tls-connect._tcp`, keeps only
   announcements from this phone's own addresses, and shows a notification. Its "Enter code" action is a
   `RemoteInput`: the code is shown in Settings, so it is typed without leaving Settings. Leaving Settings closes
   the pairing screen (and adbd's pairing server: seen on Android 11), so the in-app field is only for split screen.
3. Pairing (`AdbPairingClient`): TLS 1.3 to 127.0.0.1:pairing-port with our certificate; password = the code + 64
   bytes exported from the TLS session (label `adb-label\0`); SPAKE2 messages; then both sides exchange their
   PeerInfo encrypted with AES-128-GCM (key from HKDF-SHA256 of the SPAKE2 key). Ours carries our RSA public key in
   adb's format, so Settings lists "waaiya@phone" under Paired devices. A wrong code shows up as a PeerInfo that does
   not decrypt, or adbd closing the connection.
4. Connect (`AdbShell`): CNXN, adbd answers STLS, TLS 1.3 with the same certificate (adbd only lets in paired keys),
   CNXN inside TLS, then one `shell:` stream running the two commands. The app then checks the result itself
   (`checkSelfPermission(DUMP)`, `hasProjectMediaAppOp()`), which is the source of truth.
5. Later runs (after a reboot, or if a grant was revoked) skip pairing: with Wireless debugging on, the service sees
   the connect port and connects with the stored key. If adbd refused the key (pairing removed, or Android's
   7-day expiry of unused keys), it asks for a code again.

The key pair (RSA-2048, PKCS#8 + a self-signed X.509 certificate written by `AdbKey`) lives in
`noBackupFilesDir/adb`; backup is off for the whole app. Nothing leaves the phone: every connection is to 127.0.0.1.

TLS exporter: Android 12+ has `android.net.ssl.SSLSockets.exportKeyingMaterial`. Android 11 has the same function in
the platform's Conscrypt (`com.android.org.conscrypt.Conscrypt`), not in the SDK, so it is called by reflection
with the HiddenApiBypass exemption already used by the screen blur.

## Why this route (and not a library)

| Candidate | Licence | Verdict |
|---|---|---|
| MuntashirAkon/libadb-android | GPL-3.0-or-later OR Apache-2.0, but depends on spake2-java, which is **LGPL-3.0** | Not used: LGPL dependency |
| Shizuku's adb module (RikkaApps/Shizuku manager) | Apache-2.0 (with name/icon restrictions) | Usable, but it builds BoringSSL's SPAKE2 as native code (JNI + CMake) and bundles Conscrypt: much more than needed |
| LADB (tytydraco/LADB) | BSD-3-Clause; ships an `adb` binary built from AOSP | Not used: runs a bundled executable (about 1 MB per ABI), heavier and harder to audit |
| Conscrypt (bundled) | Apache-2.0 | Not needed in the APK: Android 10+ already has TLS 1.3 and (12+) the exporter. Used only by the JVM interop test |
| BoringSSL SPAKE2 (crypto/curve25519/spake25519.cc) | Apache-2.0 | Ported to Kotlin (`Spake2.kt`, `Ed25519.kt`): about 200 lines |

Chosen: our own Kotlin, ported from BoringSSL's `spake25519.cc` and AOSP `packages/modules/adb` (both Apache-2.0,
recorded in `THIRD_PARTY_LICENSES.md` and `android/app/licences/adb-wireless-pairing-NOTICE.txt`), on the platform
TLS. No new runtime dependency, no native code, about 900 lines in all, and the whole protocol is unit-tested on the
JVM. The edwards25519 arithmetic uses BigInteger (not constant time): the secrets are one-time (a random scalar per
attempt and a code that Settings shows on screen and discards).

## How it was verified

- JVM unit tests (`./gradlew testDebugUnitTest --tests 'org.islamicmute.app.adb.*'`): RFC 8032 public keys,
  BoringSSL's M/N points against the coordinates in its source, the password-scalar fix, SPAKE2 agreement and a fixed
  regression vector, RFC 5869 HKDF vectors, the GCM nonce counter, pairing and adb framing, the adb public key
  against `adb keygen` output, the certificate, code parsing (Arabic-Indic digits, code + port), mDNS filtering and
  the setup state machine.
- `AdbInteropTest` (skipped unless `WAAIYA_ADB_PAIR=host:port:code` and/or `WAAIYA_ADB_CONNECT=host:port` are set):
  the same client run on the JVM against an emulator's adbd through `adb forward`. Paired and ran `id` as uid 2000
  on Android 11 (im_api30).
- Android 11 emulator (im_api30, Wi-Fi "AndroidWifi"), app built with `-PimX86`, grants revoked first: Start,
  Developer options, Wireless debugging, "Pair device with pairing code", code typed in the notification: paired and
  both grants given (`dump=0`, `project_media=0`, `DUMP: granted=true`, `PROJECT_MEDIA: allow`). A wrong code gives
  "That code was not accepted". With Wireless debugging off the notification says to turn it on. After a reboot the
  grants are still there; with them revoked, Start + Wireless debugging on connected and granted without a code.
- Android 15 emulator (im_ui35), same build, grants absent, Developer options off: Start asked for notifications,
  then showed the "Developer options are off" dialog and opened About phone; after "Build number" x7, Start opened
  Developer options and the service ran in the foreground (dataSync) without error. The notification said to turn
  on Wireless debugging, and to connect to Wi-Fi while Wi-Fi was off. The reply field stayed open for 13 s (no
  re-posting). A wrong code gave "That code was not accepted"; the right code on the same pairing screen then paired
  (public `SSLSockets` exporter) and both grants were given. With the grants revoked, Start connected and granted
  without a code.

Not verified: real phones (vendor Settings differ in names and in where "Build number" is), split screen with the
in-app field (adb could not put the emulator in split screen), and Android 12-14.

Known limits:
- The ports come only from mDNS. If a phone's mDNS never shows adbd's connect port to apps, the run waits and stops
  after 10 minutes (a typed port is accepted for pairing only). The service name filter keeps other phones out.
- Developer options' "Wireless debugging" row cannot be opened directly: Waaiya opens Developer options, and the
  steps say to scroll down to it.
- Android 11 needs the hidden Conscrypt exporter (reflection); a vendor that changed Conscrypt would break pairing
  there (the error is shown as the detail of "Pairing did not work").

## Quick Settings tiles

- **Waaiya** (`FilterTileService`): starts and stops filtering from the panel. Starting goes through the invisible
  `TileStartActivity` (Android hands out the screen-capture token only to an activity); after the setup Android
  answers without asking, so nothing shows. Without the DUMP grant or the microphone permission the tile opens the
  app instead, which explains.
- **Notification text** (`ScreenShareTileService`, Android 15+ only: `values-v35/bools.xml`): Android 15 hides the
  text of notifications during a whole-screen capture, and filtering is one. When this tile is on, `FilterService`
  sets the global setting `disable_screen_share_protections_for_apps_and_notifications` (Developer options
  "Disable screen share protections") to 1 just before the capture starts and puts it back when filtering ends
  (`ScreenShareProtection`; a crash is repaired at the next app start). SystemUI reads the setting only when a
  capture starts (its `SensitiveNotificationProtectionLog` buffer logs `protection enabled:false` then), so a change
  made while filtering applies at the next start and the tile says so. Phones set up before 0.2.11 lack the grant:
  the tile asks Shizuku when it runs, otherwise the setup card shows again (`setup.notificationTextNeedsSetup`).
- On Xiaomi (MIUI/HyperOS) every grant above needs "USB debugging (Security settings)" in Developer options, for
  all three routes.

## Phones that block the setup, slow Shizuku, diagnostics

- `SetupHelp` recognises Xiaomi/Redmi/POCO (MIUI/HyperOS: "USB debugging (Security settings)" on, Xiaomi account,
  notification style "Android" for the reply field) and OPPO/OnePlus/realme (ColorOS: "Permission monitoring" off),
  as in Shizuku's FAQ. The setup card shows that phone's note first, and a grant refused by the system
  (`SecurityException`, `GRANT_RUNTIME_PERMISSIONS`, ...) is explained with it instead of the raw log.
- Shizuku's helper process can take long to start (seen on a Xiaomi). The screen says "still working" after 20 s and
  gives up only after 2 min; an answer after that is still applied (`ShizukuSetup.addListener`).
- Nothing needs a restart once the setup is done: the screen re-checks every 2 s while it is incomplete, and a
  running filter starts silencing the originals as soon as DUMP is granted (`SessionMuter` waits for it).
- The diagnostics report has the last setup attempt (route, time, duration, command output: `SetupLog`) and the
  MIUI/HyperOS/ColorOS/One UI version.

## Illustrated guide

"Steps with pictures" in the setup card opens `SetupGuideActivity`: the Wireless-debugging route in 9 steps, each
with a screenshot, like Shizuku's guide (which it links for the Shizuku route). The pictures were taken on the
API 35 emulator (`res/drawable-nodpi` English, `res/drawable-ar-nodpi` Arabic, 540 px WebP, about 190 KB in all).
To retake them: set the per-app locale of Settings and SystemUI (`cmd locale set-app-locales com.android.settings
--locales ar`), go through the setup, crop and outline with Pillow. Both screens open it (Flutter: `openSetupGuide`).

## Waaiya's own cover helper (touches through the blur covers, no Shizuku)

On Android 12+ a cover drawn by an app takes the touches under it (Android keeps app overlays opaque only that
way). A cover drawn by a shell-uid process is a trusted SurfaceFlinger layer, skipped by screenshots, that touches
pass through. Shizuku was the only such process; `CoverHelper.kt` is Waaiya's own:

- **Start.** With a blur option on, the on-phone setup (or the "Start Waaiya's helper" button on the Screen page,
  the same run) also sends `CoverHelper.startCommand` over the Wireless debugging connection: it stops an older
  helper, then `CLASSPATH=<apk> setsid app_process /system/bin --nice-name=waaiya_covers
  org.islamicmute.app.CoverHelper <uid> <version>`, as Shizuku starts its server.
- **Hand-over.** The helper hosts `CoverService` (the same one Shizuku runs) and gives its binder to the app through
  `CoverHelperProvider`, a content-provider call (`IActivityManager.getContentProviderExternal` +
  `IContentProvider.call`, API 31+). The provider is exported but needs `INTERACT_ACROSS_USERS_FULL` (shell and root
  only) and checks the caller is uid 2000 or 0; the service serves only the app's uid. The helper looks for the
  app's process every 2 s and hands the binder again to each new one (never starting the app itself).
- **Lifetime.** Like Shizuku: it outlives the adb session and Wireless debugging being turned off; it ends when the
  phone restarts, when USB debugging or Developer options are turned off, or when the app is updated (its APK path
  is gone; the version is also checked). The Screen page then shows the button again: one tap (Wi-Fi and Wireless
  debugging on, already paired) starts a new one.
- **Choice of host** (`BlurOverlay.attach`): the helper when it runs, else Shizuku, else app overlay windows.
  `blur.shizukuLayer` and the diagnostics line ("Covers drawn by: shell layer (Waaiya helper)") say which.
- **Start race.** adbd ends the session as soon as the shell exits, and a background child that has not reached
  `setsid` yet goes with it (seen once in two runs). The start line therefore waits until `pidof waaiya_covers`
  sees the helper (up to 5 s) and prints `helper=started` or `helper=missing` into the setup log.
- **Late helper, dead helper** (`BlurOverlay.heartbeat`): a helper that dies mid-blur is replaced by app-overlay
  windows within a second; a helper that appears while windows draw (it hands its binder 2 to 4 s after the app
  starts, or was restarted) takes over after the 30 s retry pause, connected first and the windows removed only
  after it drew, so nothing is uncovered in between.
- **Verified** on the API 35 emulator (2026-11-16): the whole on-phone setup from the Flutter Setup page (pairing
  code typed in the notification) granted the permissions and started the helper over the app's own connection;
  the helper kept running as shell (parent init) after Wireless debugging was turned off; "Start Waaiya's helper"
  with the phone already paired worked 4 times in 4 (about 8 s each); an app update ended the old helper;
  `emu_check.py --blur --cover-helper` (shell layer, no cover windows, a tap on a cover reaches the app). Not
  verified on a real phone or on Android 12 to 14 yet. Google has discussed restricting on-device (loopback) adb,
  which would affect this route and Shizuku alike.
