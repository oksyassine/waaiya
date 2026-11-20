# Microsoft Store: what to fill in (Partner Center, app "Waaiya", Store ID 9NBB296FSRJP)

The listing texts are in `listing/<language>.md`, one file per language (18): description, "What's new in this
version", product features, keywords and screenshot captions. The package declares the same 18 languages
(`AppxManifest.xml` `<Resources>`; Uzbek and Hausa as `uz-Latn` and `ha-Latn`, the only forms Windows accepts), so
Partner Center asks for a listing in each. Arabic and English are written by the project; the other 16 are machine
translations not reviewed yet.

What the Store version has, and does not have (owner's decisions, 2026-11-20):
- The women's-singing model is in the package. Its first version catches only part of women's singing in real songs
  (about 1 in 10 on songs outside its training data; speech is kept): the texts call it an early version.
- Links: watch only (the link opens in the browser with the filter on). The Store's rules forbid saving from sites
  whose terms do not allow it (YouTube's), so the Store package has no save tools (yt-dlp, ffmpeg); the zip from
  GitHub has "Save without music". The Store version opens links in the browser and never contacts a site itself.

Screenshots: `screenshots/<language>/` (real captures of the app on Windows, 2732x1536).

## Submission settings

| Page | Value |
|---|---|
| Pricing and availability | Free. Markets: all. First submission: **Private audience** or "hidden, direct link only", to install and check on a real PC before making it public. |
| Properties: category | Utilities & tools |
| Properties: privacy policy URL | the privacy policy below, published (see "Privacy policy") |
| Properties: support contact | the owner's support email or the GitHub issues page: https://github.com/oksyassine/waaiya/issues |
| Properties: product declarations | none needed (no accessibility claims, no in-app purchases) |
| System requirements | Windows 10 version 2004 (build 19041) or newer, x64. Memory: 4 GB recommended. |
| Age ratings (IARC questionnaire) | Utility app. No violence, no sexual content, no gambling, no user communication or sharing, no location sharing, no purchases, no unrestricted web access. |
| Packages | `waaiya-store-x64-<version>.msix` (a release asset, or the `waaiya-store-msix` artifact of the Windows workflow). Unsigned: the Store signs it. |
| Notes for certification | the text below |

## Notes for certification (English)

> Waaiya removes musical instruments from the sound of the user's other apps, live, and keeps speech and Quran
> recitation. It is open source (AGPL-3.0): https://github.com/oksyassine/waaiya
>
> How it works, and why it needs runFullTrust: it is a desktop app (Flutter) with two helper programs in the
> package, engine\waaiya-filter.exe (sound filter) and engine\waaiya-blur.exe (optional screen blur). When the user
> presses the power button, the filter turns the other apps' volume down in the Windows volume mixer, captures their
> sound with the process-loopback API, removes the instruments with an on-device model (ONNX Runtime) and plays the
> result. Pressing the button again gives every app its volume back. Nothing is sent over the network; there is no
> account, no analytics and no advertising.
>
> The startup task "Waaiya" runs engine\waaiya-filter.exe autostart at login: it starts filtering only if the user
> turned on "Start at login" in the app's Settings; otherwise it gives apps their volume back if the computer was
> turned off while filtering, and exits.
>
> The optional screen blur (Screen page, off by default) draws click-through covers over people or immodest images
> on screen, detected on the device.
>
> The Links page: the user pastes a video link; "Watch" starts the filter if it is not running, waits until it
> filters, then opens the link in the user's default browser. The app itself does not contact the site and does not
> download anything (no download tools are in this package).
>
> The optional "Mute women's singing" (Filter page, for men) uses a second on-device model in the package
> (engine\models\detector\detector_v1.onnx).
>
> To test: open Waaiya, choose a gender on first launch, play any video with music in a browser, press the power
> button on the Filter page: the music is removed and speech remains. Press it again to stop.
>
> Note: if the app is uninstalled while filtering, Windows ends the filter and other apps keep the lowered volume
> until raised in the volume mixer; the app asks users to stop filtering first (README).

## Listings

See `listing/en.md`, `listing/ar.md` and the 16 other files in `listing/`.

## Privacy policy (to publish at the URL given in Properties)

> **Waaiya: privacy policy**
>
> Waaiya does not collect, store or send any personal information. The sound filter and the screen blur run
> entirely on your device; the sound and the screen are processed in memory and never recorded or sent anywhere.
> There is no account, no analytics, no advertising and no tracking. Your settings stay in Waaiya's own folder on
> your computer and are removed when you uninstall it.
>
> The Windows app from the Microsoft Store does not use the network. Its Links page opens a link you paste in your
> own web browser; Waaiya itself does not contact the site. The Windows app from GitHub (the zip) and the Android app
> also save a link's video without music: then they contact the site of the link you opened to download it, and
> nothing else. The Android app's yt-dlp downloads its own updates from PyPI.
>
> Source code: https://github.com/oksyassine/waaiya. Contact: https://github.com/oksyassine/waaiya/issues
