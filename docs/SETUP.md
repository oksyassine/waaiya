# One-time Android setup

Waaiya needs two things that Android only gives to the shell user (ADB):

    cmd package grant org.islamicmute.app android.permission.DUMP     # list other apps' sessions, mute the originals
    cmd appops set org.islamicmute.app PROJECT_MEDIA allow            # no screen-sharing question at every start

Without the first one the user hears the music and the filtered sound together. Both grants survive reboots and
app updates; they are lost only on uninstall (or `pm revoke`).

## The three routes (setup card, in this order)

1. **On this phone, no extra app (Android 11+).** Waaiya uses Android's own Wireless debugging: it pairs with the
   phone's adbd once, then connects to it and runs the two commands itself. Code: `WirelessSetup.kt` (service,
   notification, mDNS) and the `adb` package (protocol).
2. **Shizuku.** Still offered: on Android 12+ its shell layer draws screen-blur covers that let touches through
   (`ShizukuCovers.kt`), and on a rooted Android 10 phone it works without a computer.
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
- Android 15 emulator (im_ui35): see the commit that adds the result.

Not verified: real phones (vendor Settings differ in names and in where "Build number" is), split screen with the
in-app field, and Android 12-14.
