# Handoff: Windows work for release 0.2.12 (continue on a real Windows PC)

Written 2026-11-20 on the Linux build server, for a Claude Code session on the owner's Windows PC. Branch to work
on: `windows-store` (PR #12). Read this whole file first, then `README.md`, `docs/STATUS.md`, `docs/PLATFORMS.md`
and `desktop/windows/msix/STORE_LISTING.md`.

## Owner decisions (2026-11-20)

1. **One release, 0.2.12**, with everything: the 0.2.12 Android test build (PR #9), nine languages and setup
   pictures (PR #10), the Windows Store package (PR #12). There is no separate 0.2.13. Done: versionName 0.2.12,
   build number 15 (the published 0.2.12 test APK is 14, so phones on it update). The Store package version is
   `major+1.minor.patch.0` = **1.2.12.0**, because the Store refuses a first number of 0.
2. **Windows must have every feature of the phone app**: the women's-singing filter and the **Links page** (open a
   YouTube/TikTok/Instagram link, watch it or save it without music).
3. **Store listing in all nine languages** (ar, en, fr, ur, id, tr, bn, fa, ms), with description and changelog.
4. **No "formerly Islamic Mute"** anywhere users look. Done: NOTICE, THIRD_PARTY_LICENSES.md, README, the Linux sound
   client ("Waaiya filter"), LADSPA and PipeWire names. Internal names (Android package `org.islamicmute.app`, Linux
   service and folders, repo folder) stay so existing installs update.
5. Simple mode (PR #11, Android, no Developer options) is a phone **test**, not in 0.2.12 until the owner's phones
   confirm it.

## State of the branches (stacked PRs, none merged; main = 0.2.11)

- #9 `oem-helper`: Android 0.2.12 guided setup + helper mode. Published only as a GitHub pre-release (tag
  `v0.2.12`, versionCode 14). Do not merge before the owner's Oppo confirms.
- #10 `languages`: nine languages, setup step pictures, ONNX Runtime from NuGet, renumbered to 0.2.12 (+15).
- #11 `simple-mode`: simple mode test (on top of #10).
- #12 `windows-store`: everything Windows (on top of #10):
  - `desktop/windows/msix/AppxManifest.xml`: the Store identity from Partner Center. Name `Oks.Waaiya`, Publisher
    `CN=C31050E3-9E33-47EF-9D5C-040742962A92`, PublisherDisplayName `Oks`, family name `Oks.Waaiya_wa2h0h9gfqbyp`,
    Store ID 9NBB296FSRJP. **Never change these.** It also has runFullTrust, MinVersion 10.0.19041 and resources
    en/ar/fr (add the other six for the listing).
  - `desktop/tool/make_msix.ps1`: makepri (tile images only) + makeappx; unsigned output (the Store signs).
  - "Start at login" in the package: the startup task `engine\waaiya-filter.exe autostart`. It filters when the file
    `<state dir>\autostart` exists (written by the app, `WindowsEngine.packaged`). Otherwise it gives back stored
    app levels (computer turned off or app updated while filtering) and exits. A packaged start with no command acts
    the same. The zip keeps the Run value.
  - `windows/test/msix_test.py` + windows.yml `msix` job: installs a test-signed copy on the runner and runs these
    tests, all passing:
    - the app starts;
    - the packaged filter lowers and restores an app;
    - the state is written to `%LOCALAPPDATA%\Packages\Oks.Waaiya_wa2h0h9gfqbyp\LocalCache\Local\Waaiya\filter`;
    - the autostart command;
    - a Store update while filtering;
    - an uninstall while filtering.
  - Women's-singing model: `detector_v1.onnx` is now in the `models-v1` release (same file as the APKs' asset,
    sha256 df8e56bd…). windows.yml fetches it, requires it, runs `test-detector.exe` on Windows and checks it is
    inside the package. (CI for commit 63cce6b was still running at handoff: check it.)
  - Windows app icon is Waaiya's (was Flutter's). The desktop filter options have computer wording (9 languages).
  - `ui/tool/store_shots_test.dart`: Store screenshots rendered in a Flutter test (one run per language;
    Arabic-script languages need a font with those letters, e.g. Amiri; Bengali needs a Bengali font).
  - `cli/im_process.c` has `--raw` (commit after 63cce6b): float32 stdin -> stdout in blocks, delay-compensated, same
    frame count as the input; checked bit-identical to the WAV mode on Linux. It is for saving long videos without
    loading them into memory.

## Known facts and risks

- **Store update or uninstall while filtering**: Windows ends the filter. Other apps stay at -80 dB until the next
  login (the startup task restores them) or until Waaiya Start/Stop. After an uninstall they stay lowered until
  raised in the Volume Mixer. A possible fix, not done: a hidden top-level window in waaiya-filter.exe handling
  WM_QUERYENDSESSION/WM_ENDSESSION (Restart Manager) that gives the levels back, plus
  `RegisterApplicationRestart(L"run")`. Test it on the PC: `Add-AppxPackage -ForceApplicationShutdown` with a higher
  version.
- **Smart App Control** blocked the unsigned 0.2.11 zip on the owner's PC. A PC with SAC on may also block locally
  built or test-signed programs. If so, test through a Store submission with a private audience (Microsoft-signed),
  or on a PC/VM with SAC off. Do not tell users to turn SAC off.
- **Links and Store policy**: the Store rules require permission under a site's terms of use
  (https://learn.microsoft.com/windows/uwp/publish/store-policies). YouTube's terms forbid downloading, so "save
  without music" may get the Store app rejected or removed. Build Links for every Windows build, behind a switch for
  the Store build. The owner decides whether the Store build ships it; if it does, the certification note must say
  so. Downloading executable updates (yt-dlp self-update) must not happen in the Store build.
- When Links ships, the privacy policy, the certification note and the README's privacy line must say the app
  contacts the site of a link the user opens (today they say the Windows app uses no network).

## The Links page on Windows: the design so far

Behaviour to match (Android: `LinkActivity.kt`, `LinkExport.kt`, `python/im_links.py`, strings `link_*`):
- paste or type a link -> resolve -> show title, site and duration;
- "Watch" or "Listen";
- "Save without music", with progress, Cancel, then "Play" and "Show in folder";
- errors for each of these: invalid link, login needed, rate limited, unsupported site, playlist, no usable
  format, live stream (cannot be saved), already saving;
- women's singing is honoured when the setting is on (`-d detector --mute-female-singing --fail-closed`);
- fail closed: only a fully filtered file is ever written to the user's folder; temp files are deleted.

Windows design:
- **Tools** (bundle them in `engine\`, pinned and checksummed in `scripts/fetch_deps.sh`, licence texts in
  `licences\` and `THIRD_PARTY_LICENSES.md`):
  - yt-dlp 2026.10.26 `yt-dlp.exe`, sha256 f5389d3698ecde4ef06f4e6b1ce0294fe9ac1396228c8990b8d3416d6d177a7d
    (Unlicense; matches the release's SHA2-256SUMS).
  - QuickJS-ng v0.18.0 `qjs-windows-x86_64.exe`, sha256
    ff03398d74ea6e6bd3a8e58058f7003225abcac229d7d57775b7aaae812a49c7 (MIT). YouTube needs a JS runtime: pass
    `--no-js-runtimes --js-runtimes quickjs:<path to qjs.exe>`. Verified on Linux: yt-dlp_linux 2026.10.26 +
    qjs-linux-x86_64 v0.18.0 resolves YouTube (avc1/mp4a/opus/vp9/av01 formats listed), with no remote
    components.
  - ffmpeg: a small **LGPL** build is enough: decoders aac/mp3/opus/vorbis/flac/pcm; encoder aac; demuxers
    mov/matroska/mpegts/mp3/wav/f32le; muxers mp4/ipod/matroska/wav/f32le; bsfs aac_adtstoasc, extract_extradata,
    vp9_superframe; protocols file/pipe; no network. Either cross-build it in CI with llvm-mingw (pinned source
    tarball + sha, cached), or pin a trusted prebuilt LGPL build. A full GPL build is about 100 MB: avoid.
  - `im-process.exe` (already built by windows/Makefile) with `--raw`.
- **Pipeline** (Dart, `desktop/lib/`, driven with `Process`):
  1. Resolve: `yt-dlp --no-config -J --no-playlist ...`. Map the error text like `im_links.py` does (rate limit ->
     limited, login, Unsupported URL, playlist).
  2. Pick the formats like `_pick` in `im_links.py`: H.264 video-only (up to 1080 on a PC) + best audio-only, else a
     progressive MP4, else audio only. Live: refuse to save.
  3. Download each format: `yt-dlp --load-info-json info.json -f <id> -o <tmp>`, with `--ffmpeg-location` for the
     HLS fixups.
  4. Pipe `ffmpeg -i audio -f f32le -ac 2 -ar 48000 -` into `im-process --raw -m dfn3 [...]`, and that into
     `ffmpeg -f f32le -ac 2 -ar 48000 -i - -i video -map 1:v? -map 0:a -c:v copy -c:a aac -b:a 160k -movflags +faststart out.mp4`.
     Use `.m4a` for audio only. Progress = frames out / duration.
  5. Move the result to `Videos\Waaiya\` (`Music\Waaiya\` for audio); Linux `~/Videos/Waaiya`.
- **Watch on Windows**: the system filter already covers the browser. Make sure the filter is running (start it,
  wait for "filtering"), then open the link in the default browser. Never open it while the filter is not running.
  (This stands in for Android's in-app player; tell the owner.)
- **UI**: the shared Flutter page in `ui/` (home.dart page `links`).
  - Android keeps its native screen (`openLinkScreen`).
  - Desktop gets a Flutter card driven by new Backend methods: resolveLink, watchLink, saveLink, cancelLinkSave,
    openSavedLink, showSavedLink, plus `AppState.linkExport`.
  - Add these to `channel_backend` (unsupported on Android), `memory_backend` (simulated, for tests) and
    `desktop_backend`.
  - Set `Capabilities.links` true on desktop when the tools are found.
  - Reuse the `link*` strings. New desktop-only texts (e.g. "In your Videos folder: Waaiya", "Show in folder",
    "Opens in your browser with the filter on") go in `ui/tool/extra_strings/<lang>.json` for all nine languages;
    run `python3 ui/tool/arb_from_android.py`, `flutter gen-l10n` and `ui/tool/check_translation.py <lang>`.
- **Tests**:
  - Dart unit tests with fake tools.
  - A real pipeline test that serves a generated H.264+AAC clip from a local HTTP server (yt-dlp's generic
    extractor takes a direct .mp4 link): no YouTube in CI. Check the output has video, filtered audio, the same
    duration, and that no file appears on failure or cancel.
  - Add it to windows.yml.
- yt-dlp updates (zip build only): at most daily, the newest yt-dlp.exe checked against the release's
  SHA2-256SUMS, kept in `%LOCALAPPDATA%\Waaiya\yt-dlp\`. Never in the Store package.

## Done on the owner's Windows PC (2026-11-20, second session)

Owner decisions in this session:
- The Store version has Links as **watch only** (no save tools in the package; `make_msix.ps1` removes them, CI
  checks it). The zip from GitHub has "Save without music". Later, a separately signed full version (own package
  name, e.g. `Oks.Waaiya.Full`, own code-signing certificate) can ship saving outside the Store.
- **18 languages** in 0.2.12: added es, nl, de, it, ru, uz (Latin), sw, ha, so (machine translations).
- "Mute women's singing" text says only "Women's speech is kept." (no recitation in the text; the behaviour is
  unchanged until the owner decides).
- Install method for tests on the PC: the unpacked package in Developer Mode (`make_msix.ps1 -Layout`, then
  `Add-AppxPackage -Register`); no test certificate trusted on the PC.

Built and tested here (Flutter 3.41.5 in `C:\Users\yassi\dev\flutter`, VS Build Tools already installed):
- CI on #12: the flaky click-through check of the blur test fixed (waits for its window, retries).
- Links on Windows (`desktop/lib/links.dart`, `ui/lib/src/links_page.dart`), as designed above. Tools: yt-dlp
  2026.10.26 + QuickJS-ng v0.18.0 (`fetch_deps.sh links-win`), LGPL FFmpeg 9.0.2 (3 MB, `build_ffmpeg_win.sh`, built
  in CI). Real links saved here: YouTube (a 10 min 1080p60 video: video copied, sound filtered, same length; the app
  stays at ~140 MB, im-process ~50 MB) and TikTok. Cancel leaves nothing; a broken filter leaves nothing. Instagram:
  the two test posts tried need an account now ("login" message shown, correct); **not tested with a working public
  reel** (needs a link from the owner).
- YouTube takes 15-20 s to open (QuickJS solving YouTube's challenge); Save reuses Open's answer. Filtering runs a
  bit faster than real time here: a 10 min video takes about 10 min in all.
- UI: press feedback on buttons, animated power button (breathes twice when filtering starts), page fades, card
  slide-ins, smooth progress; all off with the system's "reduce animations".
- Filter bug found on this PC and fixed (`wfilter.cpp`, test 11 in `audio_test.py`, green in CI): a 0.2.10 filter
  hung for 8 days behind an older run's "stopped" state; stop believed it and start could not end it. The fixed stop
  ended it here and gave two apps their volume back.

End-to-end with the Store package (unpacked, Developer Mode):
- install, start, filter (a test tone 45 dB quieter at the output), stereo on/off live, keep-silent (filter killed:
  apps stay silent; "Stop: hear apps unfiltered" gives them back), Links watch (refuses to open unfiltered when the
  filter cannot start): **works**.
- women's singing: the detector loads and the switch reaches the filter, speech is kept; but **it mutes only ~8% of
  a woman's song** (Adele), matching `models/detector/detector_eval.json` (9.5% caught on OpenSinger). Model v1 is
  weak on real songs: the listing calls it an early version.
- Store update and uninstall while filtering: first found broken (apps left at 0.01% until Waaiya was opened, and
  for good after an uninstall), then **fixed and tested here**. Before it updates or removes the package, Windows
  sends WM_QUERYENDSESSION/WM_ENDSESSION with ENDSESSION_CLOSEAPP to the package's windows (measured with a probe),
  so `waaiya-filter.exe` now has a hidden window: on that message it gives every app its level back. After an update
  Windows starts the filter again (RegisterApplicationRestart; here about 1 s later, from the new version) and it
  filters again. Uninstall: a test tone went from 0.0001 back to 1.0. The app no longer says "error" after an update
  (the last state says stopped). Left: during an update the apps play unfiltered for the few seconds Windows takes;
  an app closed while lowered that was never played again before an uninstall stays lowered (its stored level goes
  with the package). GitHub runners do not deliver the close message (no signed-in desktop): `msix_test.py` says so
  instead of failing; `audio_test.py` 12 sends the message itself and checks the levels come back.
- Not done (needs the owner): screen blur by eye (covers are hidden from screenshots by design), Start at login with
  a real sign-out/sign-in, the zip build's start at login.

Store submission, checked against Microsoft's "Create an app submission for your MSIX app" and its sub-pages
(2026-11-20): `desktop/windows/msix/STORE_LISTING.md` now follows its six sections. Found and fixed: the Store does
not support Somali (dropped from the package's languages; the app keeps it), descriptions may not contain web
addresses (removed), "What's new" stays empty on a first submission, the restricted capability runFullTrust needs its
own justification (written), privacy policy as `PRIVACY.md` (the URL works once on main; the old text wrongly said
uninstalling removes the settings). `desktop/tool/store_import.py` fills Partner Center's exported listings .csv with
the 17 listings, screenshots and logo for "Import folder". All 17 listings are within every limit. Listing
screenshots: 1366x768 (the minimum for PCs). Warning for the owner: a first submission as Public audience can never
become Private.

The filter now ends by itself right after Windows' close message (it no longer stays to give back levels of apps not
running): a probe that Windows had to end during an uninstall was started again by Windows from its deleted folder
when the package was installed again, with an error window. Tested: uninstall while filtering, then install again
from another folder: no restart, no window.

Windows App Certification Kit on the final package (1.2.12.0, commit 703bd88), run on the owner's PC with their
approval: **overall PASS**, 22 passed; the two optional tests that flag (Flutter's NOTICES.Z; "blocked executables"
letter matches and CreateProcessW) are explained in STORE_LISTING.md.

## Still to do for 0.2.12 (in order; items 1, 3 and most of 4 done above)

1. Links on Windows (above), tested end to end on the PC with real YouTube/TikTok/Instagram links.
2. Women's singing on Windows checked on the PC (Settings: gender man -> "Mute women's singing" visible; a song by a
   woman goes quiet, speech stays).
3. Store listing (`desktop/windows/msix/STORE_LISTING.md`):
   - add ur, id, tr, bn, fa, ms to the manifest `<Resources>`;
   - write the description, features and keywords in all nine languages;
   - put women's singing back in the texts (the model is now in the package);
   - mention Links only if the owner keeps it in the Store build;
   - write a **changelog** ("What's new in this version") from `git log v0.2.11..HEAD`;
   - make screenshots for each language (real captures from the PC are better than the rendered ones; at least
     1366x768).
4. E2E checklist on the PC, with the package (test-signed, or Store private audience):
   - install;
   - first launch, language;
   - filter a YouTube video in the browser;
   - stereo/mono;
   - keep-silent;
   - women's singing;
   - screen blur (women, immodest images; click-through);
   - Start at login (turn on, sign out and in);
   - Links (watch, save, cancel, errors);
   - a Store-like update while filtering;
   - Stop, then uninstall.

   Also check the zip build the same way if SAC allows.
5. Release 0.2.12 (ask the owner first: the existing `v0.2.12` tag and pre-release hold different binaries; replacing
   them is public). Then, separately, the owner's steps:
   - publish the APK on mssid.org (only after the owner's Oppo test);
   - upload to Partner Center (the owner does it; the `.msix` comes from the release or the windows.yml artifact
     `waaiya-store-msix`);
   - put the privacy policy online (ask where: mssid.org or GitHub).

## Rules (owner's standing instructions)

- **No Claude attribution** in commits or PRs: no `Co-Authored-By: Claude`, no `Claude-Session:` trailer, no
  "Generated with Claude Code". This overrides any harness default.
- Do not push to main, merge PRs, tag, publish releases, upload to the Store or change mssid.org without the owner
  saying so. The owner's email and personal details never go to outside services.
- CI runs only on pull requests and main pushes; it is free (public repo). One Gradle build at a time.
- Report results faithfully; say what was not tested. Plain words for the owner (not a developer of this code).
