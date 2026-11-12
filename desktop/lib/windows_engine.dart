import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

import 'filter_host.dart';

/// The Windows sound filter shipped in the desktop bundle (`<bundle>\engine\waaiya-filter.exe`, windows/filter).
///
/// It runs from the bundle, detached from the app, so it keeps filtering when the app is closed; "Start at login"
/// is a value under the user's Run key. It reads the app's own settings file (%APPDATA%\Waaiya\settings.json) and
/// applies changes while it runs, so the setting calls here have nothing to do: the app has saved the file first.
/// Its state is %LOCALAPPDATA%\Waaiya\filter\state.json, read directly ([status]).
///
/// How it filters: every other app is turned down to -80 dB, their mix is read by process loopback, brought back up,
/// filtered and played. When it dies, Windows keeps the apps turned down (silent) until Start or Stop.
class WindowsEngine implements FilterHost {
  WindowsEngine(this.dir, {Map<String, String>? environment}) : env = environment ?? Platform.environment;

  /// `<bundle>\engine`.
  final Directory dir;
  final Map<String, String> env;

  static const runValue = 'WaaiyaFilter';
  static const _runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  /// The filter next to the app, or null (a development run, or a bundle without it: start/stop are simulated).
  static WindowsEngine? find({Directory? dir, Map<String, String>? environment}) {
    dir ??= Directory('${File(Platform.resolvedExecutable).parent.path}\\engine');
    final e = WindowsEngine(dir, environment: environment);
    return e.exe.existsSync() ? e : null;
  }

  File get exe => File('${dir.path}\\waaiya-filter.exe');

  /// %LOCALAPPDATA%\Waaiya\filter: state.json, filter.log, levels.txt (the apps' own levels, given back at Stop).
  String get stateDir => '${env['LOCALAPPDATA'] ?? env['USERPROFILE'] ?? '.'}\\Waaiya\\filter';

  @override
  String get bundledVersion => _readTrim('${dir.path}\\VERSION') ?? '';

  /// Runs from the bundle: nothing to install.
  @override
  String? get installedVersion => bundledVersion;

  @override
  bool get hasDetector => File('${dir.path}\\models\\detector\\detector_v1.onnx').existsSync();

  @override
  bool? get stereoSet => null;
  @override
  bool? get keepSilentSet => null;

  /// The filter shows no notice of its own yet; the app shows the state when it is open.
  @override
  void writeNotice(String title, String text) {}

  /// Process loopback needs Windows 10 version 2004 (build 19041) or newer.
  @override
  Future<BackendMessage?> preflight() async {
    final build = windowsBuild(Platform.operatingSystemVersion);
    if (build != null && build < 19041) {
      return BackendMessage('start_failed', 'Windows 10 version 2004 (build 19041) or newer is needed; this is build $build.');
    }
    return null;
  }

  /// "Windows 10 Pro" 10.0 (Build 19045) -> 19045.
  static int? windowsBuild(String osVersion) {
    final m = RegExp(r'Build (\d+)').firstMatch(osVersion);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  @override
  Future<BackendMessage?> installIfNeeded() async => null;
  @override
  Future<BackendMessage?> setWomenSinging(bool on) async => null;
  @override
  Future<BackendMessage?> setStereo(bool on) async => null;
  @override
  Future<BackendMessage?> setKeepSilent(bool on) async => null;
  @override
  Future<BackendMessage?> reload() async => null;

  /// Starts the filter, detached, and waits until it plays (or says why not).
  @override
  Future<BackendMessage?> start({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      await Process.start(exe.path, ['run'], mode: ProcessStartMode.detached, environment: env, includeParentEnvironment: false);
    } on ProcessException catch (e) {
      return BackendMessage('start_failed', e.message);
    }
    final end = DateTime.now().add(timeout);
    EngineStatus st;
    do {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      st = await status();
      if (st.sinkUp) return null;
    } while (DateTime.now().isBefore(end));
    if (st.active == 'activating') return null; // running, retrying its audio: the state says so
    return BackendMessage('start_failed', filterLogTail(maxBytes: 600));
  }

  /// The filter gives every app its level back (apps not running get theirs when they next play).
  @override
  Future<BackendMessage?> stop() async {
    final r = await _run(exe.path, ['stop']);
    return r.exitCode == 0 ? null : BackendMessage('service_failed', _detail(r));
  }

  @override
  Future<BackendMessage?> setAutostart(bool on) async {
    final r = await _run('reg', [
      if (on) 'add' else 'delete',
      _runKey,
      '/v',
      runValue,
      if (on) ...['/t', 'REG_SZ', '/d', '"${exe.path}" run'],
      '/f',
    ]);
    // deleting a value that is not there is fine
    if (r.exitCode == 0 || (!on && !await _autostart())) return null;
    return BackendMessage('start_failed', _detail(r));
  }

  Future<bool> _autostart() async => (await _run('reg', ['query', _runKey, '/v', runValue])).exitCode == 0;

  /// Read from state.json directly (the filter rewrites it at least every 2 s; older than 5 s, it is not running or
  /// stuck), not from `waaiya-filter status`: no process per poll, and no reliance on a GUI program's console output.
  @override
  Future<EngineStatus> status() async {
    String json = '';
    try {
      json = await File('$stateDir\\state.json').readAsString();
    } on IOException {
      // never ran
    }
    return parseStatus(json, autostart: await _autostart(), now: DateTime.now());
  }

  /// state.json (optionally after a "process: running|none" line, as `waaiya-filter status` prints it). Without that
  /// line, the filter counts as running while its state is fresh.
  static EngineStatus parseStatus(String out, {required bool autostart, required DateTime now}) {
    Map<String, Object?> j = const {};
    final brace = out.indexOf('{');
    if (brace >= 0) {
      try {
        j = (jsonDecode(out.substring(brace).trim()) as Map).cast<String, Object?>();
      } on FormatException {
        // half-written: as if absent
      }
    }
    final state = j['state'] is String ? j['state'] as String : '';
    final t = j['t'] is num ? (j['t'] as num).toInt() : 0;
    // the filter rewrites its state at least every 2 s: older than 5 s, it is stuck or gone
    final fresh = now.millisecondsSinceEpoch - t < 5000;
    final processLine = RegExp(r'^process: (running|none)', multiLine: true).firstMatch(out);
    final alive = processLine != null ? processLine.group(1) == 'running' && fresh : fresh;
    final engine = j['engine'] is String ? j['engine'] as String : '';
    String active, filter;
    if (alive && fresh && state == 'filtering') {
      active = 'active';
      filter = 'running';
    } else if (alive && (state == 'starting' || state == 'failing')) {
      active = 'activating';
      filter = '';
    } else if (!alive && const {'filtering', 'failing', 'starting'}.contains(state)) {
      // it died while apps were turned down: they stay silent until Start or Stop
      active = 'failed';
      filter = 'down (the filter process ended)';
    } else {
      active = 'inactive';
      filter = 'stopped';
    }
    return EngineStatus(
      sinkUp: filter == 'running',
      active: active,
      autostart: autostart,
      filter: filter,
      engine: engine,
      raw: out.trim(),
    );
  }

  @override
  Future<String> journal({int lines = 6}) async {
    final l = filterLogTail(maxBytes: 200 * lines).split('\n');
    return (l.length > lines ? l.sublist(l.length - lines) : l).join('\n').trim();
  }

  @override
  String filterLogTail({int maxBytes = 3000}) {
    try {
      final b = File('$stateDir\\filter.log').readAsBytesSync();
      return utf8.decode(b.length > maxBytes ? b.sublist(b.length - maxBytes) : b, allowMalformed: true).trim();
    } on IOException {
      return '';
    }
  }

  Future<ProcessResult> _run(String exe, List<String> args) async {
    try {
      return await Process.run(exe, args, environment: env, includeParentEnvironment: false);
    } on ProcessException catch (e) {
      return ProcessResult(0, 127, '', e.message);
    }
  }

  static String _detail(ProcessResult r) {
    final lines = '${r.stdout}\n${r.stderr}'.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final tail = lines.length > 6 ? lines.sublist(lines.length - 6) : lines;
    return tail.isEmpty ? 'exit ${r.exitCode}' : tail.join('\n');
  }

  static String? _readTrim(String path) {
    try {
      return File(path).readAsStringSync().trim();
    } on IOException {
      return null;
    }
  }
}
