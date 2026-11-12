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
      'The blur needs to draw over other apps. Best: start Shizuku (and allow Waaiya in it): the blur then draws its own layer, which taps pass through. Otherwise allow \"Display over other apps\" in Android settings; a tap on a blurred area then does not reach the app underneath.';

  @override
  String get blurFailUnavailable =>
      'Greyed out for now: a full-screen cover would block every tap and you could get stuck. Start Shizuku (Android 12 or newer) and it turns on: the covers are then drawn by Shizuku and taps go through them. Until then, when the blur cannot keep up, the screen stays visible with a warning.';

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
  String get wsetupRouteTitle => 'Set up on this phone (no extra app)';

  @override
  String get wsetupRouteBody =>
      'With Android\'s own Wireless debugging. You need Wi-Fi (internet is not needed). Pairing is done once.';

  @override
  String get wsetupSteps =>
      '1. Tap “Start”. Waaiya opens Developer options and shows a notification.\n\n2. If Developer options are off, About phone opens instead: tap “Build number” 7 times (on some phones it is under Software information), come back and tap “Start” again.\n\n3. Scroll down to “Wireless debugging” (under Debugging), turn it on and confirm “Allow”.\n\n4. Tap the words “Wireless debugging” (not the switch), then “Pair device with pairing code”. A 6-digit code appears.\n\n5. Keep that screen open. Pull down the notifications, tap “Enter code” in Waaiya\'s notification and type the code.\n\n6. Waaiya finishes by itself and says “Setup done”. You can then turn Wireless debugging off.';

  @override
  String get wsetupStart => 'Start';

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
      'Stopped after 10 minutes without finishing. Tap “Start” to try again.';

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
      'Developer options are off. In About phone, tap “Build number” 7 times (on some phones it is under Software information), then come back and tap “Start” again.';

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
}
