// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'واعية';

  @override
  String get tagline =>
      'يزيل الآلات الموسيقية من صوت كل التطبيقات، ويُبقي الكلام والتلاوة.';

  @override
  String get onboardTitle => 'أهلًا بك';

  @override
  String get onboardBody =>
      'تزيل واعية الآلات الموسيقية من صوت كل تطبيقات هذا الهاتف، وتُبقي الكلام وتلاوة القرآن. وتُزال أصوات الغناء أيضًا في الوقت الحالي.';

  @override
  String get onboardQuestion => 'أنا';

  @override
  String get genderMan => 'رجل';

  @override
  String get genderWoman => 'امرأة';

  @override
  String get onboardWhy =>
      'هذا يحدد فقط الخيارات الإضافية التي تظهر لك، ويمكنك تغييره لاحقًا.';

  @override
  String get stateOnTitle => 'التصفية تعمل';

  @override
  String get stateOffTitle => 'التصفية متوقفة';

  @override
  String get stateStarting => 'جارٍ التشغيل…';

  @override
  String stateOnDetail(int delayMs) {
    return 'تُزال الآلات من كل التطبيقات. التأخير نحو $delayMs ميلي ثانية.';
  }

  @override
  String get stateOffDetail => 'اضغط الزر للتشغيل.';

  @override
  String get stateModelFailed =>
      'تعذّر تحميل نموذج الصوت، فكُتم الصوت احتياطًا.';

  @override
  String get stateCaptureDenied =>
      'يلزم إذن الميكروفون لاستقبال صوت التطبيقات الأخرى.';

  @override
  String get stateStoppedBySystem =>
      'أوقف أندرويد التصفية. اضغط الزر للتشغيل من جديد.';

  @override
  String get stateSilencedTitle => 'توقفت التصفية';

  @override
  String get stateSilenced =>
      'توقفت التصفية: التطبيقات الأخرى مكتومة. اضغط الزر للتشغيل من جديد، أو «إيقاف» لسماعها دون تصفية.';

  @override
  String get releaseSilence => 'إيقاف: سماع التطبيقات دون تصفية';

  @override
  String get powerStartCd => 'تشغيل التصفية';

  @override
  String get powerStopCd => 'إيقاف التصفية';

  @override
  String get captureHint =>
      'سيطلب أندرويد مشاركة الشاشة. يُستخدم الصوت فقط، ولا يُسجَّل شيء ولا يُرسَل.';

  @override
  String get needRecordAudio =>
      'تحتاج واعية إذن الميكروفون لاستقبال صوت التطبيقات الأخرى. ولا يسجّل صوتك أبدًا.';

  @override
  String get setupBannerTitle => 'بقيت خطوة واحدة';

  @override
  String get setupBannerBody =>
      'بدون الإعداد أدناه ستسمع الموسيقى والصوت المُصفّى معًا.';

  @override
  String get setupTitle => 'إعداد لمرة واحدة';

  @override
  String get setupBody =>
      'يسمح لواعية بكتم الصوت الأصلي. تفعله مرة واحدة، ويبقى حتى تلغي تثبيت التطبيق.';

  @override
  String get step1Title => 'ثبّت Shizuku';

  @override
  String get step1Body => 'تطبيق مساعد مجاني من متجر Play.';

  @override
  String get step1Action => 'تحميل Shizuku';

  @override
  String get step2Title => 'شغّل Shizuku';

  @override
  String get step2Body =>
      'يعمل Shizuku عبر الـ Wi‑Fi باستخدام ‏«تصحيح الأخطاء اللاسلكي»‏ في أندرويد. اضغط الزر لترى الخطوات، ثم ارجع إلى هنا.';

  @override
  String get step2Action => 'فتح Shizuku';

  @override
  String get step2Update => 'تحديث Shizuku';

  @override
  String get step2TooOld => 'نسخة Shizuku قديمة. حدّثها من متجر Play.';

  @override
  String get step2Denied =>
      'تم ضبط Shizuku على رفض واعية دائمًا. اسمح لها من قائمة التطبيقات في Shizuku.';

  @override
  String get step3Title => 'امنح الإذن';

  @override
  String get step3Body => 'ضغطة واحدة، ثم اختر «سماح».';

  @override
  String get step3Action => 'منح الإذن';

  @override
  String get step3Busy => 'جارٍ الإعداد…';

  @override
  String get setupDoneRestart =>
      'تم. أوقف التصفية ثم شغّلها مرة واحدة لتطبيق ذلك.';

  @override
  String setupFailed(String details) {
    return 'لم يكتمل الإعداد. التفاصيل:\n$details';
  }

  @override
  String get shizukuRefused => 'رُفض إذن Shizuku. اضغط الزر للمحاولة مرة أخرى.';

  @override
  String get stepDoneCd => 'تم';

  @override
  String stepTodoCd(int step) {
    return 'الخطوة $step';
  }

  @override
  String get computerToggle => 'استخدم حاسوبًا بدلًا من ذلك';

  @override
  String get computerBody => 'فعّل تصحيح أخطاء USB، ثم وصّل الهاتف ونفّذ:';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String get computerNote =>
      'السطر الثاني اختياري: يوقف سؤال مشاركة الشاشة عند كل تشغيل.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingSilenceTitle => 'كتم التطبيقات التي تمنع التصفية';

  @override
  String get settingSilenceBody =>
      'مستحسن. بعض التطبيقات لا تسمح بتصفية صوتها، فيُكتم بدل أن تمرّ الموسيقى.';

  @override
  String get settingHoldSilenceTitle =>
      'إبقاء التطبيقات صامتة إذا توقفت التصفية من تلقاء نفسها';

  @override
  String get settingHoldSilenceBody =>
      'مستحسن. إذا أنهى أندرويد التصفية (لا أنت)، تبقى التطبيقات الأخرى صامتة حتى تشغّلها من جديد أو تضغط «إيقاف»، بدل أن تُسمع الموسيقى دون تصفية. يحتاج إلى الإعداد لمرة واحدة.';

  @override
  String get settingStereoTitle => 'صوت ستيريو';

  @override
  String get settingStereoBody =>
      'مُطفأ: صوت أحادي (مونو)، يستهلك نحو نصف البطارية ويتابع على هواتف أكثر. مُشغَّل: يُبقي جهتَي اليمين واليسار منفصلتين. وإن كان الهاتف أبطأ من الستيريو، يعود إلى المونو من تلقاء نفسه.';

  @override
  String get settingSingingTitle => 'كتم غناء النساء';

  @override
  String get settingSingingBody => 'يُبقي كلام النساء وتلاوتهن.';

  @override
  String get settingSingingNoModel =>
      'هذه النسخة بلا كاشف للغناء، لذا تُكتم كل الأصوات ما دام هذا الخيار مفعّلًا.';

  @override
  String get settingRestart => 'أوقف التصفية ثم شغّلها لتطبيق التغييرات.';

  @override
  String get settingGenderTitle => 'أنا';

  @override
  String get change => 'تغيير';

  @override
  String get playerTitle => 'فيديو بتزامن تام';

  @override
  String get playerBody =>
      'شارك فيديو مع واعية (أو استخدم «فتح باستخدام») لمشاهدته مُصفّى بلا تأخير.';

  @override
  String get licences => 'تراخيص المصادر المفتوحة';

  @override
  String get licencesIntro => 'واعية برنامج حر بموجب رخصة Apache 2.0.';

  @override
  String get licencesCc =>
      'رخصة المشاع الإبداعي - النسبة 4.0 (بيانات التدريب): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'النصوص الكاملة';

  @override
  String get back => 'رجوع';

  @override
  String get linkEntryTitle => 'فتح رابط';

  @override
  String get linkEntryBody =>
      'الصق رابطًا من YouTube أو TikTok أو Instagram لمشاهدته أو حفظه بلا موسيقى.';

  @override
  String get linkTitle => 'فتح رابط';

  @override
  String get linkHint => 'https://… (YouTube، TikTok، Instagram…)';

  @override
  String get linkFieldLabel => 'رابط الفيديو أو الصوت';

  @override
  String get linkPaste => 'لصق';

  @override
  String get linkOpen => 'فتح';

  @override
  String get linkResolving => 'جارٍ فتح الرابط…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'مشاهدة بلا موسيقى';

  @override
  String get linkSave => 'حفظ بلا موسيقى';

  @override
  String get linkListen => 'استماع بلا موسيقى';

  @override
  String get linkAudioOnly => 'لا يمكن فتح صورة هذا المقطع بعد: صوته فقط.';

  @override
  String get linkDownloading => 'جارٍ التنزيل…';

  @override
  String get linkFiltering => 'جارٍ إزالة الموسيقى…';

  @override
  String get linkCancel => 'إلغاء';

  @override
  String get linkCancelled => 'أُلغي، ولم يُحفظ شيء.';

  @override
  String get linkTimedOut =>
      'أوقف أندرويد الحفظ: فهو لا يسمح بهذا النوع من العمل إلا بضع ساعات في اليوم. لم يُحفظ شيء؛ افتح واعية وحاول من جديد.';

  @override
  String get linkExportFailed => 'تعذّر الحفظ، ولم يُحفظ شيء.';

  @override
  String get linkSaved => 'حُفظ بلا موسيقى';

  @override
  String get linkSavedVideo => 'في المعرض: الأفلام › Waaiya';

  @override
  String get linkSavedAudio => 'في الموسيقى: Music › Waaiya';

  @override
  String get linkPlay => 'تشغيل';

  @override
  String get linkShare => 'مشاركة';

  @override
  String get linkShareNote => 'لا تشارك إلا المقاطع التي يحق لك مشاركتها.';

  @override
  String get linkLive => 'لا يمكن حفظ البث المباشر.';

  @override
  String get linkBusy => 'يجري حفظ مقطع آخر، يرجى الانتظار حتى ينتهي.';

  @override
  String get linkInvalid => 'الصق رابط ويب (يبدأ بـ https://).';

  @override
  String get linkLogin =>
      'لم يعرض الموقع هذا المقطع دون حساب. المنشورات العامة تُفتح عادةً: حاول مرة أخرى بعد بضع دقائق. أما المنشورات الخاصة فلا يمكن فتحها.';

  @override
  String get linkUnsupported => 'هذا الموقع غير مدعوم.';

  @override
  String get linkPlaylist => 'هذه قائمة تشغيل. افتح مقطعًا واحدًا.';

  @override
  String get linkNoFormat => 'هذا المقطع بصيغة لا تستطيع واعية تصفيتها بعد.';

  @override
  String get linkFailed =>
      'تعذّر فتح هذا الرابط. تحقّق من الاتصال وحاول مرة أخرى.';

  @override
  String get linkPlayFailed =>
      'تعذّر تشغيل هذا المقطع، ولم يُشغَّل أي صوت دون تصفية.';

  @override
  String get linkLimited =>
      'الموقع يحدّ من الطلبات الآن. حاول مرة أخرى بعد بضع دقائق.';

  @override
  String get blurTitle => 'تمويه الشاشة';

  @override
  String get blurBody =>
      'يغطّي الأشخاص والصور على الشاشة في كل التطبيقات ما دامت التصفية تعمل. يعمل على الهاتف، ولا يُرسَل شيء إلى أي مكان.';

  @override
  String get blurWomenTitle => 'تمويه النساء';

  @override
  String get blurWomenBody =>
      'الجسم كله. ويُموَّه أيضًا كل من لا يتبيّن للتطبيق بوضوح أنه رجل.';

  @override
  String get blurNudityTitle => 'تمويه الصور غير المحتشمة';

  @override
  String get blurNudityBody =>
      'العري واللباس الكاشف، لأي أحد: تُغطّى الشاشة كلها.';

  @override
  String get blurFailTitle => 'تغطية الشاشة إذا عجز التمويه عن المتابعة';

  @override
  String get blurFailBody =>
      'مفعّل: تُغطّى الشاشة كلها إذا كان الهاتف بطيئًا أو تعطّل التمويه. غير مفعّل: تبقى الشاشة ظاهرة مع تنبيه.';

  @override
  String get blurSetupShizuku => 'السماح عبر Shizuku';

  @override
  String get blurSetupManual => 'السماح من إعدادات أندرويد';

  @override
  String get blurStatusNeedsSetup =>
      'يحتاج التمويه إلى الظهور فوق التطبيقات الأخرى. الأفضل: اسمح بذلك عبر Shizuku (يشغّل خدمة الإتاحة «تمويه واعية» فتبقى اللمسات تصل إلى التطبيق تحته). أو اسمح بـ«الظهور فوق التطبيقات الأخرى» من إعدادات أندرويد (وحينها تضيع اللمسات على المنطقة المموّهة).';

  @override
  String get blurStatusNeedsOverlay =>
      'يحتاج التمويه إلى الظهور فوق التطبيقات الأخرى. الأفضل: شغّل Shizuku (واسمح لواعية فيه): فيرسم التمويه طبقته الخاصة التي تمرّ عبرها اللمسات. وإلا فاسمح بـ«الظهور فوق التطبيقات الأخرى» من إعدادات أندرويد، وحينها لا يصل اللمس على منطقة مموّهة إلى التطبيق تحتها.';

  @override
  String get blurFailUnavailable =>
      'معطّل مؤقتًا: تغطية الشاشة كلها ستمنع كل لمس وقد تعلق. شغّل Shizuku (أندرويد 12 أو أحدث) فيتفعّل هذا الخيار: يرسم Shizuku الأغطية ويمرّ اللمس من خلالها. وحتى ذلك الحين، إذا عجز التمويه عن المتابعة تبقى الشاشة ظاهرة مع تنبيه.';

  @override
  String get blurFailNeedsA11y =>
      'معطّل مؤقتًا: تغطية الشاشة كلها ستمنع كل لمس وقد تعلق. شغّل Shizuku (أندرويد 12 أو أحدث) أو فعّل خدمة الإتاحة «تمويه واعية» (السماح عبر Shizuku أعلاه) فيتفعّل هذا الخيار. وحتى ذلك الحين تبقى الشاشة ظاهرة مع تنبيه.';

  @override
  String get languageTitle => 'اللغة';

  @override
  String settingLanguageTitle(String language) {
    return 'اللغة: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'أوقف التصفية ثم شغّلها لتطبيق إعدادات التمويه.';

  @override
  String get blurStatusStarting => 'جارٍ تشغيل التمويه…';

  @override
  String get blurStatusOn => 'التمويه يعمل.';

  @override
  String get blurStatusOnVisible =>
      'التمويه يعمل بوضع الحذر: هذا الهاتف يُظهر التمويه في التقاط الشاشة نفسه، فتبقى المنطقة المموّهة مموّهة حتى يتغيّر المشهد.';

  @override
  String get blurStatusModels =>
      'هذه النسخة تفتقد نموذج التمويه للخيار المختار.';

  @override
  String get blurStatusFailing => 'التمويه عاجز عن المتابعة الآن.';

  @override
  String get blurStatusNoOverlay =>
      'لا يستطيع التمويه الظهور فوق التطبيقات الأخرى: اسمح بذلك أعلاه.';

  @override
  String blurStatusNoCapture(String details) {
    return 'لا يستطيع التمويه رؤية الشاشة. التفاصيل:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'تعذّر السماح عبر Shizuku:\n$details';
  }

  @override
  String get step2Guide => 'كيف أشغّل Shizuku؟';

  @override
  String get blurFailOldAndroid =>
      'معطّل: في هذه النسخة من أندرويد ستمنع تغطية الشاشة كلها كل لمس وقد تعلق (أغطية Shizuku تحتاج أندرويد 12 أو أحدث). إذا عجز التمويه عن المتابعة تبقى الشاشة ظاهرة مع تنبيه.';

  @override
  String get guideTitle => 'تشغيل Shizuku خطوة بخطوة';

  @override
  String get guideOpenDev => 'خيارات المطور';

  @override
  String get guideOpenShizuku => 'فتح Shizuku';

  @override
  String get guideClose => 'إغلاق';

  @override
  String get guideBody =>
      'تحتاج إلى شبكة Wi‑Fi وأندرويد 11 أو أحدث. الإقران يكون مرة واحدة فقط، وبعد إعادة تشغيل الهاتف تكرّر الخطوة 7 وحدها.\n\n1. اتصل بشبكة Wi‑Fi.\n\n2. فعّل ‏«خيارات المطور»‏: الإعدادات › حول الهاتف › معلومات البرنامج › اضغط على ‏«رقم الإصدار»‏ 7 مرات. (في الهواتف الأخرى: الإعدادات › حول الهاتف › رقم الإصدار.)\n\n3. افتح Shizuku. إذا طلب إظهار الإشعارات فاسمح له، لأن رمز الإقران يُكتب داخل إشعار Shizuku.\n\n4. في Shizuku، تحت ‏«Start via Wireless debugging»‏ (التشغيل عبر تصحيح الأخطاء اللاسلكي)، اضغط ‏«Pairing»‏ (إقران). في الصفحة التي تفتح اضغط ‏«Developer options»‏ (خيارات المطور)، وفعّل ‏«تصحيح الأخطاء اللاسلكي»‏، ووافق بـ‏«سماح»‏.\n\n5. اضغط على عبارة ‏«تصحيح الأخطاء اللاسلكي»‏ نفسها (لا على المفتاح)، ثم ‏«إقران الجهاز باستخدام رمز الإقران»‏. سيظهر رمز من 6 أرقام.\n\n6. اترك تلك الشاشة مفتوحة واسحب الإشعارات إلى الأسفل. عندما يظهر في إشعار Shizuku ‏«Pairing service found»‏ (تم العثور على خدمة الإقران) اضغط ‏«Enter pairing code»‏ (إدخال رمز الإقران)، واكتب الرمز. سيُخبرك Shizuku بنجاح الإقران.\n\n7. ارجع إلى Shizuku واضغط ‏«Start»‏ (بدء) تحت ‏«Start via Wireless debugging»‏، وانتظر حتى تظهر عبارة ‏«Shizuku is running»‏ (Shizuku يعمل).\n\n8. ارجع إلى واعية واضغط ‏«منح الإذن»‏ ثم ‏«السماح»‏.\n\nبعد إعادة تشغيل الهاتف يتوقف Shizuku: اتصل بالـ Wi‑Fi، وأعد تفعيل ‏«تصحيح الأخطاء اللاسلكي»‏ إن كان مطفأً، ثم افتح Shizuku واضغط ‏«Start»‏. لا حاجة إلى إقران جديد.';

  @override
  String get wsetupRouteTitle => 'الإعداد على هذا الهاتف (دون تطبيق إضافي)';

  @override
  String get wsetupRouteBody =>
      'باستخدام ‏«تصحيح الأخطاء اللاسلكي»‏ الموجود في أندرويد نفسه. تحتاج إلى شبكة Wi‑Fi (لا يلزم الإنترنت). الإقران يكون مرة واحدة فقط.';

  @override
  String get wsetupSteps =>
      '1. اضغط ‏«ابدأ»‏. تفتح واعية ‏«خيارات المطور»‏ وتُظهر إشعارًا.\n\n2. إذا كانت ‏«خيارات المطور»‏ غير مفعّلة، تُفتح صفحة ‏«حول الهاتف»‏ بدلًا منها: اضغط على ‏«رقم الإصدار»‏ 7 مرات (في بعض الهواتف تجده داخل ‏«معلومات البرنامج»‏)، ثم ارجع إلى هنا واضغط ‏«ابدأ»‏ مرة أخرى.\n\n3. انزل في الصفحة إلى ‏«تصحيح الأخطاء اللاسلكي»‏ (ضمن قسم ‏«تصحيح الأخطاء»‏)، وفعّله وأكّد بالضغط على ‏«سماح»‏.\n\n4. اضغط على عبارة ‏«تصحيح الأخطاء اللاسلكي»‏ نفسها (لا على المفتاح)، ثم على ‏«إقران الجهاز باستخدام رمز الإقران»‏. يظهر رمز من 6 أرقام.\n\n5. اترك تلك الشاشة مفتوحة. اسحب الإشعارات إلى الأسفل، واضغط ‏«أدخل الرمز»‏ في إشعار واعية واكتب الرمز.\n\n6. تُكمل واعية الباقي وحدها وتقول ‏«اكتمل الإعداد»‏. بعدها يمكنك إيقاف ‏«تصحيح الأخطاء اللاسلكي»‏.';

  @override
  String get wsetupStart => 'ابدأ';

  @override
  String get wsetupEnterHere => 'اكتب الرمز هنا';

  @override
  String get wsetupCancel => 'إلغاء';

  @override
  String get wsetupAndroid10 =>
      'أندرويد 10 لا يستطيع إتمام الإعداد وحده: يحتاج إلى حاسوب، إما مباشرة (في الأسفل) أو لتشغيل Shizuku مرة واحدة.';

  @override
  String get wsetupShizukuHeading => 'أو باستخدام تطبيق Shizuku';

  @override
  String get wsetupShizukuNote =>
      'يسمح Shizuku أيضًا بمرور اللمس عبر أغطية الشاشة.';

  @override
  String get wsetupChannel => 'الإعداد لمرة واحدة';

  @override
  String get wsetupNotifTitle => 'إعداد واعية: في انتظار رمز الإقران';

  @override
  String get wsetupFoundTitle => 'وُجدت شاشة الإقران';

  @override
  String get wsetupBusyTitle => 'إعداد واعية';

  @override
  String get wsetupDoneTitle => 'اكتمل الإعداد';

  @override
  String get wsetupDoneBody =>
      'تستطيع واعية الآن كتم الصوت الأصلي. يمكنك إيقاف ‏«تصحيح الأخطاء اللاسلكي»‏.';

  @override
  String get wsetupFailedTitle => 'لم يكتمل الإعداد';

  @override
  String get wsetupPairing => 'جارٍ الإقران…';

  @override
  String get wsetupConnecting => 'جارٍ الاتصال ومنح الأذونات…';

  @override
  String get wsetupNeedWifi =>
      'اتصل بشبكة Wi‑Fi أولًا (لا يلزم الإنترنت): ‏«تصحيح الأخطاء اللاسلكي»‏ لا يعمل إلا عبر Wi‑Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'في ‏«خيارات المطور»‏، فعّل ‏«تصحيح الأخطاء اللاسلكي»‏، ثم اضغط على اسمه ثم على ‏«إقران الجهاز باستخدام رمز الإقران»‏.';

  @override
  String get wsetupOpenDialog =>
      'في ‏«تصحيح الأخطاء اللاسلكي»‏، اضغط ‏«إقران الجهاز باستخدام رمز الإقران»‏. اترك الرمز ظاهرًا على الشاشة واضغط ‏«أدخل الرمز»‏ هنا.';

  @override
  String get wsetupEnterCodeBody =>
      'اضغط ‏«أدخل الرمز»‏ واكتب الرمز المكوّن من 6 أرقام الظاهر في الإعدادات.';

  @override
  String get wsetupCodeWaiting =>
      'وصل الرمز. في انتظار شاشة ‏«إقران الجهاز باستخدام رمز الإقران»‏: اتركها مفتوحة.';

  @override
  String get wsetupWrongCode =>
      'لم يُقبل هذا الرمز. تحقّق من الأرقام الستة الظاهرة على الشاشة وأدخلها مرة أخرى. إذا أُغلقت شاشة الإقران فافتحها من جديد، فالرمز يتغيّر.';

  @override
  String get wsetupPairingFailed =>
      'لم ينجح الإقران. أغلق شاشة الإقران، وافتح ‏«إقران الجهاز باستخدام رمز الإقران»‏ مرة أخرى وأدخل الرمز الجديد.';

  @override
  String get wsetupWaitingConnect =>
      'تم الإقران. أبقِ ‏«تصحيح الأخطاء اللاسلكي»‏ مفعّلًا: واعية تتصل الآن.';

  @override
  String get wsetupNotPaired =>
      'لم يعد هذا الهاتف يعرف واعية (أُزيل الإقران أو انتهت مدته). افتح ‏«إقران الجهاز باستخدام رمز الإقران»‏ وأدخل الرمز.';

  @override
  String get wsetupConnectFailed =>
      'تعذّر الاتصال بـ ‏«تصحيح الأخطاء اللاسلكي»‏. أوقفه ثم فعّله مرة أخرى، وستعيد واعية المحاولة وحدها.';

  @override
  String get wsetupGrantFailed =>
      'تم الاتصال، لكن الأذونات ما زالت ناقصة. استخدم Shizuku أو حاسوبًا (في الأسفل).';

  @override
  String get wsetupTimeout =>
      'توقّف الإعداد بعد 10 دقائق دون أن يكتمل. اضغط ‏«ابدأ»‏ للمحاولة مرة أخرى.';

  @override
  String get wsetupCodeUnreadable => 'اكتب الأرقام الستة لرمز الإقران.';

  @override
  String get wsetupCodeHint => 'رمز من 6 أرقام';

  @override
  String get wsetupEnterCode => 'أدخل الرمز';

  @override
  String wsetupDetail(String details) {
    return 'التفاصيل: $details';
  }

  @override
  String get wsetupErrTimeout => 'لم يأتِ رد في الوقت المحدد';

  @override
  String get wsetupErrRefused => 'رُفض الاتصال';

  @override
  String get wsetupDevOff =>
      '‏«خيارات المطور»‏ غير مفعّلة. في ‏«حول الهاتف»‏ اضغط على ‏«رقم الإصدار»‏ 7 مرات (في بعض الهواتف تجده داخل ‏«معلومات البرنامج»‏)، ثم ارجع إلى هنا واضغط ‏«ابدأ»‏ مرة أخرى.';

  @override
  String get wsetupOpenAbout => 'حول الهاتف';

  @override
  String get wsetupNotifOff =>
      'إشعارات واعية متوقفة، فلا يمكن كتابة الرمز في إشعار. استخدم تقسيم الشاشة (الإعدادات في نصف وواعية في النصف الآخر) واضغط ‏«اكتب الرمز هنا»‏.';

  @override
  String get wsetupCodeDialogTitle => 'رمز الإقران';

  @override
  String get wsetupCodeDialogBody =>
      'مع تقسيم الشاشة فقط (الإعدادات في نصف وواعية في النصف الآخر): الخروج من الإعدادات يُغلق شاشة الإقران فيتوقف رمزها عن العمل. اكتب الرمز المكوّن من 6 أرقام الظاهر تحت ‏«إقران الجهاز باستخدام رمز الإقران»‏.';

  @override
  String get wsetupCodeOk => 'إقران';

  @override
  String get blurStrictTitle => 'مَن يبقى دون تغطية';

  @override
  String blurStrictValue(String level) {
    return 'مَن يبقى دون تغطية: $level';
  }

  @override
  String get blurStrict0 => 'صارم: فقط من يكاد التطبيق يجزم أنه رجل';

  @override
  String get blurStrict1 => 'متوازن: نحو ضعف عدد الرجال دون تغطية';

  @override
  String get blurStrict2 => 'متساهل: رجال أكثر قليلًا من المتوازن';

  @override
  String get blurStrict0Short => 'صارم';

  @override
  String get blurStrict1Short => 'متوازن';

  @override
  String get blurStrict2Short => 'متساهل';

  @override
  String get blurStrictHelp =>
      'كل من لا يتأكد التطبيق أنه رجل يُغطّى. في الوضع الصارم يبقى نحو 7 رجال من كل 100 دون تغطية، وفي المتوازن نحو 14، وفي المتساهل نحو 16. وكل درجة أقل صرامة تترك أيضًا نحو امرأة واحدة إضافية من كل 100 دون تغطية.';

  @override
  String get stateOnNotMuted =>
      'الصوت الأصلي لم يُكتم بعد، ولذلك تسمع الموسيقى مع الصوت المُصفّى. أكمل الإعداد لمرة واحدة أدناه.';

  @override
  String get stateOnMuteFailing =>
      'لا تستطيع واعية كتم الصوت الأصلي للتطبيق الذي يعمل الآن، ولذلك قد تُسمع الموسيقى. أوقف التصفية ثم شغّلها. وإن استمر ذلك فأرسل تقرير التشخيص (أسفل هذه الشاشة).';

  @override
  String get stateTooSlow =>
      'هذا الهاتف أبطأ من أن يصفّي الصوت مباشرة، ولذلك يتقطّع الصوت. خيار «فتح رابط» أدناه يعمل: فهو يصفّي الفيديو قبل تشغيله.';

  @override
  String get stateMonoNote =>
      'الصوت أحادي (مونو) ليتمكن هذا الهاتف من المتابعة.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'كُتم صوته لأنه لا يسمح بالتصفية: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'يُسمع دون تصفية لأنه لا يسمح بها: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'لم يُعطِ أندرويد واعية صوت التطبيقات الأخرى. اضغط الزر للتشغيل من جديد.';

  @override
  String get stateCaptureCancelled =>
      'أُلغي التشغيل عند سؤال أندرويد عن مشاركة الشاشة. تحتاج واعية أن تختار «بدء» هناك لاستقبال الصوت. لا يُسجَّل شيء ولا يُرسَل.';

  @override
  String get startNoSetupTitle => 'ستبقى الموسيقى مسموعة';

  @override
  String get startNoSetupBody =>
      'الإعداد لمرة واحدة لم يكتمل بعد. بدونه لا تستطيع واعية كتم الصوت الأصلي، فتسمع الموسيقى والصوت المُصفّى معًا.\n\nخيار «فتح رابط» يعمل دون أي إعداد.';

  @override
  String get startNoSetupSetup => 'أكمل الإعداد';

  @override
  String get startNoSetupAnyway => 'شغّل على أي حال';

  @override
  String get diagButton => 'مشكلة؟ تقرير التشخيص';

  @override
  String get diagTitle => 'تقرير التشخيص';

  @override
  String get diagNote =>
      'ما تراه واعية على هذا الهاتف. انسخه أو شاركه مع من يساعدك. التطبيق نفسه لا يرسل شيئًا.';

  @override
  String get notifStoppedTitle => 'توقفت واعية';

  @override
  String get notifStoppedText => 'الصوت لم يعد يُصفّى. اضغط للتشغيل من جديد.';

  @override
  String get desktopPreview =>
      'معاينة: محرك التصفية غير موصول بهذا الحاسوب بعد. الزر يعرض فقط كيف سيعمل التطبيق.';

  @override
  String actionFailed(String details) {
    return 'تعذّر ذلك: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'تُزال الآلات من كل التطبيقات.';

  @override
  String get engineErrorNoPactl =>
      'لم يُعثر على أدوات الصوت (pactl). تحتاج واعية إلى PulseAudio، أو PipeWire مع pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'خادم الصوت لا يعمل (PulseAudio أو PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'لا توجد في هذا النظام جلسة systemd للمستخدم، وهي التي تشغّل التصفية في الخلفية.';

  @override
  String get engineErrorNoOutput => 'لم يُعثر على مكبّرات صوت أو سماعات.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'تعذّر تثبيت التصفية. التفاصيل:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'لم تبدأ التصفية. التفاصيل:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'توقّفت التصفية بسبب خطأ. التفاصيل:\n$details';
  }

  @override
  String get autostartTitle => 'التشغيل عند تسجيل الدخول';

  @override
  String get autostartBody => 'تصفية الصوت فور تسجيل الدخول.';

  @override
  String get blurBodyDesktop =>
      'يغطّي الأشخاص والصور على الشاشة، فوق كل النوافذ، ما دامت واعية مفتوحة (سواء كانت تصفية الصوت تعمل أم لا). يعمل على هذا الحاسوب، ولا يُرسَل شيء إلى أي مكان. إغلاق نافذة واعية يوقف التمويه.';

  @override
  String get blurFailBodyDesktop =>
      'مفعّل: تُغطّى الشاشة كلها إذا كان الحاسوب أبطأ من اللازم أو تعطّل التمويه، وتبقى النقرات تصل إلى النوافذ تحته. معطّل: تبقى الشاشة ظاهرة مع شريط أحمر في أعلاها.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'التمويه يعمل. يظهر التمويه في التقاط الشاشة على هذا الحاسوب، لذا تبقى المنطقة المموّهة مموّهة حتى يتغيّر المشهد.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'لا يستطيع التمويه الرسم فوق النوافذ الأخرى في سطح المكتب هذا. التفاصيل:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'اختر شاشتك في نافذة مشاركة الشاشة واسمح بها. تسأل واعية مرة واحدة فقط، وتبقى الصورة على هذا الحاسوب.';

  @override
  String blurStatusExited(String details) {
    return 'توقّف التمويه على نحو غير متوقّع. أطفئ أحد خيارات التمويه ثم شغّله لتجرّب من جديد. التفاصيل:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'لم يُحمَّل كاشف غناء النساء، لذا تُكتم الأصوات ما دام هذا الخيار مفعّلًا.';

  @override
  String get blurStatusUncovered =>
      'إحدى الشاشات لا يغطّيها التمويه: لم تُشارَك معه، أو وُصلت لاحقًا. أطفئ أحد خيارات التمويه ثم شغّله، واختر كل الشاشات في نافذة مشاركة الشاشة.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'نماذج التمويه غير موجودة في هذا التثبيت، لذا لا يستطيع تغطية شيء، ويبقى شريط أحمر في أعلى الشاشة. أعد تثبيت واعية.';

  @override
  String get diagNoteDesktop =>
      'ما تراه واعية على هذا الحاسوب. انسخه وأعطه لمن يساعدك. التطبيق نفسه لا يرسل شيئًا.';
}
