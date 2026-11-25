# Waaiya privacy policy

Last change: 2026-11-25. Applies to Waaiya on Android, Linux and Windows. [العربية أدناه](#سياسة-الخصوصية)

## In short

Waaiya sends nothing about you anywhere. There is no account, no analytics, no advertising and no crash reporting.
The only server of ours the app contacts is its website, to see whether a newer version exists (below); the request
carries nothing about you or your device. The sound filter, the screen blur and every other feature run on your device, and what they
hear and see stays in memory on your device and is not saved.

Two things leave the device only because you choose them: the optional reply to calls by SMS during prayer (website
and GitHub app only) sends a text from your phone to the person calling you, and a diagnostics report or notes that
you share go to whoever you share them with.

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
  the device only if you share them yourself, to whoever you choose. The report lists the phone's maker and model,
  its Android version, chip and memory, the app's language and who uses the device (man or woman, if chosen),
  Waaiya's settings and state, the last times filtering or Waaiya stopped and why, and the names of the apps that
  have a sound session or that you chose to hear unfiltered. Read it before you share it: it is shown to you in full.
  A note keeps the time, the app on screen and the settings at that moment.
- Android, the reply to calls by SMS during prayer (website and GitHub app only; off unless you turn it on): the
  number of a call while it rings, the numbers already answered during the current prayer (so each gets one text),
  and a list of the last 20 replies (time and number), which the prayer page shows you. Your call history is not
  read, and nothing from it is kept.
- Android, the one-time setup: the pairing key Waaiya made with Android's Wireless debugging (shown in Android's
  list of paired devices as "waaiya@phone"), kept in storage that is never backed up.
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
| `DUMP`, `WRITE_SECURE_SETTINGS` (granted once with the setup, by you) | To find and silence the original sound of the app being filtered, and to skip the sharing question. `WRITE_SECURE_SETTINGS` also changes Android's "screen share protections" switch (below) |
| The one-time setup: Android's Wireless debugging, or the separate Shizuku app if you use it | To give Waaiya the two permissions above. With Wireless debugging, Waaiya connects only to the phone itself (127.0.0.1). On phones that refuse those permissions to the setup, a small Waaiya helper started the same way does that work with the rights of Android's debugging shell, and talks only to Waaiya on the phone |
| Android's "screen share protections" switch (Android 15 and later; Developer options, "Disable screen share protections") | Android hides the text of notifications while the screen is captured, and filtering counts as a capture. Waaiya lifts this protection only while it filters: when you turn on "Notification text", and on phones where Android asks before every start (for example Xiaomi and OPPO), where Android would otherwise stop filtering at every screen lock. It puts the switch back when filtering stops, or the next time Waaiya runs if it was stopped by force. While it is lifted, another screen share made at the same time (a video call, for example) can also show your notifications. A value you set by hand is never changed |
| Modify audio settings | To silence the original sound of the apps being filtered (an audio effect on their sound, removed when filtering stops) |
| The list of installed apps that have a launcher icon | To name the app whose sound cannot be filtered, and to let you pick apps in "Apps heard unfiltered" and "Apps without blur". The list stays on the phone |
| Start at boot (`RECEIVE_BOOT_COMPLETED`) | To set the prayer-time alarms and a Protection waiting period again after the phone restarts |
| Read phone state, read call log, send SMS (website and GitHub app only; asked one by one only when you turn on the reply to calls by SMS during prayer; not in the Google Play app) | Android gives the number of a ringing call only to apps with the call-log permission; Waaiya uses it to send one text to someone who calls during prayer. The call history is not read |
| Move from the old app (`org.waaiya.permission.MOVE`, `REQUEST_DELETE_PACKAGES`) | To bring your settings from the old app (org.islamicmute.app, 0.2.14 and before) and to offer to uninstall it; Android asks you to confirm |
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

Waaiya is made by Mssid, which is responsible for this app, the website and this policy. Questions, or a request about data the website
holds (the test sign-up list): support@waaiya.mssid.org, or open an issue at <https://github.com/oksyassine/waaiya>.
Changes to this policy are made in this file in that public repository, where their history is kept.

---

<div dir="rtl">

## سياسة الخصوصية

آخر تعديل: 2026-11-25. تنطبق على واعية في أندرويد ولينكس وويندوز.

### باختصار

لا ترسل واعية أي شيء عنك إلى أي جهة. لا حساب، ولا إحصاءات استخدام، ولا إعلانات، ولا تقارير أعطال. والخادم الوحيد لنا الذي
يتصل به التطبيق هو موقعه، ليعرف هل صدر إصدار أحدث (أدناه)، ولا يحمل الطلب شيئًا عنك أو عن جهازك.
مُرشِّح الصوت وتغطية الشاشة وسائر الميزات تعمل على جهازك، وما تسمعه وتراه يبقى في ذاكرة جهازك ولا يُحفظ.

ولا يخرج من الجهاز شيء إلا باختيارك في حالتين: الرد على المكالمات برسالة SMS أثناء الصلاة (اختياري، في نسخة الموقع وGitHub
فقط) يرسل من هاتفك رسالة إلى من يتصل بك، وتقرير التشخيص أو الملاحظات إن شاركتها بنفسك تذهب إلى من تختاره.

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
- تقرير التشخيص وملاحظات «اكتشاف خاطئ»: نص في مساحة التطبيق الخاصة، لا يخرج من الجهاز إلا إذا شاركته بنفسك. يذكر التقرير
  صانع الهاتف وطرازه وإصدار أندرويد والمعالج والذاكرة، ولغة التطبيق ومستخدم الجهاز (رجل أو امرأة إن اخترت)، وإعدادات واعية
  وحالتها، وآخر مرات توقف الترشيح أو واعية وسببها، وأسماء التطبيقات التي لها جلسة صوت أو التي اخترت سماعها دون ترشيح.
  اقرأه قبل مشاركته، فهو يُعرض عليك كاملًا. والملاحظة تحفظ الوقت والتطبيق الظاهر والإعدادات في تلك اللحظة.
- في أندرويد، الرد على المكالمات برسالة SMS أثناء الصلاة (نسخة الموقع وGitHub فقط، ولا يعمل إلا إن فعّلته): رقم المكالمة
  أثناء رنينها، والأرقام التي رُدّ عليها في الصلاة الحالية (لتصلها رسالة واحدة)، وقائمة بآخر 20 ردًّا (الوقت والرقم) تعرضها
  عليك صفحة الصلاة. لا يُقرأ سجل مكالماتك ولا يُحفظ منه شيء.
- في أندرويد، الإعداد لمرة واحدة: مفتاح الاقتران الذي أنشأته واعية مع «تصحيح الأخطاء اللاسلكي» (يظهر في قائمة الأجهزة
  المقترنة في أندرويد باسم "waaiya@phone")، في مساحة لا تُنسخ احتياطيًا أبدًا.
- في أندرويد: النسخ الاحتياطي السحابي والنقل بين الأجهزة معطَّلان لبيانات واعية.

حذف واعية يحذف ذلك كله في أندرويد ولينكس. أما في ويندوز فالإعدادات والملاحظات وملفات المرشّح الصغيرة (مستويات صوت
التطبيقات لإرجاعها، وسجلّ لرسائل المرشّح نفسه، بلا أي صوت) في المجلدين `%APPDATA%\Waaiya` و`%LOCALAPPDATA%\Waaiya`،
ولا يحذفهما ويندوز عند إزالة التطبيق، ويمكنك حذفهما بنفسك.

### الأذونات (أندرويد)

تسجيل الصوت وسؤال مشاركة الشاشة لأن أندرويد لا يعطي صوت التطبيقات الأخرى إلا بهما؛ يُرشَّح الصوت في الذاكرة ولا يُسجَّل.
الإشعارات لإظهار أن الترشيح يعمل وإيقافه. الظهور فوق التطبيقات لرسم الأغطية. إذنا `DUMP` و`WRITE_SECURE_SETTINGS`
تمنحهما أنت مرة واحدة في الإعداد لإسكات الصوت الأصلي. الإنترنت لفتح الروابط والبحث عن إصدار جديد فقط. تعديل إعدادات الصوت لإسكات
الصوت الأصلي للتطبيقات المرشَّحة (أثر صوتي يُزال عند توقف الترشيح). قائمة التطبيقات المثبتة ذات الأيقونة لتسمية التطبيق
الذي لا يمكن ترشيح صوته، ولتختار التطبيقات في «تطبيقات تُسمع دون ترشيح» و«تطبيقات دون تغطية»، ولا تخرج القائمة من الهاتف.
التشغيل عند الإقلاع لإعادة ضبط منبّهات الصلاة ومدة انتظار الحماية بعد إعادة تشغيل الهاتف. والانتقال من التطبيق القديم
(org.islamicmute.app، الإصدار 0.2.14 وما قبله) لنقل إعداداتك منه وعرض إزالته، ويطلب أندرويد تأكيدك. إذن «تثبيت التطبيقات غير المعروفة» (ليس في نسخ المتاجر) لتسليم
التحديث المنزَّل إلى مثبّت أندرويد، الذي يطلب تأكيدك دائمًا. إذن «عدم الإزعاج» والمنبّهات
وإعدادات النظام فقط إن فعّلت أدوات الصلاة. الموقع التقريبي فقط إن ضغطت «استخدم موقعي» لأوقات الصلاة، لمعرفة المكان مرة
واحدة في تلك اللحظة، لا الموقع الدقيق ولا في الخلفية.

قراءة حالة الهاتف وسجل المكالمات وإرسال الرسائل (نسخة الموقع وGitHub فقط، لا نسخة Google Play، ويُطلب كل منها حين تفعّل الرد
على المكالمات برسالة SMS أثناء الصلاة): لا يعطي أندرويد رقم المكالمة الواردة إلا لتطبيق له إذن سجل المكالمات، وتستعمله
واعية لإرسال رسالة واحدة إلى من يتصل أثناء الصلاة. لا يُقرأ سجل المكالمات.

الإعداد لمرة واحدة يمنح الإذنين `DUMP` و`WRITE_SECURE_SETTINGS` عبر «تصحيح الأخطاء اللاسلكي» في أندرويد (لا تتصل واعية
إلا بالهاتف نفسه، 127.0.0.1) أو عبر تطبيق Shizuku المستقل إن استعملته. وفي الهواتف التي ترفض منح الإذنين، يقوم بعملهما
مساعد صغير لواعية يُشغَّل بالطريقة نفسها بصلاحيات واجهة التصحيح في أندرويد، ولا يتحدث إلا مع واعية على الهاتف.

مفتاح «حماية مشاركة الشاشة» في أندرويد (أندرويد 15 وما بعده، في خيارات المطوّرين): يخفي أندرويد نص الإشعارات أثناء
التقاط الشاشة، والترشيح يُعدّ التقاطًا. ترفع واعية هذه الحماية أثناء الترشيح فقط: حين تفعّل «نص الإشعارات»، وفي الهواتف
التي يسأل فيها أندرويد قبل كل تشغيل (مثل شاومي وأوبو)، وإلا أوقف أندرويد الترشيح عند كل قفل للشاشة. وتعيدها حين يتوقف
الترشيح، أو في المرة التالية التي تعمل فيها واعية إن أُوقفت بالقوة. وما دامت مرفوعة، فقد تُظهر مشاركة شاشة أخرى في الوقت
نفسه (مكالمة فيديو مثلًا) إشعاراتك أيضًا. والقيمة التي ضبطتها بيدك لا تُغيَّر أبدًا.

### «جرّبها على صوتك» في الموقع

- **الملف من جهازك** يُقرأ ويُصفّى في متصفحك، ولا يُرفع إلى أي مكان.
- **الرابط** يُرسَل إلى خوادمنا، بهذا الترتيب حتى ينجح أحدها: o2switch (فرنسا)، ثم Oracle Cloud (الدار البيضاء)،
  ثم خادم يديره المطوّر. يجلب الخادم دقيقةً على الأكثر من صوت الرابط، مع صورة صغيرة إن كانت له، من موقعه، ويعيدها
  إلى متصفحك فيُصفّى الصوت فيه. موقع الرابط يرى خادمنا لا أنت. يُرسَل الرابط في جسم الطلب فلا يظهر في سجلات الزيارات، ولا يُحفظ الرابط ولا
  المقطع، ويُحذف الملف المؤقت بعد إرساله. وللحدّ من إساءة الاستخدام يعدّ كل خادم الطلبات لكل عنوان مدة عشر دقائق (في
  o2switch بصيغة مشفّرة تتغير كل يوم) ومجموعها في اليوم، لا أكثر. وتحتفظ جهات الاستضافة بسجلاتها المعتادة (العنوان
  والوقت والصفحة).

### الأطفال

لا تجمع واعية شيئًا من أحد، والأطفال منهم. والرقم السري للوالدين ومدة الانتظار إعدادات محلية لا تُبلَّغ إلى أحد.

### التسجيل في اختبار Google Play على الموقع

الانضمام إلى اختبار Google Play يكون عبر مجموعة Google باسم waaiya-testers@googlegroups.com، تديرها Google وفق سياسة
الخصوصية الخاصة بها: تنضم إليها بحساب Google، ولا يرى عناوين أعضائها إلا المطوّر بصفته مديرها (لا يرى الأعضاء بعضهم، ولا
يُنشر شيء في المجموعة). ثم يتيح Google Play لأعضاء المجموعة تثبيت النسخة التجريبية.

وإن تركت عنوانك أيضًا في waaiya.mssid.org/test/ لتصلك الخطوات بالبريد، يُرسَل العنوان، واسمك إن ذكرته، إلى موقعنا (لدى
o2switch في فرنسا)، ويُحفظ هناك في قائمة خارج الموقع العام، مع الوقت ولغة الصفحة. لا يُستعمل إلا لإرسال الخطوات إليك (من
support@waaiya.mssid.org، بخادم المطوّر نفسه الذي يقرأ القائمة) ولمساعدتك في هذا الاختبار، ويُخبَر المطوّر بكل عنوان عبر بوت
في Telegram (فتمرّ الرسالة بـ Telegram). لا يُنشر العنوان، ولا يُعطى لأحد، ولا يُستعمل لغير ذلك. وللحدّ من إساءة الاستخدام
يعدّ النموذج الإرسالات لكل عنوان مدة ساعة (بصيغة مشفّرة تتغير كل يوم). ولحذف عنوانك، استعمل «الخروج من الاختبار» في الصفحة
نفسها؛ ولترك الاختبار نفسه، غادر المجموعة والبرنامج في Google Play.

### التغييرات والتواصل

واعية من صنع Mssid، وهي المسؤولة عن التطبيق والموقع وهذه السياسة. للأسئلة، أو لطلب يخص بيانات يحفظها الموقع (قائمة التسجيل في الاختبار):
support@waaiya.mssid.org، أو افتح مسألة (issue) في <https://github.com/oksyassine/waaiya>. تُجرى التعديلات على هذه السياسة
في هذا الملف في ذلك المستودع العام حيث يُحفظ تاريخها.

</div>
