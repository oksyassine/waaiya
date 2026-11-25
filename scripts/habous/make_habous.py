#!/usr/bin/env python3
"""Morocco's prayer times as the Ministry of Habous publishes them, for Waaiya's city list.

The Ministry of Habous and Islamic Affairs publishes the official times of 190 cities, month by month, on
https://www.habous.gov.ma/ (data/horaires-YYYY-MM.js: {annee, mois, fuseau, cols, villes: [{c, n, h}]}, Arabic names
only, no coordinates). Waaiya computes times offline, so this script finds, for every city, the position and the
horizon that reproduce that city's published table with Waaiya's own formula (WorshipTimes.kt, method "morocco"):

- Fajr at 19.1° and Isha at 17° below the horizon, Dhuhr 5 minutes after noon, Asr standard: the same for every city
  (checked on the 47 cities whose real coordinates are known: Fajr 19.0° gives times 0.45 min late on average,
  19.1° 0.03 min; Isha 17° 0.04 min; Dhuhr +5.03; Asr +0.10).
- Sunrise and Maghrib when the sun is `rise` and `set` degrees below the horizon: the ministry corrects them for each
  city's altitude (about 1.36° and 1.58° at sea level, 2.3° and 2.4° at Azrou, 1,277 m), so they are fitted per city.
- The city's latitude and longitude: fitted too (within 8 km of the real towns, median 3 km).

Usage:
    python3 -I scripts/habous/make_habous.py HABOUS_DIR [--reuse]
HABOUS_DIR holds the ministry's month files (horaires-2026-10.js ...). Writes:
- scripts/habous/habous_fit.tsv: the fitted values and how well each city matches (exact share, worst minutes);
  --reuse reads it instead of fitting again (fitting takes a few minutes on 6 cores);
- android/app/src/main/assets/cities.tsv: the Moroccan rows replaced by the ministry's 190 cities (names from
  names.tsv, the Arabic as the ministry writes it), with the columns habous, rise and set;
- android/app/src/test/resources/habous_times.tsv: every third day of every city, as published, for
  WorshipHabousTest.
"""
import datetime
import json
import math
import sys
from multiprocessing import Pool
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CITIES = REPO / "android/app/src/main/assets/cities.tsv"
FIXTURE = REPO / "android/app/src/test/resources/habous_times.tsv"
FIT = HERE / "habous_fit.tsv"

FAJR, ISHA, DHUHR_MINUTES = 19.1, 17.0, 5
RISE_SET = 0.833


# ---------------------------------------------------------------- WorshipTimes.kt, in Python (same steps)
def _fix(a, b):
    return a - b * math.floor(a / b)


class Solar:
    def __init__(self, date, lat, lon):
        self.jd0 = (date - datetime.date(1970, 1, 1)).days + 2440587.5
        self.phi = math.radians(lat)
        self.lon = lon

    def position(self, h):
        d = self.jd0 + (12.0 if math.isnan(h) else h) / 24.0 - 2451545.0
        g = math.radians(_fix(357.529 + 0.98560028 * d, 360.0))
        q = _fix(280.459 + 0.98564736 * d, 360.0)
        l = math.radians(_fix(q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g), 360.0))
        e = math.radians(23.439 - 0.00000036 * d)
        ra = _fix(math.degrees(math.atan2(math.cos(e) * math.sin(l), math.cos(l))) / 15.0, 24.0)
        eqt = q / 15.0 - ra
        eqt -= 24.0 * math.floor((eqt + 12.0) / 24.0)
        return math.asin(math.sin(e) * math.sin(l)), eqt

    def noon(self, h):
        return 12.0 - self.position(h)[1] - self.lon / 15.0

    def hour_angle(self, h, angle):
        decl = self.position(h)[0]
        c = (-math.sin(math.radians(angle)) - math.sin(self.phi) * math.sin(decl)) / (math.cos(self.phi) * math.cos(decl))
        return float("nan") if c < -1 or c > 1 else math.degrees(math.acos(c)) / 15.0

    def asr_hour_angle(self, h, factor):
        decl = self.position(h)[0]
        alt = math.atan(1.0 / (factor + math.tan(abs(self.phi - decl))))
        c = (math.sin(alt) - math.sin(self.phi) * math.sin(decl)) / (math.cos(self.phi) * math.cos(decl))
        return float("nan") if c < -1 or c > 1 else math.degrees(math.acos(c)) / 15.0


def compute(date, lat, lon, rise, set_):
    """Minutes after 00:00 UTC, not rounded: fajr, sunrise, dhuhr (with the 5 minutes), asr, maghrib, isha."""
    d = Solar(date, lat, lon)
    g = -lon / 15.0
    fajr, sunrise, dhuhr, asr, maghrib, isha = 5 + g, 6 + g, 12 + g, 13 + g, 18 + g, 18 + g
    for _ in range(3):
        dhuhr = d.noon(dhuhr)
        fajr = d.noon(fajr) - d.hour_angle(fajr, FAJR)
        sunrise = d.noon(sunrise) - d.hour_angle(sunrise, rise)
        asr = d.noon(asr) + d.asr_hour_angle(asr, 1.0)
        maghrib = d.noon(maghrib) + d.hour_angle(maghrib, set_)
        isha = d.noon(isha) + d.hour_angle(isha, ISHA)
    fajr = d.noon(fajr) - d.hour_angle(fajr, FAJR)
    isha = d.noon(isha) + d.hour_angle(isha, ISHA)
    return [fajr * 60, sunrise * 60, dhuhr * 60 + DHUHR_MINUTES, asr * 60, maghrib * 60, isha * 60]


# ---------------------------------------------------------------- the ministry's tables
def read_months(folder):
    """{code: {"ar": name, "rows": [(date, [6 minutes after midnight UTC])]}}; the files say their clock (GMT)."""
    cities = {}
    files = sorted(Path(folder).glob("horaires-*.js"))
    if not files:
        raise SystemExit(f"no horaires-*.js in {folder}")
    for f in files:
        s = f.read_text(encoding="utf-8")
        j = json.loads(s[s.index("push(") + 5:s.rindex(")")])
        if j["fuseau"] != "GMT" or j["cols"] != ["Fajr", "Chorouq", "Dhuhr", "Asr", "Maghrib", "Ishae"]:
            raise SystemExit(f"{f.name}: unexpected clock or columns {j['fuseau']} {j['cols']}")
        for v in j["villes"]:
            c = cities.setdefault(v["c"], {"ar": v["n"], "rows": []})
            for day, h in enumerate(v["h"], 1):
                c["rows"].append((datetime.date(j["annee"], j["mois"], day), [int(t[:2]) * 60 + int(t[3:]) for t in h]))
    return cities, [f.name for f in files]


def cost(p, rows):
    lat, lon, rise, set_ = p
    if not (20 < lat < 37 and -18 < lon < 0 and 0 < rise < 4 and 0 < set_ < 4):
        return 1e9
    return sum((pub[k] - c[k]) ** 2 for date, pub in rows for c in [compute(date, lat, lon, rise, set_)] for k in range(6))


def nelder_mead(f, x0, steps, iters):
    n = len(x0)
    pts = [list(x0)] + [[x0[j] + (steps[i] if j == i else 0) for j in range(n)] for i in range(n)]
    vals = [f(p) for p in pts]
    for _ in range(iters):
        order = sorted(range(n + 1), key=lambda i: vals[i])
        pts, vals = [pts[i] for i in order], [vals[i] for i in order]
        c = [sum(p[j] for p in pts[:-1]) / n for j in range(n)]
        r = [c[j] + (c[j] - pts[-1][j]) for j in range(n)]
        fr = f(r)
        if fr < vals[0]:
            e = [c[j] + 2 * (c[j] - pts[-1][j]) for j in range(n)]
            fe = f(e)
            pts[-1], vals[-1] = (e, fe) if fe < fr else (r, fr)
        elif fr < vals[-2]:
            pts[-1], vals[-1] = r, fr
        else:
            k = [c[j] + 0.5 * (pts[-1][j] - c[j]) for j in range(n)]
            fk = f(k)
            if fk < vals[-1]:
                pts[-1], vals[-1] = k, fk
            else:
                pts = [pts[0]] + [[pts[0][j] + 0.5 * (p[j] - pts[0][j]) for j in range(n)] for p in pts[1:]]
                vals = [vals[0]] + [f(p) for p in pts[1:]]
    i = min(range(n + 1), key=lambda i: vals[i])
    return pts[i]


def fit_city(item):
    code, rows = item
    sample = rows[::6]
    x0 = min(([la / 2, lo / 2, 1.5, 1.7] for la in range(42, 73) for lo in range(-34, 0)), key=lambda p: cost(p, sample))
    p = nelder_mead(lambda q: cost(q, rows[::3]), x0, [0.2, 0.2, 0.2, 0.2], 250)
    p = nelder_mead(lambda q: cost(q, rows), p, [0.02, 0.02, 0.05, 0.05], 250)
    return code, [round(p[0], 4), round(p[1], 4), round(p[2], 3), round(p[3], 3)]


def score(p, rows):
    """(share of times equal to the minute, worst difference in minutes) with the rounded values that are stored."""
    exact, worst, n = 0, 0, 0
    for date, pub in rows:
        c = compute(date, *p)
        for k in range(6):
            diff = abs(pub[k] - round(c[k]))
            exact += diff == 0
            worst = max(worst, diff)
            n += 1
    return exact / n, worst


# ---------------------------------------------------------------- outputs
def read_names():
    names = {}
    for line in (HERE / "names.tsv").read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#") or line.startswith("code\t"):
            continue
        code, cid, latin = line.split("\t")
        names[int(code)] = (cid, latin)
    return names


def zone_and_country(code, lat):
    if code in (24, 40):  # Ceuta, Melilla
        return "ES", "Africa/Ceuta"
    return "MA", ("Africa/El_Aaiun" if lat < 27.6667 else "Africa/Casablanca")


def write_cities(cities, fit, names):
    lines = CITIES.read_text(encoding="utf-8").splitlines()
    comments = [l for l in lines if l.startswith("#")]
    rows = [l for l in lines if l and not l.startswith("#")]
    header = rows[0].split("\t")
    base = header[:header.index("alt") + 1] if "alt" in header else header[:]
    base = [c for c in base if c not in ("habous", "rise", "set")]
    cols = base + ["habous", "rise", "set"]
    old = {}
    kept = []
    for l in rows[1:]:
        f = dict(zip(header, l.split("\t")))
        if f["cc"] == "MA" or f.get("habous"):
            old[f["id"]] = f
        else:
            f["_line"] = l  # other cities: their line as it is (no empty habous, rise, set columns added)
            kept.append(f)
    taken = {f["id"] for f in kept}
    added = []
    for code in sorted(cities):
        cid, latin = names[code]
        if cid in taken:
            raise SystemExit(f"id {cid} is already used by another city")
        lat, lon, rise, set_ = fit[code][:4]
        cc, tz = zone_and_country(code, lat)
        f = {c: "" for c in cols}
        prev = old.get(cid)
        if prev:  # the seven cities Waaiya had: keep their names in the other languages
            f.update({k: v for k, v in prev.items() if k in cols})
        f.update(id=cid, cc=cc, lat=f"{lat:.4f}", lon=f"{lon:.4f}", tz=tz, ar=cities[code]["ar"], fr=latin,
                 habous=str(code), rise=f"{rise:.3f}", set=f"{set_:.3f}")
        if not prev:
            f["en"] = latin
        added.append(f)
    missing = set(old) - {f["id"] for f in added}
    if missing:
        raise SystemExit(f"Moroccan cities that would disappear (their ids are stored in settings): {sorted(missing)}")
    note = ("# Morocco (and Ceuta, Melilla): the 190 cities of the Ministry of Habous's prayer times (habous.gov.ma), "
            "Arabic names as the ministry writes them, Latin names in scripts/habous/names.tsv, positions and "
            "horizons (rise, set: degrees below the horizon for sunrise and Maghrib) fitted to the ministry's "
            "published tables by scripts/habous/make_habous.py; habous = the ministry's city code.")
    comments = [c for c in comments if not c.startswith("# Morocco (and Ceuta")] + [note]
    allrows = sorted(kept + added, key=lambda f: (f["cc"], f["id"]))
    out = comments + ["\t".join(cols)] + [f.get("_line") or "\t".join(f.get(c, "") for c in cols) for f in allrows]
    CITIES.write_text("\n".join(out) + "\n", encoding="utf-8")
    return len(added)


def write_fixture(cities, sources):
    out = [f"# The Ministry of Habous's published prayer times (habous.gov.ma, {', '.join(sources)}, fetched 2026-11-22),",
           "# every third day, for WorshipHabousTest. Clock: GMT (Morocco's legal time since 2026-09-20).",
           "code\tdate\tfajr\tsunrise\tdhuhr\tasr\tmaghrib\tisha"]
    for code in sorted(cities):
        for i, (date, pub) in enumerate(cities[code]["rows"]):
            if i % 3 == 0:
                out.append("\t".join([str(code), date.isoformat()] + [f"{m // 60:02d}:{m % 60:02d}" for m in pub]))
    FIXTURE.write_text("\n".join(out) + "\n", encoding="utf-8")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        raise SystemExit(__doc__)
    cities, sources = read_months(args[0])
    names = read_names()
    unnamed = set(cities) - set(names)
    if unnamed:
        raise SystemExit(f"no Latin name in names.tsv for codes {sorted(unnamed)}")
    if "--reuse" in sys.argv:
        fit = {}
        for line in FIT.read_text(encoding="utf-8").splitlines()[1:]:
            f = line.split("\t")
            fit[int(f[0])] = [float(x) for x in f[2:6]]
    else:
        with Pool() as pool:
            fit = dict(pool.map(fit_city, [(c, cities[c]["rows"]) for c in sorted(cities)]))
    lines = ["code\tar\tlat\tlon\trise\tset\texact\tworst_minutes"]
    worst_all = 0
    for code in sorted(cities):
        exact, worst = score(fit[code], cities[code]["rows"])
        worst_all = max(worst_all, worst)
        lines.append(f"{code}\t{cities[code]['ar']}\t" + "\t".join(f"{x}" for x in fit[code]) + f"\t{exact:.3f}\t{worst}")
    FIT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    if worst_all > 1:
        raise SystemExit(f"a city is {worst_all} minutes off: see {FIT}")
    n = write_cities(cities, fit, names)
    write_fixture(cities, sources)
    print(f"{n} cities, worst difference {worst_all} min; wrote {CITIES.relative_to(REPO)}, {FIXTURE.relative_to(REPO)}")


if __name__ == "__main__":
    main()
