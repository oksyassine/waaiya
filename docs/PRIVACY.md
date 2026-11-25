# Waaiya privacy policy

Last change: 2026-11-24. Applies to Waaiya on Android, Linux and Windows. [العربية أدناه](#سياسة-الخصوصية)

## In short

Waaiya sends nothing about you anywhere. There is no account, no analytics, no advertising and no crash reporting.
The only server of ours the app contacts is its website, to see whether a newer version exists (below); the request
carries nothing about you or your device. The sound filter, the screen blur and every other feature run on your device, and what they
hear and see stays in memory on your device and is not saved.

## What goes online

| When | What is contacted | What it learns |
|---|---|---|
| You open or save a link ("Open a link" on Android; "Save without music" in the Windows app from GitHub) | The site of that link (for example YouTube), the same way a browser would | What any site learns from a visitor: your IP address and the video you asked for |
| Windows: "Watch" on the Links page | Nothing from Waaiya: it starts the filter and hands the link to your own web browser, which opens it as usual. The Windows app from the Microsoft Store only does this: it has no download tools and never contacts a site itself | What your browser's site learns, as without Waaiya |
| Android: the bundled link reader (yt-dlp) checks for a newer version, at most once a day, only around a link you open | PyPI (pypi.org and files.pythonhosted.org), with Python's default client name, never Waaiya's | Your IP address and that some Python program asked for yt-dlp |
| Windows: the Microsoft Store updates Waaiya | Microsoft, as for every Store app | As in Microsoft's own privacy statement |
| Android (the app from the website or GitHub; store builds have no updater): the check for a new version, once a day and when you open Waaiya, never while filtering. Turn it off in Settings, "App updates" | waaiya.mssid.org (our website, hosted by o2switch in France) reads the file `downloads/waaiya-update.json` (`downloads/update.json` for the old app, 0.2.14 and before), with the client name `Waaiya-Update/1` only: no device, version or identifier. Your phone compares the versions itself | What any website learns from a visitor: your IP address and the time |
| Android: you tap "Update now" | waaiya.mssid.org again, for the update file (only the changes when possible). Your phone checks it is the published file, signed like the app you have, before Android's installer asks you to confirm | The same, and which update file was downloaded |

Nothing else opens a network connection. The filter, the women's-singing detector and the screen blur are checked
for this on every change of the code: a test runs them with every internet connection refused and fails if any of
them tries one (`linux/test_no_network.sh`, the Linux blur's end-to-end test, and `NoNetworkTest.kt` on Android).

## What stays on your device

- Your settings (who uses the device, the filter and blur options, the language, and the optional prayer-time
  place: a city you pick, coordinates you type, or your approximate location if you tap "Use my location").
- Android, "Use my location" for the prayer times: only when you tap it, and Android asks you first. Waaiya reads
  the phone's approximate position (about 2 km, never the precise one) once, at that moment, through Android
  itself, and keeps only the resulting place (in Morocco the nearest city of the Ministry of Habous's list,
  elsewhere the coordinates). It is never sent anywhere and never read again in the background; tap it again after
  travelling.
- The diagnostics report and the "wrong detection" notes: plain text kept in the app's private storage. They leave
  the device only if you share them yourself, to whoever you choose.
- Android: cloud backup and device-to-device transfer are switched off for Waaiya's data.

Uninstalling Waaiya deletes all of it on Android and Linux (the app's own data). On Windows, the settings, the
notes and the sound filter's small working files (the apps' volume levels to give back and a log of the filter's own
messages, never any sound) are in `%APPDATA%\Waaiya` and `%LOCALAPPDATA%\Waaiya`; Windows does not delete these
two folders when you uninstall the app, and you can delete them yourself.

## Permissions and why (Android)

| Permission | Why |
|---|---|
| Record audio and the screen-sharing question (MediaProjection) | Android delivers other apps' sound to Waaiya only through these. The sound is filtered in memory and played back; nothing is recorded. The screen picture is used, in memory, only for the blur |
| Notifications, foreground service | To show that filtering runs and to let you stop it |
| Display over other apps | To draw the covers of the screen blur |
| `DUMP`, `WRITE_SECURE_SETTINGS` (granted once with the setup, by you) | To find and silence the original sound of the app being filtered, and to skip the sharing question |
| Internet | Only for "Open a link" and the check for new versions (above) |
| Install unknown apps (`REQUEST_INSTALL_PACKAGES`; not in store builds) | To hand a downloaded update to Android's installer, which always asks you to confirm. Android asks you to allow it the first time |
| Do Not Disturb access, alarms, system settings (only if you turn on the worship helpers) | To silence the phone at prayer times and to set a plain ringtone |
| Approximate location (only if you tap "Use my location" for the prayer times) | To find the place of the prayer times once, at that moment. Not the precise location; not in the background |
| Accessibility (only in the separate `-a11y` build) | To draw covers that let touches through on phones without the setup |

## Children

Waaiya collects nothing from anyone, children included. A parent PIN and a waiting period are local settings and
are not reported to anyone.

## The website's "Try it on your sound"

- **A file from your device** is read and filtered in your browser. It is not uploaded anywhere.
- **A link** is sent to our servers, asked in this order until one succeeds: o2switch (France), Oracle Cloud
  (Casablanca), then a server run by the developer. That server fetches at most one minute of the link's
  sound, with a small picture when it has one, from its site and sends it back to your browser, where the sound is
  filtered. The site of the link sees our server,
  not you. The link travels in the body of the request, so it is not in any access log; neither the link nor the clip
  is stored, and the temporary file is deleted once it is sent. To limit abuse each server counts requests per
  address for ten minutes (on o2switch as a hash that changes every day) and the total per day, nothing more. The
  hosts keep their usual access logs (address, time, page).

## The website's Google Play test sign-up

Joining the Google Play test uses a Google Group, waaiya-testers@googlegroups.com, run by Google under its own
privacy policy: you join it with your Google account, and only the developer, as its manager, sees its members'
addresses (members do not see each other, and nothing is posted to the group). Google Play then lets the group's
members install the test.

If you also leave your address on waaiya.mssid.org/test/ to receive the steps by email, the address, and your name
if you give it, is sent to our website (hosted by o2switch in France) and kept there in a list, outside the public
site, with the time and the page's language. It is used only to email you the steps (from support@waaiya.mssid.org,
sent by the developer's own server, which reads the list) and to help you with this test; the developer is told of
each address by a Telegram bot (so the message passes through Telegram). It is never published, given to anyone else
or used for anything else. To limit abuse the form counts sends per address for an hour (as a hash that changes every
day). To have your address deleted, use "Leave the test" on the same page; to leave the test itself, leave the group
and the program in Google Play.

## Changes and contact

Changes to this policy are made in this file in the public repository, where their history is kept:
<https://github.com/oksyassine/waaiya>. Questions: open an issue there.

---

<div dir="rtl">

## سياسة الخصوصية

آخر تعديل: 2026-11-24. تنطبق على واعية في أندرويد ولينكس وويندوز.

### باختصار

لا ترسل واعية أي شيء عنك إلى أي جهة. لا حساب، ولا إحصاءات استخدام، ولا إعلانات، ولا تقارير أعطال. والخادم الوحيد لنا الذي
يتصل به التطبيق هو موقعه، ليعرف هل صدر إصدار أحدث (أدناه)، ولا يحمل الطلب شيئًا عنك أو عن جهازك.
مُرشِّح الصوت وتغطية الشاشة وسائر الميزات تعمل على جهازك، وما تسمعه وتراه يبقى في ذاكرة جهازك ولا يُحفظ.

### ما يتصل بالإنترنت

- عند فتح رابط أو حفظه («افتح رابطًا» في أندرويد، و«احفظ دون موسيقى» في نسخة ويندوز من GitHub): يُتَّصَل بموقع ذلك
  الرابط كما يفعل المتصفح، فيعرف ما يعرفه أي موقع عن زائره: عنوان IP والمقطع الذي طلبته.
- في ويندوز، «شاهد» في صفحة الروابط: لا تتصل واعية بشيء، بل تشغّل الترشيح وتعطي الرابط لمتصفحك فيفتحه كعادته. ونسخة
  متجر مايكروسوفت لا تفعل إلا هذا: لا أدوات تنزيل فيها، ولا تتصل بأي موقع بنفسها.
- في أندرويد: قارئ الروابط المرفق (yt-dlp) يبحث عن إصدار أحدث، مرة في اليوم على الأكثر وعند فتح رابط فقط، من موقع
  PyPI، باسم بايثون العام لا باسم واعية.
- في ويندوز: متجر مايكروسوفت يحدّث واعية كما يحدّث كل تطبيقاته.
- في أندرويد (النسخة من الموقع أو GitHub؛ نسخ المتاجر بلا تحديث ذاتي): البحث عن إصدار جديد مرة في اليوم وعند فتح واعية،
  ولا يحدث أثناء التصفية أبدًا، ويمكن إيقافه من «تحديثات التطبيق» في الإعدادات. يُقرأ الملف `downloads/waaiya-update.json` (و`downloads/update.json` للتطبيق القديم، 0.2.14 وما قبله) من موقعنا waaiya.mssid.org
  (لدى o2switch في فرنسا) باسم العميل `Waaiya-Update/1` وحده، بلا جهاز ولا إصدار ولا مُعرِّف، ويقارن هاتفك الإصدارات بنفسه.
  فيعرف الموقع ما يعرفه أي موقع عن زائره: عنوان IP والوقت.
- في أندرويد، حين تضغط «حدِّث الآن»: يُنزَّل ملف التحديث من الموقع نفسه (التغييرات فقط إن أمكن)، ويتحقق هاتفك أنه الملف
  المنشور وأنه موقَّع كالتطبيق الذي لديك، ثم يطلب منك مثبّت أندرويد التأكيد.

لا شيء غير ذلك يتصل بالشبكة. يُختبر هذا مع كل تعديل في الشيفرة: تُشغَّل المرشحات والتغطية مع منع كل اتصال بالإنترنت،
ويفشل الاختبار إن حاول أحدها الاتصال.

### ما يبقى على جهازك

- إعداداتك، ومنها مكان أوقات الصلاة إن اخترته: مدينة تختارها، أو إحداثيات تكتبها، أو موقعك التقريبي إن ضغطت «استخدم موقعي».
- في أندرويد، «استخدم موقعي» لأوقات الصلاة: فقط حين تضغطه، وبعد أن يسألك أندرويد. تقرأ واعية الموقع التقريبي للهاتف
  (نحو كيلومترين، لا الموقع الدقيق أبدًا) مرة واحدة في تلك اللحظة، عن طريق أندرويد نفسه، ولا تحفظ إلا المكان الناتج (في
  المغرب أقرب مدينة من قائمة وزارة الأوقاف، وفي غيره الإحداثيات). لا يُرسل إلى أي جهة، ولا يُقرأ مرة أخرى في الخلفية؛ اضغطه
  من جديد بعد السفر.
- تقرير التشخيص وملاحظات «اكتشاف خاطئ»: نص في مساحة التطبيق الخاصة، لا يخرج من الجهاز إلا إذا شاركته بنفسك.
- في أندرويد: النسخ الاحتياطي السحابي والنقل بين الأجهزة معطَّلان لبيانات واعية.

حذف واعية يحذف ذلك كله في أندرويد ولينكس. أما في ويندوز فالإعدادات والملاحظات وملفات المرشّح الصغيرة (مستويات صوت
التطبيقات لإرجاعها، وسجلّ لرسائل المرشّح نفسه، بلا أي صوت) في المجلدين `%APPDATA%\Waaiya` و`%LOCALAPPDATA%\Waaiya`،
ولا يحذفهما ويندوز عند إزالة التطبيق، ويمكنك حذفهما بنفسك.

### الأذونات (أندرويد)

تسجيل الصوت وسؤال مشاركة الشاشة لأن أندرويد لا يعطي صوت التطبيقات الأخرى إلا بهما؛ يُرشَّح الصوت في الذاكرة ولا يُسجَّل.
الإشعارات لإظهار أن الترشيح يعمل وإيقافه. الظهور فوق التطبيقات لرسم الأغطية. إذنا `DUMP` و`WRITE_SECURE_SETTINGS`
تمنحهما أنت مرة واحدة في الإعداد لإسكات الصوت الأصلي. الإنترنت لفتح الروابط والبحث عن إصدار جديد فقط. إذن «تثبيت التطبيقات غير المعروفة» (ليس في نسخ المتاجر) لتسليم
التحديث المنزَّل إلى مثبّت أندرويد، الذي يطلب تأكيدك دائمًا. إذن «عدم الإزعاج» والمنبّهات
وإعدادات النظام فقط إن فعّلت أدوات الصلاة. الموقع التقريبي فقط إن ضغطت «استخدم موقعي» لأوقات الصلاة، لمعرفة المكان مرة
واحدة في تلك اللحظة، لا الموقع الدقيق ولا في الخلفية.

### «جرّبها على صوتك» في الموقع

- **الملف من جهازك** يُقرأ ويُصفّى في متصفحك، ولا يُرفع إلى أي مكان.
- **الرابط** يُرسَل إلى خوادمنا، بهذا الترتيب حتى ينجح أحدها: o2switch (فرنسا)، ثم Oracle Cloud (الدار البيضاء)،
  ثم خادم يديره المطوّر. يجلب الخادم دقيقةً على الأكثر من صوت الرابط، مع صورة صغيرة إن كانت له، من موقعه، ويعيدها
  إلى متصفحك فيُصفّى الصوت فيه. موقع الرابط يرى خادمنا لا أنت. يُرسَل الرابط في جسم الطلب فلا يظهر في سجلات الزيارات، ولا يُحفظ الرابط ولا
  المقطع، ويُحذف الملف المؤقت بعد إرساله. وللحدّ من إساءة الاستخدام يعدّ كل خادم الطلبات لكل عنوان مدة عشر دقائق (في
  o2switch بصيغة مشفّرة تتغير كل يوم) ومجموعها في اليوم، لا أكثر. وتحتفظ جهات الاستضافة بسجلاتها المعتادة (العنوان
  والوقت والصفحة).

### التسجيل في اختبار Google Play على الموقع

إن سجّلت في waaiya.mssid.org/test/ لتختبر واعية على Google Play، يُرسَل العنوان الذي تكتبه، واسمك إن ذكرته، إلى موقعنا
(لدى o2switch في فرنسا)، ويُحفظ هناك في قائمة خارج الموقع العام، مع الوقت ولغة الصفحة. لا يُستعمل إلا لدعوتك إلى الاختبار:
يُخبَر المطوّر بكل عنوان عبر بوت في Telegram (فتمرّ الرسالة بـ Telegram)، فيضيفه إلى قائمة المختبرين في Google Play Console،
حيث تنطبق سياسة الخصوصية لـ Google. لا يُنشر العنوان، ولا يُعطى لأحد، ولا يُستعمل لغير ذلك. وللحدّ من إساءة الاستخدام يعدّ
النموذج الإرسالات لكل عنوان مدة ساعة (بصيغة مشفّرة تتغير كل يوم). ولحذف عنوانك، استعمل «أزل عنواني من الاختبار» في الصفحة
نفسها: يُحذف من القائمة ومن الاختبار.

### التواصل

تُجرى التعديلات على هذه السياسة في هذا الملف في المستودع العام حيث يُحفظ تاريخها: <https://github.com/oksyassine/waaiya>.

</div>
