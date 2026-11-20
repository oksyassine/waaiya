// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'واعية';

  @override
  String get tagline =>
      'سازهای موسیقی را از صدای همهٔ برنامه‌ها حذف می‌کند و گفتار و تلاوت را نگه می‌دارد.';

  @override
  String get onboardTitle => 'خوش آمدید';

  @override
  String get onboardBody =>
      'واعية سازهای موسیقی را از صدای همهٔ برنامه‌های این تلفن حذف می‌کند. گفتار و تلاوت قرآن حفظ می‌شود. فعلاً صدای آواز هم حذف می‌شود.';

  @override
  String get onboardQuestion => 'من';

  @override
  String get genderMan => 'مرد';

  @override
  String get genderWoman => 'زن';

  @override
  String get onboardWhy =>
      'این فقط تعیین می‌کند کدام تنظیمات اختیاری را ببینید. بعداً می‌توانید آن را تغییر دهید.';

  @override
  String get stateOnTitle => 'پالایش روشن است';

  @override
  String get stateOffTitle => 'پالایش خاموش است';

  @override
  String get stateStarting => 'در حال شروع…';

  @override
  String stateOnDetail(int delayMs) {
    return 'سازها از همهٔ برنامه‌ها حذف می‌شوند. تأخیر حدود $delayMs میلی‌ثانیه.';
  }

  @override
  String get stateOffDetail => 'برای شروع، روی دکمه ضربه بزنید.';

  @override
  String get stateModelFailed =>
      'مدل صدا بارگیری نشد، برای همین صدا برای احتیاط قطع شده است.';

  @override
  String get stateCaptureDenied =>
      'برای دریافت صدای برنامه‌های دیگر، مجوز میکروفون لازم است.';

  @override
  String get stateStoppedBySystem =>
      'اندروید پالایش را متوقف کرد. برای شروع دوباره، روی دکمه ضربه بزنید.';

  @override
  String get stateSilencedTitle => 'پالایش متوقف شد';

  @override
  String get stateSilenced =>
      'پالایش متوقف شد: برنامه‌های دیگر بی‌صدا هستند. برای شروع دوباره روی دکمه ضربه بزنید، یا «توقف» را بزنید تا آن‌ها را بدون پالایش بشنوید.';

  @override
  String get releaseSilence => 'توقف: شنیدن برنامه‌ها بدون پالایش';

  @override
  String get powerStartCd => 'شروع پالایش';

  @override
  String get powerStopCd => 'توقف پالایش';

  @override
  String get captureHint =>
      'اندروید برای هم‌رسانی صفحه از شما می‌پرسد. فقط از صدا استفاده می‌شود: چیزی ضبط یا ارسال نمی‌شود.';

  @override
  String get needRecordAudio =>
      'واعية برای دریافت صدای برنامه‌های دیگر به مجوز میکروفون نیاز دارد. هرگز صدای شما را ضبط نمی‌کند.';

  @override
  String get setupBannerTitle => 'یک قدم دیگر';

  @override
  String get setupBannerBody =>
      'بدون راه‌اندازی یک‌بارهٔ زیر، موسیقی و صدای پالایش‌شده را با هم می‌شنوید.';

  @override
  String get step1Title => 'نصب Shizuku';

  @override
  String get step1Body => 'یک برنامهٔ کمکی رایگان از فروشگاه Play.';

  @override
  String get step1Action => 'دریافت Shizuku';

  @override
  String get step2Title => 'اجرای Shizuku';

  @override
  String get step2Body =>
      'برنامهٔ Shizuku از طریق Wi‑Fi با «اشکال‌زدایی بی‌سیم» اندروید اجرا می‌شود. برای دیدن مراحل روی دکمه ضربه بزنید، سپس برگردید.';

  @override
  String get step2Action => 'باز کردن Shizuku';

  @override
  String get step2Update => 'به‌روزرسانی Shizuku';

  @override
  String get step2TooOld =>
      'نسخهٔ Shizuku شما خیلی قدیمی است. آن را از فروشگاه Play به‌روز کنید.';

  @override
  String get step2Denied =>
      'برنامهٔ Shizuku طوری تنظیم شده که همیشه واعية را رد کند. در Shizuku، در فهرست برنامه‌ها به آن اجازه دهید.';

  @override
  String get step3Title => 'اعطای مجوز';

  @override
  String get step3Body => 'یک ضربه، سپس «اجازه دادن» را انتخاب کنید.';

  @override
  String get step3Action => 'اعطای مجوز';

  @override
  String get step3Busy => 'در حال راه‌اندازی…';

  @override
  String get setupDoneRestart =>
      'انجام شد. برای اعمال آن، یک بار پالایش را متوقف و دوباره شروع کنید.';

  @override
  String setupFailed(String details) {
    return 'راه‌اندازی تمام نشد. جزئیات:\n$details';
  }

  @override
  String get shizukuRefused =>
      'مجوز Shizuku رد شد. برای تلاش دوباره، روی دکمه ضربه بزنید.';

  @override
  String get setupSlow =>
      'برنامهٔ Shizuku بیشتر از معمول طول می‌کشد. منتظر بمانید: در برخی تلفن‌ها، دستیار آن بار اول تا یک دقیقه طول می‌کشد تا شروع به کار کند.';

  @override
  String get setupTimeout =>
      'برنامهٔ Shizuku در ۲ دقیقه پاسخ نداد. Shizuku را باز کنید، ببینید که می‌گوید در حال اجراست، سپس دوباره روی دکمه ضربه بزنید. اگر راه‌اندازی بعداً تمام شود، این صفحه خودش به‌روز می‌شود.';

  @override
  String get setupRefusedXiaomi =>
      'این تلفن مجوزها را رد کرد. در شیائومی، ردمی و پوکو، در «گزینه‌های برنامه‌نویسان» گزینهٔ «USB debugging (Security settings)» (اشکال‌زدایی USB، تنظیمات امنیتی) را روشن کنید (از شما می‌خواهد وارد حساب شیائومی شوید)، سپس دوباره امتحان کنید.';

  @override
  String get setupRefusedColoros =>
      'این تلفن مجوزها را رد کرد. در اوپو، وان‌پلاس و ریلمی، در «گزینه‌های برنامه‌نویسان» گزینهٔ «Disable permission monitoring» (غیرفعال کردن نظارت بر مجوزها) را روشن کنید (در جدیدترین نسخه‌ها نامش «Disable system optimization» (غیرفعال کردن بهینه‌سازی سیستم) است و شاید فقط وقتی زبان تلفن انگلیسی است نمایش داده شود). برای پیدا کردنش، در تنظیمات «permission» را جستجو کنید. سپس دوباره امتحان کنید.';

  @override
  String get setupNoteXiaomi =>
      'شیائومی، ردمی و پوکو: اگر اعلان جایی برای تایپ کد ندارد، در تنظیمات اعلان، سبک اعلان را روی «Android» بگذارید، یا کد را با تقسیم صفحه در واعية تایپ کنید.';

  @override
  String get stepDoneCd => 'انجام شد';

  @override
  String stepTodoCd(int step) {
    return 'مرحلهٔ $step';
  }

  @override
  String get computerToggle => 'به‌جای آن از رایانه استفاده کنید';

  @override
  String get computerBody =>
      '‏اشکال‌زدایی USB را روشن کنید، تلفن را وصل کنید و این را اجرا کنید:';

  @override
  String get copy => 'کپی';

  @override
  String get copied => 'کپی شد';

  @override
  String get computerNote =>
      'خط دوم اختیاری است: پرسش هم‌رسانی صفحه را در هر بار شروع حذف می‌کند.';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingSilenceTitle =>
      'بی‌صدا کردن برنامه‌هایی که جلوی پالایش را می‌گیرند';

  @override
  String get settingSilenceBody =>
      'توصیه می‌شود. برخی برنامه‌ها اجازهٔ پالایش صدایشان را نمی‌دهند؛ این گزینه به‌جای عبور موسیقی، آن‌ها را بی‌صدا می‌کند.';

  @override
  String get settingHoldSilenceTitle =>
      'بی‌صدا ماندن برنامه‌ها اگر پالایش خودبه‌خود متوقف شود';

  @override
  String get settingHoldSilenceBody =>
      'توصیه می‌شود. اگر اندروید پالایش را پایان دهد (نه شما)، برنامه‌های دیگر بی‌صدا می‌مانند تا دوباره شروع کنید یا «توقف» را بزنید، به‌جای اینکه موسیقی بدون پالایش پخش شود. به راه‌اندازی یک‌باره نیاز دارد.';

  @override
  String get settingStereoTitle => 'صدای استریو';

  @override
  String get settingStereoBody =>
      'خاموش: مونو، که حدود نصف باتری مصرف می‌کند و در تلفن‌های بیشتری عقب نمی‌ماند. روشن: سمت چپ و راست را جدا نگه می‌دارد. اگر تلفن برای استریو خیلی کند باشد، باز هم خودش به مونو برمی‌گردد.';

  @override
  String get settingSingingTitle => 'بی‌صدا کردن آواز زنان';

  @override
  String get settingSingingBody => 'گفتار و تلاوت زنان حفظ می‌شود.';

  @override
  String get settingSingingNoModel =>
      'این نسخه آشکارساز آواز ندارد، برای همین تا وقتی این گزینه روشن است، همهٔ صداهای انسانی قطع می‌شوند.';

  @override
  String get settingRestart =>
      'برای اعمال تغییرات، پالایش را متوقف و دوباره شروع کنید.';

  @override
  String get settingGenderTitle => 'من';

  @override
  String get change => 'تغییر';

  @override
  String get playerTitle => 'ویدیو با هماهنگی کامل';

  @override
  String get playerBody =>
      'ویدیویی را با واعية هم‌رسانی کنید (یا از «باز کردن با» استفاده کنید) تا آن را پالایش‌شده و بدون تأخیر تماشا کنید.';

  @override
  String get licences => 'مجوزهای متن‌باز';

  @override
  String get licencesIntro =>
      'واعية نرم‌افزاری آزاد تحت مجوز GNU Affero General Public License نسخهٔ ۳ یا بالاتر است. کد منبع: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'مجوز Creative Commons Attribution 4.0 (داده‌های آموزشی): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'متن‌های کامل';

  @override
  String get back => 'بازگشت';

  @override
  String get linkEntryTitle => 'باز کردن پیوند';

  @override
  String get linkEntryBody =>
      'پیوندی از YouTube، TikTok یا Instagram را جای‌گذاری کنید تا آن را بدون موسیقی تماشا یا ذخیره کنید.';

  @override
  String get linkTitle => 'باز کردن پیوند';

  @override
  String get linkHint => 'https://… (YouTube، TikTok، Instagram…)';

  @override
  String get linkFieldLabel => 'پیوند ویدیو یا صدا';

  @override
  String get linkPaste => 'جای‌گذاری';

  @override
  String get linkOpen => 'باز کردن';

  @override
  String get linkResolving => 'در حال باز کردن پیوند…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'تماشا بدون موسیقی';

  @override
  String get linkSave => 'ذخیره بدون موسیقی';

  @override
  String get linkListen => 'گوش دادن بدون موسیقی';

  @override
  String get linkAudioOnly =>
      'هنوز نمی‌توان ویدیوی این پیوند را باز کرد: فقط صدای آن را.';

  @override
  String get linkDownloading => 'در حال بارگیری…';

  @override
  String get linkFiltering => 'در حال حذف موسیقی…';

  @override
  String get linkCancel => 'لغو';

  @override
  String get linkCancelled => 'لغو شد. چیزی ذخیره نشد.';

  @override
  String get linkTimedOut =>
      'اندروید ذخیره را متوقف کرد: این نوع کار را فقط چند ساعت در روز اجازه می‌دهد. چیزی ذخیره نشد؛ واعية را باز کنید و دوباره امتحان کنید.';

  @override
  String get linkExportFailed => 'ذخیرهٔ این مورد ممکن نشد. چیزی ذخیره نشد.';

  @override
  String get linkSaved => 'بدون موسیقی ذخیره شد';

  @override
  String get linkSavedVideo => 'در گالری شما: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'در موسیقی شما: Music › Waaiya';

  @override
  String get linkPlay => 'پخش';

  @override
  String get linkShare => 'هم‌رسانی';

  @override
  String get linkShareNote =>
      'فقط ویدیوهایی را هم‌رسانی کنید که اجازهٔ هم‌رسانی‌شان را دارید.';

  @override
  String get linkLive => 'پخش‌های زنده را نمی‌توان ذخیره کرد.';

  @override
  String get linkBusy =>
      'ویدیوی دیگری در حال ذخیره است. لطفاً صبر کنید تا تمام شود.';

  @override
  String get linkInvalid =>
      'لطفاً یک پیوند وب (که با https:// شروع می‌شود) جای‌گذاری کنید.';

  @override
  String get linkLogin =>
      'این سایت بدون حساب کاربری این ویدیو را نشان نداد. پست‌های عمومی معمولاً باز می‌شوند: چند دقیقهٔ دیگر دوباره امتحان کنید. پست‌های خصوصی را نمی‌توان باز کرد.';

  @override
  String get linkUnsupported => 'این سایت پشتیبانی نمی‌شود.';

  @override
  String get linkPlaylist =>
      'این یک فهرست پخش است. لطفاً یک ویدیو را باز کنید.';

  @override
  String get linkNoFormat =>
      'این ویدیو هنوز در قالبی نیست که واعية بتواند پالایش کند.';

  @override
  String get linkFailed =>
      'این پیوند باز نشد. اتصال خود را بررسی کنید و دوباره امتحان کنید.';

  @override
  String get linkPlayFailed =>
      'پخش این مورد ممکن نشد. چیزی بدون پالایش پخش نشد.';

  @override
  String get linkLimited =>
      'این سایت فعلاً درخواست‌ها را محدود می‌کند. چند دقیقهٔ دیگر دوباره امتحان کنید.';

  @override
  String get blurTitle => 'تاری صفحه';

  @override
  String get blurBody =>
      'افراد و تصاویر روی صفحه را در همهٔ برنامه‌ها، تا وقتی پالایش روشن است، می‌پوشاند. روی خود تلفن اجرا می‌شود؛ چیزی به جایی فرستاده نمی‌شود.';

  @override
  String get blurWomenTitle => 'تار کردن زنان';

  @override
  String get blurWomenBody =>
      'کل بدن. افرادی که برنامه نمی‌تواند به‌روشنی تشخیص دهد مرد هستند هم تار می‌شوند.';

  @override
  String get blurNudityTitle => 'تار کردن تصاویر ناشایست';

  @override
  String get blurNudityBody =>
      'برهنگی و لباس بدن‌نما، از هر کسی: کل صفحه پوشانده می‌شود.';

  @override
  String get blurFailTitle => 'پوشاندن صفحه اگر تاری عقب بماند';

  @override
  String get blurFailBody =>
      'روشن: وقتی تلفن خیلی کند است یا تاری از کار می‌افتد، کل صفحه پوشانده می‌شود. خاموش: صفحه با یک هشدار نمایان می‌ماند.';

  @override
  String get blurSetupShizuku => 'اجازه با Shizuku';

  @override
  String get blurSetupManual => 'اجازه در تنظیمات اندروید';

  @override
  String get blurStatusNeedsSetup =>
      'تاری باید روی برنامه‌های دیگر نمایش داده شود. بهترین راه: با Shizuku اجازه دهید (سرویس دسترس‌پذیری «تاری واعية» را روشن می‌کند، تا لمس‌ها همچنان به برنامهٔ زیرین برسند). یا در تنظیمات اندروید «نمایش روی برنامه‌های دیگر» را مجاز کنید (آنگاه لمس‌ها روی ناحیهٔ تار از دست می‌روند).';

  @override
  String get blurStatusNeedsOverlay =>
      'تاری باید روی برنامه‌های دیگر نمایش داده شود. بهترین راه: Shizuku را اجرا کنید (و در آن به واعية اجازه دهید): آنگاه تاری لایهٔ خودش را می‌کشد که ضربه‌ها از آن عبور می‌کنند. در غیر این صورت، در تنظیمات اندروید «نمایش روی برنامه‌های دیگر» را مجاز کنید؛ آنگاه ضربه روی ناحیهٔ تار به برنامهٔ زیرین نمی‌رسد.';

  @override
  String get blurFailUnavailable =>
      'فعلاً غیرفعال است: پوشش تمام‌صفحه جلوی همهٔ ضربه‌ها را می‌گیرد و ممکن است گیر بیفتید. دستیار واعية یا Shizuku را اجرا کنید (اندروید ۱۲ یا جدیدتر) تا فعال شود: آنگاه پوشش‌ها طوری کشیده می‌شوند که ضربه‌ها از آن‌ها عبور کنند. تا آن زمان، وقتی تاری عقب بماند، صفحه با یک هشدار نمایان می‌ماند.';

  @override
  String get blurFailNeedsA11y =>
      'فعلاً غیرفعال است: پوشش تمام‌صفحه جلوی همهٔ ضربه‌ها را می‌گیرد و ممکن است گیر بیفتید. Shizuku را اجرا کنید (اندروید ۱۲ یا جدیدتر) یا سرویس دسترس‌پذیری «تاری واعية» را روشن کنید («اجازه با Shizuku» در بالا) تا فعال شود. تا آن زمان، صفحه با یک هشدار نمایان می‌ماند.';

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
      'برای اعمال تنظیمات تاری، پالایش را متوقف و دوباره شروع کنید.';

  @override
  String get blurStatusStarting => 'در حال شروع تاری…';

  @override
  String get blurStatusOn => 'تاری روشن است.';

  @override
  String get blurStatusOnVisible =>
      'تاری روشن است، در حالت احتیاط: این تلفن تاری را در ضبط صفحهٔ خودش نشان می‌دهد، برای همین ناحیهٔ تارشده تا تغییر صحنه تار می‌ماند.';

  @override
  String get blurStatusModels =>
      'این نسخه مدل تاری برای گزینهٔ انتخاب‌شده را ندارد.';

  @override
  String get blurStatusFailing => 'تاری فعلاً عقب مانده است.';

  @override
  String get blurStatusNoOverlay =>
      'تاری نمی‌تواند روی برنامه‌های دیگر نمایش داده شود: در بالا اجازه دهید.';

  @override
  String blurStatusNoCapture(String details) {
    return 'تاری نمی‌تواند صفحه را ببیند. جزئیات:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'برنامهٔ Shizuku نتوانست اجازه دهد:\n$details';
  }

  @override
  String get step2Guide => 'چگونه Shizuku را اجرا کنم';

  @override
  String get blurFailOldAndroid =>
      'غیرفعال است: در این نسخهٔ اندروید، پوشش تمام‌صفحه جلوی همهٔ ضربه‌ها را می‌گیرد و ممکن است گیر بیفتید (پوشش‌های Shizuku به اندروید ۱۲ یا جدیدتر نیاز دارند). وقتی تاری عقب بماند، صفحه با یک هشدار نمایان می‌ماند.';

  @override
  String get guideTitle => 'اجرای Shizuku، گام به گام';

  @override
  String get guideOpenDev => 'گزینه‌های برنامه‌نویسان';

  @override
  String get guideOpenShizuku => 'باز کردن Shizuku';

  @override
  String get guideClose => 'بستن';

  @override
  String get guideBody =>
      'به Wi‑Fi و اندروید ۱۱ یا جدیدتر نیاز دارید. جفت کردن فقط یک بار انجام می‌شود؛ پس از راه‌اندازی مجدد تلفن فقط مرحلهٔ ۷ را تکرار می‌کنید.\n\n۱. تلفن را به Wi‑Fi وصل کنید.\n\n۲. «گزینه‌های برنامه‌نویسان» را روشن کنید: تنظیمات › درباره تلفن › «Software information» (اطلاعات نرم‌افزار) › ۷ بار روی «شمارهٔ ساخت» ضربه بزنید. (در تلفن‌های دیگر: تنظیمات › درباره تلفن › شمارهٔ ساخت.)\n\n۳. Shizuku را باز کنید. اگر اجازهٔ نمایش اعلان خواست، اجازه دهید: کد مرتبط‌سازی در یک اعلان Shizuku تایپ می‌شود.\n\n۴. در Shizuku، زیر «Start via Wireless debugging» (شروع از طریق اشکال‌زدایی بی‌سیم)، روی «Pairing» (جفت کردن) ضربه بزنید. در صفحه‌ای که باز می‌شود، روی «Developer options» (گزینه‌های برنامه‌نویسان) ضربه بزنید، «اشکال‌زدایی بی‌سیم» را روشن کنید و با «اجازه دادن» تأیید کنید.\n\n۵. روی خود عبارت «اشکال‌زدایی بی‌سیم» ضربه بزنید (نه روی کلید)، سپس روی «جفت کردن دستگاه با کد مرتبط‌سازی». یک کد ۶ رقمی نمایش داده می‌شود.\n\n۶. آن صفحه را باز نگه دارید و اعلان‌ها را پایین بکشید. وقتی اعلان Shizuku نوشت «Pairing service found» (سرویس جفت کردن پیدا شد)، روی «Enter pairing code» (وارد کردن کد مرتبط‌سازی) ضربه بزنید و کد را تایپ کنید. برنامهٔ Shizuku می‌گوید جفت کردن موفق بود.\n\n۷. به Shizuku برگردید و زیر «Start via Wireless debugging» روی «Start» (شروع) ضربه بزنید. صبر کنید تا بنویسد «Shizuku is running» (Shizuku در حال اجراست).\n\n۸. به واعية برگردید و روی «اعطای مجوز» ضربه بزنید، سپس «اجازه دادن».\n\nپس از راه‌اندازی مجدد تلفن، Shizuku متوقف می‌شود: به Wi‑Fi وصل شوید، اگر «اشکال‌زدایی بی‌سیم» خاموش است دوباره روشنش کنید، Shizuku را باز کنید و روی «Start» ضربه بزنید. جفت کردن دوباره لازم نیست.';

  @override
  String get wsetupRouteTitle => 'راه‌اندازی روی همین تلفن';

  @override
  String get wsetupRouteBody =>
      'چهار مرحلهٔ کوتاه، فقط یک بار. بدون برنامهٔ اضافه و بدون رایانه. واعية هر مرحله را پس از انجام، تیک می‌زند.';

  @override
  String get wizDevTitle => '«گزینه‌های برنامه‌نویسان» را روشن کنید';

  @override
  String get wizDevBody =>
      'در «درباره تلفن»، ۷ بار روی «شمارهٔ ساخت» ضربه بزنید، سپس به اینجا برگردید. اگر آن را پیدا نمی‌کنید، در تنظیمات «شمارهٔ ساخت» را جستجو کنید.';

  @override
  String get wizDevBodySamsung =>
      'در «درباره تلفن» › «Software information» (اطلاعات نرم‌افزار)، ۷ بار روی «شمارهٔ ساخت» ضربه بزنید، سپس به اینجا برگردید.';

  @override
  String get wizDevBodyXiaomi =>
      'در «درباره تلفن»، ۷ بار روی «OS version» (نسخهٔ سیستم‌عامل) ضربه بزنید (در تلفن‌های قدیمی‌تر «MIUI version» (نسخهٔ MIUI)؛ در برخی، زیر «Detailed info and specs» (اطلاعات و مشخصات کامل))، سپس به اینجا برگردید.';

  @override
  String get wizDevBodyColoros =>
      'در «About device» (درباره دستگاه) (یا «درباره تلفن») › «Version» (نسخه)، ۷ بار روی «شمارهٔ ساخت» ضربه بزنید، سپس به اینجا برگردید.';

  @override
  String get wizDevBodyVivo =>
      'در «درباره تلفن»، ۷ بار روی «Software version» (نسخهٔ نرم‌افزار) ضربه بزنید (در برخی تلفن‌ها: «Software information» (اطلاعات نرم‌افزار) › «شمارهٔ ساخت»)، سپس به اینجا برگردید.';

  @override
  String get wizDevBodyHuawei =>
      'در «درباره تلفن»، ۷ بار روی «شمارهٔ ساخت» ضربه بزنید، سپس به اینجا برگردید.';

  @override
  String get wizDevBodyTranssion =>
      'در «My phone» (تلفن من) (یا «درباره تلفن»)، ۷ بار روی «شمارهٔ ساخت» ضربه بزنید، سپس به اینجا برگردید.';

  @override
  String get setupNoteHuawei =>
      'هواوی: بسیاری از تلفن‌های هواوی «اشکال‌زدایی بی‌سیم» ندارند. اگر آن را در «گزینه‌های برنامه‌نویسان» پیدا نمی‌کنید، از رایانه استفاده کنید («روش‌های دیگر» در پایین).';

  @override
  String get wsetupFilterOn =>
      'پالایش روشن است: در این نسخهٔ اندروید، تا وقتی پالایش در حال اجراست نمی‌توان کد را در اعلان تایپ کرد. اول پالایش را متوقف کنید، یا از تقسیم صفحه و «کد را اینجا تایپ کنید» استفاده کنید.';

  @override
  String get wizDevSearch =>
      'نام‌ها ممکن است بسته به زبان تلفن فرق کنند: اگر آن را پیدا نمی‌کنید، از جستجوی بالای تنظیمات استفاده کنید.';

  @override
  String get wizDevAction => 'باز کردن «درباره تلفن»';

  @override
  String get wizWifiTitle => 'به Wi‑Fi وصل شوید';

  @override
  String get wizWifiBody => 'هر شبکهٔ Wi‑Fi کافی است؛ اینترنت لازم نیست.';

  @override
  String get wizWifiAction => 'باز کردن تنظیمات Wi‑Fi';

  @override
  String get wizWdTitle => '«اشکال‌زدایی بی‌سیم» را روشن کنید';

  @override
  String get wizWdBody =>
      'واعية «گزینه‌های برنامه‌نویسان» را در «اشکال‌زدایی بی‌سیم» باز می‌کند. آن را روشن کنید و روی «اجازه دادن» ضربه بزنید.';

  @override
  String get wizWdAction => 'باز کردن گزینه‌های برنامه‌نویسان';

  @override
  String get wizPairTitle => 'کد مرتبط‌سازی را تایپ کنید';

  @override
  String get wizPairBody =>
      'روی خود عبارت «اشکال‌زدایی بی‌سیم» ضربه بزنید، سپس روی «جفت کردن دستگاه با کد مرتبط‌سازی». ۶ رقم را در اعلان واعية تایپ کنید. واعية بقیه را انجام می‌دهد.';

  @override
  String get wizPairBodyPaired =>
      'واعية از قبل با این تلفن جفت شده است: کدی لازم نیست. روی دکمه ضربه بزنید تا واعية خودش کار را تمام کند.';

  @override
  String get wizPairAction => 'ادامه';

  @override
  String get wizAgain => 'اجرای دوبارهٔ راه‌اندازی';

  @override
  String get setupShizukuReadyTitle => 'با Shizuku، که از قبل در حال اجراست';

  @override
  String get setupOtherWaysPlain => 'روش‌های دیگر راه‌اندازی';

  @override
  String get wizSkip => 'رفتن مستقیم به «اشکال‌زدایی بی‌سیم»';

  @override
  String get setupOtherWays => 'روش‌های دیگر: Shizuku یا رایانه';

  @override
  String get wsetupEnterHere => 'کد را اینجا تایپ کنید';

  @override
  String get wsetupCancel => 'لغو';

  @override
  String get wsetupAndroid10 =>
      'اندروید ۱۰ نمی‌تواند راه‌اندازی را به‌تنهایی انجام دهد: به رایانه نیاز دارد، یا مستقیم (در پایین) یا برای یک بار اجرای Shizuku.';

  @override
  String get wsetupShizukuHeading => 'یا با برنامهٔ Shizuku';

  @override
  String get wsetupShizukuNote =>
      'برنامهٔ Shizuku همچنین اجازه می‌دهد لمس‌ها از پوشش‌های صفحه عبور کنند.';

  @override
  String get wsetupChannel => 'راه‌اندازی یک‌باره';

  @override
  String get wsetupNotifTitle => 'راه‌اندازی واعية: در انتظار کد مرتبط‌سازی';

  @override
  String get wsetupFoundTitle => 'صفحهٔ جفت کردن پیدا شد';

  @override
  String get wsetupBusyTitle => 'راه‌اندازی واعية';

  @override
  String get wsetupDoneTitle => 'راه‌اندازی انجام شد';

  @override
  String get wsetupDoneBody =>
      'واعية اکنون می‌تواند صدای اصلی را بی‌صدا کند. می‌توانید «اشکال‌زدایی بی‌سیم» را خاموش کنید.';

  @override
  String get wsetupDoneHelperBody =>
      'انجام شد. این تلفن اجازه نمی‌دهد برنامه‌ها این مجوزها را نگه دارند، برای همین دستیار واعية به‌جای آن صدای اصلی را بی‌صدا می‌کند. دستیار با راه‌اندازی مجدد تلفن و با به‌روزرسانی واعية متوقف می‌شود. وقتی پس از آن واعية را باز کنید، اگر «اشکال‌زدایی بی‌سیم» روشن باشد، خودش دستیار را دوباره اجرا می‌کند؛ اگر نه، دکمه‌ای برای آن نشان می‌دهد.';

  @override
  String get helperMissingTitle => 'دستیار واعية متوقف است';

  @override
  String get helperMissingBody =>
      'این تلفن مجوزهای واعية را نگه نمی‌دارد، برای همین واعية از دستیار خود استفاده می‌کند. دستیار با راه‌اندازی مجدد تلفن و با به‌روزرسانی واعية متوقف می‌شود. به Wi‑Fi وصل شوید، «اشکال‌زدایی بی‌سیم» را در «گزینه‌های برنامه‌نویسان» روشن کنید، سپس روی «اجرای دستیار واعية» ضربه بزنید.';

  @override
  String get helperChannel => 'دستیار واعية';

  @override
  String get helperStarting => 'در حال اجرای دستیار…';

  @override
  String get helperModeNote =>
      'این تلفن اجازه نمی‌دهد برنامه‌ها این مجوزها را نگه دارند: دستیار واعية کار را انجام می‌دهد. با راه‌اندازی مجدد تلفن و با به‌روزرسانی واعية متوقف می‌شود. وقتی پس از آن واعية را باز کنید، اگر «اشکال‌زدایی بی‌سیم» روشن باشد، خودش دستیار را دوباره اجرا می‌کند؛ اگر نه، دکمه‌ای برای آن نشان می‌دهد.';

  @override
  String get helperTipXiaomi =>
      'اختیاری، برای نگه داشتن همیشگی مجوزها (بدون نیاز به دستیار پس از راه‌اندازی مجدد): در «گزینه‌های برنامه‌نویسان» گزینهٔ «USB debugging (Security settings)» (اشکال‌زدایی USB، تنظیمات امنیتی) را روشن کنید (از شما می‌خواهد وارد حساب شیائومی شوید)، سپس راه‌اندازی را دوباره انجام دهید.';

  @override
  String get helperTipColoros =>
      'اختیاری، برای نگه داشتن همیشگی مجوزها (بدون نیاز به دستیار پس از راه‌اندازی مجدد): در «گزینه‌های برنامه‌نویسان» گزینهٔ «Disable permission monitoring» (غیرفعال کردن نظارت بر مجوزها) را روشن کنید (در جدیدترین نسخه‌ها «Disable system optimization» (غیرفعال کردن بهینه‌سازی سیستم)؛ شاید فقط وقتی زبان تلفن انگلیسی است نمایش داده شود)، سپس راه‌اندازی را دوباره انجام دهید.';

  @override
  String get stateOnHelperMissing =>
      'صدای اصلی بی‌صدا نشده است، برای همین موسیقی را همراه با صدای پالایش‌شده می‌شنوید: دستیار واعية متوقف است. به Wi‑Fi وصل شوید، «اشکال‌زدایی بی‌سیم» را روشن کنید، سپس روی «اجرای دستیار واعية» ضربه بزنید.';

  @override
  String get setupRefusedTryWireless =>
      'یا از «راه‌اندازی روی همین تلفن» در همین صفحه استفاده کنید: آنگاه دستیار واعية بدون آن کلید کار می‌کند.';

  @override
  String get helperStartAnywayTitle => 'دستیار واعية متوقف است';

  @override
  String get helperStartAnywayBody =>
      'بدون آن، موسیقی را همراه با صدای پالایش‌شده می‌شنوید. اول دستیار را اجرا کنید («اشکال‌زدایی بی‌سیم» باید روشن باشد)، یا در هر صورت پالایش را شروع کنید.';

  @override
  String get wsetupFailedTitle => 'راه‌اندازی تمام نشد';

  @override
  String get wsetupPairing => 'در حال جفت کردن…';

  @override
  String get wsetupConnecting => 'در حال اتصال و اعطای مجوزها…';

  @override
  String get wsetupNeedWifi =>
      'اول به یک شبکهٔ Wi‑Fi وصل شوید (اینترنت لازم نیست): «اشکال‌زدایی بی‌سیم» فقط با Wi‑Fi کار می‌کند.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'در «گزینه‌های برنامه‌نویسان»، «اشکال‌زدایی بی‌سیم» را روشن کنید، سپس روی نام آن و بعد «جفت کردن دستگاه با کد مرتبط‌سازی» ضربه بزنید.';

  @override
  String get wsetupOpenDialog =>
      'در «اشکال‌زدایی بی‌سیم»، روی «جفت کردن دستگاه با کد مرتبط‌سازی» ضربه بزنید. کد را روی صفحه نگه دارید و اینجا روی «وارد کردن کد» ضربه بزنید.';

  @override
  String get wsetupEnterCodeBody =>
      'روی «وارد کردن کد» ضربه بزنید و کد ۶ رقمی نشان‌داده‌شده در تنظیمات را تایپ کنید.';

  @override
  String get wsetupCodeWaiting =>
      'کد دریافت شد. در انتظار صفحهٔ «جفت کردن دستگاه با کد مرتبط‌سازی»: آن را باز نگه دارید.';

  @override
  String get wsetupWrongCode =>
      'آن کد پذیرفته نشد. ۶ رقم روی صفحه را بررسی کنید و دوباره وارد کنید. اگر صفحهٔ جفت کردن بسته شد، دوباره بازش کنید: کد تغییر می‌کند.';

  @override
  String get wsetupPairingFailed =>
      'جفت کردن انجام نشد. صفحهٔ جفت کردن را ببندید، دوباره «جفت کردن دستگاه با کد مرتبط‌سازی» را باز کنید و کد جدید را وارد کنید.';

  @override
  String get wsetupWaitingConnect =>
      'جفت شد. «اشکال‌زدایی بی‌سیم» را روشن نگه دارید: واعية در حال اتصال است.';

  @override
  String get wsetupNotPaired =>
      'این تلفن دیگر واعية را نمی‌شناسد (جفت‌شدن حذف شده یا منقضی شده است). «جفت کردن دستگاه با کد مرتبط‌سازی» را باز کنید و کد را وارد کنید.';

  @override
  String get wsetupConnectFailed =>
      'اتصال به «اشکال‌زدایی بی‌سیم» ممکن نشد. آن را خاموش و دوباره روشن کنید: واعية خودش دوباره تلاش می‌کند.';

  @override
  String get wsetupGrantFailed =>
      'متصل شد، اما مجوزها هنوز داده نشده‌اند. از Shizuku یا رایانه (در پایین) استفاده کنید.';

  @override
  String get wsetupTimeout =>
      'پس از ۱۰ دقیقه بدون تمام شدن متوقف شد. می‌توانید دوباره امتحان کنید.';

  @override
  String get wsetupCodeUnreadable => '۶ رقم کد مرتبط‌سازی را تایپ کنید.';

  @override
  String get wsetupCodeHint => 'کد ۶ رقمی';

  @override
  String get wsetupEnterCode => 'وارد کردن کد';

  @override
  String wsetupDetail(String details) {
    return 'جزئیات: $details';
  }

  @override
  String get wsetupErrTimeout => 'پاسخی به‌موقع نیامد';

  @override
  String get wsetupErrRefused => 'اتصال رد شد';

  @override
  String get wsetupDevOff =>
      '«گزینه‌های برنامه‌نویسان» خاموش است. در «درباره تلفن»، ۷ بار روی «شمارهٔ ساخت» ضربه بزنید، سپس برگردید.';

  @override
  String get wsetupOpenAbout => 'درباره تلفن';

  @override
  String get wsetupNotifOff =>
      'اعلان‌های واعية خاموش است، برای همین نمی‌توان کد را در اعلان تایپ کرد. از تقسیم صفحه استفاده کنید (تنظیمات در یک نیمه، واعية در نیمهٔ دیگر) و روی «کد را اینجا تایپ کنید» ضربه بزنید.';

  @override
  String get wsetupCodeDialogTitle => 'کد مرتبط‌سازی';

  @override
  String get wsetupCodeDialogBody =>
      'فقط با تقسیم صفحه (تنظیمات در یک نیمه، واعية در نیمهٔ دیگر): بیرون رفتن از تنظیمات صفحهٔ جفت کردن را می‌بندد و کد آن دیگر کار نمی‌کند. کد ۶ رقمی نشان‌داده‌شده زیر «جفت کردن دستگاه با کد مرتبط‌سازی» را تایپ کنید.';

  @override
  String get wsetupCodeOk => 'جفت کردن';

  @override
  String get blurStrictTitle => 'چه کسانی بی‌پوشش می‌مانند';

  @override
  String blurStrictValue(String level) {
    return 'چه کسانی بی‌پوشش می‌مانند: $level';
  }

  @override
  String get blurStrict0 =>
      'سخت‌گیرانه: فقط کسانی که برنامه تقریباً مطمئن است مرد هستند';

  @override
  String get blurStrict1 => 'متعادل: حدود دو برابر مرد بیشتر بی‌پوشش می‌مانند';

  @override
  String get blurStrict2 => 'آسان‌گیرانه: کمی مرد بیشتر از حالت متعادل';

  @override
  String get blurStrict0Short => 'سخت‌گیرانه';

  @override
  String get blurStrict1Short => 'متعادل';

  @override
  String get blurStrict2Short => 'آسان‌گیرانه';

  @override
  String get blurStrictHelp =>
      'هر کسی که برنامه مطمئن نیست مرد است، پوشانده می‌شود. حالت سخت‌گیرانه حدود ۷ مرد از هر ۱۰۰ را بی‌پوشش می‌گذارد؛ متعادل حدود ۱۴ و آسان‌گیرانه حدود ۱۶. هر مرحله که سخت‌گیری کمتر شود، حدود ۱ زن بیشتر از هر ۱۰۰ نیز بی‌پوشش می‌ماند.';

  @override
  String get stateOnNotMuted =>
      'صدای اصلی هنوز بی‌صدا نشده است، برای همین موسیقی را همراه با صدای پالایش‌شده می‌شنوید. راه‌اندازی یک‌بارهٔ زیر را تمام کنید.';

  @override
  String get stateOnMuteFailing =>
      'واعية نمی‌تواند صدای اصلی برنامه‌ای را که اکنون پخش می‌کند بی‌صدا کند، برای همین ممکن است موسیقی همچنان شنیده شود. پالایش را متوقف و دوباره شروع کنید. اگر ادامه داشت، گزارش عیب‌یابی را بفرستید (پایین همین صفحه).';

  @override
  String get stateTooSlow =>
      'این تلفن برای پالایش زندهٔ صدا خیلی کند است، برای همین صدا قطع‌ووصل می‌شود. «باز کردن پیوند» در پایین همچنان کار می‌کند: ویدیو را پیش از پخش پالایش می‌کند.';

  @override
  String get stateMonoNote => 'صدا مونو است تا این تلفن عقب نماند.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'بی‌صدا شد، چون اجازهٔ پالایش نمی‌دهد: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'بدون پالایش پخش می‌شود، چون اجازهٔ پالایش نمی‌دهد: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'اندروید صدای برنامه‌های دیگر را به واعية نداد. برای شروع دوباره، روی دکمه ضربه بزنید.';

  @override
  String get stateCaptureCancelled =>
      'شروع در پرسش هم‌رسانی صفحهٔ اندروید لغو شد. واعية برای دریافت صدا نیاز دارد آنجا «شروع» را بزنید. چیزی ضبط یا ارسال نمی‌شود.';

  @override
  String get startNoSetupTitle => 'موسیقی همچنان شنیده می‌شود';

  @override
  String get startNoSetupBody =>
      'راه‌اندازی یک‌باره هنوز انجام نشده است. بدون آن، واعية نمی‌تواند صدای اصلی را بی‌صدا کند: موسیقی و صدای پالایش‌شده را با هم می‌شنوید.\n\n«باز کردن پیوند» بدون هیچ راه‌اندازی‌ای کار می‌کند.';

  @override
  String get startNoSetupSetup => 'انجام راه‌اندازی';

  @override
  String get startNoSetupAnyway => 'شروع در هر صورت';

  @override
  String get diagButton => 'مشکلی هست؟ گزارش عیب‌یابی';

  @override
  String get diagTitle => 'گزارش عیب‌یابی';

  @override
  String get diagNote =>
      'آنچه واعية روی این تلفن می‌بیند. آن را کپی کنید یا با کسی که به شما کمک می‌کند هم‌رسانی کنید. خود برنامه چیزی نمی‌فرستد.';

  @override
  String get notifStoppedTitle => 'واعية متوقف شد';

  @override
  String get notifStoppedText =>
      'صدا دیگر پالایش نمی‌شود. برای شروع دوباره ضربه بزنید.';

  @override
  String get wsetupGuide => 'مراحل با تصویر';

  @override
  String get navFilter => 'پالایش';

  @override
  String get navScreen => 'صفحه';

  @override
  String get navLinks => 'پیوندها';

  @override
  String get navSetup => 'راه‌اندازی';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get setupDoneTitle => 'راه‌اندازی انجام شد';

  @override
  String get setupDoneBody =>
      'واعية می‌تواند صدای اصلی برنامه‌های دیگر را بی‌صدا کند. فقط اگر چیزی تغییر کرد دوباره انجامش دهید (راه‌اندازی لغو شد، یا واعية گفت که انجام نشده است).';

  @override
  String get setupRedo => 'نمایش دوبارهٔ راه‌اندازی';

  @override
  String get setupGo => 'رفتن به راه‌اندازی';

  @override
  String get helperTitle => 'عبور لمس از پوشش‌ها';

  @override
  String get helperBodyOff =>
      'بدون کمک، پوشش جلوی لمس‌های زیر خودش را می‌گیرد. دستیار واعية پوشش‌ها را طوری می‌کشد که لمس‌ها از آن‌ها عبور کنند. «اشکال‌زدایی بی‌سیم» را روشن کنید (Wi‑Fi لازم است) و روی دکمه ضربه بزنید؛ بار اول، مانند راه‌اندازی یک بار جفت کنید. پس از راه‌اندازی مجدد تلفن، دوباره روی آن ضربه بزنید.';

  @override
  String get helperStart => 'اجرای دستیار واعية';

  @override
  String get helperOn =>
      'دستیار واعية پوشش‌ها را می‌کشد: لمس‌ها از آن‌ها عبور می‌کنند. با راه‌اندازی مجدد تلفن یا خاموش شدن ‏اشکال‌زدایی USB متوقف می‌شود؛ آنگاه دوباره روی دکمه ضربه بزنید.';

  @override
  String get helperShizukuOn =>
      'برنامهٔ Shizuku پوشش‌ها را می‌کشد: لمس‌ها از آن‌ها عبور می‌کنند.';

  @override
  String get helperOrShizuku => 'یا با Shizuku:';

  @override
  String get filterOptionsTitle => 'گزینه‌های پالایش';

  @override
  String get settingsGeneralTitle => 'عمومی';

  @override
  String get worshipPrayerFajr => 'صبح';

  @override
  String get worshipPrayerSunrise => 'طلوع آفتاب';

  @override
  String get worshipPrayerDhuhr => 'ظهر';

  @override
  String get worshipPrayerAsr => 'عصر';

  @override
  String get worshipPrayerMaghrib => 'مغرب';

  @override
  String get worshipPrayerIsha => 'عشا';

  @override
  String get worshipEndSilent => 'پایان بی‌صدایی';

  @override
  String get worshipUnmute => 'الان صدا را برگردان';

  @override
  String get worshipSmsDefault =>
      'وقت نماز است، الان نمی‌توانم جواب بدهم. بعداً با شما تماس می‌گیرم.';

  @override
  String get desktopPreview =>
      'پیش‌نمایش: موتور پالایش هنوز روی این رایانه وصل نشده است. این دکمه فقط نشان می‌دهد برنامه چگونه کار خواهد کرد.';

  @override
  String actionFailed(String details) {
    return 'انجام نشد: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'سازها از همهٔ برنامه‌ها حذف می‌شوند.';

  @override
  String get engineErrorNoPactl =>
      'ابزارهای صدا (pactl) پیدا نشد. واعية به PulseAudio، یا PipeWire همراه با pipewire-pulse نیاز دارد.';

  @override
  String get engineErrorNoSoundServer =>
      'سرور صدا (PulseAudio یا PipeWire) در حال اجرا نیست.';

  @override
  String get engineErrorNoSystemd =>
      'این سیستم نشست کاربری systemd ندارد؛ همان چیزی که پالایشگر را در پس‌زمینه اجرا می‌کند.';

  @override
  String get engineErrorNoOutput => 'هیچ بلندگو یا هدفونی پیدا نشد.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'نصب پالایشگر ممکن نشد. جزئیات:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'پالایشگر شروع به کار نکرد. جزئیات:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'پالایشگر با خطا متوقف شد. جزئیات:\n$details';
  }

  @override
  String get autostartTitle => 'شروع هنگام ورود';

  @override
  String get autostartBody => 'صدا به‌محض ورود شما به سیستم پالایش می‌شود.';

  @override
  String get blurBodyDesktop =>
      'افراد و تصاویر روی صفحه را، روی همهٔ پنجره‌ها، تا وقتی واعية باز است می‌پوشاند (چه پالایش صدا روشن باشد چه خاموش). روی همین رایانه اجرا می‌شود؛ چیزی به جایی فرستاده نمی‌شود. بستن پنجرهٔ واعية تاری را متوقف می‌کند.';

  @override
  String get blurFailBodyDesktop =>
      'روشن: وقتی رایانه خیلی کند است یا تاری از کار می‌افتد، کل صفحه پوشانده می‌شود؛ کلیک‌ها همچنان به پنجره‌های زیرین می‌رسند. خاموش: صفحه با یک نوار قرمز در بالا نمایان می‌ماند.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'تاری روشن است. این میز کار تاری را در ضبط صفحهٔ خودش نشان می‌دهد، برای همین ناحیهٔ تارشده تا تغییر صحنه تار می‌ماند.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'تاری نمی‌تواند در این میز کار روی پنجره‌های دیگر نمایش داده شود. جزئیات:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'در پنجرهٔ هم‌رسانی صفحه، صفحهٔ خود را انتخاب کنید و اجازه دهید. واعية فقط یک بار می‌پرسد؛ تصویر روی همین رایانه می‌ماند.';

  @override
  String blurStatusExited(String details) {
    return 'تاری به‌طور غیرمنتظره متوقف شد. برای تلاش دوباره، یکی از گزینه‌های تاری را خاموش و دوباره روشن کنید. جزئیات:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'آشکارساز آواز زنان بارگیری نشد، برای همین تا وقتی آن گزینه روشن است، صداهای انسانی قطع می‌شوند.';

  @override
  String get blurStatusUncovered =>
      'یک نمایشگر زیر پوشش تاری نیست: یا با آن هم‌رسانی نشده، یا بعداً وصل شده است. یکی از گزینه‌های تاری را خاموش و دوباره روشن کنید و در پنجرهٔ هم‌رسانی صفحه همهٔ صفحه‌ها را انتخاب کنید.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'مدل‌های تاری در این نصب وجود ندارند، برای همین چیزی را نمی‌پوشاند؛ یک نوار قرمز در بالای صفحه می‌ماند. واعية را دوباره نصب کنید.';

  @override
  String get diagNoteDesktop =>
      'آنچه واعية روی این رایانه می‌بیند. آن را کپی کنید و به کسی که به شما کمک می‌کند بدهید. خود برنامه چیزی نمی‌فرستد.';

  @override
  String get singingKeepTitle => 'نگه داشتن صدای آواز (آزمایشی)';

  @override
  String get singingKeepBody =>
      'سازها حذف می‌شوند ولی صدای آواز می‌ماند، پس سخنرانی‌ای که زیرش نشید پخش می‌شود صدای نشید را هم نگه می‌دارد؛ پذیرفتنی بودن آن به انتخاب شماست.';

  @override
  String get singingKeepNoModel =>
      'این نسخه مدل آواز را ندارد، پس تا وقتی این گزینه روشن است صدا خاموش می‌ماند. آن را خاموش کنید.';

  @override
  String get fixFilterAppsTitle => 'برنامه‌هایی که بدون فیلتر شنیده می‌شوند';

  @override
  String get fixFilterAppsBody =>
      'این برنامه‌ها صدای اصلی خود را پخش می‌کنند: واعیه نه آن‌ها را فیلتر می‌کند و نه بی‌صدا.';

  @override
  String get fixAddApp => 'افزودن برنامه';

  @override
  String fixRemoveApp(Object app) {
    return 'حذف $app';
  }

  @override
  String get fixNoApps => 'هیچ برنامه‌ای انتخاب نشده.';

  @override
  String get fixPickTitle => 'یک برنامه انتخاب کنید';

  @override
  String get fixPickEmpty => 'برنامهٔ دیگری پیدا نشد.';

  @override
  String get fixPickPlayingDesktop =>
      'برنامه‌هایی که اکنون صدا پخش می‌کنند، و آن‌هایی که از قبل انتخاب شده‌اند.';

  @override
  String get fixCancel => 'لغو';

  @override
  String get fixBlurAppsTitle => 'برنامه‌های بدون محوسازی';

  @override
  String get fixBlurAppsBody =>
      'تا وقتی یکی از این برنامه‌ها به‌تنهایی روی صفحه است، پوششی نیست. به‌محض ترک آن، یا هر وقت واعیه مطمئن نباشد کدام برنامه نمایش داده می‌شود، پوشش‌ها برمی‌گردند.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'به راه‌اندازی یک‌باره نیاز دارد: بدون آن واعیه نمی‌داند کدام برنامه روی صفحه است، پس محوسازی همه‌جا می‌ماند.';

  @override
  String get fixBlurAppsHelperMode =>
      'هنوز روی این گوشی در دسترس نیست: راه‌اندازی آن از طریق دستیار واعیه انجام می‌شود که نمی‌داند کدام برنامه روی صفحه است. محوسازی همه‌جا می‌ماند.';

  @override
  String get fixHandTitle => 'پوشاندن یک بخش با دست';

  @override
  String get fixHandBody =>
      'هنگام کار محوسازی، انگشت خود را روی هر بخشی از صفحه بکشید تا پوشانده شود. تا وقتی آن را بردارید یا محوسازی متوقف شود پوشیده می‌ماند.';

  @override
  String get fixHandNotRunning =>
      'هنگام کار محوسازی در دسترس است: فیلتر روشن و یکی از گزینه‌های محوسازی روشن.';

  @override
  String get fixCoverArea => 'پوشاندن یک بخش';

  @override
  String fixRemoveCovers(Object count) {
    return 'برداشتن پوشش‌های دستی ($count)';
  }

  @override
  String get fixNoteTitle => 'ثبت یک اشتباه';

  @override
  String get fixNoteBody =>
      'همان لحظه علامت بزنید. یادداشت زمان، برنامه و تنظیمات را نگه می‌دارد. روی همین دستگاه می‌ماند و هرگز فرستاده نمی‌شود.';

  @override
  String get fixMissedSound => 'موسیقی رد شد';

  @override
  String get fixWrongSound => 'صدا به‌اشتباه حذف شد';

  @override
  String get fixMissedScreen => 'چیزی پوشانده نشد';

  @override
  String get fixWrongScreen => 'به‌اشتباه پوشانده شد';

  @override
  String fixNoted(Object count) {
    return 'ثبت شد ($count یادداشت روی این دستگاه).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'یادداشت‌های روی این دستگاه: $count';
  }

  @override
  String get fixNotesShow => 'نمایش یادداشت‌ها';

  @override
  String get fixNotesDelete => 'حذف یادداشت‌ها';

  @override
  String get fixNotesDeleteAsk =>
      'همهٔ یادداشت‌ها حذف شوند؟ این کار برگشت‌پذیر نیست.';

  @override
  String get fixNotesTitle => 'یادداشت‌های تشخیص اشتباه';

  @override
  String get worshipTitle => 'اوقات نماز';

  @override
  String get worshipBody =>
      'اختیاری. روی همین گوشی از روی مکانی که انتخاب می‌کنید حساب می‌شود. چیزی فرستاده نمی‌شود.';

  @override
  String worshipPlace(Object place) {
    return 'مکان: $place';
  }

  @override
  String get worshipPlaceNone => 'مکان: انتخاب نشده';

  @override
  String get worshipChoose => 'انتخاب';

  @override
  String get worshipPlaceSearch => 'جستجوی شهر';

  @override
  String get worshipPlaceNoMatch =>
      'شهری پیدا نشد. می‌توانید به جای آن مختصات را وارد کنید.';

  @override
  String get worshipPlaceCustom => 'وارد کردن مختصات';

  @override
  String get worshipLat => 'عرض جغرافیایی (شمال +، جنوب −)';

  @override
  String get worshipLon => 'طول جغرافیایی (شرق +، غرب −)';

  @override
  String get worshipZone => 'منطقه زمانی، مثلاً Asia/Tehran';

  @override
  String get worshipCustomInvalid => 'عددها و منطقه زمانی را بررسی کنید.';

  @override
  String get worshipPlaceInvalid =>
      'این مکان قابل استفاده نیست. دوباره انتخابش کنید.';

  @override
  String worshipMethod(Object method) {
    return 'روش محاسبه: $method';
  }

  @override
  String get worshipMethodTitle => 'روش محاسبه';

  @override
  String get worshipMethodNote =>
      'بر اساس کشور شهر انتخاب شد. روشی را که مسجدتان پیروی می‌کند انتخاب کنید.';

  @override
  String worshipAsr(Object rule) {
    return 'عصر: $rule';
  }

  @override
  String get worshipAsrTitle => 'وقت عصر';

  @override
  String get worshipAsrStandard => 'رایج (شافعی، مالکی، حنبلی)';

  @override
  String get worshipAsrHanafi => 'حنفی';

  @override
  String get worshipMethodMwl => 'رابطه جهان اسلام';

  @override
  String get worshipMethodIsna => 'انجمن اسلامی آمریکای شمالی (ISNA)';

  @override
  String get worshipMethodEgypt => 'سازمان عمومی نقشه‌برداری مصر';

  @override
  String get worshipMethodUmmAlQura => 'ام‌القری، مکه';

  @override
  String get worshipMethodKarachi => 'دانشگاه علوم اسلامی کراچی';

  @override
  String get worshipMethodTehran => 'مؤسسه ژئوفیزیک دانشگاه تهران';

  @override
  String get worshipMethodGulf => 'منطقه خلیج';

  @override
  String get worshipMethodKuwait => 'کویت';

  @override
  String get worshipMethodQatar => 'قطر';

  @override
  String get worshipMethodSingapore => 'سنگاپور (MUIS)';

  @override
  String get worshipMethodTurkey => 'ترکیه (دیانت)';

  @override
  String get worshipMethodFrance => 'فرانسه (UOIF، ۱۲°)';

  @override
  String get worshipMethodMorocco => 'مراکش (وزارت اوقاف)';

  @override
  String get worshipMethodIndonesia => 'اندونزی (وزارت امور دینی)';

  @override
  String get worshipMethodMalaysia => 'مالزی (JAKIM)';

  @override
  String get worshipMethodDubai => 'دبی';

  @override
  String get worshipToday => 'امروز';

  @override
  String get worshipNoTimes =>
      'امروز اینجا وقت نماز نیست: خورشید طلوع یا غروب نمی‌کند.';

  @override
  String get worshipSilentTitle => 'بی‌صدا در وقت نماز';

  @override
  String get worshipSilentBody =>
      'از وقت هر نماز، «مزاحم نشوید» به مدت زیر روشن می‌شود و بعد به حالت قبل برمی‌گردد.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'مدت بی‌صدا: $minutes دقیقه';
  }

  @override
  String get worshipMuteTitle => 'بی‌صدا کردن رسانه هنگام اذان';

  @override
  String get worshipMuteBody =>
      'در وقت هر نماز، صدای رسانه (ویدیو، صوت، بازی) به مدت زیر قطع می‌شود. از اعلان می‌توانید فوراً صدا را برگردانید.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'مدت قطع صدا: $minutes دقیقه';
  }

  @override
  String get worshipMinutesTitle => 'مدت';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes دقیقه';
  }

  @override
  String get worshipNeedPlace => 'اول مکان را انتخاب کنید.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'بعدی: $prayer ساعت $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'بی‌صدا تا $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'رسانه تا $time بی‌صداست.';
  }

  @override
  String get worshipDndNeeded =>
      'به واعية اجازه دهید «مزاحم نشوید» را تغییر دهد، وگرنه گوشی بی‌صدا نمی‌شود.';

  @override
  String get worshipAllow => 'اجازه دادن';

  @override
  String get worshipExactNeeded =>
      '«هشدارها و یادآوری‌ها» برای واعية مجاز نیست، پس هر تغییر ممکن است تا ۱۰ دقیقه، یا وقتی گوشی در خواب است بیشتر، دیر انجام شود.';

  @override
  String get worshipNotificationsNeeded =>
      'اعلان‌ها خاموش است: نمی‌بینید گوشی کی بی‌صدا می‌شود یا برمی‌گردد.';

  @override
  String get worshipTonesTitle => 'زنگ و صدای اعلان ساده';

  @override
  String get worshipTonesBody =>
      'واعية نمی‌تواند زنگ و صدای اعلان‌ها را فیلتر کند، فقط می‌تواند آن‌ها را عوض کند. یک صدای ساده بدون موسیقی انتخاب کنید:';

  @override
  String worshipToneRing(Object number) {
    return 'زنگ ساده $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'صدای اعلان ساده $number';
  }

  @override
  String get worshipTonePlay => 'پخش';

  @override
  String get worshipToneSet => 'استفاده';

  @override
  String get worshipToneInUse => 'در حال استفاده';

  @override
  String get worshipToneDone => 'انجام شد.';

  @override
  String get worshipTonePermission =>
      'به واعية اجازه تغییر تنظیمات سیستم را بدهید، برگردید و دوباره بزنید.';

  @override
  String get worshipToneFailed =>
      'این گوشی اجازه تغییر به واعية نداد. در تنظیمات صدا، صدایی به نام «Waaiya plain» را انتخاب کنید.';

  @override
  String get worshipOpenSound => 'باز کردن تنظیمات صدا';

  @override
  String get worshipSmsTitle => 'پاسخ پیامکی به تماس‌ها هنگام نماز';

  @override
  String get worshipSmsBody =>
      'در دقیقه‌های بی‌صدای بعد از وقت هر نماز، به تماسی که بی‌پاسخ زنگ می‌خورد یک پیامک فرستاده می‌شود. برای هر شماره در هر نماز یک بار؛ هرگز به شماره‌های پنهان یا کوتاه.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'پس از: $seconds ثانیه زنگ';
  }

  @override
  String get worshipSmsDelayTitle => 'ثانیه‌های زنگ پیش از پیامک';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds ثانیه';
  }

  @override
  String worshipSmsText(Object text) {
    return 'پیام: $text';
  }

  @override
  String get worshipSmsTextTitle => 'پیام شما';

  @override
  String get worshipSmsTextDefault => 'پیام پیش‌فرض';

  @override
  String get worshipSmsCost =>
      'هر پاسخ یک پیامک معمولی از سیم‌کارت شماست، با هزینه طرح شما. هنگام رومینگ چیزی فرستاده نمی‌شود.';

  @override
  String get worshipSmsRoaming =>
      'اکنون در رومینگ هستید: پیامکی فرستاده نمی‌شود.';

  @override
  String get worshipSmsLogTitle => 'پاسخ‌های فرستاده‌شده (فقط روی همین گوشی)';

  @override
  String get worshipContinue => 'ادامه';

  @override
  String get worshipWhyDnd =>
      'برای بی‌صدا کردن گوشی در وقت نماز، در صفحه بعد به واعية دسترسی «مزاحم نشوید» بدهید.';

  @override
  String get worshipWhyExact =>
      'برای انجام کار درست سر وقت، در صفحه بعد به واعية اجازه تنظیم هشدارها و یادآوری‌ها بدهید. بدون آن ممکن است تغییرات تا ۱۰ دقیقه دیر شوند.';

  @override
  String get worshipWhyNotifications =>
      'اعلان‌ها را مجاز کنید تا هر تغییر را ببینید و بتوانید آن را برگردانید.';

  @override
  String get worshipWhyWrite =>
      'برای عوض کردن زنگ یا صدای اعلان، در صفحه بعد به واعية اجازه تغییر تنظیمات سیستم بدهید.';

  @override
  String get worshipWhyPhone =>
      'برای اینکه بداند تماسی زنگ می‌خورد و شماره‌اش چیست، واعية به اجازه‌های «تلفن» و «گزارش تماس» نیاز دارد. جز پاسخ شما چیزی از گوشی بیرون نمی‌رود.';

  @override
  String get worshipWhySms =>
      'برای فرستادن پاسخ شما، واعية به اجازه ارسال پیامک نیاز دارد. فقط همین پاسخ را می‌فرستد، حداکثر یک بار برای هر شماره در هر نماز.';

  @override
  String get worshipMissingDnd =>
      'دسترسی «مزاحم نشوید» داده نشد، پس بی‌صدایی خاموش می‌ماند.';

  @override
  String get worshipMissingPhone =>
      'اجازه‌های «تلفن» و «گزارش تماس» داده نشد، پس پاسخ پیامکی خاموش می‌ماند.';

  @override
  String get worshipMissingSms =>
      'اجازه ارسال پیامک داده نشد، پس پاسخ پیامکی خاموش می‌ماند.';

  @override
  String get worshipTryAgain => 'دوباره امتحان کنید';

  @override
  String get protectTitle => 'محافظت برای لحظه‌های ضعف';

  @override
  String get protectBody =>
      'همین حالا که آرامید تصمیم بگیرید: هر تغییری که محافظت را کم کند پیش از اعمال شدن صبر می‌کند. والدین می‌توانند رمز هم بگذارند.';

  @override
  String protectDelay(Object value) {
    return 'مدت انتظار: $value';
  }

  @override
  String get protectDelayTitle => 'مدت انتظار';

  @override
  String get protectDelayBody =>
      'توقف فیلتر، خاموش کردن پوشش یا هر چیزی که محافظت را کم کند این مدت صبر می‌کند. سپس آن را ظرف ۱۵ دقیقه تأیید می‌کنید، وگرنه چیزی تغییر نمی‌کند. روشن کردن همیشه فوراً اعمال می‌شود.';

  @override
  String get protectDelayOff => 'بدون انتظار';

  @override
  String get protectDelay1m => '۱ دقیقه';

  @override
  String get protectDelay5m => '۵ دقیقه';

  @override
  String get protectDelay15m => '۱۵ دقیقه';

  @override
  String get protectDelay30m => '۳۰ دقیقه';

  @override
  String get protectDelay1h => '۱ ساعت';

  @override
  String get protectDelay4h => '۴ ساعت';

  @override
  String get protectDelay24h => '۲۴ ساعت';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes دقیقه';
  }

  @override
  String get protectPinNone => 'رمز: گذاشته نشده';

  @override
  String get protectPinIsSet => 'رمز: گذاشته شده';

  @override
  String get protectPinSet => 'گذاشتن رمز';

  @override
  String get protectPinRemove => 'حذف';

  @override
  String get protectPinBody =>
      'با رمز، هر تغییری که محافظت را کم کند اول رمز را می‌خواهد. تغییر مدت انتظار یا خود رمز هم آن را می‌خواهد.';

  @override
  String get protectPinForgot =>
      'اگر رمز فراموش شود، راه بازنشانی نیست: فقط پاک کردن داده‌های واعية یا نصب دوباره، که همهٔ تنظیماتش را هم پاک می‌کند.';

  @override
  String get protectPinTitle => 'رمز را وارد کنید';

  @override
  String get protectPinNewTitle => 'یک رمز انتخاب کنید';

  @override
  String get protectPinChangeTitle => 'تغییر رمز';

  @override
  String get protectPinCurrent => 'رمز فعلی';

  @override
  String get protectPinNew => 'رمز جدید (۴ تا ۸ رقم)';

  @override
  String get protectPinAgain => 'رمز جدید دوباره';

  @override
  String get protectPinBad => 'از ۴ تا ۸ رقم استفاده کنید.';

  @override
  String get protectPinDiffer => 'دو رمز جدید یکی نیستند.';

  @override
  String protectPinWrong(Object count) {
    return 'رمز اشتباه. $count تلاش تا یک مکث باقی مانده.';
  }

  @override
  String protectLocked(Object time) {
    return 'تلاش‌های اشتباه زیاد. ساعت $time دوباره امتحان کنید.';
  }

  @override
  String get protectOk => 'باشه';

  @override
  String get protectCancel => 'لغو';

  @override
  String get protectCancelChange => 'لغو تغییر';

  @override
  String get protectConfirm => 'تأیید';

  @override
  String protectPending(Object time, Object what) {
    return '$what: ساعت $time اعمال می‌شود.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: انتظار تمام شد. هنوز می‌خواهید؟ پیش از $time تأیید کنید، وگرنه چیزی تغییر نمی‌کند.';
  }

  @override
  String get protectWaitTitle => 'این تغییر منتظر است';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what ساعت $time اعمال می‌شود، اگر آن موقع هنوز بخواهید. سپس ظرف ۱۵ دقیقه همین‌جا تأییدش می‌کنید.';
  }

  @override
  String get protectWaitStart => 'شروع انتظار';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'از قبل در انتظار است: ساعت $time اعمال می‌شود.';
  }

  @override
  String protectStarted(Object time) {
    return 'ساعت $time اعمال می‌شود. آن موقع تأییدش کنید.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'فردا ساعت $time';
  }

  @override
  String get protectHeldBack => 'تنظیمات محافظت این تغییر را نگه داشته است.';

  @override
  String get protectLimits =>
      'آنچه این نمی‌تواند جلویش را بگیرد: توقف اجباری، حذف برنامه، پاک کردن داده‌های واعية و تنظیمات خود اندروید. جلوگیری از این‌ها اختیارات مدیر دستگاه یا دسترس‌پذیری می‌خواهد که واعية از آن‌ها استفاده نمی‌کند. این از لحظهٔ ضعف محافظت می‌کند، نه از کسی که مصمم است.';

  @override
  String get protectLimitsDesktop =>
      'آنچه این نمی‌تواند جلویش را بگیرد: فرمان waaiya در ترمینال، حذف واعية یا پاک کردن پوشهٔ تنظیماتش. این از لحظهٔ ضعف محافظت می‌کند، نه از کسی که مصمم است.';

  @override
  String get protectWhatStop => 'توقف فیلتر';

  @override
  String protectWhatOff(Object name) {
    return 'خاموش کردن: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'روشن کردن: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'افزودن برنامه به: $name';
  }

  @override
  String get protectWhatStrictness => 'کم‌سخت‌گیرتر کردن تار کردن';

  @override
  String get protectWhatGender => 'تغییر کسی که از گوشی استفاده می‌کند';

  @override
  String protectWhatDelay(Object value) {
    return 'تغییر مدت انتظار به: $value';
  }

  @override
  String get protectWhatPinChange => 'تغییر رمز';

  @override
  String get protectWhatPinClear => 'حذف رمز';

  @override
  String get protectWhatSetting => 'تغییر یک تنظیم';
}
