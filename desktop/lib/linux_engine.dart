import 'dart:convert';
import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

import 'filter_host.dart';

export 'filter_host.dart';

/// The Linux audio engine shipped in the desktop bundle (`<bundle>/engine`, desktop/tool/bundle_engine.sh) and
/// driven through its `waaiya` script (linux/bin/islamic-mute): install, start, stop, status, women-singing.
/// The filter runs as the systemd user service islamic-mute.service, so it keeps running when the app is closed.
///
/// Every call returns facts or a [BackendMessage] code (docs/UI_CONTRACT.md, `filter.error`); no display text.
class LinuxEngine implements FilterHost {
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

  /// The script's settings folder ($CFG: `$XDG_CONFIG_HOME/islamic-mute`).
  String get configDir {
    final xdg = env['XDG_CONFIG_HOME'];
    return '${xdg != null && xdg.isNotEmpty ? xdg : '${env['HOME'] ?? '.'}/.config'}/islamic-mute';
  }

  /// What `waaiya stereo` / `waaiya keep-silent` last set (also by hand on the command line); null: never set.
  @override
  bool? get stereoSet => _onOff('stereo');
  @override
  bool? get keepSilentSet => _onOff('keep_silent');

  bool? _onOff(String name) => switch (_readTrim('$configDir/$name')) {
        'on' => true,
        'off' => false,
        _ => null,
      };

  /// The notice the daemon shows when it gives the normal sound back (`$CFG/notice`: title line, text line), in
  /// the app's language.
  @override
  void writeNotice(String title, String text) {
    try {
      Directory(configDir).createSync(recursive: true);
      File('$configDir/notice').writeAsStringSync('${title.replaceAll('\n', ' ')}\n${text.replaceAll('\n', ' ')}\n');
    } on IOException {
      // the English default then
    }
  }

  @override
  String get bundledVersion => _readTrim('${dir.path}/VERSION') ?? '';

  @override
  String? get installedVersion => File(_installedScript).existsSync() ? _readTrim('$libDir/VERSION') ?? '' : null;

  /// The women's-singing detector is bundled (the public models release has none yet).
  @override
  bool get hasDetector => File('${dir.path}/models/detector/detector_v1.onnx').existsSync();

  /// Can the filter run here at all? Null when it can, else the reason.
  @override
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
  @override
  Future<BackendMessage?> installIfNeeded() async {
    final want = bundledVersion;
    if (installedVersion == want && want.isNotEmpty) return null;
    final r = await _run(_bundledScript, ['install']);
    if (r.exitCode != 0 || installedVersion != want) return BackendMessage('install_failed', _detail(r));
    return null;
  }

  /// `waaiya women-singing on|off` (applies at the next start, or at once with [reload]).
  @override
  Future<BackendMessage?> setWomenSinging(bool on) async {
    if (installedVersion == null) return null;
    final r = await _run(_installedScript, ['women-singing', if (on) 'on' else 'off']);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  /// `waaiya stereo on|off` (setting `audio_stereo`; applies at the next start, or at once with [reload]).
  @override
  Future<BackendMessage?> setStereo(bool on) => _set('stereo', on);

  /// `waaiya keep-silent on|off` (setting `hold_silence`): when filtering stops by itself, apps stay silent (on)
  /// or get their normal sound back with a desktop notice (off). Read by the daemon when it happens.
  @override
  Future<BackendMessage?> setKeepSilent(bool on) => _set('keep-silent', on);

  Future<BackendMessage?> _set(String cmd, bool on) async {
    if (installedVersion == null) return null;
    final r = await _run(_installedScript, [cmd, if (on) 'on' else 'off']);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  /// A running filter takes the current settings: `waaiya reload` restarts only the filter process, the apps stay
  /// on the virtual output meanwhile (a moment of silence, never unfiltered sound). An engine installed before
  /// `reload` existed gets stop + start instead.
  @override
  Future<BackendMessage?> reload() async {
    if (installedVersion == null) return null;
    final r = await _run(_installedScript, ['reload']);
    if (r.exitCode == 0) return null;
    return await stop() ?? await start();
  }

  @override
  Future<BackendMessage?> start() async {
    final r = await _run(_installedScript, ['start']);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  /// `waaiya stop`: the service restores normal audio and removes the virtual output.
  @override
  Future<BackendMessage?> stop() async {
    if (installedVersion == null) return null;
    final r = await _run(_installedScript, ['stop']);
    return r.exitCode == 0 ? null : BackendMessage('service_failed', _detail(r));
  }

  /// Start at login: `systemctl --user enable|disable` (not `waaiya enable|disable`, which also start / stop now).
  @override
  Future<BackendMessage?> setAutostart(bool on) async {
    final r = await _run('systemctl', ['--user', if (on) 'enable' else 'disable', service]);
    return r.exitCode == 0 ? null : BackendMessage('start_failed', _detail(r));
  }

  @override
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

    final filter = field('filter') ?? '';
    return EngineStatus(
      sinkUp: filter == 'running',
      active: active,
      autostart: field('autostart') == 'on',
      filter: filter,
      engine: field('engine') ?? '',
      raw: out.trim(),
    );
  }

  /// The service's last log lines, for `service_failed` ([lines] more for the diagnostics report).
  @override
  Future<String> journal({int lines = 6}) async {
    final r = await _run('journalctl', ['--user', '-u', service, '-n', '$lines', '-o', 'cat', '--no-pager']);
    return r.exitCode == 0 ? r.stdout.toString().trim() : '';
  }

  /// The end of the filter's own log (`$XDG_STATE_HOME/islamic-mute/filter.log`), for the diagnostics report.
  @override
  String filterLogTail({int maxBytes = 3000}) {
    final xdg = env['XDG_STATE_HOME'];
    final f = File('${xdg != null && xdg.isNotEmpty ? xdg : '${env['HOME'] ?? '.'}/.local/state'}/islamic-mute/filter.log');
    try {
      final b = f.readAsBytesSync();
      return utf8.decode(b.length > maxBytes ? b.sublist(b.length - maxBytes) : b, allowMalformed: true).trim();
    } on IOException {
      return '';
    }
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
