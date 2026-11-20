# waaiya.mssid.org

The landing page: Arabic at `/`, English at `/en/`, the privacy policy (`docs/PRIVACY.md`) at `/privacy.html`.

- `build.py` writes `public/` from one template (texts for both languages are in it), `style.css` and `page.js`.
- `deploy.sh` builds and uploads to the o2switch host.
- Pictures are Waaiya's own: the hero spectrograms are drawn from a real 10 s mix of the test set (`speech_ar_0`,
  Arabic Speech Corpus voice, CC BY 4.0, with music the project synthesised) before and after the real filter
  (`build/im-process`, dfn3_stream_int8); the phone pictures are the 0.2.12 release on the Android 15 emulator;
  the film is the 50 s intro (`/srv/build/waaiya-intro`, draft 2).
