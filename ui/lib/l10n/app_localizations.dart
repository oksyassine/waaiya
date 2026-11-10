import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Android string app_name
  ///
  /// In ar, this message translates to:
  /// **'واعية'**
  String get appName;

  /// Android string tagline
  ///
  /// In ar, this message translates to:
  /// **'يزيل الآلات الموسيقية من صوت كل التطبيقات، ويُبقي الكلام والتلاوة.'**
  String get tagline;

  /// Android string onboard_title
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك'**
  String get onboardTitle;

  /// Android string onboard_body
  ///
  /// In ar, this message translates to:
  /// **'تزيل واعية الآلات الموسيقية من صوت كل تطبيقات هذا الهاتف، وتُبقي الكلام وتلاوة القرآن. وتُزال أصوات الغناء أيضًا في الوقت الحالي.'**
  String get onboardBody;

  /// Android string onboard_question
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get onboardQuestion;

  /// Android string gender_man
  ///
  /// In ar, this message translates to:
  /// **'رجل'**
  String get genderMan;

  /// Android string gender_woman
  ///
  /// In ar, this message translates to:
  /// **'امرأة'**
  String get genderWoman;

  /// Android string onboard_why
  ///
  /// In ar, this message translates to:
  /// **'هذا يحدد فقط الخيارات الإضافية التي تظهر لك، ويمكنك تغييره لاحقًا.'**
  String get onboardWhy;

  /// Android string state_on_title
  ///
  /// In ar, this message translates to:
  /// **'التصفية تعمل'**
  String get stateOnTitle;

  /// Android string state_off_title
  ///
  /// In ar, this message translates to:
  /// **'التصفية متوقفة'**
  String get stateOffTitle;

  /// Android string state_starting
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التشغيل…'**
  String get stateStarting;

  /// Android string state_on_detail
  ///
  /// In ar, this message translates to:
  /// **'تُزال الآلات من كل التطبيقات. التأخير نحو {delayMs} ميلي ثانية.'**
  String stateOnDetail(int delayMs);

  /// Android string state_off_detail
  ///
  /// In ar, this message translates to:
  /// **'اضغط الزر للتشغيل.'**
  String get stateOffDetail;

  /// Android string state_model_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل نموذج الصوت، فكُتم الصوت احتياطًا.'**
  String get stateModelFailed;

  /// Android string state_capture_denied
  ///
  /// In ar, this message translates to:
  /// **'يلزم إذن الميكروفون لاستقبال صوت التطبيقات الأخرى.'**
  String get stateCaptureDenied;

  /// Android string state_stopped_by_system
  ///
  /// In ar, this message translates to:
  /// **'أوقف أندرويد التصفية. اضغط الزر للتشغيل من جديد.'**
  String get stateStoppedBySystem;

  /// Android string power_start_cd
  ///
  /// In ar, this message translates to:
  /// **'تشغيل التصفية'**
  String get powerStartCd;

  /// Android string power_stop_cd
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التصفية'**
  String get powerStopCd;

  /// Android string capture_hint
  ///
  /// In ar, this message translates to:
  /// **'سيطلب أندرويد مشاركة الشاشة. يُستخدم الصوت فقط، ولا يُسجَّل شيء ولا يُرسَل.'**
  String get captureHint;

  /// Android string need_record_audio
  ///
  /// In ar, this message translates to:
  /// **'تحتاج واعية إذن الميكروفون لاستقبال صوت التطبيقات الأخرى. ولا يسجّل صوتك أبدًا.'**
  String get needRecordAudio;

  /// Android string setup_banner_title
  ///
  /// In ar, this message translates to:
  /// **'بقيت خطوة واحدة'**
  String get setupBannerTitle;

  /// Android string setup_banner_body
  ///
  /// In ar, this message translates to:
  /// **'بدون الإعداد أدناه ستسمع الموسيقى والصوت المُصفّى معًا.'**
  String get setupBannerBody;

  /// Android string setup_title
  ///
  /// In ar, this message translates to:
  /// **'إعداد لمرة واحدة'**
  String get setupTitle;

  /// Android string setup_body
  ///
  /// In ar, this message translates to:
  /// **'يسمح لواعية بكتم الصوت الأصلي. تفعله مرة واحدة، ويبقى حتى تلغي تثبيت التطبيق.'**
  String get setupBody;

  /// Android string step1_title
  ///
  /// In ar, this message translates to:
  /// **'ثبّت Shizuku'**
  String get step1Title;

  /// Android string step1_body
  ///
  /// In ar, this message translates to:
  /// **'تطبيق مساعد مجاني من متجر Play.'**
  String get step1Body;

  /// Android string step1_action
  ///
  /// In ar, this message translates to:
  /// **'تحميل Shizuku'**
  String get step1Action;

  /// Android string step2_title
  ///
  /// In ar, this message translates to:
  /// **'شغّل Shizuku'**
  String get step2Title;

  /// Android string step2_body
  ///
  /// In ar, this message translates to:
  /// **'يعمل Shizuku عبر الـ Wi‑Fi باستخدام ‏«تصحيح الأخطاء اللاسلكي»‏ في أندرويد. اضغط الزر لترى الخطوات، ثم ارجع إلى هنا.'**
  String get step2Body;

  /// Android string step2_action
  ///
  /// In ar, this message translates to:
  /// **'فتح Shizuku'**
  String get step2Action;

  /// Android string step2_update
  ///
  /// In ar, this message translates to:
  /// **'تحديث Shizuku'**
  String get step2Update;

  /// Android string step2_too_old
  ///
  /// In ar, this message translates to:
  /// **'نسخة Shizuku قديمة. حدّثها من متجر Play.'**
  String get step2TooOld;

  /// Android string step2_denied
  ///
  /// In ar, this message translates to:
  /// **'تم ضبط Shizuku على رفض واعية دائمًا. اسمح لها من قائمة التطبيقات في Shizuku.'**
  String get step2Denied;

  /// Android string step3_title
  ///
  /// In ar, this message translates to:
  /// **'امنح الإذن'**
  String get step3Title;

  /// Android string step3_body
  ///
  /// In ar, this message translates to:
  /// **'ضغطة واحدة، ثم اختر «سماح».'**
  String get step3Body;

  /// Android string step3_action
  ///
  /// In ar, this message translates to:
  /// **'منح الإذن'**
  String get step3Action;

  /// Android string step3_busy
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الإعداد…'**
  String get step3Busy;

  /// Android string setup_done_restart
  ///
  /// In ar, this message translates to:
  /// **'تم. أوقف التصفية ثم شغّلها مرة واحدة لتطبيق ذلك.'**
  String get setupDoneRestart;

  /// Android string setup_failed
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الإعداد. التفاصيل:\n{details}'**
  String setupFailed(String details);

  /// Android string shizuku_refused
  ///
  /// In ar, this message translates to:
  /// **'رُفض إذن Shizuku. اضغط الزر للمحاولة مرة أخرى.'**
  String get shizukuRefused;

  /// Android string step_done_cd
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get stepDoneCd;

  /// Android string step_todo_cd
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {step}'**
  String stepTodoCd(int step);

  /// Android string computer_toggle
  ///
  /// In ar, this message translates to:
  /// **'استخدم حاسوبًا بدلًا من ذلك'**
  String get computerToggle;

  /// Android string computer_body
  ///
  /// In ar, this message translates to:
  /// **'فعّل تصحيح أخطاء USB، ثم وصّل الهاتف ونفّذ:'**
  String get computerBody;

  /// Android string copy
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// Android string copied
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copied;

  /// Android string computer_note
  ///
  /// In ar, this message translates to:
  /// **'السطر الثاني اختياري: يوقف سؤال مشاركة الشاشة عند كل تشغيل.'**
  String get computerNote;

  /// Android string settings_title
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// Android string setting_silence_title
  ///
  /// In ar, this message translates to:
  /// **'كتم التطبيقات التي تمنع التصفية'**
  String get settingSilenceTitle;

  /// Android string setting_silence_body
  ///
  /// In ar, this message translates to:
  /// **'مستحسن. بعض التطبيقات لا تسمح بتصفية صوتها، فيُكتم بدل أن تمرّ الموسيقى.'**
  String get settingSilenceBody;

  /// Android string setting_singing_title
  ///
  /// In ar, this message translates to:
  /// **'كتم غناء النساء'**
  String get settingSingingTitle;

  /// Android string setting_singing_body
  ///
  /// In ar, this message translates to:
  /// **'يُبقي كلام النساء وتلاوتهن.'**
  String get settingSingingBody;

  /// Android string setting_singing_no_model
  ///
  /// In ar, this message translates to:
  /// **'هذه النسخة بلا كاشف للغناء، لذا تُكتم كل الأصوات ما دام هذا الخيار مفعّلًا.'**
  String get settingSingingNoModel;

  /// Android string setting_restart
  ///
  /// In ar, this message translates to:
  /// **'أوقف التصفية ثم شغّلها لتطبيق التغييرات.'**
  String get settingRestart;

  /// Android string setting_gender_title
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get settingGenderTitle;

  /// Android string change
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get change;

  /// Android string player_title
  ///
  /// In ar, this message translates to:
  /// **'فيديو بتزامن تام'**
  String get playerTitle;

  /// Android string player_body
  ///
  /// In ar, this message translates to:
  /// **'شارك فيديو مع واعية (أو استخدم «فتح باستخدام») لمشاهدته مُصفّى بلا تأخير.'**
  String get playerBody;

  /// Android string licences
  ///
  /// In ar, this message translates to:
  /// **'تراخيص المصادر المفتوحة'**
  String get licences;

  /// Android string licences_intro
  ///
  /// In ar, this message translates to:
  /// **'واعية برنامج حر بموجب رخصة جنو أفيرو العمومية (AGPL) الإصدار 3 أو أحدث.'**
  String get licencesIntro;

  /// Android string licences_cc
  ///
  /// In ar, this message translates to:
  /// **'رخصة المشاع الإبداعي - النسبة 4.0 (بيانات التدريب): https://creativecommons.org/licenses/by/4.0/'**
  String get licencesCc;

  /// Android string licences_full
  ///
  /// In ar, this message translates to:
  /// **'النصوص الكاملة'**
  String get licencesFull;

  /// Android string back
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// Android string link_entry_title
  ///
  /// In ar, this message translates to:
  /// **'فتح رابط'**
  String get linkEntryTitle;

  /// Android string link_entry_body
  ///
  /// In ar, this message translates to:
  /// **'الصق رابطًا من YouTube أو TikTok أو Instagram لمشاهدته أو حفظه بلا موسيقى.'**
  String get linkEntryBody;

  /// Android string link_title
  ///
  /// In ar, this message translates to:
  /// **'فتح رابط'**
  String get linkTitle;

  /// Android string link_hint
  ///
  /// In ar, this message translates to:
  /// **'https://… (YouTube، TikTok، Instagram…)'**
  String get linkHint;

  /// Android string link_field_label
  ///
  /// In ar, this message translates to:
  /// **'رابط الفيديو أو الصوت'**
  String get linkFieldLabel;

  /// Android string link_paste
  ///
  /// In ar, this message translates to:
  /// **'لصق'**
  String get linkPaste;

  /// Android string link_open
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get linkOpen;

  /// Android string link_resolving
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فتح الرابط…'**
  String get linkResolving;

  /// Android string link_meta
  ///
  /// In ar, this message translates to:
  /// **'{first} · {second}'**
  String linkMeta(String first, String second);

  /// Android string link_watch
  ///
  /// In ar, this message translates to:
  /// **'مشاهدة بلا موسيقى'**
  String get linkWatch;

  /// Android string link_save
  ///
  /// In ar, this message translates to:
  /// **'حفظ بلا موسيقى'**
  String get linkSave;

  /// Android string link_listen
  ///
  /// In ar, this message translates to:
  /// **'استماع بلا موسيقى'**
  String get linkListen;

  /// Android string link_downloading
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التنزيل…'**
  String get linkDownloading;

  /// Android string link_filtering
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إزالة الموسيقى…'**
  String get linkFiltering;

  /// Android string link_cancel
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get linkCancel;

  /// Android string link_cancelled
  ///
  /// In ar, this message translates to:
  /// **'أُلغي، ولم يُحفظ شيء.'**
  String get linkCancelled;

  /// Android string link_export_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ، ولم يُحفظ شيء.'**
  String get linkExportFailed;

  /// Android string link_saved
  ///
  /// In ar, this message translates to:
  /// **'حُفظ بلا موسيقى'**
  String get linkSaved;

  /// Android string link_saved_video
  ///
  /// In ar, this message translates to:
  /// **'في المعرض: الأفلام › Waaiya'**
  String get linkSavedVideo;

  /// Android string link_saved_audio
  ///
  /// In ar, this message translates to:
  /// **'في الموسيقى: Music › Waaiya'**
  String get linkSavedAudio;

  /// Android string link_play
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get linkPlay;

  /// Android string link_share
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get linkShare;

  /// Android string link_share_note
  ///
  /// In ar, this message translates to:
  /// **'لا تشارك إلا المقاطع التي يحق لك مشاركتها.'**
  String get linkShareNote;

  /// Android string link_live
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حفظ البث المباشر.'**
  String get linkLive;

  /// Android string link_busy
  ///
  /// In ar, this message translates to:
  /// **'يجري حفظ مقطع آخر، يرجى الانتظار حتى ينتهي.'**
  String get linkBusy;

  /// Android string link_invalid
  ///
  /// In ar, this message translates to:
  /// **'الصق رابط ويب (يبدأ بـ https://).'**
  String get linkInvalid;

  /// Android string link_login
  ///
  /// In ar, this message translates to:
  /// **'لم يعرض الموقع هذا المقطع دون حساب. المنشورات العامة تُفتح عادةً: حاول مرة أخرى بعد بضع دقائق. أما المنشورات الخاصة فلا يمكن فتحها.'**
  String get linkLogin;

  /// Android string link_unsupported
  ///
  /// In ar, this message translates to:
  /// **'هذا الموقع غير مدعوم.'**
  String get linkUnsupported;

  /// Android string link_playlist
  ///
  /// In ar, this message translates to:
  /// **'هذه قائمة تشغيل. افتح مقطعًا واحدًا.'**
  String get linkPlaylist;

  /// Android string link_no_format
  ///
  /// In ar, this message translates to:
  /// **'هذا المقطع بصيغة لا تستطيع واعية تصفيتها بعد.'**
  String get linkNoFormat;

  /// Android string link_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح هذا الرابط. تحقّق من الاتصال وحاول مرة أخرى.'**
  String get linkFailed;

  /// Android string link_play_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل هذا المقطع، ولم يُشغَّل أي صوت دون تصفية.'**
  String get linkPlayFailed;

  /// Android string link_limited
  ///
  /// In ar, this message translates to:
  /// **'الموقع يحدّ من الطلبات الآن. حاول مرة أخرى بعد بضع دقائق.'**
  String get linkLimited;

  /// Android string blur_title
  ///
  /// In ar, this message translates to:
  /// **'تمويه الشاشة'**
  String get blurTitle;

  /// Android string blur_body
  ///
  /// In ar, this message translates to:
  /// **'يغطّي الأشخاص والصور على الشاشة في كل التطبيقات ما دامت التصفية تعمل. يعمل على الهاتف، ولا يُرسَل شيء إلى أي مكان.'**
  String get blurBody;

  /// Android string blur_women_title
  ///
  /// In ar, this message translates to:
  /// **'تمويه النساء'**
  String get blurWomenTitle;

  /// Android string blur_women_body
  ///
  /// In ar, this message translates to:
  /// **'الجسم كله. ويُموَّه أيضًا كل من لا يتبيّن للتطبيق بوضوح أنه رجل.'**
  String get blurWomenBody;

  /// Android string blur_nudity_title
  ///
  /// In ar, this message translates to:
  /// **'تمويه الصور غير المحتشمة'**
  String get blurNudityTitle;

  /// Android string blur_nudity_body
  ///
  /// In ar, this message translates to:
  /// **'العري واللباس الكاشف، لأي أحد: تُغطّى الشاشة كلها.'**
  String get blurNudityBody;

  /// Android string blur_fail_title
  ///
  /// In ar, this message translates to:
  /// **'تغطية الشاشة إذا عجز التمويه عن المتابعة'**
  String get blurFailTitle;

  /// Android string blur_fail_body
  ///
  /// In ar, this message translates to:
  /// **'مفعّل: تُغطّى الشاشة كلها إذا كان الهاتف بطيئًا أو تعطّل التمويه. غير مفعّل: تبقى الشاشة ظاهرة مع تنبيه.'**
  String get blurFailBody;

  /// Android string blur_setup_shizuku
  ///
  /// In ar, this message translates to:
  /// **'السماح عبر Shizuku'**
  String get blurSetupShizuku;

  /// Android string blur_setup_manual
  ///
  /// In ar, this message translates to:
  /// **'السماح من إعدادات أندرويد'**
  String get blurSetupManual;

  /// Android string blur_status_needs_setup
  ///
  /// In ar, this message translates to:
  /// **'يحتاج التمويه إلى الظهور فوق التطبيقات الأخرى. الأفضل: اسمح بذلك عبر Shizuku (يشغّل خدمة الإتاحة «تمويه واعية» فتبقى اللمسات تصل إلى التطبيق تحته). أو اسمح بـ«الظهور فوق التطبيقات الأخرى» من إعدادات أندرويد (وحينها تضيع اللمسات على المنطقة المموّهة).'**
  String get blurStatusNeedsSetup;

  /// Android string blur_status_needs_overlay
  ///
  /// In ar, this message translates to:
  /// **'يحتاج التمويه إلى الظهور فوق التطبيقات الأخرى. الأفضل: شغّل Shizuku (واسمح لواعية فيه): فيرسم التمويه طبقته الخاصة التي تمرّ عبرها اللمسات. وإلا فاسمح بـ«الظهور فوق التطبيقات الأخرى» من إعدادات أندرويد، وحينها لا يصل اللمس على منطقة مموّهة إلى التطبيق تحتها.'**
  String get blurStatusNeedsOverlay;

  /// Android string blur_fail_unavailable
  ///
  /// In ar, this message translates to:
  /// **'معطّل مؤقتًا: تغطية الشاشة كلها ستمنع كل لمس وقد تعلق. شغّل Shizuku (أندرويد 12 أو أحدث) فيتفعّل هذا الخيار: يرسم Shizuku الأغطية ويمرّ اللمس من خلالها. وحتى ذلك الحين، إذا عجز التمويه عن المتابعة تبقى الشاشة ظاهرة مع تنبيه.'**
  String get blurFailUnavailable;

  /// Android string blur_fail_needs_a11y
  ///
  /// In ar, this message translates to:
  /// **'معطّل مؤقتًا: تغطية الشاشة كلها ستمنع كل لمس وقد تعلق. شغّل Shizuku (أندرويد 12 أو أحدث) أو فعّل خدمة الإتاحة «تمويه واعية» (السماح عبر Shizuku أعلاه) فيتفعّل هذا الخيار. وحتى ذلك الحين تبقى الشاشة ظاهرة مع تنبيه.'**
  String get blurFailNeedsA11y;

  /// Android string language_title
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageTitle;

  /// Android string setting_language_title
  ///
  /// In ar, this message translates to:
  /// **'اللغة: {language}'**
  String settingLanguageTitle(String language);

  /// Android string language_ar
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageAr;

  /// Android string language_en
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Android string blur_status_restart
  ///
  /// In ar, this message translates to:
  /// **'أوقف التصفية ثم شغّلها لتطبيق إعدادات التمويه.'**
  String get blurStatusRestart;

  /// Android string blur_status_starting
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تشغيل التمويه…'**
  String get blurStatusStarting;

  /// Android string blur_status_on
  ///
  /// In ar, this message translates to:
  /// **'التمويه يعمل.'**
  String get blurStatusOn;

  /// Android string blur_status_on_visible
  ///
  /// In ar, this message translates to:
  /// **'التمويه يعمل بوضع الحذر: هذا الهاتف يُظهر التمويه في التقاط الشاشة نفسه، فتبقى المنطقة المموّهة مموّهة حتى يتغيّر المشهد.'**
  String get blurStatusOnVisible;

  /// Android string blur_status_models
  ///
  /// In ar, this message translates to:
  /// **'هذه النسخة تفتقد نموذج التمويه للخيار المختار.'**
  String get blurStatusModels;

  /// Android string blur_status_failing
  ///
  /// In ar, this message translates to:
  /// **'التمويه عاجز عن المتابعة الآن.'**
  String get blurStatusFailing;

  /// Android string blur_status_no_overlay
  ///
  /// In ar, this message translates to:
  /// **'لا يستطيع التمويه الظهور فوق التطبيقات الأخرى: اسمح بذلك أعلاه.'**
  String get blurStatusNoOverlay;

  /// Android string blur_setup_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر السماح عبر Shizuku:\n{details}'**
  String blurSetupFailed(String details);

  /// Android string step2_guide
  ///
  /// In ar, this message translates to:
  /// **'كيف أشغّل Shizuku؟'**
  String get step2Guide;

  /// Android string blur_fail_old_android
  ///
  /// In ar, this message translates to:
  /// **'معطّل: في هذه النسخة من أندرويد ستمنع تغطية الشاشة كلها كل لمس وقد تعلق (أغطية Shizuku تحتاج أندرويد 12 أو أحدث). إذا عجز التمويه عن المتابعة تبقى الشاشة ظاهرة مع تنبيه.'**
  String get blurFailOldAndroid;

  /// Android string guide_title
  ///
  /// In ar, this message translates to:
  /// **'تشغيل Shizuku خطوة بخطوة'**
  String get guideTitle;

  /// Android string guide_open_dev
  ///
  /// In ar, this message translates to:
  /// **'خيارات المطور'**
  String get guideOpenDev;

  /// Android string guide_open_shizuku
  ///
  /// In ar, this message translates to:
  /// **'فتح Shizuku'**
  String get guideOpenShizuku;

  /// Android string guide_close
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get guideClose;

  /// Android string guide_body
  ///
  /// In ar, this message translates to:
  /// **'تحتاج إلى شبكة Wi‑Fi وأندرويد 11 أو أحدث. الإقران يكون مرة واحدة فقط، وبعد إعادة تشغيل الهاتف تكرّر الخطوة 7 وحدها.\n\n1. اتصل بشبكة Wi‑Fi.\n\n2. فعّل ‏«خيارات المطور»‏: الإعدادات › حول الهاتف › معلومات البرنامج › اضغط على ‏«رقم الإصدار»‏ 7 مرات. (في الهواتف الأخرى: الإعدادات › حول الهاتف › رقم الإصدار.)\n\n3. افتح Shizuku. إذا طلب إظهار الإشعارات فاسمح له، لأن رمز الإقران يُكتب داخل إشعار Shizuku.\n\n4. في Shizuku، تحت ‏«Start via Wireless debugging»‏ (التشغيل عبر تصحيح الأخطاء اللاسلكي)، اضغط ‏«Pairing»‏ (إقران). في الصفحة التي تفتح اضغط ‏«Developer options»‏ (خيارات المطور)، وفعّل ‏«تصحيح الأخطاء اللاسلكي»‏، ووافق بـ‏«سماح»‏.\n\n5. اضغط على عبارة ‏«تصحيح الأخطاء اللاسلكي»‏ نفسها (لا على المفتاح)، ثم ‏«إقران الجهاز باستخدام رمز الإقران»‏. سيظهر رمز من 6 أرقام.\n\n6. اترك تلك الشاشة مفتوحة واسحب الإشعارات إلى الأسفل. عندما يظهر في إشعار Shizuku ‏«Pairing service found»‏ (تم العثور على خدمة الإقران) اضغط ‏«Enter pairing code»‏ (إدخال رمز الإقران)، واكتب الرمز. سيُخبرك Shizuku بنجاح الإقران.\n\n7. ارجع إلى Shizuku واضغط ‏«Start»‏ (بدء) تحت ‏«Start via Wireless debugging»‏، وانتظر حتى تظهر عبارة ‏«Shizuku is running»‏ (Shizuku يعمل).\n\n8. ارجع إلى واعية واضغط ‏«منح الإذن»‏ ثم ‏«السماح»‏.\n\nبعد إعادة تشغيل الهاتف يتوقف Shizuku: اتصل بالـ Wi‑Fi، وأعد تفعيل ‏«تصحيح الأخطاء اللاسلكي»‏ إن كان مطفأً، ثم افتح Shizuku واضغط ‏«Start»‏. لا حاجة إلى إقران جديد.'**
  String get guideBody;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'معاينة: محرك التصفية غير موصول بهذا الحاسوب بعد. الزر يعرض فقط كيف سيعمل التطبيق.'**
  String get desktopPreview;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر ذلك: {details}'**
  String actionFailed(String details);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
