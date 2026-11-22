#!/usr/bin/env python3
"""Makes the in-app update files for a release: the release files and small patches from the last published versions.

    python3 site/make_update.py 0.2.15 [--from 4] [--out DIR]

Two apps read them since Waaiya moved to org.waaiya.app (0.2.15, docs/MOVE.md):
- waaiya-update.json: org.waaiya.app, from waaiya-v<version>-<variant>-release.apk.
- update.json: org.islamicmute.app, read by 0.2.14 and older. Written only for a release that has the old name's
  move build (waaiya-v<version>-move-<variant>-release.apk, 0.2.15); afterwards it stays at that version, which
  offers to install the new app.

Reads the release's signed APKs from /srv/build/waaiya-downloads/<version>/ (upload_downloads.sh puts them there) and
the APKs of the last N earlier releases from GitHub (cached next to them). For each earlier version and each variant
(universal, arm64-v8a, armeabi-v7a) it makes a zstd "--patch-from" patch that rebuilds the new APK from the old one,
checks it rebuilds byte for byte, and keeps it if it saves at least 40 %. The app (AppUpdate.kt) picks the patch whose
"from" is the SHA-256 of the APK installed on the phone, else the full APK of the same variant.

Guards, before anything is written: every new APK is the expected package with the version code in
android/app/build.gradle.kts, newer than every earlier one, and signed with the same certificate as the earlier
releases. Output: DIR (default <downloads>/<version>/update/) with update.json and patches/; upload the patches
first and update.json last (upload_downloads.sh does).
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parents[1]
GH_REPO = "oksyassine/waaiya"
SITE = "https://waaiya.mssid.org/downloads/"
DOWNLOADS = Path("/srv/build/waaiya-downloads")
VARIANTS = ("universal", "arm64-v8a", "armeabi-v7a")
NEW_ID, OLD_ID = "org.waaiya.app", "org.islamicmute.app"
# (package, release file, APK name of this release); an earlier release's APK is always waaiya-v<v>-<variant>-release.apk
APPS = ((NEW_ID, "waaiya-update.json", ""), (OLD_ID, "update.json", "move-"))
NOTES = {"en": "en-US", "ar": "ar", "fr": "fr-FR"}  # update.json language -> fastlane folder
MAX_PATCH_RATIO = 0.6


def sh(*cmd, **kw):
    return subprocess.run(cmd, check=True, text=True, capture_output=True, **kw).stdout


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def build_tool(name: str) -> str:
    tools = sorted((Path.home() / "Android/Sdk/build-tools").glob(f"*/{name}"))
    if not tools:
        sys.exit(f"{name} not found in ~/Android/Sdk/build-tools")
    return str(tools[-1])


def apk_info(apk: Path):
    """(package, versionCode, set of signer certificate SHA-256)."""
    badging = sh(build_tool("aapt2"), "dump", "badging", str(apk))
    m = re.search(r"package: name='([^']+)' versionCode='(\d+)'", badging)
    if not m:
        sys.exit(f"{apk.name}: not an APK")
    certs = set(re.findall(r"certificate SHA-256 digest: ([0-9a-f]{64})", sh(build_tool("apksigner"), "verify", "--print-certs", str(apk))))
    if not certs:
        sys.exit(f"{apk.name}: not signed")
    return m.group(1), int(m.group(2)), certs


def apk_name(version: str, variant: str, kind: str = "") -> str:
    return f"waaiya-v{version}-{kind}{variant}-release.apk"


def earlier_versions(version: str, count: int):
    tags = json.loads(sh("gh", "release", "list", "-R", GH_REPO, "--limit", "50", "--json", "tagName,isDraft,isPrerelease"))
    def key(v):
        return tuple(int(x) for x in v.split("."))
    vs = sorted({t["tagName"][1:] for t in tags if not t["isDraft"] and not t["isPrerelease"]
                 and re.fullmatch(r"v\d+\.\d+\.\d+", t["tagName"])}, key=key)
    return [v for v in vs if key(v) < key(version)][-count:]


def fetch_old(version: str) -> Path:
    d = DOWNLOADS / version
    d.mkdir(parents=True, exist_ok=True)
    missing = [v for v in VARIANTS if not (d / apk_name(version, v)).is_file()]
    if missing:
        args = ["gh", "release", "download", f"v{version}", "-R", GH_REPO, "-D", str(d), "--clobber"]
        for v in missing:
            args += ["-p", apk_name(version, v)]
        subprocess.run(args, check=False)
    return d


def notes(version_code: int):
    out = {}
    for lang, folder in NOTES.items():
        p = REPO_DIR / f"fastlane/metadata/android/{folder}/changelogs/{version_code}.txt"
        if p.is_file():
            out[lang] = p.read_text().strip()[:2000]
    return out


def release_file(package, file_name, kind, v, code, olds, out):
    """One app's release file and its patches; None when this release has no APKs of that app."""
    new_dir = DOWNLOADS / v
    if not (new_dir / apk_name(v, "universal", kind)).is_file():
        return None
    new = {}
    certs = None
    for variant in VARIANTS:
        apk = new_dir / apk_name(v, variant, kind)
        if not apk.is_file():
            sys.exit(f"missing {apk}")
        pkg, vc, c = apk_info(apk)
        if pkg != package or vc != code:
            sys.exit(f"{apk.name}: {pkg} {vc}, expected {package} {code}")
        if certs is not None and c != certs:
            sys.exit(f"{apk.name}: signed with another certificate than the other variants")
        certs = c
        new[variant] = apk

    known = {}
    patches = []
    used = []
    for ov in olds:
        d = fetch_old(ov)
        for variant in VARIANTS:
            old = d / apk_name(ov, variant)
            if not old.is_file():
                print(f"  {ov} {variant}: not published, no patch")
                continue
            pkg, ovc, oc = apk_info(old)
            if pkg != package:
                continue  # the other app (before or after the move): no patch between different apps
            if ovc >= code:
                sys.exit(f"{old.name}: {pkg} {ovc}, expected older than {code}")
            if oc != certs:
                sys.exit(f"{old.name}: earlier release signed with another certificate: the update would not install")
            if ov not in used:
                used.append(ov)
            osha = sha256(old)
            known[osha] = variant
            target = new[variant]
            patch = out / "patches" / f"waaiya-v{v}-{kind}{variant}-from-{osha[:16]}.zst"
            # --patch-from sizes the window to the old APK; the phone's decoder allows up to 2^30 (checked below)
            subprocess.run(["zstd", "-q", "-19", f"--patch-from={old}", str(target), "-o", str(patch)], check=True)
            check = out / "check.apk"
            subprocess.run(["zstd", "-q", "-d", "--long=30", f"--patch-from={old}", str(patch), "-o", str(check)], check=True)
            same = sha256(check) == sha256(target)
            check.unlink()
            if not same:
                sys.exit(f"{patch.name}: does not rebuild the new APK")
            ratio = patch.stat().st_size / target.stat().st_size
            print(f"  {ov} -> {v} {kind}{variant}: {patch.stat().st_size / 1e6:.1f} MB ({ratio:.0%} of {target.stat().st_size / 1e6:.0f} MB)")
            if ratio > MAX_PATCH_RATIO:
                patch.unlink()
                continue
            patches.append({"from": osha, "variant": variant, "url": SITE + "patches/" + patch.name,
                            "sha256": sha256(patch), "size": patch.stat().st_size})

    apks = {}
    for variant, apk in new.items():
        sha = sha256(apk)
        known[sha] = variant
        apks[variant] = {"url": SITE + apk.name, "sha256": sha, "size": apk.stat().st_size}
    manifest = {
        "schema": 1,
        "android": {"versionCode": code, "versionName": v, "apks": apks, "patches": patches, "known": known},
        "desktop": {"version": v, "page": "https://waaiya.mssid.org/#download"},
        "notes": notes(code),
    }
    (out / file_name).write_text(json.dumps(manifest, indent=1, ensure_ascii=False) + "\n")
    print(f"{out}/{file_name} ({package}): {len(patches)} patches from {', '.join(used) or 'no earlier release'}")
    return file_name


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version")
    ap.add_argument("--from", dest="count", type=int, default=4, help="patches from this many earlier releases")
    ap.add_argument("--out")
    a = ap.parse_args()
    v = a.version
    out = Path(a.out) if a.out else DOWNLOADS / v / "update"
    if out.exists():
        shutil.rmtree(out)
    (out / "patches").mkdir(parents=True)

    gradle = (REPO_DIR / "android/app/build.gradle.kts").read_text()
    code = int(re.search(r"versionCode\s*=\s*(\d+)", gradle).group(1))
    name = re.search(r'versionName\s*=\s*"([^"]+)"', gradle).group(1)
    if name != v:
        sys.exit(f"build.gradle.kts says {name}, not {v}")
    olds = earlier_versions(v, a.count)
    written = [f for f in (release_file(pkg, file_name, kind, v, code, olds, out) for pkg, file_name, kind in APPS) if f]
    if "waaiya-update.json" not in written:
        sys.exit("no APKs of org.waaiya.app for this release")


if __name__ == "__main__":
    main()
