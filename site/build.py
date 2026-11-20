#!/usr/bin/env python3
"""Builds the Waaiya landing page (waaiya.mssid.org): index.html (Arabic) and en/index.html (English) from one
template, plus privacy.html / en/privacy.html from docs/PRIVACY.md.

    python3 site/build.py            # writes site/public/
    site/deploy.sh                   # rsync to the host

Pictures: assets/spec-before.webp and spec-after.webp are spectrograms of a real 10 s mix (testset speech_ar_0, Arabic
Speech Corpus voice CC BY 4.0 + music synthesised by testset/build_testset.py), before and after the real filter
(build/im-process, dfn3_stream_int8): see make_assets.py. Phone pictures: the app on the Android 15 emulator.
"""
import html
import re
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "public"
REPO = "https://github.com/oksyassine/waaiya"
APK = "https://mssid.org/downloads/waaiya.apk"
RELEASES = REPO + "/releases/latest"
STORE = "https://apps.microsoft.com/detail/9NBB296FSRJP"

T = {
    "ar": dict(
        dir="rtl", other="en", other_label="English", other_href="en/",
        title="واعية: يزيل المعازف ويُبقي الصوت",
        desc="تطبيق مجاني مفتوح المصدر يزيل الآلات الموسيقية من صوت كل التطبيقات على هاتفك أو حاسوبك، مباشرةً، ويُبقي الكلام والتلاوة. لا يخرج شيء من جهازك.",
        h1a="يزيل المعازف", h1b="ويُبقي الصوت",
        lead="واعية تطبيق مجاني مفتوح المصدر يزيل الآلات الموسيقية من صوت كل التطبيقات على هاتفك أو حاسوبك، مباشرةً، ويُبقي الكلام والتلاوة. لا يخرج شيء من جهازك.",
        cta="حمّل واعية",
        frag_title="محاضرة بالعربية تحتها موسيقى",
        frag_on="التصفية تعمل", frag_off="التصفية متوقفة",
        frag_on_note="تُزال الآلات، ويبقى الكلام. التأخير نحو 30 ملّي ثانية.",
        frag_off_note="اضغط الزر لترى ما يصل إلى الأذن بعد واعية.",
        frag_axis="10 ثوانٍ · من 60 هرتز إلى 8 كيلوهرتز",
        frag_caption="الصورتان مرسومتان من صوت حقيقي، قبل مرشّح واعية وبعده.",
        frag_power="تشغيل التصفية أو إيقافها",
        show_h="ما تراه في التطبيق",
        shows=[
            ("زر واحد", "on", "اضغط الزر فتُزال الآلات من كل التطبيقات حتى تضغطه مرة أخرى. وإن تعذّر الترشيح بقيت التطبيقات صامتة بدل أن تُسمِع المعازف."),
            ("تغطية الشاشة", "screen", "اختياريًا: تغطية النساء أو الصور غير المحتشمة فوق كل التطبيقات، على الهاتف نفسه، دون أن يُرسَل شيء."),
            ("أوقات الصلاة", "settings2", "أوقات الصلاة محسوبة على الهاتف من مدينتك، بالطريقة التي تختارها. صمت عند كل صلاة، وردّ برسالة على من يتصل أثناءها."),
            ("الانتظار قبل الإيقاف", "settings3", "مدة تختارها مسبقًا قبل أن يسري الإيقاف، ثم تأكيد. ورمز سرّي للوالدين. لحظة الضعف تمرّ والحماية باقية."),
        ],
        how_h="كيف يعمل",
        how=[
            ("أولًا، ثبّت واعية.", "waaiya.apk · أندرويد 10 أو أحدث", "إعداد لمرة واحدة على الهاتف نفسه: أربع خطوات تتعلَّم وحدها، مع صورة لكل خطوة بلغتك."),
            ("ثم اضغط الزر.", "واعية · التصفية تعمل", "تُزال الآلات من كل التطبيقات. الإشعار يبقى ظاهرًا، وفيه زر الإيقاف."),
            ("وشغّل ما شئت.", "يوتيوب، إنستغرام، تيك توك، المتصفح، الألعاب", ""),
        ],
        how_done="محاضرة، خبر، وصفة: يصل الكلام وحده.",
        feat_h="خيارات بيدك",
        notes=[
            ("صامتة إذا توقّف", "إن أوقف أندرويد الترشيح من تلقاء نفسه بقيت التطبيقات صامتة حتى تعيد التشغيل."),
            ("أحادي أو ستيريو", "الأحادي هو الافتراضي: نصف البطارية تقريبًا، ويواكب هواتف أكثر."),
            ("كتم غناء النساء", "للرجال، اختياريًا. نسخة أولى: تلتقط جزءًا من الغناء في الأغاني الحقيقية."),
            ("تطبيقات دون تصفية", "اختر تطبيقات تُسمَع كما هي، أو تطبيقات بلا تغطية."),
            ("ملاحظة «فاتني شيء»", "دوّن الخطأ في لحظته. تبقى الملاحظات على جهازك حتى تشاركها أنت."),
            ("تقرير التشخيص", "السرعة والبطارية والحرارة، لتعرف كيف يعمل على هاتفك."),
        ],
        facts_h="لا يخرج شيء من جهازك",
        facts_body="الترشيح والتغطية يعملان على الجهاز. لا حساب، ولا إحصاءات، ولا إعلانات. وكل إصدار يُختبر بقطع الإنترنت عنه.",
        facts=[("30", "ملّي ثانية تأخير تقريبًا"), ("18", "لغة"), ("3", "أنظمة: أندرويد، ويندوز، لينكس"), ("0", "اتصال بالإنترنت أثناء التصفية"), ("365", "مدينة لأوقات الصلاة"), ("AGPL", "مفتوح المصدر")],
        film_h="واعية في 50 ثانية",
        film_body="فيلم قصير يشرح الفكرة: تفتح محاضرة أو خبرًا، فتأتي الموسيقى معه. واعية تزيلها ويبقى الكلام. بلا موسيقى.",
        film_alt="فيلم تعريفي بواعية",
        faq_h="أسئلة",
        faq=[
            ("هل يُسمَع الغناء؟", "يُزال الغناء مع الآلات حاليًا؛ ويبقى الكلام والتلاوة. وللرجال خيار يكتم غناء النساء أيضًا."),
            ("هل يحتاج إلى الإنترنت؟", "لا. الترشيح والتغطية يعملان دون إنترنت. وحده «افتح رابطًا» يتصل بموقع الرابط الذي تفتحه."),
            ("ما الإعداد لمرة واحدة؟", "يتيح لواعية إسكات الصوت الأصلي للتطبيق الذي ترشّحه. يجري على الهاتف نفسه عبر «تصحيح الأخطاء اللاسلكي» في أربع خطوات. ودونه تعمل واعية لكنها تسأل قبل كل تشغيل."),
            ("هل يعمل على هاتفي؟", "أندرويد 10 أو أحدث. هواتف شاومي وأوبو وريلمي وون بلس ترفض بعض الأذونات، فيتولّى مساعد واعية المهمة دون مفتاح مخفي."),
            ("هل يستهلك البطارية؟", "الصوت الأحادي (الافتراضي) يستهلك نحو نصف ما يستهلكه الستيريو. وتقرير التشخيص يعرض الاستهلاك في الساعة على هاتفك."),
            ("هل يمكن إيقافه في لحظة ضعف؟", "اختر مدة انتظار قبل أي إيقاف، ورمزًا سرّيًا إن شئت. لكن لا شيء يمنع حذف التطبيق أو إيقافه قسرًا من إعدادات أندرويد، وواعية تقول ذلك بوضوح."),
            ("وويندوز ولينكس؟", "على ويندوز: نسخة من GitHub الآن، وقريبًا في متجر مايكروسوفت. على لينكس: نسخة سطح المكتب من GitHub."),
            ("من يقف وراءه؟", "مشروع مفتوح المصدر برخصة AGPL، شيفرته كاملة على GitHub. يمكن لأي أحد بناؤه بنفسه ومقارنته بما ننشر."),
        ],
        dl_a="حمّل واعية لـ", dl_btn="تنزيل",
        dl_opts=[("android", "أندرويد"), ("windows", "ويندوز"), ("linux", "لينكس")],
        dl_note="أندرويد 10 أو أحدث. ويندوز 10 (2004) أو أحدث، وقريبًا في متجر مايكروسوفت. لينكس: نسخة سطح المكتب. الشيفرة كاملة على GitHub.",
        foot_what="واعية · ﴿وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ﴾",
        foot_links=[("GitHub", REPO), ("الخصوصية", "privacy.html"), ("English", "en/")],
        foot_right="2026 · مجاني ومفتوح المصدر",
        privacy_title="سياسة الخصوصية",
        shot_alt={"on": "صفحة التصفية في واعية والتصفية تعمل", "screen": "صفحة الشاشة: تغطية النساء والصور غير المحتشمة", "settings2": "أوقات الصلاة في الإعدادات", "settings3": "الانتظار قبل الإيقاف والرمز السري", "settings": "خيارات التصفية"},
    ),
    "en": dict(
        dir="ltr", other="ar", other_label="العربية", other_href="../",
        title="Waaiya: remove the music, keep the voice",
        desc="A free, open-source app that removes musical instruments from everything your phone or computer plays, live, and keeps speech and Quran recitation. Nothing leaves your device.",
        h1a="Remove the music,", h1b="keep the voice",
        lead="Waaiya is a free, open-source app that removes musical instruments from everything your phone or computer plays, live, and keeps speech and Quran recitation. Nothing leaves your device.",
        cta="Get Waaiya",
        frag_title="An Arabic lecture with music under it",
        frag_on="Filtering is on", frag_off="Filtering is off",
        frag_on_note="Instruments removed, speech kept. About 30 ms of delay.",
        frag_off_note="Press the button to see what reaches the ear after Waaiya.",
        frag_axis="10 seconds · 60 Hz to 8 kHz",
        frag_caption="Both pictures are drawn from real sound, before and after Waaiya's filter.",
        frag_power="Turn filtering on or off",
        show_h="What you see in the app",
        shows=[
            ("One button", "on", "Press it and instruments are removed from every app until you press it again. If filtering cannot run, apps stay silent instead of playing music."),
            ("Screen blur", "screen", "Optional: covers women, or immodest images, over every app, on the phone itself, with nothing sent anywhere."),
            ("Prayer times", "settings2", "Prayer times computed on the phone from your city, with the method you choose. Silent at each prayer, and an SMS reply to whoever calls meanwhile."),
            ("Wait before turning off", "settings3", "A waiting time you choose in advance before switching off takes effect, then a confirmation. And a PIN for parents. The weak moment passes; the protection stays."),
        ],
        how_h="How it works",
        how=[
            ("First, install Waaiya.", "waaiya.apk · Android 10 or newer", "A one-time setup on the phone itself: four steps that tick themselves, with a picture of each step in your language."),
            ("Then press the button.", "Waaiya · Filtering is on", "Instruments are removed from every app. The notification stays, with its Stop button."),
            ("And play anything.", "YouTube, Instagram, TikTok, the browser, games", ""),
        ],
        how_done="A lecture, the news, a recipe: only the voice comes through.",
        feat_h="Choices in your hands",
        notes=[
            ("Silent if it stops", "If Android ends filtering by itself, apps stay silent until you start again."),
            ("Mono or stereo", "Mono is the default: about half the battery, and it keeps up on more phones."),
            ("Mute women's singing", "For men, optional. An early model: it catches part of the singing in real songs."),
            ("Apps left alone", "Choose apps heard as they are, or apps the blur leaves uncovered."),
            ("Note a mistake", "Note what was missed, on the spot. Notes stay on your device until you share them."),
            ("Diagnostics report", "Speed, battery and heat, so you know how it runs on your phone."),
        ],
        facts_h="Nothing leaves your device",
        facts_body="Filtering and the blur run on the device. No account, no analytics, no ads. Every build is tested with the internet cut off.",
        facts=[("30", "ms of delay, about"), ("18", "languages"), ("3", "platforms: Android, Windows, Linux"), ("0", "internet connections while filtering"), ("365", "cities for prayer times"), ("AGPL", "open source")],
        film_h="Waaiya in 50 seconds",
        film_body="A short film of the idea: you open a lecture or the news, and music comes with it. Waaiya removes it and the voice stays. No music in it.",
        film_alt="Waaiya introduction film",
        faq_h="Questions",
        faq=[
            ("Is singing heard?", "Singing is removed with the instruments for now; speech and recitation stay. Men also have an option that mutes women's singing."),
            ("Does it need the internet?", "No. Filtering and the blur work offline. Only \"Open a link\" contacts the site of the link you open."),
            ("What is the one-time setup?", "It lets Waaiya silence the original sound of the app it filters. It runs on the phone itself through Wireless debugging, in four steps. Without it Waaiya still works but asks before each start."),
            ("Will it work on my phone?", "Android 10 or newer. Xiaomi, OPPO, realme and OnePlus phones refuse some permissions, so Waaiya's helper takes over, with no hidden switch to find."),
            ("Does it drain the battery?", "Mono sound (the default) uses about half of what stereo does. The diagnostics report shows the use per hour on your phone."),
            ("Can I be stopped from switching it off in a weak moment?", "Choose a waiting time before any switch-off, and a PIN if you like. Nothing can stop uninstalling or a force-stop from Android's settings, and Waaiya says so plainly."),
            ("Windows and Linux?", "Windows: a download from GitHub now, and soon in the Microsoft Store. Linux: the desktop app from GitHub."),
            ("Who is behind it?", "An open-source project under the AGPL, with all its code on GitHub. Anyone can build it and compare it with what we publish."),
        ],
        dl_a="Get Waaiya for", dl_btn="Download",
        dl_opts=[("android", "Android"), ("windows", "Windows"), ("linux", "Linux")],
        dl_note="Android 10 or newer. Windows 10 (2004) or newer, soon in the Microsoft Store. Linux: the desktop app. All the code is on GitHub.",
        foot_what="Waaiya · \"that a heeding ear may heed it\" (69:12)",
        foot_links=[("GitHub", REPO), ("Privacy", "privacy.html"), ("العربية", "../")],
        foot_right="2026 · Free and open source",
        privacy_title="Privacy policy",
        shot_alt={"on": "Waaiya's filter page with filtering on", "screen": "The Screen page: covering women and immodest images", "settings2": "Prayer times in Settings", "settings3": "Wait before turning off, and the PIN", "settings": "Filter options"},
    ),
}

DL = {"android": APK, "windows": RELEASES, "linux": RELEASES}

CSS = (HERE / "style.css").read_text()
JS = (HERE / "page.js").read_text()


def e(s):
    return html.escape(s, quote=True)


def page(lang, root):
    t = T[lang]
    a = f"{root}assets/"
    shows_names = "".join(
        f'<li><button type="button" class="show-name" data-shot="{k}" aria-pressed="{"true" if i == 0 else "false"}">{e(n)}</button></li>'
        for i, (n, k, _) in enumerate(t["shows"]))
    shows_text = "".join(
        f'<p class="show-text" data-for="{k}"{"" if i == 0 else " hidden"}>{e(x)}</p>' for i, (_, k, x) in enumerate(t["shows"]))
    shows_img = "".join(
        f'<img class="show-img" data-for="{k}" src="{a}{lang}-{k}.webp" width="540" height="1200" alt="{e(t["shot_alt"][k])}" loading="lazy"{"" if i == 0 else " hidden"}>'
        for i, (_, k, _) in enumerate(t["shows"]))
    how = ""
    for i, (say, call, resp) in enumerate(t["how"]):
        if i == 0:
            frag = f'<div class="resp" data-ui><img src="{a}{lang}-off.webp" width="540" height="1200" alt="{e(t["shot_alt"]["on"])}" loading="lazy"><p>{e(resp)}</p></div>'
        elif i == 1:
            frag = (f'<div class="resp notif" data-ui><img src="{a}logo.png" width="40" height="40" alt="">'
                    f'<div><strong>{e(call)}</strong><p>{e(resp)}</p></div></div>')
        else:
            frag = (f'<figure class="resp wide" data-ui><img src="{a}spec-after.webp" width="1600" height="560" alt="" loading="lazy">'
                    f'<figcaption>{e(t["how_done"])}</figcaption></figure>')
        callbox = f'<p class="call">{e(call)}</p>' if i != 1 else ""
        how += f'<li class="step reveal"><p class="say">{e(say)}</p>{callbox}{frag}</li>'
    left = t["notes"][:3]
    right = t["notes"][3:]
    notes = lambda ns, side: "".join(
        f'<div class="note" tabindex="0"><h3>{e(n)}</h3><p>{e(x)}</p></div>' for n, x in ns)
    facts = "".join(f'<div class="tile reveal"><strong>{e(n)}</strong><span>{e(x)}</span></div>' for n, x in t["facts"])
    faq = "".join(
        f'<details name="faq" class="q"{" open" if i == 0 else ""}><summary>{e(q)}<span class="pm" aria-hidden="true"></span></summary><p>{e(ans)}</p></details>'
        for i, (q, ans) in enumerate(t["faq"]))
    opts = "".join(f'<option value="{k}" data-href="{DL[k]}">{e(n)}</option>' for k, n in t["dl_opts"])
    foot_links = "".join(f'<a href="{e(h)}">{e(n)}</a>' for n, h in t["foot_links"])
    alt_lang = "en" if lang == "ar" else "ar"
    return f"""<!doctype html>
<html lang="{lang}" dir="{t['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(t['title'])}</title>
<meta name="description" content="{e(t['desc'])}">
<link rel="alternate" hreflang="{alt_lang}" href="https://waaiya.mssid.org/{'en/' if alt_lang == 'en' else ''}">
<link rel="canonical" href="https://waaiya.mssid.org/{'en/' if lang == 'en' else ''}">
<meta property="og:title" content="{e(t['title'])}">
<meta property="og:description" content="{e(t['desc'])}">
<meta property="og:image" content="https://waaiya.mssid.org/assets/og.jpg">
<meta name="theme-color" content="#0D6B5E">
<link rel="icon" href="{a}logo.png">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&display=swap">
<style>{CSS}</style>
</head>
<body>
<a class="lang" href="{t['other_href']}" hreflang="{t['other']}" lang="{t['other']}">{e(t['other_label'])}</a>
<header class="hero">
  <div class="hero-text">
    <img class="mark" src="{a}logo.png" width="48" height="48" alt="Waaiya">
    <div class="hero-copy">
      <h1><span class="line"><span>{e(t['h1a'])}</span></span><span class="line"><span>{e(t['h1b'])}</span></span></h1>
      <p class="lead">{e(t['lead'])}</p>
      <a class="btn" href="#download">{e(t['cta'])}</a>
    </div>
  </div>
  <div class="hero-stage">
    <div class="frag" data-ui data-state="off">
      <div class="frag-top">
        <button class="power" type="button" aria-pressed="false" aria-label="{e(t['frag_power'])}"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v8" /><path d="M6.4 6.6a8 8 0 1 0 11.2 0" /></svg></button>
        <div class="readout"><strong class="r-on">{e(t['frag_on'])}</strong><strong class="r-off">{e(t['frag_off'])}</strong>
          <span class="r-on">{e(t['frag_on_note'])}</span><span class="r-off">{e(t['frag_off_note'])}</span></div>
      </div>
      <p class="frag-title">{e(t['frag_title'])}</p>
      <div class="spec"><img class="s-before" src="{a}spec-before.webp" width="1600" height="560" alt=""><img class="s-after" src="{a}spec-after.webp" width="1600" height="560" alt=""></div>
      <p class="frag-axis">{e(t['frag_axis'])}</p>
    </div>
    <p class="frag-caption">{e(t['frag_caption'])}</p>
  </div>
</header>
<main>
<section class="show" aria-labelledby="show-h">
  <h2 id="show-h" class="vh">{e(t['show_h'])}</h2>
  <div class="show-index"><ul>{shows_names}</ul>{shows_text}</div>
  <div class="show-stage">{shows_img}</div>
</section>
<section class="how" aria-labelledby="how-h">
  <h2 id="how-h" class="reveal">{e(t['how_h'])}</h2>
  <ol class="steps">{how}</ol>
</section>
<section class="feat" aria-labelledby="feat-h">
  <h2 id="feat-h" class="reveal">{e(t['feat_h'])}</h2>
  <div class="feat-grid">
    <div class="notes notes-a">{notes(left, 'a')}</div>
    <div class="panel" data-ui><img src="{a}{lang}-settings.webp" width="540" height="1200" alt="{e(t['shot_alt']['settings'])}" loading="lazy"></div>
    <div class="notes notes-b">{notes(right, 'b')}</div>
  </div>
</section>
<section class="facts" aria-labelledby="facts-h">
  <div class="tile lead-tile reveal"><h2 id="facts-h">{e(t['facts_h'])}</h2><p>{e(t['facts_body'])}</p></div>
  {facts}
</section>
<section class="film" aria-labelledby="film-h">
  <div class="film-text reveal"><h2 id="film-h">{e(t['film_h'])}</h2><p>{e(t['film_body'])}</p></div>
  <video class="film-video" src="{a}waaiya-intro.mp4" poster="{a}waaiya-intro.jpg" width="540" height="960" controls playsinline muted loop preload="metadata" aria-label="{e(t['film_alt'])}"></video>
</section>
<section class="faq" aria-labelledby="faq-h">
  <h2 id="faq-h">{e(t['faq_h'])}</h2>
  <div class="qs">{faq}</div>
</section>
<section class="dl" id="download" aria-label="{e(t['cta'])}">
  <form class="dl-line" action="{APK}" method="get">
    <span>{e(t['dl_a'])}</span>
    <select id="platform" aria-label="{e(t['dl_a'])}">{opts}</select>
    <a class="btn dl-btn" href="{APK}">{e(t['dl_btn'])}</a>
  </form>
  <p class="dl-note">{e(t['dl_note'])}</p>
</section>
</main>
<footer class="foot"><span>{e(t['foot_what'])}</span><nav>{foot_links}</nav><span>{e(t['foot_right'])}</span></footer>
<script>{JS}</script>
</body>
</html>
"""


def md_to_html(md):
    """Small Markdown subset for docs/PRIVACY.md: headings, paragraphs, lists, tables, links, bold, code, rtl div."""
    out, para, lst, table = [], [], [], []

    def inline(s):
        s = html.escape(s, quote=False)
        s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
        s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
        s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
        s = re.sub(r"&lt;(https?://[^&]+)&gt;", r'<a href="\1">\1</a>', s)
        return s

    def flush():
        nonlocal para, lst, table
        if para: out.append("<p>" + inline(" ".join(para)) + "</p>"); para = []
        if lst: out.append("<ul>" + "".join(f"<li>{inline(x)}</li>" for x in lst) + "</ul>"); lst = []
        if table:
            rows = [[c.strip() for c in r.strip("|").split("|")] for r in table if not re.match(r"^\|[-| ]+\|$", r)]
            h = "".join(f"<th>{inline(c)}</th>" for c in rows[0])
            b = "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in rows[1:])
            out.append(f"<table><thead><tr>{h}</tr></thead><tbody>{b}</tbody></table>"); table = []

    for line in md.splitlines():
        s = line.strip()
        if s.startswith("<div") or s.startswith("</div"):
            flush(); out.append(s); continue
        if not s or s == "---":
            flush(); continue
        m = re.match(r"^(#{1,3}) (.*)", s)
        if m:
            flush(); n = len(m.group(1)); out.append(f"<h{n}>{inline(m.group(2))}</h{n}>"); continue
        if s.startswith("|"):
            table.append(s); continue
        if s.startswith("- "):
            lst.append(s[2:]); continue
        if lst and line.startswith("  "):
            lst[-1] += " " + s; continue
        para.append(s)
    flush()
    return "\n".join(out)


def privacy(lang, root):
    t = T[lang]
    body = md_to_html((HERE.parent / "docs/PRIVACY.md").read_text())
    body = body.replace('href="#سياسة-الخصوصية"', 'href="#ar"').replace('<div dir="rtl">', '<div dir="rtl" lang="ar" id="ar">')
    return f"""<!doctype html>
<html lang="en" dir="ltr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Waaiya: {e(T['en']['privacy_title'])} · {e(T['ar']['privacy_title'])}</title>
<link rel="icon" href="{root}assets/logo.png">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;600&display=swap">
<style>{CSS}</style></head>
<body class="doc"><a class="lang" href="{root}{'en/' if lang == 'en' else ''}">Waaiya</a><main class="prose">{body}</main></body></html>
"""


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / "en").mkdir(parents=True)
    shutil.copytree(HERE / "assets", OUT / "assets")
    (OUT / "index.html").write_text(page("ar", ""))
    (OUT / "en/index.html").write_text(page("en", "../"))
    (OUT / "privacy.html").write_text(privacy("ar", ""))
    (OUT / "en/privacy.html").write_text(privacy("en", "../"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
