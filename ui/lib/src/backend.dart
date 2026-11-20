/// The contract between the shared screens and a native backend (docs/UI_CONTRACT.md).
library;

import 'dart:typed_data';

/// Settings keys, exactly as in Android's Settings.kt (SharedPreferences file "settings").
abstract final class SettingKeys {
  static const gender = 'gender';
  static const muteWomenSinging = 'mute_women_singing';
  static const silenceUnfilterable = 'silence_unfilterable';
  static const blurWomen = 'blur_women';
  static const blurNudity = 'blur_nudity';
  static const blurFailCover = 'blur_fail_cover';

  /// Screen blur: who is left uncovered. 0 strict (default), 1 balanced, 2 relaxed (Settings.blurStrictness).
  static const blurStrictness = 'blur_strictness';

  /// Live filter in stereo; off = mono (owner's decision 0.2.10: about half the battery, keeps up on more
  /// devices). Settings.audioStereo.
  static const audioStereo = 'audio_stereo';

  /// When filtering stops by itself (not the user's Stop), other apps stay silent until the user starts again or
  /// stops (owner's decision 0.2.10). Settings.holdSilence. Linux: off = streams go back to the real output with a
  /// desktop notice.
  static const holdSilence = 'hold_silence';

  // 0.2.13 features (docs/FEATURES_CONTRACT.md). Changes that weaken protection may be refused with
  // BackendException('protected') by the waiting period or the PIN (Protection.checkSetting on Android).

  /// Apps the live filter leaves alone: comma-separated package names (Android) or application names (desktop).
  static const filterOffApps = 'filter_off_apps';

  /// Apps the screen blur leaves alone while in the foreground: comma-separated package names.
  static const blurOffApps = 'blur_off_apps';

  /// Keep singing voices (voice_v1 model, a test): off by default.
  static const keepSinging = 'keep_singing';

  /// Phone silent for [prayerSilentMinutes] from each prayer time; media muted [prayerAdhanMinutes] at the adhan.
  static const prayerSilent = 'prayer_silent';
  static const prayerSilentMinutes = 'prayer_silent_minutes';
  static const prayerAdhanMute = 'prayer_adhan_mute';
  static const prayerAdhanMinutes = 'prayer_adhan_minutes';

  /// A bundled city id, or "custom:LAT,LON,TZID"; "" = not chosen.
  static const prayerPlace = 'prayer_place';

  /// Calculation method index and Asr rule (0 standard, 1 Hanafi): the user's choice, never decided by the app.
  static const prayerMethod = 'prayer_method';
  static const prayerAsr = 'prayer_asr';

  /// Waiting period in minutes before switching off or weakening takes effect; 0 = none.
  static const protectDelayMinutes = 'protect_delay_minutes';

  /// Integer settings and their allowed range (inclusive).
  static const Map<String, (int, int)> ranges = {
    blurStrictness: (0, 2),
    prayerSilentMinutes: (5, 90),
    prayerAdhanMinutes: (1, 30),
    prayerMethod: (0, 15),
    prayerAsr: (0, 1),
    protectDelayMinutes: (0, 1440),
  };

  /// Key -> default value. The value's type is the key's type.
  static const Map<String, Object> defaults = {
    gender: '',
    muteWomenSinging: false,
    silenceUnfilterable: true,
    blurWomen: false,
    blurNudity: false,
    blurFailCover: true,
    blurStrictness: 0,
    audioStereo: false,
    holdSilence: true,
    filterOffApps: '',
    blurOffApps: '',
    keepSinging: false,
    prayerSilent: false,
    prayerSilentMinutes: 20,
    prayerAdhanMute: false,
    prayerAdhanMinutes: 5,
    prayerPlace: '',
    prayerMethod: 0,
    prayerAsr: 0,
    protectDelayMinutes: 0,
  };

  /// Returns an error text when [key]/[value] is not a valid setting, else null.
  static String? validate(String key, Object? value) {
    final def = defaults[key];
    if (def == null) return 'unknown setting "$key"';
    if (def is bool && value is! bool) return '"$key" takes a bool';
    if (def is int) {
      final (lo, hi) = ranges[key] ?? (0, 2);
      if (value is! int || value < lo || value > hi) return '"$key" takes $lo to $hi';
    }
    if (def is String) {
      if (value is! String) return '"$key" takes a string';
      if (key == gender && !const {'', 'man', 'woman'}.contains(value)) return 'gender is "", "man" or "woman"';
    }
    return null;
  }
}

/// User choices (Settings.kt).
class WaaiyaSettings {
  const WaaiyaSettings({
    this.gender = '',
    this.muteWomenSinging = false,
    this.silenceUnfilterable = true,
    this.blurWomen = false,
    this.blurNudity = false,
    this.blurFailCover = true,
    this.blurStrictness = 0,
    this.audioStereo = false,
    this.holdSilence = true,
    this.filterOffApps = const [],
    this.blurOffApps = const [],
    this.keepSinging = false,
    this.prayerSilent = false,
    this.prayerSilentMinutes = 20,
    this.prayerAdhanMute = false,
    this.prayerAdhanMinutes = 5,
    this.prayerPlace = '',
    this.prayerMethod = 0,
    this.prayerAsr = 0,
    this.protectDelayMinutes = 0,
  });

  factory WaaiyaSettings.fromMap(Map<Object?, Object?> m) => WaaiyaSettings(
        gender: _str(m[SettingKeys.gender]) ?? '',
        muteWomenSinging: _bool(m[SettingKeys.muteWomenSinging], false),
        silenceUnfilterable: _bool(m[SettingKeys.silenceUnfilterable], true),
        blurWomen: _bool(m[SettingKeys.blurWomen], false),
        blurNudity: _bool(m[SettingKeys.blurNudity], false),
        blurFailCover: _bool(m[SettingKeys.blurFailCover], true),
        blurStrictness: _int(m[SettingKeys.blurStrictness]).clamp(0, 2),
        audioStereo: _bool(m[SettingKeys.audioStereo], false),
        holdSilence: _bool(m[SettingKeys.holdSilence], true),
        filterOffApps: _csv(m[SettingKeys.filterOffApps]),
        blurOffApps: _csv(m[SettingKeys.blurOffApps]),
        keepSinging: _bool(m[SettingKeys.keepSinging], false),
        prayerSilent: _bool(m[SettingKeys.prayerSilent], false),
        prayerSilentMinutes: _intOr(m[SettingKeys.prayerSilentMinutes], 20).clamp(5, 90),
        prayerAdhanMute: _bool(m[SettingKeys.prayerAdhanMute], false),
        prayerAdhanMinutes: _intOr(m[SettingKeys.prayerAdhanMinutes], 5).clamp(1, 30),
        prayerPlace: _str(m[SettingKeys.prayerPlace]) ?? '',
        prayerMethod: _int(m[SettingKeys.prayerMethod]).clamp(0, 15),
        prayerAsr: _int(m[SettingKeys.prayerAsr]).clamp(0, 1),
        protectDelayMinutes: _int(m[SettingKeys.protectDelayMinutes]).clamp(0, 1440),
      );

  /// "man", "woman" or "" (not answered yet: the onboarding is shown).
  final String gender;
  final bool muteWomenSinging;
  final bool silenceUnfilterable;
  final bool blurWomen;
  final bool blurNudity;
  final bool blurFailCover;

  /// 0 strict (default), 1 balanced, 2 relaxed.
  final int blurStrictness;
  final bool audioStereo;
  final bool holdSilence;

  /// Sorted, no empty entries ([SettingKeys.filterOffApps]; stored comma-separated).
  final List<String> filterOffApps;
  final List<String> blurOffApps;
  final bool keepSinging;
  final bool prayerSilent;
  final int prayerSilentMinutes;
  final bool prayerAdhanMute;
  final int prayerAdhanMinutes;
  final String prayerPlace;
  final int prayerMethod;
  final int prayerAsr;
  final int protectDelayMinutes;

  bool get isMan => gender == 'man';
  bool get blurOn => blurWomen || blurNudity;

  Map<String, Object> toMap() => {
        SettingKeys.gender: gender,
        SettingKeys.muteWomenSinging: muteWomenSinging,
        SettingKeys.silenceUnfilterable: silenceUnfilterable,
        SettingKeys.blurWomen: blurWomen,
        SettingKeys.blurNudity: blurNudity,
        SettingKeys.blurFailCover: blurFailCover,
        SettingKeys.blurStrictness: blurStrictness,
        SettingKeys.audioStereo: audioStereo,
        SettingKeys.holdSilence: holdSilence,
        SettingKeys.filterOffApps: filterOffApps.join(','),
        SettingKeys.blurOffApps: blurOffApps.join(','),
        SettingKeys.keepSinging: keepSinging,
        SettingKeys.prayerSilent: prayerSilent,
        SettingKeys.prayerSilentMinutes: prayerSilentMinutes,
        SettingKeys.prayerAdhanMute: prayerAdhanMute,
        SettingKeys.prayerAdhanMinutes: prayerAdhanMinutes,
        SettingKeys.prayerPlace: prayerPlace,
        SettingKeys.prayerMethod: prayerMethod,
        SettingKeys.prayerAsr: prayerAsr,
        SettingKeys.protectDelayMinutes: protectDelayMinutes,
      };
}

/// FilterService.State. `stoppedBySystem` on desktop: the filter stopped by itself (the service died or failed).
/// `silenced`: filtering stopped by itself and `hold_silence` keeps the other apps muted until the user starts again
/// or stops (then they play unfiltered); not running.
enum FilterState {
  stopped,
  starting,
  filtering,
  modelFailed,
  noCapturePermission,
  stoppedBySystem,
  captureFailed,
  silenced,
}

/// `filter.problem`: what the user hears is not what filtering promises (shown instead of the "on" detail).
abstract final class FilterProblem {
  /// The phone cannot filter live in time: the sound cuts (FilterService.health.tooSlow).
  static const tooSlow = 'too_slow';

  /// The original sound is not silenced yet: the one-time setup is missing (SessionMuter NO_PERMISSION).
  static const notMuted = 'not_muted';

  /// Silencing the playing app's original sound fails (SessionMuter FAILING).
  static const muteFailing = 'mute_failing';

  /// Helper mode (the phone refused the grants) and Waaiya's helper is not running: the original plays too.
  static const helperMissing = 'helper_missing';

  /// Desktop: the women's-singing detector did not load; voices are muted while that option is on (fail-closed).
  static const detectorFailed = 'detector_failed';
}

/// ShizukuSetup.State.
enum ShizukuState { notInstalled, notRunning, tooOld, needsPermission, deniedPermanently, ready }

/// ScreenBlur.State; `noCapture` only on desktop (the screen cannot be captured, see `blur.error`).
enum BlurState { starting, on, onCoversVisible, noOverlay, modelsMissing, failing, noCapture }

/// A result or failure reported by native code: a machine [code] (the UI picks the text) and a raw [detail].
class BackendMessage {
  const BackendMessage(this.code, [this.detail = '']);
  final String code;
  final String detail;

  static BackendMessage? fromMap(Object? m) =>
      m is Map ? BackendMessage(_str(m['code']) ?? 'error', _str(m['detail']) ?? '') : null;

  Map<String, Object> toMap() => {'code': code, 'detail': detail};
}

class FilterInfo {
  const FilterInfo({
    this.state = FilterState.stopped,
    this.delayMs = 0,
    this.micDenied = false,
    this.simulated = false,
    this.error,
    this.autostart = false,
    this.problem,
    this.mono = false,
    this.blockedApps = const [],
    this.captureCancelled = false,
  });

  factory FilterInfo.fromMap(Map<Object?, Object?> m) => FilterInfo(
        state: _enum(FilterState.values, m['state']) ?? FilterState.stopped,
        delayMs: _int(m['delayMs']),
        micDenied: _bool(m['micDenied'], false),
        simulated: _bool(m['simulated'], false),
        error: BackendMessage.fromMap(m['error']),
        autostart: _bool(m['autostart'], false),
        problem: _str(m['problem']),
        mono: _bool(m['mono'], false),
        blockedApps: (m['blockedApps'] is List ? m['blockedApps'] as List : const []).whereType<String>().toList(),
        captureCancelled: _bool(m['captureCancelled'], false),
      );

  final FilterState state;
  final int delayMs;

  /// The microphone permission was refused at the last start.
  final bool micDenied;

  /// Desktop preview: start/stop are not connected to an engine yet.
  final bool simulated;

  /// Why the filter could not start or stopped (desktop engine host): `no_pactl`, `no_sound_server`, `no_systemd`,
  /// `no_output`, `install_failed`, `start_failed`, `service_failed` (detail = log lines). Null: no problem.
  final BackendMessage? error;

  /// The filter starts at login (capability `autostart`).
  final bool autostart;

  /// While filtering: a [FilterProblem] code, or null.
  final String? problem;

  /// The live sound was made mono so this device keeps up (Android: FilterService.health.mono).
  final bool mono;

  /// Apps playing now that do not allow their sound to be filtered (names); silenced or unfiltered according to
  /// `silence_unfilterable`.
  final List<String> blockedApps;

  /// Android's screen-sharing question was cancelled at the last start (until the next start).
  final bool captureCancelled;

  bool get running =>
      state == FilterState.starting || state == FilterState.filtering || state == FilterState.modelFailed;

  Map<String, Object?> toMap() => {
        'state': _enumName(state),
        'delayMs': delayMs,
        'micDenied': micDenied,
        'simulated': simulated,
        'error': error?.toMap(),
        'autostart': autostart,
        'problem': problem,
        'mono': mono,
        'blockedApps': blockedApps,
        'captureCancelled': captureCancelled,
      };
}

class SetupInfo {
  const SetupInfo({
    this.originalsMuted = true,
    this.consentSkipped = true,
    this.notificationTextNeedsSetup = false,
    this.deviceNote,
    this.helperMode = false,
    this.helperMissing = false,
    this.helperRestarting = false,
    this.helperTip,
    this.wireless = const WirelessInfo(),
    this.shizuku,
    this.busy = false,
    this.message,
    this.adbCommands,
  });

  factory SetupInfo.fromMap(Map<Object?, Object?> m) => SetupInfo(
        originalsMuted: _bool(m['originalsMuted'], true),
        consentSkipped: _bool(m['consentSkipped'], true),
        notificationTextNeedsSetup: _bool(m['notificationTextNeedsSetup'], false),
        deviceNote: _str(m['deviceNote']),
        helperMode: _bool(m['helperMode'], false),
        helperMissing: _bool(m['helperMissing'], false),
        helperRestarting: _bool(m['helperRestarting'], false),
        helperTip: _str(m['helperTip']),
        wireless: WirelessInfo.fromMap(_map(m['wireless'])),
        shizuku: _enum(ShizukuState.values, m['shizuku']),
        busy: _bool(m['busy'], false),
        message: BackendMessage.fromMap(m['message']),
        adbCommands: _str(m['adbCommands']),
      );

  /// The original sound can be silenced (Android: DUMP granted, or helper mode).
  final bool originalsMuted;

  /// Android: this phone refused the grants (Xiaomi, OPPO family), so Waaiya's helper reads the sound sessions.
  /// The helper stops when the phone restarts; Android asks before each capture (no PROJECT_MEDIA).
  final bool helperMode;

  /// Helper mode and the helper is not running now: the original sound plays next to the filtered one.
  final bool helperMissing;

  /// Helper mode and the setup service is starting the helper again (automatically or from the button).
  final bool helperRestarting;

  /// `xiaomi` or `coloros`: the optional Developer options switch that would make the permissions permanent.
  final String? helperTip;

  /// No screen-capture question at start (Android: app-op PROJECT_MEDIA allowed).
  final bool consentSkipped;

  /// The notification-text Quick Settings tile is on but its permission is missing (Android 15+): the same
  /// one-time setup grants it, so the setup card shows again.
  final bool notificationTextNeedsSetup;

  /// `xiaomi` or `coloros`: this phone needs a Developer options switch changed before the setup; null otherwise.
  final String? deviceNote;

  /// The setup on the phone itself (Android 11+: Wireless debugging, no Shizuku).
  final WirelessInfo wireless;
  final ShizukuState? shizuku;
  final bool busy;

  /// `failed` (detail = log), `refused`, `done_restart`, `error` (detail = text), `slow` (still waiting for
  /// Shizuku), `timeout`, `refused_xiaomi` / `refused_coloros` (the phone refused: a Developer options switch).
  final BackendMessage? message;
  final String? adbCommands;

  Map<String, Object?> toMap() => {
        'originalsMuted': originalsMuted,
        'consentSkipped': consentSkipped,
        'notificationTextNeedsSetup': notificationTextNeedsSetup,
        'deviceNote': deviceNote,
        'helperMode': helperMode,
        'helperMissing': helperMissing,
        'helperRestarting': helperRestarting,
        'helperTip': helperTip,
        'wireless': wireless.toMap(),
        'shizuku': shizuku == null ? null : _enumName(shizuku!),
        'busy': busy,
        'message': message?.toMap(),
        'adbCommands': adbCommands,
      };
}

class BlurInfo {
  const BlurInfo({
    this.state,
    this.overlayAllowed = false,
    this.a11yBuild = false,
    this.a11yEnabled = false,
    this.touchPassThrough = false,
    this.shizukuLayer = false,
    this.helperRunning = false,
    this.helperStartable = false,
    this.layerSupported = false,
    this.busy = false,
    this.message,
    this.error,
    this.uncovered = 0,
  });

  factory BlurInfo.fromMap(Map<Object?, Object?> m) => BlurInfo(
        state: _enum(BlurState.values, m['state']),
        overlayAllowed: _bool(m['overlayAllowed'], false),
        a11yBuild: _bool(m['a11yBuild'], false),
        a11yEnabled: _bool(m['a11yEnabled'], false),
        touchPassThrough: _bool(m['touchPassThrough'], false),
        shizukuLayer: _bool(m['shizukuLayer'], false),
        helperRunning: _bool(m['helperRunning'], false),
        helperStartable: _bool(m['helperStartable'], false),
        layerSupported: _bool(m['layerSupported'], false),
        busy: _bool(m['busy'], false),
        message: BackendMessage.fromMap(m['message']),
        error: BackendMessage.fromMap(m['error']),
        uncovered: _int(m['uncovered']),
      );

  /// Null when the blur is not running.
  final BlurState? state;
  final bool overlayAllowed;
  final bool a11yBuild;
  final bool a11yEnabled;
  final bool touchPassThrough;

  /// Shizuku is ready on Android 12+: the covers are a Shizuku shell layer, nothing else to allow.
  final bool shizukuLayer;

  /// Waaiya's own cover helper runs (Android 12+): it draws the covers and touches pass through them.
  final bool helperRunning;

  /// The helper can be started from here (Android 12+, through the on-phone setup).
  final bool helperStartable;

  /// The Shizuku cover layer is possible on this device (Android 12+), once Shizuku runs and allows Waaiya.
  final bool layerSupported;
  final bool busy;

  /// `setup_failed` (detail = log).
  final BackendMessage? message;

  /// Desktop blur helper: why it is not covering, or what it waits for. Codes: `no_capture`, `no_overlay`,
  /// `models_missing`, `failing` (detail = the helper's reason, untranslated), `share_dialog` (Wayland: the
  /// screen-share dialog is open), `exited` (the helper stopped; detail = its last output). Null: nothing to say.
  final BackendMessage? error;

  /// Desktop: monitors the blur does not cover (Wayland: not shared in the screen-sharing dialog, or plugged in
  /// after it). 0: every monitor is covered.
  final int uncovered;

  Map<String, Object?> toMap() => {
        'state': state == null ? null : _enumName(state!),
        'overlayAllowed': overlayAllowed,
        'a11yBuild': a11yBuild,
        'a11yEnabled': a11yEnabled,
        'touchPassThrough': touchPassThrough,
        'shizukuLayer': shizukuLayer,
        'helperRunning': helperRunning,
        'helperStartable': helperStartable,
        'layerSupported': layerSupported,
        'busy': busy,
        'message': message?.toMap(),
        'error': error?.toMap(),
        'uncovered': uncovered,
      };
}

/// What the platform offers. The screens hide what is false.
class Capabilities {
  const Capabilities({
    this.shizukuSetup = false,
    this.adbSetup = false,
    this.captureConsent = false,
    this.screenBlur = false,
    this.links = false,
    this.womenSinging = false,
    this.autostart = false,
    this.blurStandalone = false,
  });

  factory Capabilities.fromMap(Map<Object?, Object?> m) => Capabilities(
        shizukuSetup: _bool(m['shizukuSetup'], false),
        adbSetup: _bool(m['adbSetup'], false),
        captureConsent: _bool(m['captureConsent'], false),
        screenBlur: _bool(m['screenBlur'], false),
        links: _bool(m['links'], false),
        womenSinging: _bool(m['womenSinging'], false),
        autostart: _bool(m['autostart'], false),
        blurStandalone: _bool(m['blurStandalone'], false),
      );

  static const android = Capabilities(
      shizukuSetup: true, adbSetup: true, captureConsent: true, screenBlur: true, links: true, womenSinging: true);

  final bool shizukuSetup;
  final bool adbSetup;
  final bool captureConsent;
  final bool screenBlur;
  final bool links;
  final bool womenSinging;

  /// "Start at login" ([WaaiyaBackend.setAutostart]); desktop.
  final bool autostart;

  /// The blur runs on its own while a blur option is on, whether filtering is on or not (desktop, where it does
  /// not share the screen capture with the sound filter). Android: false, the blur runs while filtering.
  final bool blurStandalone;

  Map<String, bool> toMap() => {
        'shizukuSetup': shizukuSetup,
        'adbSetup': adbSetup,
        'captureConsent': captureConsent,
        'screenBlur': screenBlur,
        'links': links,
        'womenSinging': womenSinging,
        'autostart': autostart,
        'blurStandalone': blurStandalone,
      };
}

/// One full snapshot: the getState result and every event.
/// setup.wireless (docs/UI_CONTRACT.md): the on-phone setup's progress. [title] and [body] are Android string
/// names (wsetup_*, setup_refused_*), turned into words by [wirelessText].
class WirelessInfo {
  const WirelessInfo({
    this.supported = false,
    this.running = false,
    this.phase,
    this.title,
    this.body,
    this.detail,
    this.isError = false,
    this.hint,
    this.devOptions = true,
    this.wifi = true,
    this.wirelessDebugging,
    this.paired = false,
    this.aboutHint,
  });

  factory WirelessInfo.fromMap(Map<Object?, Object?> m) => WirelessInfo(
        supported: _bool(m['supported'], false),
        running: _bool(m['running'], false),
        phase: _str(m['phase']),
        title: _str(m['title']),
        body: _str(m['body']),
        detail: _str(m['detail']),
        isError: _bool(m['isError'], false),
        hint: _str(m['hint']),
        devOptions: _bool(m['devOptions'], true),
        wifi: _bool(m['wifi'], true),
        wirelessDebugging: m['wirelessDebugging'] is bool ? m['wirelessDebugging'] as bool : null,
        paired: _bool(m['paired'], false),
        aboutHint: _str(m['aboutHint']),
      );

  /// Android 11+ (pairing with a code).
  final bool supported;

  /// Waiting for the code, pairing or connecting.
  final bool running;

  /// WAITING, PAIRING, CONNECTING, DONE, FAILED; null before the first run.
  final String? phase;
  final String? title;
  final String? body;

  /// Raw output when no sentence explains it.
  final String? detail;
  final bool isError;

  /// Extra advice as a string name: `wsetup_notif_off`, `wsetup_dev_off`.
  final String? hint;

  /// The guided steps. What Waaiya can see of each one: hints for the ticks, never a gate (the Wi-Fi guess can be
  /// wrong, and [wirelessDebugging] is null on phones that do not let apps read that switch).
  final bool devOptions;
  final bool wifi;
  final bool? wirelessDebugging;

  /// Waaiya paired with this phone before: no code is needed, turning Wireless debugging on is enough.
  final bool paired;

  /// Where "Build number" is on this make of phone: `samsung`, `xiaomi`, `coloros`, `vivo`, `huawei`, or null.
  final String? aboutHint;

  Map<String, Object?> toMap() => {
        'supported': supported,
        'running': running,
        'phase': phase,
        'title': title,
        'body': body,
        'detail': detail,
        'isError': isError,
        'hint': hint,
        'devOptions': devOptions,
        'wifi': wifi,
        'wirelessDebugging': wirelessDebugging,
        'paired': paired,
        'aboutHint': aboutHint,
      };
}

/// `navigate`: show [page] once (`setup`, `filter`, `screen`, `links`, `settings`); [id] tells repeats apart.
class PageRequest {
  const PageRequest(this.page, this.id);
  final String page;
  final int id;

  static PageRequest? fromMap(Object? m) {
    if (m is! Map) return null;
    final page = m['page'];
    final id = m['id'];
    return page is String && id is int ? PageRequest(page, id) : null;
  }
}

/// The pictures of the illustrated setup guide (Android res/drawable-*-nodpi/guide_*.webp, one set per language).
const guidePictureNames = {
  'guide_1_about', 'guide_2_dev', 'guide_3_allow', 'guide_4_pair', 'guide_5_start', 'guide_6_code',
  'guide_7_notif', 'guide_8_reply', 'guide_9_done',
};

/// The app's languages: tag -> the language's own name (shown as is in every language). Arabic and English are
/// written by the project; the others are machine translations not reviewed yet (docs/STATUS.md). Keep in step with
/// Android's Lang.ALL and res/xml/locales_config.xml.
const appLanguages = <String, String>{
  'ar': 'العربية',
  'en': 'English',
  'fr': 'Français',
  'ur': 'اردو',
  'id': 'Bahasa Indonesia',
  'tr': 'Türkçe',
  'bn': 'বাংলা',
  'fa': 'فارسی',
  'ms': 'Bahasa Melayu',
};

/// [appLanguages]' tag for a system locale name such as "fr_FR.UTF-8", "id-ID" or "in", or null.
String? appLanguageOf(String? localeName) {
  if (localeName == null) return null;
  var tag = localeName.split(RegExp(r'[_.@-]')).first.toLowerCase();
  if (tag == 'in') tag = 'id';
  return appLanguages.containsKey(tag) ? tag : null;
}

class AppState {
  const AppState({
    this.platform = 'android',
    this.version = '',
    this.language = 'ar',
    this.settings = const WaaiyaSettings(),
    this.filter = const FilterInfo(),
    this.setup = const SetupInfo(),
    this.blur = const BlurInfo(),
    this.detectorModel = false,
    this.capabilities = const Capabilities(),
    this.navigate,
    this.features = const {},
  });

  /// Tolerant: a missing or unknown key takes its default (keys are added, never renamed).
  factory AppState.fromMap(Map<Object?, Object?> m) => AppState(
        platform: _str(m['platform']) ?? 'android',
        version: _str(m['version']) ?? '',
        language: appLanguages.containsKey(_str(m['language'])) ? _str(m['language'])! : 'ar',
        settings: WaaiyaSettings.fromMap(_map(m['settings'])),
        filter: FilterInfo.fromMap(_map(m['filter'])),
        setup: SetupInfo.fromMap(_map(m['setup'])),
        blur: BlurInfo.fromMap(_map(m['blur'])),
        detectorModel: _bool(_map(m['models'])['detector'], false),
        capabilities: Capabilities.fromMap(_map(m['capabilities'])),
        navigate: PageRequest.fromMap(m['navigate']),
        features: {for (final e in _map(m['features']).entries) if (e.key is String) e.key as String: _map(e.value)},
      );

  final String platform;
  final String version;

  /// One of [appLanguages]' tags ("ar" by default).
  final String language;
  final WaaiyaSettings settings;
  final FilterInfo filter;
  final SetupInfo setup;
  final BlurInfo blur;

  /// The women's-singing detector is bundled.
  final bool detectorModel;
  final Capabilities capabilities;

  /// A page the platform asks to show once (a Quick Settings tile's "Open Waaiya"); null most of the time.
  final PageRequest? navigate;

  /// One map per 0.2.13 feature, read by that feature's own file (docs/FEATURES_CONTRACT.md): `fix`
  /// (fix_mistakes.dart), `worship` (worship.dart), `protect` (protection.dart), `singing` (singing_option.dart).
  /// A missing section is an empty map.
  final Map<String, Map<Object?, Object?>> features;

  Map<Object?, Object?> feature(String name) => features[name] ?? const {};

  AppState copyWith({
    String? language,
    WaaiyaSettings? settings,
    FilterInfo? filter,
    SetupInfo? setup,
    BlurInfo? blur,
    Map<String, Map<Object?, Object?>>? features,
  }) =>
      AppState(
        platform: platform,
        version: version,
        language: language ?? this.language,
        settings: settings ?? this.settings,
        filter: filter ?? this.filter,
        setup: setup ?? this.setup,
        blur: blur ?? this.blur,
        detectorModel: detectorModel,
        capabilities: capabilities,
        features: features ?? this.features,
      );

  Map<String, Object?> toMap() => {
        'platform': platform,
        'version': version,
        'language': language,
        'settings': settings.toMap(),
        'filter': filter.toMap(),
        'setup': setup.toMap(),
        'blur': blur.toMap(),
        'models': {'detector': detectorModel},
        'capabilities': capabilities.toMap(),
        'features': features,
      };
}

/// startFilter outcome; `failed`: see `filter.error`.
enum StartResult { started, micDenied, consentDenied, alreadyRunning, failed }

StartResult startResultFromCode(Object? code) => switch (code) {
      'started' => StartResult.started,
      'mic_denied' => StartResult.micDenied,
      'consent_denied' => StartResult.consentDenied,
      'already_running' => StartResult.alreadyRunning,
      'failed' => StartResult.failed,
      _ => StartResult.consentDenied,
    };

/// One licence document: [label] is shown, [file] is passed to [WaaiyaBackend.getLicenceText].
class LicenceDoc {
  const LicenceDoc(this.label, this.file);
  final String label;
  final String file;
}

class Licences {
  const Licences({required this.notice, required this.docs});
  final String notice;
  final List<LicenceDoc> docs;
}

/// Thrown by backends (PlatformException codes on Android): `unsupported`, `bad_args`, `busy`, `failed`.
class BackendException implements Exception {
  const BackendException(this.code, [this.message = '']);
  final String code;
  final String message;
  @override
  String toString() => message.isEmpty ? code : '$code: $message';
}

/// What the screens need from the platform. Android: [ChannelBackend]; desktop: a Dart implementation.
abstract interface class WaaiyaBackend {
  /// The current snapshot first, then one after every change.
  Stream<AppState> get states;

  Future<AppState> getState();

  /// One of [SettingKeys]; stored natively.
  Future<void> setSetting(String key, Object value);

  /// Asks what the platform needs (permissions, consent), then starts. State follows through [states].
  Future<StartResult> startFilter();

  Future<void> stopFilter();

  /// The setup checklist's button: 0 = get Shizuku, 1 = update it (TOO_OLD) or open it, 2 = grant through it.
  /// Step 1 when Shizuku is installed but not running shows the guide in Flutter instead (showShizukuGuide).
  Future<void> runSetupStep(int step);

  /// Screen blur: "Allow with Shizuku".
  Future<void> blurSetup();

  /// Screen blur: "Allow in Android settings".
  Future<void> openOverlaySettings();

  /// Opens the Shizuku app (its store page when it is not installed). Capability `shizukuSetup`.
  Future<void> openShizuku();

  /// Android's Developer options (About phone when they are not turned on yet). Capability `shizukuSetup`.
  Future<void> openDeveloperOptions();

  /// "ar" or "en"; saved natively so native screens, services and notifications follow it.
  Future<void> setLanguage(String tag);

  /// Start the filter at login, or not (capability `autostart`). State in `filter.autostart`.
  Future<void> setAutostart(bool on);

  /// The native link screen (watch or save a link without music).
  Future<void> openLinkScreen();

  Future<Licences> getLicences();

  Future<String> getLicenceText(String file);

  /// A plain-text report of what the app sees on this device (Android: Diagnostics.report; desktop: the daemon,
  /// filter and blur state), for the user to copy and give to whoever helps. Nothing is sent anywhere.
  Future<String> diagnosticsReport();

  /// The on-phone setup (Android 11+): `started`, `dev_off` (Developer options are off: offer About phone), or
  /// `asking` (Android's notification question is open; the setup goes on by itself after it).
  Future<String> wirelessStart();

  /// A 6-digit pairing code typed in the app; false when it is not 6 digits.
  Future<bool> wirelessEnterCode(String code);

  Future<void> wirelessCancel();

  /// About phone (to turn on Developer options), or Developer options when they are on.
  Future<void> openAboutPhone();

  /// Android's Wi-Fi settings (Wireless debugging needs Wi-Fi).
  Future<void> openWifiSettings();

  /// The setup step by step with pictures (Android).
  Future<void> openSetupGuide();

  /// One picture of the illustrated setup guide ([guidePictureNames]), in the app's language: the encoded image
  /// (WebP), or null where there are no pictures (desktop).
  Future<Uint8List?> guidePicture(String name);

  /// The page asked for in [AppState.navigate] was shown.
  Future<void> pageShown();

  /// Android's share sheet with [text] (the diagnostics report).
  Future<void> shareText(String text);

  /// A 0.2.13 feature method, named `<feature>.<name>` (docs/FEATURES_CONTRACT.md), e.g. `worship.times`. Android:
  /// the same MethodChannel method name, routed by UiBridge to the feature's Kotlin object. Throws
  /// [BackendException] `unsupported` where the platform lacks it, `protected` when the waiting period or the PIN
  /// holds the change back.
  Future<Object?> invoke(String method, [Map<String, Object?> args = const {}]);
}

// --- tolerant readers ---

Map<Object?, Object?> _map(Object? v) => v is Map ? v : const {};
String? _str(Object? v) => v is String ? v : null;
bool _bool(Object? v, bool def) => v is bool ? v : def;
int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);
int _intOr(Object? v, int def) => v is num ? v.toInt() : def;
List<String> _csv(Object? v) => v is String
    ? (v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList()..sort())
    : v is List
        ? (v.whereType<String>().toSet().toList()..sort())
        : const [];

/// "MODEL_FAILED" <-> FilterState.modelFailed.
String _enumName(Enum e) => e.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

T? _enum<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (_enumName(v) == name) return v;
  }
  return null;
}
