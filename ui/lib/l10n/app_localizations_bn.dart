// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'সব অ্যাপ থেকে বাদ্যযন্ত্র সরিয়ে দেয়, কথা ও তিলাওয়াত রেখে দেয়।';

  @override
  String get onboardTitle => 'স্বাগতম';

  @override
  String get onboardBody =>
      'Waaiya এই ফোনের সব অ্যাপের শব্দ থেকে বাদ্যযন্ত্র সরিয়ে দেয়। কথা ও কুরআন তিলাওয়াত রেখে দেওয়া হয়। আপাতত গানের কণ্ঠও সরিয়ে দেওয়া হয়।';

  @override
  String get onboardQuestion => 'আমি';

  @override
  String get genderMan => 'পুরুষ';

  @override
  String get genderWoman => 'নারী';

  @override
  String get onboardWhy =>
      'এটি শুধু ঠিক করে আপনি কোন ঐচ্ছিক সেটিংস দেখবেন। যেমন, “নারীদের গান নীরব করুন” শুধু পুরুষদের দেখানো হয়। পরে এটি বদলাতে পারবেন।';

  @override
  String get stateOnTitle => 'ফিল্টারিং চালু আছে';

  @override
  String get stateOffTitle => 'ফিল্টারিং বন্ধ আছে';

  @override
  String get stateStarting => 'চালু হচ্ছে…';

  @override
  String stateOnDetail(int delayMs) {
    return 'সব অ্যাপ থেকে বাদ্যযন্ত্র সরানো হচ্ছে। শব্দ প্রায় $delayMs মিলিসেকেন্ড দেরিতে আসে (১০০০ মিলিসেকেন্ডে এক সেকেন্ড)।';
  }

  @override
  String get stateOffDetail => 'চালু করতে বোতামে ট্যাপ করুন।';

  @override
  String get stateModelFailed =>
      'শব্দের মডেল লোড হয়নি, তাই নিরাপত্তার জন্য শব্দ বন্ধ রাখা হয়েছে।';

  @override
  String get stateCaptureDenied =>
      'অন্য অ্যাপের শব্দ পেতে মাইক্রোফোনের অনুমতি দরকার।';

  @override
  String get stateStoppedBySystem =>
      'Android ফিল্টারিং বন্ধ করে দিয়েছে। আবার চালু করতে বোতামে ট্যাপ করুন।';

  @override
  String get stateSilencedTitle => 'ফিল্টারিং বন্ধ হয়েছে';

  @override
  String get stateSilenced =>
      'ফিল্টারিং বন্ধ হয়েছে: অন্য অ্যাপগুলো নীরব করা আছে। আবার চালু করতে বোতামে ট্যাপ করুন, অথবা ফিল্টার ছাড়া শুনতে “বন্ধ করুন” চাপুন।';

  @override
  String get releaseSilence => 'বন্ধ করুন: ফিল্টার ছাড়া অ্যাপ শুনুন';

  @override
  String get powerStartCd => 'ফিল্টারিং চালু করুন';

  @override
  String get powerStopCd => 'ফিল্টারিং বন্ধ করুন';

  @override
  String get captureHint =>
      'Android আপনার স্ক্রিন শেয়ার করার অনুমতি চাইবে। শুধু শব্দ ব্যবহার করা হয়: কিছুই রেকর্ড বা পাঠানো হয় না।';

  @override
  String get needRecordAudio =>
      'অন্য অ্যাপের শব্দ পেতে Waaiya-র মাইক্রোফোনের অনুমতি দরকার। এটি কখনো আপনার কথা রেকর্ড করে না।';

  @override
  String get setupBannerTitle => 'আর একটি ধাপ';

  @override
  String get setupBannerBody =>
      'নিচের এককালীন সেটআপ ছাড়া আপনি মিউজিক ও ফিল্টার করা শব্দ একসাথে শুনবেন।';

  @override
  String get step1Title => 'Shizuku ইনস্টল করুন';

  @override
  String get step1Body => 'Play Store-এর একটি ফ্রি সহায়ক অ্যাপ।';

  @override
  String get step1Action => 'Shizuku নিন';

  @override
  String get step2Title => 'Shizuku চালু করুন';

  @override
  String get step2Body =>
      'Shizuku ওয়াই-ফাই-এর মাধ্যমে Android-এর ওয়্যারলেস ডিবাগিং দিয়ে চালু হয়। ধাপগুলো দেখতে বোতামে ট্যাপ করুন, তারপর ফিরে আসুন।';

  @override
  String get step2Action => 'Shizuku খুলুন';

  @override
  String get step2Update => 'Shizuku আপডেট করুন';

  @override
  String get step2TooOld =>
      'আপনার Shizuku সংস্করণ অনেক পুরোনো। Play Store থেকে আপডেট করুন।';

  @override
  String get step2Denied =>
      'Shizuku-তে Waaiya সবসময় প্রত্যাখ্যান করার জন্য সেট করা আছে। Shizuku-তে অ্যাপের তালিকায় এটিকে অনুমতি দিন।';

  @override
  String get step3Title => 'অনুমতি প্রদান করুন';

  @override
  String get step3Body => 'একবার ট্যাপ করুন, তারপর “অনুমতি দিন” বেছে নিন।';

  @override
  String get step3Action => 'অনুমতি প্রদান করুন';

  @override
  String get step3Busy => 'সেটআপ হচ্ছে…';

  @override
  String get setupDoneRestart =>
      'হয়ে গেছে। এটি কার্যকর করতে একবার ফিল্টারিং বন্ধ করে আবার চালু করুন।';

  @override
  String setupFailed(String details) {
    return 'সেটআপ শেষ হয়নি। বিস্তারিত:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Shizuku-র অনুমতি দেওয়া হয়নি। আবার চেষ্টা করতে বোতামে ট্যাপ করুন।';

  @override
  String get setupSlow =>
      'Shizuku স্বাভাবিকের চেয়ে বেশি সময় নিচ্ছে। অপেক্ষা করুন: কিছু ফোনে প্রথমবার এর সহায়ক চালু হতে এক মিনিট পর্যন্ত লাগে।';

  @override
  String get setupTimeout =>
      'Shizuku ২ মিনিটের মধ্যে সাড়া দেয়নি। Shizuku খুলুন, দেখুন এটি চলছে বলে দেখাচ্ছে কি না, তারপর আবার বোতামে ট্যাপ করুন। সেটআপ পরে শেষ হলে এই স্ক্রিন নিজেই আপডেট হবে।';

  @override
  String get setupRefusedXiaomi =>
      'এই ফোন অনুমতিগুলো দেয়নি। Xiaomi, Redmi ও POCO-তে ডেভেলপার বিকল্প-এ “USB debugging (Security settings)” (USB ডিবাগিং, নিরাপত্তা সেটিংস) চালু করুন (এটি Xiaomi অ্যাকাউন্টে সাইন ইন করতে বলবে), তারপর আবার চেষ্টা করুন।';

  @override
  String get setupRefusedColoros =>
      'এই ফোন অনুমতিগুলো দেয়নি। OPPO, OnePlus ও realme-তে ডেভেলপার বিকল্প-এ “Disable permission monitoring” (অনুমতি পর্যবেক্ষণ বন্ধ করুন) চালু করুন (নতুন সংস্করণে এর নাম “Disable system optimization” (সিস্টেম অপ্টিমাইজেশন বন্ধ করুন), আর হয়তো শুধু ফোনের ভাষা ইংরেজি থাকলেই দেখা যায়)। খুঁজে পেতে সেটিংস-এ “permission” লিখে সার্চ করুন। তারপর আবার চেষ্টা করুন।';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi ও POCO: বিজ্ঞপ্তিতে কোড লেখার ঘর না থাকলে বিজ্ঞপ্তির সেটিংসে বিজ্ঞপ্তির স্টাইল “Android” করুন, অথবা স্প্লিট স্ক্রিনে Waaiya-তে কোড লিখুন।';

  @override
  String get stepDoneCd => 'সম্পন্ন';

  @override
  String stepTodoCd(int step) {
    return 'ধাপ $step';
  }

  @override
  String get computerToggle => 'বরং কম্পিউটার ব্যবহার করুন';

  @override
  String get computerBody =>
      'USB ডিবাগিং চালু করুন, ফোনটি সংযুক্ত করুন এবং চালান:';

  @override
  String get copy => 'কপি করুন';

  @override
  String get copied => 'কপি হয়েছে';

  @override
  String get computerNote =>
      'দ্বিতীয় লাইনটি ঐচ্ছিক: এটি প্রতিবার চালুর সময় স্ক্রিন শেয়ারের প্রশ্ন বন্ধ করে।';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingSilenceTitle =>
      'যে অ্যাপ ফিল্টার করতে দেয় না, সেগুলো নীরব করুন';

  @override
  String get settingSilenceBody =>
      'প্রস্তাবিত। কিছু অ্যাপ তাদের শব্দ ফিল্টার করতে দেয় না; মিউজিক শুনতে দেওয়ার বদলে এটি সেগুলো নীরব করে।';

  @override
  String get settingHoldSilenceTitle =>
      'ফিল্টারিং নিজে থেকে বন্ধ হলে অ্যাপগুলো নীরব রাখুন';

  @override
  String get settingHoldSilenceBody =>
      'প্রস্তাবিত। Android (আপনি নন) ফিল্টারিং বন্ধ করলে, আবার চালু করা বা “বন্ধ করুন” চাপা পর্যন্ত অন্য অ্যাপগুলো নীরব থাকে, ফিল্টার ছাড়া মিউজিক বাজায় না। এককালীন সেটআপ দরকার।';

  @override
  String get settingStereoTitle => 'স্টেরিও শব্দ';

  @override
  String get settingStereoBody =>
      'বন্ধ: মোনো, যা প্রায় অর্ধেক ব্যাটারি খরচ করে এবং বেশি ফোনে ঠিকমতো চলে। চালু: বাম ও ডান দিক আলাদা রাখে। ফোন স্টেরিওর জন্য বেশি ধীর হলে এটি নিজেই মোনোতে চলে যায়।';

  @override
  String get settingSingingTitle => 'নারীদের গান নীরব করুন';

  @override
  String get settingSingingBody =>
      'যেমন, কোনো নারীর গাওয়া গান নীরব করা হয়, কিন্তু কোনো নারী বক্তব্য দিলে তা ঠিকই শোনা যায়।';

  @override
  String get settingSingingNoModel =>
      'এই সংস্করণে গান শনাক্তকারী নেই, তাই এটি চালু থাকলে সব কণ্ঠ নীরব করা হয়।';

  @override
  String get settingRestart =>
      'পরিবর্তন কার্যকর করতে ফিল্টারিং বন্ধ করে আবার চালু করুন।';

  @override
  String get settingGenderTitle => 'আমি';

  @override
  String get change => 'বদলান';

  @override
  String get playerTitle => 'একদম মিলিয়ে ভিডিও';

  @override
  String get playerBody =>
      'কোনো ভিডিও Waaiya-তে শেয়ার করুন (বা “এর মাধ্যমে খুলুন” ব্যবহার করুন), কোনো বিলম্ব ছাড়াই ফিল্টার করে দেখতে।';

  @override
  String get licences => 'ওপেন সোর্স লাইসেন্স';

  @override
  String get licencesIntro =>
      'Waaiya হলো GNU Affero General Public License v3 বা পরবর্তী সংস্করণের অধীনে একটি ফ্রি সফটওয়্যার। সোর্স কোড: https://github.com/oksyassine/waaiya';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (প্রশিক্ষণের ডেটা): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'সম্পূর্ণ লেখা';

  @override
  String get back => 'ফিরে যান';

  @override
  String get linkEntryTitle => 'লিংক খুলুন';

  @override
  String get linkEntryBody =>
      'YouTube, TikTok বা Instagram-এর লিংক পেস্ট করুন, মিউজিক ছাড়া দেখতে বা সেভ করতে।';

  @override
  String get linkTitle => 'লিংক খুলুন';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'ভিডিও বা অডিওর লিংক';

  @override
  String get linkPaste => 'পেস্ট করুন';

  @override
  String get linkOpen => 'খুলুন';

  @override
  String get linkResolving => 'লিংক খোলা হচ্ছে…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'মিউজিক ছাড়া দেখুন';

  @override
  String get linkSave => 'মিউজিক ছাড়া সেভ করুন';

  @override
  String get linkListen => 'মিউজিক ছাড়া শুনুন';

  @override
  String get linkAudioOnly =>
      'এই লিংকের ভিডিও এখনো খোলা যায় না: শুধু এর শব্দ।';

  @override
  String get linkDownloading => 'ডাউনলোড হচ্ছে…';

  @override
  String get linkFiltering => 'মিউজিক সরানো হচ্ছে…';

  @override
  String get linkCancel => 'বাতিল';

  @override
  String get linkCancelled => 'বাতিল হয়েছে। কিছুই সেভ হয়নি।';

  @override
  String get linkTimedOut =>
      'Android সেভ করা বন্ধ করে দিয়েছে: এ ধরনের কাজ এটি দিনে মাত্র কয়েক ঘণ্টা করতে দেয়। কিছুই সেভ হয়নি; Waaiya খুলে আবার চেষ্টা করুন।';

  @override
  String get linkExportFailed => 'এটি সেভ করা যায়নি। কিছুই সেভ হয়নি।';

  @override
  String get linkSaved => 'মিউজিক ছাড়া সেভ হয়েছে';

  @override
  String get linkSavedVideo => 'আপনার গ্যালারিতে: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'আপনার মিউজিকে: Music › Waaiya';

  @override
  String get linkPlay => 'চালান';

  @override
  String get linkShare => 'শেয়ার করুন';

  @override
  String get linkShareNote =>
      'শুধু সেই ভিডিওগুলো শেয়ার করুন, যেগুলো শেয়ার করার অনুমতি আপনার আছে।';

  @override
  String get linkLive => 'লাইভ স্ট্রিম সেভ করা যায় না।';

  @override
  String get linkBusy =>
      'আরেকটি ভিডিও সেভ হচ্ছে। সেটি শেষ হওয়া পর্যন্ত অপেক্ষা করুন।';

  @override
  String get linkInvalid => 'একটি ওয়েব লিংক পেস্ট করুন (https:// দিয়ে শুরু)।';

  @override
  String get linkLogin =>
      'অ্যাকাউন্ট ছাড়া সাইটটি এই ভিডিও দেখায়নি। পাবলিক পোস্ট সাধারণত খোলে: কয়েক মিনিট পরে আবার চেষ্টা করুন। প্রাইভেট পোস্ট খোলা যায় না।';

  @override
  String get linkUnsupported => 'এই সাইট সমর্থিত নয়।';

  @override
  String get linkPlaylist => 'এটি একটি প্লেলিস্ট। একটি ভিডিও খুলুন।';

  @override
  String get linkNoFormat =>
      'এই ভিডিওর ফরম্যাট Waaiya এখনো ফিল্টার করতে পারে না।';

  @override
  String get linkFailed =>
      'এই লিংক খোলা যায়নি। আপনার সংযোগ দেখে আবার চেষ্টা করুন।';

  @override
  String get linkPlayFailed =>
      'এটি চালানো যায়নি। ফিল্টার ছাড়া কিছুই চালানো হয়নি।';

  @override
  String get linkLimited =>
      'সাইটটি এখন অনুরোধ সীমিত করছে। কয়েক মিনিট পরে আবার চেষ্টা করুন।';

  @override
  String get blurTitle => 'স্ক্রিন ব্লার';

  @override
  String get blurBody =>
      'ফিল্টারিং চালু থাকাকালে সব অ্যাপে স্ক্রিনের মানুষ ও ছবি ঢেকে দেয়। এটি ফোনেই চলে; কিছুই কোথাও পাঠানো হয় না।';

  @override
  String get blurWomenTitle => 'নারীদের ব্লার করুন';

  @override
  String get blurWomenBody =>
      'পুরো শরীর ঢেকে দেয়। কেউ পুরুষ কিনা অ্যাপ নিশ্চিত না হলে, তাকেও ঢেকে দেয়।';

  @override
  String get blurNudityTitle => 'অশালীন ছবি ব্লার করুন';

  @override
  String get blurNudityBody =>
      'যে কারও নগ্নতা বা খোলামেলা পোশাক: পুরো স্ক্রিন ঢেকে দেওয়া হয়।';

  @override
  String get blurFailTitle => 'ব্লার তাল রাখতে না পারলে স্ক্রিন ঢেকে দিন';

  @override
  String get blurFailBody =>
      'চালু: ফোন বেশি ধীর হলে বা ব্লার ব্যর্থ হলে পুরো স্ক্রিন ঢেকে দেওয়া হয়। বন্ধ: একটি সতর্কবার্তাসহ স্ক্রিন দেখা যায়।';

  @override
  String get blurSetupShizuku => 'Shizuku দিয়ে অনুমতি দিন';

  @override
  String get blurSetupManual => 'Android সেটিংসে অনুমতি দিন';

  @override
  String get blurStatusNeedsSetup =>
      'ব্লার করতে Waaiya-কে অন্য অ্যাপের উপরে আঁকতে হয়। সবচেয়ে ভালো: “Shizuku দিয়ে অনুমতি দিন”, যাতে আপনার ট্যাপ তখনও ব্লারের নিচের অ্যাপে পৌঁছায়। অথবা “Android সেটিংসে অনুমতি দিন”, কিন্তু তখন ব্লার করা জায়গায় ট্যাপ করলে কিছুই হয় না।';

  @override
  String get blurStatusNeedsOverlay =>
      'ব্লার করতে Waaiya-কে অন্য অ্যাপের উপরে আঁকতে হয়। সবচেয়ে ভালো: Shizuku চালু করুন এবং সেখানে Waaiya-কে অনুমতি দিন, যাতে আপনার ট্যাপ তখনও ব্লারের নিচের অ্যাপে পৌঁছায়। অথবা Android সেটিংসে “অন্যান্য অ্যাপের উপরে দেখানো” অনুমতি দিন, কিন্তু তখন ব্লার করা জায়গায় ট্যাপ করলে কিছুই হয় না।';

  @override
  String get blurFailUnavailable =>
      'আপাতত ধূসর: পুরো স্ক্রিনের কভার সব ট্যাপ আটকে দেবে এবং আপনি আটকে যেতে পারেন। Waaiya-র সহায়ক বা Shizuku (Android 12 বা নতুন) চালু করুন, তখন এটি চালু হবে: কভারগুলো এমনভাবে আঁকা হয় যে ট্যাপ এর ভেতর দিয়ে চলে যায়। ততক্ষণ ব্লার তাল রাখতে না পারলে একটি সতর্কবার্তাসহ স্ক্রিন দেখা যায়।';

  @override
  String get blurFailNeedsA11y =>
      'আপাতত ধূসর: পুরো স্ক্রিনের কভার সব ট্যাপ আটকে দেবে এবং আপনি আটকে যেতে পারেন। Shizuku (Android 12 বা নতুন) চালু করুন অথবা Waaiya Blur অ্যাক্সেসিবিলিটি সার্ভিস চালু করুন (উপরে “Shizuku দিয়ে অনুমতি দিন”), তখন এটি চালু হবে। ততক্ষণ একটি সতর্কবার্তাসহ স্ক্রিন দেখা যায়।';

  @override
  String get languageTitle => 'ভাষা';

  @override
  String settingLanguageTitle(String language) {
    return 'ভাষা: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'ব্লারের সেটিংস কার্যকর করতে ফিল্টারিং বন্ধ করে আবার চালু করুন।';

  @override
  String get blurStatusStarting => 'ব্লার চালু হচ্ছে…';

  @override
  String get blurStatusOn => 'ব্লার চালু আছে।';

  @override
  String get blurStatusOnVisible =>
      'ব্লার চালু আছে, সতর্ক মোডে: এই ফোন নিজের স্ক্রিন ক্যাপচারে ব্লার দেখায়, তাই দৃশ্য না বদলানো পর্যন্ত ব্লার করা জায়গা ব্লারই থাকে।';

  @override
  String get blurStatusModels =>
      'বেছে নেওয়া বিকল্পের জন্য এই সংস্করণে ব্লার মডেল নেই।';

  @override
  String get blurStatusFailing => 'ব্লার এখন তাল রাখতে পারছে না।';

  @override
  String get blurStatusNoOverlay =>
      'ব্লার অন্য অ্যাপের উপরে আঁকতে পারছে না: উপরে অনুমতি দিন।';

  @override
  String blurStatusNoCapture(String details) {
    return 'ব্লার স্ক্রিন দেখতে পারছে না। বিস্তারিত:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku অনুমতি দিতে পারেনি:\n$details';
  }

  @override
  String get step2Guide => 'কীভাবে Shizuku চালু করবেন';

  @override
  String get blurFailOldAndroid =>
      'ধূসর: এই Android সংস্করণে পুরো স্ক্রিনের কভার সব ট্যাপ আটকে দেবে এবং আপনি আটকে যেতে পারেন (Shizuku-র কভারের জন্য Android 12 বা নতুন দরকার)। ব্লার তাল রাখতে না পারলে একটি সতর্কবার্তাসহ স্ক্রিন দেখা যায়।';

  @override
  String get guideTitle => 'Shizuku চালু করুন, ধাপে ধাপে';

  @override
  String get guideOpenDev => 'ডেভেলপার বিকল্প';

  @override
  String get guideOpenShizuku => 'Shizuku খুলুন';

  @override
  String get guideClose => 'বন্ধ করুন';

  @override
  String get guideBody =>
      'ওয়াই-ফাই এবং Android 11 বা নতুন দরকার। পেয়ারিং একবারই করতে হয়; ফোন রিস্টার্টের পর শুধু ধাপ ৭ আবার করবেন।\n\n১. ফোনটি ওয়াই-ফাই-এ সংযুক্ত করুন।\n\n২. ডেভেলপার বিকল্প চালু করুন: সেটিংস › ফোন সম্পর্কে › “Software information” (সফটওয়্যার তথ্য) › “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন। (অন্য ফোনে: সেটিংস › ফোন সম্পর্কে › বিল্ড নম্বর।)\n\n৩. Shizuku খুলুন। বিজ্ঞপ্তি দেখানোর অনুমতি চাইলে অনুমতি দিন: পেয়ারিং কোড Shizuku-র একটি বিজ্ঞপ্তিতে লিখতে হয়।\n\n৪. Shizuku-তে “Start via Wireless debugging” (ওয়্যারলেস ডিবাগিং দিয়ে চালু)-এর নিচে “Pairing” (পেয়ারিং)-এ ট্যাপ করুন। যে পেজ খুলবে, সেখানে “ডেভেলপার বিকল্প”-এ ট্যাপ করুন, “ওয়্যারলেস ডিবাগিং” চালু করুন এবং “অনুমতি দিন” দিয়ে নিশ্চিত করুন।\n\n৫. “ওয়্যারলেস ডিবাগিং” লেখাটিতে ট্যাপ করুন (সুইচে নয়), তারপর “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন”। একটি ৬ অঙ্কের কোড দেখা যাবে।\n\n৬. সেই স্ক্রিন খোলা রেখে বিজ্ঞপ্তিগুলো নিচে টানুন। Shizuku-র বিজ্ঞপ্তিতে “Pairing service found” (পেয়ারিং সার্ভিস পাওয়া গেছে) দেখালে “Enter pairing code” (পেয়ারিং কোড লিখুন)-এ ট্যাপ করে কোডটি লিখুন। Shizuku জানাবে পেয়ারিং সফল হয়েছে।\n\n৭. Shizuku-তে ফিরে গিয়ে “Start via Wireless debugging”-এর নিচে “Start” (চালু করুন)-এ ট্যাপ করুন। “Shizuku is running” (Shizuku চলছে) দেখানো পর্যন্ত অপেক্ষা করুন।\n\n৮. Waaiya-তে ফিরে এসে “অনুমতি প্রদান করুন”-এ ট্যাপ করুন, তারপর “অনুমতি দিন”।\n\nফোন রিস্টার্ট হলে Shizuku বন্ধ হয়ে যায়: ওয়াই-ফাই-এ সংযুক্ত হোন, “ওয়্যারলেস ডিবাগিং” বন্ধ থাকলে আবার চালু করুন, Shizuku খুলে “Start”-এ ট্যাপ করুন। নতুন করে পেয়ারিং লাগবে না।';

  @override
  String get wsetupRouteTitle => 'এই ফোনেই সেটআপ করুন';

  @override
  String get wsetupRouteBody =>
      'চারটি ছোট ধাপ, একবারই। কোনো বাড়তি অ্যাপ বা কম্পিউটার লাগবে না। প্রতিটি ধাপ শেষ হলে Waaiya টিক দেয়।';

  @override
  String get wizDevTitle => 'ডেভেলপার বিকল্প চালু করুন';

  @override
  String get wizDevBody =>
      'ফোন সম্পর্কে-তে “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন, তারপর এখানে ফিরে আসুন। খুঁজে না পেলে সেটিংস-এ “বিল্ড নম্বর” লিখে সার্চ করুন।';

  @override
  String get wizDevBodySamsung =>
      'ফোন সম্পর্কে › “Software information” (সফটওয়্যার তথ্য)-তে “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন, তারপর এখানে ফিরে আসুন।';

  @override
  String get wizDevBodyXiaomi =>
      'ফোন সম্পর্কে-তে “OS version” (OS সংস্করণ)-এ ৭ বার ট্যাপ করুন (পুরোনো ফোনে “MIUI version” (MIUI সংস্করণ); কিছু ফোনে এটি “Detailed info and specs” (বিস্তারিত তথ্য ও স্পেসিফিকেশন)-এর ভেতরে), তারপর এখানে ফিরে আসুন।';

  @override
  String get wizDevBodyColoros =>
      '“About device” (ডিভাইস সম্পর্কে) (বা ফোন সম্পর্কে) › “Version” (সংস্করণ)-এ “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন, তারপর এখানে ফিরে আসুন।';

  @override
  String get wizDevBodyVivo =>
      'ফোন সম্পর্কে-তে “Software version” (সফটওয়্যার সংস্করণ)-এ ৭ বার ট্যাপ করুন (কিছু ফোনে: “Software information” (সফটওয়্যার তথ্য) › “বিল্ড নম্বর”), তারপর এখানে ফিরে আসুন।';

  @override
  String get wizDevBodyHuawei =>
      'ফোন সম্পর্কে-তে “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন, তারপর এখানে ফিরে আসুন।';

  @override
  String get wizDevBodyTranssion =>
      '“My phone” (আমার ফোন) (বা ফোন সম্পর্কে)-তে “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন, তারপর এখানে ফিরে আসুন।';

  @override
  String get setupNoteHuawei =>
      'Huawei: অনেক Huawei ফোনে “ওয়্যারলেস ডিবাগিং” নেই। ডেভেলপার বিকল্প-এ খুঁজে না পেলে কম্পিউটার ব্যবহার করুন (নিচে “অন্যান্য উপায়”)।';

  @override
  String get wsetupFilterOn =>
      'ফিল্টারিং চালু আছে: এই Android সংস্করণে এটি চলার সময় বিজ্ঞপ্তিতে কোড লেখা যায় না। আগে ফিল্টারিং বন্ধ করুন, অথবা স্প্লিট স্ক্রিন ও “এখানে কোড লিখুন” ব্যবহার করুন।';

  @override
  String get wizDevSearch =>
      'ফোনের ভাষা অনুযায়ী নাম আলাদা হতে পারে: খুঁজে না পেলে সেটিংস-এর উপরের সার্চ ব্যবহার করুন।';

  @override
  String get wizDevAction => 'ফোন সম্পর্কে খুলুন';

  @override
  String get wizWifiTitle => 'ওয়াই-ফাই-এ সংযুক্ত হোন';

  @override
  String get wizWifiBody =>
      'যেকোনো ওয়াই-ফাই নেটওয়ার্ক হলেই চলবে; ইন্টারনেট লাগবে না।';

  @override
  String get wizWifiAction => 'ওয়াই-ফাই সেটিংস খুলুন';

  @override
  String get wizWdTitle => 'ওয়্যারলেস ডিবাগিং চালু করুন';

  @override
  String get wizWdBody =>
      'Waaiya ডেভেলপার বিকল্প “ওয়্যারলেস ডিবাগিং”-এর জায়গায় খোলে। এটি চালু করে “অনুমতি দিন”-এ ট্যাপ করুন।';

  @override
  String get wizWdAction => 'ডেভেলপার বিকল্প খুলুন';

  @override
  String get wizPairTitle => 'পেয়ারিং কোড লিখুন';

  @override
  String get wizPairBody =>
      '“ওয়্যারলেস ডিবাগিং” লেখাটিতে ট্যাপ করুন, তারপর “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন”। ৬টি অঙ্ক Waaiya-র বিজ্ঞপ্তিতে লিখুন। বাকিটা Waaiya করবে।';

  @override
  String get wizPairBodyPaired =>
      'Waaiya আগেই এই ফোনের সাথে পেয়ার করা আছে: কোড লাগবে না। বোতামে ট্যাপ করুন, Waaiya নিজেই শেষ করবে।';

  @override
  String get wizPairAction => 'চালিয়ে যান';

  @override
  String get wizAgain => 'আবার সেটআপ চালান';

  @override
  String get setupShizukuReadyTitle => 'Shizuku দিয়ে, যা আগে থেকেই চলছে';

  @override
  String get setupOtherWaysPlain => 'সেটআপের অন্যান্য উপায়';

  @override
  String get wizSkip => 'সরাসরি ওয়্যারলেস ডিবাগিং-এ যান';

  @override
  String get setupOtherWays => 'অন্যান্য উপায়: Shizuku বা কম্পিউটার';

  @override
  String get wsetupEnterHere => 'এখানে কোড লিখুন';

  @override
  String get wsetupCancel => 'বাতিল';

  @override
  String get wsetupAndroid10 =>
      'Android 10 নিজে নিজে সেটআপ করতে পারে না: এর জন্য কম্পিউটার লাগে, সরাসরি (নিচে) অথবা একবার Shizuku চালু করতে।';

  @override
  String get wsetupShizukuHeading => 'অথবা Shizuku অ্যাপ দিয়ে';

  @override
  String get wsetupShizukuNote =>
      'Shizuku স্ক্রিনের কভারের ভেতর দিয়েও স্পর্শ যেতে দেয়।';

  @override
  String get wsetupChannel => 'এককালীন সেটআপ';

  @override
  String get wsetupNotifTitle => 'Waaiya সেটআপ: পেয়ারিং কোডের অপেক্ষায়';

  @override
  String get wsetupFoundTitle => 'পেয়ারিং স্ক্রিন পাওয়া গেছে';

  @override
  String get wsetupBusyTitle => 'Waaiya সেটআপ';

  @override
  String get wsetupDoneTitle => 'সেটআপ সম্পন্ন';

  @override
  String get wsetupDoneBody =>
      'Waaiya এখন আসল শব্দ নীরব করতে পারে। আপনি ওয়্যারলেস ডিবাগিং বন্ধ করতে পারেন।';

  @override
  String get wsetupDoneHelperBody =>
      'হয়ে গেছে। এই ফোন অ্যাপকে এই অনুমতিগুলো রাখতে দেয় না, তাই Waaiya-র সহায়ক আসল শব্দ নীরব করে। ফোন রিস্টার্ট হলে এবং Waaiya আপডেট হলে সহায়ক বন্ধ হয়ে যায়। এরপর Waaiya খুললে, ওয়্যারলেস ডিবাগিং চালু থাকলে এটি নিজেই সহায়ক আবার চালু করে; না থাকলে এর জন্য একটি বোতাম দেখায়।';

  @override
  String get helperMissingTitle => 'Waaiya-র সহায়ক বন্ধ আছে';

  @override
  String get helperMissingBody =>
      'এই ফোন Waaiya-র অনুমতিগুলো রাখে না, তাই Waaiya তার সহায়ক ব্যবহার করে। ফোন রিস্টার্ট হলে এবং Waaiya আপডেট হলে সহায়ক বন্ধ হয়ে যায়। ওয়াই-ফাই-এ সংযুক্ত হোন, ডেভেলপার বিকল্প-এ “ওয়্যারলেস ডিবাগিং” চালু করুন, তারপর “Waaiya-র সহায়ক চালু করুন”-এ ট্যাপ করুন।';

  @override
  String get helperChannel => 'Waaiya-র সহায়ক';

  @override
  String get helperStarting => 'সহায়ক চালু হচ্ছে…';

  @override
  String get helperModeNote =>
      'এই ফোন অ্যাপকে এই অনুমতিগুলো রাখতে দেয় না: কাজটি Waaiya-র সহায়ক করে। ফোন রিস্টার্ট হলে এবং Waaiya আপডেট হলে এটি বন্ধ হয়ে যায়। এরপর Waaiya খুললে, ওয়্যারলেস ডিবাগিং চালু থাকলে এটি নিজেই সহায়ক আবার চালু করে; না থাকলে এর জন্য একটি বোতাম দেখায়।';

  @override
  String get helperTipXiaomi =>
      'ঐচ্ছিক, অনুমতিগুলো স্থায়ীভাবে রাখতে (রিস্টার্টের পর সহায়ক লাগবে না): ডেভেলপার বিকল্প-এ “USB debugging (Security settings)” (USB ডিবাগিং, নিরাপত্তা সেটিংস) চালু করুন (এটি Xiaomi অ্যাকাউন্টে সাইন ইন করতে বলবে), তারপর আবার সেটআপ করুন।';

  @override
  String get helperTipColoros =>
      'ঐচ্ছিক, অনুমতিগুলো স্থায়ীভাবে রাখতে (রিস্টার্টের পর সহায়ক লাগবে না): ডেভেলপার বিকল্প-এ “Disable permission monitoring” (অনুমতি পর্যবেক্ষণ বন্ধ করুন) চালু করুন (নতুন সংস্করণে “Disable system optimization” (সিস্টেম অপ্টিমাইজেশন বন্ধ করুন); হয়তো শুধু ফোনের ভাষা ইংরেজি থাকলেই দেখা যায়), তারপর আবার সেটআপ করুন।';

  @override
  String get stateOnHelperMissing =>
      'আসল শব্দ নীরব হয়নি, তাই আপনি ফিল্টার করা শব্দের সাথে মিউজিকও শুনছেন: Waaiya-র সহায়ক বন্ধ আছে। ওয়াই-ফাই-এ সংযুক্ত হোন, ওয়্যারলেস ডিবাগিং চালু করুন, তারপর “Waaiya-র সহায়ক চালু করুন”-এ ট্যাপ করুন।';

  @override
  String get setupRefusedTryWireless =>
      'অথবা এই পেজে “এই ফোনেই সেটআপ করুন” ব্যবহার করুন: তখন ওই সুইচ ছাড়াই Waaiya-র সহায়ক কাজ করে।';

  @override
  String get helperStartAnywayTitle => 'Waaiya-র সহায়ক বন্ধ আছে';

  @override
  String get helperStartAnywayBody =>
      'এটি ছাড়া আপনি ফিল্টার করা শব্দের সাথে মিউজিকও শুনবেন। আগে সহায়ক চালু করুন (ওয়্যারলেস ডিবাগিং চালু থাকতে হবে), অথবা তবুও ফিল্টারিং চালু করুন।';

  @override
  String get wsetupFailedTitle => 'সেটআপ শেষ হয়নি';

  @override
  String get wsetupPairing => 'পেয়ার হচ্ছে…';

  @override
  String get wsetupConnecting => 'সংযুক্ত হচ্ছে ও অনুমতি দেওয়া হচ্ছে…';

  @override
  String get wsetupNeedWifi =>
      'আগে একটি ওয়াই-ফাই নেটওয়ার্কে সংযুক্ত হোন (ইন্টারনেট লাগবে না): ওয়্যারলেস ডিবাগিং শুধু ওয়াই-ফাই-এ কাজ করে।';

  @override
  String get wsetupNeedWirelessDebugging =>
      'ডেভেলপার বিকল্প-এ “ওয়্যারলেস ডিবাগিং” চালু করুন, তারপর এর নামে ট্যাপ করে “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন”-এ ট্যাপ করুন।';

  @override
  String get wsetupOpenDialog =>
      'ওয়্যারলেস ডিবাগিং-এ “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন”-এ ট্যাপ করুন। কোডটি স্ক্রিনে রেখে এখানে “কোড লিখুন”-এ ট্যাপ করুন।';

  @override
  String get wsetupEnterCodeBody =>
      '“কোড লিখুন”-এ ট্যাপ করে সেটিংস-এ দেখানো ৬ অঙ্কের কোডটি লিখুন।';

  @override
  String get wsetupCodeWaiting =>
      'কোড পাওয়া গেছে। “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন” স্ক্রিনের অপেক্ষা চলছে: এটি খোলা রাখুন।';

  @override
  String get wsetupWrongCode =>
      'ওই কোড গ্রহণ করা হয়নি। স্ক্রিনের ৬টি অঙ্ক দেখে আবার লিখুন। পেয়ারিং স্ক্রিন বন্ধ হয়ে গেলে আবার খুলুন: কোড বদলে যায়।';

  @override
  String get wsetupPairingFailed =>
      'পেয়ারিং কাজ করেনি। পেয়ারিং স্ক্রিন বন্ধ করুন, আবার “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন” খুলুন এবং নতুন কোড লিখুন।';

  @override
  String get wsetupWaitingConnect =>
      'পেয়ার হয়েছে। “ওয়্যারলেস ডিবাগিং” চালু রাখুন: Waaiya সংযুক্ত হচ্ছে।';

  @override
  String get wsetupNotPaired =>
      'এই ফোন আর Waaiya-কে চেনে না (পেয়ারিং মুছে ফেলা হয়েছে বা মেয়াদ শেষ)। “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন” খুলে কোড লিখুন।';

  @override
  String get wsetupConnectFailed =>
      'ওয়্যারলেস ডিবাগিং-এ সংযুক্ত হওয়া যায়নি। এটি বন্ধ করে আবার চালু করুন: Waaiya নিজেই আবার চেষ্টা করবে।';

  @override
  String get wsetupGrantFailed =>
      'সংযুক্ত হয়েছে, কিন্তু অনুমতিগুলো এখনো নেই। নিচে Shizuku বা কম্পিউটার ব্যবহার করুন।';

  @override
  String get wsetupTimeout =>
      '১০ মিনিটেও শেষ না হওয়ায় থামানো হয়েছে। আবার চেষ্টা করতে পারেন।';

  @override
  String get wsetupCodeUnreadable => 'পেয়ারিং কোডের ৬টি অঙ্ক লিখুন।';

  @override
  String get wsetupCodeHint => '৬ অঙ্কের কোড';

  @override
  String get wsetupEnterCode => 'কোড লিখুন';

  @override
  String wsetupDetail(String details) {
    return 'বিস্তারিত: $details';
  }

  @override
  String get wsetupErrTimeout => 'সময়মতো কোনো সাড়া নেই';

  @override
  String get wsetupErrRefused => 'সংযোগ প্রত্যাখ্যাত';

  @override
  String get wsetupDevOff =>
      'ডেভেলপার বিকল্প বন্ধ আছে। ফোন সম্পর্কে-তে “বিল্ড নম্বর”-এ ৭ বার ট্যাপ করুন, তারপর ফিরে আসুন।';

  @override
  String get wsetupOpenAbout => 'ফোন সম্পর্কে';

  @override
  String get wsetupNotifOff =>
      'Waaiya-র বিজ্ঞপ্তি বন্ধ আছে, তাই বিজ্ঞপ্তিতে কোড লেখা যাবে না। স্প্লিট স্ক্রিন ব্যবহার করুন (এক অর্ধেকে সেটিংস, অন্য অর্ধেকে Waaiya) এবং “এখানে কোড লিখুন”-এ ট্যাপ করুন।';

  @override
  String get wsetupCodeDialogTitle => 'পেয়ারিং কোড';

  @override
  String get wsetupCodeDialogBody =>
      'শুধু স্প্লিট স্ক্রিনে (এক অর্ধেকে সেটিংস, অন্য অর্ধেকে Waaiya): সেটিংস ছেড়ে গেলে পেয়ারিং স্ক্রিন বন্ধ হয়ে যায় এবং এর কোড আর কাজ করে না। “পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন”-এর নিচে দেখানো ৬ অঙ্কের কোডটি লিখুন।';

  @override
  String get wsetupCodeOk => 'পেয়ার করুন';

  @override
  String get blurStrictTitle => 'কারা ঢাকা থাকবে না';

  @override
  String blurStrictValue(String level) {
    return 'কারা ঢাকা থাকবে না: $level';
  }

  @override
  String get blurStrict0 =>
      'কঠোর: শুধু যাদের অ্যাপ প্রায় নিশ্চিতভাবে পুরুষ মনে করে';

  @override
  String get blurStrict1 => 'মাঝামাঝি: প্রায় দ্বিগুণ পুরুষ খোলা থাকে';

  @override
  String get blurStrict2 => 'শিথিল: মাঝামাঝির চেয়ে আরও কিছু পুরুষ';

  @override
  String get blurStrict0Short => 'কঠোর';

  @override
  String get blurStrict1Short => 'মাঝামাঝি';

  @override
  String get blurStrict2Short => 'শিথিল';

  @override
  String get blurStrictHelp =>
      'অ্যাপ যাকে পুরুষ বলে নিশ্চিত নয়, তাকে ঢেকে দেওয়া হয়। কঠোরে প্রতি ১০০ জনে প্রায় ৭ জন পুরুষ খোলা থাকে; মাঝামাঝিতে প্রায় ১৪, শিথিলে প্রায় ১৬। প্রতিটি কম কঠোর ধাপে প্রতি ১০০ জনে প্রায় আরও ১ জন নারীও খোলা থেকে যায়।';

  @override
  String get stateOnNotMuted =>
      'আসল শব্দ এখনো নীরব হয়নি, তাই আপনি ফিল্টার করা শব্দের সাথে মিউজিকও শুনছেন। নিচের এককালীন সেটআপ শেষ করুন।';

  @override
  String get stateOnMuteFailing =>
      'এখন যে অ্যাপ বাজছে, Waaiya তার আসল শব্দ নীরব করতে পারছে না, তাই মিউজিক এখনো শোনা যেতে পারে। ফিল্টারিং বন্ধ করে আবার চালু করুন। তবুও থাকলে ডায়াগনস্টিক রিপোর্ট পাঠান (এই স্ক্রিনের নিচে)।';

  @override
  String get stateTooSlow =>
      'এই ফোন লাইভ শব্দ ফিল্টার করার জন্য বেশি ধীর, তাই শব্দ কেটে যায়। নিচের “লিংক খুলুন” তবুও কাজ করে: এটি চালানোর আগে ভিডিও ফিল্টার করে।';

  @override
  String get stateMonoNote =>
      'এই ফোন যাতে তাল রাখতে পারে, তাই শব্দ মোনোতে আছে।';

  @override
  String stateBlockedSilenced(String apps) {
    return 'নীরব করা হয়েছে, কারণ এটি ফিল্টার করতে দেয় না: $apps।';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'ফিল্টার ছাড়া বাজছে, কারণ এটি ফিল্টার করতে দেয় না: $apps।';
  }

  @override
  String get stateCaptureFailed =>
      'Android Waaiya-কে অন্য অ্যাপের শব্দ দেয়নি। আবার চালু করতে বোতামে ট্যাপ করুন।';

  @override
  String get stateCaptureCancelled =>
      'Android-এর স্ক্রিন শেয়ারের প্রশ্নে চালু করা বাতিল হয়েছে। শব্দ পেতে Waaiya-র সেখানে “শুরু করুন” দরকার। কিছুই রেকর্ড বা পাঠানো হয় না।';

  @override
  String get startNoSetupTitle => 'মিউজিক তবুও শোনা যাবে';

  @override
  String get startNoSetupBody =>
      'এককালীন সেটআপ এখনো হয়নি। এটি ছাড়া Waaiya আসল শব্দ নীরব করতে পারে না: আপনি মিউজিক ও ফিল্টার করা শব্দ একসাথে শুনবেন।\n\n“লিংক খুলুন” কোনো সেটআপ ছাড়াই কাজ করে।';

  @override
  String get startNoSetupSetup => 'সেটআপ করুন';

  @override
  String get startNoSetupAnyway => 'তবুও চালু করুন';

  @override
  String get diagButton => 'সমস্যা? ডায়াগনস্টিক রিপোর্ট';

  @override
  String get diagTitle => 'ডায়াগনস্টিক রিপোর্ট';

  @override
  String get diagNote =>
      'এই ফোনে Waaiya যা দেখে। এটি কপি করুন বা যিনি আপনাকে সাহায্য করছেন তাঁর সাথে শেয়ার করুন। অ্যাপ নিজে কিছুই পাঠায় না।';

  @override
  String get notifStoppedTitle => 'Waaiya বন্ধ হয়েছে';

  @override
  String get notifStoppedText =>
      'শব্দ আর ফিল্টার হচ্ছে না। আবার চালু করতে ট্যাপ করুন।';

  @override
  String get wsetupGuide => 'ছবিসহ ধাপগুলো';

  @override
  String get navFilter => 'ফিল্টার';

  @override
  String get navScreen => 'স্ক্রিন';

  @override
  String get navLinks => 'লিংক';

  @override
  String get navSetup => 'সেটআপ';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get setupDoneTitle => 'সেটআপ সম্পন্ন';

  @override
  String get setupDoneBody =>
      'Waaiya অন্য অ্যাপের আসল শব্দ নীরব করতে পারে। শুধু কিছু বদলালে আবার করুন (সেটআপ বাতিল হয়ে গেলে, বা Waaiya বললে যে এটি নেই)।';

  @override
  String get setupRedo => 'আবার সেটআপ দেখান';

  @override
  String get setupGo => 'সেটআপে যান';

  @override
  String get helperTitle => 'কভারের ভেতর দিয়ে স্পর্শ';

  @override
  String get helperBodyOff =>
      'সাহায্য ছাড়া কভার তার নিচের স্পর্শ আটকে দেয়। Waaiya-র সহায়ক কভারগুলো এমনভাবে আঁকে যে স্পর্শ ভেতর দিয়ে চলে যায়। ওয়্যারলেস ডিবাগিং চালু করুন (ওয়াই-ফাই লাগবে) এবং বোতামে ট্যাপ করুন; প্রথমবার সেটআপের মতো একবার পেয়ার করুন। ফোন রিস্টার্ট হলে আবার ট্যাপ করুন।';

  @override
  String get helperStart => 'Waaiya-র সহায়ক চালু করুন';

  @override
  String get helperOn =>
      'Waaiya-র সহায়ক কভারগুলো আঁকছে: স্পর্শ এর ভেতর দিয়ে চলে যায়। ফোন রিস্টার্ট হলে বা USB ডিবাগিং বন্ধ করলে এটি থেমে যায়; তখন আবার বোতামে ট্যাপ করুন।';

  @override
  String get helperShizukuOn =>
      'Shizuku কভারগুলো আঁকছে: স্পর্শ এর ভেতর দিয়ে চলে যায়।';

  @override
  String get helperOrShizuku => 'অথবা Shizuku দিয়ে:';

  @override
  String get filterOptionsTitle => 'ফিল্টারের বিকল্প';

  @override
  String get settingsGeneralTitle => 'সাধারণ';

  @override
  String get simpleTitle => 'Simple mode (test): no Developer options';

  @override
  String get simpleBody =>
      'For phones where the setup below is too hard. While Waaiya filters, it mutes the phone\'s media sound and plays the filtered sound on another sound channel. Your volume buttons set Waaiya\'s volume. Android asks to share the screen at each start. The media sound comes back when filtering stops.';

  @override
  String get simpleSwitch => 'Use simple mode';

  @override
  String simpleChannelTitle(String channel) {
    return 'Sound channel: $channel';
  }

  @override
  String get simpleChannelAlarm => 'Alarm';

  @override
  String get simpleChannelNotification => 'Notification';

  @override
  String get simpleChannelHelp =>
      'If you hear nothing, or the sound comes from the phone\'s speaker while earphones are in, try the other channel. Notification is silent while the phone is on vibrate or Do Not Disturb.';

  @override
  String get simpleTestNote =>
      'This is a test. After trying it (speaker, earphones, Bluetooth), please send the diagnostics report from Settings.';

  @override
  String get simpleOnDetail =>
      'Simple mode (test): media sound is muted while Waaiya filters.';

  @override
  String get worshipPrayerFajr => 'ফজর';

  @override
  String get worshipPrayerSunrise => 'সূর্যোদয়';

  @override
  String get worshipPrayerDhuhr => 'যোহর';

  @override
  String get worshipPrayerAsr => 'আসর';

  @override
  String get worshipPrayerMaghrib => 'মাগরিব';

  @override
  String get worshipPrayerIsha => 'এশা';

  @override
  String get worshipEndSilent => 'এখনই নীরবতা শেষ করুন';

  @override
  String get worshipUnmute => 'এখনই শব্দ চালু করুন';

  @override
  String get worshipSmsDefault =>
      'এখন নামাজের সময়, এখন ধরতে পারছি না। পরে আপনাকে ফোন করব।';

  @override
  String get desktopPreview =>
      'প্রিভিউ: এই কম্পিউটারে ফিল্টার ইঞ্জিন এখনো সংযুক্ত নয়। বোতামটি শুধু দেখায় অ্যাপটি কীভাবে কাজ করবে।';

  @override
  String actionFailed(String details) {
    return 'এটি কাজ করেনি: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'সব অ্যাপ থেকে বাদ্যযন্ত্র সরানো হচ্ছে।';

  @override
  String get engineErrorNoPactl =>
      'শব্দের টুল (pactl) পাওয়া যায়নি। Waaiya-র PulseAudio, অথবা pipewire-pulse সহ PipeWire দরকার।';

  @override
  String get engineErrorNoSoundServer =>
      'সাউন্ড সার্ভার চলছে না (PulseAudio বা PipeWire)।';

  @override
  String get engineErrorNoSystemd =>
      'এই সিস্টেমে systemd ইউজার সেশন নেই, যা পটভূমিতে ফিল্টার চালায়।';

  @override
  String get engineErrorNoOutput => 'কোনো স্পিকার বা হেডফোন পাওয়া যায়নি।';

  @override
  String engineErrorInstallFailed(String details) {
    return 'ফিল্টার ইনস্টল করা যায়নি। বিস্তারিত:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'ফিল্টার চালু হয়নি। বিস্তারিত:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'একটি ত্রুটির কারণে ফিল্টার থেমে গেছে। বিস্তারিত:\n$details';
  }

  @override
  String get autostartTitle => 'লগইনের সময় চালু করুন';

  @override
  String get autostartBody => 'লগইন করার সাথে সাথেই শব্দ ফিল্টার করুন।';

  @override
  String get blurBodyDesktop =>
      'Waaiya খোলা থাকাকালে সব উইন্ডোর উপরে স্ক্রিনের মানুষ ও ছবি ঢেকে দেয় (শব্দের ফিল্টার চালু বা বন্ধ যা-ই থাকুক)। এটি এই কম্পিউটারেই চলে; কিছুই কোথাও পাঠানো হয় না। Waaiya-র উইন্ডো বন্ধ করলে ব্লার থেমে যায়।';

  @override
  String get blurFailBodyDesktop =>
      'চালু: কম্পিউটার বেশি ধীর হলে বা ব্লার ব্যর্থ হলে পুরো স্ক্রিন ঢেকে দেওয়া হয়; ক্লিক তবুও নিচের উইন্ডোতে পৌঁছায়। বন্ধ: উপরে একটি লাল বারসহ স্ক্রিন দেখা যায়।';

  @override
  String get blurStatusOnVisibleDesktop =>
      'ব্লার চালু আছে। এই ডেস্কটপ নিজের স্ক্রিন ক্যাপচারে ব্লার দেখায়, তাই দৃশ্য না বদলানো পর্যন্ত ব্লার করা জায়গা ব্লারই থাকে।';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'এই ডেস্কটপে ব্লার অন্য উইন্ডোর উপরে আঁকতে পারছে না। বিস্তারিত:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'স্ক্রিন শেয়ারের উইন্ডোতে আপনার স্ক্রিন বেছে নিয়ে অনুমতি দিন। Waaiya শুধু একবার জিজ্ঞাসা করে; ছবি এই কম্পিউটারেই থাকে।';

  @override
  String blurStatusExited(String details) {
    return 'ব্লার অপ্রত্যাশিতভাবে থেমে গেছে। আবার চেষ্টা করতে একটি ব্লার বিকল্প বন্ধ করে আবার চালু করুন। বিস্তারিত:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'নারীদের গান শনাক্তকারী লোড হয়নি, তাই ওই বিকল্প চালু থাকলে কণ্ঠ নীরব করা হয়।';

  @override
  String get blurStatusUncovered =>
      'একটি মনিটর ব্লারে ঢাকা নেই: এটি ব্লারের সাথে শেয়ার করা হয়নি, অথবা পরে লাগানো হয়েছে। একটি ব্লার বিকল্প বন্ধ করে আবার চালু করুন, এবং স্ক্রিন শেয়ারের উইন্ডোতে প্রতিটি স্ক্রিন বেছে নিন।';

  @override
  String get blurStatusModelsMissingDesktop =>
      'এই ইনস্টলেশনে ব্লারের মডেলগুলো নেই, তাই এটি কিছুই ঢাকতে পারে না; স্ক্রিনের উপরে একটি লাল বার থেকে যায়। Waaiya আবার ইনস্টল করুন।';

  @override
  String get diagNoteDesktop =>
      'এই কম্পিউটারে Waaiya যা দেখে। এটি কপি করে যিনি আপনাকে সাহায্য করছেন তাঁকে দিন। অ্যাপ নিজে কিছুই পাঠায় না।';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'প্রস্তাবিত। ফিল্টার করা যদি নিজে থেকে থেমে যায় (কোনো ত্রুটিতে, আপনি থামাননি), তাহলে আবার চালু করা বা থামান চাপা পর্যন্ত অন্য অ্যাপগুলো নীরব থাকে, ফিল্টার ছাড়া গান বাজে না।';

  @override
  String get settingStereoBodyDesktop =>
      'বন্ধ: মনো, যা কম্পিউটারের উপর কম চাপ দেয়। চালু: বাম ও ডান দিক আলাদা রাখে। কম্পিউটার স্টেরিওর জন্য খুব ধীর হলে নিজে থেকেই মনোতে চলে যায়।';

  @override
  String get linkEntryBodyDesktop =>
      'ফিল্টার চালু রেখে দেখতে, বা মিউজিক ছাড়া সেভ করতে একটি YouTube, TikTok বা Instagram লিংক পেস্ট করুন।';

  @override
  String get linkEntryBodyWatch =>
      'আপনার ব্রাউজারে ফিল্টার চালু রেখে দেখতে একটি YouTube, TikTok বা Instagram লিংক পেস্ট করুন।';

  @override
  String get linkWatchNoteDesktop =>
      'আপনার ব্রাউজারে খোলে। Waaiya আগে ফিল্টার চালু করে, তাই সেখানেও মিউজিক সরানো হয়।';

  @override
  String get linkFilterFailed =>
      'ফিল্টার চালু হয়নি, তাই লিংকটি খোলা হয়নি। ফিল্টার পেজ থেকে চালু করে আবার চেষ্টা করুন।';

  @override
  String get linkSavedVideoDesktop => 'আপনার Videos ফোল্ডারে: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'আপনার Music ফোল্ডারে: Waaiya';

  @override
  String get linkShowInFolder => 'ফোল্ডারে দেখান';

  @override
  String get linkSingingNote =>
      'আপনার সেটিংস অনুযায়ী নারীদের গানও নীরব করা হয়।';

  @override
  String get singingKeepTitle => 'গানের কণ্ঠ রাখুন (পরীক্ষামূলক)';

  @override
  String get singingKeepBody =>
      'বাদ্যযন্ত্র সরানো হয় কিন্তু গানের কণ্ঠ থাকে, তাই যে বয়ানের নিচে নাশিদ আছে তাতে নাশিদের কণ্ঠও থাকে; এটি গ্রহণযোগ্য কি না, তা আপনার সিদ্ধান্ত।';

  @override
  String get singingKeepNoModel =>
      'এই সংস্করণে গানের মডেল নেই, তাই এটি চালু থাকা পর্যন্ত শব্দ নীরব থাকবে। এটি বন্ধ করুন।';

  @override
  String get fixFilterAppsTitle => 'ফিল্টার ছাড়া শোনা অ্যাপ';

  @override
  String get fixFilterAppsBody =>
      'এখানে যে অ্যাপগুলো বেছে নেবেন, সেগুলো যেমন আছে তেমনই বাজে: কোনো ফিল্টার নেই, নীরবও করা হয় না। যেমন, ভিডিও কলের অ্যাপ, যাতে কলে কোনো দেরি না হয়।';

  @override
  String get fixAddApp => 'একটি অ্যাপ যোগ করুন';

  @override
  String fixRemoveApp(Object app) {
    return '$app সরান';
  }

  @override
  String get fixNoApps => 'কোনো অ্যাপ বেছে নেওয়া হয়নি।';

  @override
  String get fixPickTitle => 'একটি অ্যাপ বেছে নিন';

  @override
  String get fixPickEmpty => 'আর কোনো অ্যাপ পাওয়া যায়নি।';

  @override
  String get fixPickPlayingDesktop =>
      'এখন শব্দ বাজাচ্ছে এমন অ্যাপ, এবং আগে বেছে নেওয়া অ্যাপ।';

  @override
  String get fixCancel => 'বাতিল';

  @override
  String get fixBlurAppsTitle => 'ঝাপসা ছাড়া অ্যাপ';

  @override
  String get fixBlurAppsBody =>
      'এই অ্যাপগুলোর কোনো একটি পুরো স্ক্রিন জুড়ে থাকলে কোনো আবরণ থাকে না, যেমন ম্যাপের অ্যাপ বা আপনার ব্যাংকের অ্যাপ। সেটি ছাড়লেই আবরণ ফিরে আসে, অথবা যখনই Waaiya নিশ্চিত নয় কোন অ্যাপ দেখানো হচ্ছে।';

  @override
  String get fixBlurAppsNeedsSetup =>
      'একবারের সেটআপ দরকার: এটি ছাড়া Waaiya জানতে পারে না স্ক্রিনে কোন অ্যাপ, তাই ঝাপসা সব জায়গায় থাকে।';

  @override
  String get fixBlurAppsHelperMode =>
      'Waaiyaর সহায়ক চলছে না, তাই পর্দায় কোন অ্যাপ আছে তা পড়া যাচ্ছে না। সেটআপ পাতা থেকে সহায়ক আবার চালু না হওয়া পর্যন্ত ঝাপসা সব জায়গায় থাকবে।';

  @override
  String get fixHandTitle => 'হাতে একটি অংশ ঢাকুন';

  @override
  String get fixHandBody =>
      'ঝাপসা চলার সময় আপনি নিজেই স্ক্রিনের একটি অংশ ঢাকতে পারেন, যেমন এমন কোনো ছবি যা ঝাপসা ধরতে পারেনি: “একটি অংশ ঢাকুন” চাপুন এবং তার উপর আঙুল টানুন। আপনি সরানো পর্যন্ত বা ঝাপসা বন্ধ হওয়া পর্যন্ত এটি ঢাকা থাকে।';

  @override
  String get fixHandNotRunning =>
      'ঝাপসা চলার সময় পাওয়া যায়: ফিল্টারিং চালু এবং একটি ঝাপসা বিকল্প চালু।';

  @override
  String get fixCoverArea => 'একটি অংশ ঢাকুন';

  @override
  String fixRemoveCovers(Object count) {
    return 'হাতের আবরণ সরান ($count)';
  }

  @override
  String get fixNoteTitle => 'একটি ভুল লিখে রাখুন';

  @override
  String get fixNoteBody =>
      'Waaiya কোনো ভুল করলে, যা ঘটেছে তাতে চাপুন, যেমন “গান পার হয়ে গেছে”। নোটে সময়, অ্যাপ ও সেটিংস থাকে, যাতে কারণ খুঁজে পেতে সাহায্য হয়। এটি এই ডিভাইসেই থাকে এবং কখনো পাঠানো হয় না।';

  @override
  String get fixMissedSound => 'গান পার হয়ে গেছে';

  @override
  String get fixWrongSound => 'কণ্ঠ ভুল করে সরানো হয়েছে';

  @override
  String get fixMissedScreen => 'কিছু ঢাকা হয়নি';

  @override
  String get fixWrongScreen => 'ভুল করে ঢাকা হয়েছে';

  @override
  String fixNoted(Object count) {
    return 'লেখা হয়েছে (এই ডিভাইসে $countটি নোট)।';
  }

  @override
  String fixNotesCount(Object count) {
    return 'এই ডিভাইসে নোট: $count';
  }

  @override
  String get fixNotesShow => 'নোট দেখান';

  @override
  String get fixNotesDelete => 'নোট মুছুন';

  @override
  String get fixNotesDeleteAsk => 'সব নোট মুছবেন? এটি ফেরানো যাবে না।';

  @override
  String get fixNotesTitle => 'ভুলের নোট';

  @override
  String get worshipTitle => 'নামাজের সময়';

  @override
  String get worshipBody =>
      'ঐচ্ছিক। আপনার বেছে নেওয়া জায়গা থেকে এই ফোনেই হিসাব করা হয়। কিছুই পাঠানো হয় না।';

  @override
  String worshipPlace(Object place) {
    return 'জায়গা: $place';
  }

  @override
  String get worshipPlaceNone => 'জায়গা: বেছে নেওয়া হয়নি';

  @override
  String get worshipChoose => 'বেছে নিন';

  @override
  String get worshipPlaceSearch => 'শহর খুঁজুন';

  @override
  String get worshipPlaceNoMatch =>
      'কোনো শহর পাওয়া যায়নি। এর বদলে স্থানাঙ্ক লিখতে পারেন।';

  @override
  String get worshipPlaceCustom => 'স্থানাঙ্ক লিখুন';

  @override
  String get worshipLat => 'অক্ষাংশ (উত্তর +, দক্ষিণ −)';

  @override
  String get worshipLon => 'দ্রাঘিমাংশ (পূর্ব +, পশ্চিম −)';

  @override
  String get worshipZone => 'টাইম জোন, যেমন Asia/Dhaka';

  @override
  String get worshipCustomInvalid => 'সংখ্যা আর টাইম জোন দেখে নিন।';

  @override
  String get worshipPlaceInvalid =>
      'এই জায়গা ব্যবহার করা যাচ্ছে না। আবার বেছে নিন।';

  @override
  String worshipMethod(Object method) {
    return 'হিসাবের পদ্ধতি: $method';
  }

  @override
  String get worshipMethodTitle => 'হিসাবের পদ্ধতি';

  @override
  String get worshipMethodNote =>
      'শহরের দেশ অনুযায়ী বেছে নেওয়া হয়েছে। আপনার মসজিদ যেটা মানে সেটা বেছে নিন।';

  @override
  String worshipAsr(Object rule) {
    return 'আসর: $rule';
  }

  @override
  String get worshipAsrTitle => 'আসরের সময়';

  @override
  String get worshipAsrStandard => 'সাধারণ (শাফেয়ি, মালিকি, হাম্বলি)';

  @override
  String get worshipAsrHanafi => 'হানাফি';

  @override
  String get worshipMethodMwl => 'মুসলিম ওয়ার্ল্ড লীগ';

  @override
  String get worshipMethodIsna => 'ইসলামিক সোসাইটি অফ নর্থ আমেরিকা (ISNA)';

  @override
  String get worshipMethodEgypt => 'মিশরীয় জেনারেল অথরিটি অফ সার্ভে';

  @override
  String get worshipMethodUmmAlQura => 'উম্মুল কুরা, মক্কা';

  @override
  String get worshipMethodKarachi => 'ইসলামি বিজ্ঞান বিশ্ববিদ্যালয়, করাচি';

  @override
  String get worshipMethodTehran =>
      'ভূপদার্থবিদ্যা ইনস্টিটিউট, তেহরান বিশ্ববিদ্যালয়';

  @override
  String get worshipMethodGulf => 'উপসাগরীয় অঞ্চল';

  @override
  String get worshipMethodKuwait => 'কুয়েত';

  @override
  String get worshipMethodQatar => 'কাতার';

  @override
  String get worshipMethodSingapore => 'সিঙ্গাপুর (MUIS)';

  @override
  String get worshipMethodTurkey => 'তুরস্ক (দিয়ানেত)';

  @override
  String get worshipMethodFrance => 'ফ্রান্স (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'মরক্কো (হাবুস মন্ত্রণালয়)';

  @override
  String get worshipMethodIndonesia => 'ইন্দোনেশিয়া (কেমেনাগ)';

  @override
  String get worshipMethodMalaysia => 'মালয়েশিয়া (JAKIM)';

  @override
  String get worshipMethodDubai => 'দুবাই';

  @override
  String get worshipToday => 'আজ';

  @override
  String get worshipNoTimes =>
      'আজ এখানে নামাজের সময় নেই: সূর্য ওঠে না বা অস্ত যায় না।';

  @override
  String get worshipSilentTitle => 'নামাজের সময় নীরব';

  @override
  String get worshipSilentBody =>
      'প্রতিটি নামাজের সময়ে ফোন নিচের মিনিটগুলোর জন্য নীরব হয়ে যায় (বিরক্ত করবেন না), তারপর আগের মতো হয়ে যায়। যেমন, যোহরের সময় ১২:০০ থেকে ১২:২০ পর্যন্ত।';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'নীরব থাকবে: $minutes মিনিট';
  }

  @override
  String get worshipMuteTitle => 'আজানের সময় মিডিয়া বন্ধ';

  @override
  String get worshipMuteBody =>
      'প্রতিটি নামাজের সময় মিডিয়ার শব্দ (ভিডিও, অডিও, গেম) নিচের মিনিট পর্যন্ত বন্ধ থাকে। নোটিফিকেশন থেকে সঙ্গে সঙ্গে চালু করা যায়।';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'বন্ধ থাকবে: $minutes মিনিট';
  }

  @override
  String get worshipMinutesTitle => 'সময়কাল';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes মিনিট';
  }

  @override
  String get worshipNeedPlace => 'আগে জায়গা বেছে নিন।';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'পরের: $prayer, $time-এ';
  }

  @override
  String worshipSilentNow(Object time) {
    return '$time পর্যন্ত নীরব।';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'মিডিয়া $time পর্যন্ত বন্ধ।';
  }

  @override
  String get worshipDndNeeded =>
      'Waaiya-কে বিরক্ত করবেন না বদলানোর অনুমতি দিন, নইলে ফোন নীরব হতে পারবে না।';

  @override
  String get worshipAllow => 'অনুমতি দিন';

  @override
  String get worshipExactNeeded =>
      'Waaiya-র জন্য অ্যালার্ম ও রিমাইন্ডার অনুমতি নেই, তাই প্রতিটি পরিবর্তন ১০ মিনিট পর্যন্ত, ফোন ঘুমালে আরও দেরিতে হতে পারে।';

  @override
  String get worshipNotificationsNeeded =>
      'নোটিফিকেশন বন্ধ: ফোন কখন নীরব হলো বা ফিরে এলো, দেখতে পাবেন না।';

  @override
  String get worshipTonesTitle => 'সাধারণ রিংটোন ও নোটিফিকেশন শব্দ';

  @override
  String get worshipTonesBody =>
      'Waaiya রিংটোন বা নোটিফিকেশনের শব্দ ফিল্টার করতে পারে না, শুধু বদলাতে পারে। সংগীত ছাড়া একটি সাধারণ শব্দ বেছে নিন:';

  @override
  String worshipToneRing(Object number) {
    return 'সাধারণ রিংটোন $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'সাধারণ নোটিফিকেশন শব্দ $number';
  }

  @override
  String get worshipTonePlay => 'বাজান';

  @override
  String get worshipToneSet => 'ব্যবহার করুন';

  @override
  String get worshipToneInUse => 'ব্যবহৃত হচ্ছে';

  @override
  String get worshipToneDone => 'হয়ে গেছে।';

  @override
  String get worshipTonePermission =>
      'Waaiya-কে সিস্টেম সেটিংস বদলানোর অনুমতি দিন, ফিরে এসে আবার চাপুন।';

  @override
  String get worshipToneFailed =>
      'এই ফোন Waaiya-কে বদলাতে দেয়নি। সাউন্ড সেটিংসে “Waaiya plain” নামের একটি শব্দ বেছে নিন।';

  @override
  String get worshipOpenSound => 'সাউন্ড সেটিংস খুলুন';

  @override
  String get worshipSmsTitle => 'নামাজের সময় কলের উত্তর এসএমএসে';

  @override
  String get worshipSmsBody =>
      'প্রতিটি নামাজের সময়ের পরের নীরব মিনিটগুলোতে, বেজে যাওয়া কলে একটি এসএমএস যায়। প্রতি নামাজে প্রতি নম্বরে একবার; লুকানো বা ছোট নম্বরে কখনো নয়।';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'এত সময় বাজার পর: $seconds সেকেন্ড';
  }

  @override
  String get worshipSmsDelayTitle => 'এসএমএসের আগে কত সেকেন্ড বাজবে';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds সেকেন্ড';
  }

  @override
  String worshipSmsText(Object text) {
    return 'বার্তা: $text';
  }

  @override
  String get worshipSmsTextTitle => 'আপনার বার্তা';

  @override
  String get worshipSmsTextDefault => 'ডিফল্ট ব্যবহার করুন';

  @override
  String get worshipSmsCost =>
      'প্রতিটি উত্তর আপনার সিম থেকে একটি সাধারণ এসএমএস, আপনার প্ল্যানের দামে। রোমিংয়ে কিছুই পাঠানো হয় না।';

  @override
  String get worshipSmsRoaming => 'এখন রোমিংয়ে: কোনো এসএমএস পাঠানো হবে না।';

  @override
  String get worshipSmsLogTitle => 'পাঠানো উত্তর (শুধু এই ফোনে রাখা)';

  @override
  String get worshipContinue => 'চালিয়ে যান';

  @override
  String get worshipWhyDnd =>
      'নামাজের সময় ফোন নীরব করতে, পরের পাতায় Waaiya-কে বিরক্ত করবেন না অ্যাক্সেস দিন।';

  @override
  String get worshipWhyExact =>
      'ঠিক সময়ে কাজ করতে, পরের পাতায় Waaiya-কে অ্যালার্ম ও রিমাইন্ডার সেট করার অনুমতি দিন। না দিলে পরিবর্তন ১০ মিনিট পর্যন্ত দেরিতে হতে পারে।';

  @override
  String get worshipWhyNotifications =>
      'নোটিফিকেশনের অনুমতি দিন, যাতে প্রতিটি পরিবর্তন দেখতে ও ফিরিয়ে নিতে পারেন।';

  @override
  String get worshipWhyWrite =>
      'রিংটোন বা নোটিফিকেশনের শব্দ বদলাতে, পরের পাতায় Waaiya-কে সিস্টেম সেটিংস বদলানোর অনুমতি দিন।';

  @override
  String get worshipWhyPhone =>
      'কল বাজছে কিনা আর তার নম্বর জানতে Waaiya-র ফোন ও কল লগের অনুমতি লাগবে। আপনার উত্তর ছাড়া কিছুই ফোনের বাইরে যায় না।';

  @override
  String get worshipWhySms =>
      'আপনার উত্তর পাঠাতে Waaiya-র এসএমএস পাঠানোর অনুমতি লাগবে। এটি শুধু সেই উত্তরটি পাঠায়, প্রতি নামাজে প্রতি নম্বরে সর্বোচ্চ একবার।';

  @override
  String get worshipMissingDnd =>
      'বিরক্ত করবেন না অ্যাক্সেস দেওয়া হয়নি, তাই নীরবতা বন্ধ থাকছে।';

  @override
  String get worshipMissingPhone =>
      'ফোন ও কল লগের অনুমতি দেওয়া হয়নি, তাই এসএমএস উত্তর বন্ধ থাকছে।';

  @override
  String get worshipMissingSms =>
      'এসএমএস পাঠানোর অনুমতি দেওয়া হয়নি, তাই এসএমএস উত্তর বন্ধ থাকছে।';

  @override
  String get worshipTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get protectTitle => 'দুর্বল মুহূর্তের সুরক্ষা';

  @override
  String get protectBody =>
      'দুর্বল মুহূর্তের জন্য, যখন আপনি ফিল্টার বন্ধ করতে চাইতে পারেন। এখন, শান্ত অবস্থায়, একটি অপেক্ষার সময় বেছে নিন: তখন বন্ধ করার বোতাম ফিল্টার সঙ্গে সঙ্গে বন্ধ করে না, আর সময় শেষ হলে আপনি আবার সিদ্ধান্ত নেন। অভিভাবক একটি PIN-ও সেট করতে পারেন।';

  @override
  String protectDelay(Object value) {
    return 'বন্ধ করার আগে অপেক্ষা: $value';
  }

  @override
  String get protectDelayTitle => 'বন্ধ করার আগে অপেক্ষা';

  @override
  String get protectDelayBody =>
      'উদাহরণ, ৩০ মিনিট হলে: আপনি বন্ধ করার বোতাম চাপেন, কিন্তু ফিল্টার চলতেই থাকে। ৩০ মিনিট পরে এই পাতা জিজ্ঞেস করে আপনি এখনও বন্ধ করতে চান কি না। ১৫ মিনিটের মধ্যে “নিশ্চিত করুন” চাপলে এটি বন্ধ হয়; নইলে কিছুই বদলায় না। কোনো ঢাকা বা অন্য কোনো সুরক্ষা বন্ধ করার ক্ষেত্রেও একই। কিছু চালু করা সবসময় সঙ্গে সঙ্গে হয়।';

  @override
  String get protectDelayOff => 'নেই';

  @override
  String get protectDelay1m => '১ মিনিট';

  @override
  String get protectDelay5m => '৫ মিনিট';

  @override
  String get protectDelay15m => '১৫ মিনিট';

  @override
  String get protectDelay30m => '৩০ মিনিট';

  @override
  String get protectDelay1h => '১ ঘণ্টা';

  @override
  String get protectDelay4h => '৪ ঘণ্টা';

  @override
  String get protectDelay24h => '২৪ ঘণ্টা';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes মিনিট';
  }

  @override
  String get protectPinNone => 'পিন: রাখা হয়নি';

  @override
  String get protectPinIsSet => 'পিন: রাখা আছে';

  @override
  String get protectPinSet => 'পিন রাখুন';

  @override
  String get protectPinRemove => 'মুছুন';

  @override
  String get protectPinBody =>
      'পিন থাকলে, ফিল্টার বন্ধ করতে বা কোনো সুরক্ষা বন্ধ করতে আগে পিন চাওয়া হয়। যেমন, বাবা বা মা একটি পিন রাখেন, যাতে শিশু ফিল্টার বন্ধ করতে না পারে। অপেক্ষার সময় বা পিন বদলাতেও পিন লাগে।';

  @override
  String get protectPinForgot =>
      'পিনটি কোথাও নিরাপদে লিখে রাখুন: ভুলে গেলে রিসেট করার কোনো উপায় নেই। একমাত্র উপায় Waaiya-এর ডেটা মুছে ফেলা বা আবার ইনস্টল করা, যাতে এর সব সেটিংসও মুছে যায়।';

  @override
  String get protectPinTitle => 'পিন দিন';

  @override
  String get protectPinNewTitle => 'একটি পিন বেছে নিন';

  @override
  String get protectPinChangeTitle => 'পিন বদলান';

  @override
  String get protectPinCurrent => 'বর্তমান পিন';

  @override
  String get protectPinNew => 'নতুন পিন (৪ থেকে ৮ সংখ্যা)';

  @override
  String get protectPinAgain => 'নতুন পিন আবার';

  @override
  String get protectPinBad => '৪ থেকে ৮টি সংখ্যা দিন।';

  @override
  String get protectPinDiffer => 'দুটি নতুন পিন এক নয়।';

  @override
  String protectPinWrong(Object count) {
    return 'ভুল পিন। বিরতির আগে আর $count বার চেষ্টা বাকি।';
  }

  @override
  String protectLocked(Object time) {
    return 'অনেকবার ভুল চেষ্টা। $time-এ আবার চেষ্টা করুন।';
  }

  @override
  String get protectOk => 'ঠিক আছে';

  @override
  String get protectCancel => 'বাতিল';

  @override
  String get protectCancelChange => 'পরিবর্তন বাতিল করুন';

  @override
  String get protectConfirm => 'নিশ্চিত করুন';

  @override
  String protectPending(Object time, Object what) {
    return '$what: $time পর্যন্ত অপেক্ষা। তারপর “সেটিংস”-এ নিশ্চিত করুন।';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: অপেক্ষা শেষ। আপনি কি এখনও এটি চান? $time-এর আগে “নিশ্চিত করুন” চাপুন; নইলে কিছুই বদলাবে না।';
  }

  @override
  String get protectWaitTitle => 'এই পরিবর্তন অপেক্ষা করছে';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what এখন হবে না। $time-এ, যদি তখনও চান, ১৫ মিনিটের মধ্যে “সেটিংস”-এ নিশ্চিত করুন। কিছু না করলে কিছুই বদলাবে না।';
  }

  @override
  String get protectWaitStart => 'অপেক্ষা শুরু করুন';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'ইতিমধ্যে $time পর্যন্ত অপেক্ষা চলছে।';
  }

  @override
  String protectStarted(Object time) {
    return '$time পর্যন্ত অপেক্ষা। তারপর “সেটিংস”-এ নিশ্চিত করুন।';
  }

  @override
  String protectTomorrow(Object time) {
    return 'আগামীকাল $time-এ';
  }

  @override
  String get protectHeldBack =>
      'এখন নয়: আপনার সুরক্ষা সেটিংসের কারণে এই পরিবর্তনের জন্য অপেক্ষা করতে হবে, অথবা পিন লাগবে।';

  @override
  String get protectLimits =>
      'যা এটি আটকাতে পারে না: জোর করে বন্ধ করা, আনইনস্টল করা, Waaiya-এর ডেটা মুছে ফেলা এবং Android-এর নিজস্ব সেটিংস। এগুলো আটকাতে Android-এর বিশেষ অনুমতি লাগে, যা Waaiya ব্যবহার করে না। এটি দুর্বল মুহূর্ত থেকে রক্ষা করে, দৃঢ়প্রতিজ্ঞ কারো থেকে নয়।';

  @override
  String get protectLimitsDesktop =>
      'যা এটি আটকাতে পারে না: টার্মিনালে waaiya কমান্ড, Waaiya সরিয়ে ফেলা বা এর সেটিংস ফোল্ডার মুছে ফেলা। এটি দুর্বল মুহূর্ত থেকে রক্ষা করে, দৃঢ়প্রতিজ্ঞ কারো থেকে নয়।';

  @override
  String get protectLimitsWindows =>
      'যা এটি আটকাতে পারে না: টার্মিনালে waaiya-filter.exe কমান্ড, Waaiya সরিয়ে ফেলা বা এর সেটিংস ফোল্ডার মুছে ফেলা। এটি দুর্বল মুহূর্ত থেকে রক্ষা করে, দৃঢ়প্রতিজ্ঞ কারো থেকে নয়।';

  @override
  String get protectWhatStop => 'ফিল্টার বন্ধ করা';

  @override
  String protectWhatOff(Object name) {
    return 'বন্ধ করা: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'চালু করা: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'অ্যাপ যোগ করা: $name';
  }

  @override
  String get protectWhatStrictness => 'ব্লার কম কড়া করা';

  @override
  String get protectWhatGender => 'Waaiya কে ব্যবহার করেন তা বদলানো';

  @override
  String protectWhatDelay(Object value) {
    return 'বন্ধ করার আগে অপেক্ষা বদলে করুন: $value';
  }

  @override
  String get protectWhatPinChange => 'পিন বদলানো';

  @override
  String get protectWhatPinClear => 'পিন মুছে ফেলা';

  @override
  String get protectWhatSetting => 'একটি সেটিং বদলানো';

  @override
  String get onboardBodyDesktop =>
      'Waaiya এই কম্পিউটারের সব অ্যাপের শব্দ থেকে বাদ্যযন্ত্র সরিয়ে দেয়। কথা ও কুরআন তিলাওয়াত রেখে দেওয়া হয়। আপাতত গানের কণ্ঠও সরিয়ে দেওয়া হয়।';
}
