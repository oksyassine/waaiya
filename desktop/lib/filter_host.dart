import 'package:waaiya_ui/waaiya_ui.dart';

/// What the filter host says about the filter (Linux: `waaiya status` and systemd; Windows: `waaiya-filter status`).
class EngineStatus {
  const EngineStatus({
    required this.sinkUp,
    required this.active,
    required this.autostart,
    this.filter = '',
    this.engine = '',
    this.raw = '',
  });

  /// The daemon, its filter process and the virtual output "Waaiya" are all there (`filter:   running`).
  final bool sinkUp;

  /// `filter:` as the script says it: `running`, `restarting` (the filter process is being replaced),
  /// `down (...)` (the daemon is gone but the virtual output stays: apps are silent), `stopped`.
  final String filter;

  /// `engine:`: `ok`, `model not loaded, ...`, `detector not loaded, ...`, `starting`; empty from an older script.
  final String engine;

  /// The whole `waaiya status` output (diagnostics report).
  final String raw;

  /// The filter runs but its voice model did not load: the output is silent (fail-closed).
  bool get modelFailed => engine.startsWith('model not loaded');

  /// The women's-singing detector did not load: voices are muted while that option is on (fail-closed).
  bool get detectorFailed => engine.startsWith('detector not loaded');

  /// The daemon is gone and the virtual output stayed: apps are silent until the filter is started again.
  bool get down => filter.startsWith('down');

  /// `systemctl --user is-active islamic-mute.service`: active, activating, inactive, failed, ...
  final String active;

  /// `autostart: on`.
  final bool autostart;
}

/// The always-on sound filter of a desktop system, as [DesktopBackend] drives it: [LinuxEngine] (systemd user service,
/// virtual output) or [WindowsEngine] (`waaiya-filter.exe`, other apps lowered + process loopback).
///
/// Every call returns facts or a [BackendMessage] code (docs/UI_CONTRACT.md, `filter.error`); no display text.
abstract interface class FilterHost {
  /// `<app version>-<hash of the engine files>` (the bundle's `engine/VERSION`).
  String get bundledVersion;

  /// The version installed where the filter runs from; null: not installed.
  String? get installedVersion;

  /// The women's-singing detector is bundled.
  bool get hasDetector;

  /// Settings changed outside the app (Linux: `waaiya stereo` typed by hand); null: never set there.
  bool? get stereoSet;
  bool? get keepSilentSet;

  /// The notice shown when the normal sound comes back by itself, in the app's language.
  void writeNotice(String title, String text);

  /// Can the filter run here at all? Null when it can, else the reason.
  Future<BackendMessage?> preflight();
  Future<BackendMessage?> installIfNeeded();
  Future<BackendMessage?> setWomenSinging(bool on);
  Future<BackendMessage?> setStereo(bool on);
  Future<BackendMessage?> setKeepSilent(bool on);

  /// A running filter takes the current settings, never with unfiltered sound in between.
  Future<BackendMessage?> reload();
  Future<BackendMessage?> start();

  /// Normal sound back.
  Future<BackendMessage?> stop();
  Future<BackendMessage?> setAutostart(bool on);
  Future<EngineStatus> status();

  /// The filter's last log lines ([lines] more for the diagnostics report).
  Future<String> journal({int lines = 6});
  String filterLogTail({int maxBytes = 3000});
}
