# End-to-end checks of the in-app update (AppUpdate.kt)

On an emulator (`im_ui35` port 5580, `im_api30` port 5582), with two debug builds signed alike:

    ./gradlew assembleDebug -PimX86                          # A: the installed version -> $WORK/A.apk
    ./gradlew assembleDebug -PimX86 -PimTestVersionCode=17   # B: the "newer" one       -> $WORK/B.apk
    WORK=... android/tools/update_e2e/mkrel.sh               # patch + update.json -> waaiya.mssid.org/preview/updtest/
    adb install $WORK/A.apk
    SERIAL=emulator-5580 python3 android/tools/update_e2e/e2e.py [--bad-patch]   # notification, card, permission,
                                                                                 # patch (or fallback), installer
    python3 android/tools/update_e2e/prot.py                 # with a waiting period, Update now is held back

Debug builds read the release file's address from `files/update-url.txt` (the scripts write it with `run-as`).
Remove the test release afterwards: `ssh o2 rm -rf waaiya.mssid.org/preview/updtest`.
Last results (2026-11-21): e2e 10/10 on API 35 and API 30 (on API 30 Android restarts the app when installs are
allowed, and the update goes on by itself), --bad-patch falls back to the full APK, prot 7/7.
