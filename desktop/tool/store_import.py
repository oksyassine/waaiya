"""Fills a Store listings file exported from Partner Center with Waaiya's listings, for "Import listings > Import
folder" (learn.microsoft.com/windows/apps/publish/publish-your-app/msix/import-and-export-store-listings).

    python desktop/tool/store_import.py <exported.csv> [--out waaiya-listings] [--whats-new]

Partner Center: the app's overview > Store listings > Export listings gives the .csv; its Field, ID and Type columns
must stay as they are, so this starts from that file. It writes <out>/listings.csv (UTF-8) and copies the screenshots
and the 300x300 logo into <out>, with paths that start with the folder's name, as Partner Center wants. Then: Import
listings > Import folder > <out>.

Filled per language (from desktop/windows/msix/listing/<lang>.md): Description, ShortDescription (its first
paragraph), Feature1..20, SearchTerm1..7, DesktopScreenshot1..4 with their captions, Title and the logo (default
column). "What's new" (ReleaseNotes) only with --whats-new: Microsoft asks to leave it empty on a first submission.
Somali has no listing: the Store does not support it. Every limit is checked before writing; fields this does not
know are left as they are and listed at the end.
"""
import argparse
import csv
import os
import re
import shutil
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "windows", "msix"))
# Store language code for each listing file (the Store's supported list: no Somali)
LANGS = {"en": "en-us", "ar": "ar", "fr": "fr", "ur": "ur", "id": "id", "tr": "tr", "bn": "bn", "fa": "fa",
         "ms": "ms", "es": "es", "nl": "nl", "de": "de", "it": "it", "ru": "ru", "uz": "uz-latn", "sw": "sw",
         "ha": "ha-latn"}
SHOTS = ["1-filter.png", "2-links.png", "3-screen.png", "4-settings.png"]  # same order as the captions


def listing(lang):
    s = open(os.path.join(ROOT, "listing", lang + ".md"), encoding="utf-8").read()
    sec = {m.group(1).split(" (")[0].strip(): m.group(2).strip()
           for m in re.finditer(r"^## (.+?)\n(.*?)(?=^## |\Z)", s, re.S | re.M)}
    desc = sec["Description"]
    return {
        "Description": desc,
        "ShortDescription": desc.split("\n\n")[0].replace("\n", " "),
        "ReleaseNotes": sec.get("What's new in this version", ""),
        "features": [l[2:].strip() for l in sec["Product features"].splitlines() if l.startswith("- ")],
        "terms": [t.strip() for t in re.split(r"[,،、]", sec["Keywords"]) if t.strip()],
        "captions": [l.split(". ", 1)[1].strip() for l in sec["Screenshot captions"].splitlines()
                     if re.match(r"\d+\. ", l)],
    }


def check(lang, d):
    """Partner Center's limits (add-and-edit-store-listing-info, screenshots-and-images)."""
    p = []
    if not d["Description"] or len(d["Description"]) > 10000: p.append("description: 1 to 10000 characters")
    if re.search(r"https?://|www\.", d["Description"]): p.append("description: no URLs")
    if len(d["ShortDescription"]) > 1000: p.append("short description over 1000")
    if len(d["ReleaseNotes"]) > 1500: p.append("what's new over 1500")
    if len(d["features"]) > 20 or any(len(f) > 200 for f in d["features"]): p.append("features: 20 of 200 at most")
    if len(d["terms"]) > 7 or any(len(t) > 30 for t in d["terms"]) or sum(len(t.split()) for t in d["terms"]) > 21:
        p.append("search terms: 7 of 30 characters, 21 words in all")
    if len(d["captions"]) != len(SHOTS) or any(len(c) > 200 for c in d["captions"]): p.append("captions")
    return [f"{lang}: {x}" for x in p]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--out", default="waaiya-listings")
    ap.add_argument("--whats-new", action="store_true")
    a = ap.parse_args()
    with open(a.csv, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.reader(f))
    head = rows[0]
    h3 = [h.strip().lower() for h in head[:3]] + ["", "", ""]
    if h3[0] != "field" or h3[1] != "id" or not h3[2].startswith("type"):
        sys.exit(f"not a Partner Center export (first columns {head[:3]}, expected Field, ID, Type)")
    data = {lang: listing(lang) for lang in LANGS}
    problems = [p for lang, d in data.items() for p in check(lang, d)]
    if problems:
        sys.exit("limits:\n  " + "\n  ".join(problems))

    out = os.path.abspath(a.out)
    name = os.path.basename(out)
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(out)
    shutil.copy(os.path.join(ROOT, "store_logo_300.png"), os.path.join(out, "logo300.png"))
    for lang in LANGS:
        shutil.copytree(os.path.join(ROOT, "screenshots", lang), os.path.join(out, "screenshots", lang))

    cols = {h.strip().lower(): i for i, h in enumerate(head)}
    for k in [k for k in cols if cols[k] < 3]:
        del cols[k]
    default = cols.get("default")
    for lang, code in LANGS.items():  # a column per language, added when the export has none
        if code not in cols:
            match = [c for c in cols if c.split("-")[0] == code.split("-")[0] and c not in LANGS.values()]
            if match:
                cols[code] = cols.pop(match[0])
            else:
                head.append(code)
                cols[code] = len(head) - 1
    for r in rows[1:]:
        r.extend([""] * (len(head) - len(r)))

    filled, skipped = set(), set()

    def value(field, lang):
        d = data[lang]
        m = re.fullmatch(r"([A-Za-z]+?)(\d+)", field)
        base, n = (m.group(1), int(m.group(2))) if m else (field, 0)
        if field in ("Description", "ShortDescription"):
            return d[field]
        if field == "ReleaseNotes":
            return d["ReleaseNotes"] if a.whats_new else None
        if base == "Feature":
            return d["features"][n - 1] if n <= len(d["features"]) else ""
        if base in ("SearchTerm", "Keyword", "SearchTerms"):
            return d["terms"][n - 1] if n <= len(d["terms"]) else ""
        if base == "DesktopScreenshot":
            return f"{name}/screenshots/{lang}/{SHOTS[n - 1]}" if n <= len(SHOTS) else None
        if base == "DesktopScreenshotCaption":
            return d["captions"][n - 1] if n <= len(SHOTS) else None
        return None

    for r in rows[1:]:
        field = r[0].strip()
        same = {"Title": "Waaiya", "DevStudio": "Oks",
                "CopyrightTrademarkInformation": "© 2026 Oks. Free software under the GNU AGPL-3.0."}
        if default is not None and field in same:
            r[default] = same[field]
            filled.add(field)
            continue
        if default is not None and field.lower().startswith("storelogo300"):
            r[default] = f"{name}/logo300.png"
            filled.add(field)
            continue
        got = False
        for lang, code in LANGS.items():
            v = value(field, lang)
            if v is not None:
                r[cols[code]] = v
                got = True
        (filled if got else skipped).add(field)

    with open(os.path.join(out, "listings.csv"), "w", encoding="utf-8", newline="") as f:
        csv.writer(f).writerows(rows)
    print(f"{out}\\listings.csv: {len(LANGS)} languages; filled {len(filled)} fields")
    print("left as exported: " + ", ".join(sorted(skipped)))
    print("Partner Center: Store listings > Import listings > Import folder > " + out)


if __name__ == "__main__":
    main()
