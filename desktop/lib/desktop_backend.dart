import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

import 'linux_blur.dart';
import 'linux_engine.dart';

/// Desktop backend (docs/UI_CONTRACT.md, "Where the desktop backend differs").
///
/// Settings and the language are kept in a JSON file with the same keys as Android's SharedPreferences file.
///
/// Linux, with the engine in the bundle ([LinuxEngine]): Start checks the system, installs or updates the engine,
/// then starts the systemd user service; Stop stops it (normal audio comes back); the state is polled from
/// `waaiya status` and systemd. Elsewhere (Windows for now, or a development run without the engine) start/stop
/// only change the reported state, and the screen says it is a preview (`filter.simulated`).
///
/// Linux screen blur ([LinuxBlur], when the bundle has it): runs while the app is open and a blur option is on,
/// whether the sound filter runs or not (capability `blurStandalone`); its state is `blur.state` / `blur.error`.
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

  /// The Linux engine host; null: simulated.
  final LinuxEngine? engine;

  /// The Linux screen blur; null: no blur here (capability `screenBlur` false).
  final LinuxBlur? blur;
  StreamSubscription<BlurReport?>? _blurSub;

  Timer? _timer;

  /// The last start/stop problem (`filter.error`); kept until the next start, cleared once the filter runs.
  BackendMessage? _error;

  /// When the service was first seen starting without the virtual output yet.
  DateTime? _startingSince;
  bool _busy = false;

  /// A service still starting after this long is reported as failing (it keeps restarting).
  final Duration startTimeout;
  static const defaultStartTimeout = Duration(seconds: 20);

  static const _langKey = 'lang';

  /// [engine]: Linux engine host; by default the one next to the app on Linux. [blur]: Linux screen blur; by
  /// default the helper next to the app on Linux. [platform]: `linux`, `windows`, ... (tests; default: this
  /// system). [poll]: state refresh period (null: only after actions and [refresh] calls).
  static Future<DesktopBackend> open({
    File? file,
    Directory? licencesDir,
    LinuxEngine? engine,
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
    final linux = platform == 'linux';
    if (engine == null && findEngine && linux) engine = LinuxEngine.find();
    if (!linux) blur = null; // TODO(blur): Windows capture + overlay
    if (blur == null && findBlur && linux) {
      blur = LinuxBlur.find(tokenFile: File('${file.parent.path}/screencast-restore-token'));
    }
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
      version: '0.2.6',
      language: saved[_langKey] == 'en' ? 'en' : 'ar', // Arabic first, whatever the system language
      settings: WaaiyaSettings.fromMap(settings),
      filter: FilterInfo(simulated: engine == null),
      detectorModel: detector,
      // Women's singing only with a bundled detector: without one the engine mutes all voice while it is on.
      // TODO(engine): Windows host.
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
      ),
    ));
  }

  // --- Linux engine host ---

  void _emitFilter(FilterState s, {bool? autostart}) => emit(state.copyWith(
        filter: FilterInfo(state: s, error: _error, autostart: autostart ?? state.filter.autostart),
      ));

  /// Reads the engine's state (polled; also after every action).
  Future<void> refresh() async {
    final e = engine;
    if (e == null || _busy) return;
    final st = await e.status();
    if (_busy) return; // an action started meanwhile; it refreshes when done
    final FilterState s;
    if (st.sinkUp) {
      s = FilterState.filtering;
      _error = null;
      _startingSince = null;
    } else if (const {'active', 'activating', 'reloading'}.contains(st.active)) {
      s = FilterState.starting;
      _startingSince ??= DateTime.now();
      if (_error == null && DateTime.now().difference(_startingSince!) > startTimeout) {
        _error = BackendMessage('service_failed', await e.journal());
      }
    } else {
      s = FilterState.stopped;
      _startingSince = null;
      if (st.active == 'failed' && _error == null) _error = BackendMessage('service_failed', await e.journal());
    }
    _emitFilter(s, autostart: st.autostart);
  }

  /// Runs [action] with polling paused; a returned problem becomes `filter.error`.
  Future<bool> _act(Future<BackendMessage?> Function(LinuxEngine e) action) async {
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
    _emitFilter(FilterState.starting);
    final ok = await _act((e) async =>
        await e.preflight() ??
        await e.installIfNeeded() ??
        // fail-safe: never leave women's singing on without a detector (all voice would be muted)
        await e.setWomenSinging(e.hasDetector && state.settings.muteWomenSinging) ??
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
    await _act((e) => e.stop());
    await refresh();
  }

  @override
  Future<void> setSetting(String key, Object value) async {
    await super.setSetting(key, value);
    if (_blurKeys.contains(key)) await _applyBlur();
    final e = engine;
    if (e == null || key != SettingKeys.muteWomenSinging || !e.hasDetector) return;
    // `waaiya women-singing on|off` applies at the next start: restart a running filter.
    final running = state.filter.running;
    final ok = await _act((e) async =>
        await e.setWomenSinging(value == true) ?? (running ? await e.stop() ?? await e.start() : null));
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
