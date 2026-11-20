#!/usr/bin/env python3
"""Build cities.tsv (offline prayer-time city list) from Natural Earth populated places.

Usage: python3 -I scripts/make_cities.py NE_GEOJSON TZDATA2019_DIR OUT_TSV [--review]

Selection = every Admin-0 capital in Natural Earth (ADM0CAP==1 or FEATURECLA
'Admin-0 capital') + a few 'capital alt' / region capitals + hand-picked large
cities of Muslim-majority countries + cities with large Muslim communities.
Coordinates and non-Arabic names come from Natural Earth; time zones are
assigned here (NE's TIMEZONE field is unreliable) and checked against a 2019
tzdata release so that they also exist on Android 10 devices.
"""
import json, re, sys, unicodedata, zoneinfo, datetime, math, collections

NE_PATH, TZ2019, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
REVIEW = '--review' in sys.argv

HEADER = ('# Waaiya city list. Source: Natural Earth 1:10m Cultural Vectors, Populated Places '
          '(ne_10m_populated_places.geojson, v5.1.2, natural-earth-vector commit 789c990, '
          'file sha256 9b8e3de09048ef00dfc70357dbb9fa324493f214b5e0ae4daf1aa79a8d10116b), '
          'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_populated_places.geojson ; '
          'licence: public domain (Natural Earth); fetched 2026-11-20. Rows selected and lightly edited by hand '
          '(Arabic names of Arab-world and holy cities, some English names, country codes for -99 places, '
          'time zones assigned per city and checked against IANA tzdata 2019c). '
          'Columns: id cc lat lon tz en ar fr tr id_name fa ur bn')
COLS = ['id', 'cc', 'lat', 'lon', 'tz', 'en', 'ar', 'fr', 'tr', 'id_name', 'fa', 'ur', 'bn']
LANG = {'fr': 'NAME_FR', 'tr': 'NAME_TR', 'id_name': 'NAME_ID', 'fa': 'NAME_FA', 'ur': 'NAME_UR', 'bn': 'NAME_BN'}

P = [f['properties'] for f in json.load(open(NE_PATH, encoding='utf-8'))['features']]
BYID = {p['NE_ID']: p for p in P}

# ---------------------------------------------------------------- selection
# Natural Earth -99 country codes, assigned by hand.
CC_FIX = {'Somaliland': 'SO', 'Kosovo': 'XK', 'Northern Cyprus': 'CY'}

# capital alt / region capitals kept (cc, NE NAME)
EXTRA_CAPS = [('MY', 'Putrajaya'), ('NL', 'The Hague'), ('TZ', 'Dodoma'), ('BJ', 'Porto-Novo'),
              ('NG', 'Lagos'), ('IL', 'Tel Aviv'),
              ('MA', 'Laayoune'), ('PS', 'Ramallah'), ('PS', 'Gaza City'), ('HK', 'Hong Kong')]

# hand-picked cities: cc -> NE NAME (or NAME_EN) list
CITIES = {
    'SA': ['Makkah', 'Medina', 'Jeddah', 'Dammam', 'At Taif', 'Tabuk', 'Abha', 'Hofuf', 'Buraydah'],
    'ID': ['Surabaya', 'Bandung', 'Medan', 'Semarang', 'Makassar', 'Palembang', 'Yogyakarta', 'Banda Aceh'],
    'PK': ['Karachi', 'Lahore', 'Faisalabad', 'Rawalpindi', 'Multan', 'Hyderabad', 'Peshawar', 'Quetta'],
    'BD': ['Chattogram', 'Khulna', 'Sylhet'],
    'EG': ['Alexandria', 'Port Said', 'Luxor', 'El Mansura', 'Aswan'],
    'NG': ['Kano', 'Ibadan', 'Kaduna', 'Maiduguri', 'Sokoto'],
    'TR': ['Istanbul', 'İzmir', 'Bursa', 'Adana', 'Gaziantep', 'Konya', 'Diyarbakır'],
    'IR': ['Mashhad', 'Isfahan', 'Tabriz', 'Shiraz', 'Ahvaz', 'Qom', 'Zahedan'],
    'DZ': ['Oran', 'Constantine', 'Sétif'],
    'MA': ['Casablanca', 'Fez', 'Marrakesh', 'Tangier', 'Oujda'],
    'IQ': ['Basra', 'Mosul', 'Erbil', 'Najaf', 'Karbala'],
    'MY': ['George Town', 'Johor Bahru', 'Kota Baharu', 'Kuching', 'Kota Kinabalu'],
    'SD': ['Port Sudan'],
    'AF': ['Kandahar', 'Herat', 'Mazar-i-Sharif'],
    'UZ': ['Samarkand', 'Bukhara'],
    'YE': ['Aden', "Ta'izz"],
    'SY': ['Aleppo', 'Homs'],
    'TN': ['Sfax', 'Sousse'],
    'LY': ['Benghazi', 'Misratah'],
    'KZ': ['Almaty', 'Shymkent'],
    'JO': ['Zarqa', 'Irbid'],
    'AE': ['Dubai', 'Sharjah'],
    'OM': ['Salalah'],
    'LB': ['Ṭarābulus'],
    'TJ': ['Khujand'],
    'KG': ['Osh'],
    'PS': ['Al Khalil', 'Nablus'],
    'ET': ['Harar'],
    # large Muslim communities
    'GB': ['Birmingham', 'Manchester', 'Bradford'],
    'FR': ['Marseille', 'Lyon'],
    'BE': ['Antwerpen'],
    'NL': ['Rotterdam'],
    'DE': ['Hamburg', 'Cologne', 'Frankfurt', 'Munich'],
    'SE': ['Malmö'],
    'ES': ['Barcelona'],
    'IT': ['Milan'],
    'CH': ['Geneva', 'Zürich'],
    'US': ['New York', 'Chicago', 'Los Angeles', 'Houston', 'Dallas', 'Detroit', 'Philadelphia', 'Atlanta', 'Minneapolis'],
    'CA': ['Toronto', 'Montréal', 'Calgary', 'Edmonton', 'Vancouver'],
    # Delhi (NE 'Delhi', 8.5 km from New Delhi) is left out: New Delhi is the same city for prayer times.
    'IN': ['Mumbai', 'Hyderabad', 'Lucknow', 'Kolkata', 'Bengaluru', 'Chennai', 'Srinagar', 'Ahmedabad'],
    'CN': ['Ürümqi', 'Kashgar', 'Yinchuan', 'Xian'],
    'RU': ['Kazan', 'Ufa', 'Makhachkala', 'Grozny'],
    'PH': ['Cotabato', 'Zamboanga'],
    'TH': ['Pattani'],
    'KE': ['Mombasa'],
    'TZ': ['Zanzibar'],
    'ZA': ['Durban'],
    'AU': ['Sydney', 'Melbourne'],
    'NZ': ['Auckland'],
}

# ---------------------------------------------------------------- hand edits
# Keyed by NE NAME (+cc where ambiguous); values override output fields.
EDIT = {
    # names / ids
    ('SA', 'Makkah'): dict(id='makkah', en='Makkah', ar='مكة المكرمة'),
    ('SA', 'Medina'): dict(id='madinah', ar='المدينة المنورة'),   # en stays NE 'Medina'; id_name has 'Madinah'
    ('SA', 'At Taif'): dict(en='Taif', ar='الطائف'),
    ('SA', 'Buraydah'): dict(ar='بريدة'),
    ('IL', 'Jerusalem'): dict(id='jerusalem', cc='PS', en='Jerusalem', ar='القدس', tz='Asia/Jerusalem'),
    ('PS', 'Gaza City'): dict(id='gaza', en='Gaza', ar='غزة'),
    ('PS', 'Al Khalil'): dict(ar='الخليل'),
    ('PS', 'Ramallah'): dict(ar='رام الله'),
    ('PS', 'Nablus'): dict(ar='نابلس'),
    ('EG', 'El Mansura'): dict(en='Mansoura', ar='المنصورة'),
    ('EG', 'Cairo'): dict(ar='القاهرة'),
    ('MA', 'Oujda'): dict(en='Oujda', ar='وجدة'),
    ('MA', 'Fez'): dict(ar='فاس'),
    ('MA', 'Laayoune'): dict(ar='العيون'),
    ('KZ', 'Nur-Sultan'): dict(id='astana', en='Astana', ar='أستانا'),
    ('US', 'Washington,  D.C.'): dict(id='washington', en='Washington'),
    ('US', 'New York'): dict(en='New York'),
    ('TN', 'Tunis'): dict(ar='تونس'),
    ('KW', 'Kuwait City'): dict(ar='مدينة الكويت'),
    ('DZ', 'Algiers'): dict(ar='الجزائر'),
    ('DZ', 'Constantine'): dict(fa=''),                # NE fa = Constantinople
    ('MY', 'George Town'): dict(id='george_town_my'),
    ('GY', 'Georgetown'): dict(id='georgetown_gy'),
    ('SO', 'Hargeisa'): dict(ar='هرجيسا'),
    ('LB', 'Ṭarābulus'): dict(en='Tripoli', ar='طرابلس'),
    ('LY', 'Tripoli'): dict(ar='طرابلس'),
    ('LY', 'Misratah'): dict(ar='مصراتة'),
    ('SY', 'Aleppo'): dict(ar='حلب'),
    ('YE', "Ta'izz"): dict(en='Taiz', ar='تعز'),
    # NE label is a sub-district / 'City' form; plain names people search
    ('CN', 'Kashgar'): dict(id='kashgar', en='Kashgar'),
    ('ID', 'Yogyakarta'): dict(id='yogyakarta', en='Yogyakarta'),
    ('PH', 'Cotabato'): dict(id='cotabato', en='Cotabato', ar='كوتاباتو'),
    ('PH', 'Zamboanga'): dict(id='zamboanga', en='Zamboanga', ar='زامبوانغا'),
    ('TZ', 'Zanzibar'): dict(id='zanzibar', en='Zanzibar', ar='زنجبار', fa='زنگبار'),
    ('ET', 'Harar'): dict(id='harar', en='Harar'),
    ('TR', 'Diyarbakır'): dict(id='diyarbakir'),
    ('BE', 'Brussels'): dict(ar='بروكسل'),
    ('LU', 'Luxembourg'): dict(ar='لوكسمبورغ'),
    # wrong NE values (other-language columns describing a different feature)
    ('US', 'Detroit'): dict(fa='دیترویت'),            # NE fa = 'Michigan'
    ('NG', 'Sokoto'): dict(ar='سوكوتو'),              # NE ar = 'Sokoto State'
    ('ID', 'Palembang'): dict(bn=''),                 # NE bn names another place
    ('KN', 'Basseterre'): dict(bn=''),                # NE bn = country name
    ('BD', 'Chattogram'): dict(fa='چیتاگونگ'),         # NE fa = 'Chittagong county'
}
# Astana: renamed back from Nur-Sultan in 2022, after NE 5.1.2; all language columns updated by hand.
EDIT[('KZ', 'Nur-Sultan')].update(fr='Astana', tr='Astana', id_name='Astana', fa='آستانه', ur='آستانہ', bn='আস্তানা')

# Time zones for countries with several zones (2019 zone.tab names).
TZ_MULTI = {
    'US': {'New York': 'America/New_York', 'Washington,  D.C.': 'America/New_York', 'Philadelphia': 'America/New_York',
           'Atlanta': 'America/New_York', 'Detroit': 'America/Detroit', 'Chicago': 'America/Chicago', 'Houston': 'America/Chicago',
           'Dallas': 'America/Chicago', 'Minneapolis': 'America/Chicago', 'Los Angeles': 'America/Los_Angeles'},
    'CA': {'Ottawa': 'America/Toronto', 'Toronto': 'America/Toronto', 'Montréal': 'America/Toronto', 'Calgary': 'America/Edmonton',
           'Edmonton': 'America/Edmonton', 'Vancouver': 'America/Vancouver'},
    'RU': {'Moscow': 'Europe/Moscow', 'St.  Petersburg': 'Europe/Moscow', 'Kazan': 'Europe/Moscow', 'Makhachkala': 'Europe/Moscow',
           'Grozny': 'Europe/Moscow', 'Ufa': 'Asia/Yekaterinburg'},
    'ID': {'Jakarta': 'Asia/Jakarta', 'Surabaya': 'Asia/Jakarta', 'Bandung': 'Asia/Jakarta', 'Medan': 'Asia/Jakarta', 'Semarang': 'Asia/Jakarta',
           'Palembang': 'Asia/Jakarta', 'Yogyakarta': 'Asia/Jakarta', 'Banda Aceh': 'Asia/Jakarta', 'Pekanbaru': 'Asia/Jakarta',
           'Padang': 'Asia/Jakarta', 'Malang': 'Asia/Jakarta', 'Pontianak': 'Asia/Pontianak', 'Makassar': 'Asia/Makassar',
           'Bandjarmasin': 'Asia/Makassar', 'Balikpapan': 'Asia/Makassar'},
    'KZ': {'Nur-Sultan': 'Asia/Almaty', 'Almaty': 'Asia/Almaty', 'Shymkent': 'Asia/Almaty'},
    'CN': {'Beijing': 'Asia/Shanghai', 'Ürümqi': 'Asia/Shanghai', 'Kashgar': 'Asia/Shanghai', 'Yinchuan': 'Asia/Shanghai',
           'Xian': 'Asia/Shanghai', 'Lanzhou': 'Asia/Shanghai'},
    'MY': {'Kuala Lumpur': 'Asia/Kuala_Lumpur', 'Putrajaya': 'Asia/Kuala_Lumpur', 'George Town': 'Asia/Kuala_Lumpur',
           'Johor Bahru': 'Asia/Kuala_Lumpur', 'Ipoh': 'Asia/Kuala_Lumpur', 'Kota Baharu': 'Asia/Kuala_Lumpur',
           'Shah Alam': 'Asia/Kuala_Lumpur', 'Kuching': 'Asia/Kuching', 'Kota Kinabalu': 'Asia/Kuching'},
    'UZ': {'Tashkent': 'Asia/Tashkent', 'Namangan': 'Asia/Tashkent', 'Andijon': 'Asia/Tashkent', 'Samarkand': 'Asia/Samarkand',
           'Bukhara': 'Asia/Samarkand'},
    'PS': {'Gaza City': 'Asia/Gaza', 'Ramallah': 'Asia/Hebron', 'Al Khalil': 'Asia/Hebron', 'Nablus': 'Asia/Hebron'},
    'AU': {'Canberra': 'Australia/Sydney', 'Sydney': 'Australia/Sydney', 'Melbourne': 'Australia/Melbourne'},
    'BR': {'Brasília': 'America/Sao_Paulo'}, 'MX': {'Mexico City': 'America/Mexico_City'},
    'AR': {'Buenos Aires': 'America/Argentina/Buenos_Aires'}, 'CL': {'Santiago': 'America/Santiago'},
    'EC': {'Quito': 'America/Guayaquil'}, 'CD': {'Kinshasa': 'Africa/Kinshasa'}, 'MN': {'Ulaanbaatar': 'Asia/Ulaanbaatar'},
    'ES': {'Madrid': 'Europe/Madrid', 'Barcelona': 'Europe/Madrid'}, 'PT': {'Lisbon': 'Europe/Lisbon'},
    'DE': {'Berlin': 'Europe/Berlin', 'Hamburg': 'Europe/Berlin', 'Cologne': 'Europe/Berlin', 'Frankfurt': 'Europe/Berlin',
           'Munich': 'Europe/Berlin'},
    'UA': {'Kyiv': 'Europe/Kiev'}, 'CY': {'Nicosia': 'Asia/Nicosia'},
    'NZ': {'Wellington': 'Pacific/Auckland', 'Auckland': 'Pacific/Auckland'},
    'KI': {'Tarawa': 'Pacific/Tarawa'}, 'FM': {'Palikir': 'Pacific/Pohnpei'}, 'PG': {'Port Moresby': 'Pacific/Port_Moresby'},
    'MH': {'Majuro': 'Pacific/Majuro'},
}
TZ_SINGLE_EXTRA = {'XK': 'Europe/Belgrade'}   # Kosovo has no zone.tab row
TZ_CITY = {('MA', 'Laayoune'): 'Africa/El_Aaiun'}  # Western Sahara zone

# ---------------------------------------------------------------- tzdata 2019
zone_tab = collections.defaultdict(list)
for line in open(f'{TZ2019}/zone.tab', encoding='utf-8'):
    if line.startswith('#') or not line.strip():
        continue
    f = line.rstrip('\n').split('\t')
    zone_tab[f[0]].append(f[2])
old_names = {z for zs in zone_tab.values() for z in zs}
for fn in ('backward', 'africa', 'asia', 'europe', 'northamerica', 'southamerica', 'australasia', 'etcetera', 'antarctica'):
    for line in open(f'{TZ2019}/{fn}', encoding='utf-8'):
        f = line.split()
        if f and f[0] == 'Zone':
            old_names.add(f[1])
        elif f and f[0] == 'Link':
            old_names.add(f[2])


def cc_of(p):
    cc = p['ISO_A2']
    if cc == '-99':
        cc = CC_FIX[p['ADM0NAME']]
    return cc


def find(cc, name):
    hits = [p for p in P if cc_of(p) == cc and name in (p['NAME'], p['NAME_EN'], p['NAMEASCII'])]
    if len(hits) != 1:
        raise SystemExit(f'lookup {cc}/{name}: {len(hits)} hits ' + str([(h["NAME"], h["NE_ID"]) for h in hits]))
    return hits[0]


def fold(s):
    # plain ASCII spelling as people type it: Ürümqi -> Urumqi, Diyarbakır -> Diyarbakir
    s = s.replace('ı', 'i').replace('ʻ', "'")
    return unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()


def slug(s):
    s = fold(s).lower().replace("'", '')
    return re.sub(r'_+', '_', re.sub(r'[^a-z0-9]+', '_', s)).strip('_')


sel, is_cap = [], {}
for p in P:
    if p['ADM0CAP'] == 1 or p['FEATURECLA'] == 'Admin-0 capital':
        sel.append(p)
        is_cap[p['NE_ID']] = True
for cc, name in EXTRA_CAPS:
    sel.append(find(cc, name))
for cc, names in CITIES.items():
    for n in names:
        sel.append(find(cc, n))
seen, uniq = set(), []
for p in sel:
    if p['NE_ID'] not in seen:
        seen.add(p['NE_ID'])
        uniq.append(p)
sel = uniq

rows = []
used_edits = set()
folded, edit_log = [], []
for p in sel:
    cc = cc_of(p)
    key = next(((cc, n) for n in (p['NAME'], p['NAME_EN'], p['NAMEASCII']) if (cc, n) in EDIT), (cc, p['NAME']))
    e = EDIT.get(key, {})
    used_edits.add(key)
    en = fold(e.get('en') or p['NAME_EN'] or p['NAME'])
    if en != (p['NAME_EN'] or p['NAME']) and 'en' not in e:
        folded.append(f'{p["NAME_EN"]} -> {en}')
    for fld, val in e.items():
        src = {'en': p['NAME_EN'], 'ar': p['NAME_AR'], 'cc': cc, **{c: p[LANG[c]] for c in LANG}}.get(fld)
        if fld != 'id' and (fld == 'tz' or val != src):
            edit_log.append(f'{key[0]}/{key[1]} {fld}: {src!r} -> {val!r}')
    r = dict(cc=e.get('cc', cc), lat=f"{p['LATITUDE']:.4f}", lon=f"{p['LONGITUDE']:.4f}", en=en,
             ar=e.get('ar', p['NAME_AR'] or ''), _ne=p, _key=key, _id=e.get('id'))
    for col, fld in LANG.items():
        r[col] = e[col] if col in e else (p[fld] or '').strip()
    # tz
    if 'tz' in e:
        tz = e['tz']
    elif key in TZ_CITY:
        tz = TZ_CITY[key]
    elif cc in TZ_MULTI:
        tz = next((TZ_MULTI[cc][n] for n in (p['NAME'], p['NAME_EN'], p['NAMEASCII']) if n in TZ_MULTI[cc]), None)
        if not tz:
            raise SystemExit(f'no tz for multi-zone city {key}')
    elif cc in TZ_SINGLE_EXTRA:
        tz = TZ_SINGLE_EXTRA[cc]
    else:
        zs = zone_tab.get(cc, [])
        if len(zs) != 1:
            raise SystemExit(f'country {cc} ({p["NAME"]}) has zones {zs}')
        tz = zs[0]
    r['tz'] = tz
    rows.append(r)

# ids: explicit, else slug(en); colliding slugs get _cc on every member
base = collections.Counter(r['_id'] or slug(r['en']) for r in rows)
for r in rows:
    b = r['_id'] or slug(r['en'])
    r['id'] = b if base[b] == 1 or r['_id'] else f"{b}_{r['cc'].lower()}"

# ---------------------------------------------------------------- checks
errors = [f'unused edit {k}' for k in EDIT if k not in used_edits]
ids = [r['id'] for r in rows]
for i, c in collections.Counter(ids).items():
    if c > 1:
        errors.append(f'duplicate id {i}')
jan, jul = datetime.datetime(2026, 1, 15, 12), datetime.datetime(2026, 7, 15, 12)
outliers = []
linked = []
HOST_LINKS = {}
for line in open('/usr/share/zoneinfo/tzdata.zi', encoding='utf-8'):
    f = line.split()
    if f and f[0] == 'L':
        HOST_LINKS[f[2]] = f[1]
for r in rows:
    if not re.fullmatch(r'[a-z0-9_]+', r['id']):
        errors.append(f'bad id {r["id"]}')
    if not re.fullmatch(r'[A-Z]{2}', r['cc']):
        errors.append(f'bad cc {r}')
    lat, lon = float(r['lat']), float(r['lon'])
    if not (-90 <= lat <= 90 and -180 <= lon <= 180):
        errors.append(f'bad coords {r["id"]}')
    if r['tz'] not in old_names:
        errors.append(f'tz not in tzdata 2019c: {r["id"]} {r["tz"]}')
    try:
        z = zoneinfo.ZoneInfo(r['tz'])
    except Exception as ex:
        # Ubuntu ships backward links (e.g. Europe/Kiev) only in tzdata-legacy; accept a name that the
        # host's own tzdata.zi declares as a link, and validate its target instead.
        tgt = HOST_LINKS.get(r['tz'])
        if not tgt:
            errors.append(f'tz invalid {r["id"]} {r["tz"]} {ex}')
            continue
        z = zoneinfo.ZoneInfo(tgt)
        linked.append(f'{r["tz"]} -> {tgt} (host tzdata.zi link)')
    std = min(z.utcoffset(jan), z.utcoffset(jul)).total_seconds() / 3600  # standard offset
    d = (std - lon / 15 + 12) % 24 - 12
    if abs(d) >= 3 or REVIEW and abs(d) >= 2:
        outliers.append(f'  {r["id"]:<22} {r["tz"]:<28} std UTC{std:+.2f} lon/15={lon/15:+.2f} diff={d:+.2f}')
    if not r['ar']:
        errors.append(f'no Arabic {r["id"]}')
    for c in COLS:
        if '\t' in r[c] or '\n' in r[c]:
            errors.append(f'tab/newline in {r["id"]}.{c}')
    # NE tz cross-check (printed only)
    if REVIEW and r['_ne']['TIMEZONE'] and r['_ne']['TIMEZONE'] != r['tz']:
        print(f'  ne-tz differs {r["id"]}: NE {r["_ne"]["TIMEZONE"]} -> {r["tz"]}')
# capitals: every source ADM0_A3 with a capital present
cap_countries = {p['ADM0_A3'] for p in P if p['ADM0CAP'] == 1 or p['FEATURECLA'] == 'Admin-0 capital'}
present = collections.Counter(r['_ne']['ADM0_A3'] for r in rows if is_cap.get(r['_ne']['NE_ID']))
missing = cap_countries - set(present)
if missing:
    errors.append(f'capital missing for {missing}')
# near duplicates (same cc within 20 km)
near = []
for i, a in enumerate(rows):
    for b in rows[i + 1:]:
        if a['cc'] == b['cc']:
            la1, lo1, la2, lo2 = map(math.radians, map(float, (a['lat'], a['lon'], b['lat'], b['lon'])))
            dist = 6371 * math.acos(min(1, math.sin(la1) * math.sin(la2) + math.cos(la1) * math.cos(la2) * math.cos(lo1 - lo2)))
            if dist < 20:
                near.append(f'  {a["id"]} ~ {b["id"]} {dist:.1f} km')

rows.sort(key=lambda r: (r['cc'], r['id']))
with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
    f.write(HEADER + '\n')
    for r in rows:
        f.write('\t'.join(r[c] for c in COLS) + '\n')

print(f'rows: {len(rows)}  countries: {len({r["cc"] for r in rows})}  capital countries (NE ADM0_A3): {len(cap_countries)} '
      f'present: {len(present)}; with >1 capital row: ' + ', '.join(f'{k}={v}' for k, v in present.items() if v > 1))
print('ids unique:', len(set(ids)) == len(ids), ' all tz in 2019c + zoneinfo:', not any('tz' in e for e in errors))
print('tz validated through host link:', sorted(set(linked)) or 'none')
print('offset outliers (|std offset - lon/15| >= 3h' + (', review shows >=2h' if REVIEW else '') + '):')
print('\n'.join(outliers) or '  none')
print('same-country pairs < 20 km:')
print('\n'.join(near) or '  none')
print('empty columns per language:', {c: sum(1 for r in rows if not r[c]) for c in COLS[5:]})
print('en folded to ASCII:', '; '.join(folded))
print('hand edits (NE value -> output):\n  ' + '\n  '.join(edit_log))
if REVIEW:
    for r in rows:
        print('|'.join([r['id'], r['cc'], r['tz'], r['en'], r['ar'], r['fr'], r['tr'], r['id_name'], r['fa'], r['ur'], r['bn']]))
if errors:
    print('ERRORS:\n' + '\n'.join(errors))
    sys.exit(1)
