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
      'This only decides which optional settings you see. For example, “Mute women\'s singing” is offered only to men. You can change it later.';

  @override
  String get stateOnTitle => 'Filtering is on';

  @override
  String get stateOffTitle => 'Filtering is off';

  @override
  String get stateStarting => 'Starting…';

  @override
  String stateOnDetail(int delayMs) {
    return 'Instruments are removed from all apps. The sound comes about $delayMs ms late (1000 ms is one second).';
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
  String get stateSilencedTitle => 'Filtering stopped';

  @override
  String get stateSilenced =>
      'Filtering stopped: other apps are silenced. Tap the button to start again, or Stop to hear them unfiltered.';

  @override
  String get releaseSilence => 'Stop: hear apps unfiltered';

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
  String get step1Title => 'Install Shizuku';

  @override
  String get step1Body => 'A free helper app from the Play Store.';

  @override
  String get step1Action => 'Get Shizuku';

  @override
  String get step2Title => 'Start Shizuku';

  @override
  String get step2Body =>
      'Shizuku starts over Wi-Fi with Android\'s wireless debugging. Tap the button for the steps, then come back.';

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
  String get setupSlow =>
      'Shizuku is taking longer than usual. Keep waiting: on some phones its helper takes up to a minute to start the first time.';

  @override
  String get setupTimeout =>
      'Shizuku did not answer within 2 minutes. Open Shizuku, check that it says it is running, then tap the button again. If the setup finishes later, this screen updates by itself.';

  @override
  String get setupRefusedXiaomi =>
      'This phone refused the permissions. On Xiaomi, Redmi and POCO, turn on “USB debugging (Security settings)” in Developer options (it asks you to sign in to a Xiaomi account), then try again.';

  @override
  String get setupRefusedColoros =>
      'This phone refused the permissions. On OPPO, OnePlus and realme, in Developer options, turn on “Disable permission monitoring” (on the newest versions it is called “Disable system optimization”, and may show only with the phone set to English). To find it, search “permission” in Settings. Then try again.';

  @override
  String get setupNoteXiaomi =>
      'Xiaomi, Redmi and POCO: if the notification has no field to type the code in, set the notification style to “Android” in the notification settings, or type the code in Waaiya using split screen.';

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
  String get settingHoldSilenceTitle =>
      'Keep apps silent if filtering stops by itself';

  @override
  String get settingHoldSilenceBody =>
      'Recommended. If Android ends filtering (not you), other apps stay silent until you start again or tap Stop, instead of playing music unfiltered. Needs the one-time setup.';

  @override
  String get settingStereoTitle => 'Stereo sound';

  @override
  String get settingStereoBody =>
      'Off: mono, which uses about half the battery and keeps up on more phones. On: keeps the left and right sides apart. If the phone is too slow for stereo, it still switches to mono by itself.';

  @override
  String get settingSingingTitle => 'Mute women\'s singing';

  @override
  String get settingSingingBody =>
      'For example, a song sung by a woman is muted, but a woman giving a talk is still heard.';

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
      'Waaiya is free software under the GNU Affero General Public License v3 or later. Source code: https://github.com/oksyassine/waaiya';

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
  String get linkAudioOnly =>
      'The video of this link cannot be opened yet: only its sound.';

  @override
  String get linkDownloading => 'Downloading…';

  @override
  String get linkFiltering => 'Removing music…';

  @override
  String get linkCancel => 'Cancel';

  @override
  String get linkCancelled => 'Cancelled. Nothing was saved.';

  @override
  String get linkTimedOut =>
      'Android stopped the save: it allows this kind of work only a few hours a day. Nothing was saved; open Waaiya and try again.';

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
      'Covers the whole body. If the app is not sure that a person is a man, it covers them too.';

  @override
  String get blurNudityTitle => 'Blur immodest images';

  @override
  String get blurNudityBody =>
      'Nudity or revealing clothes, on anyone: the whole screen is covered.';

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
      'To blur, Waaiya has to draw over other apps. Best: “Allow with Shizuku”, so your taps still reach the app under the blur. Or “Allow in Android settings”, but then a tap on a blurred area does nothing.';

  @override
  String get blurStatusNeedsOverlay =>
      'To blur, Waaiya has to draw over other apps. Best: start Shizuku and allow Waaiya in it, so your taps still reach the app under the blur. Or allow “Display over other apps” in Android settings, but then a tap on a blurred area does nothing.';

  @override
  String get blurFailUnavailable =>
      'Greyed out for now: a full-screen cover would block every tap and you could get stuck. Start Waaiya\'s helper or Shizuku (Android 12 or newer) and it turns on: the covers are then drawn so that taps go through them. Until then, when the blur cannot keep up, the screen stays visible with a warning.';

  @override
  String get blurFailNeedsA11y =>
      'Greyed out for now: a full-screen cover would block every tap and you could get stuck. Start Shizuku (Android 12 or newer) or turn on the Waaiya Blur accessibility service (Allow with Shizuku above) and it turns on. Until then, the screen stays visible with a warning.';

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
  String blurStatusNoCapture(String details) {
    return 'The blur cannot see the screen. Details:\n$details';
  }

  @override
  String blurSetupFailed(String details) {
    return 'Shizuku could not allow it:\n$details';
  }

  @override
  String get step2Guide => 'How to start Shizuku';

  @override
  String get blurFailOldAndroid =>
      'Greyed out: on this Android version a full-screen cover would block every tap and you could get stuck (Shizuku covers need Android 12 or newer). When the blur cannot keep up, the screen stays visible with a warning.';

  @override
  String get guideTitle => 'Start Shizuku, step by step';

  @override
  String get guideOpenDev => 'Developer options';

  @override
  String get guideOpenShizuku => 'Open Shizuku';

  @override
  String get guideClose => 'Close';

  @override
  String get guideBody =>
      'You need Wi-Fi and Android 11 or newer. Pairing is done once; after the phone restarts you only repeat step 7.\n\n1. Connect the phone to Wi-Fi.\n\n2. Turn on Developer options: Settings › About phone › Software information › tap “Build number” 7 times. (On other phones: Settings › About phone › Build number.)\n\n3. Open Shizuku. If it asks to show notifications, allow it: the pairing code is typed in a Shizuku notification.\n\n4. In Shizuku, under “Start via Wireless debugging”, tap “Pairing”. On the page that opens, tap “Developer options”, turn on “Wireless debugging” and confirm “Allow”.\n\n5. Tap the words “Wireless debugging” (not the switch), then “Pair device with pairing code”. A 6-digit code appears.\n\n6. Keep that screen open and pull down the notifications. When Shizuku\'s notification says “Pairing service found”, tap “Enter pairing code” and type the code. Shizuku says pairing succeeded.\n\n7. Go back to Shizuku and tap “Start” under “Start via Wireless debugging”. Wait until it says “Shizuku is running”.\n\n8. Come back to Waaiya and tap “Give permission”, then “Allow”.\n\nAfter a phone restart Shizuku stops: connect to Wi-Fi, turn “Wireless debugging” back on if it is off, open Shizuku and tap “Start”. No new pairing.';

  @override
  String get wsetupRouteTitle => 'Set up on this phone';

  @override
  String get wsetupRouteBody =>
      'Four short steps, done once. No extra app and no computer. Waaiya ticks each step when it is done.';

  @override
  String get wizDevTitle => 'Turn on Developer options';

  @override
  String get wizDevBody =>
      'In About phone, tap “Build number” 7 times, then come back here. If you cannot find it, search “Build number” in Settings.';

  @override
  String get wizDevBodySamsung =>
      'In About phone › Software information, tap “Build number” 7 times, then come back here.';

  @override
  String get wizDevBodyXiaomi =>
      'In About phone, tap “OS version” 7 times (on older phones “MIUI version”; on some it is under “Detailed info and specs”), then come back here.';

  @override
  String get wizDevBodyColoros =>
      'In About device (or About phone) › Version, tap “Build number” 7 times, then come back here.';

  @override
  String get wizDevBodyVivo =>
      'In About phone, tap “Software version” 7 times (on some phones: Software information › “Build number”), then come back here.';

  @override
  String get wizDevBodyHuawei =>
      'In About phone, tap “Build number” 7 times, then come back here.';

  @override
  String get wizDevBodyTranssion =>
      'In My phone (or About phone), tap “Build number” 7 times, then come back here.';

  @override
  String get setupNoteHuawei =>
      'Huawei: many Huawei phones have no “Wireless debugging”. If you cannot find it in Developer options, use a computer (“Other ways” below).';

  @override
  String get wsetupFilterOn =>
      'Filtering is on: on this Android version the code cannot be typed in a notification while it runs. Stop filtering first, or use split screen and “Type the code here”.';

  @override
  String get wizDevSearch =>
      'The names can differ with the phone’s language: if you cannot find it, use the search at the top of Settings.';

  @override
  String get wizDevAction => 'Open About phone';

  @override
  String get wizWifiTitle => 'Connect to Wi-Fi';

  @override
  String get wizWifiBody =>
      'Any Wi-Fi network will do; internet is not needed.';

  @override
  String get wizWifiAction => 'Open Wi-Fi settings';

  @override
  String get wizWdTitle => 'Turn on Wireless debugging';

  @override
  String get wizWdBody =>
      'Waaiya opens Developer options at “Wireless debugging”. Turn it on and tap “Allow”.';

  @override
  String get wizWdAction => 'Open Developer options';

  @override
  String get wizPairTitle => 'Type the pairing code';

  @override
  String get wizPairBody =>
      'Tap the words “Wireless debugging”, then “Pair device with pairing code”. Type the 6 digits in Waaiya’s notification. Waaiya does the rest.';

  @override
  String get wizPairBodyPaired =>
      'Waaiya is already paired with this phone: no code is needed. Tap the button and Waaiya finishes by itself.';

  @override
  String get wizPairAction => 'Continue';

  @override
  String get wizAgain => 'Run the setup again';

  @override
  String get setupShizukuReadyTitle => 'With Shizuku, which is already running';

  @override
  String get setupOtherWaysPlain => 'Other ways to do the setup';

  @override
  String get wizSkip => 'Skip to Wireless debugging';

  @override
  String get setupOtherWays => 'Other ways: Shizuku or a computer';

  @override
  String get wsetupEnterHere => 'Type the code here';

  @override
  String get wsetupCancel => 'Cancel';

  @override
  String get wsetupAndroid10 =>
      'Android 10 cannot do the setup on its own: it needs a computer, directly (below) or to start Shizuku once.';

  @override
  String get wsetupShizukuHeading => 'Or with the Shizuku app';

  @override
  String get wsetupShizukuNote =>
      'Shizuku also lets touches pass through the screen covers.';

  @override
  String get wsetupChannel => 'One-time setup';

  @override
  String get wsetupNotifTitle => 'Waaiya setup: waiting for the pairing code';

  @override
  String get wsetupFoundTitle => 'Pairing screen found';

  @override
  String get wsetupBusyTitle => 'Waaiya setup';

  @override
  String get wsetupDoneTitle => 'Setup done';

  @override
  String get wsetupDoneBody =>
      'Waaiya can now silence the original sound. You can turn Wireless debugging off.';

  @override
  String get wsetupDoneHelperBody =>
      'Done. This phone does not let apps keep these permissions, so Waaiya’s helper silences the original sound instead. The helper stops when the phone restarts and when Waaiya is updated. When you open Waaiya after that, it starts the helper again by itself if Wireless debugging is on; if not, it shows a button for it.';

  @override
  String get helperMissingTitle => 'Waaiya’s helper is stopped';

  @override
  String get helperMissingBody =>
      'This phone does not keep Waaiya’s permissions, so Waaiya uses its helper. The helper stops when the phone restarts and when Waaiya is updated. Connect to Wi-Fi, turn on “Wireless debugging” in Developer options, then tap “Start Waaiya’s helper”.';

  @override
  String get helperChannel => 'Waaiya’s helper';

  @override
  String get helperStarting => 'Starting the helper…';

  @override
  String get helperModeNote =>
      'This phone does not let apps keep these permissions: Waaiya’s helper does the work. It stops when the phone restarts and when Waaiya is updated. When you open Waaiya after that, it starts the helper again by itself if Wireless debugging is on; if not, it shows a button for it.';

  @override
  String get helperTipXiaomi =>
      'Optional, to keep the permissions for good (no helper after restarts): in Developer options, turn on “USB debugging (Security settings)” (it asks you to sign in to a Xiaomi account), then do the setup again.';

  @override
  String get helperTipColoros =>
      'Optional, to keep the permissions for good (no helper after restarts): in Developer options, turn on “Disable permission monitoring” (on the newest versions “Disable system optimization”; it may show only with the phone set to English), then do the setup again.';

  @override
  String get stateOnHelperMissing =>
      'The original sound is not silenced, so you hear the music together with the filtered sound: Waaiya’s helper is stopped. Connect to Wi-Fi, turn on Wireless debugging, then tap “Start Waaiya’s helper”.';

  @override
  String get setupRefusedTryWireless =>
      'Or use “Set up on this phone” on this page: Waaiya’s helper then works without that switch.';

  @override
  String get helperStartAnywayTitle => 'Waaiya’s helper is stopped';

  @override
  String get helperStartAnywayBody =>
      'Without it you will hear the music together with the filtered sound. Start the helper first (Wireless debugging must be on), or start filtering anyway.';

  @override
  String get wsetupFailedTitle => 'Setup did not finish';

  @override
  String get wsetupPairing => 'Pairing…';

  @override
  String get wsetupConnecting => 'Connecting and giving the permissions…';

  @override
  String get wsetupNeedWifi =>
      'Connect to a Wi-Fi network first (internet is not needed): Wireless debugging works only on Wi-Fi.';

  @override
  String get wsetupNeedWirelessDebugging =>
      'In Developer options, turn on “Wireless debugging”, then tap its name and “Pair device with pairing code”.';

  @override
  String get wsetupOpenDialog =>
      'In Wireless debugging, tap “Pair device with pairing code”. Keep the code on screen and tap “Enter code” here.';

  @override
  String get wsetupEnterCodeBody =>
      'Tap “Enter code” and type the 6-digit code shown in Settings.';

  @override
  String get wsetupCodeWaiting =>
      'Got the code. Waiting for the “Pair device with pairing code” screen: keep it open.';

  @override
  String get wsetupWrongCode =>
      'That code was not accepted. Check the 6 digits on screen and enter them again. If the pairing screen closed, open it again: the code changes.';

  @override
  String get wsetupPairingFailed =>
      'Pairing did not work. Close the pairing screen, open “Pair device with pairing code” again and enter the new code.';

  @override
  String get wsetupWaitingConnect =>
      'Paired. Keep “Wireless debugging” on: Waaiya is connecting.';

  @override
  String get wsetupNotPaired =>
      'This phone no longer knows Waaiya (the pairing was removed or expired). Open “Pair device with pairing code” and enter the code.';

  @override
  String get wsetupConnectFailed =>
      'Could not connect to Wireless debugging. Turn it off and on again: Waaiya tries again by itself.';

  @override
  String get wsetupGrantFailed =>
      'Connected, but the permissions are still missing. Use Shizuku or a computer below.';

  @override
  String get wsetupTimeout =>
      'Stopped after 10 minutes without finishing. You can try again.';

  @override
  String get wsetupCodeUnreadable => 'Type the 6 digits of the pairing code.';

  @override
  String get wsetupCodeHint => '6-digit code';

  @override
  String get wsetupEnterCode => 'Enter code';

  @override
  String wsetupDetail(String details) {
    return 'Details: $details';
  }

  @override
  String get wsetupErrTimeout => 'no answer in time';

  @override
  String get wsetupErrRefused => 'connection refused';

  @override
  String get wsetupDevOff =>
      'Developer options are off. In About phone, tap “Build number” 7 times, then come back.';

  @override
  String get wsetupOpenAbout => 'About phone';

  @override
  String get wsetupNotifOff =>
      'Notifications are off for Waaiya, so the code cannot be typed in a notification. Use split screen (Settings in one half, Waaiya in the other) and tap “Type the code here”.';

  @override
  String get wsetupCodeDialogTitle => 'Pairing code';

  @override
  String get wsetupCodeDialogBody =>
      'Only with split screen (Settings in one half, Waaiya in the other): leaving Settings closes the pairing screen and its code stops working. Type the 6-digit code shown under “Pair device with pairing code”.';

  @override
  String get wsetupCodeOk => 'Pair';

  @override
  String get blurStrictTitle => 'Who is left uncovered';

  @override
  String blurStrictValue(String level) {
    return 'Who is left uncovered: $level';
  }

  @override
  String get blurStrict0 =>
      'Strict: only people the app is almost certain are men';

  @override
  String get blurStrict1 => 'Balanced: about twice as many men left uncovered';

  @override
  String get blurStrict2 => 'Relaxed: a few more men than balanced';

  @override
  String get blurStrict0Short => 'strict';

  @override
  String get blurStrict1Short => 'balanced';

  @override
  String get blurStrict2Short => 'relaxed';

  @override
  String get blurStrictHelp =>
      'Anyone the app is not sure is a man is covered. Strict leaves about 7 men in 100 uncovered; balanced about 14, relaxed about 16. Each step less strict also leaves about 1 more woman in 100 uncovered.';

  @override
  String get stateOnNotMuted =>
      'The original sound is not silenced yet, so you hear the music together with the filtered sound. Finish the one-time setup below.';

  @override
  String get stateOnMuteFailing =>
      'Waaiya cannot silence the original sound of the app playing now, so the music may still be heard. Stop and start filtering. If it stays, send the diagnostics report (at the bottom of this screen).';

  @override
  String get stateTooSlow =>
      'This phone is too slow to filter live sound, so the sound cuts. \"Open a link\" below still works: it filters the video before playing it.';

  @override
  String get stateMonoNote =>
      'The sound is in mono so that this phone keeps up.';

  @override
  String stateBlockedSilenced(String apps) {
    return 'Silenced, because it does not allow filtering: $apps.';
  }

  @override
  String stateBlockedUnfiltered(String apps) {
    return 'Playing unfiltered, because it does not allow filtering: $apps.';
  }

  @override
  String get stateCaptureFailed =>
      'Android did not give Waaiya the sound of other apps. Tap the button to start again.';

  @override
  String get stateCaptureCancelled =>
      'Starting was cancelled at Android\'s screen-sharing question. Waaiya needs \"Start\" there to receive the sound. Nothing is recorded or sent.';

  @override
  String get startNoSetupTitle => 'The music will still be heard';

  @override
  String get startNoSetupBody =>
      'The one-time setup is not done yet. Without it Waaiya cannot silence the original sound: you will hear the music and the filtered sound together.\n\n\"Open a link\" works without any setup.';

  @override
  String get startNoSetupSetup => 'Do the setup';

  @override
  String get startNoSetupAnyway => 'Start anyway';

  @override
  String get diagButton => 'Problem? Diagnostics report';

  @override
  String get diagTitle => 'Diagnostics report';

  @override
  String get diagNote =>
      'What Waaiya sees on this phone. Copy it or share it with whoever helps you. The app itself sends nothing.';

  @override
  String get notifStoppedTitle => 'Waaiya stopped';

  @override
  String get notifStoppedText =>
      'The sound is not filtered any more. Tap to start again.';

  @override
  String get wsetupGuide => 'Steps with pictures';

  @override
  String get navFilter => 'Filter';

  @override
  String get navScreen => 'Screen';

  @override
  String get navLinks => 'Links';

  @override
  String get navSetup => 'Setup';

  @override
  String get navSettings => 'Settings';

  @override
  String get setupDoneTitle => 'Setup done';

  @override
  String get setupDoneBody =>
      'Waaiya can silence the original sound of other apps. Do it again only if something changed (the setup was undone, or Waaiya says it is missing).';

  @override
  String get setupRedo => 'Show the setup again';

  @override
  String get setupGo => 'Go to the setup';

  @override
  String get helperTitle => 'Touches through the covers';

  @override
  String get helperBodyOff =>
      'Without help, a cover blocks the touches under it. Waaiya\'s helper draws the covers so that touches pass through. Turn on Wireless debugging (Wi-Fi is needed) and tap the button; the first time, pair once as in the setup. After the phone restarts, tap it again.';

  @override
  String get helperStart => 'Start Waaiya\'s helper';

  @override
  String get helperOn =>
      'Waaiya\'s helper draws the covers: touches pass through them. It stops when the phone restarts or when USB debugging is turned off; tap the button again then.';

  @override
  String get helperShizukuOn =>
      'Shizuku draws the covers: touches pass through them.';

  @override
  String get helperOrShizuku => 'Or with Shizuku:';

  @override
  String get filterOptionsTitle => 'Filter options';

  @override
  String get settingsGeneralTitle => 'General';

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
  String get worshipPrayerFajr => 'Fajr';

  @override
  String get worshipPrayerSunrise => 'Sunrise';

  @override
  String get worshipPrayerDhuhr => 'Dhuhr';

  @override
  String get worshipPrayerAsr => 'Asr';

  @override
  String get worshipPrayerMaghrib => 'Maghrib';

  @override
  String get worshipPrayerIsha => 'Isha';

  @override
  String get worshipEndSilent => 'End silence now';

  @override
  String get worshipUnmute => 'Unmute now';

  @override
  String get worshipSmsDefault =>
      'It\'s prayer time, I can\'t answer now. I\'ll call you back.';

  @override
  String get desktopPreview =>
      'Preview: the filter engine is not connected on this computer yet. The button only shows how the app will work.';

  @override
  String actionFailed(String details) {
    return 'That did not work: $details';
  }

  @override
  String get stateOnDetailNoDelay => 'Instruments are removed from all apps.';

  @override
  String get engineErrorNoPactl =>
      'Sound tools not found (pactl). Waaiya needs PulseAudio, or PipeWire with pipewire-pulse.';

  @override
  String get engineErrorNoSoundServer =>
      'The sound server is not running (PulseAudio or PipeWire).';

  @override
  String get engineErrorNoSystemd =>
      'This system has no systemd user session, which runs the filter in the background.';

  @override
  String get engineErrorNoOutput => 'No speakers or headphones found.';

  @override
  String engineErrorInstallFailed(String details) {
    return 'Could not install the filter. Details:\n$details';
  }

  @override
  String engineErrorStartFailed(String details) {
    return 'The filter did not start. Details:\n$details';
  }

  @override
  String engineErrorServiceFailed(String details) {
    return 'The filter stopped with an error. Details:\n$details';
  }

  @override
  String get autostartTitle => 'Start at login';

  @override
  String get autostartBody => 'Filter the sound as soon as you log in.';

  @override
  String get blurBodyDesktop =>
      'Covers people and images on screen, over every window, while Waaiya is open (it works whether the sound filter is on or off). It runs on this computer; nothing is sent anywhere. Closing the Waaiya window stops the blur.';

  @override
  String get blurFailBodyDesktop =>
      'On: the whole screen is covered when the computer is too slow or the blur fails; clicks still reach the windows underneath. Off: the screen stays visible with a red bar at the top.';

  @override
  String get blurStatusOnVisibleDesktop =>
      'Blur on. This desktop shows the blur in its own screen capture, so a blurred area stays blurred until the scene changes.';

  @override
  String blurStatusNoOverlayDesktop(String details) {
    return 'The blur cannot draw over other windows on this desktop. Details:\n$details';
  }

  @override
  String get blurStatusShareDialog =>
      'Choose your screen in the screen-sharing window and allow it. Waaiya asks only once; the picture stays on this computer.';

  @override
  String blurStatusExited(String details) {
    return 'The blur stopped unexpectedly. Turn a blur option off and on to try again. Details:\n$details';
  }

  @override
  String get engineDetectorFailed =>
      'The women\'s singing detector did not load, so voices are muted while that option is on.';

  @override
  String get blurStatusUncovered =>
      'A monitor is not covered by the blur: it was not shared with it, or it was plugged in later. Turn a blur option off and on, and choose every screen in the screen-sharing window.';

  @override
  String get blurStatusModelsMissingDesktop =>
      'The blur\'s models are missing from this installation, so it cannot cover anything; a red bar stays at the top of the screen. Reinstall Waaiya.';

  @override
  String get diagNoteDesktop =>
      'What Waaiya sees on this computer. Copy it and give it to whoever helps you. The app itself sends nothing.';

  @override
  String get settingHoldSilenceBodyDesktop =>
      'Recommended. If filtering stops by itself (an error, not you), other apps stay silent until you start again or press Stop, instead of playing music unfiltered.';

  @override
  String get settingStereoBodyDesktop =>
      'Off: mono, which uses less of the computer. On: keeps the left and right sides apart. If the computer is too slow for stereo, it switches to mono by itself.';

  @override
  String get linkEntryBodyDesktop =>
      'Paste a YouTube, TikTok or Instagram link to watch it with the filter on, or to save it without music.';

  @override
  String get linkEntryBodyWatch =>
      'Paste a YouTube, TikTok or Instagram link to watch it in your browser with the filter on.';

  @override
  String get linkWatchNoteDesktop =>
      'Opens in your browser. Waaiya starts the filter first, so the music is removed there too.';

  @override
  String get linkFilterFailed =>
      'The filter did not start, so the link was not opened. Start it on the Filter page and try again.';

  @override
  String get linkSavedVideoDesktop => 'In your Videos folder: Waaiya';

  @override
  String get linkSavedAudioDesktop => 'In your Music folder: Waaiya';

  @override
  String get linkShowInFolder => 'Show in folder';

  @override
  String get linkSingingNote =>
      'Women\'s singing is muted too, as in your settings.';

  @override
  String get singingKeepTitle => 'Keep singing (test)';

  @override
  String get singingKeepBody =>
      'Instruments are removed but singing voices are kept, so a lecture with a nasheed under it keeps the nasheed\'s voice too; whether that is acceptable is your choice.';

  @override
  String get singingKeepNoModel =>
      'This version has no singing model, so the sound stays silent while this is on. Turn it off.';

  @override
  String get fixFilterAppsTitle => 'Apps heard unfiltered';

  @override
  String get fixFilterAppsBody =>
      'Apps you choose here play as they are: no filter and no silence. For example, a video-call app, so that calls have no delay.';

  @override
  String get fixAddApp => 'Add an app';

  @override
  String fixRemoveApp(Object app) {
    return 'Remove $app';
  }

  @override
  String get fixNoApps => 'No app chosen.';

  @override
  String get fixPickTitle => 'Choose an app';

  @override
  String get fixPickEmpty => 'No other app found.';

  @override
  String get fixPickPlayingDesktop =>
      'Apps playing sound now, and the ones already chosen.';

  @override
  String get fixCancel => 'Cancel';

  @override
  String get fixBlurAppsTitle => 'Apps left uncovered';

  @override
  String get fixBlurAppsBody =>
      'No covers while one of these apps fills the screen, for example a maps app or your bank\'s app. The covers come back as soon as you leave it, or whenever Waaiya is not sure which app is shown.';

  @override
  String get fixBlurAppsNeedsSetup =>
      'Needs the one-time setup: without it Waaiya cannot tell which app is on screen, so the blur stays on everywhere.';

  @override
  String get fixBlurAppsHelperMode =>
      'Waaiya\'s helper is not running, so the app on screen cannot be read. The blur stays on everywhere until the helper is started again from the Setup page.';

  @override
  String get fixHandTitle => 'Cover an area by hand';

  @override
  String get fixHandBody =>
      'While the blur runs, you can cover a part of the screen yourself, for example a picture the blur missed: tap “Cover an area” and drag your finger over it. It stays covered until you remove it or the blur stops.';

  @override
  String get fixHandNotRunning =>
      'Available while the blur runs: filtering on and a blur option on.';

  @override
  String get fixCoverArea => 'Cover an area';

  @override
  String fixRemoveCovers(Object count) {
    return 'Remove hand covers ($count)';
  }

  @override
  String get fixNoteTitle => 'Note a mistake';

  @override
  String get fixNoteBody =>
      'When Waaiya gets something wrong, tap what happened, for example “Music got through”. The note keeps the time, the app and the settings, to help find the cause. It stays on this device and is never sent.';

  @override
  String get fixMissedSound => 'Music got through';

  @override
  String get fixWrongSound => 'Voice removed by mistake';

  @override
  String get fixMissedScreen => 'Something was not covered';

  @override
  String get fixWrongScreen => 'Covered by mistake';

  @override
  String fixNoted(Object count) {
    return 'Noted ($count notes on this device).';
  }

  @override
  String fixNotesCount(Object count) {
    return 'Notes on this device: $count';
  }

  @override
  String get fixNotesShow => 'Show the notes';

  @override
  String get fixNotesDelete => 'Delete notes';

  @override
  String get fixNotesDeleteAsk =>
      'Delete all the notes? This cannot be undone.';

  @override
  String get fixNotesTitle => 'Notes about mistakes';

  @override
  String get worshipTitle => 'Prayer times';

  @override
  String get worshipBody =>
      'Optional. Worked out on this phone from the place you choose. Nothing is sent.';

  @override
  String worshipPlace(Object place) {
    return 'Place: $place';
  }

  @override
  String get worshipPlaceNone => 'Place: not chosen';

  @override
  String get worshipChoose => 'Choose';

  @override
  String get worshipPlaceSearch => 'Search for a city';

  @override
  String get worshipPlaceNoMatch =>
      'No city found. You can enter coordinates instead.';

  @override
  String get worshipPlaceCustom => 'Enter coordinates';

  @override
  String get worshipLat => 'Latitude (north +, south −)';

  @override
  String get worshipLon => 'Longitude (east +, west −)';

  @override
  String get worshipZone => 'Time zone, for example Africa/Cairo';

  @override
  String get worshipCustomInvalid => 'Check the numbers and the time zone.';

  @override
  String get worshipPlaceInvalid =>
      'This place cannot be used. Choose it again.';

  @override
  String worshipMethod(Object method) {
    return 'Calculation: $method';
  }

  @override
  String get worshipMethodTitle => 'Calculation method';

  @override
  String get worshipMethodNote =>
      'Chosen from the city\'s country. Pick the one your mosque follows.';

  @override
  String worshipAsr(Object rule) {
    return 'Asr: $rule';
  }

  @override
  String get worshipAsrTitle => 'Asr time';

  @override
  String get worshipAsrStandard => 'Standard (Shafi\'i, Maliki, Hanbali)';

  @override
  String get worshipAsrHanafi => 'Hanafi';

  @override
  String get worshipMethodMwl => 'Muslim World League';

  @override
  String get worshipMethodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get worshipMethodEgypt => 'Egyptian General Authority of Survey';

  @override
  String get worshipMethodUmmAlQura => 'Umm al-Qura, Makkah';

  @override
  String get worshipMethodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get worshipMethodTehran =>
      'Institute of Geophysics, University of Tehran';

  @override
  String get worshipMethodGulf => 'Gulf region';

  @override
  String get worshipMethodKuwait => 'Kuwait';

  @override
  String get worshipMethodQatar => 'Qatar';

  @override
  String get worshipMethodSingapore => 'Singapore (MUIS)';

  @override
  String get worshipMethodTurkey => 'Turkey (Diyanet)';

  @override
  String get worshipMethodFrance => 'France (UOIF, 12°)';

  @override
  String get worshipMethodMorocco => 'Morocco (Ministry of Habous)';

  @override
  String get worshipMethodIndonesia => 'Indonesia (Kemenag)';

  @override
  String get worshipMethodMalaysia => 'Malaysia (JAKIM)';

  @override
  String get worshipMethodDubai => 'Dubai';

  @override
  String get worshipToday => 'Today';

  @override
  String get worshipNoTimes =>
      'No prayer times here today: the sun does not rise or does not set.';

  @override
  String get worshipSilentTitle => 'Silent at prayer times';

  @override
  String get worshipSilentBody =>
      'At each prayer time the phone goes silent (Do Not Disturb) for the minutes below, then comes back as it was. For example, from Dhuhr at 12:00 until 12:20.';

  @override
  String worshipSilentMinutes(Object minutes) {
    return 'Silent for: $minutes min';
  }

  @override
  String get worshipMuteTitle => 'Mute media at the adhan';

  @override
  String get worshipMuteBody =>
      'At each prayer time, media sound (videos, music, games) is muted for the minutes below. The notification can unmute it at once.';

  @override
  String worshipMuteMinutes(Object minutes) {
    return 'Muted for: $minutes min';
  }

  @override
  String get worshipMinutesTitle => 'Duration';

  @override
  String worshipMinutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get worshipNeedPlace => 'Choose a place first.';

  @override
  String worshipNext(Object prayer, Object time) {
    return 'Next: $prayer at $time';
  }

  @override
  String worshipSilentNow(Object time) {
    return 'Silent until $time.';
  }

  @override
  String worshipMutedNow(Object time) {
    return 'Media muted until $time.';
  }

  @override
  String get worshipDndNeeded =>
      'Allow Waaiya to change Do Not Disturb, or the phone cannot go silent.';

  @override
  String get worshipAllow => 'Allow';

  @override
  String get worshipExactNeeded =>
      'Alarms and reminders are not allowed for Waaiya, so each change may come up to 10 minutes late, or later while the phone sleeps.';

  @override
  String get worshipNotificationsNeeded =>
      'Notifications are off: you will not see when the phone goes silent or comes back.';

  @override
  String get worshipTonesTitle => 'Plain ringtone and notification sound';

  @override
  String get worshipTonesBody =>
      'Waaiya cannot filter the ringtone or notification sounds, only replace them. Choose a plain tone with no music:';

  @override
  String worshipToneRing(Object number) {
    return 'Plain ringtone $number';
  }

  @override
  String worshipToneNotification(Object number) {
    return 'Plain notification sound $number';
  }

  @override
  String get worshipTonePlay => 'Play';

  @override
  String get worshipToneSet => 'Use';

  @override
  String get worshipToneInUse => 'In use';

  @override
  String get worshipToneDone => 'Done.';

  @override
  String get worshipTonePermission =>
      'Allow Waaiya to modify system settings, come back, and tap again.';

  @override
  String get worshipToneFailed =>
      'This phone did not let Waaiya change it. In Sound settings, choose a tone named “Waaiya plain”.';

  @override
  String get worshipOpenSound => 'Open Sound settings';

  @override
  String get worshipSmsTitle => 'Reply to calls by SMS during prayer';

  @override
  String get worshipSmsBody =>
      'In the silent minutes after each prayer time, a call left ringing gets one SMS. Once per number per prayer; never to hidden numbers or short codes.';

  @override
  String worshipSmsDelay(Object seconds) {
    return 'After: $seconds s of ringing';
  }

  @override
  String get worshipSmsDelayTitle => 'Seconds of ringing before the SMS';

  @override
  String worshipSmsSecondsOption(Object seconds) {
    return '$seconds s';
  }

  @override
  String worshipSmsText(Object text) {
    return 'Message: $text';
  }

  @override
  String get worshipSmsTextTitle => 'Your message';

  @override
  String get worshipSmsTextDefault => 'Use the default';

  @override
  String get worshipSmsCost =>
      'Each reply is a normal SMS from your SIM, at your plan\'s price. Nothing is sent while roaming.';

  @override
  String get worshipSmsRoaming => 'Roaming now: no SMS is sent.';

  @override
  String get worshipSmsLogTitle => 'Replies sent (kept on this phone only)';

  @override
  String get worshipContinue => 'Continue';

  @override
  String get worshipWhyDnd =>
      'To make the phone silent at prayer times, allow Waaiya\'s Do Not Disturb access on the next page.';

  @override
  String get worshipWhyExact =>
      'To act exactly on time, allow Waaiya to set alarms and reminders on the next page. Without it, changes can come up to 10 minutes late.';

  @override
  String get worshipWhyNotifications =>
      'Allow notifications so that you see each change and can undo it.';

  @override
  String get worshipWhyWrite =>
      'To change your ringtone or notification sound, allow Waaiya to modify system settings on the next page.';

  @override
  String get worshipWhyPhone =>
      'To know that a call is ringing and its number, Waaiya needs the Phone and Call logs permissions. Nothing leaves the phone except your reply.';

  @override
  String get worshipWhySms =>
      'To send your reply, Waaiya needs permission to send SMS. It sends only that reply, at most once per number per prayer.';

  @override
  String get worshipMissingDnd =>
      'Do Not Disturb access was not allowed, so the silence stays off.';

  @override
  String get worshipMissingPhone =>
      'The Phone and Call logs permissions were not allowed, so the SMS reply stays off.';

  @override
  String get worshipMissingSms =>
      'Permission to send SMS was not allowed, so the SMS reply stays off.';

  @override
  String get worshipTryAgain => 'Try again';

  @override
  String get protectTitle => 'Protection for weak moments';

  @override
  String get protectBody =>
      'For a weak moment when you might want to turn the filter off. Set a wait now, while you are calm: then pressing the button to stop does not stop it at once, and you decide again when the wait is over. A parent can also set a PIN.';

  @override
  String protectDelay(Object value) {
    return 'Wait before turning off: $value';
  }

  @override
  String get protectDelayTitle => 'Wait before turning off';

  @override
  String get protectDelayBody =>
      'For example, with 30 minutes: you press the button to stop, but the filter keeps working. After 30 minutes, this page asks whether you still want to stop. Press “Confirm” within 15 minutes and it stops; otherwise nothing changes. It is the same for turning off a cover or any other protection. Turning things on always works at once.';

  @override
  String get protectDelayOff => 'None';

  @override
  String get protectDelay1m => '1 minute';

  @override
  String get protectDelay5m => '5 minutes';

  @override
  String get protectDelay15m => '15 minutes';

  @override
  String get protectDelay30m => '30 minutes';

  @override
  String get protectDelay1h => '1 hour';

  @override
  String get protectDelay4h => '4 hours';

  @override
  String get protectDelay24h => '24 hours';

  @override
  String protectDelayOther(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get protectPinNone => 'PIN: not set';

  @override
  String get protectPinIsSet => 'PIN: set';

  @override
  String get protectPinSet => 'Set a PIN';

  @override
  String get protectPinRemove => 'Remove';

  @override
  String get protectPinBody =>
      'With a PIN, stopping the filter or turning off any protection asks for the PIN first. For example, a parent sets one so that a child cannot turn the filter off. Changing the wait or the PIN asks for it too.';

  @override
  String get protectPinForgot =>
      'Write the PIN down somewhere safe: if it is forgotten, there is no reset. The only way out is to clear Waaiya\'s data or reinstall it, which also erases all its settings.';

  @override
  String get protectPinTitle => 'Enter the PIN';

  @override
  String get protectPinNewTitle => 'Choose a PIN';

  @override
  String get protectPinChangeTitle => 'Change the PIN';

  @override
  String get protectPinCurrent => 'Current PIN';

  @override
  String get protectPinNew => 'New PIN (4 to 8 digits)';

  @override
  String get protectPinAgain => 'New PIN again';

  @override
  String get protectPinBad => 'Use 4 to 8 digits.';

  @override
  String get protectPinDiffer => 'The two new PINs are not the same.';

  @override
  String protectPinWrong(Object count) {
    return 'Wrong PIN. $count tries left before a pause.';
  }

  @override
  String protectLocked(Object time) {
    return 'Too many wrong tries. Try again at $time.';
  }

  @override
  String get protectOk => 'OK';

  @override
  String get protectCancel => 'Cancel';

  @override
  String get protectCancelChange => 'Cancel the change';

  @override
  String get protectConfirm => 'Confirm';

  @override
  String protectPending(Object time, Object what) {
    return '$what: waiting until $time. Then confirm it in “Settings”.';
  }

  @override
  String protectReady(Object time, Object what) {
    return '$what: the wait is over. Do you still want it? Press “Confirm” before $time; otherwise nothing changes.';
  }

  @override
  String get protectWaitTitle => 'This change waits';

  @override
  String protectWaitBody(Object time, Object what) {
    return '$what does not happen now. At $time, if you still want it, confirm it in “Settings” within 15 minutes. If you do nothing, nothing changes.';
  }

  @override
  String get protectWaitStart => 'Start waiting';

  @override
  String protectAlreadyWaiting(Object time) {
    return 'Already waiting until $time.';
  }

  @override
  String protectStarted(Object time) {
    return 'Waiting until $time. Then confirm it in “Settings”.';
  }

  @override
  String protectTomorrow(Object time) {
    return 'tomorrow at $time';
  }

  @override
  String get protectHeldBack =>
      'Not now: your protection settings make this change wait, or ask for the PIN.';

  @override
  String get protectLimits =>
      'What this cannot stop: force stop, uninstalling, clearing Waaiya\'s data and Android\'s own settings. Blocking those would need special Android permissions that Waaiya does not use. This protects against a weak moment, not against a determined person.';

  @override
  String get protectLimitsDesktop =>
      'What this cannot stop: the waaiya command in a terminal, removing Waaiya or deleting its settings folder. This protects against a weak moment, not against a determined person.';

  @override
  String get protectLimitsWindows =>
      'What this cannot stop: the waaiya-filter.exe command in a terminal, removing Waaiya or deleting its settings folder. This protects against a weak moment, not against a determined person.';

  @override
  String get protectWhatStop => 'Stop the filter';

  @override
  String protectWhatOff(Object name) {
    return 'Turn off: $name';
  }

  @override
  String protectWhatOn(Object name) {
    return 'Turn on: $name';
  }

  @override
  String protectWhatApps(Object name) {
    return 'Add an app to: $name';
  }

  @override
  String get protectWhatStrictness => 'Make the blur less strict';

  @override
  String get protectWhatGender => 'Change who uses Waaiya';

  @override
  String protectWhatDelay(Object value) {
    return 'Change the wait before turning off to: $value';
  }

  @override
  String get protectWhatPinChange => 'Change the PIN';

  @override
  String get protectWhatPinClear => 'Remove the PIN';

  @override
  String get protectWhatSetting => 'Change a setting';

  @override
  String get onboardBodyDesktop =>
      'Waaiya removes musical instruments from the sound of every app on this computer. Speech and Quran recitation are kept. For now, singing voices are removed too.';
}
