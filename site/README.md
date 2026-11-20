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
