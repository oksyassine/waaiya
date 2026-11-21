import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_ui/src/protection_core.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// The guard on the desktop (lane B): setSetting and stopFilter pass the same rules as Android; the PIN hash and the
/// pending request survive a restart in protect.json, and a reboot never shortens the wait.
class _Clock implements ProtectionClock {
  int wall = DateTime.now().millisecondsSinceEpoch;
  int elapsed = 10000000;
  String boot = 'boot-1';
  @override
  int wallMs() => wall;
  @override
  int elapsedMs() => elapsed;
  @override
  String bootId() => boot;
  void pass(int minutes) {
    wall += minutes * 60000;
    elapsed += minutes * 60000;
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('waaiya_protect'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<DesktopBackend> open(_Clock c) => DesktopBackend.open(
      file: File('${dir.path}/settings.json'),
      licencesDir: dir,
      findEngine: false,
      findBlur: false,
      poll: null,
      protectionClock: c,
      protectionIterations: 50);

  Future<Map<String, Object?>> refused(Future<void> Function() f) async {
    try {
      await f();
    } on BackendException catch (e) {
      expect(e.code, 'protected');
      return (jsonDecode(e.message) as Map).cast<String, Object?>();
    }
    fail('not refused');
  }

  test('without protection everything applies at once', () async {
    final b = await open(_Clock());
    await b.setSetting(SettingKeys.blurWomen, true);
    await b.setSetting(SettingKeys.blurWomen, false);
    await b.startFilter();
    await b.stopFilter();
    expect(b.state.filter.running, isFalse);
    expect(b.state.feature('protect')['pinSet'], false);
  });

  test('a PIN guards Stop and weakening changes; strengthening passes', () async {
    final c = _Clock();
    final b = await open(c);
    await b.setSetting(SettingKeys.blurWomen, true);
    expect(await b.invoke('protect.setPin', {'pin': '2468'}), {'status': 'done'});
    final pinFile = File('${dir.path}/protect.json').readAsStringSync();
    expect(pinFile, isNot(contains('2468')));
    await b.startFilter();
    final d = await refused(b.stopFilter);
    expect(d['need'], 'pin');
    expect(d['what'], 'stop');
    expect(b.state.filter.running, isTrue);
    expect((await b.invoke('protect.request', {'what': 'stop', 'pin': '1111'}) as Map)['status'], 'pin_wrong');
    expect((await b.invoke('protect.request', {'what': 'stop', 'pin': '2468'}) as Map)['status'], 'done');
    expect(b.state.filter.running, isFalse);
    expect((await refused(() => b.setSetting(SettingKeys.blurWomen, false)))['need'], 'pin');
    await b.setSetting(SettingKeys.blurNudity, true); // strengthening
    await b.setSetting(SettingKeys.prayerSilent, true); // not about protection
    expect(b.state.settings.blurNudity, isTrue);
  });

  test('a waiting period survives a restart and a reboot, and needs confirming', () async {
    final c = _Clock();
    var b = await open(c);
    await b.setSetting(SettingKeys.blurWomen, true);
    await b.setSetting(SettingKeys.protectDelayMinutes, 60); // raising: at once without a PIN
    final d = await refused(() => b.setSetting(SettingKeys.blurWomen, false));
    expect(d['need'], 'wait');
    expect(d['delayMinutes'], 60);
    expect((await b.invoke('protect.request', {'what': 'blur_women', 'value': false}) as Map)['status'], 'pending');
    expect((await refused(() => b.setSetting(SettingKeys.blurWomen, false)))['need'], 'waiting');
    c.pass(20);
    await b.close();
    // the app restarts in the same boot: the request is still there, and the 20 minutes counted
    b = await open(c);
    var p = b.state.feature('protect')['pending'] as Map;
    expect(p['what'], 'blur_women');
    expect((p['dueAt'] as int) - c.wall, 40 * 60000);
    // a reboot, with the clock moved 10 hours forward: only the 5 minutes since boot count from the last saved
    // time left (60 minutes, saved at the request): the 20 minutes before were not saved, so they are lost
    c
      ..boot = 'boot-2'
      ..elapsed = 5 * 60000
      ..wall += 10 * 3600000;
    await b.close();
    b = await open(c);
    p = b.state.feature('protect')['pending'] as Map;
    expect(p['ready'], false);
    expect((p['dueAt'] as int) - c.wall, 55 * 60000);
    expect((await b.invoke('protect.confirm') as Map)['status'], 'waiting');
    c.pass(55);
    await b.close();
    b = await open(c);
    expect(b.state.settings.blurWomen, isTrue, reason: 'never applied silently');
    expect((await b.invoke('protect.confirm') as Map)['status'], 'done');
    expect(b.state.settings.blurWomen, isFalse);
    expect((jsonDecode(File('${dir.path}/settings.json').readAsStringSync()) as Map)['blur_women'], false);
  });

  test('lowering the waiting period waits the current one', () async {
    final c = _Clock();
    final b = await open(c);
    await b.setSetting(SettingKeys.protectDelayMinutes, 5);
    expect((await refused(() => b.setSetting(SettingKeys.protectDelayMinutes, 0)))['need'], 'wait');
    await b.invoke('protect.request', {'what': 'protect_delay_minutes', 'value': 0});
    c.pass(5);
    await b.invoke('protect.confirm');
    expect(b.state.settings.protectDelayMinutes, 0);
  });
}
