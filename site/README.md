# waaiya.mssid.org

The landing page: Arabic at `/`, English at `/en/`, the privacy policy (`docs/PRIVACY.md`) at `/privacy.html`.

- `build.py` writes `public/` from one template (texts for both languages are in it), `style.css` and `page.js`.
  `--preview` adds `noindex`.
- `deploy.sh` builds and uploads to the o2switch host; `deploy.sh --preview` uploads to `/preview/` only.
- `make_assets.py` (run with the repo's venv) makes the generated assets from real material: the spectrograms
  before and after the real filter (one shared dB scale), the music-band texture (what the filter removed), the
  filtered sound (`filtered.webm/.m4a`, from `out.wav` only: the unfiltered mix is never published), the 18
  language screens from `desktop/windows/msix/screenshots/<lang>/1-filter.png`, and the loudspeaker frame from the
  intro film's footage. Inputs live in `site/.work/` (not committed): `mix.wav` = testset `speech_ar_0_mvr-3`
  (voice: Arabic Speech Corpus, Nawar Halabi, CC BY 4.0; music synthesised by the project) and `out.wav` =
  `build/im-process -m models/dfn3/dfn3_stream_int8.onnx mix.wav out.wav`.
- Nothing is fetched from another server: IBM Plex Sans Arabic (OFL, `assets/fonts/OFL.txt`) and GSAP 3.15.0
  (`assets/js/GSAP-LICENSE.txt`) are in `assets/`. The only outside links are the downloads and the source.
- Phone pictures: the 0.2.12 release on the Android 15 emulator. Film: the 50 s intro (`/srv/build/waaiya-intro`).

## Try it on your sound

`try/` holds the in-browser filter (the app's model via ONNX Runtime Web, copied into `assets/try/` by `build.py`,
which needs the model in `models/dfn3` or `WAAIYA_MODELS=<dir>`). A link is fetched by the servers in `link/`:
see `link/README.md`.

## Set up from a computer (/usb/)

`usb/` holds the page that gives Waaiya its Android permissions from Chrome or Edge over a USB cable (WebUSB, our own
small ADB client; nothing loaded from elsewhere). `build.py` writes `usb/index.html` (Arabic) and `en/usb/index.html`
and copies the scripts to `assets/usb/`. How it works and what was checked: `docs/SETUP.md`, "Route 3 from a
browser". Tests:

    node site/usb/test/adb_unit.mjs                         # signatures, adb's key format, the "Allow" prompt
    python3 site/build.py --preview && node site/usb/test/page_test.mjs    # the page with a simulated USB phone
    adb kill-server && node site/usb/test/adb_e2e.mjs 127.0.0.1:<emulator port + 1> --setup   # a real adbd

## Automatic deploy

The live site follows `main`: `site/auto_deploy.sh`, run every 5 minutes by a systemd user timer, fetches `main` into
its own clone and runs `deploy.sh` when a new commit touched `site/`, `docs/PRIVACY.md` or `models/SHA256SUMS`.
Install it (or update it) on the machine that has the `o2` ssh alias:

    site/install_auto_deploy.sh <clone dir> [voice model dir]
    journalctl --user -u waaiya-site-deploy -n 20     # what it did
    site/install_auto_deploy.sh --remove

Merging to `main` is publishing; use `deploy.sh --preview` to look at a change first.
