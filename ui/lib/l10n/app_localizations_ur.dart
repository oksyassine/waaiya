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
      'آپ کی ایپس کی آواز سے موسیقی کے آلات ہٹاتی ہے اور بات چیت اور تلاوت باقی رکھتی ہے۔';

  @override
  String get onboardTitle => 'خوش آمدید';

  @override
  String get onboardBody =>
      'واعية اس فون کی ایپس کی آواز سے موسیقی کے آلات ہٹاتی ہے۔ بات چیت اور قرآن کی تلاوت باقی رہتی ہے۔ گانے کی آوازیں بھی ہٹا دی جاتی ہیں۔';

  @override
  String get onboardQuestion => 'میں ہوں';

  @override
  String get genderMan => 'مرد';

  @override
  String get genderWoman => 'عورت';

  @override
  String get onboardWhy =>
      'اس سے صرف یہ طے ہوتا ہے کہ آپ کو کون سی اختیاری ترتیبات نظر آئیں۔ مثال کے طور پر، “خواتین کا گانا خاموش کریں” صرف مردوں کو دکھایا جاتا ہے۔ آپ اسے بعد میں بدل سکتے ہیں۔';

  @override
  String get stateOnTitle => 'فلٹرنگ آن ہے';

  @override
  String get stateOffTitle => 'فلٹرنگ آف ہے';

  @override
  String get stateStarting => 'شروع ہو رہا ہے…';

  @override
  String stateOnDetail(int delayMs) {
    return 'آپ کی ایپس کی آواز فلٹر ہو رہی ہے۔ یہ تقریباً $delayMs ملی سیکنڈ دیر سے آتی ہے (1000 ملی سیکنڈ ایک سیکنڈ ہے)۔';
  }

  @override
  String get stateOffDetail => 'شروع کرنے کے لیے بٹن دبائیں۔';

  @override
  String get stateModelFailed =>
      'فلٹر لوڈ نہیں ہو سکا، اس لیے آواز بغیر فلٹر کے چلنے کے بجائے بند کر دی گئی ہے۔';

  @override
  String get stateCaptureDenied =>
      'دوسری ایپس کی آواز وصول کرنے کے لیے مائیکروفون کی اجازت درکار ہے۔';

  @override
  String get stateStoppedBySystem =>
      'Android نے فلٹرنگ روک دی۔ دوبارہ شروع کرنے کے لیے بٹن دبائیں۔';

  @override
  String get stateSilencedTitle => 'فلٹرنگ رک گئی';

  @override
  String get stateSilenced =>
      'فلٹرنگ رک گئی: دوسری ایپس خاموش ہیں۔ دوبارہ شروع کرنے کے لیے بٹن دبائیں، یا انہیں بغیر فلٹر کے سننے کے لیے “روکیں”۔';

  @override
  String get releaseSilence => 'روکیں: ایپس کو بغیر فلٹر سنیں';

  @override
  String get powerStartCd => 'فلٹرنگ شروع کریں';

  @override
  String get powerStopCd => 'فلٹرنگ روکیں';

  @override
  String get captureHint =>
      'Android آپ کی اسکرین کا اشتراک کرنے کو کہے گا۔ نہ کچھ ریکارڈ ہوتا ہے نہ کہیں بھیجا جاتا ہے۔';

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
  String get computerWeb =>
      '‏سب سے آسان: کمپیوٹر پر Chrome یا Edge میں waaiya.mssid.org/usb کھولیں، USB ڈیبگنگ آن کریں اور فون کو کیبل سے جوڑیں۔ کچھ انسٹال نہیں کرنا پڑتا، اور یہ Android 10 پر بھی کام کرتا ہے۔ یا، اگر adb انسٹال ہے:';

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
  String get settingSingingBody =>
      'مثال کے طور پر، کسی عورت کا گایا ہوا گانا خاموش ہو جاتا ہے، لیکن بیان دیتی ہوئی عورت کی آواز سنائی دیتی رہتی ہے۔';

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
  String get playerTitle => 'آواز اور تصویر ہم آہنگ ویڈیوز';

  @override
  String get playerBody =>
      'کوئی ویڈیو واعية کے ساتھ شیئر کریں (یا “اس کے ساتھ کھولیں” استعمال کریں) تاکہ اسے فلٹر شدہ، آواز اور تصویر کی ہم آہنگی کے ساتھ اور براہ راست فلٹر کی تاخیر کے بغیر دیکھیں۔';

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
      'فلٹرنگ آن رہنے تک اسکرین پر لوگوں اور تصاویر کو ڈھانپ دیتی ہے۔ یہ فون پر ہی چلتی ہے؛ کچھ بھی کہیں نہیں بھیجا جاتا۔';

  @override
  String get blurOnTitle => 'دھندلاہٹ آن ہے';

  @override
  String get blurOffTitle => 'دھندلاہٹ بند ہے';

  @override
  String get blurStartCd => 'دھندلاہٹ شروع کریں';

  @override
  String get blurStopCd => 'دھندلاہٹ بند کریں';

  @override
  String get blurOffDetail =>
      'شروع کرنے کے لیے بٹن دبائیں۔ فلٹرنگ بھی ساتھ شروع ہو جاتی ہے۔';

  @override
  String get blurWhatTitle => 'کیا دھندلا کیا جائے';

  @override
  String get blurWomenTitle => 'خواتین کی تصاویر دھندلا کریں';

  @override
  String get blurWomenBody =>
      'پورا جسم ڈھانپا جاتا ہے۔ اگر ایپ کو یقین نہ ہو کہ کوئی شخص مرد ہے، تو اسے بھی ڈھانپ دیا جاتا ہے۔';

  @override
  String get blurNudityTitle => 'غیر شائستہ تصاویر دھندلا کریں';

  @override
  String get blurNudityBody =>
      'برہنگی یا جسم دکھانے والا لباس، کسی پر بھی: پوری اسکرین ڈھانپ دی جاتی ہے۔';

  @override
  String get blurFailTitle => 'اگر دھندلاہٹ ساتھ نہ دے سکے تو اسکرین ڈھانپ دیں';

  @override
  String get blurFailBody =>
      'آن: جب فون بہت سست ہو یا دھندلاہٹ ناکام ہو جائے تو پوری اسکرین ڈھانپ دی جاتی ہے۔ آف: اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get blurSetupManual => 'Android ترتیبات میں اجازت دیں';

  @override
  String get blurStatusNeedsSetup =>
      'دھندلا کرنے کے لیے واعية کو دوسری ایپس کے اوپر ظاہر ہونا ہوتا ہے۔ بہترین: “سیٹ اپ پر جائیں”، تاکہ آپ کے ٹچ دھندلاہٹ کے نیچے والی ایپ تک پہنچتے رہیں۔ یا “Android ترتیبات میں اجازت دیں”، لیکن پھر دھندلے حصے پر ٹچ کرنے سے کچھ نہیں ہوتا۔';

  @override
  String get blurStatusNeedsOverlay =>
      'دھندلا کرنے کے لیے واعية کو دوسری ایپس کے اوپر ظاہر ہونا ہوتا ہے۔ بہترین: ایک بار کا سیٹ اپ مکمل کریں، تاکہ آپ کے ٹچ دھندلاہٹ کے نیچے والی ایپ تک پہنچتے رہیں۔ یا Android ترتیبات میں “دیگر ایپس پر دکھائیں” کی اجازت دیں، لیکن پھر دھندلے حصے پر ٹچ کرنے سے کچھ نہیں ہوتا۔';

  @override
  String get blurFailUnavailable =>
      'فی الحال غیر فعال: پوری اسکرین کا پردہ ہر ٹچ روک دے گا اور آپ پھنس سکتے ہیں۔ واعية کا مددگار (Android 12 یا نیا) شروع کریں تو یہ آن ہو جائے گا: پھر پردے اس طرح بنتے ہیں کہ ٹچ ان سے گزر جائیں۔ تب تک، جب دھندلاہٹ ساتھ نہ دے سکے تو اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

  @override
  String get blurFailNeedsA11y =>
      'فی الحال غیر فعال: پوری اسکرین کا پردہ ہر ٹچ روک دے گا اور آپ پھنس سکتے ہیں۔ واعية کا مددگار (Android 12 یا نیا) شروع کریں یا Android ترتیبات میں واعية دھندلاہٹ کی ایکسیسبیلٹی سروس آن کریں تو یہ آن ہو جائے گا۔ تب تک، اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

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
  String get step2Guide => 'Shizuku کیسے شروع کریں';

  @override
  String get blurFailOldAndroid =>
      'غیر فعال: Android کے اس ورژن پر پوری اسکرین کا پردہ ہر ٹچ روک دے گا اور آپ پھنس سکتے ہیں (جن پردوں سے ٹچ گزر جائیں انہیں Android 12 یا نیا درکار ہے)۔ جب دھندلاہٹ ساتھ نہ دے سکے تو اسکرین ایک انتباہ کے ساتھ نظر آتی رہتی ہے۔';

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
  String get blurStrictTitle => 'مرد کو دکھانے سے پہلے کتنا یقین';

  @override
  String blurStrictValue(String level) {
    return 'مرد کو دکھانے سے پہلے کتنا یقین: $level';
  }

  @override
  String get blurStrict0 =>
      'سخت: صرف وہ لوگ جن کے مرد ہونے کا ایپ کو تقریباً یقین ہو';

  @override
  String get blurStrict1 => 'متوازن: تقریباً دگنے مرد دکھائے جاتے ہیں';

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
      'کسی شخص کو صرف تب دکھایا جاتا ہے جب ایپ کو یقین ہو کہ وہ مرد ہے؛ باقی سب کو دھندلا کر دیا جاتا ہے۔ سخت میں ہر 100 میں سے تقریباً 7 مرد دکھائے جاتے ہیں، متوازن میں تقریباً 14، نرم میں تقریباً 16۔ کچھ عورتیں پھر بھی چھوٹ جاتی ہیں؛ ہر کم سخت درجہ ہر 100 میں سے تقریباً 1 مزید چھوڑ دیتا ہے۔';

  @override
  String get stateOnNotMuted =>
      'اصل آواز ابھی خاموش نہیں ہوئی، اس لیے آپ کو فلٹر شدہ آواز کے ساتھ موسیقی بھی سنائی دے رہی ہے۔ “سیٹ اپ” صفحے پر ایک بار کا سیٹ اپ مکمل کریں۔';

  @override
  String get stateOnMuteFailing =>
      'واعية اس وقت چلنے والی ایپ کی اصل آواز خاموش نہیں کر پا رہی، اس لیے موسیقی اب بھی سنائی دے سکتی ہے۔ فلٹرنگ روک کر دوبارہ شروع کریں۔ اگر مسئلہ برقرار رہے تو تشخیصی رپورٹ بھیجیں (ترتیبات)۔';

  @override
  String get stateTooSlow =>
      'یہ فون براہ راست آواز فلٹر کرنے کے لیے بہت سست ہے، اس لیے آواز ٹوٹتی ہے۔ “لنکس” صفحے پر “لنک کھولیں” پھر بھی کام کرتا ہے: یہ ویڈیو کو چلانے سے پہلے فلٹر کر دیتا ہے۔';

  @override
  String get stateMonoNote => 'آواز مونو میں ہے تاکہ یہ فون ساتھ چل سکے۔';

  @override
  String stateBlockedSilenced(String apps) {
    return 'خاموش کر دی گئی کیونکہ ان کی طرف سے فلٹرنگ کی اجازت نہیں: $apps۔';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'بغیر فلٹر چل رہی ہے کیونکہ ان کی طرف سے فلٹرنگ کی اجازت نہیں: $apps۔';
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
      'اس فون پر واعية کیا دیکھتی ہے۔ اسے کاپی کریں یا جو آپ کی مدد کر رہا ہو اس کے ساتھ شیئر کریں۔ واعية اسے خود نہیں بھیجتی: آپ چنتے ہیں کہ یہ کسے ملے۔';

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
  String get helperTitle => 'دھندلے حصوں کے پار ٹچ';

  @override
  String get helperBodyOff =>
      'مدد کے بغیر، پردہ اپنے نیچے کے ٹچ روک دیتا ہے۔ واعية کا مددگار پردے اس طرح بناتا ہے کہ ٹچ ان سے گزر جائیں۔ وائرلیس ڈیبگنگ آن کریں (Wi-Fi درکار ہے) اور بٹن تھپتھپائیں؛ پہلی بار، سیٹ اپ کی طرح ایک بار جوڑا بنائیں۔ فون ری اسٹارٹ ہونے کے بعد اسے دوبارہ تھپتھپائیں۔';

  @override
  String get helperStart => 'واعية کا مددگار شروع کریں';

  @override
  String get helperOn =>
      'واعية کا مددگار دھندلاہٹ بناتا ہے: ٹچ اس سے گزر جاتے ہیں۔ فون ری اسٹارٹ ہونے پر یا “‏USB ڈیبگنگ” (ڈویلپر کے اختیارات میں ایک الگ سوئچ) آف ہونے پر یہ رک جاتا ہے؛ تب بٹن دوبارہ تھپتھپائیں۔';

  @override
  String get helperShizukuOn => 'Shizuku پردے بناتی ہے: ٹچ ان سے گزر جاتے ہیں۔';

  @override
  String get helperOrShizuku => 'یا Shizuku کے ساتھ:';

  @override
  String get filterOptionsTitle => 'فلٹر کے اختیارات';

  @override
  String get settingsGeneralTitle => 'عام';

  @override
  String get simpleTitle => 'آسان موڈ (آزمائشی): ڈویلپر کے اختیارات کے بغیر';

  @override
  String get simpleBody =>
      'ان فونز کے لیے جن پر نیچے والا سیٹ اپ بہت مشکل ہو۔ واعية فلٹر کرتے وقت فون کی میڈیا آواز بند کر دیتی ہے اور فلٹر شدہ آواز ایک دوسرے ساؤنڈ چینل پر چلاتی ہے۔ آپ کے والیوم بٹن واعية کا والیوم طے کرتے ہیں۔ اینڈرائیڈ ہر بار شروع کرنے پر اسکرین شیئر کرنے کا پوچھتا ہے۔ فلٹرنگ رکنے پر میڈیا آواز واپس آ جاتی ہے۔';

  @override
  String get simpleSwitch => 'آسان موڈ استعمال کریں';

  @override
  String simpleChannelTitle(String channel) {
    return 'ساؤنڈ چینل: $channel';
  }

  @override
  String get simpleChannelAlarm => 'الارم';

  @override
  String get simpleChannelNotification => 'اطلاع';

  @override
  String get simpleChannelHelp =>
      'اگر کچھ سنائی نہ دے، یا ایئرفون لگے ہونے کے باوجود آواز فون کے اسپیکر سے آئے، تو دوسرا چینل آزمائیں۔ فون وائبریٹ پر ہو یا «ڈسٹرب نہ کریں» آن ہو تو اطلاع والا چینل خاموش رہتا ہے۔';

  @override
  String get simpleTestNote =>
      'یہ ایک آزمائش ہے۔ اسے آزمانے کے بعد (اسپیکر، ایئرفون، Bluetooth) براہ کرم ترتیبات سے تشخیصی رپورٹ بھیجیں۔';

  @override
  String get simpleOnDetail =>
      'آسان موڈ (آزمائشی): واعية کے فلٹر کرتے وقت میڈیا آواز بند رہتی ہے۔';

  @override
  String get worshipPrayerFajr => 'فجر';

  @override
  String get worshipPrayerSunrise => 'طلوع آفتاب';

  @override
  String get worshipPrayerDhuhr => 'ظہر';

  @override
  String get worshipPrayerAsr => 'عصر';

  @override
  String get worshipPrayerMaghrib => 'مغرب';

  @override
  String get worshipPrayerIsha => 'عشاء';

  @override
  String get worshipEndSilent => 'ابھی خاموشی ختم کریں';

  @override
  String get worshipUnmute => 'ابھی آواز کھولیں';

  @override
  String get worshipSmsDefault =>
      'نماز کا وقت ہے، ابھی جواب نہیں دے سکتا۔ میں آپ کو بعد میں کال کروں گا۔';

  @override
  String get updateTitle => 'ایپ کی اپ ڈیٹس';

  @override
  String get updateAuto => 'دن میں ایک بار نیا ورژن تلاش کریں';

  @override
  String get updateAutoBody =>
      'واعیہ waaiya.mssid.org سے پوچھتی ہے کہ کیا کوئی نیا ورژن ہے، اور کچھ اور نہیں بھیجتی۔ جب تک آپ ابھی اپ ڈیٹ کریں نہ دبائیں، کچھ ڈاؤن لوڈ نہیں ہوتا۔';

  @override
  String get updateCheck => 'ابھی تلاش کریں';

  @override
  String get updateChecking => 'تلاش ہو رہی ہے…';

  @override
  String updateNone(String version) {
    return 'آپ کے پاس تازہ ترین ورژن ہے ($version)۔';
  }

  @override
  String updateAvailable(String latest, String current) {
    return 'واعیہ $latest دستیاب ہے۔ آپ کے پاس $current ہے۔';
  }

  @override
  String updateSizePatch(String size, String full) {
    return 'ڈاؤن لوڈ: $size، صرف تبدیلیاں (پوری ایپ $full ہے)۔';
  }

  @override
  String updateSizeFull(String size) {
    return 'ڈاؤن لوڈ: $size۔';
  }

  @override
  String get updateNow => 'ابھی اپ ڈیٹ کریں';

  @override
  String updateDownloading(String progress) {
    return 'ڈاؤن لوڈ ہو رہا ہے: $progress';
  }

  @override
  String get updatePreparing => 'اپ ڈیٹ تیار ہو رہی ہے…';

  @override
  String get updateInstalling =>
      'اینڈرائیڈ کی دکھائی گئی اسکرین پر انسٹال کی تصدیق کریں۔';

  @override
  String get updateStopsFilter =>
      'انسٹال کرنے سے فلٹرنگ رک جاتی ہے۔ اپ ڈیٹ کے بعد اسے دوبارہ شروع کریں۔';

  @override
  String get updatePermission =>
      'واعیہ کو اپنی اپ ڈیٹس انسٹال کرنے کی اجازت دیں، پھر دوبارہ ابھی اپ ڈیٹ کریں دبائیں۔';

  @override
  String get updateFailed =>
      'اپ ڈیٹ مکمل نہیں ہو سکی۔ بعد میں کوشش کریں، یا ویب سائٹ سے ڈاؤن لوڈ کریں۔';

  @override
  String get updateOpenPage => 'ڈاؤن لوڈ کا صفحہ کھولیں';

  @override
  String get updateCheckFailed => 'ابھی تلاش نہیں ہو سکی۔ بعد میں کوشش کریں۔';

  @override
  String get moveOldTitle => '‏واعیہ منتقل ہو گئی ہے';

  @override
  String get moveOldBody =>
      '‏واعیہ اب Android پر ایک نئی ایپ کے طور پر آتی ہے (وہی واعیہ، نئے نام سے)، اور اس ایپ کو اب کوئی اپ ڈیٹ نہیں ملے گی۔ نئی ایپ انسٹال کریں: آپ کی سیٹنگز ساتھ جائیں گی۔ پھر اس کا ایک بار کا سیٹ اپ کریں اور اسے ہٹا دیں۔';

  @override
  String get moveOldInstalled =>
      '‏نئی واعیہ انسٹال ہو گئی ہے۔ اسے کھولیں: یہ آپ کی سیٹنگز لے لے گی۔ اس کا ایک بار کا سیٹ اپ کریں، پھر اس پرانی کو ہٹا دیں تاکہ دونوں کبھی ایک ساتھ فلٹر نہ کریں۔';

  @override
  String get moveInstall => '‏نئی واعیہ انسٹال کریں';

  @override
  String get moveOpenNew => '‏نئی واعیہ کھولیں';

  @override
  String get moveRemoveThis => '‏یہ پرانی واعیہ ہٹائیں';

  @override
  String get moveNewTitle => '‏پرانی واعیہ ابھی تک انسٹال ہے';

  @override
  String get moveNewBody =>
      '‏پرانی واعیہ (ورژن 0.2.15 سے پہلے کی) ابھی تک اس فون پر ہے۔ اسے ہٹا دیں تاکہ دونوں کبھی ایک ساتھ فلٹر نہ کریں۔';

  @override
  String get moveNewImported => '‏آپ کی سیٹنگز اس سے لے آئی گئی ہیں۔';

  @override
  String get moveRemoveOld => '‏پرانی واعیہ ہٹائیں';

  @override
  String get desktopPreview =>
      'پیش نظارہ: اس کمپیوٹر پر فلٹر انجن ابھی منسلک نہیں ہے۔ بٹن صرف یہ دکھاتا ہے کہ ایپ کیسے کام کرے گی۔';

  @override
  String actionFailed(String details) {
    return 'یہ کام نہیں ہوا: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'آپ کی ایپس کی آواز فلٹر ہو رہی ہے۔';

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
      'اس کمپیوٹر پر واعية کیا دیکھتی ہے۔ اسے کاپی کریں اور جو آپ کی مدد کر رہا ہو اسے دے دیں۔ واعية اسے خود نہیں بھیجتی: آپ چنتے ہیں کہ یہ کسے ملے۔';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'تجویز کردہ۔ اگر فلٹرنگ خود بخود رک جائے (کسی خرابی سے، آپ کے روکنے سے نہیں)، تو دوسری ایپس خاموش رہتی ہیں جب تک آپ دوبارہ شروع نہ کریں یا «روکیں» نہ دبائیں، بجائے اس کے کہ موسیقی بغیر فلٹر کے چلے۔';

  @override
  String get settingStereoBodyDesktop =>
      'بند: مونو، جو کمپیوٹر پر کم بوجھ ڈالتا ہے۔ آن: بائیں اور دائیں آواز کو الگ رکھتا ہے۔ اگر کمپیوٹر اسٹیریو کے لیے بہت سست ہو تو یہ خود ہی مونو پر آ جاتا ہے۔';

  @override
  String get linkEntryBodyDesktop =>
      'یوٹیوب، ٹک ٹاک یا انسٹاگرام کا لنک پیسٹ کریں تاکہ اسے فلٹر چلتے ہوئے دیکھیں، یا بغیر موسیقی محفوظ کریں۔';

  @override
  String get linkEntryBodyWatch =>
      'یوٹیوب، ٹک ٹاک یا انسٹاگرام کا لنک پیسٹ کریں تاکہ اسے اپنے براؤزر میں فلٹر چلتے ہوئے دیکھیں۔';

  @override
  String get linkWatchNoteDesktop =>
      'آپ کے براؤزر میں کھلتا ہے۔ Waaiya پہلے فلٹر شروع کرتا ہے، اس لیے وہاں بھی موسیقی ہٹ جاتی ہے۔';

  @override
  String get linkFilterFailed =>
      'فلٹر شروع نہیں ہوا، اس لیے لنک نہیں کھولا گیا۔ فلٹر کے صفحے سے اسے شروع کریں اور دوبارہ کوشش کریں۔';

  @override
  String get linkSavedVideoDesktop => 'آپ کے ویڈیوز فولڈر میں: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'آپ کے میوزک فولڈر میں: Waaiya';

  @override
  String get linkShowInFolder => 'فولڈر میں دکھائیں';

  @override
  String get linkSingingNote =>
      'آپ کی ترتیبات کے مطابق خواتین کا گانا بھی خاموش کیا جاتا ہے۔';

  @override
  String get singingKeepTitle => 'گانے کی آوازیں رکھیں (آزمائشی)';

  @override
  String get singingKeepBody =>
      'ساز ہٹا دیے جاتے ہیں مگر گانے کی آوازیں رہتی ہیں، اس لیے جس بیان کے پیچھے نشید ہو اس میں نشید کی آواز بھی رہتی ہے؛ یہ قابلِ قبول ہے یا نہیں، یہ آپ کا فیصلہ ہے۔';

  @override
  String get singingKeepNoModel =>
      'اس ورژن میں گانے کا ماڈل نہیں ہے، اس لیے جب تک یہ آن ہے آواز خاموش رہے گی۔ اسے بند کریں۔';

  @override
  String get fixFilterAppsTitle => 'بغیر فلٹر سنی جانے والی ایپس';

  @override
  String get fixFilterAppsBody =>
      'یہاں آپ جو ایپس چنیں وہ اپنی اصل آواز میں چلتی ہیں: نہ فلٹر، نہ خاموشی۔ مثال کے طور پر، ویڈیو کال کی ایپ، تاکہ کالوں میں تاخیر نہ ہو۔';

  @override
  String get fixAddApp => 'ایپ شامل کریں';

  @override
  String fixRemoveApp(Object app) {
    return '$app ہٹائیں';
  }

  @override
  String get fixNoApps => 'کوئی ایپ منتخب نہیں۔';

  @override
  String get fixPickTitle => 'ایپ منتخب کریں';

  @override
  String get fixPickEmpty => 'کوئی اور ایپ نہیں ملی۔';

  @override
  String get fixPickPlayingDesktop =>
      'اس وقت آواز چلانے والی ایپس، اور پہلے سے منتخب ایپس۔';

  @override
  String get fixCancel => 'منسوخ کریں';

  @override
  String get fixBlurAppsTitle => 'بغیر دھندلاہٹ والی ایپس';

  @override
  String get fixBlurAppsBody =>
      'جب تک ان میں سے کوئی ایپ پوری اسکرین پر ہو، مثلاً نقشے کی ایپ یا آپ کے بینک کی ایپ، کوئی پردہ نہیں لگتا۔ اسے چھوڑتے ہی پردے واپس آ جاتے ہیں، یا جب بھی واعية کو یقین نہ ہو کہ کون سی ایپ دکھ رہی ہے۔';

  @override
  String get fixBlurAppsNeedsSetup =>
      'ایک بار کا سیٹ اپ درکار ہے: اس کے بغیر واعية نہیں جان سکتی کہ اسکرین پر کون سی ایپ ہے، اس لیے دھندلاہٹ ہر جگہ رہتی ہے۔';

  @override
  String get fixBlurAppsHelperMode =>
      'واعية کا مددگار نہیں چل رہا، اس لیے اسکرین پر موجود ایپ معلوم نہیں ہو سکتی۔ جب تک سیٹ اپ صفحے سے مددگار دوبارہ شروع نہ ہو، دھندلاہٹ ہر جگہ رہے گی۔';

  @override
  String get fixHandTitle => 'ہاتھ سے کوئی حصہ ڈھانپیں';

  @override
  String get fixHandBody =>
      'دھندلاہٹ چلتے وقت آپ خود اسکرین کا کوئی حصہ ڈھانپ سکتے ہیں، مثلاً کوئی تصویر جو دھندلاہٹ سے رہ گئی ہو: “کوئی حصہ ڈھانپیں” دبائیں اور اس پر انگلی گھسیٹیں۔ یہ تب تک ڈھکا رہتا ہے جب تک آپ اسے ہٹا نہ دیں یا دھندلاہٹ رک نہ جائے۔';

  @override
  String get fixHandNotRunning =>
      'دھندلاہٹ چلنے کے دوران دستیاب: فلٹرنگ آن اور دھندلاہٹ کا کوئی آپشن آن۔';

  @override
  String get fixCoverArea => 'کوئی حصہ ڈھانپیں';

  @override
  String fixRemoveCovers(Object count) {
    return 'ہاتھ کے پردے ہٹائیں ($count)';
  }

  @override
  String get fixNoteTitle => 'غلطی نوٹ کریں';

  @override
  String get fixNoteBody =>
      'جب واعية سے کوئی غلطی ہو، تو جو ہوا اسے دبائیں، مثلاً “موسیقی گزر گئی”۔ نوٹ میں وقت، ایپ اور ترتیبات محفوظ ہوتی ہیں، تاکہ وجہ معلوم کرنے میں مدد ملے۔ یہ اسی آلے پر رہتا ہے اور کبھی بھیجا نہیں جاتا۔';

  @override
  String get fixMissedSound => 'موسیقی گزر گئی';

  @override
  String get fixWrongSound => 'آواز غلطی سے ہٹ گئی';

  @override
  String get fixMissedScreen => 'کچھ ڈھکا نہیں گیا';

  @override
  String get fixWrongScreen => 'غلطی سے ڈھکا گیا';

  @override
  String fixNoted(Object count) {
    return 'نوٹ ہو گیا۔ اس آلے پر نوٹس: $count۔';
  }

  @override
  String fixNotesCount(Object count) {
    return 'اس آلے پر نوٹس: $count';
  }

  @override
  String get fixNotesShow => 'نوٹس دکھائیں';

  @override
  String get fixNotesDelete => 'نوٹس حذف کریں';

  @override
  String get fixNotesDeleteAsk => 'تمام نوٹس حذف کریں؟ یہ واپس نہیں ہو سکتا۔';

  @override
  String get fixNotesTitle => 'غلطیوں کے نوٹس';

  @override
  String get worshipTitle => 'نماز کے اوقات';

  @override
  String get worshipBody =>
      'اختیاری۔ آپ کے منتخب کردہ مقام سے اسی فون پر حساب کیے جاتے ہیں۔ کچھ نہیں بھیجا جاتا۔';

  @override
  String worshipPlace(Object place) {
    return 'مقام: $place';
  }

  @override
  String get worshipPlaceNone => 'مقام: منتخب نہیں';

  @override
  String get worshipChoose => 'منتخب کریں';

  @override
  String get worshipPlaceSearch => 'شہر تلاش کریں';

  @override
  String get worshipPlaceNoMatch =>
      'کوئی شہر نہیں ملا۔ آپ اس کی جگہ نقاط درج کر سکتے ہیں۔';

  @override
  String get worshipPlaceCustom => 'نقاط درج کریں';

  @override
  String get worshipLat => 'عرض بلد (شمال +، جنوب −)';

  @override
  String get worshipLon => 'طول بلد (مشرق +، مغرب −)';

  @override
  String get worshipZone => 'ٹائم زون، مثلاً Asia/Karachi';

  @override
  String get worshipCustomInvalid => 'نمبر اور ٹائم زون چیک کریں۔';

  @override
  String get worshipPlaceInvalid =>
      'یہ مقام استعمال نہیں ہو سکتا۔ دوبارہ منتخب کریں۔';

  @override
  String worshipMethod(Object method) {
    return 'حساب کا طریقہ: $method';
  }

  @override
  String get worshipMethodTitle => 'حساب کا طریقہ';

  @override
  String get worshipMethodNote =>
      'شہر کے ملک کے مطابق چنا گیا ہے۔ وہ طریقہ چنیں جس پر آپ کی مسجد چلتی ہے۔';

  @override
  String worshipAsr(Object rule) {
    return 'عصر: $rule';
  }

  @override
  String get worshipAsrTitle => 'عصر کا وقت';

  @override
  String get worshipAsrStandard => 'جمہور (شافعی، مالکی، حنبلی)';

  @override
  String get worshipAsrHanafi => 'حنفی';

  @override
  String get worshipMethodMwl => 'رابطہ عالم اسلامی';

  @override
  String get worshipMethodIsna => 'اسلامک سوسائٹی آف نارتھ امریکا (ISNA)';

  @override
  String get worshipMethodEgypt => 'مصری جنرل اتھارٹی آف سروے';

  @override
  String get worshipMethodUmmAlQura => 'ام القریٰ، مکہ مکرمہ';

  @override
  String get worshipMethodKarachi => 'جامعہ علوم اسلامیہ، کراچی';

  @override
  String get worshipMethodTehran => 'انسٹی ٹیوٹ آف جیو فزکس، تہران یونیورسٹی';

  @override
  String get worshipMethodGulf => 'خلیجی خطہ';

  @override
  String get worshipMethodKuwait => 'کویت';

  @override
  String get worshipMethodQatar => 'قطر';

  @override
  String get worshipMethodSingapore => 'سنگاپور (MUIS)';

  @override
  String get worshipMethodTurkey => 'ترکی (دیانت)';

  @override
  String get worshipMethodFrance => 'فرانس (UOIF، 12°)';

  @override
  String get worshipMethodMorocco => 'مراکش (وزارت اوقاف)';

  @override
  String get worshipMethodIndonesia => 'انڈونیشیا (وزارت مذہبی امور)';

  @override
  String get worshipMethodMalaysia => 'ملائیشیا (JAKIM)';

  @override
  String get worshipMethodDubai => 'دبئی';

  @override
  String get worshipToday => 'آج';

  @override
  String get worshipNoTimes =>
      'آج یہاں نماز کے اوقات نہیں: سورج طلوع یا غروب نہیں ہوتا۔';

  @override
  String get worshipSilentTitle => 'نماز کے اوقات میں خاموش';

  @override
  String get worshipSilentBody =>
      'ہر نماز کے وقت فون نیچے دیے گئے منٹوں تک خاموش ہو جاتا ہے («ڈسٹرب نہ کریں»)، پھر پہلے جیسا ہو جاتا ہے۔ مثلاً ظہر کے وقت 12:00 سے 12:20 تک۔';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'خاموشی کی مدت: $minutes منٹ';
  }

  @override
  String get worshipMuteTitle => 'اذان پر میڈیا خاموش';

  @override
  String get worshipMuteBody =>
      'ہر نماز کے وقت میڈیا کی آواز (ویڈیو، آڈیو، گیمز) نیچے دیے گئے منٹوں تک بند۔ اطلاع سے فوراً کھول سکتے ہیں۔';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'خاموشی کی مدت: $minutes منٹ';
  }

  @override
  String get worshipMinutesTitle => 'دورانیہ';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes منٹ';
  }

  @override
  String get worshipNeedPlace => 'پہلے مقام منتخب کریں۔';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'اگلی: $prayer، $time بجے';
  }

  @override
  String worshipSilentNow(Object time) {
    return '$time تک خاموش۔';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'میڈیا $time تک خاموش۔';
  }

  @override
  String get worshipDndNeeded =>
      'واعية کو «ڈسٹرب نہ کریں» بدلنے کی اجازت دیں، ورنہ فون خاموش نہیں ہو سکتا۔';

  @override
  String get worshipAllow => 'اجازت دیں';

  @override
  String get worshipExactNeeded =>
      'واعية کے لیے «الارم اور یاد دہانیاں» کی اجازت نہیں، اس لیے ہر تبدیلی 10 منٹ تک، یا فون سوتے وقت اس سے زیادہ، دیر سے ہو سکتی ہے۔';

  @override
  String get worshipNotificationsNeeded =>
      'اطلاعات بند ہیں: آپ نہیں دیکھ پائیں گے کہ فون کب خاموش ہوا یا واپس آیا۔';

  @override
  String get worshipTonesTitle => 'سادہ رنگ ٹون اور اطلاع کی آواز';

  @override
  String get worshipTonesBody =>
      'واعية رنگ ٹون اور اطلاع کی آوازوں کو فلٹر نہیں کر سکتا، صرف بدل سکتا ہے۔ بغیر موسیقی کی سادہ آواز چنیں:';

  @override
  String worshipToneRing(Object number) {
    return 'سادہ رنگ ٹون $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'سادہ اطلاع کی آواز $number';
  }

  @override
  String get worshipTonePlay => 'چلائیں';

  @override
  String get worshipToneSet => 'استعمال کریں';

  @override
  String get worshipToneInUse => 'زیر استعمال';

  @override
  String get worshipToneDone => 'ہو گیا۔';

  @override
  String get worshipTonePermission =>
      'واعية کو سسٹم سیٹنگز بدلنے کی اجازت دیں، واپس آئیں اور دوبارہ دبائیں۔';

  @override
  String get worshipToneFailed =>
      'اس فون نے واعية کو بدلنے نہیں دیا۔ آواز کی سیٹنگز میں «Waaiya plain» نام کی ٹون چنیں۔';

  @override
  String get worshipOpenSound => 'آواز کی سیٹنگز کھولیں';

  @override
  String get worshipSmsTitle => 'نماز کے دوران کالوں کا جواب SMS سے';

  @override
  String get worshipSmsBody =>
      'ہر نماز کے وقت کے بعد خاموشی کے منٹوں میں، بجتی رہ جانے والی کال کو ایک SMS جاتا ہے۔ ہر نمبر کو ہر نماز میں ایک بار؛ چھپے یا مختصر نمبروں کو کبھی نہیں۔';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'اتنی دیر بجنے کے بعد: $seconds سیکنڈ';
  }

  @override
  String get worshipSmsDelayTitle => 'SMS سے پہلے بجنے کے سیکنڈ';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds سیکنڈ';
  }

  @override
  String worshipSmsText(Object text) {
    return 'پیغام: $text';
  }

  @override
  String get worshipSmsTextTitle => 'آپ کا پیغام';

  @override
  String get worshipSmsTextDefault => 'طے شدہ پیغام';

  @override
  String get worshipSmsCost =>
      'ہر جواب آپ کی SIM سے ایک عام SMS ہے، آپ کے پیکج کی قیمت پر۔ رومنگ کے دوران کچھ نہیں بھیجا جاتا۔';

  @override
  String get worshipSmsRoaming =>
      'ابھی رومنگ میں ہیں: کوئی SMS نہیں بھیجا جائے گا۔';

  @override
  String get worshipSmsLogTitle => 'بھیجے گئے جوابات (صرف اسی فون پر محفوظ)';

  @override
  String get worshipContinue => 'جاری رکھیں';

  @override
  String get worshipWhyDnd =>
      'نماز کے اوقات میں فون خاموش کرنے کے لیے، اگلے صفحے پر واعية کو «ڈسٹرب نہ کریں» تک رسائی دیں۔';

  @override
  String get worshipWhyExact =>
      'بالکل وقت پر کام کے لیے، اگلے صفحے پر واعية کو الارم اور یاد دہانیاں لگانے کی اجازت دیں۔ اس کے بغیر تبدیلیاں 10 منٹ تک دیر سے ہو سکتی ہیں۔';

  @override
  String get worshipWhyNotifications =>
      'اطلاعات کی اجازت دیں تاکہ آپ ہر تبدیلی دیکھ سکیں اور اسے واپس کر سکیں۔';

  @override
  String get worshipWhyWrite =>
      'رنگ ٹون یا اطلاع کی آواز بدلنے کے لیے، اگلے صفحے پر واعية کو سسٹم سیٹنگز بدلنے کی اجازت دیں۔';

  @override
  String get worshipWhyPhone =>
      'یہ جاننے کے لیے کہ کال بج رہی ہے اور اس کا نمبر کیا ہے، واعية کو «فون» اور «کال لاگز» کی اجازتیں چاہییں۔ آپ کے جواب کے سوا کچھ فون سے باہر نہیں جاتا۔';

  @override
  String get worshipWhySms =>
      'آپ کا جواب بھیجنے کے لیے واعية کو SMS بھیجنے کی اجازت چاہیے۔ یہ صرف وہی جواب بھیجتا ہے، ہر نمبر کو ہر نماز میں زیادہ سے زیادہ ایک بار۔';

  @override
  String get worshipMissingDnd =>
      '«ڈسٹرب نہ کریں» تک رسائی نہیں دی گئی، اس لیے خاموشی بند رہے گی۔';

  @override
  String get worshipMissingPhone =>
      '«فون» اور «کال لاگز» کی اجازتیں نہیں دی گئیں، اس لیے SMS جواب بند رہے گا۔';

  @override
  String get worshipMissingSms =>
      'SMS بھیجنے کی اجازت نہیں دی گئی، اس لیے SMS جواب بند رہے گا۔';

  @override
  String get worshipTryAgain => 'دوبارہ کوشش کریں';

  @override
  String get protectTitle => 'کمزور لمحوں کے لیے تحفظ';

  @override
  String get protectBody =>
      'کمزوری کے اس لمحے کے لیے جب آپ فلٹر بند کرنا چاہیں۔ ابھی، سکون کی حالت میں، انتظار کا وقت چنیں: پھر بند کرنے کا بٹن فلٹر کو فوراً بند نہیں کرتا، اور وقت پورا ہونے پر آپ دوبارہ فیصلہ کرتے ہیں۔ والدین PIN بھی لگا سکتے ہیں۔';

  @override
  String protectDelay(Object value) {
    return 'بند کرنے سے پہلے انتظار: $value';
  }

  @override
  String get protectDelayTitle => 'بند کرنے سے پہلے انتظار';

  @override
  String get protectDelayBody =>
      'مثال کے طور پر 30 منٹ کے ساتھ: آپ بند کرنے کا بٹن دباتے ہیں، مگر فلٹر چلتا رہتا ہے۔ 30 منٹ بعد یہ صفحہ پوچھتا ہے کہ کیا آپ اب بھی بند کرنا چاہتے ہیں۔ 15 منٹ کے اندر “تصدیق کریں” دبائیں تو یہ بند ہو جاتا ہے، ورنہ کچھ نہیں بدلتا۔ کوئی پردہ یا کوئی اور حفاظت بند کرنے میں بھی یہی ہوتا ہے۔ کچھ چالو کرنا ہمیشہ فوراً ہوتا ہے۔';

  @override
  String get protectDelayOff => 'کوئی نہیں';

  @override
  String get protectDelay1m => '1 منٹ';

  @override
  String get protectDelay5m => '5 منٹ';

  @override
  String get protectDelay15m => '15 منٹ';

  @override
  String get protectDelay30m => '30 منٹ';

  @override
  String get protectDelay1h => '1 گھنٹہ';

  @override
  String get protectDelay4h => '4 گھنٹے';

  @override
  String get protectDelay24h => '24 گھنٹے';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes منٹ';
  }

  @override
  String get protectPinNone => 'PIN: نہیں لگا';

  @override
  String get protectPinIsSet => 'PIN: لگا ہوا ہے';

  @override
  String get protectPinSet => 'PIN لگائیں';

  @override
  String get protectPinRemove => 'ہٹائیں';

  @override
  String get protectPinBody =>
      'PIN لگا ہو تو فلٹر روکنے یا کوئی بھی تحفظ بند کرنے سے پہلے PIN مانگا جاتا ہے۔ مثلاً ماں یا باپ PIN لگا دیتے ہیں تاکہ بچہ واعية میں فلٹر بند نہ کر سکے (جو یہ نہیں روک سکتا وہ نیچے درج ہے)۔ انتظار کا وقت یا PIN بدلنے کے لیے بھی یہ مانگا جاتا ہے۔';

  @override
  String get protectPinForgot =>
      'PIN کسی محفوظ جگہ لکھ لیں: اگر بھول گیا تو اسے ری سیٹ کرنے کا کوئی طریقہ نہیں۔ واحد راستہ واعية کا ڈیٹا صاف کرنا یا اسے دوبارہ انسٹال کرنا ہے، جس سے اس کی تمام ترتیبات بھی مٹ جاتی ہیں۔';

  @override
  String get protectPinTitle => 'PIN درج کریں';

  @override
  String get protectPinNewTitle => 'PIN منتخب کریں';

  @override
  String get protectPinChangeTitle => 'PIN بدلیں';

  @override
  String get protectPinCurrent => 'موجودہ PIN';

  @override
  String get protectPinNew => 'نیا PIN (4 سے 8 ہندسے)';

  @override
  String get protectPinAgain => 'نیا PIN دوبارہ';

  @override
  String get protectPinBad => '4 سے 8 ہندسے استعمال کریں۔';

  @override
  String get protectPinDiffer => 'دونوں نئے PIN ایک جیسے نہیں ہیں۔';

  @override
  String protectPinWrong(Object count) {
    return 'غلط PIN۔ وقفے سے پہلے باقی کوششیں: $count۔';
  }

  @override
  String protectLocked(Object time) {
    return 'بہت زیادہ غلط کوششیں۔ $time پر دوبارہ کوشش کریں۔';
  }

  @override
  String get protectOk => 'ٹھیک ہے';

  @override
  String get protectCancel => 'منسوخ کریں';

  @override
  String get protectCancelChange => 'تبدیلی منسوخ کریں';

  @override
  String get protectConfirm => 'تصدیق کریں';

  @override
  String protectPending(Object time, Object what) {
    return '$what: $time تک انتظار۔ پھر “ترتیبات” میں تصدیق کریں۔';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: انتظار ختم ہو گیا۔ کیا آپ اب بھی یہ چاہتے ہیں؟ $time سے پہلے “تصدیق کریں” دبائیں، ورنہ کچھ نہیں بدلے گا۔';
  }

  @override
  String get protectWaitTitle => 'یہ تبدیلی انتظار میں ہے';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what ابھی نہیں ہوگا۔ $time پر، اگر آپ تب بھی چاہیں، تو 15 منٹ کے اندر “ترتیبات” میں اس کی تصدیق کریں۔ اگر آپ کچھ نہ کریں تو کچھ نہیں بدلے گا۔';
  }

  @override
  String get protectWaitStart => 'انتظار شروع کریں';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'پہلے سے $time تک انتظار جاری ہے۔';
  }

  @override
  String protectStarted(Object time) {
    return '$time تک انتظار۔ پھر “ترتیبات” میں تصدیق کریں۔';
  }

  @override
  String protectTomorrow(Object time) {
    return 'کل $time پر';
  }

  @override
  String get protectHeldBack =>
      'ابھی نہیں: آپ کی تحفظ کی ترتیبات کے مطابق یہ تبدیلی انتظار کرے گی، یا PIN مانگا جائے گا۔';

  @override
  String get protectLimits =>
      'جو یہ نہیں روک سکتا: فون ری اسٹارٹ کرنا (فلٹرنگ خود سے دوبارہ شروع نہیں ہوتی)، زبردستی بند کرنا، ان انسٹال کرنا، واعية کا ڈیٹا صاف کرنا اور خود Android کی ترتیبات۔ انہیں روکنے کے لیے Android کی خاص اجازتیں چاہئیں جو واعية استعمال نہیں کرتی۔ یہ کمزور لمحے سے بچاتا ہے، پختہ ارادے والے شخص سے نہیں۔';

  @override
  String get protectLimitsDesktop =>
      'جو یہ نہیں روک سکتا: ٹرمینل میں waaiya کمانڈ، واعية کو ہٹانا یا اس کی ترتیبات کا فولڈر حذف کرنا۔ یہ کمزور لمحے سے بچاتا ہے، پختہ ارادے والے شخص سے نہیں۔';

  @override
  String get protectLimitsWindows =>
      'جو یہ نہیں روک سکتا: ٹرمینل میں waaiya-filter.exe کمانڈ، واعية کو ہٹانا یا اس کی ترتیبات کا فولڈر حذف کرنا۔ یہ کمزور لمحے سے بچاتا ہے، پختہ ارادے والے شخص سے نہیں۔';

  @override
  String get protectWhatStop => 'فلٹر روکنا';

  @override
  String protectWhatOff(Object name) {
    return 'بند کرنا: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'چالو کرنا: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'ایپ شامل کرنا: $name';
  }

  @override
  String get protectWhatStrictness => 'دھندلاہٹ کو کم سخت کرنا';

  @override
  String get protectWhatGender => 'واعية کون استعمال کرتا ہے، بدلنا';

  @override
  String protectWhatDelay(Object value) {
    return 'بند کرنے سے پہلے انتظار بدل کر یہ کریں: $value';
  }

  @override
  String get protectWhatPinChange => 'PIN بدلنا';

  @override
  String get protectWhatPinClear => 'PIN ہٹانا';

  @override
  String get protectWhatSetting => 'کوئی ترتیب بدلنا';

  @override
  String get onboardBodyDesktop =>
      'واعية اس کمپیوٹر کی ایپس کی آواز سے موسیقی کے آلات ہٹاتی ہے۔ بات چیت اور قرآن کی تلاوت باقی رہتی ہے۔ گانے کی آوازیں بھی ہٹا دی جاتی ہیں۔';

  @override
  String get worshipUseLocation => 'میرا مقام استعمال کریں';

  @override
  String get worshipWhyLocation =>
      'جہاں آپ ہیں وہاں کے نماز کے اوقات جاننے کے لیے واعیہ اس فون کا تقریبی مقام ایک بار، ابھی، پڑھتا ہے۔ یہ فون پر آپ کی جگہ کے طور پر رہتا ہے اور کہیں نہیں بھیجا جاتا۔';

  @override
  String get worshipLocating => 'آپ کا مقام تلاش کیا جا رہا ہے…';

  @override
  String get worshipLocationDenied =>
      'مقام کی اجازت نہیں دی گئی۔ اس کے بجائے آپ اپنا شہر تلاش کر سکتے ہیں۔';

  @override
  String get worshipLocationOff =>
      'اس فون میں مقام بند ہے۔ اسے آن کر کے دوبارہ کوشش کریں، یا اپنا شہر تلاش کریں۔';

  @override
  String get worshipLocationSettings => 'مقام کی ترتیبات';

  @override
  String get worshipLocationFailed =>
      'آپ کا مقام نہیں مل سکا۔ تھوڑی دیر بعد دوبارہ کوشش کریں، یا اپنا شہر تلاش کریں۔';

  @override
  String worshipPlaceNear(Object city) {
    return '$city کے قریب';
  }

  @override
  String worshipHabousNote(Object city) {
    return '$city کے لیے وزارتِ اوقاف و امورِ اسلامیہ (مراکش) کے جدولوں کے مطابق حساب کیے گئے اوقات۔';
  }

  @override
  String get trayOpen => 'واعية کھولیں';

  @override
  String get trayQuit => 'باہر نکلیں';

  @override
  String get engineErrorAutostartBlocked =>
      'ونڈوز لاگ اِن پر واعية کو شروع ہونے نہیں دے رہا۔ ترتیبات › ایپس › اسٹارٹ اپ میں واعية کو آن کریں، پھر اسے دوبارہ آن کریں۔';

  @override
  String get engineErrorAutostartPolicy =>
      'اس کمپیوٹر کی ترتیبات، جو اس کے منتظم نے منتخب کی ہیں، لاگ اِن پر واعية کو شروع ہونے نہیں دیتیں۔';

  @override
  String get notifTextTitle => 'فلٹر کے دوران اطلاعات کا متن دکھائیں';

  @override
  String get notifTextBody =>
      'جب کوئی ایپ پوری اسکرین ریکارڈ کرے تو اینڈرائیڈ اطلاعات کا متن چھپا دیتا ہے، اور فلٹرنگ بھی اسی میں شمار ہوتی ہے۔ آن: واعية یہ حفاظت صرف فلٹر کے دوران ہٹاتی ہے تاکہ آپ اپنی اطلاعات پڑھ سکیں۔ جب تک یہ حفاظت ہٹی رہے، اسی وقت کی کوئی دوسری اسکرین شیئرنگ بھی آپ کی اطلاعات اور کوڈ دوسروں کو دکھا سکتی ہے۔';

  @override
  String get notifTextNextStart =>
      'یہ تبدیلی نافذ کرنے کے لیے فلٹر بند کر کے دوبارہ شروع کریں۔';

  @override
  String get notifTextRefused =>
      'اس فون نے تبدیلی قبول نہیں کی۔ ڈویلپر کے اختیارات میں ”اسکرین شیئر کی حفاظت غیر فعال کریں“ خود آن کریں۔';

  @override
  String get notifTextByHand =>
      'دکھایا جا رہا ہے: ڈویلپر کے اختیارات میں اینڈرائیڈ کی حفاظت بند ہے (”اسکرین شیئر کی حفاظت غیر فعال کریں“)۔ یہ ہر اسکرین شیئرنگ کے لیے بند رہے گی جب تک آپ اسے وہاں دوبارہ آن نہ کریں۔';

  @override
  String get notifTextHowTo =>
      'واعیہ کے فلٹر کے دوران اینڈرائیڈ اطلاعات کا متن چھپا دیتا ہے۔ ایک بار کے سیٹ اپ کے بعد واعیہ انہیں دکھاتا ہے: یہ حفاظت صرف فلٹر کے دوران ہٹاتا ہے۔';

  @override
  String get notifTextOpenDev => 'ڈویلپر کے اختیارات کھولیں';

  @override
  String get notifTextLockNote =>
      'اس فون پر اسکرین لاک ہونے پر اینڈرائیڈ فلٹرنگ بھی روک دیتا ہے، پھر دوسری ایپس خاموش رہتی ہیں جب تک آپ ”دوبارہ شروع کریں“ نہ دبائیں۔ سیٹ اپ اسے بھی روکتا ہے۔';

  @override
  String get notifTextHandOptional =>
      'اختیاری، بغیر سیٹ اپ کے: ڈویلپر کے اختیارات میں ”اسکرین شیئر کی حفاظت غیر فعال کریں“ آن کریں۔ پھر یہ ہر اسکرین شیئرنگ کے لیے بند رہے گی، اور کچھ فونز میں یہ نہیں ہوتا۔';

  @override
  String get notifTextForced =>
      'آن: اس فون پر اینڈرائیڈ ہر بار شروع کرنے سے پہلے پوچھتا ہے اور پھر ہر اسکرین لاک پر فلٹرنگ روک دیتا۔ اس لیے واعية فلٹر کے دوران یہ حفاظت ہٹاتی ہے، جس سے اطلاعات کا متن بھی دکھتا ہے۔ جب تک یہ حفاظت ہٹی رہے، اسی وقت کی کوئی دوسری اسکرین شیئرنگ بھی آپ کی اطلاعات اور کوڈ دوسروں کو دکھا سکتی ہے۔';

  @override
  String get oneAppTitle => 'شروع کرتے وقت: ”ایک ایپ شیئر کریں“، پھر واعیہ';

  @override
  String get oneAppBody =>
      'جب اینڈرائیڈ پوچھے کہ کیا شیئر کرنا ہے، تو ”ایک ایپ شیئر کریں“ چنیں، پھر واعية۔ دوسری ایپس فلٹر ہوتی رہیں گی، اطلاعات پڑھی جا سکیں گی، اور اسکرین لاک ہونے پر بھی فلٹرنگ جاری رہے گی۔ پوری اسکرین کے ساتھ اینڈرائیڈ اطلاعات کا متن چھپا دیتا ہے اور ہر لاک پر فلٹرنگ روک دیتا ہے۔';

  @override
  String get oneAppPair =>
      'واعیہ کے مکمل کام کے لیے سیٹ اپ والے صفحے پر وائرلیس ڈیبگنگ سے اسے ایک بار جوڑیں: پھر اصل موسیقی بھی خاموش ہو جائے گی اور اینڈرائیڈ ہر بار شروع پر پوچھنا بند کر دے گا۔';

  @override
  String get notifTextOneApp =>
      'شروع پر ”ایک ایپ شیئر کریں“، پھر واعیہ چننے پر دکھایا جاتا ہے۔ پوری اسکرین کے ساتھ اینڈرائیڈ اسے چھپاتا ہے؛ ایک بار کے سیٹ اپ کے بعد واعیہ فلٹر کے دوران یہ ہٹا دیتا ہے۔';

  @override
  String get blurNeedsRestart =>
      'دھندلاہٹ استعمال کرنے کے لیے فلٹر بند کر کے دوبارہ شروع کریں: اسے پوری اسکرین چاہیے، اور یہ فلٹرنگ ”ایک ایپ شیئر کریں“ کی پیشکش کے ساتھ شروع ہوئی تھی۔';

  @override
  String get micOpenSettings =>
      'مائیکروفون کی اجازت کے لیے واعية کی ترتیبات کھولیں';

  @override
  String get keepRunningTitle => 'واعية کو چلتا رکھیں';

  @override
  String get keepRunningBattery =>
      'یہ فون بیٹری بچانے کے لیے کچھ دیر بعد واعية کو بند کر سکتا ہے، پھر فلٹرنگ رک جاتی ہے۔ واعية کی ترتیبات میں بیٹری کے تحت «غیر محدود» منتخب کریں۔ Xiaomi، Redmi اور POCO پر: «کوئی پابندی نہیں»، اور آٹو اسٹارٹ بھی آن کریں۔';

  @override
  String get keepRunningNotifications =>
      'واعية کی اطلاعات بند ہیں، اس لیے فلٹرنگ رکنے پر یہ آپ کو نہیں بتا سکتا۔ انہیں واعية کی ترتیبات میں آن کریں۔';

  @override
  String get keepRunningOpen => 'واعية کی ترتیبات کھولیں';

  @override
  String get lockAskTitle => 'کیا اسکرین لاک ہونے پر فلٹرنگ جاری رہے؟';

  @override
  String get lockTitle => 'اسکرین لاک ہونے پر فلٹرنگ جاری رکھیں';

  @override
  String get lockBody =>
      'اس فون پر Android ہر بار شروع کرنے سے پہلے پوچھتا ہے، پھر ہر بار اسکرین لاک ہونے پر فلٹرنگ روک دیتا ہے۔ واعية فلٹرنگ کے دوران Android کی اسکرین شیئر حفاظت ہٹا کر اسے روک سکتا ہے، اور فلٹرنگ رکنے پر اسے واپس لگا دیتا ہے۔ جب تک یہ ہٹی رہے، اسی وقت کوئی دوسری اسکرین شیئرنگ (مثلاً ویڈیو کال) آپ کی اطلاعات بھی دکھا سکتی ہے۔ تبدیلی اگلی بار شروع کرنے پر نافذ ہوگی۔';

  @override
  String get lockYes => 'فلٹرنگ جاری رکھیں';

  @override
  String get lockNo => 'ہر لاک پر روک دیں';

  @override
  String get sendToSupport => 'واعية کو بھیجیں';

  @override
  String get stateTooSlowNoLinks =>
      'یہ فون براہ راست آواز فلٹر کرنے کے لیے بہت سست ہے، اس لیے آواز ٹوٹتی ہے۔';

  @override
  String get startNoSetupBodyNoLinks =>
      'ایک بار کا سیٹ اپ ابھی نہیں ہوا۔ اس کے بغیر واعية اصل آواز خاموش نہیں کر سکتی: آپ کو موسیقی اور فلٹر شدہ آواز ایک ساتھ سنائی دے گی۔';

  @override
  String protectDelayLongAsk(String value) {
    return 'کیا $value کا انتظار منتخب کریں؟ اب سے فلٹر یا کوئی بھی حفاظت بند کرنے کے لیے $value انتظار ہوگا، اور اس انتظار کو کم کرنے کے لیے بھی۔';
  }

  @override
  String get keepRunningKilled =>
      'Android نے فلٹرنگ کے دوران واعية کو بند کر دیا، اس لیے آواز فلٹر ہونا بند ہو گئی۔';
}
