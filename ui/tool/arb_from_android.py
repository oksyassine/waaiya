#!/usr/bin/env python3
"""Generates ui/lib/l10n/app_<language>.arb from the Android string resources.

The Android strings (android/app/src/main/res/values{,-ar,-fr,...}/strings.xml) are the source: the Arabic texts are
reviewed there and are copied verbatim. Every values-<language> folder with a strings.xml is a language of the app
(values-in is Indonesian, "id" in Flutter). A text missing from a language is an error: Flutter would otherwise show
the Arabic template's text in its place. Strings only the native side uses (notification, blur covers, accessibility
service) are left out. Flutter-only strings are in EXTRA below.

    python3 ui/tool/arb_from_android.py           # write the ARB files
    python3 ui/tool/arb_from_android.py --check   # fail if they are out of date (CI)

Then run `flutter gen-l10n` in ui/ (the generated Dart is committed: path dependencies do not run gen-l10n).
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
RES = REPO / "android/app/src/main/res"
OUT = REPO / "ui/lib/l10n"

# Native-only strings (notification, blur covers drawn by the service, accessibility service). The "Waaiya
# stopped" notice is also the desktop screen's text when the filter stopped by itself.
# Quick Settings tiles (tile_*) and the illustrated setup guide (guide_w_*) are Android-only too.
SKIP = re.compile(r"^(notif_(?!stopped_).*|blur_cover_.*|blur_not_working|blur_a11y_.*|link_channel|tile_.*|shortcut_.*|guide_w_.*)$")

# Android format arguments -> named placeholders, per string.
PLACEHOLDERS = {
    "state_on_detail": [("delayMs", "int")],
    "step_todo_cd": [("step", "int")],
    "setup_failed": [("details", "String")],
    "blur_setup_failed": [("details", "String")],
    "setting_language_title": [("language", "String")],
    "link_meta": [("first", "String"), ("second", "String")],
    "blur_strict_value": [("level", "String")],
    "state_blocked_silenced": [("apps", "String")],
    "state_blocked_unfiltered": [("apps", "String")],
    "wsetup_detail": [("details", "String")],
}

# Strings the Flutter screens need that the Android screens did not have: ui/tool/extra_strings/<language>.json
# (the Arabic there is NOT reviewed yet; the other languages except English are machine translations).
EXTRA_DIR = REPO / "ui/tool/extra_strings"

EXTRA_PLACEHOLDERS = {
    "action_failed": [("details", "String")],
    "engine_error_install_failed": [("details", "String")],
    "engine_error_start_failed": [("details", "String")],
    "engine_error_service_failed": [("details", "String")],
    "blur_status_no_capture": [("details", "String")],
    "blur_status_no_overlay_desktop": [("details", "String")],
    "blur_status_exited": [("details", "String")],
}


def camel(name: str) -> str:
    head, *rest = name.split("_")
    return head + "".join(p[:1].upper() + p[1:] for p in rest)


def unescape(s: str) -> str:
    """Android resource escapes -> plain text."""
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            out.append({"n": "\n", "t": "\t", "'": "'", '"': '"', "\\": "\\", "@": "@", "?": "?"}.get(n, n))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def load(path: Path) -> dict:
    strings = {}
    for el in ET.parse(path).getroot().findall("string"):
        strings[el.get("name")] = ("".join(el.itertext()), el.get("translatable") == "false")
    return strings


def convert(name: str, raw: str, places) -> str:
    text = unescape(raw)
    for idx, (pname, _) in enumerate(places or [], start=1):
        text = re.sub(r"%%%d\$[ds]" % idx, "{%s}" % pname, text)
    if re.search(r"%\d*\$?[ds]", text):
        raise SystemExit(f"{name}: format argument without a placeholder name: {text!r}")
    return text


def languages() -> dict:
    """Flutter language tag -> Android values folder, English and Arabic first."""
    found = {"en": RES / "values"}
    for d in sorted(RES.glob("values-*")):
        tag = d.name.split("-", 1)[1]
        if re.fullmatch(r"[a-z]{2,3}", tag) and (d / "strings.xml").is_file():
            found["id" if tag == "in" else tag] = d
    return dict(sorted(found.items(), key=lambda kv: ({"ar": 0, "en": 1}.get(kv[0], 2), kv[0])))


def build() -> dict:
    langs = languages()
    texts = {tag: load(d / "strings.xml") for tag, d in langs.items()}
    en = texts["en"]
    arb = {tag: {"@@locale": tag} for tag in langs}
    for name, (raw_en, untranslatable) in en.items():
        if SKIP.match(name):
            continue
        places = PLACEHOLDERS.get(name)
        key = camel(name)
        for tag in langs:
            if name in texts[tag]:
                raw = texts[tag][name][0]
            elif untranslatable:
                raw = raw_en
            else:
                raise SystemExit(f"{name}: no text in {langs[tag].relative_to(REPO)}/strings.xml")
            arb[tag][key] = convert(name, raw, places)
        meta = {"description": f"Android string {name}"}
        if places:
            meta["placeholders"] = {p: {"type": t} for p, t in places}
        arb["ar"]["@" + key] = meta
    extra = {}
    for tag in langs:
        f = EXTRA_DIR / f"{tag}.json"
        if not f.is_file():
            raise SystemExit(f"missing {f.relative_to(REPO)} (the Flutter-only texts in that language)")
        extra[tag] = json.loads(f.read_text(encoding="utf-8"))
    for name, text_en in extra["en"].items():
        key = camel(name)
        for tag in langs:
            if name not in extra[tag]:
                raise SystemExit(f"{name}: missing from extra_strings/{tag}.json")
            arb[tag][key] = extra[tag][name]
        meta = {"description": "Flutter only. Not reviewed yet except in English."}
        if name in EXTRA_PLACEHOLDERS:
            meta["placeholders"] = {p: {"type": t} for p, t in EXTRA_PLACEHOLDERS[name]}
        arb["ar"]["@" + key] = meta
    return {lang: json.dumps(d, ensure_ascii=False, indent=2) + "\n" for lang, d in arb.items()}


def main() -> int:
    check = "--check" in sys.argv[1:]
    stale = []
    for lang, text in build().items():
        path = OUT / f"app_{lang}.arb"
        if check:
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                stale.append(str(path.relative_to(REPO)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
    if stale:
        print("Out of date with the Android strings (run python3 ui/tool/arb_from_android.py):", *stale, sep="\n  ")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
