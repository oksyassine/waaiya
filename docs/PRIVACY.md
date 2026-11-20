# Waaiya privacy policy

Last change: 2026-11-20. Applies to Waaiya on Android, Linux and Windows. [العربية أدناه](#سياسة-الخصوصية)

## In short

Waaiya sends nothing about you anywhere. There is no account, no analytics, no advertising, no crash reporting and
no server of ours. The sound filter, the screen blur and every other feature run on your device, and what they
hear and see stays in memory on your device and is not saved.

## What goes online, and only when you ask

| When | What is contacted | What it learns |
|---|---|---|
| You open or save a link ("Open a link", Android; Windows from 0.2.12) | The site of that link (for example YouTube), the same way a browser would | What any site learns from a visitor: your IP address and the video you asked for |
| Android: the bundled link reader (yt-dlp) checks for a newer version, at most once a day, only around a link you open | PyPI (pypi.org and files.pythonhosted.org), with Python's default client name, never Waaiya's | Your IP address and that some Python program asked for yt-dlp |
| Windows: the Microsoft Store updates Waaiya | Microsoft, as for every Store app | As in Microsoft's own privacy statement |

Nothing else opens a network connection. The filter, the women's-singing detector and the screen blur are checked
for this on every change of the code: a test runs them with every internet connection refused and fails if any of
them tries one (`linux/test_no_network.sh`, the Linux blur's end-to-end test, and `NoNetworkTest.kt` on Android).

## What stays on your device

- Your settings (who uses the device, the filter and blur options, the language, and the optional prayer-time
  place, which is a city you pick or coordinates you type: Waaiya never reads your location).
- The diagnostics report and the "wrong detection" notes: plain text kept in the app's private storage. They leave
  the device only if you share them yourself, to whoever you choose.
- Android: cloud backup and device-to-device transfer are switched off for Waaiya's data.

Uninstalling Waaiya deletes all of it.

## Permissions and why (Android)

| Permission | Why |
|---|---|
| Record audio and the screen-sharing question (MediaProjection) | Android delivers other apps' sound to Waaiya only through these. The sound is filtered in memory and played back; nothing is recorded. The screen picture is used, in memory, only for the blur |
| Notifications, foreground service | To show that filtering runs and to let you stop it |
| Display over other apps | To draw the covers of the screen blur |
| `DUMP`, `WRITE_SECURE_SETTINGS` (granted once with the setup, by you) | To find and silence the original sound of the app being filtered, and to skip the sharing question |
| Internet | Only for "Open a link" (above) |
| Do Not Disturb access, alarms, system settings (only if you turn on the worship helpers) | To silence the phone at prayer times and to set a plain ringtone |
| Accessibility (only in the separate `-a11y` build) | To draw covers that let touches through on phones without the setup |

## Children

Waaiya collects nothing from anyone, children included. A parent PIN and a waiting period are local settings and
are not reported to anyone.

## Changes and contact

Changes to this policy are made in this file in the public repository, where their history is kept:
<https://github.com/oksyassine/waaiya>. Questions: open an issue there.

---

<div dir="rtl">

## سياسة الخصوصية

آخر تعديل: 2026-11-20. تنطبق على واعية في أندرويد ولينكس وويندوز.

### باختصار

لا ترسل واعية أي شيء عنك إلى أي جهة. لا حساب، ولا إحصاءات استخدام، ولا إعلانات، ولا تقارير أعطال، ولا خادم لنا.
مُرشِّح الصوت وتغطية الشاشة وسائر الميزات تعمل على جهازك، وما تسمعه وتراه يبقى في ذاكرة جهازك ولا يُحفظ.

### ما يتصل بالإنترنت، وبطلب منك فقط

- عند فتح رابط أو حفظه («افتح رابطًا»): يُتَّصَل بموقع ذلك الرابط كما يفعل المتصفح، فيعرف ما يعرفه أي موقع عن زائره:
  عنوان IP والمقطع الذي طلبته.
- في أندرويد: قارئ الروابط المرفق (yt-dlp) يبحث عن إصدار أحدث، مرة في اليوم على الأكثر وعند فتح رابط فقط، من موقع
  PyPI، باسم بايثون العام لا باسم واعية.
- في ويندوز: متجر مايكروسوفت يحدّث واعية كما يحدّث كل تطبيقاته.

لا شيء غير ذلك يتصل بالشبكة. يُختبر هذا مع كل تعديل في الشيفرة: تُشغَّل المرشحات والتغطية مع منع كل اتصال بالإنترنت،
ويفشل الاختبار إن حاول أحدها الاتصال.

### ما يبقى على جهازك

- إعداداتك، ومنها مكان أوقات الصلاة إن اخترته: مدينة تختارها أو إحداثيات تكتبها، ولا تقرأ واعية موقعك أبدًا.
- تقرير التشخيص وملاحظات «اكتشاف خاطئ»: نص في مساحة التطبيق الخاصة، لا يخرج من الجهاز إلا إذا شاركته بنفسك.
- في أندرويد: النسخ الاحتياطي السحابي والنقل بين الأجهزة معطَّلان لبيانات واعية.

حذف واعية يحذف ذلك كله.

### الأذونات (أندرويد)

تسجيل الصوت وسؤال مشاركة الشاشة لأن أندرويد لا يعطي صوت التطبيقات الأخرى إلا بهما؛ يُرشَّح الصوت في الذاكرة ولا يُسجَّل.
الإشعارات لإظهار أن الترشيح يعمل وإيقافه. الظهور فوق التطبيقات لرسم الأغطية. إذنا `DUMP` و`WRITE_SECURE_SETTINGS`
تمنحهما أنت مرة واحدة في الإعداد لإسكات الصوت الأصلي. الإنترنت لفتح الروابط فقط. إذن «عدم الإزعاج» والمنبّهات
وإعدادات النظام فقط إن فعّلت أدوات الصلاة.

### التواصل

تُجرى التعديلات على هذه السياسة في هذا الملف في المستودع العام حيث يُحفظ تاريخها: <https://github.com/oksyassine/waaiya>.

</div>
