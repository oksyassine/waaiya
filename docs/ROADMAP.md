# Roadmap (2026-11-12)

What comes next for Waaiya, in order, and why. Each item names the evidence behind it: the research notes in
`research_notes/Muslim phone needs/findings.md` (needs are numbered as in its table, sources as `[S1]`, `[G3]`…),
the code audit, or a measurement in `eval/results/`.

## Rules that do not change

- The app applies the user's choice. It never decides a religious ruling: where scholars differ, it is a setting.
- Everything runs on the device. Nothing is sent anywhere, no account, no analytics.
- Fail-closed: when the app is unsure or broken, the user gets silence or a cover, never unfiltered content.
- Arabic first, with an English switch. No root.
- Current features come before new ones.

## Done in 0.2.9: the live filter says what is wrong and adapts to the phone

Found by running the app on emulators in the state of a phone that never installed Shizuku
(`android/tools/emu_check.py`), and by reading the audio path.

| Problem | Cause | Fix |
|---|---|---|
| Sound cuts on some phones, with no message | The model must finish each 10 ms hop in under 10 ms. Stereo runs it twice per hop (about 7 ms on a desktop core). A slower phone drops sound at the capture and at the output; nothing measured or reported it | The filter times every hop and counts dropouts (`LoadMonitor`). Too slow in stereo: it mixes to mono, half the work, and remembers that for a week. Too slow even in mono: the screen and the notification say so and point to "Open a link", which filters before playing. Android 12+: the audio thread asks the system for a fast core |
| "Instruments are removed from all apps" shown while the music was still heard | Without the one-time setup the original sound cannot be silenced; the state line did not depend on it | Start without setup opens a dialog first. While running, the state line and the notification say the original is not silenced |
| On Android 10 and 11 the original was never silenced, even with the setup done | The session list was read from a system dump that has session numbers only from Android 12 | Sessions come from the audio policy dump, which has them on every version, with the real "refuses capture" flag (`AudioDump`, tested against dumps from Android 11 and 15 emulators) |
| The app stayed "on" with no sound when capture died | A failed read was retried forever | A dead capture stops the filter with its own message. A cancelled screen-sharing question explains why it is asked |
| Nobody could tell which of these a phone had | No numbers were kept | "Problem? Diagnostics report" at the bottom of the screen: setup state, speed per hop, dropouts, what is silenced, blur speed. Copy or share; the app sends nothing |
| Delay grew after a slow start or a stall and never came back | Late sound stays in the output buffer as extra delay | Delay that the phone's slowest recent hop does not need is given back during silence |
| Apps that refuse capture went silent without explanation | Not shown | The state line names the app: silenced, or playing unfiltered, by the user's setting |

Checks that run without a phone: 19 JVM tests (load monitor, session list parser), an engine test for the mono
switch, and `emu_check.py` on Android 11 and 15 emulators with the setup missing and done, with a native build
("fast phone") and the release build under ARM translation ("slow phone").

Not provable without a phone, so still open: how many real phones need mono, sound quality by ear, Bluetooth.
The diagnostics report is how those answers will come back.

## Next, in order

1. **Setup without a second app.** Today the setup needs Shizuku or a computer; it is longer than any
   competitor's, and a crash or confusion during first-run setup is a known reason people give up (finding 3.16).
   - a. Pair with Android's wireless debugging from inside Waaiya (Android 11+) and run the two grants directly.
     Shizuku stays optional, for the touch-through blur layer. Large: needs the ADB pairing protocol in the app.
   - b. A "use a computer" page that does the grant from Chrome over USB (WebUSB), no ADB install. Medium.
2. **A lighter live model, and measured battery and heat** (need 3: the most common complaint about every similar
   tool). Benchmark model variants on ARM through the diagnostics numbers; try the two channels on two threads;
   consider mono as the default with stereo as an option; publish per-phone figures.
3. **Blur quality where users judge it** (need 2, finding 3.1, 3.2): shorten the first-frame gap, small
   thumbnails, drawn and 3D figures (anime, games: need 10). Evaluate before changing models.
4. **Protection that survives a weak moment** (need 4, [C1] [C3]): a waiting period, chosen in advance, before
   switching off or weakening takes effect; a local PIN for parents (need 8). Local only: no partner reports,
   no uninstall blocking (they need a server or an accessibility service).
5. **Fix mistakes on the spot** (need 7): cover an area by hand, turn the filter or blur off for one app, and a
   local "wrong detection" note the user can export himself.
6. **Keep singing as an option** (need 1, lectures with a nasheed under them [S6]): finish `voice_v1`; a setting,
   since what counts as acceptable differs.
7. **Proof of the privacy claim** (need 5): a plain privacy page, a test that the filter and blur paths open no
   network connection, reproducible-build notes. Competitors' store labels contradict their claims
   (finding 2.6); this is cheap and sets Waaiya apart.
8. **Worship helpers that reuse what Waaiya already holds** (needs 9, 16): silent at prayer times and an optional
   "mute media at the adhan", computed on the phone from a city the user picks, each action announced in a
   notification ([W3]). Off by default. Well served by other apps, so small scope only.
9. **Plain tones helper** (need 15): one screen that sets a plain ringtone and notification tone. Ring and
   notification sound cannot be filtered, only replaced.
10. **More languages** (need 11): Urdu, Indonesian, Malay, Turkish, French, Persian. Each needs a native reviewer;
    "Arabic that needs fixing" is itself a complaint (finding 3.15).
11. **Distribution**: decide on Google's developer verification (live in Indonesia, Brazil, Singapore, Thailand
    since 2026-09-30, global in 2027 [D5]; it needs an identity check); a Play build without the link
    downloader's self-update; F-Droid.
12. **Other platforms**: Windows engine and blur; Linux blur on real Wayland sessions; Android TV (need 8,
    [G6]); iPhone in-app player and Safari extension (need 12).

## Not building

| Idea | Why not |
|---|---|
| Prayer times, adhan and qibla as an app of its own | Crowded and free elsewhere; location data is where users lost trust [T3] |
| Website filtering by DNS or VPN | Needs servers; done at scale by others [C5] |
| Hiding Reels and Shorts inside other apps | Needs an accessibility service tied to each app's layout; breaks with their updates |
| Partner reports, remote parental dashboards, uninstall blocking | Send data off the phone or need device-admin powers |
| Filtering links on a server | Against "nothing is sent"; it is what users wait on elsewhere [S13] |
| Blocking ads | Forbidden on Play [D4]. Removing instruments from an ad's sound is a different act |
| Any built-in ruling or "is this allowed" score | The app applies the user's choice |

## Decisions that belong to the owner

- Developer verification: register (identity check) or rely on the advanced install flow.
- Mono as the default for the live filter (half the battery, voice is almost always centred) or stereo with
  automatic fallback as now.
- Whether the waiting period (item 4) may delay switching the filter off, or only weakening the blur.
