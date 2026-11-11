#!/usr/bin/env python3
"""Generates ui/lib/l10n/app_ar.arb and app_en.arb from the Android string resources.

The Android strings (android/app/src/main/res/values{,-ar}/strings.xml) are the source: the Arabic texts are
reviewed there and are copied verbatim. Strings only the native side uses (notification, blur covers, accessibility
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

# Native-only strings (notification, blur covers drawn by the service, accessibility service).
SKIP = re.compile(r"^(notif_.*|blur_cover_.*|blur_not_working|blur_a11y_.*|link_channel)$")

# Android format arguments -> named placeholders, per string.
PLACEHOLDERS = {
    "state_on_detail": [("delayMs", "int")],
    "step_todo_cd": [("step", "int")],
    "setup_failed": [("details", "String")],
    "blur_setup_failed": [("details", "String")],
    "setting_language_title": [("language", "String")],
    "link_meta": [("first", "String"), ("second", "String")],
    "blur_strict_value": [("level", "String")],
}

# Strings the Flutter screens need that the Android screens did not have. The Arabic here is NOT reviewed yet.
EXTRA = {
    "desktop_preview": (
        "Preview: the filter engine is not connected on this computer yet. The button only shows how the app will work.",
        "معاينة: محرك التصفية غير موصول بهذا الحاسوب بعد. الزر يعرض فقط كيف سيعمل التطبيق.",
    ),
    "action_failed": (
        "That did not work: {details}",
        "تعذّر ذلك: {details}",
    ),
}
EXTRA_PLACEHOLDERS = {"action_failed": [("details", "String")]}


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


def build() -> dict:
    en, ar = load(RES / "values/strings.xml"), load(RES / "values-ar/strings.xml")
    arb = {"ar": {"@@locale": "ar"}, "en": {"@@locale": "en"}}
    for name, (raw_en, untranslatable) in en.items():
        if SKIP.match(name):
            continue
        places = PLACEHOLDERS.get(name)
        if name in ar:
            raw_ar = ar[name][0]
        elif untranslatable:
            raw_ar = raw_en
        else:
            raise SystemExit(f"{name}: no Arabic text in values-ar/strings.xml")
        key = camel(name)
        arb["en"][key] = convert(name, raw_en, places)
        arb["ar"][key] = convert(name, raw_ar, places)
        meta = {"description": f"Android string {name}"}
        if places:
            meta["placeholders"] = {p: {"type": t} for p, t in places}
        arb["ar"]["@" + key] = meta
    for name, (text_en, text_ar) in EXTRA.items():
        key = camel(name)
        arb["en"][key] = text_en
        arb["ar"][key] = text_ar
        meta = {"description": "Flutter only. Arabic not reviewed yet."}
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
