import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:waaiya_ui/waaiya_ui.dart';
// ignore: implementation_imports
import 'package:waaiya_ui/src/protection_core.dart' show ProtectionClock, ProcessClock;

import 'filter_host.dart';

/// The Windows sound filter shipped in the desktop bundle (`<bundle>\engine\waaiya-filter.exe`, windows/filter).
///
/// It runs from the bundle, detached from the app, so it keeps filtering when the app is closed; "Start at login"
/// is a value under the user's Run key, or, in the Microsoft Store package (desktop/msix, [packaged]), the file
/// `autostart` that the package's startup task (`waaiya-filter autostart`, at every login) looks for: a packaged
/// app's registry writes stay inside the package, where Windows does not read Run values. It reads the app's own settings file (%APPDATA%\Waaiya\settings.json) and
/// applies changes while it runs, so the setting calls here have nothing to do: the app has saved the file first.
/// Its state is %LOCALAPPDATA%\Waaiya\filter\state.json, read directly ([status]).
///
/// How it filters: every other app is turned down to -80 dB, their mix is read by process loopback, brought back up,
/// filtered and played. When it dies, Windows keeps the apps turned down (silent) until Start or Stop.
class WindowsEngine implements FilterHost {
  WindowsEngine(this.dir,
      {Map<String, String>? environment,
      bool? packaged,
      Future<String> Function(String method)? startupTask,
      Future<void> Function(String uri)? openSettings})
      : env = environment ?? Platform.environment,
        packaged = packaged ?? (isPackagedPath(dir.path) || isPackagedProcess()),
        startupTask = startupTask ?? _startupChannel,
        openSettings = openSettings ?? _openUri;

  /// The package's startup task as Windows has it (desktop/windows/runner/startup.cpp): `state`, or `request`
  /// (Windows asks the user when it is off). Answers enabled, disabled, disabledByUser, disabledByPolicy,
  /// enabledByPolicy, or none (no package, or no runner side: the autostart file alone decides).
  final Future<String> Function(String method) startupTask;

  /// Opens a Settings page (ms-settings:startupapps).
  final Future<void> Function(String uri) openSettings;

  static Future<String> _startupChannel(String method) async {
    try {
      return await const MethodChannel('waaiya/startup').invokeMethod<String>(method) ?? 'none';
    } on MissingPluginException {
      return 'none';
    } on PlatformException {
      return 'none';
    }
  }

  static Future<void> _openUri(String uri) => Process.run('explorer.exe', [uri]);

  /// Windows lets the startup task run.
  static bool startupAllowed(String state) =>
      !const {'disabled', 'disabledByUser', 'disabledByPolicy'}.contains(state);

  /// `<bundle>\engine`.
  final Directory dir;
  final Map<String, String> env;

  /// Installed from the Microsoft Store (an MSIX package): the app runs from `C:\Program Files\WindowsApps`.
  final bool packaged;

  static bool isPackagedPath(String path) => path.toLowerCase().contains(r'\windowsapps\');

  /// This app runs with a package identity (the Store's install, or the same package installed unpacked in
  /// Developer Mode, outside WindowsApps): Windows' own answer, as waaiya-filter.exe asks it.
  static bool isPackagedProcess() {
    if (!Platform.isWindows) return false;
    try {
      final ole = DynamicLibrary.open('ole32.dll');
      final alloc = ole.lookupFunction<Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('CoTaskMemAlloc');
      final free = ole.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('CoTaskMemFree');
      final name = DynamicLibrary.open('kernel32.dll').lookupFunction<Int32 Function(Pointer<Uint32>, Pointer<Uint16>),
          int Function(Pointer<Uint32>, Pointer<Uint16>)>('GetCurrentPackageFullName');
      final len = alloc(4).cast<Uint32>();
      if (len == nullptr) return false;
      len.value = 0;
      final r = name(len, nullptr);
      free(len.cast());
      return r != 15700; // APPMODEL_ERROR_NO_PACKAGE
    } on Object {
      return false;
    }
  }

  static const runValue = 'WaaiyaFilter';
  static const appRunValue = 'Waaiya';
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

  /// The "keep singing" model (voice_v1) is in the bundle; the filter switches to it while running when the setting
  /// `keep_singing` changes (it reads the settings file).
  bool get hasSingingModel =>
      File('${dir.path}\\models\\voice\\v3\\voice_v1_fp16.onnx').existsSync() &&
      File('${dir.path}\\models\\voice\\v3\\voice_v1_fp16.state_init.bin').existsSync();

  /// The apps with a sound session now, as the filter last wrote them (state.json "apps"): file name ("chrome.exe",
  /// what the setting `filter_off_apps` holds) and the name Windows shows ("Google Chrome").
  List<({String exe, String name})> playingApps() => appsFrom(_readState());

  static List<({String exe, String name})> appsFrom(String json) {
    try {
      final apps = (jsonDecode(json) as Map)['apps'];
      if (apps is! List) return const [];
      return [
        for (final a in apps)
          if (a is Map && a['exe'] is String && (a['exe'] as String).isNotEmpty)
            (exe: a['exe'] as String, name: a['name'] is String ? a['name'] as String : a['exe'] as String),
      ];
    } on Object {
      return const [];
    }
  }

  String _readState() {
    try {
      return File('$stateDir\\state.json').readAsStringSync();
    } on IOException {
      return '';
    }
  }

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
    final since = DateTime.now().subtract(const Duration(seconds: 1));
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
    return BackendMessage('start_failed', startFailure(filterLogTail(maxBytes: 4000), since));
  }

  /// Why a start failed, for the details under the message: the filter's log lines written since [since] (older
  /// ones belong to another run and only mislead), or, when it wrote none, what that means.
  static String startFailure(String log, DateTime since) {
    final recent = log.split('\n').where((line) {
      final t = line.length >= 23 ? DateTime.tryParse(line.substring(0, 23)) : null;
      return t != null && !t.isBefore(since);
    }).toList();
    if (recent.isNotEmpty) return (recent.length > 8 ? recent.sublist(recent.length - 8) : recent).join('\n');
    return 'waaiya-filter.exe did not answer. Another Waaiya filter may be running and not responding (for example '
        'one from an older version). Restarting the computer ends it.';
  }

  /// The filter gives every app its level back (apps not running get theirs when they next play).
  @override
  Future<BackendMessage?> stop() async {
    final r = await _run(exe.path, ['stop']);
    return r.exitCode == 0 ? null : BackendMessage('service_failed', _detail(r));
  }

  /// Levels the filter could not give back yet are stored (levels.txt not empty).
  bool get levelsStored {
    try {
      return File('$stateDir\\levels.txt').lengthSync() > 0;
    } on IOException {
      return false;
    }
  }

  /// When the app opens with no filter running: give back the levels left lowered? [active] is [EngineStatus.active]
  /// ('failed': the filter died while apps were lowered). Never when the filter starts at login ([autostart]): it
  /// lowers them again at once, and a restorer racing it would let unfiltered sound through at every login. Levels
  /// left by a clean end (Stop, the session ending, an update) are always given back; those of a filter that died
  /// only with [holdSilence] off (on: apps stay silent until Start or Stop, the owner's fail-closed choice).
  static bool restoreAtOpen(
          {required String active, required bool levelsStored, required bool autostart, required bool holdSilence}) =>
      levelsStored &&
      !autostart &&
      const {'inactive', 'failed'}.contains(active) &&
      (active != 'failed' || !holdSilence);

  /// `waaiya-filter restore`, detached: gives stored levels back as their apps show up, then ends. It leaves at once
  /// when a filter or another restorer runs, and a Start makes it quit.
  Future<void> restoreLevels() async {
    try {
      await Process.start(exe.path, ['restore'], mode: ProcessStartMode.detached, environment: env, includeParentEnvironment: false);
    } on ProcessException {
      // the next Stop gives them back
    }
  }

  @override
  Future<BackendMessage?> setAutostart(bool on) async {
    if (packaged) {
      final f = File('$stateDir\\autostart');
      try {
        if (on) {
          await f.parent.create(recursive: true);
          await f.writeAsString('1\n');
        } else if (await f.exists()) {
          await f.delete();
        }
      } on IOException catch (e) {
        return BackendMessage('start_failed', '$e');
      }
      _startup = null;
      if (!on) return null;
      // Windows must let the startup task run: it asks the user when the task is off; one the user turned off in
      // Settings > Apps > Startup can only be turned on there (that page opens)
      final state = await startupTask('request');
      if (startupAllowed(state)) return null;
      if (state == 'disabledByPolicy') return const BackendMessage('autostart_policy');
      if (state == 'disabledByUser') await openSettings('ms-settings:startupapps');
      return const BackendMessage('autostart_blocked');
    }
    final r = await _run('reg', [
      if (on) 'add' else 'delete',
      _runKey,
      '/v',
      runValue,
      if (on) ...['/t', 'REG_SZ', '/d', '"${exe.path}" run'],
      '/f',
    ]);
    // the app too, hidden at login: only its icon next to the clock (the Store package: the filter starts it)
    final app = File('${dir.parent.path}\\waaiya_desktop.exe');
    if (!on || (r.exitCode == 0 && app.existsSync())) {
      await _run('reg', [
        if (on) 'add' else 'delete',
        _runKey,
        '/v',
        appRunValue,
        if (on) ...['/t', 'REG_SZ', '/d', '"${app.path}" --tray'],
        '/f',
      ]);
    }
    // deleting a value that is not there is fine
    if (r.exitCode == 0 || (!on && !await _autostart())) return null;
    return BackendMessage('start_failed', _detail(r));
  }

  Future<bool> _autostart() async => packaged
      ? await File('$stateDir\\autostart').exists() && startupAllowed(await _startupState())
      : (await _run('reg', ['query', _runKey, '/v', runValue])).exitCode == 0;

  // read again at most every 10 s (the status is polled), and after a change
  String? _startup;
  DateTime _startupAt = DateTime(0);
  Future<String> _startupState() async {
    if (_startup == null || DateTime.now().difference(_startupAt) > const Duration(seconds: 10)) {
      _startup = await startupTask('state');
      _startupAt = DateTime.now();
    }
    return _startup!;
  }

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

/// The clock of the waiting period on Windows (protection_core.dart): the time since Windows started
/// (GetTickCount64: sleep and hibernation included, not changed by the clock settings), so the wait keeps counting
/// while Waaiya is closed and a clock change does not shorten it. The boot id is always the same: after a restart
/// the count is lower than the one saved, which ProtectionCore reads as a new boot (only the time since that start
/// counts); in the rare case the new count is already above the saved one, it counts less than the real time,
/// never more. A restart or a clock change can make the wait longer, never shorter.
class WindowsTickClock implements ProtectionClock {
  WindowsTickClock() : _ticks = _lookup();

  final int Function()? _ticks;
  final _fallback = ProcessClock();

  static int Function()? _lookup() {
    try {
      return DynamicLibrary.open('kernel32.dll').lookupFunction<Uint64 Function(), int Function()>('GetTickCount64');
    } on Object {
      return null;
    }
  }

  @override
  int wallMs() => DateTime.now().millisecondsSinceEpoch;

  @override
  int elapsedMs() => _ticks?.call() ?? _fallback.elapsedMs();

  @override
  String bootId() => _ticks != null ? 'windows' : _fallback.bootId();
}
