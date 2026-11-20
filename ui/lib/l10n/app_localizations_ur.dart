// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'واعية';

  @override
  String get tagline =>
      'ہر ایپ سے موسیقی کے آلات ہٹاتی ہے اور بات چیت اور تلاوت باقی رکھتی ہے۔';

  @override
  String get onboardTitle => 'خوش آمدید';

  @override
  String get onboardBody =>
      'واعية اس فون کی ہر ایپ کی آواز سے موسیقی کے آلات ہٹاتی ہے۔ بات چیت اور قرآن کی تلاوت باقی رہتی ہے۔ فی الحال گانے کی آوازیں بھی ہٹا دی جاتی ہیں۔';

  @override
  String get onboardQuestion => 'میں ہوں';

  @override
  String get genderMan => 'مرد';

  @override
  String get genderWoman => 'عورت';

  @override
  String get onboardWhy =>
      'اس سے صرف یہ طے ہوتا ہے کہ آپ کو کون سی اختیاری ترتیبات نظر آئیں۔ آپ اسے بعد میں بدل سکتے ہیں۔';

  @override
  String get stateOnTitle => 'فلٹرنگ آن ہے';

  @override
  String get stateOffTitle => 'فلٹرنگ آف ہے';

  @override
  String get stateStarting => 'شروع ہو رہا ہے…';

  @override
  String stateOnDetail(int delayMs) {
    return 'تمام ایپس سے آلات ہٹائے جا رہے ہیں۔ تاخیر تقریباً $delayMs ملی سیکنڈ۔';
  }

  @override
  String get stateOffDetail => 'شروع کرنے کے لیے بٹن تھپتھپائیں۔';

  @override
  String get stateModelFailed =>
      'آواز کا ماڈل لوڈ نہیں ہو سکا، اس لیے احتیاطاً آواز بند کر دی گئی ہے۔';

  @override
  String get stateCaptureDenied =>
      'دوسری ایپس کی آواز وصول کرنے کے لیے مائیکروفون کی اجازت درکار ہے۔';

  @override
  String get stateStoppedBySystem =>
      'Android نے فلٹرنگ روک دی۔ دوبارہ شروع کرنے کے لیے بٹن تھپتھپائیں۔';

  @override
  String get stateSilencedTitle => 'فلٹرنگ رک گئی';

  @override
  String get stateSilenced =>
      'فلٹرنگ رک گئی: دوسری ایپس خاموش ہیں۔ دوبارہ شروع کرنے کے لیے بٹن تھپتھپائیں، یا انہیں بغیر فلٹر کے سننے کے لیے “روکیں”۔';

  @override
  String get releaseSilence => 'روکیں: ایپس کو بغیر فلٹر سنیں';

  @override
  String get powerStartCd => 'فلٹرنگ شروع کریں';

  @override
  String get powerStopCd => 'فلٹرنگ روکیں';

  @override
  String get captureHint =>
      'Android آپ کی اسکرین کا اشتراک کرنے کو کہے گا۔ صرف آواز استعمال ہوتی ہے: نہ کچھ ریکارڈ ہوتا ہے نہ کہیں بھیجا جاتا ہے۔';

  @override
  String get needRecordAudio =>
      'دوسری ایپس کی آواز وصول کرنے کے لیے واعية کو مائیکروفون کی اجازت درکار ہے۔ یہ کبھی آپ کی آواز ریکارڈ نہیں کرتی۔';

  @override
  String get setupBannerTitle => 'ایک اور قدم';

  @override
  String get setupBannerBody =>
      'نیچے دیے گئے ایک بار کے سیٹ اپ کے بغیر آپ کو موسیقی اور فلٹر شدہ آواز ایک ساتھ سنائی دے گی۔';

  @override
  String get step1Title => 'Shizuku انسٹال کریں';

  @override
  String get step1Body => 'Play Store سے ایک مفت مددگار ایپ۔';

  @override
  String get step1Action => 'Shizuku حاصل کریں';

  @override
  String get step2Title => 'Shizuku شروع کریں';

  @override
  String get step2Body =>
      'Shizuku، Android کی وائرلیس ڈیبگنگ کے ذریعے Wi-Fi پر شروع ہوتی ہے۔ مراحل دیکھنے کے لیے بٹن تھپتھپائیں، پھر واپس آئیں۔';

  @override
  String get step2Action => 'Shizuku کھولیں';

  @override
  String get step2Update => 'Shizuku اپ ڈیٹ کریں';

  @override
  String get step2TooOld =>
      'آپ کا Shizuku ورژن بہت پرانا ہے۔ اسے Play Store سے اپ ڈیٹ کریں۔';

  @override
  String get step2Denied =>
      'Shizuku میں واعية کو ہمیشہ مسترد کرنا سیٹ ہے۔ Shizuku میں ایپس کی فہرست میں اسے اجازت دیں۔';

  @override
  String get step3Title => 'اجازت عطا کریں';

  @override
  String get step3Body => 'ایک بار تھپتھپائیں، پھر “اجازت دیں” منتخب کریں۔';

  @override
  String get step3Action => 'اجازت عطا کریں';

  @override
  String get step3Busy => 'سیٹ اپ ہو رہا ہے…';

  @override
  String get setupDoneRestart =>
      'ہو گیا۔ اسے لاگو کرنے کے لیے ایک بار فلٹرنگ روک کر دوبارہ شروع کریں۔';

  @override
  String setupFailed(String details) {
    return 'سیٹ اپ مکمل نہیں ہوا۔ تفصیلات:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Shizuku کی اجازت مسترد کر دی گئی۔ دوبارہ کوشش کرنے کے لیے بٹن تھپتھپائیں۔';

  @override
  String get setupSlow =>
      'Shizuku معمول سے زیادہ وقت لے رہی ہے۔ انتظار کرتے رہیں: کچھ فونز پر پہلی بار اس کے مددگار کو شروع ہونے میں ایک منٹ تک لگتا ہے۔';

  @override
  String get setupTimeout =>
      'Shizuku نے 2 منٹ میں جواب نہیں دیا۔ Shizuku کھولیں، دیکھیں کہ وہ چلنے کا بتا رہی ہے، پھر بٹن دوبارہ تھپتھپائیں۔ اگر سیٹ اپ بعد میں مکمل ہو جائے تو یہ اسکرین خود بخود اپ ڈیٹ ہو جائے گی۔';

  @override
  String get setupRefusedXiaomi =>
      'اس فون نے اجازتیں مسترد کر دیں۔ Xiaomi، Redmi اور POCO پر، ڈویلپر کے اختیارات میں “USB debugging (Security settings)” (‏USB ڈیبگنگ - سیکیورٹی کی ترتیبات) آن کریں (یہ Xiaomi اکاؤنٹ میں سائن ان کرنے کو کہتا ہے)، پھر دوبارہ کوشش کریں۔';

  @override
  String get setupRefusedColoros =>
      'اس فون نے اجازتیں مسترد کر دیں۔ OPPO، OnePlus اور realme پر، ڈویلپر کے اختیارات میں “Disable permission monitoring” (اجازت کی نگرانی غیر فعال کریں) آن کریں (نئے ورژنز میں اس کا نام “Disable system optimization” (سسٹم کی اصلاح غیر فعال کریں) ہے، اور یہ شاید صرف فون کی زبان انگریزی ہونے پر دکھائی دے)۔ اسے ڈھونڈنے کے لیے ترتیبات میں “permission” تلاش کریں۔ پھر دوبارہ کوشش کریں۔';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi، Redmi اور POCO: اگر اطلاع میں کوڈ ٹائپ کرنے کی جگہ نہ ہو تو اطلاعات کی ترتیبات میں اطلاع کا انداز “Android” پر سیٹ کریں، یا اسپلٹ اسکرین کے ساتھ کوڈ واعية میں ٹائپ کریں۔';

  @override
  String get stepDoneCd => 'مکمل';

  @override
  String stepTodoCd(int step) {
    return 'مرحلہ $step';
  }

  @override
  String get computerToggle => 'اس کے بجائے کمپیوٹر استعمال کریں';

  @override
  String get computerBody =>
      '‏USB ڈیبگنگ آن کریں، فون کو کمپیوٹر سے منسلک کریں اور یہ چلائیں:';

  @override
  String get copy => 'کاپی کریں';

  @override
  String get copied => 'کاپی ہو گیا';

  @override
  String get computerNote =>
      'دوسری لائن اختیاری ہے: یہ ہر بار شروع کرنے پر اسکرین کے اشتراک کا سوال بند کر دیتی ہے۔';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get settingSilenceTitle => 'فلٹرنگ روکنے والی ایپس کو خاموش کریں';

  @override
  String get settingSilenceBody =>
      'تجویز کردہ۔ کچھ ایپس اپنی آواز فلٹر نہیں ہونے دیتیں؛ یہ موسیقی کو گزرنے دینے کے بجائے انہیں خاموش کر دیتا ہے۔';

  @override
  String get settingHoldSilenceTitle =>
      'اگر فلٹرنگ خود رک جائے تو ایپس کو خاموش رکھیں';

  @override
  String get settingHoldSilenceBody =>
      'تجویز کردہ۔ اگر Android فلٹرنگ ختم کر دے (آپ نہیں)، تو دوسری ایپس خاموش رہتی ہیں جب تک آپ دوبارہ شروع نہ کریں یا “روکیں” نہ تھپتھپائیں، بجائے اس کے کہ موسیقی بغیر فلٹر کے چلے۔ ایک بار کا سیٹ اپ درکار ہے۔';

  @override
  String get settingStereoTitle => 'اسٹیریو آواز';

  @override
  String get settingStereoBody =>
      'آف: مونو، جو تقریباً آدھی بیٹری استعمال کرتا ہے اور زیادہ فونز پر ساتھ چل پاتا ہے۔ آن: بائیں اور دائیں اطراف الگ رکھتا ہے۔ اگر فون اسٹیریو کے لیے بہت سست ہو تو یہ پھر بھی خود بخود مونو پر چلا جاتا ہے۔';

  @override
  String get settingSingingTitle => 'خواتین کا گانا خاموش کریں';

  @override
  String get settingSingingBody => 'خواتین کی بات چیت اور تلاوت باقی رہتی ہے۔';

  @override
  String get settingSingingNoModel =>
      'اس ورژن میں گانے کا ڈیٹیکٹر نہیں ہے، اس لیے جب تک یہ آن ہے تمام آوازیں خاموش رہتی ہیں۔';

  @override
  String get settingRestart =>
      'تبدیلیاں لاگو کرنے کے لیے فلٹرنگ روک کر دوبارہ شروع کریں۔';

  @override
  String get settingGenderTitle => 'میں ہوں';

  @override
  String get change => 'تبدیل کریں';

  @override
  String get playerTitle => 'مکمل ہم آہنگی میں ویڈیوز';

  @override
  String get playerBody =>
      'کوئی ویڈیو واعية کے ساتھ شیئر کریں (یا “اس کے ساتھ کھولیں” استعمال کریں) تاکہ اسے بغیر تاخیر کے فلٹر شدہ دیکھیں۔';

  @override
  String get licences => 'اوپن سورس لائسنس';

  @override
  String get licencesIntro =>
      'واعية، GNU Affero General Public License v3 یا اس کے بعد کے ورژن کے تحت آزاد سافٹ ویئر ہے۔ سورس کوڈ: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (تربیتی ڈیٹا): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'مکمل متن';

  @override
  String get back => 'واپس';

  @override
  String get linkEntryTitle => 'لنک کھولیں';

  @override
  String get linkEntryBody =>
      'YouTube، TikTok یا Instagram کا لنک پیسٹ کریں تاکہ اسے بغیر موسیقی کے دیکھیں یا محفوظ کریں۔';

  @override
  String get linkTitle => 'لنک کھولیں';

  @override
  String get linkHint => 'https://… (YouTube، TikTok، Instagram…)';

  @override
  String get linkFieldLabel => 'ویڈیو یا آڈیو لنک';

  @override
  String get linkPaste => 'پیسٹ کریں';

  @override
  String get linkOpen => 'کھولیں';

  @override
  String get linkResolving => 'لنک کھل رہا ہے…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'بغیر موسیقی دیکھیں';

  @override
  String get linkSave => 'بغیر موسیقی محفوظ کریں';

  @override
  String get linkListen => 'بغیر موسیقی سنیں';

  @override
  String get linkAudioOnly =>
      'اس لنک کی ویڈیو ابھی نہیں کھل سکتی: صرف اس کی آواز۔';

  @override
  String get linkDownloading => 'ڈاؤن لوڈ ہو رہا ہے…';

  @override
  String get linkFiltering => 'موسیقی ہٹائی جا رہی ہے…';

  @override
  String get linkCancel => 'منسوخ کریں';

  @override
  String get linkCancelled => 'منسوخ ہو گیا۔ کچھ محفوظ نہیں ہوا۔';

  @override
  String get linkTimedOut =>
      'Android نے محفوظ کرنا روک دیا: وہ اس قسم کے کام کی اجازت دن میں صرف چند گھنٹے دیتا ہے۔ کچھ محفوظ نہیں ہوا؛ واعية کھولیں اور دوبارہ کوشش کریں۔';

  @override
  String get linkExportFailed =>
      'اسے محفوظ نہیں کیا جا سکا۔ کچھ محفوظ نہیں ہوا۔';

  @override
  String get linkSaved => 'بغیر موسیقی محفوظ ہو گیا';

  @override
  String get linkSavedVideo => 'آپ کی گیلری میں: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'آپ کی موسیقی میں: Music › Waaiya';

  @override
  String get linkPlay => 'چلائیں';

  @override
  String get linkShare => 'شیئر کریں';

  @override
  String get linkShareNote =>
      'صرف وہی ویڈیوز شیئر کریں جنہیں شیئر کرنے کی آپ کو اجازت ہے۔';

  @override
  String get linkLive => 'لائیو اسٹریمز محفوظ نہیں کی جا سکتیں۔';

  @override
  String get linkBusy =>
      'ایک اور ویڈیو محفوظ ہو رہی ہے۔ براہ کرم اس کے مکمل ہونے کا انتظار کریں۔';

  @override
  String get linkInvalid =>
      'براہ کرم ویب لنک پیسٹ کریں (جو https:// سے شروع ہو)۔';

  @override
  String get linkLogin =>
      'اس سائٹ نے یہ ویڈیو اکاؤنٹ کے بغیر نہیں دکھائی۔ عوامی پوسٹس عموماً کھل جاتی ہیں: چند منٹ بعد دوبارہ کوشش کریں۔ نجی پوسٹس نہیں کھولی جا سکتیں۔';

  @override
  String get linkUnsupported => 'یہ سائٹ تعاون یافتہ نہیں ہے۔';

  @override
  String get linkPlaylist => 'یہ ایک پلے لسٹ ہے۔ براہ کرم ایک ویڈیو کھولیں۔';

  @override
  String get linkNoFormat =>
      'یہ ویڈیو ایسے فارمیٹ میں ہے جسے واعية ابھی فلٹر نہیں کر سکتی۔';

  @override
  String get linkFailed =>
      'یہ لنک نہیں کھل سکا۔ اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get linkPlayFailed =>
      'اسے چلایا نہیں جا سکا۔ بغیر فلٹر کے کچھ نہیں چلایا گیا۔';

  @override
  String get linkLimited =>
      'یہ سائٹ اس وقت درخواستیں محدود کر رہی ہے۔ چند منٹ بعد دوبارہ کوشش کریں۔';

  @override
  String get blurTitle => 'اسکرین کی دھندلاہٹ';

  @override
  String get blurBody =>
      'فلٹرنگ آن رہنے تک، ہر ایپ میں اسکرین پر لوگوں اور تصاویر کو ڈھانپ دیتی ہے۔ یہ فون پر ہی چلتی ہے؛ کچھ بھی کہیں نہیں بھیجا جاتا۔';

  @override
  String get blurWomenTitle => 'خواتین کو دھندلا کریں';

  @override
  String get blurWomenBody =>
      'پورا جسم۔ جن لوگوں کے بارے میں ایپ واضح طور پر نہیں بتا سکتی کہ وہ مرد ہیں، انہیں بھی دھندلا کیا جاتا ہے۔';

  @override
  String get blurNudityTitle => 'غیر شائستہ تصاویر دھندلا کریں';

  @override
  String get blurNudityBody =>
      'کسی کی بھی برہنگی اور جسم ظاہر کرنے والا لباس: پوری اسکرین ڈھانپ دی جاتی ہے۔';

  @override
  String get blurFailTitle => 'اگر دھندلاہٹ ساتھ نہ دے سکے تو اسکرین ڈھانپ دیں';

  @override
  String get blurFailBody =>
      'آن: جب فون بہت سست ہو یا دھندلاہٹ ناکام ہو جائے تو پوری اسکرین ڈھانپ دی جاتی ہے۔ آف: اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get blurSetupShizuku => 'Shizuku کے ساتھ اجازت دیں';

  @override
  String get blurSetupManual => 'Android ترتیبات میں اجازت دیں';

  @override
  String get blurStatusNeedsSetup =>
      'دھندلاہٹ کو دوسری ایپس کے اوپر ظاہر ہونا ہوتا ہے۔ بہترین: Shizuku کے ساتھ اجازت دیں (اس سے واعية دھندلاہٹ کی ایکسیسبیلٹی سروس آن ہو جاتی ہے، تاکہ ٹچ نیچے والی ایپ تک پہنچتے رہیں)۔ یا Android ترتیبات میں “دیگر ایپس پر دکھائیں” کی اجازت دیں (پھر دھندلے حصے پر ٹچ ضائع ہو جاتے ہیں)۔';

  @override
  String get blurStatusNeedsOverlay =>
      'دھندلاہٹ کو دوسری ایپس کے اوپر ظاہر ہونا ہوتا ہے۔ بہترین: Shizuku شروع کریں (اور اس میں واعية کو اجازت دیں): پھر دھندلاہٹ اپنی الگ تہہ بناتی ہے جس سے ٹچ گزر جاتے ہیں۔ ورنہ Android ترتیبات میں “دیگر ایپس پر دکھائیں” کی اجازت دیں؛ پھر دھندلے حصے پر ٹچ نیچے والی ایپ تک نہیں پہنچتا۔';

  @override
  String get blurFailUnavailable =>
      'فی الحال غیر فعال: پوری اسکرین کا پردہ ہر ٹچ روک دے گا اور آپ پھنس سکتے ہیں۔ واعية کا مددگار یا Shizuku (Android 12 یا نیا) شروع کریں تو یہ آن ہو جائے گا: پھر پردے اس طرح بنتے ہیں کہ ٹچ ان سے گزر جائیں۔ تب تک، جب دھندلاہٹ ساتھ نہ دے سکے تو اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get blurFailNeedsA11y =>
      'فی الحال غیر فعال: پوری اسکرین کا پردہ ہر ٹچ روک دے گا اور آپ پھنس سکتے ہیں۔ Shizuku (Android 12 یا نیا) شروع کریں یا واعية دھندلاہٹ کی ایکسیسبیلٹی سروس آن کریں (اوپر “Shizuku کے ساتھ اجازت دیں”) تو یہ آن ہو جائے گا۔ تب تک، اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get languageTitle => 'زبان';

  @override
  String settingLanguageTitle(String language) {
    return 'زبان: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'دھندلاہٹ کی ترتیبات لاگو کرنے کے لیے فلٹرنگ روک کر دوبارہ شروع کریں۔';

  @override
  String get blurStatusStarting => 'دھندلاہٹ شروع ہو رہی ہے…';

  @override
  String get blurStatusOn => 'دھندلاہٹ آن ہے۔';

  @override
  String get blurStatusOnVisible =>
      'دھندلاہٹ آن ہے، محتاط موڈ میں: یہ فون دھندلاہٹ کو اپنے ہی اسکرین کیپچر میں دکھاتا ہے، اس لیے دھندلا حصہ منظر بدلنے تک دھندلا رہتا ہے۔';

  @override
  String get blurStatusModels =>
      'اس ورژن میں منتخب کردہ آپشن کے لیے دھندلاہٹ کا ماڈل نہیں ہے۔';

  @override
  String get blurStatusFailing => 'دھندلاہٹ اس وقت ساتھ نہیں دے پا رہی۔';

  @override
  String get blurStatusNoOverlay =>
      'دھندلاہٹ دوسری ایپس کے اوپر ظاہر نہیں ہو سکتی: اوپر اس کی اجازت دیں۔';

  @override
  String blurStatusNoCapture(String details) {
    return 'دھندلاہٹ اسکرین نہیں دیکھ سکتی۔ تفصیلات:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku اس کی اجازت نہیں دے سکی:\n$details';
  }

  @override
  String get step2Guide => 'Shizuku کیسے شروع کریں';

  @override
  String get blurFailOldAndroid =>
      'غیر فعال: Android کے اس ورژن پر پوری اسکرین کا پردہ ہر ٹچ روک دے گا اور آپ پھنس سکتے ہیں (Shizuku کے پردوں کو Android 12 یا نیا درکار ہے)۔ جب دھندلاہٹ ساتھ نہ دے سکے تو اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get guideTitle => 'Shizuku شروع کریں، مرحلہ وار';

  @override
  String get guideOpenDev => 'ڈویلپر کے اختیارات';

  @override
  String get guideOpenShizuku => 'Shizuku کھولیں';

  @override
  String get guideClose => 'بند کریں';

  @override
  String get guideBody =>
      'آپ کو Wi-Fi اور Android 11 یا نیا درکار ہے۔ جوڑا صرف ایک بار بنتا ہے؛ فون ری اسٹارٹ ہونے کے بعد آپ صرف مرحلہ 7 دہراتے ہیں۔\n\n1. فون کو Wi-Fi سے منسلک کریں۔\n\n2. ڈویلپر کے اختیارات آن کریں: ترتیبات › فون کے بارے میں › “Software information” (سافٹ ویئر کی معلومات) › “بلڈ نمبر” کو 7 بار تھپتھپائیں۔ (دوسرے فونز پر: ترتیبات › فون کے بارے میں › بلڈ نمبر۔)\n\n3. Shizuku کھولیں۔ اگر وہ اطلاعات دکھانے کی اجازت مانگے تو اجازت دیں: جوڑا بنانے کا کوڈ Shizuku کی ایک اطلاع میں ٹائپ کیا جاتا ہے۔\n\n4. Shizuku میں، “Start via Wireless debugging” (وائرلیس ڈیبگنگ کے ذریعے شروع کریں) کے نیچے “Pairing” (جوڑا بنانا) تھپتھپائیں۔ کھلنے والے صفحے پر “Developer options” (ڈویلپر کے اختیارات) تھپتھپائیں، “وائرلیس ڈیبگنگ” آن کریں اور “اجازت دیں” سے تصدیق کریں۔\n\n5. “وائرلیس ڈیبگنگ” کے الفاظ کو تھپتھپائیں (سوئچ کو نہیں)، پھر “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” کو۔ 6 ہندسوں کا ایک کوڈ ظاہر ہوگا۔\n\n6. وہ اسکرین کھلی رکھیں اور اطلاعات نیچے کھینچیں۔ جب Shizuku کی اطلاع میں “Pairing service found” (جوڑا بنانے کی سروس مل گئی) لکھا ہو تو “Enter pairing code” (جوڑا بنانے کا کوڈ درج کریں) تھپتھپائیں اور کوڈ ٹائپ کریں۔ Shizuku بتائے گی کہ جوڑا کامیابی سے بن گیا۔\n\n7. Shizuku میں واپس جائیں اور “Start via Wireless debugging” کے نیچے “Start” (شروع کریں) تھپتھپائیں۔ انتظار کریں یہاں تک کہ “Shizuku is running” (Shizuku چل رہی ہے) لکھا آئے۔\n\n8. واعية میں واپس آئیں اور “اجازت عطا کریں” تھپتھپائیں، پھر “اجازت دیں”۔\n\nفون ری اسٹارٹ ہونے کے بعد Shizuku رک جاتی ہے: Wi-Fi سے منسلک ہوں، اگر “وائرلیس ڈیبگنگ” آف ہو تو اسے دوبارہ آن کریں، Shizuku کھولیں اور “Start” تھپتھپائیں۔ نیا جوڑا بنانے کی ضرورت نہیں۔';

  @override
  String get wsetupRouteTitle => 'اسی فون پر سیٹ اپ کریں';

  @override
  String get wsetupRouteBody =>
      'چار مختصر مراحل، صرف ایک بار۔ نہ کوئی اضافی ایپ نہ کمپیوٹر۔ ہر مرحلہ مکمل ہونے پر واعية اس پر نشان لگا دیتی ہے۔';

  @override
  String get wizDevTitle => 'ڈویلپر کے اختیارات آن کریں';

  @override
  String get wizDevBody =>
      '“فون کے بارے میں” میں “بلڈ نمبر” کو 7 بار تھپتھپائیں، پھر یہاں واپس آئیں۔ اگر یہ نہ ملے تو ترتیبات میں “بلڈ نمبر” تلاش کریں۔';

  @override
  String get wizDevBodySamsung =>
      '“فون کے بارے میں” › “Software information” (سافٹ ویئر کی معلومات) میں “بلڈ نمبر” کو 7 بار تھپتھپائیں، پھر یہاں واپس آئیں۔';

  @override
  String get wizDevBodyXiaomi =>
      '“فون کے بارے میں” میں “OS version” (OS ورژن) کو 7 بار تھپتھپائیں (پرانے فونز پر “MIUI version” (MIUI ورژن)؛ کچھ پر یہ “Detailed info and specs” (تفصیلی معلومات اور خصوصیات) کے اندر ہوتا ہے)، پھر یہاں واپس آئیں۔';

  @override
  String get wizDevBodyColoros =>
      '“About device” (ڈیوائس کے بارے میں) (یا “فون کے بارے میں”) › “Version” (ورژن) میں “بلڈ نمبر” کو 7 بار تھپتھپائیں، پھر یہاں واپس آئیں۔';

  @override
  String get wizDevBodyVivo =>
      '“فون کے بارے میں” میں “Software version” (سافٹ ویئر ورژن) کو 7 بار تھپتھپائیں (کچھ فونز پر: “Software information” (سافٹ ویئر کی معلومات) › “بلڈ نمبر”)، پھر یہاں واپس آئیں۔';

  @override
  String get wizDevBodyHuawei =>
      '“فون کے بارے میں” میں “بلڈ نمبر” کو 7 بار تھپتھپائیں، پھر یہاں واپس آئیں۔';

  @override
  String get wizDevBodyTranssion =>
      '“My phone” (میرا فون) (یا “فون کے بارے میں”) میں “بلڈ نمبر” کو 7 بار تھپتھپائیں، پھر یہاں واپس آئیں۔';

  @override
  String get setupNoteHuawei =>
      'Huawei: بہت سے Huawei فونز میں “وائرلیس ڈیبگنگ” نہیں ہوتی۔ اگر یہ ڈویلپر کے اختیارات میں نہ ملے تو کمپیوٹر استعمال کریں (نیچے “دوسرے طریقے”)۔';

  @override
  String get wsetupFilterOn =>
      'فلٹرنگ آن ہے: Android کے اس ورژن پر فلٹرنگ چلتے ہوئے کوڈ اطلاع میں ٹائپ نہیں کیا جا سکتا۔ پہلے فلٹرنگ روکیں، یا اسپلٹ اسکرین اور “کوڈ یہاں ٹائپ کریں” استعمال کریں۔';

  @override
  String get wizDevSearch =>
      'فون کی زبان کے مطابق نام مختلف ہو سکتے ہیں: اگر نہ ملے تو ترتیبات کے اوپر والی تلاش استعمال کریں۔';

  @override
  String get wizDevAction => '“فون کے بارے میں” کھولیں';

  @override
  String get wizWifiTitle => 'Wi-Fi سے منسلک ہوں';

  @override
  String get wizWifiBody =>
      'کوئی بھی Wi-Fi نیٹ ورک چلے گا؛ انٹرنیٹ کی ضرورت نہیں۔';

  @override
  String get wizWifiAction => 'Wi-Fi کی ترتیبات کھولیں';

  @override
  String get wizWdTitle => 'وائرلیس ڈیبگنگ آن کریں';

  @override
  String get wizWdBody =>
      'واعية ڈویلپر کے اختیارات کو “وائرلیس ڈیبگنگ” پر کھولتی ہے۔ اسے آن کریں اور “اجازت دیں” تھپتھپائیں۔';

  @override
  String get wizWdAction => 'ڈویلپر کے اختیارات کھولیں';

  @override
  String get wizPairTitle => 'جوڑا بنانے کا کوڈ ٹائپ کریں';

  @override
  String get wizPairBody =>
      '“وائرلیس ڈیبگنگ” کے الفاظ کو تھپتھپائیں، پھر “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” کو۔ 6 ہندسے واعية کی اطلاع میں ٹائپ کریں۔ باقی کام واعية کر لے گی۔';

  @override
  String get wizPairBodyPaired =>
      'واعية کا اس فون کے ساتھ پہلے سے جوڑا بنا ہوا ہے: کسی کوڈ کی ضرورت نہیں۔ بٹن تھپتھپائیں اور واعية خود مکمل کر لے گی۔';

  @override
  String get wizPairAction => 'جاری رکھیں';

  @override
  String get wizAgain => 'سیٹ اپ دوبارہ چلائیں';

  @override
  String get setupShizukuReadyTitle => 'Shizuku کے ساتھ، جو پہلے سے چل رہی ہے';

  @override
  String get setupOtherWaysPlain => 'سیٹ اپ کے دوسرے طریقے';

  @override
  String get wizSkip => 'سیدھے وائرلیس ڈیبگنگ پر جائیں';

  @override
  String get setupOtherWays => 'دوسرے طریقے: Shizuku یا کمپیوٹر';

  @override
  String get wsetupEnterHere => 'کوڈ یہاں ٹائپ کریں';

  @override
  String get wsetupCancel => 'منسوخ کریں';

  @override
  String get wsetupAndroid10 =>
      'Android 10 خود سیٹ اپ نہیں کر سکتا: اسے کمپیوٹر درکار ہے، براہ راست (نیچے) یا ایک بار Shizuku شروع کرنے کے لیے۔';

  @override
  String get wsetupShizukuHeading => 'یا Shizuku ایپ کے ساتھ';

  @override
  String get wsetupShizukuNote =>
      'Shizuku اسکرین کے پردوں سے ٹچ گزرنے بھی دیتی ہے۔';

  @override
  String get wsetupChannel => 'ایک بار کا سیٹ اپ';

  @override
  String get wsetupNotifTitle => 'واعية سیٹ اپ: جوڑا بنانے کے کوڈ کا انتظار ہے';

  @override
  String get wsetupFoundTitle => 'جوڑا بنانے کی اسکرین مل گئی';

  @override
  String get wsetupBusyTitle => 'واعية سیٹ اپ';

  @override
  String get wsetupDoneTitle => 'سیٹ اپ مکمل';

  @override
  String get wsetupDoneBody =>
      'اب واعية اصل آواز خاموش کر سکتی ہے۔ آپ وائرلیس ڈیبگنگ آف کر سکتے ہیں۔';

  @override
  String get wsetupDoneHelperBody =>
      'ہو گیا۔ یہ فون ایپس کو یہ اجازتیں رکھنے نہیں دیتا، اس لیے اس کے بجائے واعية کا مددگار اصل آواز خاموش کرتا ہے۔ فون ری اسٹارٹ ہونے پر اور واعية اپ ڈیٹ ہونے پر مددگار رک جاتا ہے۔ اس کے بعد جب آپ واعية کھولیں گے تو وائرلیس ڈیبگنگ آن ہونے کی صورت میں یہ مددگار کو خود دوبارہ شروع کر دیتی ہے؛ ورنہ اس کے لیے ایک بٹن دکھاتی ہے۔';

  @override
  String get helperMissingTitle => 'واعية کا مددگار رکا ہوا ہے';

  @override
  String get helperMissingBody =>
      'یہ فون واعية کی اجازتیں برقرار نہیں رکھتا، اس لیے واعية اپنا مددگار استعمال کرتی ہے۔ فون ری اسٹارٹ ہونے پر اور واعية اپ ڈیٹ ہونے پر مددگار رک جاتا ہے۔ Wi-Fi سے منسلک ہوں، ڈویلپر کے اختیارات میں “وائرلیس ڈیبگنگ” آن کریں، پھر “واعية کا مددگار شروع کریں” تھپتھپائیں۔';

  @override
  String get helperChannel => 'واعية کا مددگار';

  @override
  String get helperStarting => 'مددگار شروع ہو رہا ہے…';

  @override
  String get helperModeNote =>
      'یہ فون ایپس کو یہ اجازتیں رکھنے نہیں دیتا: واعية کا مددگار یہ کام کرتا ہے۔ فون ری اسٹارٹ ہونے پر اور واعية اپ ڈیٹ ہونے پر یہ رک جاتا ہے۔ اس کے بعد جب آپ واعية کھولیں گے تو وائرلیس ڈیبگنگ آن ہونے کی صورت میں یہ مددگار کو خود دوبارہ شروع کر دیتی ہے؛ ورنہ اس کے لیے ایک بٹن دکھاتی ہے۔';

  @override
  String get helperTipXiaomi =>
      'اختیاری، اجازتیں ہمیشہ کے لیے رکھنے کے لیے (ری اسٹارٹ کے بعد مددگار کی ضرورت نہیں): ڈویلپر کے اختیارات میں “USB debugging (Security settings)” (‏USB ڈیبگنگ - سیکیورٹی کی ترتیبات) آن کریں (یہ Xiaomi اکاؤنٹ میں سائن ان کرنے کو کہتا ہے)، پھر سیٹ اپ دوبارہ کریں۔';

  @override
  String get helperTipColoros =>
      'اختیاری، اجازتیں ہمیشہ کے لیے رکھنے کے لیے (ری اسٹارٹ کے بعد مددگار کی ضرورت نہیں): ڈویلپر کے اختیارات میں “Disable permission monitoring” (اجازت کی نگرانی غیر فعال کریں) آن کریں (نئے ورژنز میں “Disable system optimization” (سسٹم کی اصلاح غیر فعال کریں)؛ یہ شاید صرف فون کی زبان انگریزی ہونے پر دکھائی دے)، پھر سیٹ اپ دوبارہ کریں۔';

  @override
  String get stateOnHelperMissing =>
      'اصل آواز خاموش نہیں ہے، اس لیے آپ کو فلٹر شدہ آواز کے ساتھ موسیقی بھی سنائی دے رہی ہے: واعية کا مددگار رکا ہوا ہے۔ Wi-Fi سے منسلک ہوں، وائرلیس ڈیبگنگ آن کریں، پھر “واعية کا مددگار شروع کریں” تھپتھپائیں۔';

  @override
  String get setupRefusedTryWireless =>
      'یا اس صفحے پر “اسی فون پر سیٹ اپ کریں” استعمال کریں: پھر واعية کا مددگار اس سوئچ کے بغیر کام کرتا ہے۔';

  @override
  String get helperStartAnywayTitle => 'واعية کا مددگار رکا ہوا ہے';

  @override
  String get helperStartAnywayBody =>
      'اس کے بغیر آپ کو فلٹر شدہ آواز کے ساتھ موسیقی بھی سنائی دے گی۔ پہلے مددگار شروع کریں (وائرلیس ڈیبگنگ آن ہونی چاہیے)، یا پھر بھی فلٹرنگ شروع کریں۔';

  @override
  String get wsetupFailedTitle => 'سیٹ اپ مکمل نہیں ہوا';

  @override
  String get wsetupPairing => 'جوڑا بن رہا ہے…';

  @override
  String get wsetupConnecting => 'منسلک ہو رہا ہے اور اجازتیں دی جا رہی ہیں…';

  @override
  String get wsetupNeedWifi =>
      'پہلے کسی Wi-Fi نیٹ ورک سے منسلک ہوں (انٹرنیٹ کی ضرورت نہیں): وائرلیس ڈیبگنگ صرف Wi-Fi پر کام کرتی ہے۔';

  @override
  String get wsetupNeedWirelessDebugging =>
      'ڈویلپر کے اختیارات میں “وائرلیس ڈیبگنگ” آن کریں، پھر اس کے نام کو اور “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” کو تھپتھپائیں۔';

  @override
  String get wsetupOpenDialog =>
      'وائرلیس ڈیبگنگ میں “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” تھپتھپائیں۔ کوڈ اسکرین پر رہنے دیں اور یہاں “کوڈ درج کریں” تھپتھپائیں۔';

  @override
  String get wsetupEnterCodeBody =>
      '“کوڈ درج کریں” تھپتھپائیں اور ترتیبات میں دکھایا گیا 6 ہندسوں کا کوڈ ٹائپ کریں۔';

  @override
  String get wsetupCodeWaiting =>
      'کوڈ مل گیا۔ “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” والی اسکرین کا انتظار ہے: اسے کھلا رکھیں۔';

  @override
  String get wsetupWrongCode =>
      'وہ کوڈ قبول نہیں ہوا۔ اسکرین پر 6 ہندسے چیک کریں اور دوبارہ درج کریں۔ اگر جوڑا بنانے کی اسکرین بند ہو گئی ہو تو اسے دوبارہ کھولیں: کوڈ بدل جاتا ہے۔';

  @override
  String get wsetupPairingFailed =>
      'جوڑا نہیں بن سکا۔ جوڑا بنانے کی اسکرین بند کریں، “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” دوبارہ کھولیں اور نیا کوڈ درج کریں۔';

  @override
  String get wsetupWaitingConnect =>
      'جوڑا بن گیا۔ “وائرلیس ڈیبگنگ” آن رکھیں: واعية منسلک ہو رہی ہے۔';

  @override
  String get wsetupNotPaired =>
      'یہ فون اب واعية کو نہیں پہچانتا (جوڑا ہٹا دیا گیا یا اس کی مدت ختم ہو گئی)۔ “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” کھولیں اور کوڈ درج کریں۔';

  @override
  String get wsetupConnectFailed =>
      'وائرلیس ڈیبگنگ سے منسلک نہیں ہو سکا۔ اسے آف کر کے دوبارہ آن کریں: واعية خود دوبارہ کوشش کرے گی۔';

  @override
  String get wsetupGrantFailed =>
      'منسلک ہو گیا، لیکن اجازتیں ابھی بھی نہیں ملیں۔ نیچے Shizuku یا کمپیوٹر استعمال کریں۔';

  @override
  String get wsetupTimeout =>
      '10 منٹ تک مکمل نہ ہونے پر رک گیا۔ آپ دوبارہ کوشش کر سکتے ہیں۔';

  @override
  String get wsetupCodeUnreadable => 'جوڑا بنانے کے کوڈ کے 6 ہندسے ٹائپ کریں۔';

  @override
  String get wsetupCodeHint => '6 ہندسوں کا کوڈ';

  @override
  String get wsetupEnterCode => 'کوڈ درج کریں';

  @override
  String wsetupDetail(String details) {
    return 'تفصیلات: $details';
  }

  @override
  String get wsetupErrTimeout => 'وقت پر جواب نہیں ملا';

  @override
  String get wsetupErrRefused => 'کنکشن مسترد ہو گیا';

  @override
  String get wsetupDevOff =>
      'ڈویلپر کے اختیارات آف ہیں۔ “فون کے بارے میں” میں “بلڈ نمبر” کو 7 بار تھپتھپائیں، پھر واپس آئیں۔';

  @override
  String get wsetupOpenAbout => 'فون کے بارے میں';

  @override
  String get wsetupNotifOff =>
      'واعية کے لیے اطلاعات آف ہیں، اس لیے کوڈ اطلاع میں ٹائپ نہیں کیا جا سکتا۔ اسپلٹ اسکرین استعمال کریں (ایک حصے میں ترتیبات، دوسرے میں واعية) اور “کوڈ یہاں ٹائپ کریں” تھپتھپائیں۔';

  @override
  String get wsetupCodeDialogTitle => 'جوڑا بنانے کا کوڈ';

  @override
  String get wsetupCodeDialogBody =>
      'صرف اسپلٹ اسکرین کے ساتھ (ایک حصے میں ترتیبات، دوسرے میں واعية): ترتیبات سے باہر جانے پر جوڑا بنانے کی اسکرین بند ہو جاتی ہے اور اس کا کوڈ کام کرنا چھوڑ دیتا ہے۔ “جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں” کے نیچے دکھایا گیا 6 ہندسوں کا کوڈ ٹائپ کریں۔';

  @override
  String get wsetupCodeOk => 'جوڑا بنائیں';

  @override
  String get blurStrictTitle => 'کون بغیر ڈھکا رہے';

  @override
  String blurStrictValue(String level) {
    return 'کون بغیر ڈھکا رہے: $level';
  }

  @override
  String get blurStrict0 =>
      'سخت: صرف وہ لوگ جن کے مرد ہونے کا ایپ کو تقریباً یقین ہو';

  @override
  String get blurStrict1 => 'متوازن: تقریباً دگنے مرد بغیر ڈھکے رہتے ہیں';

  @override
  String get blurStrict2 => 'نرم: متوازن سے کچھ زیادہ مرد';

  @override
  String get blurStrict0Short => 'سخت';

  @override
  String get blurStrict1Short => 'متوازن';

  @override
  String get blurStrict2Short => 'نرم';

  @override
  String get blurStrictHelp =>
      'جس کے مرد ہونے کا ایپ کو یقین نہ ہو، اسے ڈھانپ دیا جاتا ہے۔ سخت میں ہر 100 میں سے تقریباً 7 مرد بغیر ڈھکے رہتے ہیں؛ متوازن میں تقریباً 14، نرم میں تقریباً 16۔ ہر کم سخت درجہ ہر 100 میں سے تقریباً 1 مزید عورت کو بھی بغیر ڈھکا چھوڑتا ہے۔';

  @override
  String get stateOnNotMuted =>
      'اصل آواز ابھی خاموش نہیں ہوئی، اس لیے آپ کو فلٹر شدہ آواز کے ساتھ موسیقی بھی سنائی دے رہی ہے۔ نیچے ایک بار کا سیٹ اپ مکمل کریں۔';

  @override
  String get stateOnMuteFailing =>
      'واعية اس وقت چلنے والی ایپ کی اصل آواز خاموش نہیں کر پا رہی، اس لیے موسیقی اب بھی سنائی دے سکتی ہے۔ فلٹرنگ روک کر دوبارہ شروع کریں۔ اگر مسئلہ برقرار رہے تو تشخیصی رپورٹ بھیجیں (اس اسکرین کے نیچے)۔';

  @override
  String get stateTooSlow =>
      'یہ فون براہ راست آواز فلٹر کرنے کے لیے بہت سست ہے، اس لیے آواز ٹوٹتی ہے۔ نیچے “لنک کھولیں” پھر بھی کام کرتا ہے: یہ ویڈیو کو چلانے سے پہلے فلٹر کر دیتا ہے۔';

  @override
  String get stateMonoNote => 'آواز مونو میں ہے تاکہ یہ فون ساتھ چل سکے۔';

  @override
  String stateBlockedSilenced(String apps) {
    return 'خاموش کر دی گئی، کیونکہ یہ فلٹرنگ کی اجازت نہیں دیتی: $apps۔';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'بغیر فلٹر چل رہی ہے، کیونکہ یہ فلٹرنگ کی اجازت نہیں دیتی: $apps۔';
  }

  @override
  String get stateCaptureFailed =>
      'Android نے واعية کو دوسری ایپس کی آواز نہیں دی۔ دوبارہ شروع کرنے کے لیے بٹن تھپتھپائیں۔';

  @override
  String get stateCaptureCancelled =>
      'Android کے اسکرین کے اشتراک والے سوال پر شروع کرنا منسوخ ہو گیا۔ آواز وصول کرنے کے لیے واعية کو وہاں “شروع کریں” درکار ہے۔ نہ کچھ ریکارڈ ہوتا ہے نہ بھیجا جاتا ہے۔';

  @override
  String get startNoSetupTitle => 'موسیقی پھر بھی سنائی دے گی';

  @override
  String get startNoSetupBody =>
      'ایک بار کا سیٹ اپ ابھی نہیں ہوا۔ اس کے بغیر واعية اصل آواز خاموش نہیں کر سکتی: آپ کو موسیقی اور فلٹر شدہ آواز ایک ساتھ سنائی دے گی۔\n\n“لنک کھولیں” کسی سیٹ اپ کے بغیر کام کرتا ہے۔';

  @override
  String get startNoSetupSetup => 'سیٹ اپ کریں';

  @override
  String get startNoSetupAnyway => 'پھر بھی شروع کریں';

  @override
  String get diagButton => 'مسئلہ؟ تشخیصی رپورٹ';

  @override
  String get diagTitle => 'تشخیصی رپورٹ';

  @override
  String get diagNote =>
      'اس فون پر واعية کیا دیکھتی ہے۔ اسے کاپی کریں یا جو آپ کی مدد کر رہا ہو اس کے ساتھ شیئر کریں۔ ایپ خود کچھ نہیں بھیجتی۔';

  @override
  String get notifStoppedTitle => 'واعية رک گئی';

  @override
  String get notifStoppedText =>
      'آواز اب فلٹر نہیں ہو رہی۔ دوبارہ شروع کرنے کے لیے تھپتھپائیں۔';

  @override
  String get wsetupGuide => 'تصاویر کے ساتھ مراحل';

  @override
  String get navFilter => 'فلٹر';

  @override
  String get navScreen => 'اسکرین';

  @override
  String get navLinks => 'لنکس';

  @override
  String get navSetup => 'سیٹ اپ';

  @override
  String get navSettings => 'ترتیبات';

  @override
  String get setupDoneTitle => 'سیٹ اپ مکمل';

  @override
  String get setupDoneBody =>
      'واعية دوسری ایپس کی اصل آواز خاموش کر سکتی ہے۔ اسے دوبارہ صرف تب کریں جب کچھ بدل جائے (سیٹ اپ ختم ہو گیا ہو، یا واعية کہے کہ یہ موجود نہیں)۔';

  @override
  String get setupRedo => 'سیٹ اپ دوبارہ دکھائیں';

  @override
  String get setupGo => 'سیٹ اپ پر جائیں';

  @override
  String get helperTitle => 'پردوں کے پار ٹچ';

  @override
  String get helperBodyOff =>
      'مدد کے بغیر، پردہ اپنے نیچے کے ٹچ روک دیتا ہے۔ واعية کا مددگار پردے اس طرح بناتا ہے کہ ٹچ ان سے گزر جائیں۔ وائرلیس ڈیبگنگ آن کریں (Wi-Fi درکار ہے) اور بٹن تھپتھپائیں؛ پہلی بار، سیٹ اپ کی طرح ایک بار جوڑا بنائیں۔ فون ری اسٹارٹ ہونے کے بعد اسے دوبارہ تھپتھپائیں۔';

  @override
  String get helperStart => 'واعية کا مددگار شروع کریں';

  @override
  String get helperOn =>
      'واعية کا مددگار پردے بناتا ہے: ٹچ ان سے گزر جاتے ہیں۔ فون ری اسٹارٹ ہونے پر یا ‏USB ڈیبگنگ آف ہونے پر یہ رک جاتا ہے؛ تب بٹن دوبارہ تھپتھپائیں۔';

  @override
  String get helperShizukuOn => 'Shizuku پردے بناتی ہے: ٹچ ان سے گزر جاتے ہیں۔';

  @override
  String get helperOrShizuku => 'یا Shizuku کے ساتھ:';

  @override
  String get filterOptionsTitle => 'فلٹر کے اختیارات';

  @override
  String get settingsGeneralTitle => 'عام';

  @override
  String get desktopPreview =>
      'پیش نظارہ: اس کمپیوٹر پر فلٹر انجن ابھی منسلک نہیں ہے۔ بٹن صرف یہ دکھاتا ہے کہ ایپ کیسے کام کرے گی۔';

  @override
  String actionFailed(String details) {
    return 'یہ کام نہیں ہوا: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'تمام ایپس سے آلات ہٹائے جا رہے ہیں۔';

  @override
  String get engineErrorNoPactl =>
      'آواز کے ٹولز (pactl) نہیں ملے۔ واعية کو PulseAudio، یا pipewire-pulse کے ساتھ PipeWire درکار ہے۔';

  @override
  String get engineErrorNoSoundServer =>
      'ساؤنڈ سرور (PulseAudio یا PipeWire) نہیں چل رہا۔';

  @override
  String get engineErrorNoSystemd =>
      'اس سسٹم میں systemd یوزر سیشن نہیں ہے، جو فلٹر کو پس منظر میں چلاتا ہے۔';

  @override
  String get engineErrorNoOutput => 'کوئی اسپیکر یا ہیڈفون نہیں ملا۔';

  @override
  String engineErrorInstallFailed(String details) {
    return 'فلٹر انسٹال نہیں ہو سکا۔ تفصیلات:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'فلٹر شروع نہیں ہوا۔ تفصیلات:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'فلٹر ایک خرابی کے ساتھ رک گیا۔ تفصیلات:\n$details';
  }

  @override
  String get autostartTitle => 'لاگ ان پر شروع کریں';

  @override
  String get autostartBody => 'لاگ ان کرتے ہی آواز فلٹر کریں۔';

  @override
  String get blurBodyDesktop =>
      'واعية کھلی رہنے تک، ہر ونڈو کے اوپر، اسکرین پر لوگوں اور تصاویر کو ڈھانپ دیتی ہے (آواز کا فلٹر آن ہو یا آف، یہ کام کرتی ہے)۔ یہ اسی کمپیوٹر پر چلتی ہے؛ کچھ بھی کہیں نہیں بھیجا جاتا۔ واعية کی ونڈو بند کرنے سے دھندلاہٹ رک جاتی ہے۔';

  @override
  String get blurFailBodyDesktop =>
      'آن: جب کمپیوٹر بہت سست ہو یا دھندلاہٹ ناکام ہو جائے تو پوری اسکرین ڈھانپ دی جاتی ہے؛ کلکس پھر بھی نیچے کی ونڈوز تک پہنچتے ہیں۔ آف: اسکرین اوپر ایک سرخ پٹی کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get blurStatusOnVisibleDesktop =>
      'دھندلاہٹ آن ہے۔ یہ ڈیسک ٹاپ دھندلاہٹ کو اپنے ہی اسکرین کیپچر میں دکھاتا ہے، اس لیے دھندلا حصہ منظر بدلنے تک دھندلا رہتا ہے۔';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'اس ڈیسک ٹاپ پر دھندلاہٹ دوسری ونڈوز کے اوپر ظاہر نہیں ہو سکتی۔ تفصیلات:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'اسکرین کے اشتراک والی ونڈو میں اپنی اسکرین منتخب کریں اور اجازت دیں۔ واعية صرف ایک بار پوچھتی ہے؛ تصویر اسی کمپیوٹر پر رہتی ہے۔';

  @override
  String blurStatusExited(String details) {
    return 'دھندلاہٹ غیر متوقع طور پر رک گئی۔ دوبارہ کوشش کے لیے دھندلاہٹ کا کوئی آپشن آف کر کے دوبارہ آن کریں۔ تفصیلات:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'خواتین کے گانے کا ڈیٹیکٹر لوڈ نہیں ہوا، اس لیے جب تک وہ آپشن آن ہے آوازیں خاموش رہتی ہیں۔';

  @override
  String get blurStatusUncovered =>
      'ایک مانیٹر دھندلاہٹ سے ڈھکا نہیں ہے: یا تو اس کا اشتراک نہیں کیا گیا، یا وہ بعد میں لگایا گیا۔ دھندلاہٹ کا کوئی آپشن آف کر کے دوبارہ آن کریں، اور اسکرین کے اشتراک والی ونڈو میں ہر اسکرین منتخب کریں۔';

  @override
  String get blurStatusModelsMissingDesktop =>
      'اس انسٹالیشن میں دھندلاہٹ کے ماڈلز موجود نہیں، اس لیے یہ کچھ نہیں ڈھانپ سکتی؛ اسکرین کے اوپر ایک سرخ پٹی رہتی ہے۔ واعية دوبارہ انسٹال کریں۔';

  @override
  String get diagNoteDesktop =>
      'اس کمپیوٹر پر واعية کیا دیکھتی ہے۔ اسے کاپی کریں اور جو آپ کی مدد کر رہا ہو اسے دے دیں۔ ایپ خود کچھ نہیں بھیجتی۔';

  @override
  String get singingKeepTitle => 'گانے کی آوازیں رکھیں (آزمائشی)';

  @override
  String get singingKeepBody =>
      'ساز ہٹا دیے جاتے ہیں مگر گانے کی آوازیں رہتی ہیں، اس لیے جس بیان کے پیچھے نشید ہو اس میں نشید کی آواز بھی رہتی ہے؛ یہ قابلِ قبول ہے یا نہیں، یہ آپ کا فیصلہ ہے۔';

  @override
  String get singingKeepNoModel =>
      'اس ورژن میں گانے کا ماڈل نہیں ہے، اس لیے جب تک یہ آن ہے آواز خاموش رہے گی۔ اسے بند کریں۔';
}
