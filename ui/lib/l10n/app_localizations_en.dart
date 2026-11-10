// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Waaiya';

  @override
  String get tagline =>
      'Removes musical instruments from every app and keeps speech and recitation.';

  @override
  String get onboardTitle => 'Welcome';

  @override
  String get onboardBody =>
      'Waaiya removes musical instruments from the sound of every app on this phone. Speech and Quran recitation are kept. For now, singing voices are removed too.';

  @override
  String get onboardQuestion => 'I am';

  @override
  String get genderMan => 'A man';

  @override
  String get genderWoman => 'A woman';

  @override
  String get onboardWhy =>
      'This only decides which optional settings you see. You can change it later.';

  @override
  String get stateOnTitle => 'Filtering is on';

  @override
  String get stateOffTitle => 'Filtering is off';

  @override
  String get stateStarting => 'Starting…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Instruments are removed from all apps. Delay about $delayMs ms.';
  }

  @override
  String get stateOffDetail => 'Tap the button to start.';

  @override
  String get stateModelFailed =>
      'The sound model could not load, so the sound is muted for safety.';

  @override
  String get stateCaptureDenied =>
      'The microphone permission is needed to receive other apps\' sound.';

  @override
  String get stateStoppedBySystem =>
      'Android stopped filtering. Tap the button to start again.';

  @override
  String get powerStartCd => 'Start filtering';

  @override
  String get powerStopCd => 'Stop filtering';

  @override
  String get captureHint =>
      'Android will ask to share your screen. Only the sound is used: nothing is recorded or sent.';

  @override
  String get needRecordAudio =>
      'Waaiya needs the microphone permission to receive other apps\' sound. It never records you.';

  @override
  String get setupBannerTitle => 'One more step';

  @override
  String get setupBannerBody =>
      'Without the one-time setup below, you will hear the music and the filtered sound together.';

  @override
  String get setupTitle => 'One-time setup';

  @override
  String get setupBody =>
      'Lets Waaiya silence the original sound. You do it once; it stays until you uninstall the app.';

  @override
  String get step1Title => 'Install Shizuku';

  @override
  String get step1Body => 'A free helper app from the Play Store.';

  @override
  String get step1Action => 'Get Shizuku';

  @override
  String get step2Title => 'Start Shizuku';

  @override
  String get step2Body =>
      'In Shizuku, choose \"Start via Wireless debugging\" and follow its steps, then come back.';

  @override
  String get step2Action => 'Open Shizuku';

  @override
  String get step2Update => 'Update Shizuku';

  @override
  String get step2TooOld =>
      'Your Shizuku version is too old. Update it from the Play Store.';

  @override
  String get step2Denied =>
      'Shizuku is set to always deny Waaiya. In Shizuku, allow it in the list of apps.';

  @override
  String get step3Title => 'Give permission';

  @override
  String get step3Body => 'One tap, then choose \"Allow\".';

  @override
  String get step3Action => 'Give permission';

  @override
  String get step3Busy => 'Setting up…';

  @override
  String get setupDoneRestart =>
      'Done. Stop and start filtering once to apply it.';

  @override
  String setupFailed(String details) {
    return 'Setup did not finish. Details:\n$details';
  }

  @override
  String get shizukuRefused =>
      'Shizuku permission was refused. Tap the button to try again.';

  @override
  String get stepDoneCd => 'Done';

  @override
  String stepTodoCd(int step) {
    return 'Step $step';
  }

  @override
  String get computerToggle => 'Use a computer instead';

  @override
  String get computerBody =>
      'Turn on USB debugging, connect the phone and run:';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get computerNote =>
      'The second line is optional: it stops the screen-sharing question at every start.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingSilenceTitle => 'Silence apps that block filtering';

  @override
  String get settingSilenceBody =>
      'Recommended. Some apps do not allow their sound to be filtered; this mutes them instead of letting music through.';

  @override
  String get settingSingingTitle => 'Mute women\'s singing';

  @override
  String get settingSingingBody => 'Women\'s speech and recitation are kept.';

  @override
  String get settingSingingNoModel =>
      'This version has no singing detector, so all voices are muted while this is on.';

  @override
  String get settingRestart => 'Stop and start filtering to apply changes.';

  @override
  String get settingGenderTitle => 'I am';

  @override
  String get change => 'Change';

  @override
  String get playerTitle => 'Videos in perfect sync';

  @override
  String get playerBody =>
      'Share a video to Waaiya (or use \"Open with\") to watch it filtered with no delay.';

  @override
  String get licences => 'Open-source licences';

  @override
  String get licencesIntro =>
      'Waaiya is free software under the GNU Affero General Public License v3 or later.';

  @override
  String get licencesCc =>
      'Creative Commons Attribution 4.0 (training data): https://creativecommons.org/licenses/by/4.0/';

  @override
  String get licencesFull => 'Full texts';

  @override
  String get back => 'Back';

  @override
  String get linkEntryTitle => 'Open a link';

  @override
  String get linkEntryBody =>
      'Paste a YouTube, TikTok or Instagram link to watch it or save it without music.';

  @override
  String get linkTitle => 'Open a link';

  @override
  String get linkHint => 'https://… (YouTube, TikTok, Instagram…)';

  @override
  String get linkFieldLabel => 'Video or audio link';

  @override
  String get linkPaste => 'Paste';

  @override
  String get linkOpen => 'Open';

  @override
  String get linkResolving => 'Opening the link…';

  @override
  String linkMeta(String first, String second) {
    return '$first · $second';
  }

  @override
  String get linkWatch => 'Watch without music';

  @override
  String get linkSave => 'Save without music';

  @override
  String get linkListen => 'Listen without music';

  @override
  String get linkDownloading => 'Downloading…';

  @override
  String get linkFiltering => 'Removing music…';

  @override
  String get linkCancel => 'Cancel';

  @override
  String get linkCancelled => 'Cancelled. Nothing was saved.';

  @override
  String get linkExportFailed => 'Could not save this one. Nothing was saved.';

  @override
  String get linkSaved => 'Saved without music';

  @override
  String get linkSavedVideo => 'In your gallery: Movies › Waaiya';

  @override
  String get linkSavedAudio => 'In your music: Music › Waaiya';

  @override
  String get linkPlay => 'Play';

  @override
  String get linkShare => 'Share';

  @override
  String get linkShareNote => 'Only share videos you are allowed to share.';

  @override
  String get linkLive => 'Live streams cannot be saved.';

  @override
  String get linkBusy =>
      'Another video is being saved. Please wait for it to finish.';

  @override
  String get linkInvalid => 'Please paste a web link (starting with https://).';

  @override
  String get linkLogin =>
      'The site would not show this video without an account. Public posts usually open: try again in a few minutes. Private posts cannot be opened.';

  @override
  String get linkUnsupported => 'This site is not supported.';

  @override
  String get linkPlaylist => 'This is a playlist. Please open one video.';

  @override
  String get linkNoFormat =>
      'This video is not in a format Waaiya can filter yet.';

  @override
  String get linkFailed =>
      'Could not open this link. Check your connection and try again.';

  @override
  String get linkPlayFailed =>
      'Could not play this. Nothing unfiltered was played.';

  @override
  String get linkLimited =>
      'The site is limiting requests right now. Try again in a few minutes.';

  @override
  String get blurTitle => 'Screen blur';

  @override
  String get blurBody =>
      'Covers people and images on screen, in every app, while filtering is on. It runs on the phone; nothing is sent anywhere.';

  @override
  String get blurWomenTitle => 'Blur women';

  @override
  String get blurWomenBody =>
      'Whole body. People the app cannot clearly tell are men are blurred too.';

  @override
  String get blurNudityTitle => 'Blur immodest images';

  @override
  String get blurNudityBody =>
      'Nudity and revealing clothing, of anyone: the whole screen is covered.';

  @override
  String get blurFailTitle => 'Cover the screen if the blur cannot keep up';

  @override
  String get blurFailBody =>
      'On: the whole screen is covered when the phone is too slow or the blur fails. Off: the screen stays visible with a warning.';

  @override
  String get blurSetupShizuku => 'Allow with Shizuku';

  @override
  String get blurSetupManual => 'Allow in Android settings';

  @override
  String get blurStatusNeedsSetup =>
      'The blur needs to draw over other apps. Best: allow it with Shizuku (turns on the Waaiya Blur accessibility service, so touches still reach the app underneath). Or allow \"Display over other apps\" in Android settings (touches on a blurred area are then lost).';

  @override
  String get blurStatusNeedsOverlay =>
      'The blur needs to draw over other apps: allow it with Shizuku, or allow \"Display over other apps\" in Android settings. A tap on a blurred area does not reach the app underneath.';

  @override
  String get blurFailUnavailable =>
      'Not available in this version: here a tap on a blurred area does not reach the app, so a full-screen cover would block every touch and you could get stuck. When the blur cannot keep up, the screen stays visible with a warning.';

  @override
  String get blurFailNeedsA11y =>
      'Needs the Waaiya Blur accessibility service (Allow with Shizuku above). Without it, a full-screen cover would block every touch and you could get stuck, so the screen stays visible with a warning.';

  @override
  String get languageTitle => 'Language';

  @override
  String settingLanguageTitle(String language) {
    return 'Language: $language';
  }

  @override
  String get languageAr => 'العربية';

  @override
  String get languageEn => 'English';

  @override
  String get blurStatusRestart =>
      'Stop and start filtering to apply the blur settings.';

  @override
  String get blurStatusStarting => 'Blur starting…';

  @override
  String get blurStatusOn => 'Blur on.';

  @override
  String get blurStatusOnVisible =>
      'Blur on, in cautious mode: this phone shows the blur in its own screen capture, so a blurred area stays blurred until the scene changes.';

  @override
  String get blurStatusModels =>
      'This version lacks a blur model for the chosen option.';

  @override
  String get blurStatusFailing => 'The blur cannot keep up right now.';

  @override
  String get blurStatusNoOverlay =>
      'The blur cannot draw over other apps: allow it above.';

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku could not allow it:\n$details';
  }

  @override
  String get desktopPreview =>
      'Preview: the filter engine is not connected on this computer yet. The button only shows how the app will work.';

  @override
  String actionFailed(String details) {
    return 'That did not work: $details';
  }
}
