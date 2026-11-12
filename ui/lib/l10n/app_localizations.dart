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

  /// Android string state_silenced_title
  ///
  /// In ar, this message translates to:
  /// **'توقفت التصفية'**
  String get stateSilencedTitle;

  /// Android string state_silenced
  ///
  /// In ar, this message translates to:
  /// **'توقفت التصفية: التطبيقات الأخرى مكتومة. اضغط الزر للتشغيل من جديد، أو «إيقاف» لسماعها دون تصفية.'**
  String get stateSilenced;

  /// Android string release_silence
  ///
  /// In ar, this message translates to:
  /// **'إيقاف: سماع التطبيقات دون تصفية'**
  String get releaseSilence;

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

  /// Android string setting_hold_silence_title
  ///
  /// In ar, this message translates to:
  /// **'إبقاء التطبيقات صامتة إذا توقفت التصفية من تلقاء نفسها'**
  String get settingHoldSilenceTitle;

  /// Android string setting_hold_silence_body
  ///
  /// In ar, this message translates to:
  /// **'مستحسن. إذا أنهى أندرويد التصفية (لا أنت)، تبقى التطبيقات الأخرى صامتة حتى تشغّلها من جديد أو تضغط «إيقاف»، بدل أن تُسمع الموسيقى دون تصفية. يحتاج إلى الإعداد لمرة واحدة.'**
  String get settingHoldSilenceBody;

  /// Android string setting_stereo_title
  ///
  /// In ar, this message translates to:
  /// **'صوت ستيريو'**
  String get settingStereoTitle;

  /// Android string setting_stereo_body
  ///
  /// In ar, this message translates to:
  /// **'مُطفأ: صوت أحادي (مونو)، يستهلك نحو نصف البطارية ويتابع على هواتف أكثر. مُشغَّل: يُبقي جهتَي اليمين واليسار منفصلتين. وإن كان الهاتف أبطأ من الستيريو، يعود إلى المونو من تلقاء نفسه.'**
  String get settingStereoBody;

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
  /// **'واعية برنامج حر بموجب رخصة جنو أفيرو العمومية (AGPL) الإصدار 3 أو أحدث. الشيفرة المصدرية: https://github.com/oksyassine/waaiya'**
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

  /// Android string link_audio_only
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن فتح صورة هذا المقطع بعد: صوته فقط.'**
  String get linkAudioOnly;

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

  /// Android string link_timed_out
  ///
  /// In ar, this message translates to:
  /// **'أوقف أندرويد الحفظ: فهو لا يسمح بهذا النوع من العمل إلا بضع ساعات في اليوم. لم يُحفظ شيء؛ افتح واعية وحاول من جديد.'**
  String get linkTimedOut;

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

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لا يستطيع التمويه رؤية الشاشة. التفاصيل:\n{details}'**
  String blurStatusNoCapture(String details);

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

  /// Android string wsetup_route_title
  ///
  /// In ar, this message translates to:
  /// **'الإعداد على هذا الهاتف (دون تطبيق إضافي)'**
  String get wsetupRouteTitle;

  /// Android string wsetup_route_body
  ///
  /// In ar, this message translates to:
  /// **'باستخدام ‏«تصحيح الأخطاء اللاسلكي»‏ الموجود في أندرويد نفسه. تحتاج إلى شبكة Wi‑Fi (لا يلزم الإنترنت). الإقران يكون مرة واحدة فقط.'**
  String get wsetupRouteBody;

  /// Android string wsetup_steps
  ///
  /// In ar, this message translates to:
  /// **'1. اضغط ‏«ابدأ»‏. تفتح واعية ‏«خيارات المطور»‏ وتُظهر إشعارًا.\n\n2. إذا كانت ‏«خيارات المطور»‏ غير مفعّلة، تُفتح صفحة ‏«حول الهاتف»‏ بدلًا منها: اضغط على ‏«رقم الإصدار»‏ 7 مرات (في بعض الهواتف تجده داخل ‏«معلومات البرنامج»‏)، ثم ارجع إلى هنا واضغط ‏«ابدأ»‏ مرة أخرى.\n\n3. انزل في الصفحة إلى ‏«تصحيح الأخطاء اللاسلكي»‏ (ضمن قسم ‏«تصحيح الأخطاء»‏)، وفعّله وأكّد بالضغط على ‏«سماح»‏.\n\n4. اضغط على عبارة ‏«تصحيح الأخطاء اللاسلكي»‏ نفسها (لا على المفتاح)، ثم على ‏«إقران الجهاز باستخدام رمز الإقران»‏. يظهر رمز من 6 أرقام.\n\n5. اترك تلك الشاشة مفتوحة. اسحب الإشعارات إلى الأسفل، واضغط ‏«أدخل الرمز»‏ في إشعار واعية واكتب الرمز.\n\n6. تُكمل واعية الباقي وحدها وتقول ‏«اكتمل الإعداد»‏. بعدها يمكنك إيقاف ‏«تصحيح الأخطاء اللاسلكي»‏.'**
  String get wsetupSteps;

  /// Android string wsetup_start
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get wsetupStart;

  /// Android string wsetup_enter_here
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرمز هنا'**
  String get wsetupEnterHere;

  /// Android string wsetup_cancel
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get wsetupCancel;

  /// Android string wsetup_android10
  ///
  /// In ar, this message translates to:
  /// **'أندرويد 10 لا يستطيع إتمام الإعداد وحده: يحتاج إلى حاسوب، إما مباشرة (في الأسفل) أو لتشغيل Shizuku مرة واحدة.'**
  String get wsetupAndroid10;

  /// Android string wsetup_shizuku_heading
  ///
  /// In ar, this message translates to:
  /// **'أو باستخدام تطبيق Shizuku'**
  String get wsetupShizukuHeading;

  /// Android string wsetup_shizuku_note
  ///
  /// In ar, this message translates to:
  /// **'يسمح Shizuku أيضًا بمرور اللمس عبر أغطية الشاشة.'**
  String get wsetupShizukuNote;

  /// Android string wsetup_channel
  ///
  /// In ar, this message translates to:
  /// **'الإعداد لمرة واحدة'**
  String get wsetupChannel;

  /// Android string wsetup_notif_title
  ///
  /// In ar, this message translates to:
  /// **'إعداد واعية: في انتظار رمز الإقران'**
  String get wsetupNotifTitle;

  /// Android string wsetup_found_title
  ///
  /// In ar, this message translates to:
  /// **'وُجدت شاشة الإقران'**
  String get wsetupFoundTitle;

  /// Android string wsetup_busy_title
  ///
  /// In ar, this message translates to:
  /// **'إعداد واعية'**
  String get wsetupBusyTitle;

  /// Android string wsetup_done_title
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الإعداد'**
  String get wsetupDoneTitle;

  /// Android string wsetup_done_body
  ///
  /// In ar, this message translates to:
  /// **'تستطيع واعية الآن كتم الصوت الأصلي. يمكنك إيقاف ‏«تصحيح الأخطاء اللاسلكي»‏.'**
  String get wsetupDoneBody;

  /// Android string wsetup_failed_title
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الإعداد'**
  String get wsetupFailedTitle;

  /// Android string wsetup_pairing
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الإقران…'**
  String get wsetupPairing;

  /// Android string wsetup_connecting
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال ومنح الأذونات…'**
  String get wsetupConnecting;

  /// Android string wsetup_need_wifi
  ///
  /// In ar, this message translates to:
  /// **'اتصل بشبكة Wi‑Fi أولًا (لا يلزم الإنترنت): ‏«تصحيح الأخطاء اللاسلكي»‏ لا يعمل إلا عبر Wi‑Fi.'**
  String get wsetupNeedWifi;

  /// Android string wsetup_need_wireless_debugging
  ///
  /// In ar, this message translates to:
  /// **'في ‏«خيارات المطور»‏، فعّل ‏«تصحيح الأخطاء اللاسلكي»‏، ثم اضغط على اسمه ثم على ‏«إقران الجهاز باستخدام رمز الإقران»‏.'**
  String get wsetupNeedWirelessDebugging;

  /// Android string wsetup_open_dialog
  ///
  /// In ar, this message translates to:
  /// **'في ‏«تصحيح الأخطاء اللاسلكي»‏، اضغط ‏«إقران الجهاز باستخدام رمز الإقران»‏. اترك الرمز ظاهرًا على الشاشة واضغط ‏«أدخل الرمز»‏ هنا.'**
  String get wsetupOpenDialog;

  /// Android string wsetup_enter_code_body
  ///
  /// In ar, this message translates to:
  /// **'اضغط ‏«أدخل الرمز»‏ واكتب الرمز المكوّن من 6 أرقام الظاهر في الإعدادات.'**
  String get wsetupEnterCodeBody;

  /// Android string wsetup_code_waiting
  ///
  /// In ar, this message translates to:
  /// **'وصل الرمز. في انتظار شاشة ‏«إقران الجهاز باستخدام رمز الإقران»‏: اتركها مفتوحة.'**
  String get wsetupCodeWaiting;

  /// Android string wsetup_wrong_code
  ///
  /// In ar, this message translates to:
  /// **'لم يُقبل هذا الرمز. تحقّق من الأرقام الستة الظاهرة على الشاشة وأدخلها مرة أخرى. إذا أُغلقت شاشة الإقران فافتحها من جديد، فالرمز يتغيّر.'**
  String get wsetupWrongCode;

  /// Android string wsetup_pairing_failed
  ///
  /// In ar, this message translates to:
  /// **'لم ينجح الإقران. أغلق شاشة الإقران، وافتح ‏«إقران الجهاز باستخدام رمز الإقران»‏ مرة أخرى وأدخل الرمز الجديد.'**
  String get wsetupPairingFailed;

  /// Android string wsetup_waiting_connect
  ///
  /// In ar, this message translates to:
  /// **'تم الإقران. أبقِ ‏«تصحيح الأخطاء اللاسلكي»‏ مفعّلًا: واعية تتصل الآن.'**
  String get wsetupWaitingConnect;

  /// Android string wsetup_not_paired
  ///
  /// In ar, this message translates to:
  /// **'لم يعد هذا الهاتف يعرف واعية (أُزيل الإقران أو انتهت مدته). افتح ‏«إقران الجهاز باستخدام رمز الإقران»‏ وأدخل الرمز.'**
  String get wsetupNotPaired;

  /// Android string wsetup_connect_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بـ ‏«تصحيح الأخطاء اللاسلكي»‏. أوقفه ثم فعّله مرة أخرى، وستعيد واعية المحاولة وحدها.'**
  String get wsetupConnectFailed;

  /// Android string wsetup_grant_failed
  ///
  /// In ar, this message translates to:
  /// **'تم الاتصال، لكن الأذونات ما زالت ناقصة. استخدم Shizuku أو حاسوبًا (في الأسفل).'**
  String get wsetupGrantFailed;

  /// Android string wsetup_timeout
  ///
  /// In ar, this message translates to:
  /// **'توقّف الإعداد بعد 10 دقائق دون أن يكتمل. اضغط ‏«ابدأ»‏ للمحاولة مرة أخرى.'**
  String get wsetupTimeout;

  /// Android string wsetup_code_unreadable
  ///
  /// In ar, this message translates to:
  /// **'اكتب الأرقام الستة لرمز الإقران.'**
  String get wsetupCodeUnreadable;

  /// Android string wsetup_code_hint
  ///
  /// In ar, this message translates to:
  /// **'رمز من 6 أرقام'**
  String get wsetupCodeHint;

  /// Android string wsetup_enter_code
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز'**
  String get wsetupEnterCode;

  /// Android string wsetup_detail
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل: {details}'**
  String wsetupDetail(String details);

  /// Android string wsetup_err_timeout
  ///
  /// In ar, this message translates to:
  /// **'لم يأتِ رد في الوقت المحدد'**
  String get wsetupErrTimeout;

  /// Android string wsetup_err_refused
  ///
  /// In ar, this message translates to:
  /// **'رُفض الاتصال'**
  String get wsetupErrRefused;

  /// Android string wsetup_dev_off
  ///
  /// In ar, this message translates to:
  /// **'‏«خيارات المطور»‏ غير مفعّلة. في ‏«حول الهاتف»‏ اضغط على ‏«رقم الإصدار»‏ 7 مرات (في بعض الهواتف تجده داخل ‏«معلومات البرنامج»‏)، ثم ارجع إلى هنا واضغط ‏«ابدأ»‏ مرة أخرى.'**
  String get wsetupDevOff;

  /// Android string wsetup_open_about
  ///
  /// In ar, this message translates to:
  /// **'حول الهاتف'**
  String get wsetupOpenAbout;

  /// Android string wsetup_notif_off
  ///
  /// In ar, this message translates to:
  /// **'إشعارات واعية متوقفة، فلا يمكن كتابة الرمز في إشعار. استخدم تقسيم الشاشة (الإعدادات في نصف وواعية في النصف الآخر) واضغط ‏«اكتب الرمز هنا»‏.'**
  String get wsetupNotifOff;

  /// Android string wsetup_code_dialog_title
  ///
  /// In ar, this message translates to:
  /// **'رمز الإقران'**
  String get wsetupCodeDialogTitle;

  /// Android string wsetup_code_dialog_body
  ///
  /// In ar, this message translates to:
  /// **'مع تقسيم الشاشة فقط (الإعدادات في نصف وواعية في النصف الآخر): الخروج من الإعدادات يُغلق شاشة الإقران فيتوقف رمزها عن العمل. اكتب الرمز المكوّن من 6 أرقام الظاهر تحت ‏«إقران الجهاز باستخدام رمز الإقران»‏.'**
  String get wsetupCodeDialogBody;

  /// Android string wsetup_code_ok
  ///
  /// In ar, this message translates to:
  /// **'إقران'**
  String get wsetupCodeOk;

  /// Android string blur_strict_title
  ///
  /// In ar, this message translates to:
  /// **'مَن يبقى دون تغطية'**
  String get blurStrictTitle;

  /// Android string blur_strict_value
  ///
  /// In ar, this message translates to:
  /// **'مَن يبقى دون تغطية: {level}'**
  String blurStrictValue(String level);

  /// Android string blur_strict_0
  ///
  /// In ar, this message translates to:
  /// **'صارم: فقط من يكاد التطبيق يجزم أنه رجل'**
  String get blurStrict0;

  /// Android string blur_strict_1
  ///
  /// In ar, this message translates to:
  /// **'متوازن: نحو ضعف عدد الرجال دون تغطية'**
  String get blurStrict1;

  /// Android string blur_strict_2
  ///
  /// In ar, this message translates to:
  /// **'متساهل: رجال أكثر قليلًا من المتوازن'**
  String get blurStrict2;

  /// Android string blur_strict_0_short
  ///
  /// In ar, this message translates to:
  /// **'صارم'**
  String get blurStrict0Short;

  /// Android string blur_strict_1_short
  ///
  /// In ar, this message translates to:
  /// **'متوازن'**
  String get blurStrict1Short;

  /// Android string blur_strict_2_short
  ///
  /// In ar, this message translates to:
  /// **'متساهل'**
  String get blurStrict2Short;

  /// Android string blur_strict_help
  ///
  /// In ar, this message translates to:
  /// **'كل من لا يتأكد التطبيق أنه رجل يُغطّى. في الوضع الصارم يبقى نحو 7 رجال من كل 100 دون تغطية، وفي المتوازن نحو 14، وفي المتساهل نحو 16. وكل درجة أقل صرامة تترك أيضًا نحو امرأة واحدة إضافية من كل 100 دون تغطية.'**
  String get blurStrictHelp;

  /// Android string state_on_not_muted
  ///
  /// In ar, this message translates to:
  /// **'الصوت الأصلي لم يُكتم بعد، ولذلك تسمع الموسيقى مع الصوت المُصفّى. أكمل الإعداد لمرة واحدة أدناه.'**
  String get stateOnNotMuted;

  /// Android string state_on_mute_failing
  ///
  /// In ar, this message translates to:
  /// **'لا تستطيع واعية كتم الصوت الأصلي للتطبيق الذي يعمل الآن، ولذلك قد تُسمع الموسيقى. أوقف التصفية ثم شغّلها. وإن استمر ذلك فأرسل تقرير التشخيص (أسفل هذه الشاشة).'**
  String get stateOnMuteFailing;

  /// Android string state_too_slow
  ///
  /// In ar, this message translates to:
  /// **'هذا الهاتف أبطأ من أن يصفّي الصوت مباشرة، ولذلك يتقطّع الصوت. خيار «فتح رابط» أدناه يعمل: فهو يصفّي الفيديو قبل تشغيله.'**
  String get stateTooSlow;

  /// Android string state_mono_note
  ///
  /// In ar, this message translates to:
  /// **'الصوت أحادي (مونو) ليتمكن هذا الهاتف من المتابعة.'**
  String get stateMonoNote;

  /// Android string state_blocked_silenced
  ///
  /// In ar, this message translates to:
  /// **'كُتم صوته لأنه لا يسمح بالتصفية: {apps}.'**
  String stateBlockedSilenced(String apps);

  /// Android string state_blocked_unfiltered
  ///
  /// In ar, this message translates to:
  /// **'يُسمع دون تصفية لأنه لا يسمح بها: {apps}.'**
  String stateBlockedUnfiltered(String apps);

  /// Android string state_capture_failed
  ///
  /// In ar, this message translates to:
  /// **'لم يُعطِ أندرويد واعية صوت التطبيقات الأخرى. اضغط الزر للتشغيل من جديد.'**
  String get stateCaptureFailed;

  /// Android string state_capture_cancelled
  ///
  /// In ar, this message translates to:
  /// **'أُلغي التشغيل عند سؤال أندرويد عن مشاركة الشاشة. تحتاج واعية أن تختار «بدء» هناك لاستقبال الصوت. لا يُسجَّل شيء ولا يُرسَل.'**
  String get stateCaptureCancelled;

  /// Android string start_no_setup_title
  ///
  /// In ar, this message translates to:
  /// **'ستبقى الموسيقى مسموعة'**
  String get startNoSetupTitle;

  /// Android string start_no_setup_body
  ///
  /// In ar, this message translates to:
  /// **'الإعداد لمرة واحدة لم يكتمل بعد. بدونه لا تستطيع واعية كتم الصوت الأصلي، فتسمع الموسيقى والصوت المُصفّى معًا.\n\nخيار «فتح رابط» يعمل دون أي إعداد.'**
  String get startNoSetupBody;

  /// Android string start_no_setup_setup
  ///
  /// In ar, this message translates to:
  /// **'أكمل الإعداد'**
  String get startNoSetupSetup;

  /// Android string start_no_setup_anyway
  ///
  /// In ar, this message translates to:
  /// **'شغّل على أي حال'**
  String get startNoSetupAnyway;

  /// Android string diag_button
  ///
  /// In ar, this message translates to:
  /// **'مشكلة؟ تقرير التشخيص'**
  String get diagButton;

  /// Android string diag_title
  ///
  /// In ar, this message translates to:
  /// **'تقرير التشخيص'**
  String get diagTitle;

  /// Android string diag_note
  ///
  /// In ar, this message translates to:
  /// **'ما تراه واعية على هذا الهاتف. انسخه أو شاركه مع من يساعدك. التطبيق نفسه لا يرسل شيئًا.'**
  String get diagNote;

  /// Android string notif_stopped_title
  ///
  /// In ar, this message translates to:
  /// **'توقفت واعية'**
  String get notifStoppedTitle;

  /// Android string notif_stopped_text
  ///
  /// In ar, this message translates to:
  /// **'الصوت لم يعد يُصفّى. اضغط للتشغيل من جديد.'**
  String get notifStoppedText;

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

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'تُزال الآلات من كل التطبيقات.'**
  String get stateOnDetailNoDelay;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على أدوات الصوت (pactl). تحتاج واعية إلى PulseAudio، أو PipeWire مع pipewire-pulse.'**
  String get engineErrorNoPactl;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'خادم الصوت لا يعمل (PulseAudio أو PipeWire).'**
  String get engineErrorNoSoundServer;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد في هذا النظام جلسة systemd للمستخدم، وهي التي تشغّل التصفية في الخلفية.'**
  String get engineErrorNoSystemd;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على مكبّرات صوت أو سماعات.'**
  String get engineErrorNoOutput;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تثبيت التصفية. التفاصيل:\n{details}'**
  String engineErrorInstallFailed(String details);

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ التصفية. التفاصيل:\n{details}'**
  String engineErrorStartFailed(String details);

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'توقّفت التصفية بسبب خطأ. التفاصيل:\n{details}'**
  String engineErrorServiceFailed(String details);

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'التشغيل عند تسجيل الدخول'**
  String get autostartTitle;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'تصفية الصوت فور تسجيل الدخول.'**
  String get autostartBody;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'يغطّي الأشخاص والصور على الشاشة، فوق كل النوافذ، ما دامت واعية مفتوحة (سواء كانت تصفية الصوت تعمل أم لا). يعمل على هذا الحاسوب، ولا يُرسَل شيء إلى أي مكان. إغلاق نافذة واعية يوقف التمويه.'**
  String get blurBodyDesktop;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل: تُغطّى الشاشة كلها إذا كان الحاسوب أبطأ من اللازم أو تعطّل التمويه، وتبقى النقرات تصل إلى النوافذ تحته. معطّل: تبقى الشاشة ظاهرة مع شريط أحمر في أعلاها.'**
  String get blurFailBodyDesktop;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'التمويه يعمل. يظهر التمويه في التقاط الشاشة على هذا الحاسوب، لذا تبقى المنطقة المموّهة مموّهة حتى يتغيّر المشهد.'**
  String get blurStatusOnVisibleDesktop;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لا يستطيع التمويه الرسم فوق النوافذ الأخرى في سطح المكتب هذا. التفاصيل:\n{details}'**
  String blurStatusNoOverlayDesktop(String details);

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'اختر شاشتك في نافذة مشاركة الشاشة واسمح بها. تسأل واعية مرة واحدة فقط، وتبقى الصورة على هذا الحاسوب.'**
  String get blurStatusShareDialog;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'توقّف التمويه على نحو غير متوقّع. أطفئ أحد خيارات التمويه ثم شغّله لتجرّب من جديد. التفاصيل:\n{details}'**
  String blurStatusExited(String details);

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحمَّل كاشف غناء النساء، لذا تُكتم الأصوات ما دام هذا الخيار مفعّلًا.'**
  String get engineDetectorFailed;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'إحدى الشاشات لا يغطّيها التمويه: لم تُشارَك معه، أو وُصلت لاحقًا. أطفئ أحد خيارات التمويه ثم شغّله، واختر كل الشاشات في نافذة مشاركة الشاشة.'**
  String get blurStatusUncovered;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'نماذج التمويه غير موجودة في هذا التثبيت، لذا لا يستطيع تغطية شيء، ويبقى شريط أحمر في أعلى الشاشة. أعد تثبيت واعية.'**
  String get blurStatusModelsMissingDesktop;

  /// Flutter only. Arabic not reviewed yet.
  ///
  /// In ar, this message translates to:
  /// **'ما تراه واعية على هذا الحاسوب. انسخه وأعطه لمن يساعدك. التطبيق نفسه لا يرسل شيئًا.'**
  String get diagNoteDesktop;
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
