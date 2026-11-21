# Building Waaiya yourself, and checking a release

Waaiya's claim is that it sends nothing (docs/PRIVACY.md). This page shows how anyone can check that the programs we
publish are built from this repository, and how to build them without us.

## What a release is made of

| Part | Where it comes from | How to check it |
|---|---|---|
| Source | This repository, at the release tag (`vX.Y.Z`) | `git checkout vX.Y.Z`; tags are never moved after a release is final |
| Models (sound filter, women's-singing detector, blur) | GitHub release assets `models-v1` and `vision-v1`, never in git (docs/MODELS.md) | Each tag pins a `SHA256SUMS`; `scripts/fetch_deps.sh` refuses a file whose hash differs |
| ONNX Runtime | Microsoft's published packages: the Android AAR from Maven Central, the Linux and Windows libraries from NuGet, version pinned in `android/app/build.gradle.kts` and `scripts/fetch_deps.sh` | Same version, same hashes as Microsoft publishes |
| yt-dlp, yt-dlp-ejs, QuickJS (links only) | PyPI wheels and the QuickJS-ng release, versions pinned in `android/app/build.gradle.kts` (Windows: `scripts/fetch_deps.sh`) | PyPI's SHA-256; the pinned release hashes |
| Builds | GitHub Actions on GitHub's own runners (`.github/workflows/release.yml`, `android.yml`, `linux.yml`, `windows.yml`), logs public | Every release links its workflow run |

Pinned tools (CI): Ubuntu 22.04 (Linux desktop) and 24.04 (Android, engine), Java 17 (Temurin), Android NDK
27.1.12297006, CMake 3.22.1, Python 3.11, Flutter 3.41.5 stable.

## Build it

```sh
git clone https://github.com/oksyassine/waaiya && cd waaiya && git checkout vX.Y.Z
scripts/fetch_deps.sh              # models, ONNX Runtime; checked against SHA256SUMS
make all                           # C engine, command-line tools, Linux filter
make build/test-failclosed && build/test-failclosed   # the engine's fail-closed checks
(cd android && ./gradlew assembleRelease -PimBuildPython=$(command -v python3.11))
(cd desktop && flutter build linux --release)
```

The Android build without a signing key writes `app-release-unsigned.apk`. The Windows build steps are in
`.github/workflows/windows.yml`.

## Compare your build with ours

Android APKs differ in their signature, so compare everything but the signature:

```sh
pip install apksigcopier         # or: diffoscope ours.apk yours.apk
apksigcopier compare waaiya-X.Y.Z.apk --unsigned app-release-unsigned.apk && echo same
```

`apksigcopier compare` copies our signature onto your unsigned build and checks the result is byte-identical to
ours. If it reports a difference, `diffoscope` shows where.

What is known not to be bit-for-bit yet (open work, said here rather than hidden):
- The Python part of the link reader (Chaquopy) and the R8 shrinker have not been checked for identical output
  between two machines; differences there would show as changed `.dex` or `assets/chaquopy` entries.
- The Linux and Windows archives carry file times; compare their contents (`tar -xf`, `unzip`) and the hashes of
  each program, not the archive itself.

Report any difference in an issue, with the diffoscope output.

## Check that it sends nothing

You do not have to trust the build at all to check the main claim:

- Linux: `make build/no-network.so && linux/test_no_network.sh` runs the filters and the detector with every
  internet connection refused and logged; the log must stay empty.
- Android: the filter and blur code paths are kept free of network calls by `NoNetworkTest.kt`; on a phone, a
  firewall app (or `adb shell dumpsys netstats`) shows Waaiya's traffic: none unless you open a link.
