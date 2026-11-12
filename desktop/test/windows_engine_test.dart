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

  test('Windows build from the OS version string', () {
    expect(WindowsEngine.windowsBuild('"Windows 10 Pro" 10.0 (Build 19045)'), 19045);
    expect(WindowsEngine.windowsBuild('"Windows 10 Pro" 10.0 (Build 18363)'), 18363);
    expect(WindowsEngine.windowsBuild('Linux 6.8'), isNull);
  });
}
