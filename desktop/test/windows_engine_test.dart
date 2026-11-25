import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/windows_engine.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1794518754630);
  String out(String process, String state, {int age = 0, String engine = 'ok'}) =>
      'process: $process\n{"pid":1,"t":${now.millisecondsSinceEpoch - age},"state":"$state","engine":"$engine",'
      '"error":"","lowered":2,"pending":2}\n';

  test('filtering, fresh state: running', () {
    final s = WindowsEngine.parseStatus(out('running', 'filtering'), autostart: true, now: now);
    expect(s.sinkUp, isTrue);
    expect(s.active, 'active');
    expect(s.autostart, isTrue);
    expect(s.modelFailed, isFalse);
  });

  test('a state older than 5 s is not running (hung)', () {
    final s = WindowsEngine.parseStatus(out('running', 'filtering', age: 6000), autostart: false, now: now);
    expect(s.sinkUp, isFalse);
  });

  test('starting or retrying its audio: activating', () {
    expect(WindowsEngine.parseStatus(out('running', 'failing'), autostart: false, now: now).active, 'activating');
    expect(WindowsEngine.parseStatus(out('running', 'starting'), autostart: false, now: now).active, 'activating');
  });

  test('the process died while filtering: down (apps silent until Start or Stop)', () {
    final s = WindowsEngine.parseStatus(out('none', 'filtering', age: 60000), autostart: false, now: now);
    expect(s.down, isTrue);
    expect(s.active, 'failed');
    expect(s.sinkUp, isFalse);
  });

  test('levels left lowered are given back when the app opens: after a clean end, or a death with hold_silence off',
      () {
    bool r(String active, {bool stored = true, bool autostart = false, bool hold = true}) =>
        WindowsEngine.restoreAtOpen(active: active, levelsStored: stored, autostart: autostart, holdSilence: hold);
    // stopped, the session ended or an update closed it: apps not running then still hold their -80 dB
    expect(r('inactive'), isTrue);
    expect(r('inactive', stored: false), isFalse);
    // it died while filtering: silent until Start or Stop (fail-closed), unless the user chose normal sound back
    expect(r('failed'), isFalse);
    expect(r('failed', hold: false), isTrue);
    // running, or starting: never
    expect(r('active', hold: false), isFalse);
    expect(r('activating', hold: false), isFalse);
    // it starts at login: it lowers them again at once; a restorer racing it would let music through
    expect(r('inactive', autostart: true), isFalse);
    expect(r('failed', autostart: true, hold: false), isFalse);
  });

  test('giving levels back, or stopped: stopped', () {
    expect(WindowsEngine.parseStatus(out('running', 'restoring'), autostart: false, now: now).filter, 'stopped');
    expect(WindowsEngine.parseStatus(out('none', 'stopped'), autostart: false, now: now).filter, 'stopped');
    expect(WindowsEngine.parseStatus('process: none\n{}\n', autostart: false, now: now).filter, 'stopped');
    expect(WindowsEngine.parseStatus('process: none\n{"state":', autostart: false, now: now).filter, 'stopped');
  });

  test('the engine field: model failures are reported', () {
    final s = WindowsEngine.parseStatus(out('running', 'filtering', engine: 'model not loaded, no file'),
        autostart: false, now: now);
    expect(s.modelFailed, isTrue);
  });

  test('state.json alone (as the app reads it): fresh = running, stale = not', () {
    String js(String state, int age) => '{"pid":1,"t":${now.millisecondsSinceEpoch - age},"state":"$state","engine":"ok"}';
    expect(WindowsEngine.parseStatus(js('filtering', 500), autostart: false, now: now).sinkUp, isTrue);
    final stale = WindowsEngine.parseStatus(js('filtering', 9000), autostart: false, now: now);
    expect(stale.sinkUp, isFalse);
    expect(stale.down, isTrue); // stuck or gone while apps were lowered: silenced until Start or Stop
    expect(WindowsEngine.parseStatus('', autostart: false, now: now).filter, 'stopped');
  });

  test('status() reads %LOCALAPPDATA%\\Waaiya\\filter\\state.json', () async {
    final tmp = Directory.systemTemp.createTempSync('waaiya-win-');
    final dir = Directory('${tmp.path}\\Waaiya\\filter')..createSync(recursive: true);
    File('${dir.path}\\state.json').writeAsStringSync(
        '{"pid":1,"t":${DateTime.now().millisecondsSinceEpoch},"state":"filtering","engine":"ok"}');
    final e = WindowsEngine(tmp, environment: {'LOCALAPPDATA': tmp.path});
    expect(e.stateDir, '${tmp.path}\\Waaiya\\filter');
    expect((await e.status()).sinkUp, isTrue);
    tmp.deleteSync(recursive: true);
  });

  test('Store package: "Start at login" is the file the startup task looks for, not a Run value', () async {
    expect(WindowsEngine.isPackagedPath(r'C:\Program Files\WindowsApps\Oks.Waaiya_1.2.13.0_x64__wa2h0h9gfqbyp\engine'),
        isTrue);
    expect(WindowsEngine.isPackagedPath(r'C:\Users\a\Downloads\waaiya\engine'), isFalse);
    final tmp = Directory.systemTemp.createTempSync('waaiya-win-');
    final e = WindowsEngine(tmp,
        environment: {'LOCALAPPDATA': tmp.path}, packaged: true, startupTask: (_) async => 'enabled');
    final marker = File('${e.stateDir}\\autostart');
    expect(await e.setAutostart(true), isNull);
    expect(marker.existsSync(), isTrue);
    expect((await e.status()).autostart, isTrue);
    expect(await e.setAutostart(false), isNull);
    expect(marker.existsSync(), isFalse);
    expect((await e.status()).autostart, isFalse);
    expect(await e.setAutostart(false), isNull); // already off
    tmp.deleteSync(recursive: true);
  });

  test('Store package: Windows is asked to let the startup task run, and "Start at login" shows what Windows allows',
      () async {
    final tmp = Directory.systemTemp.createTempSync('waaiya-win-');
    var task = 'disabled';
    final calls = <String>[], opened = <String>[];
    final e = WindowsEngine(tmp, environment: {'LOCALAPPDATA': tmp.path}, packaged: true, startupTask: (m) async {
      calls.add(m);
      if (m == 'request' && task == 'disabled') task = 'enabled'; // the user said yes to Windows' question
      return task;
    }, openSettings: (uri) async => opened.add(uri));

    // off, never asked: Windows asks, the user agrees
    expect(await e.setAutostart(true), isNull);
    expect(calls, ['request']);
    expect((await e.status()).autostart, isTrue);

    // turned off in Settings > Apps > Startup: only that page can turn it on again; it opens
    task = 'disabledByUser';
    expect((await e.setAutostart(true))?.code, 'autostart_blocked');
    expect(opened, ['ms-settings:startupapps']);
    expect((await e.status()).autostart, isFalse); // the file is there, but Windows does not run the task

    // the user said no to Windows' question: nothing opens
    task = 'disabled';
    final e2 = WindowsEngine(tmp, environment: {'LOCALAPPDATA': tmp.path}, packaged: true,
        startupTask: (_) async => 'disabled', openSettings: (uri) async => opened.add(uri));
    expect((await e2.setAutostart(true))?.code, 'autostart_blocked');
    expect(opened, hasLength(1));

    // the administrator's policy
    final e3 = WindowsEngine(tmp,
        environment: {'LOCALAPPDATA': tmp.path}, packaged: true, startupTask: (_) async => 'disabledByPolicy');
    expect((await e3.setAutostart(true))?.code, 'autostart_policy');

    // turning it off asks nothing
    calls.clear();
    expect(await e.setAutostart(false), isNull);
    expect(calls, isEmpty);
    tmp.deleteSync(recursive: true);
  });

  test('Windows build from the OS version string', () {
    expect(WindowsEngine.windowsBuild('"Windows 10 Pro" 10.0 (Build 19045)'), 19045);
    expect(WindowsEngine.windowsBuild('"Windows 10 Pro" 10.0 (Build 18363)'), 18363);
    expect(WindowsEngine.windowsBuild('Linux 6.8'), isNull);
  });

  test("a failed start shows only the log lines written since it, never an older run's", () {
    const log = '2026-11-12 22:17:21.304 sessions: pid 12580 active\n'
        '2026-11-12 22:17:21.673 audio: playing to "Speakers"\n'
        r'2026-11-20 10:31:02.120 run: model C:\x\dfn3.onnx' '\n'
        '2026-11-20 10:31:02.300 audio: no output device';
    final since = DateTime(2026, 11, 20, 10, 31, 1);
    final d = WindowsEngine.startFailure(log, since);
    expect(d, contains('no output device'));
    expect(d, isNot(contains('2026-11-12')));
    expect(WindowsEngine.startFailure(log.split('\n').take(2).join('\n'), since), contains('did not answer'));
  });

  test('a test run is not a packaged app', () {
    expect(WindowsEngine.isPackagedProcess(), isFalse);
  });

  test("the apps with sound come from the filter's state: file name and the name Windows shows", () {
    const st = '{"pid":1,"state":"filtering","apps":[{"exe":"chrome.exe","name":"Google Chrome"},'
        '{"exe":"tone.exe"},{"name":"no file"},{"exe":""}]}';
    final a = WindowsEngine.appsFrom(st);
    expect(a.map((x) => x.exe), ['chrome.exe', 'tone.exe']);
    expect(a.first.name, 'Google Chrome');
    expect(a[1].name, 'tone.exe'); // no description: the file name
    expect(WindowsEngine.appsFrom('{"apps":"x"}'), isEmpty);
    expect(WindowsEngine.appsFrom('half {'), isEmpty);
  });

  test('the waiting period counts on the time since Windows started, which a clock change does not move', () {
    final c = WindowsTickClock();
    if (!Platform.isWindows) return;
    final a = c.elapsedMs();
    expect(a, greaterThan(0));
    sleep(const Duration(milliseconds: 50));
    expect(c.elapsedMs() - a, inInclusiveRange(40, 2000));
    expect(c.bootId(), 'windows'); // a restart shows as a lower count, never as more time
  });
}
