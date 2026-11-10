# Contributing to Waaiya

Thank you for helping. Bug reports, translations, tests on real devices and code are all welcome.

## Before you start

- For anything bigger than a small fix, open an issue first, so that we agree on the approach before you spend
  time on it.
- How the project is split, engine versus per-platform hosts: [docs/PLATFORMS.md](docs/PLATFORMS.md).
  Current state and open work: [docs/STATUS.md](docs/STATUS.md).

## Build

```bash
scripts/fetch_deps.sh                 # ONNX Runtime 1.19.2 and the default model, with checksums
make                                  # Linux engine, CLI, LADSPA plugin, im-pulse
cd android && ./gradlew assembleDebug # Android (JDK 17, Android SDK + NDK 27.1, Python 3.11 on PATH)
```

## Rules the project keeps

- **Fail-closed.** If the filter cannot run, the output is silent, never unfiltered. A change that can play
  unfiltered sound on any error path will not be merged.
- **Measure.** Model or engine changes come with `eval/evaluate.py` results on the test set and the parity
  tests (`models/dfn3/test_engine.py`, `models/detector/test_detector_engine.py`). Delay changes come with a
  measurement (`linux/test_run.sh`, `eval/latency/`).
- **Licences.** Only train on data whose licence allows publishing the resulting model, and list it in
  `THIRD_PARTY_LICENSES.md`. Add any new dependency to `THIRD_PARTY_LICENSES.md` and to the in-app licences
  screen.
- **No secrets in git**: no signing keys, tokens or personal paths. Model weights are release assets, not git
  files (`docs/MODELS.md`).
- **Two languages.** Every user-facing Android string needs an English and an Arabic version (`values/`,
  `values-ar/`), and layouts must work right-to-left.

## Pull requests

- Keep each pull request to one change, and say how you tested it: which device or OS, and what you heard or
  measured.
- CI (Android build and lint, Linux engine build and smoke test) must pass.
- By contributing you agree that your contribution is licensed under the GNU Affero General Public License, version 3 or any later version (`LICENSE`).
