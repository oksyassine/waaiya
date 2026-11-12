import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;

import 'package:waaiya_ui/waaiya_ui.dart';

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
  }) async {
    file ??= defaultSettingsFile();
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
      language: saved[_langKey] == 'en' ? 'en' : 'ar', // Arabic first, whatever the system language
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
    );
    final b = DesktopBackend._(file, licencesDir, engine, blur, startTimeout, initial, poll);
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
      _error = null;
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
    if (engine == null) return super.stopFilter();
    _error = null;
    _ranSinceAction = false;
    await _act((e) => e.stop());
    await refresh();
  }

  @override
  Future<void> setSetting(String key, Object value) async {
    await super.setSetting(key, value);
    if (_blurKeys.contains(key)) await _applyBlur();
    final e = engine;
    if (e == null) return;
    if (key == SettingKeys.holdSilence) {
      // read by the daemon when the filter stops by itself: nothing to restart
      final ok = await _act((e) => e.setKeepSilent(value == true));
      if (!ok) _emitFilter(state.filter.state);
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
