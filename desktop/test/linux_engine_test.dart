// The Linux engine host against fake `waaiya`, `pactl`, `systemctl` and `journalctl` on PATH (no sound server is
// needed). The real audio path is checked by hand: see desktop/TESTING.md.
@TestOn('linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_desktop/linux_engine.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// Stands in for linux/bin/islamic-mute: records its calls in $FAKE/calls and keeps its state in $FAKE.
const _fakeWaaiya = r'''#!/bin/bash
LIB="$XDG_DATA_HOME/islamic-mute"
REPO="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
echo "$*" >> "$FAKE/calls"
case "$1" in
  install) [ -f "$FAKE/install_fails" ] && { echo "cp: cannot create $LIB/lib/im-stream: Text file busy" >&2; exit 1; }
           mkdir -p "$LIB"; cp "$0" "$LIB/islamic-mute"; cp "$REPO/VERSION" "$LIB/VERSION" ;;
  start) [ -f "$FAKE/start_fails" ] && { echo "Job for islamic-mute.service failed." >&2; exit 1; }
         touch "$FAKE/running" ;;
  stop) rm -f "$FAKE/running" ;;
  status) if [ -f "$FAKE/running" ]; then echo "filter:   running"
          elif [ -f "$FAKE/down" ]; then echo "filter:   down (virtual output kept: apps are silent)"
          else echo "filter:   stopped"; fi
          if [ -f "$FAKE/engine" ]; then echo "engine:   $(cat "$FAKE/engine")"; else echo "engine:   ok"; fi
          if [ -f "$FAKE/enabled" ]; then echo "autostart: on"; else echo "autostart: off"; fi ;;
  women-singing) echo "$2" > "$FAKE/women" ;;
  reload) [ -f "$FAKE/no_reload" ] && { echo "usage: islamic-mute ..." >&2; exit 1; }; true ;;
esac
''';

const _fakePactl = r'''#!/bin/bash
[ -f "$FAKE/no_server" ] && { echo "Connection failure: Connection refused" >&2; exit 1; }
case "$1 $2 $3" in
  "info  ") echo "Server Name: fake" ;;
  "list short sinks") [ -f "$FAKE/no_output" ] || printf '0\talsa_output.pci\tmodule-alsa-card.c\ts16le 2ch 48000Hz\tSUSPENDED\n'
                      [ -f "$FAKE/running" ] && printf '1\tislamic_mute\tmodule-null-sink.c\tfloat32le 2ch 48000Hz\tRUNNING\n' ;;
esac
exit 0
''';

const _fakeSystemctl = r'''#!/bin/bash
echo "$*" >> "$FAKE/systemctl"
case "$2" in
  show-environment) [ -f "$FAKE/no_systemd" ] && { echo "Failed to connect to bus" >&2; exit 1; }; echo "HOME=$HOME" ;;
  is-active) if [ -f "$FAKE/failed" ]; then echo failed; exit 3
             elif [ -f "$FAKE/activating" ]; then echo activating; exit 3
             elif [ -f "$FAKE/running" ]; then echo active
             else echo inactive; exit 3; fi ;;
  enable) touch "$FAKE/enabled" ;;
  disable) rm -f "$FAKE/enabled" ;;
esac
''';

const _fakeJournal = '#!/bin/bash\necho "islamic-mute: no real output device found"\n';

class _World {
  _World() {
    root = Directory.systemTemp.createTempSync('waaiya_engine');
    for (final d in ['bin', 'fake', 'home', 'data', 'config', 'state', 'engine/linux/bin']) {
      Directory('${root.path}/$d').createSync(recursive: true);
    }
    script('engine/linux/bin/islamic-mute', _fakeWaaiya);
    script('bin/pactl', _fakePactl);
    script('bin/systemctl', _fakeSystemctl);
    script('bin/journalctl', _fakeJournal);
    version = '0.2.6-aaaa';
  }

  late final Directory root;

  String p(String rel) => '${root.path}/$rel';

  void script(String rel, String body) {
    File(p(rel)).writeAsStringSync(body);
    Process.runSync('chmod', ['+x', p(rel)]);
  }

  set version(String v) => File(p('engine/VERSION')).writeAsStringSync('$v\n');

  void flag(String name, [bool on = true]) =>
      on ? File(p('fake/$name')).writeAsStringSync('') : File(p('fake/$name')).deleteSync();

  List<String> get calls {
    final f = File(p('fake/calls'));
    return f.existsSync() ? f.readAsLinesSync() : [];
  }

  int count(String cmd) => calls.where((c) => c.split(' ').first == cmd).length;

  Map<String, String> get env => {
        'PATH': '${p('bin')}:/usr/bin:/bin',
        'HOME': p('home'),
        'XDG_DATA_HOME': p('data'),
        'XDG_CONFIG_HOME': p('config'),
        'XDG_STATE_HOME': p('state'),
        'FAKE': p('fake'),
      };

  LinuxEngine get engine => LinuxEngine(Directory(p('engine')), environment: env);

  Future<DesktopBackend> backend({Duration timeout = DesktopBackend.defaultStartTimeout}) async {
    final b = await DesktopBackend.open(
      file: File(p('config/settings.json')),
      licencesDir: Directory(p('licences')),
      engine: engine,
      poll: null,
      startTimeout: timeout,
    );
    await b.refresh();
    return b;
  }

  void dispose() => root.deleteSync(recursive: true);
}

void main() {
  late _World w;
  setUp(() => w = _World());
  tearDown(() => w.dispose());

  test('start installs the bundled engine, then starts it; stop stops it', () async {
    final b = await w.backend();
    expect(b.state.filter.simulated, isFalse);
    expect(b.state.filter.state, FilterState.stopped);
    expect(b.state.capabilities.autostart, isTrue);
    expect(b.state.capabilities.womenSinging, isFalse, reason: 'no detector bundled');

    expect(await b.startFilter(), StartResult.started);
    expect(w.calls, ['install', 'women-singing off', 'start', 'status']);
    expect(File(w.p('data/islamic-mute/VERSION')).readAsStringSync().trim(), '0.2.6-aaaa');
    expect(b.state.filter.state, FilterState.filtering);
    expect(b.state.filter.error, isNull);
    expect(await b.startFilter(), StartResult.alreadyRunning);

    await b.stopFilter();
    expect(w.calls.last, 'status');
    expect(w.calls, contains('stop'));
    expect(b.state.filter.state, FilterState.stopped);
  });

  test('reinstalls only when the bundled version changes', () async {
    final b = await w.backend();
    await b.startFilter();
    await b.stopFilter();
    await b.startFilter();
    await b.stopFilter();
    expect(w.count('install'), 1);
    w.version = '0.2.7-bbbb';
    await b.startFilter();
    expect(w.count('install'), 2);
    expect(w.engine.installedVersion, '0.2.7-bbbb');
  });

  test('a filter already running at launch (started at login) is reported', () async {
    await w.engine.installIfNeeded();
    w.flag('running');
    w.flag('enabled');
    final b = await w.backend();
    expect(b.state.filter.state, FilterState.filtering);
    expect(b.state.filter.autostart, isTrue);
  });

  Future<BackendMessage?> startError(DesktopBackend b) async {
    expect(await b.startFilter(), StartResult.failed);
    expect(b.state.filter.state, FilterState.stopped);
    return b.state.filter.error;
  }

  test('errors: no pactl, no sound server, no systemd, no output', () async {
    final b = await w.backend();
    File(w.p('bin/pactl')).renameSync(w.p('bin/pactl.off'));
    expect((await startError(b))!.code, 'no_pactl');
    File(w.p('bin/pactl.off')).renameSync(w.p('bin/pactl'));
    w.flag('no_server');
    expect((await startError(b))!.code, 'no_sound_server');
    w.flag('no_server', false);
    w.flag('no_systemd');
    expect((await startError(b))!.code, 'no_systemd');
    w.flag('no_systemd', false);
    w.flag('no_output');
    expect((await startError(b))!.code, 'no_output');
    expect(w.count('install'), 0);
    expect(w.count('start'), 0);
    // the error stays while stopped, and goes at the next successful start
    await b.refresh();
    expect(b.state.filter.error?.code, 'no_output');
    w.flag('no_output', false);
    expect(await b.startFilter(), StartResult.started);
    expect(b.state.filter.error, isNull);
  });

  test('errors: a failed install or start carries the log lines', () async {
    final b = await w.backend();
    w.flag('install_fails');
    final e = await startError(b);
    expect(e!.code, 'install_failed');
    expect(e.detail, contains('Text file busy'));
    w.flag('install_fails', false);
    w.flag('start_fails');
    final s = await startError(b);
    expect(s!.code, 'start_failed');
    expect(s.detail, contains('islamic-mute.service failed'));
  });

  test('status: a failed service, or one that keeps restarting, is reported with its journal', () async {
    await w.engine.installIfNeeded();
    w.flag('failed');
    var b = await w.backend();
    expect(b.state.filter.state, FilterState.stopped);
    expect(b.state.filter.error?.code, 'service_failed');
    expect(b.state.filter.error?.detail, contains('no real output device'));
    w.flag('failed', false);

    w.flag('activating');
    b = await w.backend(timeout: Duration.zero);
    expect(b.state.filter.state, FilterState.starting);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.refresh();
    expect(b.state.filter.state, FilterState.starting);
    expect(b.state.filter.error?.code, 'service_failed');
  });

  test('start at login: systemctl --user enable / disable (installs first)', () async {
    final b = await w.backend();
    await b.setAutostart(true);
    expect(w.count('install'), 1);
    expect(File(w.p('fake/systemctl')).readAsStringSync(), contains('--user enable islamic-mute.service'));
    expect(b.state.filter.autostart, isTrue);
    expect(b.state.filter.running, isFalse, reason: 'enable without --now: does not start the filter');
    await b.setAutostart(false);
    expect(b.state.filter.autostart, isFalse);
  });

  test("women's singing: hidden without a detector; with one, on/off plus a restart while running", () async {
    var b = await w.backend();
    await b.setSetting(SettingKeys.muteWomenSinging, true);
    expect(w.count('women-singing'), 0, reason: 'no detector: never turned on');
    await b.startFilter();
    expect(File(w.p('fake/women')).readAsStringSync().trim(), 'off');

    Directory(w.p('engine/models/detector')).createSync(recursive: true);
    File(w.p('engine/models/detector/detector_v1.onnx')).writeAsStringSync('x');
    b = await w.backend();
    expect(b.state.capabilities.womenSinging, isTrue);
    expect(b.state.detectorModel, isTrue);
    final before = w.calls.length;
    await b.setSetting(SettingKeys.muteWomenSinging, true);
    // a reload restarts only the filter: no stop, which would move the apps to the real output (unfiltered)
    expect(w.calls.sublist(before), ['women-singing on', 'reload', 'status']);
    expect(b.state.filter.state, FilterState.filtering);

    // an engine installed before 'reload' existed: stop + start as before
    w.flag('no_reload');
    final before2 = w.calls.length;
    await b.setSetting(SettingKeys.muteWomenSinging, false);
    expect(w.calls.sublist(before2), ['women-singing off', 'reload', 'stop', 'start', 'status']);
  });

  test('running is not enough: a model that did not load is reported, a failed detector too', () async {
    await w.engine.installIfNeeded();
    w.flag('running');
    File(w.p('fake/engine')).writeAsStringSync('model not loaded, output silent: cannot load model');
    final b = await w.backend();
    expect(b.state.filter.state, FilterState.modelFailed);
    expect(b.state.filter.running, isTrue);
    File(w.p('fake/engine')).writeAsStringSync('detector not loaded, voice muted: no file');
    await b.refresh();
    expect(b.state.filter.state, FilterState.filtering);
    expect(b.state.filter.problem, isNull, reason: "women's singing is off: the detector does not matter");
    Directory(w.p('engine/models/detector')).createSync(recursive: true);
    File(w.p('engine/models/detector/detector_v1.onnx')).writeAsStringSync('x');
    final b2 = await w.backend();
    await b2.setSetting(SettingKeys.muteWomenSinging, true);
    expect(b2.state.filter.problem, FilterProblem.detectorFailed);
  });

  test('a filter that stops by itself is "stopped by the system", the user\'s stop is not', () async {
    final b = await w.backend();
    await b.startFilter();
    expect(b.state.filter.state, FilterState.filtering);
    w.flag('running', false); // the daemon died
    w.flag('down');
    await b.refresh();
    expect(b.state.filter.state, FilterState.stoppedBySystem);
    expect(b.state.filter.running, isFalse);
    w.flag('down', false);
    await b.startFilter();
    await b.stopFilter();
    expect(b.state.filter.state, FilterState.stopped);
  });

  test('diagnostics report: version, waaiya status, logs', () async {
    final b = await w.backend();
    await b.startFilter();
    final r = await b.diagnosticsReport();
    expect(r, startsWith('Waaiya 0.2.6 (linux'));
    expect(r, contains('filter:   running'));
    expect(r, contains('engine:   ok'));
    expect(r, contains('no real output device found')); // the journal
    expect(r, contains('Filter: filtering'));
  });

  test('without the engine in the bundle, start/stop stay simulated', () async {
    final b = await DesktopBackend.open(file: File(w.p('config/s.json')), findEngine: false, poll: null);
    expect(b.state.filter.simulated, isTrue);
    expect(b.state.capabilities.autostart, isFalse);
    expect(LinuxEngine.find(dir: Directory(w.p('nothing'))), isNull);
    expect(LinuxEngine.find(dir: Directory(w.p('engine'))), isNotNull);
  });
}
