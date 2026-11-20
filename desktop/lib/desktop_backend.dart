import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;

import 'package:waaiya_ui/waaiya_ui.dart';
// ignore: implementation_imports
import 'package:waaiya_ui/src/fix_mistakes_notes.dart';
// ignore: implementation_imports
import 'package:waaiya_ui/src/protection_core.dart';

import 'linux_blur.dart';
import 'linux_engine.dart';
import 'version.dart';
import 'windows_engine.dart';

/// Desktop backend (docs/UI_CONTRACT.md, "Where the desktop backend differs").
///
/// Settings and the language are kept in a JSON file with the same keys as Android's SharedPreferences file.
///
/// Linux, with the engine in the bundle ([LinuxEngine]): Start checks the system, installs or updates the engine,
/// then starts the systemd user service; Stop stops it (normal audio comes back); the state is polled from
/// `waaiya status` and systemd. Windows ([WindowsEngine]): Start runs `waaiya-filter.exe` from the bundle, detached;
/// Stop gives every app its level back; the state is polled from `waaiya-filter status`. Without the engine (a
/// development run) start/stop only change the reported state, and the screen says it is a preview
/// (`filter.simulated`).
///
/// Screen blur ([LinuxBlur]: `im-blur` on Linux, `waaiya-blur.exe` on Windows, when the bundle has it): runs while the
/// app is open and a blur option is on, whether the sound filter runs or not (capability `blurStandalone`); its
/// state is `blur.state` / `blur.error`.
///
/// Protection (waiting period and PIN, `features.protect`): the same rules as Android ([ProtectionGate]); setSetting and
/// stopFilter pass the guard first. The PIN hash and the pending request are in protect.json in the state folder. The
/// `waaiya` command line is not guarded: it stays the way out, and the card says so.
class DesktopBackend extends MemoryBackend {
  DesktopBackend._(this.settingsFile, this.licencesDir, this.engine, this.blur, this.startTimeout, AppState initial,
      Duration? poll)
      : super(initial: initial) {
    if (engine != null && poll != null) _timer = Timer.periodic(poll, (_) => refresh());
    _blurSub = blur?.reports.listen(_onBlur);
  }

  /// Where the settings are stored.
  final File settingsFile;

  /// Licence texts shipped next to the app (desktop/tool/bundle_engine.sh copies them there).
  final Directory licencesDir;

  /// The sound filter host (Linux or Windows); null: simulated.
  final FilterHost? engine;

  /// The screen blur; null: no blur here (capability `screenBlur` false).
  final LinuxBlur? blur;
  StreamSubscription<BlurReport?>? _blurSub;

  Timer? _timer;

  /// The last start/stop problem (`filter.error`); kept until the next start, cleared once the filter runs.
  BackendMessage? _error;

  /// When the service was first seen starting without the virtual output yet.
  DateTime? _startingSince;
  bool _busy = false;

  /// The filter ran since the last start or stop from this app: a later "not running" is the filter stopping by
  /// itself ("Waaiya stopped"), not the user's stop.
  bool _ranSinceAction = false;

  /// The last `waaiya status` (diagnostics report).
  EngineStatus? _lastStatus;

  /// A service still starting after this long is reported as failing (it keeps restarting).
  final Duration startTimeout;
  static const defaultStartTimeout = Duration(seconds: 20);

  static const _langKey = 'lang';

  /// [engine]: filter host; by default the one next to the app on Linux and Windows. [blur]: screen blur; by
  /// default the helper next to the app on Linux and Windows. [platform]: `linux`, `windows`, ... (tests; default: this
  /// system). [poll]: state refresh period (null: only after actions and [refresh] calls).
  static Future<DesktopBackend> open({
    File? file,
    Directory? licencesDir,
    FilterHost? engine,
    bool findEngine = true,
    LinuxBlur? blur,
    bool findBlur = true,
    String? platform,
    Duration? poll = const Duration(seconds: 3),
    Duration startTimeout = defaultStartTimeout,
    String? systemLocale,
    ProtectionClock? protectionClock,
    int protectionIterations = ProtectionRules.iterations,
  }) async {
    // "Fix mistakes" notes: next to a given settings file (tests), else in the state folder
    final notes = FixNotes(file != null ? File('${file.parent.path}${Platform.pathSeparator}fix_notes.txt') : defaultNotesFile());
    // the waiting period and the PIN: next to a given settings file (tests), else in the state folder
    final protectFile = File(file != null
        ? '${file.parent.path}${Platform.pathSeparator}protect.json'
        : '${defaultNotesFile().parent.path}${Platform.pathSeparator}protect.json');
    file ??= defaultSettingsFile();
    systemLocale ??= Platform.localeName;
    platform ??= Platform.operatingSystem;
    licencesDir ??= Directory('${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}licences');
    final linux = platform == 'linux', windows = platform == 'windows';
    if (engine == null && findEngine && linux) engine = LinuxEngine.find();
    if (engine == null && findEngine && windows) engine = WindowsEngine.find();
    if (!linux && !windows) blur = null; // macOS: not yet
    if (blur == null && findBlur && linux) {
      blur = LinuxBlur.find(tokenFile: File('${file.parent.path}/screencast-restore-token'));
    }
    if (blur == null && findBlur && windows) blur = LinuxBlur.findWindows();
    var saved = <String, Object?>{};
    try {
      saved = (jsonDecode(await file.readAsString()) as Map).cast<String, Object?>();
    } on Object {
      // first run, or an unreadable file: defaults
    }
    final settings = <String, Object>{...SettingKeys.defaults};
    for (final key in SettingKeys.defaults.keys) {
      final v = saved[key];
      if (v != null && SettingKeys.validate(key, v) == null) settings[key] = v;
    }
    final detector = engine?.hasDetector ?? false;
    final initial = AppState(
      platform: platform,
      // the bundle's engine/VERSION is "<app version>-<hash of the engine files>"
      version: (engine?.bundledVersion ?? '').split('-').first.isNotEmpty
          ? engine!.bundledVersion.split('-').first
          : appVersion,
      // The saved choice; on a first run the computer's language when Waaiya has it, else Arabic. Someone who used
      // Waaiya before this rule has a settings file without a language and keeps Arabic.
      language: appLanguageOf(saved[_langKey] as String?) ??
          (saved.isEmpty ? appLanguageOf(systemLocale) ?? 'ar' : 'ar'),
      settings: WaaiyaSettings.fromMap(settings),
      filter: FilterInfo(simulated: engine == null),
      detectorModel: detector,
      // Women's singing only with a bundled detector: without one the engine mutes all voice while it is on.
      capabilities: Capabilities(
        womenSinging: engine == null || detector,
        autostart: engine != null,
        screenBlur: blur != null,
        blurStandalone: blur != null,
      ),
      // the covers let every click through (empty input region), so the full-screen fail cover is safe here
      blur: blur != null ? const BlurInfo(overlayAllowed: true, touchPassThrough: true) : const BlurInfo(),
      features: {
        'singing': _singingFeature(engine, settings[SettingKeys.keepSinging] == true, false),
        'fix': _fixSection(engine, notes.count),
      },
    );
    final b = DesktopBackend._(file, licencesDir, engine, blur, startTimeout, initial, poll);
    b._initFix(notes);
    b._initProtect(protectFile, protectionClock ?? (linux ? LinuxBootClock() : ProcessClock()), protectionIterations);
    await b.refresh(); // a filter already running (started at login) shows at once
    await b._applyBlur();
    return b;
  }

  /// %APPDATA%\Waaiya\settings.json, ~/Library/Application Support/Waaiya/settings.json,
  /// $XDG_CONFIG_HOME/waaiya/settings.json (default ~/.config).
  static File defaultSettingsFile() {
    final env = Platform.environment;
    final sep = Platform.pathSeparator;
    final String dir;
    if (Platform.isWindows) {
      dir = '${env['APPDATA'] ?? env['USERPROFILE'] ?? '.'}${sep}Waaiya';
    } else if (Platform.isMacOS) {
      dir = '${env['HOME'] ?? '.'}/Library/Application Support/Waaiya';
    } else {
      final xdg = env['XDG_CONFIG_HOME'];
      dir = '${xdg != null && xdg.isNotEmpty ? xdg : '${env['HOME'] ?? '.'}/.config'}/waaiya';
    }
    return File('$dir${sep}settings.json');
  }

  /// $XDG_STATE_HOME/waaiya/fix_notes.txt (default ~/.local/state); Windows and macOS: next to the settings.
  static File defaultNotesFile() {
    final env = Platform.environment;
    if (Platform.isLinux) {
      final xdg = env['XDG_STATE_HOME'];
      return File('${xdg != null && xdg.isNotEmpty ? xdg : '${env['HOME'] ?? '.'}/.local/state'}/waaiya/fix_notes.txt');
    }
    return File('${defaultSettingsFile().parent.path}${Platform.pathSeparator}fix_notes.txt');
  }

  // --- Fix mistakes on the spot (lane A): apps heard unfiltered (Linux engine), wrong-detection notes ---

  /// `features.fix` on desktop: no blur-off apps and no hand covers here (not offered: hidden).
  static Map<Object?, Object?> _fixSection(FilterHost? engine, int notes) =>
      {'filterApps': engine is LinuxEngine, 'notes': notes};

  late final FixNotes _notes;

  void _initFix(FixNotes notes) {
    _notes = notes;
    final e = engine;
    // the daemon reads the app's list (also one chosen before the engine was installed)
    if (e is LinuxEngine) e.writeFilterOffApps(state.settings.filterOffApps);
    methods['fix.apps'] = (_) async {
      // the apps playing sound now, and the ones already chosen (names are what the daemon matches)
      final playing = e is LinuxEngine ? await e.playingApps() : const <String>[];
      return [
        for (final n in {...playing, ...state.settings.filterOffApps}) {'package': n, 'label': n},
      ];
    };
    methods['fix.note'] = (args) async {
      final kind = args['kind'];
      if (kind is! String || !FixNotes.kinds.contains(kind)) throw const BackendException('bad_args', 'kind');
      final s = state;
      final n = _notes.add(
        time: DateTime.now(),
        kind: kind,
        where: args['where'] is String ? args['where'] as String : 'app',
        filter: '${s.filter.state.name}${s.settings.muteWomenSinging ? ", women's singing muted" : ''}'
            '${s.settings.filterOffApps.isNotEmpty ? ', unfiltered apps: ${s.settings.filterOffApps.join(', ')}' : ''}',
        blur: '${s.blur.state?.name ?? 'off'}${s.settings.blurWomen ? ', women' : ''}'
            '${s.settings.blurNudity ? ', nudity' : ''}, strictness ${s.settings.blurStrictness}',
        models: 'Waaiya ${s.version} (${s.platform}); engine ${engine?.bundledVersion ?? 'none'}'
            '${(engine?.hasDetector ?? false) ? ', detector' : ''}',
      );
      _emitFix(n);
      return n;
    };
    methods['fix.notes'] = (_) async => _notes.text('Waaiya ${state.version}: wrong-detection notes (kept on this computer only)');
    methods['fix.clearNotes'] = (_) async {
      _notes.clear();
      _emitFix(0);
      return null;
    };
  }

  // --- Protection: the waiting period and the PIN (lane B) ---

  late final ProtectionGate _protect;
  Timer? _protectTimer;

  void _initProtect(File file, ProtectionClock clock, int iterations) {
    var store = <String, Object?>{};
    try {
      store = (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();
    } on Object {
      // first run, or an unreadable file: no PIN, nothing pending
    }
    void save() {
      try {
        file.parent.createSync(recursive: true);
        final tmp = File('${file.path}.tmp')..writeAsStringSync(jsonEncode(store));
        tmp.renameSync(file.path);
      } on IOException {
        // the guard keeps working for this run
      }
    }

    _protect = ProtectionGate(
      ProtectionCore(
        store: store,
        clock: clock,
        delayMinutes: () => state.settings.protectDelayMinutes,
        current: (key) => state.settings.toMap()[key],
        save: save,
        iterations: iterations,
      ),
      apply: (what, value) => what == ProtectionCore.stop ? _stop() : _applySetting(what, value!),
      changed: _emitProtect,
    );
    methods.addAll(_protect.methods);
    _emitProtect();
  }

  /// `features.protect`; while a change waits, the time left is saved every minute and the card follows it.
  void _emitProtect() {
    final section = _protect.section();
    emit(state.copyWith(features: {...state.features, 'protect': section}));
    if (section['pending'] != null) {
      _protectTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
        _protect.core.checkpoint();
        _emitProtect();
      });
    } else {
      _protectTimer?.cancel();
      _protectTimer = null;
    }
  }

  void _emitFix(int notes) =>
      emit(state.copyWith(features: {...state.features, 'fix': _fixSection(engine, notes)}));

  @override
  Future<void> saved() async {
    final data = {...state.settings.toMap(), _langKey: state.language};
    await settingsFile.parent.create(recursive: true);
    final tmp = File('${settingsFile.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await tmp.rename(settingsFile.path); // atomic: never half a file
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _protectTimer?.cancel();
    await _blurSub?.cancel();
    await blur?.dispose();
    return super.close();
  }

  // --- Linux screen blur ---

  static const _blurKeys = {
    SettingKeys.blurWomen,
    SettingKeys.blurNudity,
    SettingKeys.blurStrictness,
    SettingKeys.blurFailCover,
  };

  Future<void> _applyBlur() async => blur?.apply(BlurConfig.of(state.settings));

  void _onBlur(BlurReport? r) {
    final exited = r == null ? blur?.exitDetail : null;
    emit(state.copyWith(
      blur: BlurInfo(
        state: r?.blurState,
        overlayAllowed: true,
        touchPassThrough: true,
        error: exited != null ? BackendMessage('exited', exited) : r?.blurError,
        uncovered: r?.uncovered ?? 0,
      ),
    ));
  }

  // --- Keep singing (setting keep_singing; Linux engine only) ---

  /// `features.singing`: `available` = the bundled Linux engine has the voice_v1 model; `active` = the filter runs
  /// with it (it loaded: a model that did not load is silent, FilterState.modelFailed).
  static Map<String, Object?> _singingFeature(FilterHost? e, bool keepSinging, bool filtering) {
    final available = e is LinuxEngine && e.hasSingingModel;
    return {'available': available, 'active': available && keepSinging && filtering};
  }

  void _emitSinging() => emit(state.copyWith(features: {
        ...state.features,
        'singing': _singingFeature(engine, state.settings.keepSinging, state.filter.state == FilterState.filtering),
      }));

  /// `waaiya keep-singing on|off`; Linux only (no other host has the model). "on" only with the model bundled; "off"
  /// whenever the engine still has it on (also left on by an earlier bundle without the model: it would stay silent).
  static Future<BackendMessage?> _setKeepSinging(FilterHost e, bool on) async {
    if (e is! LinuxEngine) return null;
    if (on ? e.hasSingingModel : e.keepSingingSet == true) return e.setKeepSinging(on);
    return null;
  }

  // --- Linux engine host ---

  void _emitFilter(FilterState s, {bool? autostart, String? problem}) => emit(state.copyWith(
        filter: FilterInfo(state: s, error: _error, autostart: autostart ?? state.filter.autostart, problem: problem),
      ));

  /// Reads the engine's state (polled; also after every action).
  Future<void> refresh() async {
    final e = engine;
    if (e == null || _busy) return;
    final st = await e.status();
    if (_busy) return; // an action started meanwhile; it refreshes when done
    _lastStatus = st;
    FilterState s;
    String? problem;
    final starting = const {'active', 'activating', 'reloading'}.contains(st.active);
    if (st.sinkUp) {
      // running: but is the sound actually filtered? (the engine says what it loaded)
      s = st.modelFailed ? FilterState.modelFailed : FilterState.filtering;
      if (st.detectorFailed && state.settings.muteWomenSinging) problem = FilterProblem.detectorFailed;
      // up at this poll, but it keeps crashing and restarting (apps are silent during each restart)
      _error = st.crashLoop
          ? BackendMessage('service_failed', 'the filter restarted ${st.restarts} times in the last minute\n${await e.journal()}')
          : null;
      _startingSince = null;
      _ranSinceAction = true;
    } else if (starting) {
      // the service is up but its filter is not (yet): starting, or being replaced ('restarting', a reload)
      s = st.filter == 'restarting' ? FilterState.filtering : FilterState.starting;
      _startingSince ??= DateTime.now();
      if (_error == null && DateTime.now().difference(_startingSince!) > startTimeout) {
        _error = BackendMessage('service_failed', await e.journal());
      }
    } else {
      _startingSince = null;
      // the daemon is gone but its virtual output stayed (hold_silence): apps are held silent until Start or Stop;
      // it ran and stopped otherwise without the user's stop: "Waaiya stopped"
      s = st.down
          ? FilterState.silenced
          : (_ranSinceAction ? FilterState.stoppedBySystem : FilterState.stopped);
      if (st.active == 'failed' && _error == null) _error = BackendMessage('service_failed', await e.journal());
    }
    _emitFilter(s, autostart: st.autostart, problem: problem);
    _emitSinging();
    await _adoptEngineSettings(e);
  }

  /// `waaiya stereo on|off` / `keep-silent on|off` typed on the command line: the app shows them and keeps them
  /// (Start writes the app's values, so the app adopts the engine's first instead of overriding them).
  Future<void> _adoptEngineSettings(FilterHost e) async {
    final stereo = e.stereoSet, keep = e.keepSilentSet;
    final st = state.settings;
    if ((stereo == null || stereo == st.audioStereo) && (keep == null || keep == st.holdSilence)) return;
    emit(state.copyWith(
      settings: WaaiyaSettings.fromMap({
        ...st.toMap(),
        SettingKeys.audioStereo: ?stereo,
        SettingKeys.holdSilence: ?keep,
      }),
    ));
    await saved();
  }

  /// The daemon's notice, in the app's language.
  void _writeNotice() {
    final l = lookupAppLocalizations(Locale(state.language));
    engine?.writeNotice(l.notifStoppedTitle, l.notifStoppedText);
  }

  @override
  Future<void> setLanguage(String tag) async {
    await super.setLanguage(tag);
    _writeNotice();
  }

  /// Runs [action] with polling paused; a returned problem becomes `filter.error`.
  Future<bool> _act(Future<BackendMessage?> Function(FilterHost e) action) async {
    _busy = true;
    try {
      final err = await action(engine!);
      if (err != null) _error = err;
      return err == null;
    } finally {
      _busy = false;
    }
  }

  @override
  Future<StartResult> startFilter() async {
    final e = engine;
    if (e == null) return super.startFilter();
    if (state.filter.running) return StartResult.alreadyRunning;
    _error = null;
    _startingSince = null;
    _ranSinceAction = false;
    _emitFilter(FilterState.starting);
    _writeNotice();
    final ok = await _act((e) async =>
        await e.preflight() ??
        await e.installIfNeeded() ??
        // fail-safe: never leave women's singing on without a detector (all voice would be muted)
        await e.setWomenSinging(e.hasDetector && state.settings.muteWomenSinging) ??
        await e.setStereo(state.settings.audioStereo) ??
        await _setKeepSinging(e, state.settings.keepSinging) ??
        await e.setKeepSilent(state.settings.holdSilence) ??
        await e.start());
    if (!ok) {
      _emitFilter(FilterState.stopped);
      return StartResult.failed;
    }
    await refresh();
    return StartResult.started;
  }

  @override
  Future<void> stopFilter() async {
    _protect.checkStop(); // throws 'protected' when the waiting period or the PIN holds it back
    await _stop();
  }

  Future<void> _stop() async {
    if (engine == null) return super.stopFilter();
    _error = null;
    _ranSinceAction = false;
    await _act((e) => e.stop());
    await refresh();
  }

  @override
  Future<void> setSetting(String key, Object value) async {
    _protect.checkSetting(key, value); // throws 'protected' when the waiting period or the PIN holds it back
    await _applySetting(key, value);
  }

  /// A setting change the guard allowed.
  Future<void> _applySetting(String key, Object value) async {
    await super.setSetting(key, value);
    if (key == SettingKeys.protectDelayMinutes) _emitProtect();
    if (_blurKeys.contains(key)) await _applyBlur();
    final e = engine;
    // apps heard unfiltered: the daemon reads the file every second, nothing to restart
    if (key == SettingKeys.filterOffApps && e is LinuxEngine) e.writeFilterOffApps(state.settings.filterOffApps);
    if (e == null) return;
    if (key == SettingKeys.holdSilence) {
      // read by the daemon when the filter stops by itself: nothing to restart
      final ok = await _act((e) => e.setKeepSilent(value == true));
      if (!ok) _emitFilter(state.filter.state);
      return;
    }
    if (key == SettingKeys.keepSinging) {
      // the other model: a running filter reloads (a moment of silence, never unfiltered sound)
      final running = state.filter.running;
      final ok = await _act((e) async => await _setKeepSinging(e, value == true) ?? (running ? await e.reload() : null));
      if (!ok) _emitFilter(state.filter.state);
      await refresh();
      _emitSinging();
      return;
    }
    if (key == SettingKeys.audioStereo) {
      final running = state.filter.running;
      final ok = await _act((e) async => await e.setStereo(value == true) ?? (running ? await e.reload() : null));
      if (!ok) _emitFilter(state.filter.state);
      await refresh();
      return;
    }
    if (key != SettingKeys.muteWomenSinging || !e.hasDetector) return;
    // `waaiya women-singing on|off`, then a running filter reloads: only the filter process restarts, the apps
    // stay on the virtual output (never stop + start, which gave 2-4 s of unfiltered sound).
    final running = state.filter.running;
    final ok = await _act((e) async => await e.setWomenSinging(value == true) ?? (running ? await e.reload() : null));
    if (!ok) _emitFilter(state.filter.state);
    await refresh();
  }

  @override
  Future<void> setAutostart(bool on) async {
    if (engine == null) return super.setAutostart(on);
    final ok = await _act((e) async {
      if (on) {
        final err = await e.preflight();
        if (err != null) return err;
        // the unit file must exist; never replace the binaries of a running filter
        if (!state.filter.running || e.installedVersion == null) {
          final inst = await e.installIfNeeded();
          if (inst != null) return inst;
        }
      }
      return e.setAutostart(on);
    });
    if (!ok) _emitFilter(state.filter.state);
    await refresh();
  }

  // --- diagnostics ---

  @override
  Future<String> diagnosticsReport() async {
    final s = state;
    final b = StringBuffer()
      ..writeln('Waaiya ${s.version} (${s.platform}, ${Platform.operatingSystemVersion})')
      ..writeln('Session: ${['XDG_SESSION_TYPE', 'XDG_CURRENT_DESKTOP', 'WAYLAND_DISPLAY', 'DISPLAY'].map((k) => '$k=${Platform.environment[k] ?? ''}').join(' ')}')
      ..writeln('Settings: ${s.settings.toMap()}')
      ..writeln('Filter: ${s.filter.state.name}${s.filter.problem != null ? ', ${s.filter.problem}' : ''}'
          '${s.filter.error != null ? ', error ${s.filter.error!.code}' : ''}')
      ..writeln('Blur: ${s.blur.state?.name ?? 'off'}${s.blur.error != null ? ', ${s.blur.error!.code}: ${s.blur.error!.detail}' : ''}'
          '${s.blur.uncovered > 0 ? ', ${s.blur.uncovered} monitor(s) not covered' : ''}');
    final bl = blur;
    if (bl != null) {
      final r = bl.last;
      if (r != null) {
        b.writeln('Blur helper: backend ${r.backend}, covers ${r.covers}'
            '${r.ms != null ? ', ${r.ms!.toStringAsFixed(0)} ms per frame, ${r.cpu?.toStringAsFixed(0)}% CPU' : ''}');
      }
      if (bl.exitDetail != null) b.writeln('Blur helper exited: ${bl.exitDetail}');
      if (bl.missingModels.isNotEmpty) b.writeln('Blur models missing: ${bl.missingModels.join(', ')}');
    }
    final e = engine;
    if (e == null) {
      b.writeln('Engine: not in this build (preview)');
    } else {
      final st = _lastStatus ?? await e.status();
      b
        ..writeln('Engine: bundled ${e.bundledVersion}, installed ${e.installedVersion ?? 'no'}, service ${st.active}')
        ..writeln()
        ..writeln('waaiya status:')
        ..writeln(st.raw)
        ..writeln()
        ..writeln('Service log:')
        ..writeln(await e.journal(lines: 20))
        ..writeln()
        ..writeln('Filter log (end):')
        ..writeln(e.filterLogTail());
    }
    return b.toString().trim();
  }

  // --- licences ---

  static const _baseDocs = [
    LicenceDoc('GNU Affero General Public License v3 or later (Waaiya)', 'LICENSE-AGPL-3.0.txt'),
    LicenceDoc('Third-party components, models and training data', 'THIRD_PARTY_LICENSES.txt'),
  ];
  static const _blurDocs = [
    LicenceDoc('YOLOX person detector (Apache-2.0)', 'YOLOX-LICENSE.txt'),
    LicenceDoc('Marqo nudity classifier (Apache-2.0)', 'Marqo-nsfw-image-detection-384-NOTICE.txt'),
    LicenceDoc('Apache License 2.0 (YOLOX and Marqo models)', 'Apache-2.0-LICENSE.txt'),
  ];
  static const _engineDocs = [
    LicenceDoc('ONNX Runtime (MIT)', 'onnxruntime-LICENSE.txt'),
    LicenceDoc('ONNX Runtime third-party notices', 'onnxruntime-ThirdPartyNotices.txt'),
    LicenceDoc('DeepFilterNet (MIT; also available under Apache-2.0)', 'DeepFilterNet-LICENSE-MIT.txt'),
    LicenceDoc('EfficientAT detector backbone (MIT)', 'EfficientAT-LICENSE.txt'),
  ];

  /// The base texts, plus the engine's when they are in the bundle.
  List<LicenceDoc> get _docs => [
        ..._baseDocs,
        ...[..._engineDocs, ..._blurDocs]
            .where((d) => File('${licencesDir.path}${Platform.pathSeparator}${d.file}').existsSync()),
      ];

  @override
  Future<Licences> getLicences() async {
    final notice = await _read('NOTICE.txt');
    return Licences(notice: notice, docs: _docs);
  }

  @override
  Future<String> getLicenceText(String file) async {
    if (!_docs.any((d) => d.file == file)) throw BackendException('bad_args', 'licence file $file');
    return _read(file);
  }

  Future<String> _read(String name) async {
    try {
      return await File('${licencesDir.path}${Platform.pathSeparator}$name').readAsString();
    } on IOException {
      return 'Waaiya is free software under the GNU Affero General Public License v3 or later. Licence texts: '
          'https://github.com/oksyassine/waaiya (NOTICE, LICENSE, THIRD_PARTY_LICENSES.md).';
    }
  }
}

/// Linux: the boot id and the time since boot (CLOCK_BOOTTIME, suspend included) from /proc, so a waiting period keeps
/// counting while Waaiya is closed but never counts a time the computer was off. Without /proc: this run only.
class LinuxBootClock implements ProtectionClock {
  final _fallback = ProcessClock();
  String? _boot;

  @override
  int wallMs() => DateTime.now().millisecondsSinceEpoch;

  @override
  int elapsedMs() {
    try {
      final up = double.parse(File('/proc/uptime').readAsStringSync().split(' ').first);
      return (up * 1000).round();
    } on Object {
      return _fallback.elapsedMs();
    }
  }

  @override
  String bootId() {
    try {
      return _boot ??= File('/proc/sys/kernel/random/boot_id').readAsStringSync().trim();
    } on Object {
      return _fallback.bootId();
    }
  }
}
