# Microsoft Store: what to fill in (Partner Center, app "Waaiya", Store ID 9NBB296FSRJP)

Follows Microsoft's checklist, "Create an app submission for your MSIX app"
(learn.microsoft.com/windows/apps/publish/publish-your-app/msix/create-app-submission), section by section.

What the Store version has, and does not have (owner's decisions, 2026-11-20):
- The women's-singing model is in the package. Its first version catches only part of women's singing in real songs
  (about 1 in 10 on songs outside its training data; speech is kept): the texts call it an early version.
- Links: watch only (the link opens in the browser with the filter on). The Store's rules forbid saving from sites
  whose terms do not allow it (YouTube's), so the Store package has no save tools (yt-dlp, ffmpeg); the zip from
  GitHub has "Save without music". The Store version opens links in the browser and never contacts a site itself.

Before submitting: run the Windows App Certification Kit on the package (Microsoft asks for it; it needs an
administrator): `appcert.exe test -appxpackagepath <waaiya-store.msix> -reportoutputpath <report.xml>`, or the
"Windows App Cert Kit" app, "Validate Store App".

Result on the owner's PC (2026-11-20, package 1.2.12.0 from commit 703bd88, Windows 11 build 26200): **PASS**,
22 tests passed. Two optional tests flag, as for most desktop apps, and neither blocks certification:
- "Archive files usage": `data\flutter_assets\NOTICES.Z` is Flutter's own compressed licence list, in every Flutter
  app.
- "Blocked executables": the programs can start processes (CreateProcessW: the app starts its own filter and blur;
  the filter starts its own restorer), and short letter runs such as "reg", "cmd", "csi" appear inside binaries and
  the model files. The Store version never runs reg.exe or cmd.exe: "Start at login" is a file in the app's data
  folder, and the only reg.exe call (finding the Videos folder) belongs to "Save without music", which the Store
  package does not have.

## 1. Pricing and availability

| Field | Value |
|---|---|
| Markets | All (the default). |
| Audience | **Choose before the first submission: it cannot be undone.** A first submission as "Public audience" can never become private later. "Private audience" needs a known user group of testers with personal Microsoft accounts (not work or school), and no scheduled release date. To check the Store version on a real PC first without a private group: keep Public, and set Discoverability to "not discoverable" (direct link only) for the first submission. |
| Discoverability | First submission: "Make this product available but not discoverable in the Store" (direct link only: https://apps.microsoft.com/detail/9NBB296FSRJP). Later: "available and discoverable". |
| Schedule | Release as soon as possible (the default). |
| Base price | Free. No free trial, no sale pricing. |
| Organizational licensing | Leave on (the default). |

## 2. Properties

| Field | Value |
|---|---|
| Category | Utilities & tools (no subcategory needed). |
| Privacy policy | "Does this product access, collect or transmit personal information?" **No.** Microsoft may still ask for a URL because of runFullTrust: give https://github.com/oksyassine/waaiya/blob/main/PRIVACY.md (the file `PRIVACY.md`; it is on GitHub's main branch once this branch is merged). |
| Website | https://github.com/oksyassine/waaiya |
| Support contact | https://github.com/oksyassine/waaiya/issues (or the owner's support email) |
| Contact details | Only for a company account: the owner's details (never put in this repository). |
| Display mode, product declarations | Leave as they are (no accessibility claims, no in-app purchases, no Xbox). |
| System requirements | Optional. Minimum: Windows 10 version 2004 (build 19041), x64; memory 4 GB. |

## 3. Age ratings (IARC questionnaire, required)

Category: utility / productivity app. Answer every question truthfully: no violence, no sexual content, no gambling,
no controlled substances, no crude humour; users do not communicate or share with each other; no location sharing; no
purchases; it does not give unrestricted web access (the Links page only opens the user's own browser). The
publisher's display name and email are shared with IARC.

## 4. Packages

`waaiya-store-x64-<version>.msix`: a release asset, the `waaiya-store-msix` artifact of the Windows workflow, or
`desktop/tool/make_msix.ps1 -App <app folder> -Out waaiya-store.msix`. Unsigned: the Store signs it. Version
1.2.12.0 for app 0.2.12 (the last number must stay 0; the Store uses it). Device family: Windows 10/11 Desktop only.
Partner Center must show "Validated" for the package (errors block the submission; warnings do not).

## 5. Store listings

17 languages: `listing/<language>.md` (Arabic and English written by the project; the other 15 are machine
translations not reviewed yet). Somali (`listing/so.md`) is kept but not used: the Store does not support Somali,
so the package does not declare it either (the app itself still offers Somali). Screenshots: `screenshots/<language>/`
(4 real captures each, 1366x768, the Store's minimum for PCs); app tile icon 1:1 300x300: `store_logo_300.png`.

The fastest way (Microsoft's "Import and export Store listings"):
1. Partner Center, the app's overview > Store listings > **Export listings**: save the .csv.
2. `python desktop/tool/store_import.py <the exported .csv> --out waaiya-listings`: fills Description, a short
   description, features, search terms, the 4 screenshots with captions, title, logo, copyright and "Developed by"
   for the 17 languages, checks every limit, and puts the screenshots and logo next to the .csv.
3. Store listings > **Import listings > Import folder** > `waaiya-listings`. Fix what "View errors" lists, if any.

"What's new in this version": Microsoft asks to leave it empty on a first submission; the texts are ready in each
`listing/<language>.md` for the next update (`store_import.py --whats-new`). Descriptions contain no web addresses
(not allowed in the description); the source is in Website.

## 6. Submission options

| Field | Value |
|---|---|
| Publishing hold | First submission: "Publish this submission as soon as it passes certification" is fine with "not discoverable"; or hold manually to check it first. |
| Notes for certification | the English text below |
| Restricted capabilities (required: the package declares runFullTrust) | the "runFullTrust" text below |

### runFullTrust: why and how it is used

> Waaiya is a desktop app (Flutter, Win32) packaged with the Desktop Bridge, with two helper programs in the
> package: engine\waaiya-filter.exe and engine\waaiya-blur.exe. runFullTrust is needed because the sound filter uses
> Win32 audio APIs not available to sandboxed apps: it lowers the other apps' session volumes through the Windows
> volume mixer (IAudioSessionManager2 / ISimpleAudioVolume), captures their sound with process loopback
> (ActivateAudioInterfaceAsync, AUDIOCLIENT_ACTIVATION_TYPE_PROCESS_LOOPBACK), filters it on the device with ONNX
> Runtime, and plays the result. The optional screen blur draws click-through topmost windows (desktop duplication).
> A startup task (windows.startupTask) starts the filter at login only if the user turned on "Start at login".
> Nothing is sent over the network.

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
> Updating or uninstalling the app while it filters: Windows asks the filter to close (WM_ENDSESSION,
> ENDSESSION_CLOSEAPP) and it gives every app its volume back first. After an update, Windows starts the filter
> again (RegisterApplicationRestart) and it filters again.

## Privacy policy

`PRIVACY.md` at the top of the repository (the URL in Properties).
