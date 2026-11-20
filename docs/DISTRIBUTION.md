# Distribution (roadmap item 11)

Where Waaiya can be installed from, what each channel needs, and what is ready in the repository. Decisions that
are the owner's are marked **Owner**, with the recommended answer.

| Channel | State | What it needs |
|---|---|---|
| mssid.org and GitHub releases (signed APK) | Live | Nothing new; see below for Google's developer verification |
| Microsoft Store | Package ready (PR #12) | Submission by the owner (desktop/windows/msix/STORE_LISTING.md) |
| Google Play | Build option ready (`-PimPlay`, `-PimNoLinks`) | A Play developer account, the owner's decisions below, the store listing |
| IzzyOnDroid (F-Droid client repository) | Metadata ready (`fastlane/metadata/android/`, en, ar, fr) | A request to the repository; its APK size limit (below) |
| F-Droid main repository | Blocked for now | Builds from source only: see below |
| Obtainium | Works today | Users add `https://github.com/oksyassine/waaiya`; it follows GitHub releases |

## Google's developer verification

From 2026-09-30, phones certified by Google in Brazil, Indonesia, Singapore and Thailand install only apps whose
developer is verified, also outside Play; worldwide in 2027. Indonesian is one of Waaiya's nine languages.

- What it takes: an Android Developer Console account (an individual one is enough), an identity check with a
  government ID, and registering the package name `org.islamicmute.app` with the existing release signing key
  (certificate SHA-256 `296a57bf…`). The APK and the signing key do not change.
- **Owner**: register as an individual developer now. Recommended: yes, before the next release, because without it
  new users in Indonesia cannot install the APK at all on a certified phone.

## Google Play build

`./gradlew assembleRelease -PimPlay` (or `bundleRelease` for an app bundle):

- `-PimPlay` turns off the yt-dlp self-update (`BuildConfig.SELF_UPDATE`): Play forbids apps that download code to
  run outside Play. Links then use the yt-dlp version bundled in that release, which breaks when sites change, so
  Play users would need app updates more often.
- `-PimNoLinks` removes "Open a link" (`BuildConfig.LINKS`: the share target is disabled and the Links page is
  hidden).
- **Owner**: should the Play build ship links? Recommended: no (`-PimPlay -PimNoLinks`). Downloading from YouTube
  breaks its terms, and Play removes apps for it; the full APK keeps links.
- Play will also ask for: a video showing the screen-capture foreground service (MediaProjection) in use; a
  declaration for `RECORD_AUDIO`; the privacy policy URL (docs/PRIVACY.md); the data safety form (no data collected,
  no data shared). `DUMP` and `WRITE_SECURE_SETTINGS` are development permissions granted by the user with the
  setup; Play accepts them in the manifest, but reviewers may ask why.
- The accessibility build (`-PimBlurA11y`) must not go to Play.

## IzzyOnDroid and F-Droid

- IzzyOnDroid takes the signed APK from GitHub releases and the texts and pictures from `fastlane/metadata/android/`.
  Its usual size limit is 30 MB per APK; Waaiya's universal APK is about 100 MB (models and the link reader).
  Per-ABI APKs (`-PimAbiSplit`) are smaller but still above it. **Owner**: ask IzzyOnDroid for an exception, or
  wait. Recommended: ask, with the per-ABI APKs.
- The F-Droid main repository builds every app from source, including its native libraries. Waaiya uses Microsoft's
  prebuilt ONNX Runtime and prebuilt model weights, and downloads yt-dlp updates; each of these needs work or an
  anti-feature label there. Not planned before the other channels.

## Texts

The fastlane texts are in English, Arabic and French. The other six app languages fall back to English there until
translated texts are added (`fastlane/metadata/android/<locale>/`). Pictures: `ui/tool/store_shots_test.dart`
renders screenshots per language (desktop size today; a phone size can be added).
