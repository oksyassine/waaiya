import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

/// What the blur helper should do (the blur settings, docs/UI_CONTRACT.md).
class BlurConfig {
  const BlurConfig({required this.women, required this.nudity, required this.strictness, required this.failCover});

  factory BlurConfig.of(WaaiyaSettings s) =>
      BlurConfig(women: s.blurWomen, nudity: s.blurNudity, strictness: s.blurStrictness, failCover: s.blurFailCover);

  final bool women;
  final bool nudity;
  final int strictness;
  final bool failCover;

  /// im-blur's policy bits: 1 women, 2 nudity.
  int get policy => (women ? 1 : 0) | (nudity ? 2 : 0);
  bool get on => policy != 0;
}

/// One line of the helper's state (stdout JSON).
class BlurReport {
  const BlurReport({required this.state, this.error = '', this.ms, this.cpu, this.covers = 0, this.backend = ''});

  /// [line]: `{"state": ..., "error": ..., "backend": ..., "overlay": ..., "covers": n, "ms"?, "cpu"?, "fps"?}`.
  /// Null when the line is not a state line.
  static BlurReport? parse(String line) {
    try {
      final m = jsonDecode(line);
      if (m is! Map || m['state'] is! String) return null;
      num? n(Object? v) => v is num ? v : null;
      return BlurReport(
        state: m['state'] as String,
        error: m['error'] is String ? m['error'] as String : '',
        ms: n(m['ms'])?.toDouble(),
        cpu: n(m['cpu'])?.toDouble(),
        covers: n(m['covers'])?.toInt() ?? 0,
        backend: m['backend'] is String ? m['backend'] as String : '',
      );
    } on FormatException {
      return null;
    }
  }

  /// starting, on, on_covers_visible, failing, models_missing, no_capture, no_overlay, idle.
  final String state;

  /// The helper's reason (English, technical), or a token: `share_dialog` while starting on Wayland.
  final String error;
  final double? ms;
  final double? cpu;
  final int covers;
  final String backend;

  /// The snapshot's `blur.state`.
  BlurState? get blurState => switch (state) {
    'starting' => BlurState.starting,
    'on' => BlurState.on,
    'on_covers_visible' => BlurState.onCoversVisible,
    'failing' => BlurState.failing,
    'models_missing' => BlurState.modelsMissing,
    'no_capture' => BlurState.noCapture,
    'no_overlay' => BlurState.noOverlay,
    _ => null,
  };

  /// The snapshot's `blur.error`.
  BackendMessage? get blurError {
    if (state == 'starting' && error == 'share_dialog') return const BackendMessage('share_dialog');
    if (const {'failing', 'models_missing', 'no_capture', 'no_overlay'}.contains(state)) {
      return BackendMessage(state, error);
    }
    return null;
  }
}

/// The Linux screen blur: the `im-blur` helper in the bundle (`engine/build/im-blur`, models in
/// `engine/models/vision`), started by the app while a blur option is on and stopped when both are off or the app
/// quits. It is a child of the app on purpose: it inherits the graphical session as it is now (DISPLAY,
/// WAYLAND_DISPLAY, DBUS_SESSION_BUS_ADDRESS, XDG_RUNTIME_DIR, XAUTHORITY), which a systemd user unit only has if
/// the desktop imported it, and the Wayland screen-share dialog belongs to the app the user just used. Closing the
/// app closes the helper's stdin, and it quits.
///
/// Settings go to its stdin as commands (`policy N`, `strictness N`, `fail_cover 0|1`), applied live; its state
/// comes back as JSON lines ([BlurReport]).
class LinuxBlur {
  LinuxBlur(
    this.exe,
    this.models, {
    Map<String, String>? environment,
    this.tokenFile,
    this.restartDelay = const Duration(seconds: 3),
  }) : env = environment ?? Platform.environment;

  /// `<bundle>/engine/build/im-blur`.
  final File exe;
  final Directory models;
  final Map<String, String> env;

  /// Where the Wayland screen-share permission (restore token) is kept.
  final File? tokenFile;

  /// Wait before restarting a helper that died (at most [maxRestarts] times in a row).
  final Duration restartDelay;
  static const maxRestarts = 3;

  static const _models = ['person_yolox_nano.onnx', 'gender_v2.onnx', 'nsfw_marqo_int8.onnx'];

  /// The helper and its models next to the app, or null (a development run, or a bundle without the blur).
  static LinuxBlur? find({Directory? engineDir, Map<String, String>? environment, File? tokenFile}) {
    engineDir ??= Directory('${File(Platform.resolvedExecutable).parent.path}/engine');
    final exe = File('${engineDir.path}/build/im-blur');
    final models = Directory('${engineDir.path}/models/vision');
    if (!exe.existsSync() || _models.any((m) => !File('${models.path}/$m').existsSync())) return null;
    return LinuxBlur(exe, models, environment: environment, tokenFile: tokenFile);
  }

  final _reports = StreamController<BlurReport?>.broadcast();

  /// Every state line; null when the helper is not running (stopped, or exited: see [exitDetail]).
  Stream<BlurReport?> get reports => _reports.stream;

  BlurReport? last;

  /// Why the helper last exited on its own (exit code and its last stderr lines); null after a normal stop.
  String? exitDetail;

  Process? _p;
  BlurConfig? _cfg;
  bool _stopping = false;
  int _restarts = 0;
  Timer? _restart;
  final _stderr = <String>[];

  bool get running => _p != null;

  /// Starts the helper, or updates the running one, for [cfg]; stops it when no blur option is on.
  Future<void> apply(BlurConfig cfg) async {
    final old = _cfg;
    _cfg = cfg;
    if (!cfg.on) return stop();
    final p = _p;
    if (p == null) {
      _restarts = 0;
      return _start();
    }
    if (old == null || old.policy != cfg.policy) _send('policy ${cfg.policy}');
    if (old == null || old.strictness != cfg.strictness) _send('strictness ${cfg.strictness}');
    if (old == null || old.failCover != cfg.failCover) _send('fail_cover ${cfg.failCover ? 1 : 0}');
  }

  Future<void> _start() async {
    final cfg = _cfg;
    if (cfg == null || !cfg.on || _p != null) return;
    _restart?.cancel();
    exitDetail = null;
    _stderr.clear();
    final Process p;
    try {
      p = await Process.start(
        exe.path,
        [
          '--models',
          models.path,
          '--policy',
          '${cfg.policy}',
          '--strictness',
          '${cfg.strictness}',
          '--fail-cover',
          cfg.failCover ? '1' : '0',
          if (tokenFile != null) ...['--token-file', tokenFile!.path],
        ],
        environment: env,
        includeParentEnvironment: false,
      );
    } on ProcessException catch (e) {
      exitDetail = e.message;
      last = null;
      _reports.add(null);
      return;
    }
    _p = p;
    _stopping = false;
    last = const BlurReport(state: 'starting');
    _reports.add(last);
    p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      final r = BlurReport.parse(line);
      if (r == null || _p != p) return;
      if (r.state == 'on' || r.state == 'on_covers_visible') _restarts = 0; // it works: a later crash restarts again
      last = r;
      _reports.add(r);
    });
    p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      _stderr.add(l);
      if (_stderr.length > 6) _stderr.removeAt(0);
    });
    unawaited(p.exitCode.then((code) => _exited(p, code)));
  }

  Future<void> _exited(Process p, int code) async {
    if (_p != p) return;
    _p = null;
    last = null;
    if (_stopping) {
      _reports.add(null);
      return;
    }
    // died on its own: report it, and try again a few times (a crash in a driver, a display server restart)
    exitDetail = ['exit code $code', ..._stderr].join('\n');
    _reports.add(null);
    if (_restarts < maxRestarts && (_cfg?.on ?? false)) {
      _restarts++;
      _restart = Timer(restartDelay, () => _start());
    }
  }

  void _send(String cmd) {
    try {
      _p?.stdin.writeln(cmd);
    } on Object {
      // the helper is exiting; its exit is reported
    }
  }

  /// Asks the helper to quit (stdin closed), then kills it if it does not within 3 s.
  Future<void> stop() async {
    _restart?.cancel();
    final p = _p;
    if (p == null) return;
    _stopping = true;
    try {
      p.stdin.writeln('quit');
      await p.stdin.close();
    } on Object {
      // already gone
    }
    final code = await p.exitCode.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        p.kill(ProcessSignal.sigkill);
        return -9;
      },
    );
    await _exited(p, code);
  }

  Future<void> dispose() async {
    _cfg = null;
    await stop();
    await _reports.close();
  }
}
