import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_so.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_uz.dart';

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
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('ha'),
    Locale('id'),
    Locale('it'),
    Locale('ms'),
    Locale('nl'),
    Locale('ru'),
    Locale('so'),
    Locale('sw'),
    Locale('tr'),
    Locale('ur'),
    Locale('uz'),
  ];

  /// Android string app_name
  ///
  /// In ar, this message translates to:
  /// **'واعية'**
  String get appName;

  /// Android string tagline
  ///
  /// In ar, this message translates to:
  /// **'تزيل الآلات الموسيقية من صوت تطبيقاتك، وتُبقي الكلام والتلاوة.'**
  String get tagline;

  /// Android string onboard_title
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك'**
  String get onboardTitle;

  /// Android string onboard_body
  ///
  /// In ar, this message translates to:
  /// **'تزيل واعية الآلات الموسيقية من صوت التطبيقات على هذا الهاتف، وتُبقي الكلام وتلاوة القرآن. وتُزال أصوات الغناء أيضًا.'**
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
  /// **'هذا يحدّد فقط الخيارات الاختيارية التي تظهر لك. مثلًا: «كتم غناء النساء» يظهر للرجال فقط. ويمكنك تغييره لاحقًا.'**
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
  /// **'تُصفّى أصوات تطبيقاتك. يتأخّر الصوت نحو {delayMs} ميلي ثانية (1000 ميلي ثانية = ثانية واحدة).'**
  String stateOnDetail(int delayMs);

  /// Android string state_off_detail
  ///
  /// In ar, this message translates to:
  /// **'اضغط الزر للتشغيل.'**
  String get stateOffDetail;

  /// Android string state_model_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المرشِّح، فكُتم الصوت بدل أن يُسمع دون تصفية.'**
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
  /// **'سيطلب أندرويد مشاركة الشاشة. لا يُسجَّل شيء ولا يُرسَل.'**
  String get captureHint;

  /// Android string need_record_audio
  ///
  /// In ar, this message translates to:
  /// **'تحتاج واعية إذن الميكروفون لاستقبال صوت التطبيقات الأخرى. ولا تسجّل صوتك أبدًا.'**
  String get needRecordAudio;

  /// Android string setup_banner_title
  ///
  /// In ar, this message translates to:
  /// **'بقيت خطوة واحدة'**
  String get setupBannerTitle;

  /// Android string setup_banner_body
  ///
  /// In ar, this message translates to:
  /// **'دون الإعداد لمرة واحدة، ستسمع الموسيقى والصوت المُصفّى معًا.'**
  String get setupBannerBody;

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

  /// Android string setup_slow
  ///
  /// In ar, this message translates to:
  /// **'يستغرق Shizuku وقتًا أطول من المعتاد. انتظر قليلًا: في بعض الهواتف يحتاج مساعده إلى دقيقة ليبدأ أول مرة.'**
  String get setupSlow;

  /// Android string setup_timeout
  ///
  /// In ar, this message translates to:
  /// **'لم يُجب Shizuku خلال دقيقتين. افتح Shizuku وتأكد أنه يعمل، ثم اضغط الزر مرة أخرى. إذا اكتمل الإعداد لاحقًا فستتحدّث هذه الشاشة وحدها.'**
  String get setupTimeout;

  /// Android string setup_refused_xiaomi
  ///
  /// In ar, this message translates to:
  /// **'رفض الهاتف منح الأذونات. في هواتف شاومي وريدمي وبوكو، فعّل ‏«تصحيح أخطاء USB (إعدادات الأمان)»‏ في ‏«خيارات المطور»‏ (يطلب تسجيل الدخول إلى حساب شاومي)، ثم حاول مرة أخرى.'**
  String get setupRefusedXiaomi;

  /// Android string setup_refused_coloros
  ///
  /// In ar, this message translates to:
  /// **'رفض الهاتف منح الأذونات. في هواتف أوبو وون بلس وريلمي، فعّل في ‏«خيارات المطور»‏ ‏«تعطيل مراقبة الأذونات»‏ (اسمه في أحدث الإصدارات ‏«تعطيل تحسين النظام»‏، وقد لا يظهر إلا إذا كانت لغة الهاتف الإنجليزية: Disable permission monitoring أو Disable system optimization). ثم حاول مرة أخرى.'**
  String get setupRefusedColoros;

  /// Android string setup_note_xiaomi
  ///
  /// In ar, this message translates to:
  /// **'شاومي وريدمي وبوكو: إذا لم يظهر في الإشعار مكان لكتابة الرمز، فاختر نمط الإشعارات ‏«Android»‏ في إعدادات الإشعارات، أو اكتب الرمز في واعية مع تقسيم الشاشة.'**
  String get setupNoteXiaomi;

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

  /// Android string computer_web
  ///
  /// In ar, this message translates to:
  /// **'الأسهل: افتح على حاسوب الصفحة waaiya.mssid.org/usb في متصفح Chrome أو Edge، وفعّل تصحيح أخطاء USB، ثم وصّل الهاتف بكابل. لا حاجة إلى تثبيت شيء، وتعمل على أندرويد 10 أيضًا. أو إن كان adb مثبّتًا:'**
  String get computerWeb;

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
  /// **'مثلًا: تُكتم أغنية تغنّيها امرأة، أما امرأة تُلقي درسًا أو كلمة فيبقى صوتها مسموعًا.'**
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
  /// **'فيديو بصوت وصورة متزامنين'**
  String get playerTitle;

  /// Android string player_body
  ///
  /// In ar, this message translates to:
  /// **'شارك فيديو مع واعية (أو استخدم «فتح باستخدام») لمشاهدته مُصفّى، بصوت وصورة متزامنين، دون تأخير التصفية المباشرة.'**
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
  /// **'يغطّي الأشخاص والصور على الشاشة ما دامت التصفية تعمل. يعمل على الهاتف، ولا يُرسَل شيء إلى أي مكان.'**
  String get blurBody;

  /// Android string blur_on_title
  ///
  /// In ar, this message translates to:
  /// **'التمويه يعمل'**
  String get blurOnTitle;

  /// Android string blur_off_title
  ///
  /// In ar, this message translates to:
  /// **'التمويه متوقف'**
  String get blurOffTitle;

  /// Android string blur_start_cd
  ///
  /// In ar, this message translates to:
  /// **'تشغيل التمويه'**
  String get blurStartCd;

  /// Android string blur_stop_cd
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التمويه'**
  String get blurStopCd;

  /// Android string blur_off_detail
  ///
  /// In ar, this message translates to:
  /// **'اضغط الزر للتشغيل. تبدأ التصفية معه.'**
  String get blurOffDetail;

  /// Android string blur_what_title
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يُموَّه'**
  String get blurWhatTitle;

  /// Android string blur_women_title
  ///
  /// In ar, this message translates to:
  /// **'تمويه صور النساء'**
  String get blurWomenTitle;

  /// Android string blur_women_body
  ///
  /// In ar, this message translates to:
  /// **'يغطّي الجسم كله. وإن لم يتأكّد التطبيق أن الشخص رجل، غطّاه أيضًا.'**
  String get blurWomenBody;

  /// Android string blur_nudity_title
  ///
  /// In ar, this message translates to:
  /// **'تمويه الصور غير المحتشمة'**
  String get blurNudityTitle;

  /// Android string blur_nudity_body
  ///
  /// In ar, this message translates to:
  /// **'العُري أو اللباس الكاشف، على أيّ أحد: تُغطّى الشاشة كلها.'**
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

  /// Android string blur_setup_manual
  ///
  /// In ar, this message translates to:
  /// **'السماح من إعدادات أندرويد'**
  String get blurSetupManual;

  /// Android string blur_status_needs_setup
  ///
  /// In ar, this message translates to:
  /// **'ليعمل التمويه، يجب أن تظهر واعية فوق التطبيقات الأخرى. الأفضل: «الذهاب إلى الإعداد»، فتبقى لمساتك تصل إلى التطبيق تحت التمويه. أو «السماح من إعدادات أندرويد»، لكن اللمسة على منطقة مموّهة لن تفعل شيئًا حينها.'**
  String get blurStatusNeedsSetup;

  /// Android string blur_status_needs_overlay
  ///
  /// In ar, this message translates to:
  /// **'ليعمل التمويه، يجب أن تظهر واعية فوق التطبيقات الأخرى. الأفضل: أكمل الإعداد لمرة واحدة، فتبقى لمساتك تصل إلى التطبيق تحت التمويه. أو اسمح بـ«الظهور فوق التطبيقات الأخرى» من إعدادات أندرويد، لكن اللمسة على منطقة مموّهة لن تفعل شيئًا حينها.'**
  String get blurStatusNeedsOverlay;

  /// Android string blur_fail_unavailable
  ///
  /// In ar, this message translates to:
  /// **'معطّل مؤقتًا: تغطية الشاشة كلها ستمنع كل لمس وقد تعلق. شغّل مساعد واعية (أندرويد 12 أو أحدث) فيتفعّل هذا الخيار: تُرسم الأغطية حينها بحيث يمرّ اللمس من خلالها. وحتى ذلك الحين، إذا عجز التمويه عن المتابعة تبقى الشاشة ظاهرة مع تنبيه.'**
  String get blurFailUnavailable;

  /// Android string blur_fail_needs_a11y
  ///
  /// In ar, this message translates to:
  /// **'معطّل مؤقتًا: تغطية الشاشة كلها ستمنع كل لمس وقد تعلق. شغّل مساعد واعية (أندرويد 12 أو أحدث) أو فعّل خدمة الإتاحة «تمويه واعية» من إعدادات أندرويد فيتفعّل هذا الخيار. وحتى ذلك الحين تبقى الشاشة ظاهرة مع تنبيه.'**
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

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا يستطيع التمويه رؤية الشاشة. التفاصيل:\n{details}'**
  String blurStatusNoCapture(String details);

  /// Android string step2_guide
  ///
  /// In ar, this message translates to:
  /// **'كيف أشغّل Shizuku؟'**
  String get step2Guide;

  /// Android string blur_fail_old_android
  ///
  /// In ar, this message translates to:
  /// **'معطّل: في هذه النسخة من أندرويد ستمنع تغطية الشاشة كلها كل لمس وقد تعلق (الأغطية التي يمرّ منها اللمس تحتاج أندرويد 12 أو أحدث). إذا عجز التمويه عن المتابعة تبقى الشاشة ظاهرة مع تنبيه.'**
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
  /// **'الإعداد على هذا الهاتف'**
  String get wsetupRouteTitle;

  /// Android string wsetup_route_body
  ///
  /// In ar, this message translates to:
  /// **'أربع خطوات قصيرة، مرة واحدة فقط. دون تطبيق إضافي ودون حاسوب. تضع واعية علامة على كل خطوة عند إتمامها.'**
  String get wsetupRouteBody;

  /// Android string wiz_dev_title
  ///
  /// In ar, this message translates to:
  /// **'فعّل ‏«خيارات المطور»‏'**
  String get wizDevTitle;

  /// Android string wiz_dev_body
  ///
  /// In ar, this message translates to:
  /// **'في صفحة ‏«حول الهاتف»‏، اضغط على ‏«رقم الإصدار»‏ 7 مرات، ثم ارجع إلى هنا. إن لم تجده، فابحث عن ‏«رقم الإصدار»‏ في الإعدادات.'**
  String get wizDevBody;

  /// Android string wiz_dev_body_samsung
  ///
  /// In ar, this message translates to:
  /// **'في ‏«حول الهاتف»‏ › ‏«معلومات البرنامج»‏، اضغط على ‏«رقم الإصدار»‏ 7 مرات، ثم ارجع إلى هنا.'**
  String get wizDevBodySamsung;

  /// Android string wiz_dev_body_xiaomi
  ///
  /// In ar, this message translates to:
  /// **'في ‏«حول الهاتف»‏، اضغط على ‏«إصدار النظام»‏ 7 مرات (في الهواتف الأقدم ‏«إصدار MIUI»‏، وفي بعضها داخل ‏«المعلومات والمواصفات التفصيلية»‏)، ثم ارجع إلى هنا.'**
  String get wizDevBodyXiaomi;

  /// Android string wiz_dev_body_coloros
  ///
  /// In ar, this message translates to:
  /// **'في ‏«حول الجهاز»‏ (أو ‏«حول الهاتف»‏) › ‏«الإصدار»‏، اضغط على ‏«رقم الإصدار»‏ 7 مرات، ثم ارجع إلى هنا.'**
  String get wizDevBodyColoros;

  /// Android string wiz_dev_body_vivo
  ///
  /// In ar, this message translates to:
  /// **'في ‏«حول الهاتف»‏، اضغط على ‏«إصدار البرنامج»‏ 7 مرات (في بعض الهواتف: ‏«معلومات البرنامج»‏ › ‏«رقم الإصدار»‏)، ثم ارجع إلى هنا.'**
  String get wizDevBodyVivo;

  /// Android string wiz_dev_body_huawei
  ///
  /// In ar, this message translates to:
  /// **'في ‏«حول الهاتف»‏، اضغط على ‏«رقم الإصدار»‏ 7 مرات، ثم ارجع إلى هنا.'**
  String get wizDevBodyHuawei;

  /// Android string wiz_dev_body_transsion
  ///
  /// In ar, this message translates to:
  /// **'في ‏«هاتفي»‏ (أو ‏«حول الهاتف»‏)، اضغط على ‏«رقم الإصدار»‏ 7 مرات، ثم ارجع إلى هنا.'**
  String get wizDevBodyTranssion;

  /// Android string setup_note_huawei
  ///
  /// In ar, this message translates to:
  /// **'هواوي: كثير من هواتف هواوي ليس فيها ‏«تصحيح الأخطاء اللاسلكي»‏. إن لم تجده في ‏«خيارات المطور»‏، فاستعمل حاسوبًا (‏«طرق أخرى»‏ في الأسفل).'**
  String get setupNoteHuawei;

  /// Android string wsetup_filter_on
  ///
  /// In ar, this message translates to:
  /// **'التصفية تعمل: في هذا الإصدار من أندرويد لا يمكن كتابة الرمز في الإشعار أثناء عملها. أوقف التصفية أولًا، أو استعمل تقسيم الشاشة و‏«اكتب الرمز هنا»‏.'**
  String get wsetupFilterOn;

  /// Android string wiz_dev_search
  ///
  /// In ar, this message translates to:
  /// **'قد تختلف الأسماء بحسب لغة الهاتف: إن لم تجده، فاستعمل البحث في أعلى الإعدادات.'**
  String get wizDevSearch;

  /// Android string wiz_dev_action
  ///
  /// In ar, this message translates to:
  /// **'افتح ‏«حول الهاتف»‏'**
  String get wizDevAction;

  /// Android string wiz_wifi_title
  ///
  /// In ar, this message translates to:
  /// **'اتصل بشبكة Wi-Fi'**
  String get wizWifiTitle;

  /// Android string wiz_wifi_body
  ///
  /// In ar, this message translates to:
  /// **'أي شبكة Wi-Fi تكفي؛ لا يلزم الإنترنت.'**
  String get wizWifiBody;

  /// Android string wiz_wifi_action
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات Wi-Fi'**
  String get wizWifiAction;

  /// Android string wiz_wd_title
  ///
  /// In ar, this message translates to:
  /// **'فعّل ‏«تصحيح الأخطاء اللاسلكي»‏'**
  String get wizWdTitle;

  /// Android string wiz_wd_body
  ///
  /// In ar, this message translates to:
  /// **'تفتح واعية ‏«خيارات المطور»‏ عند ‏«تصحيح الأخطاء اللاسلكي»‏. فعّله واضغط ‏«سماح»‏.'**
  String get wizWdBody;

  /// Android string wiz_wd_action
  ///
  /// In ar, this message translates to:
  /// **'افتح خيارات المطور'**
  String get wizWdAction;

  /// Android string wiz_pair_title
  ///
  /// In ar, this message translates to:
  /// **'اكتب رمز الإقران'**
  String get wizPairTitle;

  /// Android string wiz_pair_body
  ///
  /// In ar, this message translates to:
  /// **'اضغط على عبارة ‏«تصحيح الأخطاء اللاسلكي»‏ نفسها، ثم على ‏«إقران الجهاز باستخدام رمز الإقران»‏. اكتب الأرقام الستة في إشعار واعية، وتكمل واعية الباقي.'**
  String get wizPairBody;

  /// Android string wiz_pair_body_paired
  ///
  /// In ar, this message translates to:
  /// **'سبق إقران واعية بهذا الهاتف: لا حاجة لأي رمز. اضغط الزر وتكمل واعية وحدها.'**
  String get wizPairBodyPaired;

  /// Android string wiz_pair_action
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get wizPairAction;

  /// Android string wiz_again
  ///
  /// In ar, this message translates to:
  /// **'أعد تنفيذ الإعداد'**
  String get wizAgain;

  /// Android string setup_shizuku_ready_title
  ///
  /// In ar, this message translates to:
  /// **'عبر Shizuku، وهو يعمل الآن'**
  String get setupShizukuReadyTitle;

  /// Android string setup_other_ways_plain
  ///
  /// In ar, this message translates to:
  /// **'طرق أخرى لإتمام الإعداد'**
  String get setupOtherWaysPlain;

  /// Android string wiz_skip
  ///
  /// In ar, this message translates to:
  /// **'انتقل مباشرة إلى ‏«تصحيح الأخطاء اللاسلكي»‏'**
  String get wizSkip;

  /// Android string setup_other_ways
  ///
  /// In ar, this message translates to:
  /// **'طرق أخرى: Shizuku أو حاسوب'**
  String get setupOtherWays;

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

  /// Android string wsetup_done_helper_body
  ///
  /// In ar, this message translates to:
  /// **'تم. هذا الهاتف لا يسمح للتطبيقات بالاحتفاظ بهذه الأذونات، لذلك يتولى مساعد واعية كتم الصوت الأصلي. يتوقف المساعد عند إعادة تشغيل الهاتف وعند تحديث واعية. عند فتح واعية بعد ذلك، تشغّله من جديد تلقائيًا إن كان ‏«تصحيح الأخطاء اللاسلكي»‏ مفعّلًا؛ وإلا فتعرض زرًّا لذلك.'**
  String get wsetupDoneHelperBody;

  /// Android string helper_missing_title
  ///
  /// In ar, this message translates to:
  /// **'مساعد واعية متوقف'**
  String get helperMissingTitle;

  /// Android string helper_missing_body
  ///
  /// In ar, this message translates to:
  /// **'هذا الهاتف لا يحتفظ بأذونات واعية، لذلك تستعمل واعية مساعدها. يتوقف المساعد عند إعادة تشغيل الهاتف وعند تحديث واعية. اتصل بشبكة Wi-Fi، وفعّل ‏«تصحيح الأخطاء اللاسلكي»‏ في ‏«خيارات المطور»‏، ثم اضغط ‏«تشغيل مساعد واعية»‏.'**
  String get helperMissingBody;

  /// Android string helper_channel
  ///
  /// In ar, this message translates to:
  /// **'مساعد واعية'**
  String get helperChannel;

  /// Android string helper_starting
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تشغيل المساعد…'**
  String get helperStarting;

  /// Android string helper_mode_note
  ///
  /// In ar, this message translates to:
  /// **'هذا الهاتف لا يسمح للتطبيقات بالاحتفاظ بهذه الأذونات: مساعد واعية يقوم بالعمل. يتوقف عند إعادة تشغيل الهاتف وعند تحديث واعية. عند فتح واعية بعد ذلك، تشغّله من جديد تلقائيًا إن كان ‏«تصحيح الأخطاء اللاسلكي»‏ مفعّلًا؛ وإلا فتعرض زرًّا لذلك.'**
  String get helperModeNote;

  /// Android string helper_tip_xiaomi
  ///
  /// In ar, this message translates to:
  /// **'اختياري، للاحتفاظ بالأذونات نهائيًا (دون مساعد بعد إعادة التشغيل): فعّل في ‏«خيارات المطور»‏ ‏«تصحيح أخطاء USB (إعدادات الأمان)»‏ (يطلب تسجيل الدخول إلى حساب شاومي)، ثم أعد الإعداد.'**
  String get helperTipXiaomi;

  /// Android string helper_tip_coloros
  ///
  /// In ar, this message translates to:
  /// **'اختياري، للاحتفاظ بالأذونات نهائيًا (دون مساعد بعد إعادة التشغيل): فعّل في ‏«خيارات المطور»‏ ‏«تعطيل مراقبة الأذونات»‏ (في أحدث الإصدارات ‏«تعطيل تحسين النظام»‏؛ وقد لا يظهر إلا إذا كانت لغة الهاتف الإنجليزية: Disable permission monitoring أو Disable system optimization)، ثم أعد الإعداد.'**
  String get helperTipColoros;

  /// Android string state_on_helper_missing
  ///
  /// In ar, this message translates to:
  /// **'الصوت الأصلي لم يُكتم، ولذلك تسمع الموسيقى مع الصوت المُصفّى: مساعد واعية متوقف. اتصل بشبكة Wi-Fi، وفعّل ‏«تصحيح الأخطاء اللاسلكي»‏، ثم اضغط ‏«تشغيل مساعد واعية»‏.'**
  String get stateOnHelperMissing;

  /// Android string setup_refused_try_wireless
  ///
  /// In ar, this message translates to:
  /// **'أو استعمل ‏«الإعداد على هذا الهاتف»‏ في هذه الصفحة: يعمل مساعد واعية حينها دون ذلك الخيار.'**
  String get setupRefusedTryWireless;

  /// Android string helper_start_anyway_title
  ///
  /// In ar, this message translates to:
  /// **'مساعد واعية متوقف'**
  String get helperStartAnywayTitle;

  /// Android string helper_start_anyway_body
  ///
  /// In ar, this message translates to:
  /// **'من دونه ستسمع الموسيقى مع الصوت المُصفّى. شغّل المساعد أولًا (يجب أن يكون ‏«تصحيح الأخطاء اللاسلكي»‏ مفعّلًا)، أو ابدأ التصفية على أي حال.'**
  String get helperStartAnywayBody;

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
  /// **'توقّف الإعداد بعد 10 دقائق دون أن يكتمل. يمكنك المحاولة مرة أخرى.'**
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
  /// **'‏«خيارات المطور»‏ غير مفعّلة. في صفحة ‏«حول الهاتف»‏، اضغط على ‏«رقم الإصدار»‏ 7 مرات، ثم ارجع إلى هنا.'**
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
  /// **'مدى التأكد قبل إظهار رجل'**
  String get blurStrictTitle;

  /// Android string blur_strict_value
  ///
  /// In ar, this message translates to:
  /// **'مدى التأكد قبل إظهار رجل: {level}'**
  String blurStrictValue(String level);

  /// Android string blur_strict_0
  ///
  /// In ar, this message translates to:
  /// **'صارم: فقط من يكاد التطبيق يجزم أنه رجل'**
  String get blurStrict0;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'متوازن: يظهر نحو ضعف عدد الرجال'**
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
  /// **'لا يظهر الشخص إلا إذا تأكد التطبيق أنه رجل، ويُموَّه كل من سواه. في الوضع الصارم يظهر نحو 7 رجال من كل 100، وفي المتوازن نحو 14، وفي المتساهل نحو 16. ومع ذلك تفوت بعض النساء، وكل درجة أقل صرامة تُفوّت نحو امرأة إضافية من كل 100.'**
  String get blurStrictHelp;

  /// Android string state_on_not_muted
  ///
  /// In ar, this message translates to:
  /// **'الصوت الأصلي لم يُكتم بعد، ولذلك تسمع الموسيقى مع الصوت المُصفّى. أكمل الإعداد لمرة واحدة في صفحة «الإعداد».'**
  String get stateOnNotMuted;

  /// Android string state_on_mute_failing
  ///
  /// In ar, this message translates to:
  /// **'لا تستطيع واعية كتم الصوت الأصلي للتطبيق الذي يعمل الآن، ولذلك قد تُسمع الموسيقى. أوقف التصفية ثم شغّلها. وإن استمر ذلك فأرسل تقرير التشخيص (الإعدادات).'**
  String get stateOnMuteFailing;

  /// Android string state_too_slow
  ///
  /// In ar, this message translates to:
  /// **'هذا الهاتف أبطأ من أن يصفّي الصوت مباشرة، ولذلك يتقطّع الصوت. خيار «فتح رابط» في صفحة «الروابط» يعمل: فهو يصفّي الفيديو قبل تشغيله.'**
  String get stateTooSlow;

  /// Android string state_mono_note
  ///
  /// In ar, this message translates to:
  /// **'الصوت أحادي (مونو) ليتمكن هذا الهاتف من المتابعة.'**
  String get stateMonoNote;

  /// Android string state_blocked_silenced
  ///
  /// In ar, this message translates to:
  /// **'كُتم لعدم السماح بالتصفية: {apps}.'**
  String stateBlockedSilenced(String apps);

  /// Android string state_blocked_unfiltered
  ///
  /// In ar, this message translates to:
  /// **'يُسمع دون تصفية لعدم السماح بها: {apps}.'**
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
  /// **'ما تراه واعية على هذا الهاتف. انسخه أو شاركه مع من يساعدك. لا ترسله واعية من تلقاء نفسها: أنت تختار من يستلمه.'**
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

  /// Android string wsetup_guide
  ///
  /// In ar, this message translates to:
  /// **'الخطوات بالصور'**
  String get wsetupGuide;

  /// Android string nav_filter
  ///
  /// In ar, this message translates to:
  /// **'التصفية'**
  String get navFilter;

  /// Android string nav_screen
  ///
  /// In ar, this message translates to:
  /// **'الشاشة'**
  String get navScreen;

  /// Android string nav_links
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get navLinks;

  /// Android string nav_setup
  ///
  /// In ar, this message translates to:
  /// **'الإعداد'**
  String get navSetup;

  /// Android string nav_settings
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// Android string setup_done_title
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الإعداد'**
  String get setupDoneTitle;

  /// Android string setup_done_body
  ///
  /// In ar, this message translates to:
  /// **'تستطيع واعية كتم الصوت الأصلي للتطبيقات الأخرى. لا تُعِده إلا إذا تغيّر شيء (أُلغي الإعداد، أو قالت واعية إنه ناقص).'**
  String get setupDoneBody;

  /// Android string setup_redo
  ///
  /// In ar, this message translates to:
  /// **'إظهار الإعداد من جديد'**
  String get setupRedo;

  /// Android string setup_go
  ///
  /// In ar, this message translates to:
  /// **'الذهاب إلى الإعداد'**
  String get setupGo;

  /// Android string helper_title
  ///
  /// In ar, this message translates to:
  /// **'اللمس عبر المناطق المموّهة'**
  String get helperTitle;

  /// Android string helper_body_off
  ///
  /// In ar, this message translates to:
  /// **'دون مساعدة، يمنع الغطاء اللمس تحته. يرسم مساعد واعية الأغطية بحيث يمرّ اللمس من خلالها. فعّل ‏«تصحيح الأخطاء اللاسلكي»‏ (يلزم Wi‑Fi) واضغط الزر؛ في المرة الأولى تُقرن الهاتف مرة واحدة كما في الإعداد. بعد إعادة تشغيل الهاتف اضغطه من جديد.'**
  String get helperBodyOff;

  /// Android string helper_start
  ///
  /// In ar, this message translates to:
  /// **'تشغيل مساعد واعية'**
  String get helperStart;

  /// Android string helper_on
  ///
  /// In ar, this message translates to:
  /// **'مساعد واعية يرسم التمويه: تمرّ اللمسات من خلاله. يتوقف عند إعادة تشغيل الهاتف أو عند إيقاف «تصحيح أخطاء USB» (وهو مفتاح منفصل في خيارات المطور)؛ اضغط الزر من جديد حينها.'**
  String get helperOn;

  /// Android string helper_shizuku_on
  ///
  /// In ar, this message translates to:
  /// **'Shizuku يرسم الأغطية: يمرّ اللمس من خلالها.'**
  String get helperShizukuOn;

  /// Android string helper_or_shizuku
  ///
  /// In ar, this message translates to:
  /// **'أو باستخدام Shizuku:'**
  String get helperOrShizuku;

  /// Android string filter_options_title
  ///
  /// In ar, this message translates to:
  /// **'خيارات التصفية'**
  String get filterOptionsTitle;

  /// Android string settings_general_title
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get settingsGeneralTitle;

  /// Android string simple_title
  ///
  /// In ar, this message translates to:
  /// **'الوضع البسيط (تجريبي): دون خيارات المطور'**
  String get simpleTitle;

  /// Android string simple_body
  ///
  /// In ar, this message translates to:
  /// **'للهواتف التي يصعب فيها الإعداد أدناه. أثناء التصفية تكتم واعية صوت الوسائط في الهاتف، وتُشغّل الصوت المُصفّى على قناة صوت أخرى. أزرار الصوت تضبط صوت واعية. يسأل أندرويد عن مشاركة الشاشة عند كل تشغيل. ويعود صوت الوسائط عند إيقاف التصفية.'**
  String get simpleBody;

  /// Android string simple_switch
  ///
  /// In ar, this message translates to:
  /// **'استخدام الوضع البسيط'**
  String get simpleSwitch;

  /// Android string simple_channel_title
  ///
  /// In ar, this message translates to:
  /// **'قناة الصوت: {channel}'**
  String simpleChannelTitle(String channel);

  /// Android string simple_channel_alarm
  ///
  /// In ar, this message translates to:
  /// **'المنبّه'**
  String get simpleChannelAlarm;

  /// Android string simple_channel_notification
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get simpleChannelNotification;

  /// Android string simple_channel_help
  ///
  /// In ar, this message translates to:
  /// **'إن لم تسمع شيئًا، أو خرج الصوت من سمّاعة الهاتف والسمّاعات موصولة، فجرّب القناة الأخرى. قناة الإشعارات صامتة ما دام الهاتف على الاهتزاز أو «عدم الإزعاج».'**
  String get simpleChannelHelp;

  /// Android string simple_test_note
  ///
  /// In ar, this message translates to:
  /// **'هذا وضع تجريبي. بعد تجربته (السمّاعة، سمّاعات الأذن، البلوتوث)، أرسل من فضلك تقرير التشخيص من «الإعدادات».'**
  String get simpleTestNote;

  /// Android string simple_on_detail
  ///
  /// In ar, this message translates to:
  /// **'الوضع البسيط (تجريبي): صوت الوسائط مكتوم أثناء التصفية.'**
  String get simpleOnDetail;

  /// Android string worship_prayer_fajr
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get worshipPrayerFajr;

  /// Android string worship_prayer_sunrise
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get worshipPrayerSunrise;

  /// Android string worship_prayer_dhuhr
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get worshipPrayerDhuhr;

  /// Android string worship_prayer_asr
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get worshipPrayerAsr;

  /// Android string worship_prayer_maghrib
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get worshipPrayerMaghrib;

  /// Android string worship_prayer_isha
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get worshipPrayerIsha;

  /// Android string worship_end_silent
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الصمت الآن'**
  String get worshipEndSilent;

  /// Android string worship_unmute
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكتم الآن'**
  String get worshipUnmute;

  /// Android string worship_sms_default
  ///
  /// In ar, this message translates to:
  /// **'إنه وقت الصلاة، لا أستطيع الرد الآن. سأعاود الاتصال بك.'**
  String get worshipSmsDefault;

  /// Android string update_title
  ///
  /// In ar, this message translates to:
  /// **'تحديثات التطبيق'**
  String get updateTitle;

  /// Android string update_auto
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن إصدار جديد مرة في اليوم'**
  String get updateAuto;

  /// Android string update_auto_body
  ///
  /// In ar, this message translates to:
  /// **'تسأل واعية موقع waaiya.mssid.org هل يوجد إصدار أحدث، ولا ترسل شيئًا غير ذلك. ولا يُنزَّل شيء حتى تضغط «حدِّث الآن».'**
  String get updateAutoBody;

  /// Android string update_check
  ///
  /// In ar, this message translates to:
  /// **'ابحث الآن'**
  String get updateCheck;

  /// Android string update_checking
  ///
  /// In ar, this message translates to:
  /// **'جارٍ البحث…'**
  String get updateChecking;

  /// Android string update_none
  ///
  /// In ar, this message translates to:
  /// **'لديك أحدث إصدار ({version}).'**
  String updateNone(String version);

  /// Android string update_available
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {latest} من واعية متاح. لديك {current}.'**
  String updateAvailable(String latest, String current);

  /// Android string update_size_patch
  ///
  /// In ar, this message translates to:
  /// **'التنزيل: {size}، التغييرات فقط (التطبيق كاملًا {full}).'**
  String updateSizePatch(String size, String full);

  /// Android string update_size_full
  ///
  /// In ar, this message translates to:
  /// **'التنزيل: {size}.'**
  String updateSizeFull(String size);

  /// Android string update_now
  ///
  /// In ar, this message translates to:
  /// **'حدِّث الآن'**
  String get updateNow;

  /// Android string update_downloading
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التنزيل: {progress}'**
  String updateDownloading(String progress);

  /// Android string update_preparing
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز التحديث…'**
  String get updatePreparing;

  /// Android string update_installing
  ///
  /// In ar, this message translates to:
  /// **'أكِّد التثبيت في الشاشة التي يعرضها أندرويد.'**
  String get updateInstalling;

  /// Android string update_stops_filter
  ///
  /// In ar, this message translates to:
  /// **'التثبيت يوقف التصفية. شغّلها مجددًا بعد التحديث.'**
  String get updateStopsFilter;

  /// Android string update_permission
  ///
  /// In ar, this message translates to:
  /// **'اسمح لواعية بتثبيت تحديثاتها، ثم اضغط «حدِّث الآن» مرة أخرى.'**
  String get updatePermission;

  /// Android string update_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إكمال التحديث. حاول لاحقًا، أو نزّله من الموقع.'**
  String get updateFailed;

  /// Android string update_open_page
  ///
  /// In ar, this message translates to:
  /// **'افتح صفحة التنزيل'**
  String get updateOpenPage;

  /// Android string update_check_failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث الآن. حاول لاحقًا.'**
  String get updateCheckFailed;

  /// Android string move_old_title
  ///
  /// In ar, this message translates to:
  /// **'انتقلت واعية'**
  String get moveOldTitle;

  /// Android string move_old_body
  ///
  /// In ar, this message translates to:
  /// **'صارت واعية تأتي في تطبيق جديد على أندرويد (واعية نفسها باسم جديد)، ولن تصل تحديثات أخرى لهذا التطبيق. ثبّت الجديد: تنتقل إليه إعداداتك. ثم أتمّ إعداده لمرة واحدة واحذف هذا.'**
  String get moveOldBody;

  /// Android string move_old_installed
  ///
  /// In ar, this message translates to:
  /// **'ثُبّتت واعية الجديدة. افتحها: تأخذ إعداداتك. أتمّ إعدادها لمرة واحدة، ثم احذف هذه القديمة كي لا يعمل التطبيقان معًا.'**
  String get moveOldInstalled;

  /// Android string move_install
  ///
  /// In ar, this message translates to:
  /// **'ثبّت واعية الجديدة'**
  String get moveInstall;

  /// Android string move_open_new
  ///
  /// In ar, this message translates to:
  /// **'افتح واعية الجديدة'**
  String get moveOpenNew;

  /// Android string move_remove_this
  ///
  /// In ar, this message translates to:
  /// **'احذف واعية القديمة هذه'**
  String get moveRemoveThis;

  /// Android string move_new_title
  ///
  /// In ar, this message translates to:
  /// **'ما زالت واعية القديمة مثبّتة'**
  String get moveNewTitle;

  /// Android string move_new_body
  ///
  /// In ar, this message translates to:
  /// **'ما زالت واعية القديمة (من قبل الإصدار 0.2.15) على هذا الهاتف. احذفها كي لا يعمل التطبيقان معًا.'**
  String get moveNewBody;

  /// Android string move_new_imported
  ///
  /// In ar, this message translates to:
  /// **'نُقلت إعداداتك منها.'**
  String get moveNewImported;

  /// Android string move_remove_old
  ///
  /// In ar, this message translates to:
  /// **'احذف واعية القديمة'**
  String get moveRemoveOld;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'معاينة: محرك التصفية غير موصول بهذا الحاسوب بعد. الزر يعرض فقط كيف سيعمل التطبيق.'**
  String get desktopPreview;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر ذلك: {details}'**
  String actionFailed(String details);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تُصفّى أصوات تطبيقاتك.'**
  String get stateOnDetailNoDelay;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على أدوات الصوت (pactl). تحتاج واعية إلى PulseAudio، أو PipeWire مع pipewire-pulse.'**
  String get engineErrorNoPactl;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'خادم الصوت لا يعمل (PulseAudio أو PipeWire).'**
  String get engineErrorNoSoundServer;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد في هذا النظام جلسة systemd للمستخدم، وهي التي تشغّل التصفية في الخلفية.'**
  String get engineErrorNoSystemd;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على مكبّرات صوت أو سماعات.'**
  String get engineErrorNoOutput;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تثبيت التصفية. التفاصيل:\n{details}'**
  String engineErrorInstallFailed(String details);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ التصفية. التفاصيل:\n{details}'**
  String engineErrorStartFailed(String details);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'توقّفت التصفية بسبب خطأ. التفاصيل:\n{details}'**
  String engineErrorServiceFailed(String details);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'التشغيل عند تسجيل الدخول'**
  String get autostartTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تصفية الصوت فور تسجيل الدخول.'**
  String get autostartBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يغطّي الأشخاص والصور على الشاشة، فوق كل النوافذ، ما دامت واعية مفتوحة (سواء كانت تصفية الصوت تعمل أم لا). يعمل على هذا الحاسوب، ولا يُرسَل شيء إلى أي مكان. إغلاق نافذة واعية يوقف التمويه.'**
  String get blurBodyDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل: تُغطّى الشاشة كلها إذا كان الحاسوب أبطأ من اللازم أو تعطّل التمويه، وتبقى النقرات تصل إلى النوافذ تحته. معطّل: تبقى الشاشة ظاهرة مع شريط أحمر في أعلاها.'**
  String get blurFailBodyDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'التمويه يعمل. يظهر التمويه في التقاط الشاشة على هذا الحاسوب، لذا تبقى المنطقة المموّهة مموّهة حتى يتغيّر المشهد.'**
  String get blurStatusOnVisibleDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا يستطيع التمويه الظهور فوق النوافذ الأخرى في سطح المكتب هذا. التفاصيل:\n{details}'**
  String blurStatusNoOverlayDesktop(String details);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختر شاشتك في نافذة مشاركة الشاشة واسمح بها. تسأل واعية مرة واحدة فقط، وتبقى الصورة على هذا الحاسوب.'**
  String get blurStatusShareDialog;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'توقّف التمويه على نحو غير متوقّع. أطفئ أحد خيارات التمويه ثم شغّله لتجرّب من جديد. التفاصيل:\n{details}'**
  String blurStatusExited(String details);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحمَّل كاشف غناء النساء، لذا تُكتم الأصوات ما دام هذا الخيار مفعّلًا.'**
  String get engineDetectorFailed;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إحدى الشاشات لا يغطّيها التمويه: لم تُشارَك معه، أو وُصلت لاحقًا. أطفئ أحد خيارات التمويه ثم شغّله، واختر كل الشاشات في نافذة مشاركة الشاشة.'**
  String get blurStatusUncovered;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'نماذج التمويه غير موجودة في هذا التثبيت، لذا لا يستطيع تغطية شيء، ويبقى شريط أحمر في أعلى الشاشة. أعد تثبيت واعية.'**
  String get blurStatusModelsMissingDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ما تراه واعية على هذا الحاسوب. انسخه وأعطه لمن يساعدك. لا ترسله واعية من تلقاء نفسها: أنت تختار من يستلمه.'**
  String get diagNoteDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مستحسن. إذا توقفت التصفية من تلقاء نفسها (بسبب خطأ، لا بفعلك)، تبقى التطبيقات الأخرى صامتة حتى تشغّلها من جديد أو تضغط «إيقاف»، بدل أن تُسمع الموسيقى دون تصفية.'**
  String get settingHoldSilenceBodyDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مُطفأ: صوت أحادي (مونو)، يُثقل الحاسوب أقل. مُشغَّل: يُبقي جهتَي اليمين واليسار منفصلتين. وإن كان الحاسوب أبطأ من الستيريو، يعود إلى المونو من تلقاء نفسه.'**
  String get settingStereoBodyDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الصق رابطًا من يوتيوب أو تيك توك أو إنستغرام لتشاهده والتصفية تعمل، أو لتحفظه بلا موسيقى.'**
  String get linkEntryBodyDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الصق رابطًا من يوتيوب أو تيك توك أو إنستغرام لتشاهده في متصفحك والتصفية تعمل.'**
  String get linkEntryBodyWatch;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يُفتح في متصفحك. تبدأ واعية التصفية أولًا، فتُزال الموسيقى هناك أيضًا.'**
  String get linkWatchNoteDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ التصفية، فلم يُفتح الرابط. شغّلها من صفحة التصفية ثم حاول مرة أخرى.'**
  String get linkFilterFailed;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'في مجلد الفيديو: Waaiya'**
  String get linkSavedVideoDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'في مجلد الموسيقى: Waaiya'**
  String get linkSavedAudioDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إظهار في المجلد'**
  String get linkShowInFolder;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يُكتم غناء النساء أيضًا، كما في إعداداتك.'**
  String get linkSingingNote;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إبقاء أصوات الغناء (تجريبي)'**
  String get singingKeepTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تُزال الآلات الموسيقية وتبقى أصوات الغناء، فالمحاضرة التي تحتها نشيد يبقى معها صوت النشيد أيضًا؛ وقبول ذلك من عدمه راجعٌ إليك.'**
  String get singingKeepBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'هذه النسخة بلا نموذج الغناء، لذا يبقى الصوت صامتًا ما دام هذا الخيار مفعّلًا. أطفئه.'**
  String get singingKeepNoModel;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات تُسمع بلا تصفية'**
  String get fixFilterAppsTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'التطبيقات التي تختارها هنا تُسمع كما هي: بلا تصفية وبلا إسكات. مثلًا: تطبيق مكالمات الفيديو، حتى لا يتأخّر الصوت في المكالمات.'**
  String get fixFilterAppsBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تطبيق'**
  String get fixAddApp;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إزالة {app}'**
  String fixRemoveApp(Object app);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُختر أي تطبيق.'**
  String get fixNoApps;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختر تطبيقًا'**
  String get fixPickTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على تطبيق آخر.'**
  String get fixPickEmpty;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'التطبيقات التي تُشغّل صوتًا الآن، والتي اختيرت من قبل.'**
  String get fixPickPlayingDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get fixCancel;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات بلا تمويه'**
  String get fixBlurAppsTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا تغطية ما دام أحد هذه التطبيقات يملأ الشاشة، مثل تطبيق الخرائط أو تطبيق البنك. وتعود التغطية فور مغادرته، أو كلما لم تتيقّن واعية من التطبيق الظاهر.'**
  String get fixBlurAppsBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج الإعداد لمرة واحدة: من دونه لا تعرف واعية أي تطبيق على الشاشة، فيبقى التمويه في كل مكان.'**
  String get fixBlurAppsNeedsSetup;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مساعد واعية لا يعمل، فلا يمكن معرفة التطبيق الظاهر على الشاشة. يبقى التمويه في كل مكان حتى يُشغَّل المساعد من جديد من صفحة الإعداد.'**
  String get fixBlurAppsHelperMode;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تغطية جزء باليد'**
  String get fixHandTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أثناء عمل التمويه يمكنك تغطية جزء من الشاشة بنفسك، مثل صورة فاتت التمويه: اضغط «تغطية جزء» واسحب إصبعك فوقها. تبقى مغطّاة حتى تزيلها أو يتوقف التمويه.'**
  String get fixHandBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'متاح أثناء عمل التمويه: التصفية تعمل وأحد خيارات التمويه مفعّل.'**
  String get fixHandNotRunning;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تغطية جزء'**
  String get fixCoverArea;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إزالة التغطية اليدوية ({count})'**
  String fixRemoveCovers(Object count);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل خطأ'**
  String get fixNoteTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حين تخطئ واعية، اضغط على ما حدث، مثل «مرّت موسيقى». تحفظ الملاحظة الوقت والتطبيق والإعدادات، لتساعد على معرفة السبب. وتبقى على هذا الجهاز ولا تُرسَل أبدًا.'**
  String get fixNoteBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مرّت موسيقى'**
  String get fixMissedSound;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حُذف صوت خطأً'**
  String get fixWrongSound;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'بقي شيء دون تغطية'**
  String get fixMissedScreen;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'غُطّي خطأً'**
  String get fixWrongScreen;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'سُجّلت الملاحظة (عدد الملاحظات على هذا الجهاز: {count}).'**
  String fixNoted(Object count);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات على هذا الجهاز: {count}'**
  String fixNotesCount(Object count);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'عرض الملاحظات'**
  String get fixNotesShow;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظات'**
  String get fixNotesDelete;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حذف كل الملاحظات؟ لا يمكن التراجع عن ذلك.'**
  String get fixNotesDeleteAsk;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الأخطاء'**
  String get fixNotesTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة'**
  String get worshipTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختياري. تُحسب على هذا الهاتف من المكان الذي تختاره، ولا يُرسَل شيء.'**
  String get worshipBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'المكان: {place}'**
  String worshipPlace(Object place);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'المكان: لم يُختر بعد'**
  String get worshipPlaceNone;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختيار'**
  String get worshipChoose;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مدينة'**
  String get worshipPlaceSearch;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم توجد مدينة بهذا الاسم. يمكنك إدخال الإحداثيات بدلًا من ذلك.'**
  String get worshipPlaceNoMatch;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إدخال الإحداثيات'**
  String get worshipPlaceCustom;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض (شمال +، جنوب −)'**
  String get worshipLat;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول (شرق +، غرب −)'**
  String get worshipLon;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية، مثل Africa/Cairo'**
  String get worshipZone;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من الأرقام ومن المنطقة الزمنية.'**
  String get worshipCustomInvalid;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن استخدام هذا المكان. اختره من جديد.'**
  String get worshipPlaceInvalid;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب: {method}'**
  String worshipMethod(Object method);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get worshipMethodTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختيرت حسب بلد المدينة. اختر ما يتبعه مسجدك.'**
  String get worshipMethodNote;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'العصر: {rule}'**
  String worshipAsr(Object rule);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'وقت العصر'**
  String get worshipAsrTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الجمهور (الشافعي والمالكي والحنبلي)'**
  String get worshipAsrStandard;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الحنفي'**
  String get worshipAsrHanafi;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get worshipMethodMwl;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الجمعية الإسلامية لأمريكا الشمالية (ISNA)'**
  String get worshipMethodIsna;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية العامة للمساحة'**
  String get worshipMethodEgypt;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى، مكة المكرمة'**
  String get worshipMethodUmmAlQura;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية، كراتشي'**
  String get worshipMethodKarachi;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'معهد الجيوفيزياء، جامعة طهران'**
  String get worshipMethodTehran;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'منطقة الخليج'**
  String get worshipMethodGulf;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get worshipMethodKuwait;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get worshipMethodQatar;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة (المجلس الإسلامي MUIS)'**
  String get worshipMethodSingapore;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تركيا (رئاسة الشؤون الدينية)'**
  String get worshipMethodTurkey;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'فرنسا (اتحاد المنظمات الإسلامية، 12°)'**
  String get worshipMethodFrance;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'المغرب (وزارة الأوقاف)'**
  String get worshipMethodMorocco;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إندونيسيا (وزارة الشؤون الدينية)'**
  String get worshipMethodIndonesia;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ماليزيا (JAKIM)'**
  String get worshipMethodMalaysia;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'دبي'**
  String get worshipMethodDubai;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get worshipToday;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا أوقات صلاة هنا اليوم: الشمس لا تشرق أو لا تغرب.'**
  String get worshipNoTimes;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'صامت في أوقات الصلاة'**
  String get worshipSilentTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'عند كل وقت صلاة يصبح الهاتف صامتًا («عدم الإزعاج») للدقائق المحدّدة أدناه، ثم يعود كما كان. مثلًا: من الظهر الساعة 12:00 حتى 12:20.'**
  String get worshipSilentBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مدة الصمت بالدقائق: {minutes}'**
  String worshipSilentMinutes(Object minutes);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'كتم الوسائط عند الأذان'**
  String get worshipMuteTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'عند وقت كل صلاة، يُكتم صوت الوسائط (الفيديو والصوتيات والألعاب) للمدة أدناه. ويمكن إلغاء الكتم فورًا من الإشعار.'**
  String get worshipMuteBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مدة الكتم بالدقائق: {minutes}'**
  String worshipMuteMinutes(Object minutes);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get worshipMinutesTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} د'**
  String worshipMinutesOption(Object minutes);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختر المكان أولًا.'**
  String get worshipNeedPlace;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'التالي: {prayer} الساعة {time}'**
  String worshipNext(Object prayer, Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'صامت حتى {time}.'**
  String worshipSilentNow(Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الوسائط مكتومة حتى {time}.'**
  String worshipMutedNow(Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اسمح لواعية بتغيير «عدم الإزعاج»، وإلا فلن يصير الهاتف صامتًا.'**
  String get worshipDndNeeded;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'السماح'**
  String get worshipAllow;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'«المنبّهات والتذكيرات» غير مسموحة لواعية، لذا قد يتأخر كل تغيير حتى 10 دقائق، أو أكثر أثناء سكون الهاتف.'**
  String get worshipExactNeeded;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات متوقفة: لن ترى متى يصير الهاتف صامتًا أو متى يعود.'**
  String get worshipNotificationsNeeded;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'نغمة رنين وصوت إشعارات بسيطان'**
  String get worshipTonesTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لا تستطيع واعية تصفية نغمة الرنين وأصوات الإشعارات، بل استبدالها فقط. اختر نغمة بسيطة بلا موسيقى:'**
  String get worshipTonesBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'نغمة رنين بسيطة {number}'**
  String worshipToneRing(Object number);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'صوت إشعار بسيط {number}'**
  String worshipToneNotification(Object number);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get worshipTonePlay;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'استخدام'**
  String get worshipToneSet;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مستخدَمة'**
  String get worshipToneInUse;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تم.'**
  String get worshipToneDone;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اسمح لواعية بتعديل إعدادات النظام، ثم ارجع واضغط مرة أخرى.'**
  String get worshipTonePermission;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يسمح هذا الهاتف لواعية بتغييرها. في إعدادات الصوت، اختر نغمة اسمها «Waaiya plain».'**
  String get worshipToneFailed;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات الصوت'**
  String get worshipOpenSound;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرد على المكالمات برسالة أثناء الصلاة'**
  String get worshipSmsTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'في دقائق الصمت بعد وقت كل صلاة، يتلقى المتصل الذي يُترك هاتفه يرنّ رسالة واحدة. مرة لكل رقم في كل صلاة، ولا تُرسل أبدًا إلى الأرقام المخفية أو القصيرة.'**
  String get worshipSmsBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'بعد الرنين بالثواني: {seconds}'**
  String worshipSmsDelay(Object seconds);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ثوانٍ من الرنين قبل الرسالة'**
  String get worshipSmsDelayTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'{seconds} ث'**
  String worshipSmsSecondsOption(Object seconds);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة: {text}'**
  String worshipSmsText(Object text);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'رسالتك'**
  String get worshipSmsTextTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'استخدام الرسالة الافتراضية'**
  String get worshipSmsTextDefault;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'كل رد رسالة عادية من شريحتك بسعر باقتك. ولا يُرسل شيء أثناء التجوال.'**
  String get worshipSmsCost;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أنت في التجوال الآن: لن تُرسل رسائل.'**
  String get worshipSmsRoaming;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الردود المرسلة (محفوظة على هذا الهاتف فقط)'**
  String get worshipSmsLogTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get worshipContinue;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لجعل الهاتف صامتًا في أوقات الصلاة، اسمح لواعية بالوصول إلى «عدم الإزعاج» في الصفحة التالية.'**
  String get worshipWhyDnd;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'للعمل في الوقت تمامًا، اسمح لواعية بضبط «المنبّهات والتذكيرات» في الصفحة التالية. وبدونه قد تتأخر التغييرات حتى 10 دقائق.'**
  String get worshipWhyExact;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اسمح بالإشعارات لترى كل تغيير وتستطيع التراجع عنه.'**
  String get worshipWhyNotifications;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لتغيير نغمة الرنين أو صوت الإشعارات، اسمح لواعية بتعديل إعدادات النظام في الصفحة التالية.'**
  String get worshipWhyWrite;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لمعرفة أن مكالمة ترنّ ومعرفة رقمها، تحتاج واعية إذنَي «الهاتف» و«سجلّ المكالمات». لا يخرج شيء من الهاتف إلا ردّك.'**
  String get worshipWhyPhone;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لإرسال ردّك، تحتاج واعية إذن إرسال الرسائل. ولا ترسل إلا هذا الرد، مرة واحدة على الأكثر لكل رقم في كل صلاة.'**
  String get worshipWhySms;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالوصول إلى «عدم الإزعاج»، لذا يبقى الصمت متوقفًا.'**
  String get worshipMissingDnd;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بإذنَي «الهاتف» و«سجلّ المكالمات»، لذا يبقى الرد بالرسائل متوقفًا.'**
  String get worshipMissingPhone;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بإرسال الرسائل، لذا يبقى الرد بالرسائل متوقفًا.'**
  String get worshipMissingSms;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get worshipTryAgain;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حماية في لحظات الضعف'**
  String get protectTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'للحظة ضعف قد تريد فيها إيقاف التصفية. اختر الآن، وأنت هادئ، مدةً للانتظار: عندها لا يُوقف زرّ الإيقاف التصفيةَ فورًا، وتقرّر من جديد حين تنتهي المدة. ويمكن للوالدين أيضًا وضع رمز.'**
  String get protectBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الانتظار قبل الإيقاف: {value}'**
  String protectDelay(Object value);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الانتظار قبل الإيقاف'**
  String get protectDelayTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا مع 30 دقيقة: تضغط زرّ الإيقاف، لكن التصفية تبقى تعمل. بعد 30 دقيقة تسألك هذه الصفحة: أما زلت تريد الإيقاف؟ اضغط «أكِّد» خلال 15 دقيقة فتتوقف، وإلا فلن يتغيّر شيء. وكذلك إطفاء التغطية أو أي حماية أخرى. أما التشغيل فيسري فورًا دائمًا.'**
  String get protectDelayBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'بلا انتظار'**
  String get protectDelayOff;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة واحدة'**
  String get protectDelay1m;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'5 دقائق'**
  String get protectDelay5m;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'15 دقيقة'**
  String get protectDelay15m;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'30 دقيقة'**
  String get protectDelay30m;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ساعة واحدة'**
  String get protectDelay1h;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'4 ساعات'**
  String get protectDelay4h;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'24 ساعة'**
  String get protectDelay24h;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} د'**
  String protectDelayOther(Object minutes);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري: غير مضبوط'**
  String get protectPinNone;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري: مضبوط'**
  String get protectPinIsSet;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ضع رمزًا'**
  String get protectPinSet;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get protectPinRemove;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مع الرقم السري، يُطلب أولًا قبل إيقاف التصفية أو إطفاء أي حماية. مثلًا: يضع أحد الوالدين رقمًا سريًا حتى لا يستطيع الطفل إيقاف التصفية من واعية (وما لا تستطيع منعه مذكور أدناه). ويُطلب أيضًا لتغيير مدة الانتظار أو الرقم السري نفسه.'**
  String get protectPinBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرقم السري في مكان آمن: إن نُسي فلا سبيل لاسترجاعه. ولا يبقى إلا مسح بيانات واعية أو إعادة تثبيتها، وهذا يمسح كل إعداداتها أيضًا.'**
  String get protectPinForgot;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرقم السري'**
  String get protectPinTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختر رمزًا'**
  String get protectPinNewTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'غيِّر الرقم السري'**
  String get protectPinChangeTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري الحالي'**
  String get protectPinCurrent;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري الجديد (من 4 إلى 8 أرقام)'**
  String get protectPinNew;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري الجديد مرة أخرى'**
  String get protectPinAgain;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'استعمل من 4 إلى 8 أرقام.'**
  String get protectPinBad;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السريان الجديدان غير متطابقين.'**
  String get protectPinDiffer;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'رقم سري خاطئ. المحاولات الباقية قبل التوقّف: {count}.'**
  String protectPinWrong(Object count);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'محاولات خاطئة كثيرة. حاول مرة أخرى عند {time}.'**
  String protectLocked(Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حسنًا'**
  String get protectOk;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get protectCancel;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ألغِ التغيير'**
  String get protectCancelChange;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أكِّد'**
  String get protectConfirm;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'{what}: ينتظر حتى {time}، ثم أكِّده في «الإعدادات».'**
  String protectPending(Object time, Object what);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'{what}: انتهى الانتظار. أما زلت تريده؟ اضغط «أكِّد» قبل {time}، وإلا فلن يتغيّر شيء.'**
  String protectReady(Object time, Object what);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'هذا التغيير ينتظر'**
  String get protectWaitTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'{what} لن يحدث الآن. عند {time}، إن بقيتَ تريده، أكِّده في «الإعدادات» خلال 15 دقيقة. وإن لم تفعل شيئًا فلن يتغيّر شيء.'**
  String protectWaitBody(Object time, Object what);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الانتظار'**
  String get protectWaitStart;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ينتظر بالفعل حتى {time}.'**
  String protectAlreadyWaiting(Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ينتظر حتى {time}، ثم أكِّده في «الإعدادات».'**
  String protectStarted(Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'غدًا عند {time}'**
  String protectTomorrow(Object time);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن: إعدادات الحماية تجعل هذا التغيير ينتظر، أو تطلب الرقم السري.'**
  String get protectHeldBack;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ما لا تستطيع منعه: إعادة تشغيل الهاتف (لا تعود التصفية من تلقاء نفسها)، والإيقاف الإجباري، وإلغاء التثبيت، ومسح بيانات واعية، وإعدادات أندرويد نفسها. منعُ ذلك يحتاج صلاحيات خاصة في أندرويد لا تستعملها واعية. هذه حماية من لحظة ضعف، لا من شخص مُصِرّ.'**
  String get protectLimits;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ما لا تستطيع منعه: أمر waaiya في الطرفية، وإزالة واعية، وحذف مجلد إعداداتها. هذه حماية من لحظة ضعف، لا من شخص مُصِرّ.'**
  String get protectLimitsDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ما لا تستطيع منعه: أمر waaiya-filter.exe في الطرفية، وإزالة واعية، وحذف مجلد إعداداتها. هذه حماية من لحظة ضعف، لا من شخص مُصِرّ.'**
  String get protectLimitsWindows;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التصفية'**
  String get protectWhatStop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إطفاء: {name}'**
  String protectWhatOff(Object name);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل: {name}'**
  String protectWhatOn(Object name);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تطبيق إلى: {name}'**
  String protectWhatApps(Object name);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'جعل التغطية أقل صرامة'**
  String get protectWhatStrictness;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تغيير من يستعمل واعية'**
  String get protectWhatGender;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الانتظار قبل الإيقاف إلى: {value}'**
  String protectWhatDelay(Object value);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم السري'**
  String get protectWhatPinChange;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'حذف الرقم السري'**
  String get protectWhatPinClear;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تغيير إعداد'**
  String get protectWhatSetting;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تزيل واعية الآلات الموسيقية من صوت التطبيقات على هذا الحاسوب، وتُبقي الكلام وتلاوة القرآن. وتُزال أصوات الغناء أيضًا.'**
  String get onboardBodyDesktop;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي'**
  String get worshipUseLocation;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لمعرفة أوقات الصلاة حيث أنت، تقرأ واعية الموقع التقريبي لهذا الهاتف مرة واحدة، الآن. ويُحفظ على الهاتف بوصفه مكانك ولا يُرسل إلى أي جهة.'**
  String get worshipWhyLocation;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد مكانك…'**
  String get worshipLocating;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالموقع. يمكنك البحث عن مدينتك بدلًا من ذلك.'**
  String get worshipLocationDenied;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الموقع مُطفأ في هذا الهاتف. شغّله ثم أعد المحاولة، أو ابحث عن مدينتك.'**
  String get worshipLocationOff;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الموقع'**
  String get worshipLocationSettings;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك. أعد المحاولة بعد قليل، أو ابحث عن مدينتك.'**
  String get worshipLocationFailed;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'قرب {city}'**
  String worshipPlaceNear(Object city);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أوقات محسوبة لتطابق جداول وزارة الأوقاف والشؤون الإسلامية لمدينة {city}.'**
  String worshipHabousNote(Object city);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'افتح واعية'**
  String get trayOpen;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get trayQuit;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'ويندوز لا يسمح لواعية بالبدء عند تسجيل الدخول. فعّل واعية في الإعدادات › التطبيقات › بدء التشغيل، ثم فعّل هذا الخيار من جديد.'**
  String get engineErrorAutostartBlocked;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات هذا الحاسوب، التي اختارها مسؤوله، لا تسمح لواعية بالبدء عند تسجيل الدخول.'**
  String get engineErrorAutostartPolicy;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إظهار نص الإشعارات أثناء التصفية'**
  String get notifTextTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يُخفي أندرويد محتوى الإشعارات ما دام أي تطبيق يسجّل الشاشة كلها، والتصفية تُعدّ من ذلك. عند التفعيل: ترفع واعية هذه الحماية أثناء التصفية فقط، فتقرأ إشعاراتك. وما دامت مرفوعة، يمكن لمشاركة شاشة أخرى في الوقت نفسه أن تُظهر إشعاراتك ورموزك للآخرين أيضًا.'**
  String get notifTextBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أوقف التصفية ثم شغّلها من جديد ليسري هذا التغيير.'**
  String get notifTextNextStart;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'رفض هذا الهاتف التغيير. فعّل بنفسك «إيقاف ميزات الحماية أثناء مشاركة الشاشة» في خيارات المطور.'**
  String get notifTextRefused;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'النص ظاهر: حماية أندرويد متوقفة في خيارات المطور («إيقاف ميزات الحماية أثناء مشاركة الشاشة»). وتبقى متوقفة لكل مشاركة شاشة حتى تعيد تفعيلها هناك.'**
  String get notifTextByHand;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يُخفي أندرويد محتوى الإشعارات أثناء تصفية واعية. بعد الإعداد لمرة واحدة تُظهرها واعية: ترفع هذه الحماية أثناء التصفية فقط.'**
  String get notifTextHowTo;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'فتح خيارات المطور'**
  String get notifTextOpenDev;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'على هذا الهاتف يوقف أندرويد التصفية أيضًا عند قفل الشاشة، فتبقى التطبيقات الأخرى صامتة حتى تضغط «استئناف». والإعداد يمنع ذلك أيضًا.'**
  String get notifTextLockNote;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'اختياري، دون إعداد: فعّل «إيقاف ميزات الحماية أثناء مشاركة الشاشة» في خيارات المطور. ستبقى الحماية متوقفة حينها لكل مشاركة شاشة، وبعض الهواتف ليس فيها هذا المفتاح.'**
  String get notifTextHandOptional;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل: على هذا الهاتف يسأل أندرويد قبل كل تشغيل، ثم يوقف التصفية عند كل قفل للشاشة. لذلك ترفع واعية هذه الحماية أثناء التصفية، فيظهر نص الإشعارات أيضًا. وما دامت مرفوعة، يمكن لمشاركة شاشة أخرى في الوقت نفسه أن تُظهر إشعاراتك ورموزك للآخرين أيضًا.'**
  String get notifTextForced;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'عند التشغيل: «مشاركة تطبيق واحد» ثم واعية'**
  String get oneAppTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'عندما يسألك أندرويد عمّا تشاركه، اختر «مشاركة تطبيق واحد» ثم واعية. تبقى التطبيقات الأخرى مُصفّاة، ويبقى نص الإشعارات مقروءًا، وتستمر التصفية عند قفل الشاشة. أما مع الشاشة كلها فيُخفي أندرويد نص الإشعارات ويوقف التصفية عند كل قفل للشاشة.'**
  String get oneAppBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'لتعمل واعية كاملةً، اقرنها مرة واحدة عبر «تصحيح الأخطاء اللاسلكي» في صفحة الإعداد: عندها تُكتم الموسيقى الأصلية أيضًا، ويكفّ أندرويد عن السؤال عند كل تشغيل.'**
  String get oneAppPair;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'يظهر النص عندما تختار «مشاركة تطبيق واحد» ثم واعية عند التشغيل. أما مع الشاشة كلها فيُخفيه أندرويد، وبعد الإعداد لمرة واحدة ترفع واعية ذلك أثناء التصفية.'**
  String get notifTextOneApp;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أوقف التصفية ثم شغّلها من جديد لاستعمال التمويه: فهو يحتاج إلى الشاشة كلها، وقد بدأت هذه التصفية مع عرض «مشاركة تطبيق واحد».'**
  String get blurNeedsRestart;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات واعية واسمح بالميكروفون'**
  String get micOpenSettings;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أبقِ واعية تعمل'**
  String get keepRunningTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'قد يغلق هذا الهاتف واعية بعد مدة لتوفير البطارية، فيتوقف الترشيح. في إعدادات واعية، تحت «البطارية»، اختر «غير مقيَّد». وفي شاومي وريدمي وبوكو: «بلا قيود»، وفعّل «التشغيل التلقائي» أيضًا.'**
  String get keepRunningBattery;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات واعية متوقفة، فلا تستطيع إخبارك حين يتوقف الترشيح. فعّلها في إعدادات واعية.'**
  String get keepRunningNotifications;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات واعية'**
  String get keepRunningOpen;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'هل يستمر الترشيح عند قفل الشاشة؟'**
  String get lockAskTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'استمرار الترشيح عند قفل الشاشة'**
  String get lockTitle;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'في هذا الهاتف يسأل أندرويد قبل كل تشغيل، ثم يوقف الترشيح عند كل قفل للشاشة. تستطيع واعية منع ذلك برفع «حماية مشاركة الشاشة» في أندرويد أثناء الترشيح، وتعيدها حين يتوقف. وما دامت مرفوعة، فقد تُظهر مشاركة شاشة أخرى في الوقت نفسه (مكالمة فيديو مثلًا) إشعاراتك أيضًا. يسري التغيير عند التشغيل التالي.'**
  String get lockBody;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'استمر في الترشيح'**
  String get lockYes;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أوقفه عند كل قفل'**
  String get lockNo;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أرسل إلى واعية'**
  String get sendToSupport;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'هذا الهاتف أبطأ من أن يصفّي الصوت مباشرة، ولذلك يتقطّع الصوت.'**
  String get stateTooSlowNoLinks;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'الإعداد لمرة واحدة لم يكتمل بعد. بدونه لا تستطيع واعية كتم الصوت الأصلي، فتسمع الموسيقى والصوت المُصفّى معًا.'**
  String get startNoSetupBodyNoLinks;

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'هل تختار انتظارًا مدته {value}؟ من الآن، يحتاج إيقاف الترشيح أو أي حماية إلى انتظار {value}، وكذلك تقصير هذا الانتظار.'**
  String protectDelayLongAsk(String value);

  /// Flutter only. Not reviewed yet except in English.
  ///
  /// In ar, this message translates to:
  /// **'أغلق أندرويد واعية أثناء التصفية، فلم يعد الصوت مُصفّى.'**
  String get keepRunningKilled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'ha',
    'id',
    'it',
    'ms',
    'nl',
    'ru',
    'so',
    'sw',
    'tr',
    'ur',
    'uz',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'ha':
      return AppLocalizationsHa();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'ru':
      return AppLocalizationsRu();
    case 'so':
      return AppLocalizationsSo();
    case 'sw':
      return AppLocalizationsSw();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
