#!/usr/bin/env python3
"""Builds the Waaiya landing page (waaiya.mssid.org): index.html (Arabic) and en/index.html (English) from one
template, plus privacy.html / en/privacy.html from docs/PRIVACY.md.

    python3 site/build.py              # writes site/public/
    python3 site/build.py --preview    # same, with noindex (for waaiya.mssid.org/preview/)
    site/deploy.sh [--preview]         # build and rsync to the host

The page asks nothing of any other server: the typeface (IBM Plex Sans Arabic, OFL) and GSAP are in assets/.
Generated pictures and the filtered sound come from real material: see make_assets.py.
"""
import html
import json
import re
import shutil
import sys
import unicodedata
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "public"
SITE = "https://waaiya.mssid.org/"
REPO = "https://github.com/oksyassine/waaiya"
VERSION = "0.2.12"
DL = "https://waaiya.mssid.org/downloads/"   # every download lives here (site/upload_downloads.sh); GitHub has the same files
APK = DL + "waaiya.apk"                      # the universal APK under a stable name
APK_ARM64 = DL + f"waaiya-v{VERSION}-arm64-v8a-release.apk"
APK_V7A = DL + f"waaiya-v{VERSION}-armeabi-v7a-release.apk"
WIN_ZIP = DL + f"waaiya-desktop-windows-x64-v{VERSION}.zip"
LINUX_DESKTOP = DL + f"waaiya-desktop-linux-x64-v{VERSION}.tar.gz"
LINUX_CLI = DL + f"waaiya-linux-x64-v{VERSION}.tar.gz"
SUMS = DL + "SHA256SUMS"
RELEASES = REPO + "/releases/latest"
VERSION = "0.2.12"
GSAP = "js/gsap-3.15.0.min.js"
PREVIEW = "--preview" in sys.argv

LANGS = [("ar", "العربية"), ("en", "English"), ("fr", "Français"), ("ur", "اردو"), ("id", "Bahasa Indonesia"),
         ("tr", "Türkçe"), ("bn", "বাংলা"), ("fa", "فارسی"), ("ms", "Bahasa Melayu"), ("es", "Español"),
         ("nl", "Nederlands"), ("de", "Deutsch"), ("it", "Italiano"), ("ru", "Русский"), ("uz", "Oʻzbekcha"),
         ("sw", "Kiswahili"), ("ha", "Hausa"), ("so", "Soomaali")]
RTL_LANGS = {"ar", "ur", "fa"}

# [[...]] marks a Latin or number run inside Arabic copy: it becomes <bdi dir="ltr"> so it keeps its order.
T = {
    "ar": dict(
        dir="rtl", other="en", other_label="English", other_href="en/",
        title="واعية: تطبيق يزيل المعازف ويُبقي الكلام",
        desc="تطبيق مجاني مفتوح المصدر لأندرويد وويندوز ولينكس، يزيل الآلات الموسيقية من صوت كل التطبيقات مباشرةً ويُبقي الكلام والتلاوة. لا يخرج شيء من جهازك.",
        nav=[("hear", "اسمع"), ("cover", "التمويه"), ("lang", "لغتك"), ("faq", "أسئلة")],
        nav_cta="حمّل",
        h1="يزيل المعازف ويُبقي الكلام",
        lead="تطبيق مجاني مفتوح المصدر لأندرويد وويندوز ولينكس. يزيل الآلات الموسيقية من صوت كل التطبيقات مباشرةً، ويُبقي الكلام والتلاوة. ولا يخرج شيء من جهازك.",
        cta="حمّل واعية",
        power_label="التصفية على هذه الصفحة",
        r_off="اضغط الزر: الخطوط الأفقية في هذه الصفحة موسيقى حقيقية.",
        r_off_h="التصفية متوقفة",
        r_on_h="التصفية تعمل · تأخير نحو 30 ملّي ثانية",
        r_on="بقي الكلام وحده. اضغط مرة أخرى لإيقافها.",
        compact_off="متوقفة", compact_on="تعمل",
        spec_cap_off="قبل واعية", spec_cap_on="بعد واعية",
        spec_what="محاضرة بالعربية تحتها موسيقى · [[10]] ثوانٍ · من [[60]] هرتز إلى [[8]] كيلوهرتز",
        hear_h1="ما يدخل", hear_h2="وما تسمعه",
        hear_in="قبل واعية: محاضرة بالعربية تحتها موسيقى، كما تصل من أي تطبيق. هذه صورتها فقط: لن نُسمِعك الموسيقى.",
        hear_in_cap="قبل واعية",
        hear_out_cap="بعد واعية",
        play="استمع إلى ما بعد واعية", pause="إيقاف مؤقت",
        hear_out="بعد واعية: الصوت نفسه بعد تصفية واعية الحقيقية، على الجهاز. وقِسنا الموسيقى وحدها قبله وبعده: خرجت أخفض بنحو [[37]] ديسيبل.",
        hear_credit="الصوت: [[Arabic Speech Corpus]]، نوّار حلبي، [[CC BY 4.0]]. الموسيقى صنعها المشروع للاختبار.",
        opts_h="خيارات بيدك",
        opts=[
            ("صمتٌ إن توقّفت التصفية وحدها", "إن أنهى النظام التصفية دون أن تطلب، تبقى التطبيقات صامتة حتى تعيد التشغيل، فلا تُسمَع الموسيقى.", True),
            ("صوت أحادي يوفّر البطارية", "الأحادي هو الافتراضي: نحو نصف ما يستهلكه الستيريو، ويواكب هواتف أكثر.", True),
            ("صمت الهاتف في أوقات الصلاة", "محسوبة على الهاتف من مدينتك. مثلًا من الظهر [[12:00]] حتى [[12:20]]، ورسالة قصيرة لمن يتصل.", False),
            ("كتم غناء النساء، للرجال", "اختياري. نموذج أوّلي: يلتقط جزءًا من الغناء في الأغاني الحقيقية، لا كلّه.", False),
            ("تطبيقات تُسمَع كما هي", "اختر تطبيقات لا تمرّ بالتصفية، أو تطبيقات لا يغطّيها التمويه.", False),
        ],
        cover_h="غطِّ بيدك ما فات التمويه",
        cover_p="«تمويه الشاشة» يغطّي النساء أو الصور غير المحتشمة فوق كل التطبيقات، على الجهاز نفسه. وإن فاتته صورة، اضغط «تغطية جزء» واسحب إصبعك فوقها. جرّبه على هذه الصورة.",
        cover_add="تغطية جزء", cover_clear="إزالة التغطية اليدوية", cover_hint="اسحب فوق الصورة.",
        cover_alt="مكبّر صوت عليه حبيبات رمل، من فيلم واعية",
        cover_note="تبقى مغطّاة حتى تزيلها أو يتوقف التمويه.",
        wait_h="الانتظار قبل الإيقاف",
        wait_p="اختر الآن، وأنت هادئ، مدةً للانتظار من دقيقة إلى [[24]] ساعة. عندها ينتظر زرّ الإيقاف، وتقرّر من جديد حين تنتهي المدة. ويمكن للوالدين وضع رمز.",
        wait_limits="هذه حماية من لحظة ضعف، لا من شخص مُصِرّ: لا شيء يمنع الإيقاف الإجباري أو حذف التطبيق، وواعية تقول ذلك بوضوح.",
        card_title="حماية في لحظات الضعف",
        card_delay="الانتظار قبل الإيقاف: [[10]] ثوانٍ",
        card_demo="مختصرة للعرض. في التطبيق تختار من دقيقة إلى [[24]] ساعة.",
        card_on="التصفية تعمل", card_off="التصفية متوقفة",
        card_stop="إيقاف", card_start="تشغيل",
        card_wait="إيقاف التصفية: ينتظر حتى {time}، ثم أكِّده.",
        card_left="بقي {n} ث",
        card_ready="إيقاف التصفية: انتهى الانتظار. أما زلت تريده؟",
        card_confirm="أكِّد", card_cancel="إلغاء",
        card_hint="شغّل التصفية أولًا، ثم جرّب «إيقاف».",
        card_done="توقفت التصفية في هذه الصفحة. أما التشغيل فيسري فورًا دائمًا.",
        card_kept="لم يتغيّر شيء: التصفية باقية.",
        lang_h="واعية تتكلّم لغتك",
        lang_p="[[18]] لغة، ويبدأ التطبيق على أندرويد بلغة هاتفك إن كانت منها. اختر لغة لترى صفحة التصفية في واعية على ويندوز بها.",
        lang_cap="واعية على ويندوز، صفحة التصفية: {name}",
        lang_alt="صفحة التصفية في واعية على ويندوز بلغة: {name}",
        phone_h="على هاتفك",
        phones=[("on", "التصفية", "زر واحد لكل التطبيقات"), ("screen", "الشاشة", "تمويه النساء والصور غير المحتشمة"),
                ("settings2", "أوقات الصلاة", "صمت، ورسالة لمن يتصل"), ("settings3", "الحماية", "الانتظار قبل الإيقاف، والرمز")],
        phone_meta="أندرويد [[15]] · واعية [[0.2.12]]",
        how_h="كيف تبدأ",
        how=[
            ("أولًا، ثبّت واعية.", "ملف [[waaiya.apk]] لأندرويد [[10]] أو أحدث. أو نسخة ويندوز ولينكس."),
            ("ثم أعدّه مرة واحدة.", "على الهاتف نفسه، في أربع خطوات: [[Wi‑Fi]]، و«خيارات المطور»، و«تصحيح الأخطاء اللاسلكي»، ورمز الإقران. تُوضَع علامة الإتمام على كل خطوة وحدها حين تُنجزها، مع صورة لكل خطوة بلغتك."),
            ("ثم اضغط الزر.", "تُزال الآلات من كل التطبيقات. يبقى الإشعار ظاهرًا، وفيه زر الإيقاف."),
            ("وشغّل ما شئت.", "يوتيوب، إنستغرام، المتصفح، الألعاب: محاضرة أو خبر أو وصفة، يصل الكلام وحده."),
        ],
        priv_h="لا يخرج شيء من جهازك",
        priv_p="التصفية والتمويه تعملان على الجهاز. لا حساب، ولا إحصاءات، ولا إعلانات. وكل تغيير في الشيفرة يُختبر والإنترنت مقطوع عنه. والشيفرة كاملة على [[GitHub]] برخصة [[AGPL]]: يستطيع أي أحد بناءها ومقارنتها بما ننشر.",
        facts=[("0", "اتصال بالإنترنت أثناء التصفية"), ("18", "لغة"), ("3", "أنظمة: أندرويد، ويندوز، لينكس"), ("30", "ملّي ثانية تأخير تقريبًا")],
        film_cap="واعية في [[50]] ثانية. صوت الفيلم كلام فقط، بلا موسيقى.",
        film_alt="فيلم تعريفي بواعية",
        faq_h="أسئلة",
        faq=[
            ("هل يبقى الغناء والأناشيد؟", "لا، يُزال الغناء مع الآلات حاليًا، ويبقى الكلام والتلاوة. وللرجال خيار يكتم غناء النساء أيضًا، وهو نموذج أوّلي يلتقط جزءًا من الغناء في الأغاني الحقيقية."),
            ("هل يحتاج إلى الإنترنت؟", "لا. التصفية والتمويه تعملان دون إنترنت. وحده «افتح رابطًا» يتصل بموقع الرابط الذي تفتحه."),
            ("ما الإعداد لمرة واحدة؟", "يتيح لواعية كتم الصوت الأصلي للتطبيقات أثناء التصفية. يجري على الهاتف نفسه عبر «تصحيح الأخطاء اللاسلكي» في أربع خطوات، تُوضَع علامة الإتمام على كل منها وحدها حين تُنجزها. ودونه تعمل واعية لكنها تسأل قبل كل تشغيل."),
            ("هل يعمل على هاتفي؟", "أندرويد [[10]] أو أحدث. هواتف شاومي وأوبو وريلمي وون بلس ترفض بعض الأذونات، فيتولّى مساعد واعية المهمة دون مفتاح مخفي تبحث عنه."),
            ("كم التأخير؟", "نحو [[30]] ملّي ثانية بين الصوت الأصلي وما تسمعه."),
            ("هل يستهلك البطارية؟", "الصوت الأحادي، وهو الافتراضي، يستهلك نحو نصف ما يستهلكه الستيريو. وتقرير التشخيص يعرض الاستهلاك في الساعة على هاتفك."),
            ("هل يمكن إيقافه في لحظة ضعف؟", "اختر مدة انتظار قبل أي إيقاف، ورمزًا إن شئت. لكن لا شيء يمنع حذف التطبيق أو إيقافه الإجباري من إعدادات أندرويد، وواعية تقول ذلك بوضوح."),
            ("وويندوز ولينكس؟", "ويندوز [[10 (2004)]] أو أحدث: قريبًا في متجر مايكروسوفت، والطلب قيد المراجعة. حتى ذلك الحين ملف [[zip]] على [[GitHub]]، لكنه غير موقَّع بعد، فقد يمنعه «التحكم الذكي في التطبيقات» في ويندوز. لينكس: نسخة سطح المكتب من [[GitHub]]."),
            ("من يقف وراءه؟", "مشروع مفتوح المصدر برخصة [[AGPL]]، شيفرته كاملة على [[GitHub]]. يمكن لأي أحد بناؤه بنفسه ومقارنته بما ننشر."),
        ],
        dl_btn="تنزيل", dl_soon="قريبًا في متجر مايكروسوفت",
        dl_for={"android": "حمّل واعية لأندرويد", "windows": "حمّل واعية لويندوز", "linux": "حمّل واعية للينكس"},
        dl_rows=[
            ("android", "أندرويد: [[waaiya.apk]]", APK, "الإصدار [[0.2.12]]، يعمل على كل الهواتف، أندرويد [[10]] أو أحدث · [[108 MB]]",
             [("نسخة أصغر لأغلب الهواتف · [[arm64-v8a]]", APK_ARM64, "[[90 MB]]"),
              ("للهواتف القديمة بنظام [[32]] بت · [[armeabi-v7a]]", APK_V7A, "[[88 MB]]")]),
            ("windows", "ويندوز: قريبًا في متجر مايكروسوفت", None, "الطلب قيد المراجعة. ويندوز [[10 (2004)]] أو أحدث.",
             [("ملف [[zip]]: فكّه وشغّل [[waaiya_desktop.exe]]", WIN_ZIP, "[[47 MB]] · غير موقَّع بعد، فقد يمنعه «التحكم الذكي في التطبيقات» في ويندوز.")]),
            ("linux", "لينكس: تطبيق سطح المكتب", LINUX_DESKTOP, "لينكس [[x64]] · [[58 MB]]",
             [("المحرّك وسطر الأوامر فقط", LINUX_CLI, "[[9 MB]]")]),
        ],
        dl_sums=("تحقّق من الملفات بـ [[SHA256SUMS]]", "والملفات نفسها والشيفرة كاملة على [[GitHub]]"),
        foot_what="واعية · ﴿وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ﴾ الحاقة: [[12]]",
        foot_links=[("GitHub", REPO), ("الخصوصية", "privacy.html"), ("English", "en/")],
        foot_right="[[2026]] · مجاني ومفتوح المصدر",
        privacy_title="سياسة الخصوصية",
        shot_alt={"on": "صفحة التصفية في واعية والتصفية تعمل", "screen": "صفحة الشاشة: تمويه النساء والصور غير المحتشمة", "settings2": "أوقات الصلاة في الإعدادات", "settings3": "الانتظار قبل الإيقاف والرمز"},
    ),
    "en": dict(
        dir="ltr", other="ar", other_label="العربية", other_href="../",
        title="Waaiya: remove the music, keep the voice",
        desc="A free, open-source app for Android, Windows and Linux that removes musical instruments from everything you play, live, and keeps speech and Quran recitation.",
        nav=[("hear", "Listen"), ("cover", "Screen blur"), ("lang", "Your language"), ("faq", "Questions")],
        nav_cta="Download",
        h1="Removes music, keeps the voice",
        lead="A free, open-source app for Android, Windows and Linux. It removes musical instruments from the sound of every app, live, and keeps speech and Quran recitation. Nothing leaves your device.",
        cta="Get Waaiya",
        power_label="Filtering on this page",
        r_off="Press the button: the horizontal lines on this page are real music.",
        r_off_h="Filtering is off",
        r_on_h="Filtering is on · about 30 ms of delay",
        r_on="Only the voice is left. Press again to turn it off.",
        compact_off="Off", compact_on="On",
        spec_cap_off="Before Waaiya", spec_cap_on="After Waaiya",
        spec_what="An Arabic lecture with music under it · 10 seconds · 60 Hz to 8 kHz",
        hear_h1="What goes in", hear_h2="What you hear",
        hear_in="Before Waaiya: an Arabic lecture with music under it, as any app plays it. Only its picture: we will not play you the music.",
        hear_in_cap="Before Waaiya",
        hear_out_cap="After Waaiya",
        play="Listen to it after Waaiya", pause="Pause",
        hear_out="After Waaiya: the same sound after Waaiya's real filter, on the device. We also measured the music alone before and after it: it came out about 37 dB quieter.",
        hear_credit="Voice: Arabic Speech Corpus, Nawar Halabi, CC BY 4.0. Music made by the project for testing.",
        opts_h="Choices in your hands",
        opts=[
            ("Silence if filtering stops by itself", "If the system ends filtering without you asking, apps stay silent until you start again, so no music comes through.", True),
            ("Mono sound that saves battery", "Mono is the default: about half of what stereo uses, and it keeps up on more phones.", True),
            ("A silent phone at prayer times", "Computed on the phone from your city. For example from Dhuhr at 12:00 until 12:20, and a text to whoever calls.", False),
            ("Mute women's singing, for men", "Optional. An early model: it catches part of the singing in real songs, not all of it.", False),
            ("Apps heard as they are", "Choose apps that skip filtering, or apps the screen blur leaves uncovered.", False),
        ],
        cover_h="Cover what the blur missed",
        cover_p="Screen blur covers women, or immodest images, over every app, on the device itself. If it misses a picture, tap “Cover an area” and drag your finger over it. Try it on this picture.",
        cover_add="Cover an area", cover_clear="Remove hand covers", cover_hint="Drag over the picture.",
        cover_alt="A loudspeaker with grains of sand on it, from Waaiya's film",
        cover_note="It stays covered until you remove it or the blur stops.",
        wait_h="Wait before turning off",
        wait_p="Set a wait now, while you are calm: from 1 minute to 24 hours. Then Stop waits, and you decide again when the wait is over. A parent can also set a PIN.",
        wait_limits="This protects against a weak moment, not against a determined person: nothing can stop a force stop or uninstalling, and Waaiya says so plainly.",
        card_title="Protection for weak moments",
        card_delay="Wait before turning off: 10 seconds",
        card_demo="Shortened for this demo. In the app you choose from 1 minute to 24 hours.",
        card_on="Filtering is on", card_off="Filtering is off",
        card_stop="Stop", card_start="Start",
        card_wait="Stop the filter: waiting until {time}. Then confirm it.",
        card_left="{n} s left",
        card_ready="Stop the filter: the wait is over. Do you still want it?",
        card_confirm="Confirm", card_cancel="Cancel",
        card_hint="Turn filtering on first, then try Stop.",
        card_done="Filtering is off on this page. Turning it on always takes effect at once.",
        card_kept="Nothing changed: filtering stays on.",
        lang_h="Waaiya speaks your language",
        lang_p="18 languages; on Android it starts in your phone's language. Pick one to see the Windows app in it.",
        lang_cap="Waaiya on Windows, the filter page: {name}",
        lang_alt="Waaiya's filter page on Windows in {name}",
        phone_h="On your phone",
        phones=[("on", "Filter", "One button for every app"), ("screen", "Screen", "Blur for women and immodest images"),
                ("settings2", "Prayer times", "Silence, and a text to callers"), ("settings3", "Protection", "Wait before turning off, and a PIN")],
        phone_meta="Android 15 · Waaiya 0.2.12",
        how_h="How to start",
        how=[
            ("First, install Waaiya.", "waaiya.apk for Android 10 or newer. Or the Windows and Linux apps."),
            ("Then set it up once.", "On the phone itself, in four steps: Wi‑Fi, Developer options, Wireless debugging and the pairing code. Each step ticks itself when you finish it, with a picture of each step in your language."),
            ("Then press the button.", "Instruments are removed from every app. The notification stays, with its Stop button."),
            ("And play anything.", "YouTube, Instagram, the browser, games: a lecture, the news, a recipe, only the voice comes through."),
        ],
        priv_h="Nothing leaves your device",
        priv_p="Filtering and the blur run on the device. No account, no analytics, no ads. Every change to the code is tested with the internet cut off. All the code is on GitHub under the AGPL: anyone can build it and compare it with what we publish.",
        facts=[("0", "internet connections while filtering"), ("18", "languages"), ("3", "platforms: Android, Windows, Linux"), ("30", "ms of delay, about")],
        film_cap="Waaiya in 50 seconds. The film's sound is voice only, no music.",
        film_alt="Waaiya introduction film",
        faq_h="Questions",
        faq=[
            ("Is singing kept?", "No, singing is removed with the instruments for now; speech and recitation stay. Men also have an option that mutes women's singing: an early model that catches part of the singing in real songs."),
            ("Does it need the internet?", "No. Filtering and the blur work offline. Only “Open a link” contacts the site of the link you open."),
            ("What is the one-time setup?", "It lets Waaiya silence the original sound of the app it filters. It runs on the phone itself through Wireless debugging, in four steps that tick themselves as you finish them. Without it Waaiya still works but asks before each start."),
            ("Will it work on my phone?", "Android 10 or newer. Xiaomi, OPPO, realme and OnePlus phones refuse some permissions, so Waaiya's helper takes over, with no hidden switch to find."),
            ("How much delay?", "About 30 ms between the original sound and what you hear."),
            ("Does it drain the battery?", "Mono sound, the default, uses about half of what stereo does. The diagnostics report shows the use per hour on your phone."),
            ("Can I be stopped from switching it off in a weak moment?", "Choose a waiting time before any switch-off, and a PIN if you like. Nothing can stop uninstalling or a force stop from Android's settings, and Waaiya says so plainly."),
            ("Windows and Linux?", "Windows 10 (2004) or newer: soon in the Microsoft Store, where it is under review. Until then a zip on GitHub, which is not signed yet, so Windows Smart App Control may block it. Linux: the desktop app from GitHub."),
            ("Who is behind it?", "An open-source project under the AGPL, with all its code on GitHub. Anyone can build it and compare it with what we publish."),
        ],
        dl_btn="Download", dl_soon="Soon in the Microsoft Store",
        dl_for={"android": "Get Waaiya for Android", "windows": "Get Waaiya for Windows", "linux": "Get Waaiya for Linux"},
        dl_rows=[
            ("android", "Android: waaiya.apk", APK, "Version 0.2.12, for every phone, Android 10 or newer · 108 MB",
             [("Smaller, for most phones · arm64-v8a", APK_ARM64, "90 MB"),
              ("For older 32-bit phones · armeabi-v7a", APK_V7A, "88 MB")]),
            ("windows", "Windows: soon in the Microsoft Store", None, "Under review. Windows 10 (2004) or newer.",
             [("The zip: unpack it and run waaiya_desktop.exe", WIN_ZIP, "47 MB · not signed yet, so Windows Smart App Control may block it.")]),
            ("linux", "Linux: the desktop app", LINUX_DESKTOP, "Linux x64 · 58 MB",
             [("The engine and command line only", LINUX_CLI, "9 MB")]),
        ],
        dl_sums=("Check the files against SHA256SUMS", "The same files and all the code are on GitHub"),
        foot_what="Waaiya · “that a heeding ear may heed it” (Al-Haqqah 69:12)",
        foot_links=[("GitHub", REPO), ("Privacy", "privacy.html"), ("العربية", "../")],
        foot_right="2026 · Free and open source",
        privacy_title="Privacy policy",
        shot_alt={"on": "Waaiya's filter page with filtering on", "screen": "The Screen page: blur for women and immodest images", "settings2": "Prayer times in Settings", "settings3": "Wait before turning off, and the PIN"},
    ),
}

CSS = (HERE / "style.css").read_text()
JS = (HERE / "page.js").read_text()

AR_RANGE = "U+0600-06FF,U+0750-077F,U+0870-088E,U+0890-0891,U+0897-08E1,U+08E3-08FF,U+200C-200E,U+2010-2011,U+204F,U+2E41,U+FB50-FDFF,U+FE70-FE74,U+FE76-FEFC"
LAT_RANGE = "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"


def fonts(a):
    out = []
    for sub, rng in (("arabic", AR_RANGE), ("latin", LAT_RANGE)):
        for w in (400, 600, 700):
            out.append(f"@font-face{{font-family:'IBM Plex Sans Arabic';font-style:normal;font-weight:{w};font-display:swap;"
                       f"src:url({a}fonts/ibm-plex-sans-arabic-{sub}-{w}-normal.woff2) format('woff2');unicode-range:{rng}}}")
    return "\n".join(out)


def bands_css(a):
    """The music strips: crisp lines drawn at their shown size (make_assets.py), 1x and 2x, light and dark."""
    def img(theme, h):
        one, two = f"{a}bands-{theme}-{h}.png", f"{a}bands-{theme}-{h}@2x.png"
        return (f"background-image:url({two});background-image:-webkit-image-set(url({one}) 1x,url({two}) 2x);"
                f"background-image:image-set(url({one}) 1x,url({two}) 2x)")
    dark = ":root:not([data-theme=\"light\"]) .music i{%s}"
    return (f".music i{{{img('light', 48)}}}"
            f"@media (prefers-color-scheme: dark){{{dark % img('dark', 48)}}}"
            f":root[data-theme=\"dark\"] .music i{{{img('dark', 48)}}}"
            f"@media (max-width: 560px){{.music i{{{img('light', 32)}}}"
            f"@media (prefers-color-scheme: dark){{{dark % img('dark', 32)}}}"
            f":root[data-theme=\"dark\"] .music i{{{img('dark', 32)}}}}}")


def e(s):
    """Escape, then turn [[run]] into an isolated left-to-right run."""
    s = html.escape(s, quote=True)
    return re.sub(r"\[\[(.+?)\]\]", r'<bdi dir="ltr">\1</bdi>', s)


def plain(s):
    return re.sub(r"\[\[(.+?)\]\]", r"\1", s)


def visible_len(s):
    s = unicodedata.normalize("NFC", html.unescape(s))
    return sum(1 for c in s if unicodedata.category(c) != "Mn")


POWER_SVG = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.2v8.2"/><path d="M6.3 6.4a8.1 8.1 0 1 0 11.4 0"/></svg>'


def mark(cls, draw=False):
    """The logo, redrawn: a note with a strike through it. The strike (and the gap it cuts) can draw on."""
    d = ' class="strike draw"' if draw else ' class="strike"'
    return (f'<svg class="{cls}" viewBox="0 0 300 300" aria-hidden="true" focusable="false">'
            f'<mask id="m-{cls}" maskUnits="userSpaceOnUse" x="0" y="0" width="300" height="300"><rect width="300" height="300" fill="#fff"/>'
            f'<line{d} x1="92" y1="89" x2="215" y2="212" pathLength="1" stroke="#000" stroke-width="30"/></mask>'
            f'<g mask="url(#m-{cls})" fill="currentColor"><circle cx="137" cy="183" r="27"/><rect x="152" y="90" width="12" height="95"/><rect x="152" y="90" width="38" height="24"/></g>'
            f'<line{d} x1="96" y1="93" x2="211" y2="208" pathLength="1" stroke="currentColor" stroke-width="14"/></svg>')


def jsonld(lang, t, root_url):
    app = {
        "@context": "https://schema.org", "@type": "SoftwareApplication",
        "name": "Waaiya", "alternateName": "واعية", "url": root_url,
        "description": plain(t["desc"]), "inLanguage": [c for c, _ in LANGS],
        "applicationCategory": "MultimediaApplication",
        "operatingSystem": "Android 10+, Windows 10 (2004)+, Linux",
        "softwareVersion": VERSION, "downloadUrl": APK,
        "license": "https://www.gnu.org/licenses/agpl-3.0.html",
        "isAccessibleForFree": True, "sameAs": [REPO],
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "image": SITE + "assets/og.jpg",
        "screenshot": SITE + f"assets/{lang}-on.webp",
    }
    faq = {"@context": "https://schema.org", "@type": "FAQPage", "inLanguage": lang,
           "mainEntity": [{"@type": "Question", "name": plain(q), "acceptedAnswer": {"@type": "Answer", "text": plain(ans)}} for q, ans in t["faq"]]}
    return json.dumps([app, faq], ensure_ascii=False).replace("</", "<\\/")


def page(lang, root):
    t = T[lang]
    a = f"{root}assets/"
    url = SITE + ("en/" if lang == "en" else "")
    rtl = t["dir"] == "rtl"
    for k, lim in (("title", 60), ("desc", 160)):
        n = visible_len(t[k])
        assert n <= lim, f"{lang} {k} is {n} characters (limit {lim})"

    nav = "".join(f'<a href="#{i}">{e(n)}</a>' for i, n in t["nav"])
    strip = '<div class="music" aria-hidden="true"><i></i></div>'

    # options: sentences with switches
    opts = ""
    for i, (s, c, on) in enumerate(t["opts"]):
        opts += (f'<div class="opt" data-on="{str(on).lower()}" data-tone="{i % 5}"><div class="opt-t"><p class="opt-s" id="opt{i}">{e(s)}</p>'
                 f'<p class="opt-c">{e(c)}</p></div>'
                 f'<button type="button" class="sw" role="switch" aria-checked="{str(on).lower()}" aria-labelledby="opt{i}" data-ui><span></span></button></div>')

    langs = "".join(
        f'<li><button type="button" class="lt" data-lang="{c}" lang="{c}" dir="{"rtl" if c in RTL_LANGS else "ltr"}" aria-pressed="{"true" if c == lang else "false"}">{html.escape(n)}</button></li>'
        for c, n in LANGS)
    lname = dict(LANGS)

    phones = "".join(
        f'<figure class="tile" data-tone="{i}"><img src="{a}{lang}-{k}.webp" width="540" height="1200" alt="{e(t["shot_alt"][k])}" loading="lazy">'
        f'<figcaption><strong>{e(n)}</strong><span>{e(x)}</span><span class="meta">{e(t["phone_meta"])}</span></figcaption></figure>'
        for i, (k, n, x) in enumerate(t["phones"]))

    how = "".join(f'<li><h3>{e(s)}</h3><p>{e(n)}</p></li>' for s, n in t["how"])
    facts = "".join(f'<li><strong><bdi dir="ltr">{e(n)}</bdi></strong><span>{e(x)}</span></li>' for n, x in t["facts"])
    qs = "".join(
        f'<h3 class="qq" style="--r:{i + 2}"><button type="button" id="q{i}" aria-expanded="{"true" if i == 0 else "false"}" aria-controls="a{i}">{e(q)}</button></h3>'
        f'<div class="qa" id="a{i}" role="region" aria-labelledby="q{i}" style="--r:{i + 2}"{"" if i == 0 else " data-closed"}><p>{e(ans)}</p></div>'
        for i, (q, ans) in enumerate(t["faq"]))
    rows = ""
    for k, main, href, note, more in t["dl_rows"]:
        main_html = f'<a class="dl-main" href="{href}">{e(main)}</a>' if href else f'<span class="dl-main soon">{e(main)}</span>'
        more_html = "".join(f'<li><a href="{h}">{e(n)}</a> <span>{e(x)}</span></li>' for n, h, x in more)
        rows += f'<li data-plat="{k}">{main_html}<p>{e(note)}</p><ul class="dl-more">{more_html}</ul></li>'
    sums = f'<p class="dl-sums"><a href="{SUMS}">{e(t["dl_sums"][0])}</a> · <a href="{RELEASES}">{e(t["dl_sums"][1])}</a></p>'
    foot_links = "".join(f'<a href="{html.escape(h)}">{e(n)}</a>' for n, h in t["foot_links"])

    i18n = {k: plain(t[k]) for k in ("r_off", "r_off_h", "r_on", "r_on_h", "compact_off", "compact_on", "spec_cap_off", "spec_cap_on",
                                     "play", "pause", "cover_clear", "cover_hint", "card_on", "card_off", "card_stop", "card_start", "card_wait",
                                     "card_left", "card_ready", "card_done", "card_hint", "card_kept", "lang_cap", "lang_alt", "dl_btn", "dl_soon")}
    i18n["dl_for"] = t["dl_for"]
    i18n["names"] = lname
    i18n["apk"] = APK
    i18n["releases"] = RELEASES
    i18n["linux"] = LINUX_DESKTOP
    i18n_json = json.dumps(i18n, ensure_ascii=False).replace("</", "<\\/")
    sub = "arabic" if rtl else "latin"
    alt_url = SITE + ("" if lang == "en" else "en/")
    robots = '<meta name="robots" content="noindex">\n' if PREVIEW else ""
    sweep = "sweep-rtl" if rtl else "sweep-ltr"

    return f"""<!doctype html>
<html lang="{lang}" dir="{t['dir']}" class="{sweep}" data-filter="off">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(t['title'])}</title>
<meta name="description" content="{html.escape(t['desc'])}">
{robots}<link rel="canonical" href="{url}">
<link rel="alternate" hreflang="ar" href="{SITE}">
<link rel="alternate" hreflang="en" href="{SITE}en/">
<link rel="alternate" hreflang="x-default" href="{SITE}">
<meta property="og:type" content="website">
<meta property="og:url" content="{url}">
<meta property="og:title" content="{html.escape(t['title'])}">
<meta property="og:description" content="{html.escape(t['desc'])}">
<meta property="og:image" content="{SITE}assets/og.jpg">
<meta property="og:locale" content="{'ar_AR' if rtl else 'en_US'}">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#053D35">
<link rel="icon" href="{a}logo.png">
<link rel="preload" href="{a}fonts/ibm-plex-sans-arabic-{sub}-400-normal.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="{a}fonts/ibm-plex-sans-arabic-{sub}-700-normal.woff2" as="font" type="font/woff2" crossorigin>
<script>(function(d){{d.classList.add("js");var s=null;try{{s=localStorage.getItem("waaiya.filter")}}catch(x){{}}var q=/[?&]filter=(on|off)/.exec(location.search);if(q)s=q[1];d.setAttribute("data-filter",s==="on"?"on":"off")}})(document.documentElement)</script>
<style>{fonts(a)}
{CSS}\n{bands_css(a)}</style>
<script type="application/ld+json">{jsonld(lang, t, url)}</script>
</head>
<body>
<a class="skip" href="#main">{'تخطَّ إلى المحتوى' if rtl else 'Skip to content'}</a>
<header class="bar">
  <a class="brand" href="#top" aria-label="{'واعية' if rtl else 'Waaiya'}">{mark('brand-mark', draw=True)}<span>{'واعية' if rtl else 'Waaiya'}</span></a>
  <nav class="links" aria-label="{'أقسام الصفحة' if rtl else 'Page sections'}">{nav}</nav>
  <div class="bar-end">
    <button type="button" class="power power-s" data-power aria-pressed="false" aria-label="{e(t['power_label'])}">{POWER_SVG}<span class="ps-t" aria-hidden="true">{e(t['compact_off'])}</span></button>
    <a class="lang" href="{t['other_href']}" hreflang="{t['other']}" lang="{t['other']}">{e(t['other_label'])}</a>
    <a class="btn btn-bar" href="#download">{e(t['nav_cta'])}</a>
  </div>
</header>
<main id="main">
<section class="hero" id="top" aria-labelledby="h1">
  <div class="hero-text" data-enter>
    <h1 id="h1" data-e>{e(t['h1'])}</h1>
    <p class="lead" data-e>{e(t['lead'])}</p>
    <a class="btn btn-hero" href="#download" data-e>{e(t['cta'])}</a>
  </div>
  <div class="hero-power">
    <button type="button" class="power power-l" data-power aria-pressed="false" aria-describedby="readout">{POWER_SVG}<span class="ring" aria-hidden="true"></span><span class="vh">{e(t['power_label'])}</span></button>
    <div class="readout" id="readout" aria-live="polite"><strong>{e(t['r_off_h'])}</strong><span>{e(t['r_off'])}</span></div>
  </div>
  <figure class="stage" dir="ltr">
    <div class="stage-img shutter"><img class="s-after" src="{a}spec-after-dark.webp" width="2400" height="840" alt="{e(t['spec_cap_on'])}"><img class="s-before" src="{a}spec-before-dark.webp" width="2400" height="840" alt="{e(t['spec_cap_off'])}"></div>
    <figcaption dir="{t['dir']}"><strong class="cap-state">{e(t['spec_cap_on'])}</strong><span>{e(t['spec_what'])}</span></figcaption>
  </figure>
</section>
{strip}
<section class="hear" id="hear" aria-label="{e(t['hear_h1'])} {e(t['hear_h2'])}">
  <div class="half half-in" data-enter>
    <figure dir="ltr" data-e><img src="{a}spec-before-dark.webp" width="2400" height="840" alt="{e(t['hear_in_cap'])}" loading="lazy"></figure>
    <p data-e>{e(t['hear_in'])}</p>
    <h2 data-e>{e(t['hear_h1'])}</h2>
  </div>
  <div class="half half-out" data-enter>
    <div class="player" data-ui data-e>
      <div class="pl-spec" dir="ltr"><img src="{a}spec-after-light.webp" width="1600" height="560" alt="{e(t['hear_out_cap'])}" loading="lazy"><i class="playhead"></i></div>
      <div class="pl-row">
        <button type="button" class="play" aria-pressed="false"><svg viewBox="0 0 24 24" aria-hidden="true"><path class="i-play" d="M8 5.5v13l11-6.5z"/><path class="i-pause" d="M7 5h3.6v14H7zM13.4 5H17v14h-3.6z"/></svg><span class="play-t">{e(t['play'])}</span></button>
        <span class="pl-time"><bdi dir="ltr"><span class="pl-now">0:00</span> / 0:10</bdi></span>
      </div>
      <audio preload="none"><source src="{a}filtered.webm" type="audio/webm; codecs=opus"><source src="{a}filtered.m4a" type="audio/mp4"></audio>
    </div>
    <p data-e>{e(t['hear_out'])}</p>
    <p class="credit" data-e>{e(t['hear_credit'])}</p>
    <h2 data-e>{e(t['hear_h2'])}</h2>
  </div>
</section>
{strip}
<section class="opts" aria-labelledby="opts-h">
  <h2 id="opts-h" class="vh">{e(t['opts_h'])}</h2>
  {opts}
</section>
{strip}
<section class="cover" id="cover" aria-labelledby="cover-h">
  <div class="cover-text" data-enter>
    <h2 id="cover-h" data-e>{e(t['cover_h'])}</h2>
    <p data-e>{e(t['cover_p'])}</p>
    <p class="note" data-e>{e(t['cover_note'])}</p>
  </div>
  <div class="cover-frag" data-ui>
    <div class="tools">
      <button type="button" class="tool cover-add">{e(t['cover_add'])}</button>
      <button type="button" class="tool cover-clear" disabled>{e(t['cover_clear'])} (<bdi class="n">0</bdi>)</button>
      <span class="tool-hint" aria-live="polite"></span>
    </div>
    <div class="pad"><img src="{a}speaker.webp" width="960" height="1067" alt="{e(t['cover_alt'])}" loading="lazy" draggable="false"><div class="covers"></div></div>
  </div>
</section>
{strip}
<section class="langs" id="lang" aria-labelledby="lang-h">
  <div class="langs-head" data-enter><h2 id="lang-h" data-e>{e(t['lang_h'])}</h2><p data-e>{e(t['lang_p'])}</p></div>
  <ul class="ltabs" aria-label="{e(t['lang_h'])}">{langs}</ul>
  <figure class="lshot"><img src="{a}lang/{lang}.webp" width="1366" height="768" alt="{e(t['lang_alt'].format(name=lname[lang]))}" loading="lazy"><figcaption>{e(t['lang_cap'].format(name=lname[lang]))}</figcaption></figure>
</section>
{strip}
<section class="wait" aria-labelledby="wait-h">
  <div class="card" data-ui>
    <p class="card-title">{e(t['card_title'])}</p>
    <div class="card-row"><span class="card-delay">{e(t['card_delay'])}</span><span class="card-demo">{e(t['card_demo'])}</span></div>
    <div class="card-state"><span class="dot"></span><strong class="st">{e(t['card_on'])}</strong></div>
    <p class="card-msg" aria-live="polite"></p>
    <div class="card-acts"><button type="button" class="cbtn c-stop">{e(t['card_stop'])}</button><button type="button" class="cbtn c-confirm" hidden>{e(t['card_confirm'])}</button><button type="button" class="cbtn c-cancel quiet" hidden>{e(t['card_cancel'])}</button></div>
  </div>
  <div class="wait-text" data-enter>
    <h2 id="wait-h" data-e>{e(t['wait_h'])}</h2>
    <p data-e>{e(t['wait_p'])}</p>
    <p class="note" data-e>{e(t['wait_limits'])}</p>
  </div>
</section>
{strip}
<section class="phones" aria-labelledby="phone-h">
  <h2 id="phone-h">{e(t['phone_h'])}</h2>
  <div class="tiles">{phones}</div>
</section>
{strip}
<section class="how" aria-labelledby="how-h">
  <h2 id="how-h">{e(t['how_h'])}</h2>
  <ol>{how}</ol>
</section>
{strip}
<section class="priv" aria-labelledby="priv-h">
  <div class="priv-text" data-enter>
    <h2 id="priv-h" data-e>{e(t['priv_h'])}</h2>
    <p data-e>{e(t['priv_p'])}</p>
    <ul class="facts" data-e>{facts}</ul>
  </div>
  <figure class="film"><video src="{a}waaiya-intro.mp4" poster="{a}waaiya-intro.jpg" width="540" height="960" controls playsinline muted loop preload="metadata" aria-label="{e(t['film_alt'])}"></video><figcaption>{e(t['film_cap'])}</figcaption></figure>
</section>
{strip}
<section class="faq" id="faq" aria-labelledby="faq-h">
  <div class="qs"><h2 id="faq-h">{e(t['faq_h'])}</h2>{qs}</div>
</section>
{strip}
<section class="dl" id="download" aria-labelledby="dl-h">
  <div class="dl-head"><h2 id="dl-h" class="dl-line">{e(t['cta'])}</h2><a class="btn dl-go" href="{APK}">{e(t['dl_btn'])}</a></div>
  <ul class="dl-rows">{rows}</ul>
  {sums}
</section>
</main>
<footer class="foot"><span>{e(t['foot_what'])}</span><nav>{foot_links}</nav><span>{e(t['foot_right'])}</span></footer>
<script type="application/json" id="i18n">{i18n_json}</script>
<script src="{a}{GSAP}"></script>
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
    body = md_to_html((HERE.parent / "docs/PRIVACY.md").read_text())
    body = body.replace('href="#سياسة-الخصوصية"', 'href="#ar"').replace('<div dir="rtl">', '<div dir="rtl" lang="ar" id="ar">')
    robots = '<meta name="robots" content="noindex">' if PREVIEW else ""
    return f"""<!doctype html>
<html lang="en" dir="ltr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Waaiya: {e(T['en']['privacy_title'])} · {e(T['ar']['privacy_title'])}</title>{robots}
<link rel="icon" href="{root}assets/logo.png">
<style>{fonts(root + 'assets/')}
{CSS}</style></head>
<body class="doc"><a class="doc-home" href="{root}{'en/' if lang == 'en' else ''}">Waaiya</a><main class="prose">{body}</main></body></html>
"""


LLMS = f"""# Waaiya (واعية)

> Waaiya is a free, open-source (AGPL) app for Android 10+, Windows 10 (2004)+ and Linux that removes musical
> instruments from the sound of every app, live (about 30 ms of delay), and keeps speech and Quran recitation.
> Optional screen blur for women or immodest images, prayer-time silence, a wait before turning off and a parent PIN.
> Everything runs on the device; nothing is sent anywhere.

## Pages

- [Waaiya, in Arabic]({SITE}): the main page
- [Waaiya, in English]({SITE}en/)
- [Privacy policy]({SITE}privacy.html)

## Downloads and source

- [Android: waaiya.apk {VERSION}]({APK})
- [Windows and Linux releases]({RELEASES}): the Windows zip is not signed yet; a Microsoft Store listing is under review
- [Source code]({REPO})
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
    (OUT / "llms.txt").write_text(LLMS)
    print("wrote", OUT, "(preview)" if PREVIEW else "")


if __name__ == "__main__":
    main()
