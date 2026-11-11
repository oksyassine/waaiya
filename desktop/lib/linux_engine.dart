import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

/// What `waaiya status` and systemd say about the Linux filter.
class EngineStatus {
  const EngineStatus({required this.sinkUp, required this.active, required this.autostart});

  /// The virtual output "Waaiya" exists: the filter is running (`filter:   running`).
  final bool sinkUp;

  /// `systemctl --user is-active islamic-mute.service`: active, activating, inactive, failed, ...
  final String active;

  /// `autostart: on`.
  final bool autostart;
}

/// The Linux audio engine shipped in the desktop bundle (`<bundle>/engine`, desktop/tool/bundle_engine.sh) and
/// driven through its `waaiya` script (linux/bin/islamic-mute): install, start, stop, status, women-singing.
/// The filter runs as the systemd user service islamic-mute.service, so it keeps running when the app is closed.
///
/// Every call returns facts or a [BackendMessage] code (docs/UI_CONTRACT.md, `filter.error`); no display text.
class LinuxEngine {
  LinuxEngine(this.dir, {Map<String, String>? environment}) : env = environment ?? Platform.environment;

  static const service = 'islamic-mute.service';
  static const _sink = 'islamic_mute';

  /// `<bundle>/engine`.
  final Directory dir;

  /// Environment for every command (tests put fake `pactl` / `systemctl` on PATH).
  final Map<String, String> env;

  /// The engine next to the app, or null (a development run, or a bundle without it: start/stop are simulated).
  static LinuxEngine? find({Directory? dir, Map<String, String>? environment}) {
    dir ??= Directory('${File(Platform.resolvedExecutable).parent.path}/engine');
    final e = LinuxEngine(dir, environment: environment);
    return File(e._bundledScript).existsSync() ? e : null;
  }

  String get _bundledScript => '${dir.path}/linux/bin/islamic-mute';

  /// Where `waaiya install` puts the engine (the script's $LIB).
  String get libDir {
    final xdg = env['XDG_DATA_HOME'];
    return '${xdg != null && xdg.isNotEmpty ? xdg : '${env['HOME'] ?? '.'}/.local/share'}/islamic-mute';
  }

  String get _installedScript => '$libDir/islamic-mute';

  String get bundledVersion => _readTrim('${dir.path}/VERSION') ?? '';

  String? get installedVersion => File(_installedScript).existsSync() ? _readTrim('$libDir/VERSION') ?? '' : null;

  /// The women's-singing detector is bundled (the public models release has none yet).
  bool get hasDetector => File('${dir.path}/models/detector/detector_v1.onnx').existsSync();

  /// Can the filter run here at all? Null when it can, else the reason.
  Future<BackendMessage?> preflight() async {
    if (_which('pactl') == null) return const BackendMessage('no_pactl');
    if ((await _run('pactl', ['info'])).exitCode != 0) return const BackendMessage('no_sound_server');
    if (_which('systemctl') == null ||
        (await _run('systemctl', ['--user', 'show-environment'])).exitCode != 0) {
      return const BackendMessage('no_systemd');
    }
    final sinks = await _run('pactl', ['list', 'short', 'sinks']);
    final real = _lines(sinks.stdout).map((l) => l.split(RegExp(r'\s+'))).where((f) => f.length > 1 && f[1] != _sink);
    if (real.isEmpty) return const BackendMessage('no_output');
    return null;
  }

  /// Installs the bundled engine when it is missing or another version (the filter must not be running: the
  /// install replaces its binaries). Null on success.
  Future<BackendMessage?> installIfNeeded() async {
    final want = bundledVersion;
    if (installedVersion == want && want.isNotEmpty) return null;
    final r = await _run(_bundledScript, ['install']);
    if (r.exitCode != 0 || installedVersion != want) return BackendMessage('install_failed', _detail(r));
    return null;
  }

  /// `waaiya women-singing on|off` (applies at the next start).
  Future<BackendMessage?> setWomenSinging(bool on) async {
    if (installedVersion == null) return null;
    final r = await _run(_installedScript, ['women-singing', if (on) 'on' else 'off']);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  Future<BackendMessage?> start() async {
    final r = await _run(_installedScript, ['start']);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  /// `waaiya stop`: the service restores normal audio and removes the virtual output.
  Future<BackendMessage?> stop() async {
    if (installedVersion == null) return null;
    final r = await _run(_installedScript, ['stop']);
    return r.exitCode == 0 ? null : BackendMessage('service_failed', _detail(r));
  }

  /// Start at login: `systemctl --user enable|disable` (not `waaiya enable|disable`, which also start / stop now).
  Future<BackendMessage?> setAutostart(bool on) async {
    final r = await _run('systemctl', ['--user', if (on) 'enable' else 'disable', service]);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  Future<EngineStatus> status() async {
    final active = (await _run('systemctl', ['--user', 'is-active', service])).stdout.toString().trim();
    if (installedVersion == null) return EngineStatus(sinkUp: false, active: active, autostart: false);
    final out = (await _run(_installedScript, ['status'])).stdout.toString();
    String? field(String name) {
      for (final l in _lines(out)) {
        final m = RegExp('^$name:\\s*(.*)\$').firstMatch(l);
        if (m != null) return m.group(1)!.trim();
      }
      return null;
    }

    return EngineStatus(sinkUp: field('filter') == 'running', active: active, autostart: field('autostart') == 'on');
  }

  /// The service's last log lines, for `service_failed`.
  Future<String> journal() async {
    final r = await _run('journalctl', ['--user', '-u', service, '-n', '6', '-o', 'cat', '--no-pager']);
    return r.exitCode == 0 ? r.stdout.toString().trim() : '';
  }

  // --- helpers ---

  Future<ProcessResult> _run(String exe, List<String> args) async {
    try {
      return await Process.run(exe, args, environment: env, includeParentEnvironment: false);
    } on ProcessException catch (e) {
      return ProcessResult(0, 127, '', e.message);
    }
  }

  String? _which(String name) {
    for (final d in (env['PATH'] ?? '').split(':')) {
      if (d.isEmpty) continue;
      final f = File('$d/$name');
      if (f.existsSync()) return f.path;
    }
    return null;
  }

  static List<String> _lines(Object? s) => '$s'.split('\n').where((l) => l.trim().isNotEmpty).toList();

  /// The last lines of a command's output, as the error detail.
  static String _detail(ProcessResult r) {
    final lines = [..._lines(r.stdout), ..._lines(r.stderr)];
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
