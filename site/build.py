#!/usr/bin/env python3
"""Builds the Waaiya landing page (waaiya.mssid.org): index.html (Arabic) and en/index.html (English) from one
template, plus privacy.html / en/privacy.html from docs/PRIVACY.md.

    python3 site/build.py              # writes site/public/
    python3 site/build.py --preview    # same, with noindex (for waaiya.mssid.org/preview/)
    site/deploy.sh [--preview]         # build and rsync to the host

The page asks nothing of any other server: the typeface (IBM Plex Sans Arabic, OFL) and GSAP are in assets/.
The exceptions are "try a link" (site/link/), only when the visitor submits a link, and the Google Play test sign-up
(/test/, site/test/), which posts to our own host only when the visitor sends the form.
Generated pictures and the filtered sound come from real material: see make_assets.py.
"""
import datetime
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
VERSION = "0.2.16"
INDEXNOW_KEY = "975a156c404dff8c423982350b431cc8"  # public by design: Bing, Yandex and others fetch /<key>.txt
VIDEO_DATE = "2026-11-21"  # the introduction video's upload date (VideoObject)
DL = "https://waaiya.mssid.org/downloads/"   # every download lives here (site/upload_downloads.sh); GitHub has the same files
APK = DL + "waaiya.apk"                      # the universal APK under a stable name
APK_ARM64 = DL + f"waaiya-v{VERSION}-arm64-v8a-release.apk"
APK_V7A = DL + f"waaiya-v{VERSION}-armeabi-v7a-release.apk"
WIN_ZIP = DL + f"waaiya-desktop-windows-x64-v{VERSION}.zip"
LINUX_DESKTOP = DL + f"waaiya-desktop-linux-x64-v{VERSION}.tar.gz"
LINUX_CLI = DL + f"waaiya-linux-x64-v{VERSION}.tar.gz"
SUMS = DL + "SHA256SUMS"
STORE = "https://apps.microsoft.com/detail/9NBB296FSRJP"  # Microsoft Store listing (Store ID 9NBB296FSRJP)
RELEASES = REPO + "/releases/latest"
GSAP = "js/gsap-3.15.0.min.js"
# "Try it on your sound" (site/try/, site/link/): the servers asked for a link, in order; empty hides the link box.
LINK_ENDPOINTS = ["https://waaiya.mssid.org/api/link.php", "https://link.waaiya.mssid.org/oracle",
                  "https://link.waaiya.mssid.org/mhost"]
ORT_VERSION = "1.20.1"   # onnxruntime-web, from the npm registry, checked below; files copied to assets/try/
ORT_TGZ_SHA256 = "0a38facf0672dfaaeaf352e8a9f44533732b60b4af93b9dd507fe7c2d2be437b"
ORT_FILES = ("ort.wasm.min.js", "ort-wasm-simd-threaded.mjs", "ort-wasm-simd-threaded.wasm")
MODEL_FILES = ("dfn3_stream_int8.onnx", "dfn3_stream_int8.state_init.bin")  # the app's voice model (models/SHA256SUMS)
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
        title="واعية: تطبيق يحذف الموسيقى والمعازف ويُبقي الكلام",
        desc="تطبيق مجاني مفتوح المصدر لأندرويد وويندوز ولينكس، يزيل الآلات الموسيقية من صوت كل التطبيقات لحظةً بلحظة، ويُبقي الكلام وتلاوة القرآن. لا يخرج شيء من جهازك.",
        nav=[("hear", "اسمع"), ("try", "جرّب"), ("cover", "تمويه الشاشة"), ("lang", "لغتك"), ("faq", "أسئلة")],
        nav_cta="حمّل",
        try_nav="جرّب",
        try_hero="أو جرّبها على ملف أو رابط",
        try_h="جرّبها بنفسك",
        try_p="اختر ملفًا من جهازك أو ألصق رابطًا. تعمل تصفية واعية الحقيقية هنا في متصفحك، ثم تنتقل بين «قبل» و«بعد» عند الموضع نفسه من المقطع.",
        try_file="اختر ملفًا من جهازك",
        try_file_note="ملف صوت أو فيديو. تُصفّى الدقيقة الأولى منه، وتظهر صورته معها إن كانت له صورة. لا يغادر الملف جهازك.",
        try_or="أو",
        try_link_label="رابط من يوتيوب أو تيك توك أو ساوند كلاود",
        try_link_btn="جرّب الرابط",
        try_link_note="يجلب أحدُ خوادمنا دقيقةً منه على الأكثر، صوتًا وصورةً صغيرة، بدءًا من الوقت المذكور في الرابط إن وُجد. ثم يُصفّى الصوت هنا على جهازك. لا نحفظ الرابط ولا المقطع.",
        try_idle="لم تختر شيئًا بعد.",
        try_delay="تسمع «بعد واعية» بتأخير التطبيق الحقيقي: نحو [[30]] ملّي ثانية. وإن كان للمقطع صورة، فقارن حركة الشفاه بالكلام.",
        try_before="قبل واعية", try_after="بعد واعية", try_ab="الصوت",
        try_js=dict(
            reading="قراءة الملف…", fetching="جلب دقيقة من الرابط…", next="تعذّر ذلك على هذا الخادم، نجرّب خادمًا آخر…",
            loading="تجهيز أداة التصفية (نحو [[6 MB]]، مرة واحدة فقط)…", filtering="التصفية على جهازك: [[{p}]]٪",
            ready="جاهز. انتقل بين «قبل» و«بعد» وأنت تستمع.", play="تشغيل", pause="إيقاف مؤقت",
            src_file="ملفك: {name}", src_link="من الرابط: {title}",
            err=dict(
                all="تعذّر جلب هذا الرابط الآن من خوادمنا كلّها. جرّب رابطًا آخر أو ملفًا من جهازك، أو افتحه في تطبيق واعية.",
                invalid_url="هذا ليس رابطًا صالحًا. ألصق رابط المقطع كاملًا.",
                unsupported_site="هذا الموقع غير مدعوم هنا. جرّب يوتيوب أو تيك توك أو ساوند كلاود، أو افتحه في تطبيق واعية.",
                playlist="هذه قائمة تشغيل أو قناة. ألصق رابط مقطع واحد.",
                live="هذا بثّ مباشر. ألصق رابط مقطع مسجَّل.",
                no_format="لم نجد صوتًا في هذا الرابط.",
                file_long="هذا الملف أطول مما يحتمله هذا المتصفح. قصّه أو اختر ملفًا أقصر.",
                decode="لم يستطع المتصفح قراءة هذا الملف. جرّب [[MP3]] أو [[M4A]] أو [[MP4]].",
                filter="تعذّرت التصفية على هذا الجهاز، فلن نُسمِعك شيئًا على أنه «بعد واعية».")),
        h1="يزيل المعازف ويُبقي الكلام",
        lead="تطبيق مجاني مفتوح المصدر لأندرويد وويندوز ولينكس. يزيل الآلات الموسيقية من صوت كل التطبيقات لحظةً بلحظة، ويُبقي الكلام وتلاوة القرآن. ولا يخرج شيء من جهازك.",
        cta="حمّل واعية",
        power_label="التصفية على هذه الصفحة",
        r_off="اضغط الزر: الخطوط الأفقية في هذه الصفحة صورةُ موسيقى حقيقية.",
        r_off_h="التصفية متوقفة",
        r_on_h="التصفية تعمل · تأخير نحو [[30]] ملّي ثانية",
        r_on="بقي الكلام وحده. اضغط مرة أخرى لإيقافها.",
        compact_off="متوقفة", compact_on="تعمل",
        spec_cap_off="قبل واعية", spec_cap_on="بعد واعية",
        spec_what="محاضرة بالعربية تحتها موسيقى · [[10]] ثوانٍ · الأصوات الحادّة في الأعلى والغليظة في الأسفل",
        hear_h1="ما يدخل", hear_h2="وما تسمعه",
        hear_in="قبل واعية: محاضرة بالعربية تحتها موسيقى، كما تصل من أي تطبيق. هذه صورتها فقط: لن نُسمِعك الموسيقى.",
        hear_in_cap="قبل واعية",
        hear_out_cap="بعد واعية",
        play="استمع إلى ما بعد واعية", pause="إيقاف مؤقت",
        hear_out="بعد واعية: الصوت نفسه بعد تصفية واعية الحقيقية، على الجهاز. وقِسنا الموسيقى وحدها قبل التصفية وبعدها، فخرجت أخفض بنحو [[37]] ديسيبل.",
        hear_credit="الكلام: [[Arabic Speech Corpus]]، نوّار حلبي، [[CC BY 4.0]]. الموسيقى صنعها المشروع للاختبار.",
        opts_h="خيارات بيدك",
        opts=[
            ("صمتٌ إن توقّفت التصفية من تلقاء نفسها", "إن أنهى النظام التصفية دون أن تطلب، تبقى التطبيقات صامتة حتى تشغّل التصفية من جديد، فلا تُسمَع الموسيقى.", True),
            ("صوت أحادي يوفّر البطارية", "الصوت الأحادي هو الافتراضي: يستهلك نحو نصف ما يستهلكه الستيريو، ويعمل بسلاسة على هواتف أكثر.", True),
            ("صمت الهاتف في أوقات الصلاة", "تُحسب الأوقات على الهاتف من مدينتك. مثلًا من الظهر [[12:00]] حتى [[12:20]]، مع رسالة قصيرة لمن يتصل.", False),
            ("كتم غناء النساء، للرجال", "اختياري، وما زال في بدايته: يلتقط جزءًا من الغناء في الأغاني الحقيقية، لا كلّه.", False),
            ("تطبيقات تُسمَع كما هي", "اختر تطبيقات لا تمرّ بالتصفية، أو تطبيقات لا يغطّيها التمويه.", False),
        ],
        cover_h="غطِّ بيدك ما فات التمويه",
        cover_p="«تمويه الشاشة» يغطّي النساء أو الصور غير المحتشمة في كل التطبيقات، على الجهاز نفسه. وإن فاتته صورة، فاضغط «تغطية جزء» واسحب إصبعك فوقها. جرّب ذلك على هذه الصورة.",
        cover_add="تغطية جزء", cover_clear="إزالة التغطية اليدوية", cover_hint="اسحب فوق الصورة.",
        cover_alt="مكبّر صوت عليه حبيبات رمل، من المقطع التعريفي بواعية",
        cover_note="تبقى مغطّاة حتى تزيلها أو يتوقف التمويه.",
        wait_h="الانتظار قبل الإيقاف",
        wait_p="اختر الآن، وأنت هادئ، مدةً للانتظار من دقيقة إلى [[24]] ساعة. وحين تضغط «إيقاف» بعد ذلك، تنتظر واعية حتى تنتهي المدة، ثم تقرّر من جديد. ويمكن للوالدين وضع رمز.",
        wait_limits="هذه حماية من لحظة ضعف، لا من شخص مُصِرّ: لا شيء يمنع الإيقاف الإجباري أو حذف التطبيق، وواعية تقول ذلك بوضوح.",
        card_title="حماية في لحظات الضعف",
        card_delay="الانتظار قبل الإيقاف: [[10]] ثوانٍ",
        card_demo="مختصَر لهذا العرض. في التطبيق تختار من دقيقة إلى [[24]] ساعة.",
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
        lang_p="[[18]] لغة، ويبدأ التطبيق على أندرويد بلغة هاتفك إن كانت منها. اختر لغة لترى بها صفحة التصفية على ويندوز.",
        lang_cap="واعية على ويندوز، صفحة التصفية: {name}",
        lang_alt="صفحة التصفية في واعية على ويندوز بلغة: {name}",
        phone_h="على هاتفك",
        phones=[("on", "التصفية", "زر واحد لكل التطبيقات"), ("screen", "الشاشة", "تمويه النساء والصور غير المحتشمة"),
                ("settings2", "أوقات الصلاة", "صمت، ورسالة لمن يتصل"), ("settings3", "الحماية", "الانتظار قبل الإيقاف، والرمز")],
        phone_meta="أندرويد [[15]]",
        how_h="كيف تبدأ",
        how=[
            ("أولًا، ثبّت واعية.", "ملف [[waaiya.apk]] لأندرويد [[10]] أو أحدث، أو نسخة ويندوز أو لينكس."),
            ("ثم الإعداد لمرة واحدة.", "على الهاتف نفسه، في أربع خطوات: [[Wi‑Fi]]، و«خيارات المطور»، و«تصحيح الأخطاء اللاسلكي»، ورمز الإقران. لكل خطوة صورة بلغتك، وتظهر عليها علامة الإتمام تلقائيًا حين تُنجزها."),
            ("ثم اضغط الزر.", "تُزال الآلات الموسيقية من كل التطبيقات. يبقى الإشعار ظاهرًا، وفيه زر الإيقاف."),
            ("وشغّل ما شئت.", "يوتيوب، إنستغرام، المتصفح، وأي تطبيق: محاضرة أو خبر أو وصفة، يصل الكلام وحده."),
        ],
        priv_h="لا يخرج شيء من جهازك",
        priv_p="التصفية وتمويه الشاشة يعملان على الجهاز. لا حساب، ولا إحصاءات، ولا إعلانات. وكل تغيير في الشيفرة يُختبر والإنترنت مقطوع عنه. والشيفرة كاملة على [[GitHub]] برخصة [[AGPL]]: يستطيع أي أحد أن يبني التطبيق منها ويقارنه بما ننشر.",
        facts=[("0", "اتصال بالإنترنت أثناء التصفية"), ("18", "لغة"), ("3", "أنظمة: أندرويد، ويندوز، لينكس"), ("30", "ملّي ثانية تأخير تقريبًا")],
        film_cap="مقطع تعريفي بواعية في [[52]] ثانية. صوته كلام فقط، بلا موسيقى.",
        film_alt="مقطع تعريفي بواعية",
        faq_h="أسئلة",
        faq=[
            ("هل يبقى الغناء والأناشيد؟", "لا، يُزال الغناء مع الآلات الموسيقية حاليًا، ويبقى الكلام والتلاوة. وللرجال خيار يكتم غناء النساء أيضًا، وهو ما زال في بدايته: يلتقط جزءًا من الغناء في الأغاني الحقيقية، لا كلّه."),
            ("هل يحتاج إلى الإنترنت؟", "لا. التصفية وتمويه الشاشة يعملان دون إنترنت. وحدها ميزة «فتح رابط» تتصل بموقع الرابط الذي تفتحه."),
            ("ما الإعداد لمرة واحدة؟", "يتيح لواعية كتم الصوت الأصلي للتطبيقات أثناء التصفية. يجري على الهاتف نفسه عبر «تصحيح الأخطاء اللاسلكي» في أربع خطوات، تظهر علامة الإتمام على كل منها تلقائيًا حين تُنجزها. ودونه تعمل واعية، لكنها تسأل قبل كل تشغيل."),
            ("هل يعمل على هاتفي؟", "أندرويد [[10]] أو أحدث. هواتف شاومي وأوبو وريلمي وون بلس لا تسمح للتطبيقات بالاحتفاظ ببعض الأذونات، فيتولّى مساعد واعية المهمة، دون إعداد مخفي تبحث عنه."),
            ("كم التأخير؟", "نحو [[30]] ملّي ثانية، أي أقل من عُشر ثانية، بين الصوت الأصلي وما تسمعه."),
            ("هل يستهلك البطارية؟", "الصوت الأحادي، وهو الافتراضي، يستهلك نحو نصف ما يستهلكه الستيريو. وفي واعية، يعرض «تقرير التشخيص» الاستهلاك في الساعة على هاتفك."),
            ("هل يمكن منعي من إيقافه في لحظة ضعف؟", "اختر مدة انتظار قبل أي إيقاف، ورمزًا إن شئت. لكن لا شيء يمنع حذف التطبيق أو إيقافه الإجباري من إعدادات أندرويد، وواعية تقول ذلك بوضوح."),
            ("وويندوز ولينكس؟", "ويندوز [[10 (2004)]] أو أحدث: واعية في متجر مايكروسوفت، مجانًا، ويتحدّث المتجر بنفسه. ويبقى ملف [[zip]] في أسفل هذه الصفحة وعلى [[GitHub]]، لكنه غير موقَّع، فقد يمنعه «التحكم الذكي في التطبيقات» في ويندوز. لينكس: تطبيق سطح المكتب، أو سطر الأوامر وحده."),
            ("من يقف وراءه؟", "مشروع مفتوح المصدر برخصة [[AGPL]]، شيفرته كاملة على [[GitHub]]. يستطيع أي أحد أن يبني التطبيق منها بنفسه ويقارنه بما ننشر."),
        ],
        dl_btn="حمّل", dl_store="من متجر مايكروسوفت",
        dl_for={"android": "حمّل واعية لأندرويد", "windows": "حمّل واعية لويندوز", "linux": "حمّل واعية للينكس"},
        dl_rows=[
            ("android", "أندرويد: [[waaiya.apk]]", APK, f"الإصدار [[{VERSION}]]، لكل أنواع الهواتف بأندرويد [[10]] أو أحدث · [[108 MB]]",
             [("نسخة أصغر لأغلب الهواتف · [[arm64-v8a]]", APK_ARM64, "[[90 MB]]"),
              ("للهواتف القديمة بنظام [[32]] بت · [[armeabi-v7a]]", APK_V7A, "[[88 MB]]"),
              ("انضمّ إلى اختبار واعية على [[Google Play]]", "test/", "بعنوان [[Gmail]]")]),
            ("windows", "ويندوز: واعية في متجر مايكروسوفت", STORE, "مجانًا، وموقَّع من مايكروسوفت، ويتحدّث تلقائيًا. ويندوز [[10 (2004)]] أو أحدث.",
             [("ملف [[zip]]: فُكَّ ضغطه وشغّل [[waaiya_desktop.exe]]", WIN_ZIP, "[[47 MB]] · غير موقَّع، فقد يمنعه «التحكم الذكي في التطبيقات» في ويندوز.")]),
            ("linux", "لينكس: تطبيق سطح المكتب", LINUX_DESKTOP, "لينكس [[x64]] · [[58 MB]]",
             [("سطر الأوامر وحده، بلا واجهة", LINUX_CLI, "[[9 MB]]")]),
        ],
        dl_sums=("تحقّق من الملفات بـ [[SHA256SUMS]]", "الملفات نفسها والشيفرة كاملة على [[GitHub]]"),
        foot_what="واعية · ﴿وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ﴾ الحاقة: [[12]]",
        foot_links=[("GitHub", REPO), ("الخصوصية", "privacy.html"), ("English", "en/")],
        foot_right="[[2026]] · مجاني ومفتوح المصدر",
        privacy_title="سياسة الخصوصية",
        shot_alt={"on": "صفحة التصفية في واعية والتصفية تعمل", "screen": "صفحة الشاشة: تمويه النساء والصور غير المحتشمة", "settings2": "أوقات الصلاة في الإعدادات", "settings3": "الانتظار قبل الإيقاف والرمز"},
    ),
    "en": dict(
        dir="ltr", other="ar", other_label="العربية", other_href="../",
        title="Waaiya: remove music from any app, keep the voice",
        desc="A free, open-source app for Android, Windows and Linux. It removes musical instruments from the sound of every app, live, and keeps speech and Quran recitation.",
        nav=[("hear", "Listen"), ("try", "Try it"), ("cover", "Screen blur"), ("lang", "Your language"), ("faq", "Questions")],
        nav_cta="Download",
        try_nav="Try it",
        try_hero="Or try it on a file or a link",
        try_h="Try it yourself",
        try_p="Pick a file from your device or paste a link. Waaiya's real filter runs here in your browser. Then switch between before and after at the same point in the clip.",
        try_file="Pick a file from your device",
        try_file_note="Audio or video. Its first minute is filtered, shown with its picture if it has one. The file never leaves your device.",
        try_or="or",
        try_link_label="A YouTube, TikTok or SoundCloud link",
        try_link_btn="Try the link",
        try_link_note="One of our servers fetches up to a minute of it, sound and a small picture, starting from the time in the link if it has one. The sound is then filtered here, on your device. We keep neither the link nor the clip.",
        try_idle="Nothing chosen yet.",
        try_delay="You hear \u201cAfter Waaiya\u201d with the app's real delay: about 30 milliseconds. If the clip has a picture, watch the lips against the voice.",
        try_before="Before Waaiya", try_after="After Waaiya", try_ab="Sound",
        try_js=dict(
            reading="Reading the file…", fetching="Fetching a minute from the link…", next="That server could not fetch it. Trying another…",
            loading="Loading the filter (about 6 MB, only once)…", filtering="Filtering on your device: {p}%",
            ready="Ready. Switch between before and after while you listen.", play="Play", pause="Pause",
            src_file="Your file: {name}", src_link="From the link: {title}",
            err=dict(
                all="None of our servers could fetch this link right now. Try another link or a file from your device, or open it in the Waaiya app.",
                invalid_url="That is not a valid link. Paste the full link of the clip.",
                unsupported_site="This site is not supported here. Try YouTube, TikTok or SoundCloud, or open it in the Waaiya app.",
                playlist="That is a playlist or a channel. Paste the link of one clip.",
                live="That is a live stream. Paste the link of a recorded clip.",
                no_format="We found no sound at this link.",
                file_long="This file is too long for this browser. Trim it or pick a shorter file.",
                decode="The browser could not read this file. Try MP3, M4A or MP4.",
                filter="Filtering failed on this device, so nothing is played as \u201cafter Waaiya\u201d.")),
        h1="Removes music, keeps the voice",
        lead="A free, open-source app for Android, Windows and Linux. It removes musical instruments from the sound of every app, live, and keeps speech and Quran recitation. Nothing leaves your device.",
        cta="Get Waaiya",
        power_label="Filtering on this page",
        r_off="Press the button: the horizontal lines on this page are a picture of real music.",
        r_off_h="Filtering is off",
        r_on_h="Filtering is on · about 30 ms of delay",
        r_on="Only the voice is left. Press again to turn it off.",
        compact_off="Off", compact_on="On",
        spec_cap_off="Before Waaiya", spec_cap_on="After Waaiya",
        spec_what="An Arabic lecture with music under it · 10 seconds · high-pitched sounds at the top, low-pitched at the bottom",
        hear_h1="What goes in", hear_h2="What you hear",
        hear_in="Before Waaiya: an Arabic lecture with music under it, as any app plays it. Only its picture: we will not play you the music.",
        hear_in_cap="Before Waaiya",
        hear_out_cap="After Waaiya",
        play="Listen to it after Waaiya", pause="Pause",
        hear_out="After Waaiya: the same sound after Waaiya's real filter, on the device. We also measured the music alone before and after filtering: it came out about 37 decibels quieter.",
        hear_credit="Voice: Arabic Speech Corpus, Nawar Halabi, CC BY 4.0. Music made by the project for testing.",
        opts_h="Choices in your hands",
        opts=[
            ("Silence if filtering stops by itself", "If the system ends filtering without you asking, apps stay silent until you start filtering again, so no music comes through.", True),
            ("Mono sound that saves battery", "Mono is the default: it uses about half of what stereo uses, and it runs smoothly on more phones.", True),
            ("A silent phone at prayer times", "The times are computed on the phone from your city. For example from Dhuhr at 12:00 until 12:20, with a text to whoever calls.", False),
            ("Mute women's singing, for men", "Optional, and still early: it catches part of the singing in real songs, not all of it.", False),
            ("Apps heard as they are", "Choose apps that skip filtering, or apps the screen blur leaves uncovered.", False),
        ],
        cover_h="Cover what the blur missed",
        cover_p="Screen blur covers women, or immodest images, in every app, on the device itself. If it misses a picture, tap “Cover an area” and drag your finger over it. Try it on this picture.",
        cover_add="Cover an area", cover_clear="Remove your covers", cover_hint="Drag over the picture.",
        cover_alt="A loudspeaker with grains of sand on it, from Waaiya's introduction video",
        cover_note="It stays covered until you remove it or the blur stops.",
        wait_h="Wait before turning off",
        wait_p="Set a wait now, while you are calm: from 1 minute to 24 hours. Later, when you press Stop, Waaiya waits until the time is up, and then you decide again. A parent can also set a PIN.",
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
        lang_p="18 languages. On Android, Waaiya starts in your phone's language if it has it. Pick one to see its Windows filter page.",
        lang_cap="Waaiya on Windows, the filter page: {name}",
        lang_alt="Waaiya's filter page on Windows in {name}",
        phone_h="On your phone",
        phones=[("on", "Filter", "One button for every app"), ("screen", "Screen", "Blur for women and immodest images"),
                ("settings2", "Prayer times", "Silence, and a text to callers"), ("settings3", "Protection", "Wait before turning off, and a PIN")],
        phone_meta="Android 15",
        how_h="How to start",
        how=[
            ("First, install Waaiya.", "waaiya.apk for Android 10 or newer. Or the Windows and Linux apps."),
            ("Then set it up once.", "On the phone itself, in four steps: Wi‑Fi, Developer options, Wireless debugging and the pairing code. Each step has a picture in your language and is checked off automatically when you finish it."),
            ("Then press the button.", "Musical instruments are removed from every app. The notification stays, with its Stop button."),
            ("And play anything.", "YouTube, Instagram, the browser, any app: a lecture, the news, a recipe, only the voice comes through."),
        ],
        priv_h="Nothing leaves your device",
        priv_p="Filtering and screen blur run on the device. No account, no analytics, no ads. Every change to the code is tested with the internet cut off. All the code is on GitHub under the AGPL: anyone can build the app from it and compare it with what we publish.",
        facts=[("0", "internet connections while filtering"), ("18", "languages"), ("3", "platforms: Android, Windows, Linux"), ("30", "milliseconds of delay, roughly")],
        film_cap="An introduction to Waaiya in 52 seconds. Its sound is voice only, with no music.",
        film_alt="Waaiya introduction video",
        faq_h="Questions",
        faq=[
            ("Are singing and nasheeds kept?", "No. For now, singing is removed with the musical instruments, and speech and recitation stay. Men also have an option that mutes women's singing. It is still early: it catches part of the singing in real songs, not all of it."),
            ("Does it need the internet?", "No. Filtering and screen blur work offline. Only the “Open a link” feature contacts the site of the link you open."),
            ("What is the one-time setup?", "It lets Waaiya silence the original sound of the apps while it filters. It runs on the phone itself through Wireless debugging, in four steps, each checked off automatically as you finish it. Without it Waaiya still works, but asks before each start."),
            ("Will it work on my phone?", "Android 10 or newer. Xiaomi, OPPO, realme and OnePlus phones do not let apps keep some permissions, so Waaiya's helper takes over, with no hidden setting to find."),
            ("How much delay?", "About 30 milliseconds, less than a tenth of a second, between the original sound and what you hear."),
            ("Does it drain the battery?", "Mono sound, the default, uses about half of what stereo uses. The Diagnostics report in Waaiya shows the use per hour on your phone."),
            ("Can I be stopped from turning it off in a weak moment?", "Choose a wait before turning off, and a PIN if you like. But nothing can prevent uninstalling or a force stop from Android's settings, and Waaiya says so plainly."),
            ("Windows and Linux?", "Windows 10 (2004) or newer: Waaiya is in the Microsoft Store, free, and the Store keeps it up to date. The zip at the bottom of this page and on GitHub is still there, but it is not signed, so Windows Smart App Control may block it. Linux: the desktop app, or the command line alone."),
            ("Who is behind it?", "An open-source project under the AGPL, with all its code on GitHub. Anyone can build the app from it and compare it with what we publish."),
        ],
        dl_btn="Download", dl_store="Get it from the Microsoft Store",
        dl_for={"android": "Get Waaiya for Android", "windows": "Get Waaiya for Windows", "linux": "Get Waaiya for Linux"},
        dl_rows=[
            ("android", "Android: waaiya.apk", APK, f"Version {VERSION}, for every kind of phone with Android 10 or newer · 108 MB",
             [("Smaller, for most phones · arm64-v8a", APK_ARM64, "90 MB"),
              ("For older 32-bit phones · armeabi-v7a", APK_V7A, "88 MB"),
              ("Join the test on Google Play", "test/", "with your Gmail address")]),
            ("windows", "Windows: Waaiya in the Microsoft Store", STORE, "Free, signed by Microsoft, updates itself. Windows 10 (2004) or newer.",
             [("The zip: unpack it and run waaiya_desktop.exe", WIN_ZIP, "47 MB · not signed, so Windows Smart App Control may block it.")]),
            ("linux", "Linux: the desktop app", LINUX_DESKTOP, "Linux x64 · 58 MB",
             [("Command line only, no window", LINUX_CLI, "9 MB")]),
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


def icons(a):
    """The tab icon: drawn at 16, 32 and 48 px (desktop/tool/make_icons.py --site), where the ear's arc stays apart from
    the letter; scaled down from the 192 px logo, only a plain ع was seen."""
    return (f'<link rel="icon" type="image/png" sizes="16x16" href="{a}favicon-16.png">'
            f'<link rel="icon" type="image/png" sizes="32x32" href="{a}favicon-32.png">'
            f'<link rel="icon" type="image/png" sizes="48x48" href="{a}favicon-48.png">'
            f'<link rel="icon" type="image/png" sizes="192x192" href="{a}logo.png">')


def mark(cls, draw=False):
    """The logo: the ع of واعية drawn as an ear («أذنٌ واعية»); the small arc in its bowl is the sound it keeps.
    Source: /srv/build/waaiya-logo (ain-ear), 120-unit grid. With draw=True the strokes draw on once."""
    d = ' class="strike draw"' if draw else ""
    return (f'<svg class="{cls}" viewBox="0 0 120 120" aria-hidden="true" focusable="false">'
            f'<g transform="translate(12 12) scale(0.8)" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">'
            f'<path{d} pathLength="1" stroke-width="13" d="M80.2 22.15 A14.5 14.5 0 1 0 74.67 44.33 A31 31 0 1 0 89.43 86.01"/>'
            f'<path{d} pathLength="1" stroke-width="9" d="M66.01 60.2 A13 13 0 1 0 66.01 84.64" style="animation-delay:700ms"/></g></svg>')


def jsonld(lang, t, root_url):
    app = {
        "@context": "https://schema.org", "@type": "SoftwareApplication",
        "name": "Waaiya", "alternateName": "واعية", "url": root_url,
        "description": plain(t["desc"]), "inLanguage": [c for c, _ in LANGS],
        "applicationCategory": "MultimediaApplication",
        "operatingSystem": "Android 10+, Windows 10 (2004)+, Linux",
        "softwareVersion": VERSION, "downloadUrl": APK,
        "license": "https://www.gnu.org/licenses/agpl-3.0.html",
        "isAccessibleForFree": True, "sameAs": [REPO, STORE],
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "image": SITE + "assets/og.jpg",
        "screenshot": SITE + f"assets/{lang}-on.webp",
    }
    faq = {"@context": "https://schema.org", "@type": "FAQPage", "inLanguage": lang,
           "mainEntity": [{"@type": "Question", "name": plain(q), "acceptedAnswer": {"@type": "Answer", "text": plain(ans)}} for q, ans in t["faq"]]}
    video = {"@context": "https://schema.org", "@type": "VideoObject", "name": plain(t["film_alt"]),
             "description": plain(t["film_cap"]), "inLanguage": "ar", "uploadDate": VIDEO_DATE, "duration": "PT52S",
             "thumbnailUrl": SITE + "assets/waaiya-intro.jpg", "contentUrl": SITE + "assets/waaiya-intro.mp4"}
    return json.dumps([app, faq, video], ensure_ascii=False).replace("</", "<\\/")


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
        main_html = f'<a class="dl-main" href="{href}">{e(main)}</a>'
        more_html = "".join(f'<li><a href="{h}">{e(n)}</a> <span>{e(x)}</span></li>' for n, h, x in more)
        rows += f'<li data-plat="{k}">{main_html}<p>{e(note)}</p><ul class="dl-more">{more_html}</ul></li>'
    sums = f'<p class="dl-sums"><a href="{SUMS}">{e(t["dl_sums"][0])}</a> · <a href="{RELEASES}">{e(t["dl_sums"][1])}</a></p>'
    foot_links = "".join(f'<a href="{html.escape(h)}">{e(n)}</a>' for n, h in t["foot_links"])

    i18n = {k: plain(t[k]) for k in ("r_off", "r_off_h", "r_on", "r_on_h", "compact_off", "compact_on", "spec_cap_off", "spec_cap_on",
                                     "play", "pause", "cover_clear", "cover_hint", "card_on", "card_off", "card_stop", "card_start", "card_wait",
                                     "card_left", "card_ready", "card_done", "card_hint", "card_kept", "lang_cap", "lang_alt", "dl_btn", "dl_store")}
    i18n["dl_for"] = t["dl_for"]
    i18n["names"] = lname
    i18n["apk"] = APK
    i18n["releases"] = RELEASES
    i18n["linux"] = LINUX_DESKTOP
    i18n["store"] = STORE
    def plain_tree(v):
        return {k: plain_tree(x) for k, x in v.items()} if isinstance(v, dict) else plain(v)
    i18n["try"] = plain_tree(t["try_js"])
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
<meta property="og:site_name" content="{'واعية' if rtl else 'Waaiya'}">
<meta property="og:image" content="{SITE}assets/og.jpg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="{html.escape(plain(t['cover_alt']))}">
<meta property="og:locale" content="{'ar_AR' if rtl else 'en_US'}">
<meta property="og:locale:alternate" content="{'en_US' if rtl else 'ar_AR'}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{html.escape(t['title'])}">
<meta name="twitter:description" content="{html.escape(t['desc'])}">
<meta name="twitter:image" content="{SITE}assets/og.jpg">
<meta name="theme-color" content="#053D35">
{icons(a)}
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
    <a class="hero-try" href="#try" data-e>{e(t['try_hero'])}</a>
  </div>
  <div class="hero-power">
    <button type="button" class="power power-l" data-power aria-pressed="false" aria-describedby="readout">{POWER_SVG}<span class="ring" aria-hidden="true"></span><span class="vh">{e(t['power_label'])}</span></button>
    <div class="readout" id="readout" aria-live="polite"><strong>{e(t['r_off_h'])}</strong><span>{e(t['r_off'])}</span></div>
  </div>
  <figure class="film hero-film"><video src="{a}waaiya-intro.mp4" poster="{a}waaiya-intro.jpg" width="540" height="960" controls playsinline muted loop preload="metadata" aria-label="{e(t['film_alt'])}"></video><figcaption>{e(t['film_cap'])}</figcaption></figure>
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
<section class="try" id="try" aria-labelledby="try-h" data-base="{a}try/" data-endpoints='{json.dumps(LINK_ENDPOINTS)}'>
  <div class="try-text" data-enter>
    <h2 id="try-h" data-e>{e(t['try_h'])}</h2>
    <p data-e>{e(t['try_p'])}</p>
  </div>
  <div class="try-tool" data-ui>
    <div class="try-file"><input type="file" accept="audio/*,video/*" hidden tabindex="-1"><button type="button" class="btn try-pick">{e(t['try_file'])}</button><p>{e(t['try_file_note'])}</p></div>
    <p class="try-or" aria-hidden="true"><span>{e(t['try_or'])}</span></p>
    <form class="try-link" novalidate><label for="try-url">{e(t['try_link_label'])}</label><div class="try-row"><input id="try-url" type="url" inputmode="url" dir="ltr" autocomplete="off" spellcheck="false" placeholder="https://youtu.be/…"><button type="submit" class="btn try-go">{e(t['try_link_btn'])}</button></div><p>{e(t['try_link_note'])}</p></form>
    <div class="try-out">
      <p class="try-status" role="status" aria-live="polite">{e(t['try_idle'])}</p>
      <div class="try-bar" aria-hidden="true"><i></i></div>
      <div class="try-deck" hidden>
        <p class="try-src" dir="auto"></p>
        <video class="try-video" muted playsinline preload="auto" hidden></video>
        <div class="try-ab" role="group" aria-label="{e(t['try_ab'])}"><button type="button" data-side="before" aria-pressed="false">{e(t['try_before'])}</button><button type="button" data-side="after" aria-pressed="true">{e(t['try_after'])}</button></div>
        <div class="try-row try-play-row"><button type="button" class="play try-play" aria-pressed="false"><svg viewBox="0 0 24 24" aria-hidden="true"><path class="i-play" d="M8 5.5v13l11-6.5z"/><path class="i-pause" d="M7 5h3.6v14H7zM13.4 5H17v14h-3.6z"/></svg><span>{e(t['try_js']['play'])}</span></button><input class="try-seek" type="range" min="0" max="600" step="1" value="0" aria-label="{e(t['try_ab'])}" dir="ltr"><span class="pl-time"><bdi dir="ltr"><span class="try-now">0:00</span> / <span class="try-len">0:00</span></bdi></span></div>
        <p class="try-delay">{e(t['try_delay'])}</p>
      </div>
    </div>
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
<script src="{a}try/try.js" defer></script>
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
<meta name="description" content="What Waaiya does with your data: the filter and the screen blur work on your device and send nothing. سياسة الخصوصية لتطبيق واعية.">
<link rel="canonical" href="{SITE}privacy.html">
{icons(root + 'assets/')}
<style>{fonts(root + 'assets/')}
{CSS}</style></head>
<body class="doc"><a class="doc-home" href="{root}{'en/' if lang == 'en' else ''}">Waaiya</a><main class="prose">{body}</main></body></html>
"""


# ---------- /usb/: the one-time Android setup from a computer, over WebUSB (site/usb/) ----------
# Static texts render here; the script's messages go to the page as JSON (#usb-text). {model} is filled in by setup.js.
USB = {
    "en": dict(
        dir="ltr", title="Set up Waaiya from a computer",
        desc="Give Waaiya its one-time Android permissions from Chrome or Edge over a USB cable. Nothing to install.",
        lead="Nothing to install: in Chrome or Edge, this page talks to your phone over the USB cable and gives Waaiya the "
             "same permissions as the setup on the phone. It also works on Android 10 and on phones without "
             "Wireless debugging.",
        steps=["Install Waaiya on the phone ({apk}).",
               "Turn on Developer options: in Settings › About phone, tap “Build number” 7 times (Samsung: About phone › "
               "Software information; Xiaomi: “OS version”).",
               "In Developer options, turn on “USB debugging”.",
               "Connect the phone to this computer with a USB cable, unlock it, and press the button."],
        apk="waaiya.apk", button="Connect the phone",
        privacy="The page runs in your browser and talks only to the phone: nothing is sent anywhere. It keeps a key in "
                "this browser so the phone can remember the computer (“Revoke USB debugging authorizations” in "
                "Developer options makes the phone forget it).",
        log="What was run on the phone", source="Source", home="Waaiya",
        js=dict(
            choose="Choose your phone in the browser's list.",
            opening="Opening the phone…",
            allow="On the phone: “Allow USB debugging?” Tick “Always allow from this computer”, then tap Allow.",
            allowWhy="This lets the page run the setup commands. If nothing shows, unlock the phone, or unplug it and "
                     "plug it in again.",
            step_phone="Reading the phone…", step_grants="Giving Waaiya its permissions…",
            step_helper="This phone refused the permissions: starting Waaiya's helper instead…",
            thePhone="the phone",
            done="Done: Waaiya has its permissions on {model}.",
            noProjectMedia="This phone does not keep the permission that skips Android's screen-sharing question, so "
                           "Android will ask at every start (vivo and iQOO phones do this).",
            doneAfter="Unplug the phone and open Waaiya: its setup page ticks itself. You can turn USB debugging off "
                      "again; the permissions stay until Waaiya is uninstalled.",
            helper="{model} refused the permissions, so Waaiya's helper now lists the sound for it instead.",
            helperAfter="Open Waaiya now, and leave USB debugging on. The helper stops when the phone restarts or USB "
                        "debugging is turned off: then connect here again, or do Waaiya's own setup on the phone "
                        "once (Wireless debugging) and it restarts the helper by itself.",
            tipXiaomi="To keep the permissions for good: in Developer options, turn on “USB debugging (Security "
                      "settings)” (it asks you to sign in to a Xiaomi account), then connect again.",
            tipColoros="To keep the permissions for good: in Developer options, turn on “Disable permission "
                       "monitoring” (on the newest versions “Disable system optimization”, sometimes shown only with "
                       "the phone in English), then connect again.",
            refused="This phone refused the permissions.",
            refusedOld="Waaiya's helper needs Android 11 or newer, so on this phone the permissions must be allowed "
                       "in Developer options (Xiaomi: “USB debugging (Security settings)”; OPPO, OnePlus, realme: "
                       "“Disable permission monitoring”).",
            refusedOther="Check that the phone is unlocked and connect again. If it keeps refusing, copy what was run "
                         "(below) and send it to us on GitHub.",
            noApp="Waaiya is not installed on this phone. Install it first (waaiya.mssid.org/downloads/), then connect "
                  "again.",
            tooOld="Waaiya needs Android 10 or newer.",
            unsupported="This browser cannot reach USB devices. Open this page in Chrome, Edge or another Chromium "
                        "browser, on Windows, macOS, Linux or ChromeOS.",
            err_unsupported="This browser cannot reach USB devices.",
            err_none="No phone was chosen. If the list was empty: unlock the phone, check that USB debugging is on, and "
                     "try another cable (some cables only charge).",
            err_noadb="That device has no USB debugging. Turn on “USB debugging” in Developer options and choose "
                      "the phone again.",
            err_access="The browser was not allowed to open the phone.",
            accessWindows="On Windows the phone needs the WinUSB driver: some phone makers' drivers block it. Install "
                          "Google's USB driver, or try another computer.",
            accessLinux="On Linux, install your distribution's android-udev-rules package (or add a udev rule for the "
                        "phone), then unplug the phone and plug it in again.",
            accessOther="Unplug the phone, plug it in again and retry.",
            err_busy="Another program is using the phone: close Android Studio or phone manager apps, and if adb is "
                     "installed run “adb kill-server”. Then try again.",
            err_io="The connection to the phone broke off. Unplug it, plug it in again and retry.",
            lost="The phone was disconnected. Plug it in again and retry.",
            error="Something went wrong. Unplug the phone, plug it in again and retry.",
        )),
    "ar": dict(
        dir="rtl", title="إعداد واعية من حاسوب",
        desc="امنح واعية أذونات أندرويد مرة واحدة من متصفح Chrome أو Edge عبر كابل USB، دون تثبيت أي برنامج.",
        lead="لا حاجة إلى تثبيت شيء: في متصفح Chrome أو Edge، تتصل هذه الصفحة بهاتفك عبر كابل USB وتمنح واعية الأذونات "
             "نفسها التي يمنحها الإعداد على الهاتف. وتعمل أيضًا على أندرويد 10 وعلى الهواتف التي ليس فيها "
             "«تصحيح الأخطاء اللاسلكي».",
        steps=["ثبّت واعية على الهاتف ({apk}).",
               "فعّل «خيارات المطور»: في الإعدادات › «حول الهاتف»، اضغط على «رقم الإصدار» 7 مرات (سامسونج: «حول الهاتف» › "
               "«معلومات البرنامج»؛ شاومي: «إصدار النظام»).",
               "في «خيارات المطور»، فعّل «تصحيح أخطاء USB».",
               "وصّل الهاتف بهذا الحاسوب بكابل USB، وافتح قفله، ثم اضغط الزر."],
        apk="waaiya.apk", button="وصّل الهاتف",
        privacy="تعمل الصفحة في متصفحك ولا تتصل إلا بالهاتف: لا يُرسَل شيء إلى أي مكان. وتحفظ في هذا المتصفح مفتاحًا "
                "ليتذكّر الهاتف هذا الحاسوب (يُنسيه الهاتفَ خيارُ «إبطال تفويضات تصحيح أخطاء USB» في «خيارات المطور»).",
        log="ما نُفِّذ على الهاتف", source="المصدر", home="واعية",
        js=dict(
            choose="اختر هاتفك من قائمة المتصفح.",
            opening="جارٍ فتح الهاتف…",
            allow="على الهاتف: «هل تريد السماح بتصحيح أخطاء USB؟» ضع علامة على «السماح دائمًا من هذا الكمبيوتر»، ثم اضغط «سماح».",
            allowWhy="هذا يتيح للصفحة تنفيذ أوامر الإعداد. إن لم يظهر شيء، فافتح قفل الهاتف، أو افصله ثم وصّله من جديد.",
            step_phone="جارٍ قراءة الهاتف…", step_grants="جارٍ منح واعية أذوناتها…",
            step_helper="رفض الهاتف منح الأذونات: جارٍ تشغيل مساعد واعية بدلًا منها…",
            thePhone="الهاتف",
            done="تمّ: صارت لواعية أذوناتها على {model}.",
            noProjectMedia="هذا الهاتف لا يحتفظ بالإذن الذي يتخطّى سؤال أندرويد عن مشاركة الشاشة، فسيسأل أندرويد عند كل "
                           "تشغيل (تفعل ذلك هواتف vivo وiQOO).",
            doneAfter="افصل الهاتف وافتح واعية: صفحة الإعداد تؤشّر خطواتها وحدها. ويمكنك إيقاف «تصحيح أخطاء USB» من "
                      "جديد؛ تبقى الأذونات حتى تُحذف واعية.",
            helper="رفض {model} منح الأذونات، فصار مساعد واعية يقرأ الأصوات بدلًا منها.",
            helperAfter="افتح واعية الآن، واترك «تصحيح أخطاء USB» مفعّلًا. يتوقف المساعد عند إعادة تشغيل الهاتف أو عند "
                        "إيقاف «تصحيح أخطاء USB»: فوصّل الهاتف هنا من جديد، أو أتمّ إعداد واعية على الهاتف مرة واحدة "
                        "(«تصحيح الأخطاء اللاسلكي») فتعيد تشغيل المساعد وحدها.",
            tipXiaomi="للاحتفاظ بالأذونات نهائيًا: فعّل في «خيارات المطور» «تصحيح أخطاء USB (إعدادات الأمان)» (يطلب "
                      "تسجيل الدخول إلى حساب شاومي)، ثم وصّل الهاتف من جديد.",
            tipColoros="للاحتفاظ بالأذونات نهائيًا: فعّل في «خيارات المطور» «تعطيل مراقبة الأذونات» (اسمه في أحدث "
                       "الإصدارات «تعطيل تحسين النظام»، وقد لا يظهر إلا إذا كانت لغة الهاتف الإنجليزية)، ثم وصّل "
                       "الهاتف من جديد.",
            refused="رفض الهاتف منح الأذونات.",
            refusedOld="مساعد واعية يحتاج إلى أندرويد 11 أو أحدث، فلا بد في هذا الهاتف من السماح بالأذونات في «خيارات "
                       "المطور» (شاومي: «تصحيح أخطاء USB (إعدادات الأمان)»؛ أوبو وون بلس وريلمي: «تعطيل مراقبة الأذونات»).",
            refusedOther="تأكّد أن الهاتف مفتوح القفل ثم وصّله من جديد. وإن ظل يرفض، فانسخ ما نُفِّذ (في الأسفل) "
                         "وأرسله إلينا على GitHub.",
            noApp="واعية غير مثبّتة على هذا الهاتف. ثبّتها أولًا (waaiya.mssid.org/downloads/)، ثم وصّل الهاتف من جديد.",
            tooOld="تحتاج واعية إلى أندرويد 10 أو أحدث.",
            unsupported="هذا المتصفح لا يصل إلى أجهزة USB. افتح هذه الصفحة في Chrome أو Edge أو متصفح آخر مبني على "
                        "Chromium، على ويندوز أو ماك أو لينكس أو ChromeOS.",
            err_unsupported="هذا المتصفح لا يصل إلى أجهزة USB.",
            err_none="لم يُختر أي هاتف. إن كانت القائمة فارغة: افتح قفل الهاتف، وتأكّد أن «تصحيح أخطاء USB» مفعّل، "
                     "وجرّب كابلًا آخر (بعض الكابلات للشحن فقط).",
            err_noadb="هذا الجهاز ليس فيه «تصحيح أخطاء USB». فعّله في «خيارات المطور» ثم اختر الهاتف من جديد.",
            err_access="لم يُسمح للمتصفح بفتح الهاتف.",
            accessWindows="في ويندوز يحتاج الهاتف إلى تعريف WinUSB، وبعض تعريفات الشركات المصنّعة تمنعه. ثبّت تعريف USB "
                          "من Google، أو جرّب حاسوبًا آخر.",
            accessLinux="في لينكس، ثبّت حزمة android-udev-rules من توزيعتك (أو أضف قاعدة udev للهاتف)، ثم افصل الهاتف "
                        "ووصّله من جديد.",
            accessOther="افصل الهاتف ووصّله من جديد، ثم أعد المحاولة.",
            err_busy="برنامج آخر يستعمل الهاتف: أغلق Android Studio أو برامج إدارة الهاتف، وإن كان adb مثبّتًا فنفّذ "
                     "«adb kill-server». ثم أعد المحاولة.",
            err_io="انقطع الاتصال بالهاتف. افصله ووصّله من جديد، ثم أعد المحاولة.",
            lost="فُصل الهاتف. وصّله من جديد ثم أعد المحاولة.",
            error="حدث خطأ. افصل الهاتف ووصّله من جديد، ثم أعد المحاولة.",
        )),
}
USB_FILES = ("adb.js", "usb.js", "flow.js", "setup.js")


def usb_page(lang, root):
    u = USB[lang]
    other, other_label, other_href = ("en", "English", "en/usb/") if lang == "ar" else ("ar", "العربية", "usb/")
    robots = '<meta name="robots" content="noindex">' if PREVIEW else ""
    home = root + ("en/" if lang == "en" else "")
    link = '<a href="' + APK + '">' + e(u["apk"]) + "</a>"
    steps = "".join("<li>" + e(s).replace("{apk}", link) + "</li>" for s in u["steps"])
    text = json.dumps(u["js"], ensure_ascii=False).replace("</", "<\\/")
    return f"""<!doctype html>
<html lang="{lang}" dir="{u['dir']}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(u['title'])} · Waaiya</title>{robots}
<meta name="description" content="{e(u['desc'])}">
<link rel="canonical" href="{SITE}{'en/' if lang == 'en' else ''}usb/">
<link rel="alternate" hreflang="ar" href="{SITE}usb/"><link rel="alternate" hreflang="en" href="{SITE}en/usb/">
{icons(root + 'assets/')}
<style>{fonts(root + 'assets/')}
{CSS}</style></head>
<body class="doc"><a class="doc-home" href="{home}">{e(u['home'])}</a>
<a class="doc-lang" href="{root}{other_href}" lang="{other}" hreflang="{other}">{other_label}</a>
<main class="prose usb">
<h1>{e(u['title'])}</h1>
<p class="usb-lead">{e(u['lead'])}</p>
<ol class="usb-steps">{steps}</ol>
<p><button id="usb-connect" class="cbtn" type="button">{e(u['button'])}</button></p>
<div id="usb-status" class="usb-status" role="status" aria-live="polite" tabindex="-1" hidden></div>
<details id="usb-log" class="usb-log" hidden><summary>{e(u['log'])}</summary><pre id="usb-log-text" dir="ltr"></pre></details>
<p class="usb-privacy">{e(u['privacy'])} <a href="{REPO}/tree/main/site/usb">{e(u['source'])}</a></p>
</main>
<script type="application/json" id="usb-text">{text}</script>
<script type="module" src="{root}assets/usb/setup.js"></script>
</body></html>
"""


# ---------- /test/: sign up for the Google Play test (site/test/) ----------
# The form posts to {root}api/test-signup.php (site/test/signup.php, copied by main()): on the live site /api/, on the
# preview /preview/api/. The endpoint keeps the list outside the docroot and tells the owner on Telegram.
TEST = {
    "ar": dict(
        dir="rtl", home="واعية", home_href="", privacy_href="privacy.html",
        title="انضمّ إلى اختبار واعية على [[Google Play]]",
        desc="واعية في طريقها إلى [[Google Play]]. سجّل عنوان [[Gmail]] لتُدعى إلى اختبارها على هاتفك قبل نشرها للجميع.",
        lead="واعية في طريقها إلى متجر [[Google Play]]. وقبل أن تُنشر للجميع، يطلب [[Google]] أن يجرّبها مختبرون مدة "
             "أسبوعين. اكتب عنوان [[Gmail]]، أو عنوان حساب [[Google]] الذي تستعمله في [[Google Play]] على هاتفك، "
             "فنضيفك إلى قائمة المختبرين.",
        steps_h="ما معنى الاختبار؟",
        steps=["نضيف عنوانك إلى قائمة المختبرين في [[Google Play]]، ثم يصلك رابط الانضمام إلى الاختبار.",
               "افتح الرابط على هاتفك الأندرويد بحساب [[Google]] نفسه، ووافق على الانضمام، ثم ثبّت واعية من "
               "[[Google Play]] كأي تطبيق.",
               "أبقِها مثبّتة [[14]] يومًا على الأقل: هذا ما يطلبه [[Google]] قبل نشر التطبيق للجميع. واستعملها كما تشاء."],
        email_label="عنوان [[Gmail]]، أو عنوان حسابك في [[Google]]",
        email_note="العنوان الذي تستعمله في [[Google Play]] على هاتفك.",
        name_label="اسمك (اختياري)",
        submit="أضفني إلى الاختبار",
        use_note="لا نستعمل عنوانك إلا لدعوتك إلى هذا الاختبار: لا يُنشر، ولا يُعطى لأحد، ولا نستعمله لغير ذلك. يُحفظ "
                 "في قائمة على خادم موقعنا، ويصل إلى المطوّر عبر [[Telegram]] ليضيفه في [[Google Play Console]].",
        privacy="سياسة الخصوصية",
        remove_h="أزل عنواني من الاختبار",
        remove_p="اكتب العنوان نفسه، فنحذفه من القائمة ومن الاختبار في [[Google Play]].",
        remove_btn="أزل عنواني",
        js=dict(
            sending="جارٍ الإرسال…",
            done="شكرًا! وصلنا عنوانك. سنضيفه إلى قائمة المختبرين، ثم يصلك رابط الانضمام إلى الاختبار.",
            removed="تمّ. إن كان هذا العنوان في القائمة فقد حُذف منها، وسنحذفه من الاختبار في [[Google Play]].",
            invalid_email="هذا لا يبدو عنوان بريد صحيحًا. تحقّق منه ثم أعد المحاولة.",
            rate="محاولات كثيرة من هذا الاتصال. أعد المحاولة بعد ساعة.",
            failed="تعذّر الإرسال الآن. أعد المحاولة بعد دقائق.",
            oops="لم يُرسَل شيء: تحقّق من العنوان ثم أعد المحاولة، أو أعدها بعد قليل.")),
    "en": dict(
        dir="ltr", home="Waaiya", home_href="en/", privacy_href="en/privacy.html",
        title="Join the Waaiya test on Google Play",
        desc="Waaiya is coming to Google Play. Sign up with your Gmail address to be invited to test it on your phone "
             "before it is published for everyone.",
        lead="Waaiya is on its way to Google Play. Before it can be published for everyone, Google asks for testers to "
             "try it for two weeks. Enter your Gmail address, or the address of the Google account you use for Google "
             "Play on your phone, and we will add you to the testers.",
        steps_h="What testing means",
        steps=["We add your address to the testers list in Google Play, and you get a link to join the test.",
               "Open the link on your Android phone, with the same Google account, accept to become a tester, then "
               "install Waaiya from Google Play like any app.",
               "Keep it installed for at least 14 days: Google asks for this before an app is published for everyone. "
               "Use it as you like."],
        email_label="Gmail address, or the address of your Google account",
        email_note="The one you use for Google Play on your phone.",
        name_label="Your name (optional)",
        submit="Invite me to the test",
        use_note="Your address is used only to invite you to this test: it is not published, not given to anyone and "
                 "not used for anything else. It is kept in a list on our website's server and sent to the developer "
                 "over Telegram, to be added in Google Play Console.",
        privacy="Privacy policy",
        remove_h="Remove my address",
        remove_p="Enter the same address: we delete it from the list and from the test in Google Play.",
        remove_btn="Remove my address",
        js=dict(
            sending="Sending…",
            done="Thank you! Your address has arrived. We will add it to the testers list, then you will get the link "
                 "to join the test.",
            removed="Done. If this address was on the list it has been deleted, and we will remove it from the test "
                    "in Google Play.",
            invalid_email="This does not look like an email address. Check it and try again.",
            rate="Too many tries from this connection. Try again in an hour.",
            failed="It could not be sent just now. Try again in a few minutes.",
            oops="Nothing was sent: check the address and try again, or try again a little later.")),
    "fr": dict(
        dir="ltr", home="Waaiya", home_href="en/", privacy_href="en/privacy.html",
        title="Testez Waaiya sur Google Play",
        desc="Waaiya arrive sur Google Play. Inscrivez votre adresse Gmail pour être invité à la tester sur votre "
             "téléphone avant sa publication pour tous.",
        lead="Waaiya arrive sur Google Play. Avant de la publier pour tous, Google demande qu'elle soit testée pendant "
             "deux semaines. Indiquez votre adresse Gmail, ou celle du compte Google que vous utilisez pour Google Play "
             "sur votre téléphone, et nous vous ajouterons aux testeurs.",
        steps_h="En quoi consiste le test",
        steps=["Nous ajoutons votre adresse à la liste des testeurs dans Google Play, puis vous recevez un lien pour "
               "rejoindre le test.",
               "Ouvrez le lien sur votre téléphone Android, avec le même compte Google, acceptez de devenir testeur, "
               "puis installez Waaiya depuis Google Play comme n'importe quelle application.",
               "Gardez-la installée au moins 14 jours : Google le demande avant de publier une application pour tous. "
               "Utilisez-la comme vous voulez."],
        email_label="Adresse Gmail, ou adresse de votre compte Google",
        email_note="Celle que vous utilisez pour Google Play sur votre téléphone.",
        name_label="Votre nom (facultatif)",
        submit="M'inviter au test",
        use_note="Votre adresse sert uniquement à vous inviter à ce test : elle n'est ni publiée, ni transmise à "
                 "quiconque, ni utilisée pour autre chose. Elle est conservée dans une liste sur le serveur de notre "
                 "site et envoyée au développeur par Telegram, pour être ajoutée dans la Google Play Console.",
        privacy="Politique de confidentialité (en anglais et en arabe)",
        remove_h="Retirer mon adresse",
        remove_p="Indiquez la même adresse : nous la supprimons de la liste et du test dans Google Play.",
        remove_btn="Retirer mon adresse",
        js=dict(
            sending="Envoi…",
            done="Merci ! Votre adresse est bien arrivée. Nous l'ajoutons à la liste des testeurs, puis vous recevrez "
                 "le lien pour rejoindre le test.",
            removed="C'est fait. Si cette adresse était dans la liste, elle en a été supprimée, et nous la retirerons "
                    "du test dans Google Play.",
            invalid_email="Cette adresse ne semble pas valide. Vérifiez-la et réessayez.",
            rate="Trop d'essais depuis cette connexion. Réessayez dans une heure.",
            failed="L'envoi a échoué. Réessayez dans quelques minutes.",
            oops="Rien n'a été envoyé : vérifiez l'adresse et réessayez, ou réessayez un peu plus tard.")),
}
TEST_LANGS = (("ar", "العربية", "test/"), ("en", "English", "en/test/"), ("fr", "Français", "fr/test/"))


def test_page(lang, root):
    u = TEST[lang]
    for k, lim in (("title", 60), ("desc", 160)):
        n = visible_len(plain(u[k]))
        assert n <= lim, f"test {lang} {k} is {n} characters (limit {lim})"
    robots = '<meta name="robots" content="noindex">' if PREVIEW else ""
    path = dict((c, p) for c, _, p in TEST_LANGS)
    alts = "".join(f'<link rel="alternate" hreflang="{c}" href="{SITE}{p}">' for c, _, p in TEST_LANGS)
    others = " · ".join(f'<a href="{root}{p}" lang="{c}" hreflang="{c}">{n}</a>' for c, n, p in TEST_LANGS if c != lang)
    steps = "".join(f"<li>{e(s)}</li>" for s in u["steps"])
    text = json.dumps({k: plain(v) for k, v in u["js"].items()}, ensure_ascii=False).replace("</", "<\\/")
    action = f"{root}api/test-signup.php"
    trap = ('<div class="vh" aria-hidden="true"><label for="tst-web-{n}">Website</label>'
            '<input id="tst-web-{n}" name="website" type="text" tabindex="-1" autocomplete="off"></div>')
    hidden = f'<input type="hidden" name="lang" value="{lang}">'
    status = '<p class="tst-status" role="status" aria-live="polite" tabindex="-1" hidden></p>'
    return f"""<!doctype html>
<html lang="{lang}" dir="{u['dir']}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(plain(u['title']))} · {'واعية' if lang == 'ar' else 'Waaiya'}</title>{robots}
<meta name="description" content="{e(plain(u['desc']))}">
<link rel="canonical" href="{SITE}{path[lang]}">
{alts}<link rel="alternate" hreflang="x-default" href="{SITE}test/">
<link rel="icon" href="{root}assets/logo.png">
<style>{fonts(root + 'assets/')}
{CSS}</style></head>
<body class="doc"><a class="doc-home" href="{root}{u['home_href']}">{e(u['home'])}</a>
<span class="doc-lang">{others}</span>
<main class="prose tst">
<h1>{e(u['title'])}</h1>
<p class="tst-lead">{e(u['lead'])}</p>
<h2>{e(u['steps_h'])}</h2>
<ol class="tst-steps">{steps}</ol>
<form class="tst-form" action="{action}" method="post">{hidden}<input type="hidden" name="mode" value="join">
<div class="tst-field"><label for="tst-email">{e(u['email_label'])}</label>
<input id="tst-email" name="email" type="email" required maxlength="254" autocomplete="email" inputmode="email" dir="ltr" spellcheck="false" autocapitalize="off" aria-describedby="tst-email-note">
<p class="tst-hint" id="tst-email-note">{e(u['email_note'])}</p></div>
<div class="tst-field"><label for="tst-name">{e(u['name_label'])}</label>
<input id="tst-name" name="name" type="text" maxlength="80" autocomplete="name" dir="auto"></div>
{trap.format(n=1)}
<p><button type="submit" class="cbtn">{e(u['submit'])}</button></p>
{status}
</form>
<p class="tst-status ok tst-after" id="done" tabindex="-1">{e(u['js']['done'])}</p>
<p class="tst-status ok tst-after" id="removed" tabindex="-1">{e(u['js']['removed'])}</p>
<p class="tst-status bad tst-after" id="oops" tabindex="-1">{e(u['js']['oops'])}</p>
<p class="tst-use">{e(u['use_note'])} <a href="{root}{u['privacy_href']}">{e(u['privacy'])}</a></p>
<details class="tst-remove"><summary>{e(u['remove_h'])}</summary>
<form class="tst-form" action="{action}" method="post">{hidden}<input type="hidden" name="mode" value="remove">
<p>{e(u['remove_p'])}</p>
<div class="tst-field"><label for="tst-email-rm" class="vh">{e(u['email_label'])}</label>
<input id="tst-email-rm" name="email" type="email" required maxlength="254" autocomplete="email" inputmode="email" dir="ltr" spellcheck="false" autocapitalize="off"></div>
{trap.format(n=2)}
<p><button type="submit" class="cbtn quiet">{e(u['remove_btn'])}</button></p>
{status}
</form></details>
</main>
<script type="application/json" id="test-text">{text}</script>
<script src="{root}assets/test/signup.js" defer></script>
</body></html>
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
- [Set up Android from a computer over USB (Chrome, Edge)]({SITE}en/usb/)

## Downloads and source

- [Android: waaiya.apk {VERSION}]({APK})
- [Windows: Waaiya in the Microsoft Store]({STORE}): free, signed by Microsoft
- [Windows and Linux releases]({RELEASES}): the Windows zip (not signed) and the Linux apps
- [Source code]({REPO})
"""


def sha256(path):
    import hashlib
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def try_assets(dst):
    """The in-browser filter: try.js + its worker, ONNX Runtime Web (npm tarball, cached in .work/, checked) and the
    app's voice model (models/dfn3, checked against models/SHA256SUMS; WAAIYA_MODELS=<dir> to take it elsewhere)."""
    import os, tarfile, urllib.request
    dst.mkdir(parents=True)
    for f in ("try.js", "try-worker.js"):
        shutil.copy(HERE / "try" / f, dst / f)
    work = HERE / ".work"
    work.mkdir(exist_ok=True)
    tgz = work / f"onnxruntime-web-{ORT_VERSION}.tgz"
    if not tgz.exists() or sha256(tgz) != ORT_TGZ_SHA256:
        urllib.request.urlretrieve(f"https://registry.npmjs.org/onnxruntime-web/-/onnxruntime-web-{ORT_VERSION}.tgz", tgz)
    if sha256(tgz) != ORT_TGZ_SHA256:
        sys.exit(f"onnxruntime-web {ORT_VERSION}: checksum mismatch")
    with tarfile.open(tgz) as t:
        for f in ORT_FILES:
            with t.extractfile(f"package/dist/{f}") as src, open(dst / f, "wb") as out:
                shutil.copyfileobj(src, out)
    import gzip  # the host does not compress wasm itself; htaccess sends this copy to browsers that accept gzip
    with open(dst / ORT_FILES[2], "rb") as src, gzip.open(dst / (ORT_FILES[2] + ".gz"), "wb", 9) as out:
        shutil.copyfileobj(src, out)
    models = Path(os.environ.get("WAAIYA_MODELS") or HERE.parent / "models/dfn3")
    sums = dict(reversed(l.split()) for l in (HERE.parent / "models/SHA256SUMS").read_text().splitlines() if l.strip())
    for f in MODEL_FILES:
        if not (models / f).exists():
            sys.exit(f"missing {models / f}: run scripts/fetch_deps.sh models, or set WAAIYA_MODELS")
        if sha256(models / f) != sums[f]:
            sys.exit(f"{f}: checksum does not match models/SHA256SUMS")
        shutil.copy(models / f, dst / f)


ROBOTS = f"""User-agent: *
Allow: /
Disallow: /api/
Disallow: /preview/

Sitemap: {SITE}sitemap.xml
"""


def sitemap():
    """The two language pages (each naming the other) and the privacy page; lastmod is the build date."""
    today = datetime.date.today().isoformat()
    alts = "".join(f'\n    <xhtml:link rel="alternate" hreflang="{h}" href="{u}"/>'
                   for h, u in (("ar", SITE), ("en", SITE + "en/"), ("x-default", SITE)))
    urls = [(SITE, alts, "1.0"), (SITE + "en/", alts, "0.9"), (SITE + "privacy.html", "", "0.3"),
            (SITE + "usb/", "", "0.4"), (SITE + "en/usb/", "", "0.4")]
    body = "".join(f"  <url>\n    <loc>{u}</loc>{a}\n    <lastmod>{today}</lastmod>\n    <priority>{p}</priority>\n  </url>\n"
                   for u, a, p in urls)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" '
            'xmlns:xhtml="http://www.w3.org/1999/xhtml">\n' + body + "</urlset>\n")


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / "en").mkdir(parents=True)
    shutil.copytree(HERE / "assets", OUT / "assets")
    try_assets(OUT / "assets/try")
    (OUT / "index.html").write_text(page("ar", ""))
    (OUT / "en/index.html").write_text(page("en", "../"))
    (OUT / "privacy.html").write_text(privacy("ar", ""))
    (OUT / "en/privacy.html").write_text(privacy("en", "../"))
    (OUT / "assets/usb").mkdir(parents=True)
    for f in USB_FILES:
        shutil.copy(HERE / "usb" / f, OUT / "assets/usb" / f)
    (OUT / "usb").mkdir()
    (OUT / "en/usb").mkdir()
    (OUT / "usb/index.html").write_text(usb_page("ar", "../"))
    (OUT / "en/usb/index.html").write_text(usb_page("en", "../../"))
    (OUT / "assets/test").mkdir(parents=True)
    shutil.copy(HERE / "test/signup.js", OUT / "assets/test/signup.js")
    (OUT / "api").mkdir()
    shutil.copy(HERE / "test/signup.php", OUT / "api/test-signup.php")
    for c, _, p in TEST_LANGS:
        (OUT / p).mkdir(parents=True)
        (OUT / p / "index.html").write_text(test_page(c, "../" * p.count("/")))
    (OUT / "llms.txt").write_text(LLMS)
    if not PREVIEW:
        (OUT / "robots.txt").write_text(ROBOTS)
        (OUT / "sitemap.xml").write_text(sitemap())
        (OUT / f"{INDEXNOW_KEY}.txt").write_text(INDEXNOW_KEY)
    print("wrote", OUT, "(preview)" if PREVIEW else "")


if __name__ == "__main__":
    main()
