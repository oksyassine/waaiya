#!/usr/bin/env python3
"""Checks one translation against the English source before it is used.

    python3 ui/tool/check_translation.py fr      # android/.../values-fr/strings.xml + ui/tool/extra_strings/fr.json

The Android folder of Indonesian is values-in (Android's old code for it); its extra file is extra_strings/id.json.
Checks: every translatable English string is there and nothing else; the same format arguments (%1$s, %1$d ...);
apostrophes and quotes escaped as Android needs (\\' and \\"); the same {placeholders} in the Flutter-only texts;
and, when the Android SDK is found, that aapt2 compiles the file.
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
RES = REPO / "android/app/src/main/res"
EXTRA = REPO / "ui/tool/extra_strings"


def strings(path):
    out = {}
    root = ET.parse(path).getroot()
    for el in root:
        if el.tag != "string":
            raise SystemExit(f"{path}: only <string> elements are expected, found <{el.tag}>")
        out[el.get("name")] = ("".join(el.itertext()), el.get("translatable") == "false")
    return out


def args(text):
    return sorted(re.findall(r"%\d+\$[sd]|%[sd]", text))


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    lang = sys.argv[1]
    folder = "in" if lang == "id" else lang
    extra_lang = "id" if lang in ("in", "id") else lang
    path = RES / f"values-{folder}/strings.xml"
    problems = []
    en = strings(RES / "values/strings.xml")
    tr = strings(path)
    want = {k for k, (_, untranslatable) in en.items() if not untranslatable}
    for k in sorted(want - tr.keys()):
        problems.append(f"missing: {k}")
    for k in sorted(tr.keys() - want):
        problems.append(f"not in the English file (or not translatable): {k}")
    for k in sorted(want & tr.keys()):
        src, text = en[k][0], tr[k][0]
        if args(src) != args(text):
            problems.append(f"{k}: format arguments {args(text)} instead of {args(src)}")
        if not text.strip():
            problems.append(f"{k}: empty")
        if re.search(r"(?<!\\)'", text) and not (text.startswith('"') and text.endswith('"')):
            problems.append(f"{k}: apostrophe not escaped (write \\')")
        if re.search(r'(?<!\\)"', text):
            problems.append(f'{k}: quote not escaped (write \\" or use “ ”)')
        if text.startswith(("@", "?")):
            problems.append(f"{k}: starts with @ or ? (write \\@ or \\?)")
        if src.count("\\n") != text.count("\\n"):
            problems.append(f"{k}: {text.count(chr(92) + 'n')} line breaks (\\n) instead of {src.count(chr(92) + 'n')}")
    en_extra = json.loads((EXTRA / "en.json").read_text(encoding="utf-8"))
    extra_path = EXTRA / f"{extra_lang}.json"
    if not extra_path.is_file():
        problems.append(f"missing file {extra_path.relative_to(REPO)}")
    else:
        ex = json.loads(extra_path.read_text(encoding="utf-8"))
        for k in sorted(en_extra.keys() - ex.keys()):
            problems.append(f"extra: missing {k}")
        for k in sorted(ex.keys() - en_extra.keys()):
            problems.append(f"extra: unknown key {k}")
        for k in sorted(en_extra.keys() & ex.keys()):
            if sorted(re.findall(r"\{\w+\}", en_extra[k])) != sorted(re.findall(r"\{\w+\}", ex[k])):
                problems.append(f"extra {k}: placeholders differ from English")
    sdk = Path(os.environ.get("ANDROID_HOME", "/srv/homecache/Android/Sdk")) / "build-tools"
    tools = sorted(sdk.glob("*/aapt2")) if sdk.is_dir() else []
    if tools:
        with tempfile.TemporaryDirectory() as d:
            r = subprocess.run([str(tools[-1]), "compile", str(path), "-o", d], capture_output=True, text=True)
            if r.returncode:
                problems.append("aapt2: " + (r.stderr or r.stdout).strip()[:2000])
    for p in problems:
        print(p)
    print(f"{lang}: {'OK' if not problems else str(len(problems)) + ' problem(s)'} ({len(tr)} strings)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
