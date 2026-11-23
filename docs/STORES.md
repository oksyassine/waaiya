# App stores: the store build and what each store asks for

One Android build serves every store: Google Play (as an app bundle), and Samsung Galaxy Store, Xiaomi GetApps,
Huawei AppGallery and the others (as APKs). The website and GitHub keep the full APK. Decisions that are the
owner's are marked **Owner**, with the recommended answer.

## The store build

    scripts/fetch_deps.sh            # includes ort-android: ONNX Runtime 1.20.0's licence texts for the app
    cd android
    # Google Play (app bundle) and the other stores (universal APK + one per ABI), in one run
    ./gradlew bundleRelease assembleRelease -PimPlay -PimNoLinks -PimAbiSplit -PimBuildPython=<python3.11>

Outputs: `app/build/outputs/bundle/release/app-release.aab` (Play) and `app/build/outputs/apk/release/` (the
others). Store pictures and texts: `store/` (`store/make_graphics.py` for the icon and feature graphics;
`ui/tool/store_shots_test.dart --dart-define=FORM=phone` for the phone screenshots).

What the store build leaves out, compared with the website APK:

| Left out | Why | How |
|---|---|---|
| The in-app updater (daily check, "Update now") | Stores update apps themselves; Google Play forbids self-updates | `-PimPlay`: no `REQUEST_INSTALL_PACKAGES`, `BuildConfig.SELF_UPDATE` false, the Settings section hides itself |
| The SMS reply to calls during prayer | Google Play allows SMS and call-log permissions only to default SMS/phone apps | `-PimPlay`: no `SEND_SMS`, `READ_CALL_LOG`, `READ_PHONE_STATE`; the option hides itself |
| "Open a link" (yt-dlp, QuickJS, the link screens, the export service) | Downloading from YouTube breaks its terms; a bundled downloader is a rejection risk even when unreachable | `-PimNoLinks`: none of it is packaged (no yt-dlp, no `libqjs.so`, no `LinkActivity`/`LinkExportService`, no `mediaProcessing` service type) |

The store build makes no internet connection at all. Everything else is the same app: the filter, the women's-singing
option, the screen blur (preview), prayer times, the wait and PIN, the setup.

Requirements met by every build since this change: target Android 16 (API 36, Google Play's rule for new apps and
updates since 2026-08-31) and native libraries aligned for 16 KB memory pages (Google Play's rule for apps
targeting Android 15+): ONNX Runtime 1.20.0, and the NDK's flexible page sizes for our own libraries.

**Owner**: links stay out of store builds (recommended, and the documented default since the Play switch was made).

## One signing key everywhere

The website, GitHub, Galaxy Store and the other APK stores all ship APKs signed with Waaiya's release key, so a
user can move between them and keep updating. Google Play re-signs apps: at the first upload, Play Console asks
which app signing key to use.

**Owner**: choose "Use a key from Java keystore" (upload the existing release key, encrypted with Google's PEPK
tool, which Play Console provides). Recommended: yes. With a key Google generates instead, the Play app and the
website app cannot update each other: users would have to uninstall (and lose their settings) to switch. This
choice cannot be changed after the first upload. Claude can prepare the encrypted key file once the owner sends
the encryption public key that Play Console shows on that page.

## Google Play: the forms

- **App**: name "Waaiya", default language Arabic or English (owner's choice), free, app (not game).
- **Category**: Tools (or Music & Audio). Tags: audio, privacy.
- **Contact**: an email address (shown publicly), the website https://waaiya.mssid.org.
- **Privacy policy**: https://waaiya.mssid.org/en/privacy.html (it already says store builds have no updater).
- **Ads**: no ads.
- **App access**: all functions available without an account.
- **Content rating**: questionnaire, all "no" (no violence, no user-generated content shared with others, no
  gambling); expected rating: Everyone / PEGI 3.
- **Target audience**: 13 and over (choosing under-13 ages brings Play's Families policy; Waaiya is not made for
  children, parents install it on their own phones or their children's).
- **News app**: no. **Government app**: no. **Financial features**: none. **Health**: none.
- **Data safety**: no data collected, no data shared. Reason: audio, screen content, location (prayer times) and
  settings are processed only on the phone and never leave it; Google counts on-device processing as not collected.
  Security section: "data is not transferred off the device" (encryption in transit: not applicable); deletion:
  not applicable (no account).
- **Foreground service declarations** (Play Console, App content):
  - `mediaProjection` (FilterService): captures the sound other apps play so Waaiya can remove the music and
    play the filtered sound, while the user has filtering on; the screen blur reads the screen through the same
    capture. Needs a short video of it in use (record: start filtering, play a video with music, show the
    notification, stop).
  - `dataSync` (WirelessSetupService): the one-time setup, which pairs with the phone's own Wireless debugging
    and keeps the connection open while the user follows the steps. A reviewer may question the type; the
    alternative is `specialUse` with this explanation.
- **Sensitive permissions**: no SMS, call log, accessibility or install-packages permission in the store build.
  `SCHEDULE_EXACT_ALARM` (prayer start and end) and `ACCESS_COARSE_LOCATION` (optional "Use my location", in the
  foreground) need no form. `DUMP` and `WRITE_SECURE_SETTINGS` are granted only by the user's own setup over
  Wireless debugging; Play accepts them in the manifest, but a reviewer may ask why.
- **Testing**: a new personal developer account must run a closed test with at least 12 testers for 14 days
  before production. Organization accounts are reported to be exempt.
- **Trader status** (EU): non-trader while Waaiya is free, without ads or purchases, under a personal account.

Store listing texts for the store build (no links, no update check): `store/listing/<lang>/` (en-US, ar, fr-FR).
The `fastlane/metadata/android/` texts describe the website APK (IzzyOnDroid) and keep links and the update check.

Graphics Play asks for, all in `store/`: the icon (`graphics/icon-512.png`), the feature graphic
(`graphics/feature-graphic-{en,ar}.png`, 1024x500) and phone screenshots (`screenshots/<lang>-phone-*.png`,
1080x2400, rendered from the app's own screens with the store build's options: no Links tab).

## The other stores

All of them take the store APKs (`-PimAbiSplit` gives a universal APK and one per ABI). None needs Google services,
and Waaiya uses none.

| Store | Account | Notes |
|---|---|---|
| Samsung Galaxy Store | Samsung seller portal (seller.samsungapps.com), free, individuals accepted | Preinstalled on Samsung phones. Uploads the APK as signed (no re-signing). Review takes a few days |
| Xiaomi GetApps | Xiaomi's developer platform; check whether individual accounts are accepted for the global store | Preinstalled on Xiaomi/Redmi/POCO phones. Also a way around the "package invalid" install failures on HyperOS |
| Huawei AppGallery | AppGallery Connect (developer.huawei.com), individuals with an ID check | For Huawei phones without Google services. Do not turn on its app-signing service: keep the release key |
| APKPure, Uptodown | Free developer accounts | Large audiences where Play is missing or restricted |
| IzzyOnDroid, F-Droid | See docs/DISTRIBUTION.md | Take the website APK, not the store build |
| Amazon Appstore | - | Closed on ordinary Android phones since 2025 (Fire tablets only): skip |

Version codes must only go up in every store; the store build uses the same `versionCode` as the website APK of
the same release.
