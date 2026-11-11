/// The contract between the shared screens and a native backend (docs/UI_CONTRACT.md).
library;

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

  /// Key -> default value. The value's type is the key's type.
  static const Map<String, Object> defaults = {
    gender: '',
    muteWomenSinging: false,
    silenceUnfilterable: true,
    blurWomen: false,
    blurNudity: false,
    blurFailCover: true,
    blurStrictness: 0,
  };

  /// Returns an error text when [key]/[value] is not a valid setting, else null.
  static String? validate(String key, Object? value) {
    final def = defaults[key];
    if (def == null) return 'unknown setting "$key"';
    if (def is bool && value is! bool) return '"$key" takes a bool';
    if (def is int && (value is! int || value < 0 || value > 2)) return '"$key" takes 0, 1 or 2';
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
  });

  factory WaaiyaSettings.fromMap(Map<Object?, Object?> m) => WaaiyaSettings(
        gender: _str(m[SettingKeys.gender]) ?? '',
        muteWomenSinging: _bool(m[SettingKeys.muteWomenSinging], false),
        silenceUnfilterable: _bool(m[SettingKeys.silenceUnfilterable], true),
        blurWomen: _bool(m[SettingKeys.blurWomen], false),
        blurNudity: _bool(m[SettingKeys.blurNudity], false),
        blurFailCover: _bool(m[SettingKeys.blurFailCover], true),
        blurStrictness: _int(m[SettingKeys.blurStrictness]).clamp(0, 2),
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
      };
}

/// FilterService.State.
enum FilterState { stopped, starting, filtering, modelFailed, noCapturePermission, stoppedBySystem }

/// ShizukuSetup.State.
enum ShizukuState { notInstalled, notRunning, tooOld, needsPermission, deniedPermanently, ready }

/// ScreenBlur.State.
enum BlurState { starting, on, onCoversVisible, noOverlay, modelsMissing, failing }

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
  });

  factory FilterInfo.fromMap(Map<Object?, Object?> m) => FilterInfo(
        state: _enum(FilterState.values, m['state']) ?? FilterState.stopped,
        delayMs: _int(m['delayMs']),
        micDenied: _bool(m['micDenied'], false),
        simulated: _bool(m['simulated'], false),
        error: BackendMessage.fromMap(m['error']),
        autostart: _bool(m['autostart'], false),
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

  bool get running =>
      state == FilterState.starting || state == FilterState.filtering || state == FilterState.modelFailed;

  Map<String, Object?> toMap() => {
        'state': _enumName(state),
        'delayMs': delayMs,
        'micDenied': micDenied,
        'simulated': simulated,
        'error': error?.toMap(),
        'autostart': autostart,
      };
}

class SetupInfo {
  const SetupInfo({
    this.originalsMuted = true,
    this.consentSkipped = true,
    this.shizuku,
    this.busy = false,
    this.message,
    this.adbCommands,
  });

  factory SetupInfo.fromMap(Map<Object?, Object?> m) => SetupInfo(
        originalsMuted: _bool(m['originalsMuted'], true),
        consentSkipped: _bool(m['consentSkipped'], true),
        shizuku: _enum(ShizukuState.values, m['shizuku']),
        busy: _bool(m['busy'], false),
        message: BackendMessage.fromMap(m['message']),
        adbCommands: _str(m['adbCommands']),
      );

  /// The original sound can be silenced (Android: DUMP granted).
  final bool originalsMuted;

  /// No screen-capture question at start (Android: app-op PROJECT_MEDIA allowed).
  final bool consentSkipped;
  final ShizukuState? shizuku;
  final bool busy;

  /// `failed` (detail = log), `refused`, `done_restart`, `error` (detail = text).
  final BackendMessage? message;
  final String? adbCommands;

  Map<String, Object?> toMap() => {
        'originalsMuted': originalsMuted,
        'consentSkipped': consentSkipped,
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
    this.layerSupported = false,
    this.busy = false,
    this.message,
  });

  factory BlurInfo.fromMap(Map<Object?, Object?> m) => BlurInfo(
        state: _enum(BlurState.values, m['state']),
        overlayAllowed: _bool(m['overlayAllowed'], false),
        a11yBuild: _bool(m['a11yBuild'], false),
        a11yEnabled: _bool(m['a11yEnabled'], false),
        touchPassThrough: _bool(m['touchPassThrough'], false),
        shizukuLayer: _bool(m['shizukuLayer'], false),
        layerSupported: _bool(m['layerSupported'], false),
        busy: _bool(m['busy'], false),
        message: BackendMessage.fromMap(m['message']),
      );

  /// Null when the blur is not running.
  final BlurState? state;
  final bool overlayAllowed;
  final bool a11yBuild;
  final bool a11yEnabled;
  final bool touchPassThrough;

  /// Shizuku is ready on Android 12+: the covers are a Shizuku shell layer, nothing else to allow.
  final bool shizukuLayer;

  /// The Shizuku cover layer is possible on this device (Android 12+), once Shizuku runs and allows Waaiya.
  final bool layerSupported;
  final bool busy;

  /// `setup_failed` (detail = log).
  final BackendMessage? message;

  Map<String, Object?> toMap() => {
        'state': state == null ? null : _enumName(state!),
        'overlayAllowed': overlayAllowed,
        'a11yBuild': a11yBuild,
        'a11yEnabled': a11yEnabled,
        'touchPassThrough': touchPassThrough,
        'shizukuLayer': shizukuLayer,
        'layerSupported': layerSupported,
        'busy': busy,
        'message': message?.toMap(),
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
  });

  factory Capabilities.fromMap(Map<Object?, Object?> m) => Capabilities(
        shizukuSetup: _bool(m['shizukuSetup'], false),
        adbSetup: _bool(m['adbSetup'], false),
        captureConsent: _bool(m['captureConsent'], false),
        screenBlur: _bool(m['screenBlur'], false),
        links: _bool(m['links'], false),
        womenSinging: _bool(m['womenSinging'], false),
        autostart: _bool(m['autostart'], false),
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

  Map<String, bool> toMap() => {
        'shizukuSetup': shizukuSetup,
        'adbSetup': adbSetup,
        'captureConsent': captureConsent,
        'screenBlur': screenBlur,
        'links': links,
        'womenSinging': womenSinging,
        'autostart': autostart,
      };
}

/// One full snapshot: the getState result and every event.
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
  });

  /// Tolerant: a missing or unknown key takes its default (keys are added, never renamed).
  factory AppState.fromMap(Map<Object?, Object?> m) => AppState(
        platform: _str(m['platform']) ?? 'android',
        version: _str(m['version']) ?? '',
        language: _str(m['language']) == 'en' ? 'en' : 'ar',
        settings: WaaiyaSettings.fromMap(_map(m['settings'])),
        filter: FilterInfo.fromMap(_map(m['filter'])),
        setup: SetupInfo.fromMap(_map(m['setup'])),
        blur: BlurInfo.fromMap(_map(m['blur'])),
        detectorModel: _bool(_map(m['models'])['detector'], false),
        capabilities: Capabilities.fromMap(_map(m['capabilities'])),
      );

  final String platform;
  final String version;

  /// "ar" (default) or "en".
  final String language;
  final WaaiyaSettings settings;
  final FilterInfo filter;
  final SetupInfo setup;
  final BlurInfo blur;

  /// The women's-singing detector is bundled.
  final bool detectorModel;
  final Capabilities capabilities;

  AppState copyWith({
    String? language,
    WaaiyaSettings? settings,
    FilterInfo? filter,
    SetupInfo? setup,
    BlurInfo? blur,
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
}

// --- tolerant readers ---

Map<Object?, Object?> _map(Object? v) => v is Map ? v : const {};
String? _str(Object? v) => v is String ? v : null;
bool _bool(Object? v, bool def) => v is bool ? v : def;
int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

/// "MODEL_FAILED" <-> FilterState.modelFailed.
String _enumName(Enum e) => e.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

T? _enum<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (_enumName(v) == name) return v;
  }
  return null;
}
