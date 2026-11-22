# The move to org.waaiya.app (0.2.15)

Until 0.2.14 the Android app's package name was `org.islamicmute.app`, from the project's first name. From 0.2.15 it
is `org.waaiya.app` (owner's decision, 2026-11-22), before Google's developer verification, IzzyOnDroid and F-Droid
tie a name to the app for good.

Android treats a new package name as a different app: no update from one to the other, no shared data, and the
permissions of the one-time setup belong to the old one. So 0.2.15 is released twice, from the same source:

| Build | Package | Who gets it | What it does |
|---|---|---|---|
| `assembleRelease -PimAbiSplit` | `org.waaiya.app` | everyone from now on: the website, GitHub, `waaiya-update.json` | Waaiya. On its first start it takes the old app's settings, and while the old app is installed it shows a card that removes it |
| `assembleRelease -PimAbiSplit -PimMoveBuild` | `org.islamicmute.app` | phones with 0.2.14, through their in-app update (`update.json`); GitHub assets `waaiya-v0.2.15-move-*.apk` | The old app's last version: Waaiya as before, plus a card and a notification that install the new app and then remove this one |

## The steps a user sees

1. **0.2.14** (old name) offers "Waaiya 0.2.15 is available" as an ordinary in-app update (`update.json`, with
   patches from 0.2.11 to 0.2.14). Phones with 0.2.13 or older have no updater: they install the new app from the
   website, and the new app offers to remove the old one (their settings do not come over).
2. **The old app's last version** posts "Waaiya has moved to a new app" once (`AppMove.notifyOnce`, at the first
   start after the update and from the daily check), and shows the card "Waaiya has moved" at the top of the Filter and
   Settings pages. "Install the new Waaiya" uses the in-app update's download and checks, aimed at the new app
   (`AppUpdate.TARGET`): it reads `waaiya-update.json`, downloads the APK of the same variant, checks its SHA-256, that
   its package is `org.waaiya.app` and that it is signed with the release certificate, and hands it to Android's
   installer, which asks the user. Installing the new app does not stop the old app's filter (the PIN and waiting
   period still apply to the button, as to any update).
3. **The new app's first start** (`AppMove.onStart`, in `WaaiyaApp.onCreate`, before anything reads the settings):
   if the old app is installed and the new app has no settings yet, it calls the old app's `MoveProvider`
   (`content://org.islamicmute.app.move`, method `export`) and writes what it returns into its own preference files:
   `settings`, `protect` (PIN, waiting period) and `worship`. Not moved: the setup and pairing state, the update
   state and simple mode's media mute, which belong to an installation. It tries once.
4. **The one-time setup again** in the new app (Android's grants belong to a package): the Setup page shows it as on a
   new phone; waaiya.mssid.org/usb does it from a computer.
5. **Removing the old app**: both cards have the button ("Remove this old Waaiya" in the old app, "Remove the old
   Waaiya" in the new one; Android asks). In the old app it goes through the same gate as Stop while filtering.

## Who may read the settings

`MoveProvider` is declared only in the move build (`src/move/AndroidManifest.xml`), exported with the permission
`org.waaiya.permission.MOVE`, protection level `signature`, which is also declared only there: Android grants it only
to an app signed with the same certificate, and the provider checks again that the caller is `org.waaiya.app` with
matching signatures. The new app only requests the permission. If both declared it, Android would refuse to install
an `org.waaiya.app` signed with another key (a rebuild from source) while the old app is installed
(`INSTALL_FAILED_DUPLICATE_PERMISSION`, seen on the emulator); now such a build installs and simply gets no settings
(SecurityException, logged).

## What else changed with the name

- Kotlin package, AIDL, JNI symbols (`Java_org_waaiya_app_*`), R8 rules, the helper's class
  (`org.waaiya.app.CoverHelper`, started by name with `app_process`), intent actions, `emu_check.py`, the docs.
- The move build keeps the launcher entry's old full name (`org.islamicmute.app.MainActivity`, an alias), so home-screen
  icons keep working after the update; it has no long-press shortcuts (they name the new package). Its Quick
  Settings tiles must be added again (the services' class names changed).
- The release files: `waaiya-update.json` (new app, read by 0.2.15 and later, and by the move build to find the new
  app) and `update.json` (old app, read by 0.2.14; stays at 0.2.15's move build). Both are written by
  `site/make_update.py` and uploaded by `site/upload_downloads.sh`, the new app's first; `htaccess` keeps both out of
  caches. `.github/workflows/release.yml` builds the move APKs for the tag v0.2.15 only.
- waaiya.mssid.org/usb grants to `org.waaiya.app` when installed, else to `org.islamicmute.app`; the helper's class
  follows the version (18 and later: `org.waaiya.app.CoverHelper`).
- Unchanged: the signing key, the Linux and Windows apps, the Microsoft Store listing, internal Linux names
  (`islamic_mute` sink, LADSPA labels), the log tag.

## How it was checked (2026-11-22)

On the Android 15 emulator (`im_ui35`), debug builds of both, a test release file in `preview/movetest/` (removed
afterwards): the move build posted "Waaiya has moved to a new app" and showed the card; "Install the new Waaiya"
downloaded the new app (226 MB debug APK), Android's installer installed it, the card turned to "Open the new Waaiya";
the new app took the six settings written into the old one and showed "The old Waaiya is still installed" with "Your
settings were brought over from it"; "Remove the old Waaiya" opened Android's uninstall question and the card went
away after it. Again after the permission was moved to the move build only, and the new app (debug key) installed
next to a release-signed old app, refusing its settings. A release-signed 0.2.14 updated in place to the
release-signed move build: same launcher component, "Waaiya has moved" posted at once (MY_PACKAGE_REPLACED).
`ui/test/app_move_test.dart`: the card's states, its calls and every language on a small phone. waaiya.mssid.org/usb:
`page_test.mjs` with the new app, and with 0.2.14 on a Xiaomi (helper class from the old package).

Not checked: the real 0.2.14 → move build in-app update with release files on the live site (it is the same path as
every in-app update since 0.2.14), and real phones.
