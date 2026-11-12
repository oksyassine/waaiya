import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_desktop/linux_blur.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// A stand-in for engine/build/im-blur: records its arguments, environment and stdin commands, prints the state
/// lines it is told to (FAKE_STATE / FAKE_ERROR), quits on "quit" or end of input; FAKE_CRASH=1 dies at once.
const fakeHelper = r'''#!/bin/bash
echo "$*" > "$LOG.args"
echo $$ >> "$LOG.pids"
/usr/bin/env > "$LOG.env"
echo '{"state":"starting","error":"","backend":"x11","overlay":"x11","covers":0}'
if [ "$FAKE_CRASH" = 1 ]; then echo "segfault in a driver" >&2; exit 3; fi
if [ "$FAKE_HANG" = 1 ]; then exec sleep 30; fi
echo "{\"state\":\"${FAKE_STATE:-on_covers_visible}\",\"error\":\"${FAKE_ERROR:-}\",\"backend\":\"x11\",\"overlay\":\"x11\",\"covers\":1,\"ms\":40.5,\"cpu\":12.0,\"fps\":5.0}"
echo 'not json'
if [ "$FAKE_CRASH_LATER" = 1 ]; then sleep 0.1; exit 3; fi
if [ -n "$FAKE_THEN" ]; then sleep 0.2; echo "{\"state\":\"$FAKE_THEN\",\"error\":\"sharing stopped\",\"covers\":0}"; fi
while read -r line; do
  echo "$line" >> "$LOG.cmds"
  [ "$line" = quit ] && exit 0
done
exit 0
''';

void main() {
  late Directory dir;
  late Directory engine;
  late String log;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('waaiya_blur');
    engine = Directory('${dir.path}/engine')..createSync();
    Directory('${engine.path}/build').createSync();
    Directory('${engine.path}/models/vision').createSync(recursive: true);
    final exe = File('${engine.path}/build/im-blur')..writeAsStringSync(fakeHelper);
    Process.runSync('chmod', ['+x', exe.path]);
    for (final m in ['person_yolox_nano.onnx', 'gender_v2.onnx', 'nsfw_marqo_int8.onnx']) {
      File('${engine.path}/models/vision/$m').writeAsStringSync('x');
    }
    log = '${dir.path}/helper';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, String> env([Map<String, String> extra = const {}]) => {
    'LOG': log,
    'DISPLAY': ':42',
    'WAYLAND_DISPLAY': 'wayland-1',
    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=/run/user/1000/bus',
    'XDG_RUNTIME_DIR': '/run/user/1000',
    ...extra,
  };

  LinuxBlur helper([Map<String, String> extra = const {}]) =>
      LinuxBlur.find(engineDir: engine, environment: env(extra), tokenFile: File('${dir.path}/token'))!;

  Future<List<String>> cmds() async {
    final f = File('$log.cmds');
    for (var i = 0; i < 50 && !f.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return f.existsSync() ? f.readAsLinesSync() : [];
  }

  Future<List<String>> cmdsAtLeast(int n) async {
    var c = await cmds();
    for (var i = 0; i < 500 && c.length < n; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      c = await cmds();
    }
    return c;
  }

  Future<T> until<T>(T Function() read, bool Function(T) ok) async {
    for (var i = 0; i < 500; i++) {
      final v = read();
      if (ok(v)) return v;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return read();
  }

  test('state lines from the helper', () {
    final r = BlurReport.parse(
      '{"state":"no_overlay","error":"GNOME: no layer-shell","backend":"wayland",'
      '"overlay":"","covers":0,"ms":12.5,"cpu":3.0}',
    )!;
    expect(r.blurState, BlurState.noOverlay);
    expect(r.blurError!.code, 'no_overlay');
    expect(r.blurError!.detail, 'GNOME: no layer-shell');
    expect(r.ms, 12.5);
    expect(r.backend, 'wayland');
    expect(BlurReport.parse('{"state":"on_covers_visible","error":""}')!.blurState, BlurState.onCoversVisible);
    expect(BlurReport.parse('{"state":"on_covers_visible","error":""}')!.blurError, isNull);
    expect(BlurReport.parse('{"state":"no_capture","error":"refused"}')!.blurState, BlurState.noCapture);
    expect(BlurReport.parse('{"state":"starting","error":"share_dialog"}')!.blurError!.code, 'share_dialog');
    expect(BlurReport.parse('{"state":"idle","error":""}')!.blurState, isNull);
    expect(BlurReport.parse('not json'), isNull);
    expect(BlurReport.parse('{"covers":1}'), isNull);
    expect(const BlurConfig(women: true, nudity: true, strictness: 0, failCover: true).policy, 3);
    expect(const BlurConfig(women: false, nudity: true, strictness: 0, failCover: true).policy, 2);
    expect(const BlurConfig(women: false, nudity: false, strictness: 0, failCover: true).on, isFalse);
  });

  test('found with the helper; a missing model keeps the blur (the helper says models_missing), not hidden', () {
    expect(LinuxBlur.find(engineDir: engine)!.missingModels, isEmpty);
    File('${engine.path}/models/vision/gender_v2.onnx').deleteSync();
    expect(LinuxBlur.find(engineDir: engine)!.missingModels, ['gender_v2.onnx']);
    expect(LinuxBlur.find(engineDir: Directory('${dir.path}/nowhere')), isNull);
    expect(BlurReport.parse('{"state":"on","error":"","uncovered":2}')!.uncovered, 2);
    expect(BlurReport.parse('{"state":"on","error":""}')!.uncovered, 0);
  });

  LinuxBlur quick(Map<String, String> extra) => LinuxBlur(
        File('${engine.path}/build/im-blur'),
        Directory('${engine.path}/models/vision'),
        environment: env(extra),
        restartDelay: const Duration(milliseconds: 50),
        silenceTimeout: const Duration(milliseconds: 600),
      );
  const cfgOn = BlurConfig(women: true, nudity: false, strictness: 0, failCover: true);

  test('a helper that says nothing for a while is reported failing and restarted', () async {
    final b = quick({'FAKE_HANG': '1'});
    final seen = <BlurReport?>[];
    b.reports.listen(seen.add);
    await b.apply(cfgOn);
    await until(() => seen, (s) => s.any((r) => r?.state == 'failing'));
    expect(seen.firstWhere((r) => r?.state == 'failing')!.error, contains('has not answered'));
    await until(() => File('$log.pids').readAsLinesSync().length, (n) => n >= 2);
    await b.dispose();
  });

  test('the capture ended while on: the helper is started again', () async {
    final b = quick({'FAKE_THEN': 'no_capture'});
    await b.apply(cfgOn);
    await until(() => File('$log.pids').existsSync() ? File('$log.pids').readAsLinesSync().length : 0, (n) => n >= 2);
    await b.dispose();
  });

  test('a helper that crashes soon after every "on" is not restarted for ever', () async {
    final b = quick({'FAKE_CRASH_LATER': '1'});
    final seen = <BlurReport?>[];
    b.reports.listen(seen.add);
    await b.apply(cfgOn);
    await until(() => seen.where((r) => r == null).length, (n) => n >= LinuxBlur.maxRestarts + 1);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(File('$log.pids').readAsLinesSync().length, LinuxBlur.maxRestarts + 1);
    await b.dispose();
  });

  test('started with the settings and the session environment; changes go to stdin live; off stops it', () async {
    final b = helper();
    final seen = <BlurReport?>[];
    b.reports.listen(seen.add);
    await b.apply(const BlurConfig(women: true, nudity: false, strictness: 1, failCover: false));
    await until(() => seen, (s) => s.any((r) => r?.state == 'on_covers_visible'));
    expect(seen.last!.blurState, BlurState.onCoversVisible);
    final args = File('$log.args').readAsStringSync();
    expect(args, contains('--policy 1'));
    expect(args, contains('--strictness 1'));
    expect(args, contains('--fail-cover 0'));
    expect(args, contains('--models ${engine.path}/models/vision'));
    expect(args, contains('--token-file ${dir.path}/token'));
    final e = File('$log.env').readAsStringSync();
    for (final k in ['DISPLAY=:42', 'WAYLAND_DISPLAY=wayland-1', 'DBUS_SESSION_BUS_ADDRESS=', 'XDG_RUNTIME_DIR=']) {
      expect(e, contains(k));
    }

    await b.apply(const BlurConfig(women: true, nudity: true, strictness: 2, failCover: true));
    expect(await cmdsAtLeast(3), ['policy 3', 'strictness 2', 'fail_cover 1']);
    await b.apply(const BlurConfig(women: true, nudity: true, strictness: 2, failCover: true)); // no change
    await b.apply(const BlurConfig(women: false, nudity: false, strictness: 2, failCover: true));
    expect(b.running, isFalse);
    expect((await cmds()).last, 'quit');
    expect(seen.last, isNull);
    expect(b.exitDetail, isNull);
    await b.dispose();
  });

  test('a helper that dies is reported with its last words and restarted', () async {
    final b = LinuxBlur(
      File('${engine.path}/build/im-blur'),
      Directory('${engine.path}/models/vision'),
      environment: env({'FAKE_CRASH': '1'}),
      restartDelay: const Duration(milliseconds: 50),
    );
    final seen = <BlurReport?>[];
    b.reports.listen(seen.add);
    await b.apply(const BlurConfig(women: true, nudity: false, strictness: 0, failCover: true));
    await until(() => seen.where((r) => r == null).length, (n) => n >= LinuxBlur.maxRestarts + 1);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      seen.where((r) => r == null).length,
      LinuxBlur.maxRestarts + 1,
    ); // first run + 3 restarts, then it stays down
    expect(b.exitDetail, contains('exit code 3'));
    expect(b.exitDetail, contains('segfault in a driver'));
    await b.dispose();
  });

  bool alive(String pid) => Process.runSync('kill', ['-0', pid]).exitCode == 0;

  test('quick toggles never leave two helpers; a helper that gave up starts again on a change', () async {
    final b = helper({'FAKE_STATE': 'no_capture', 'FAKE_ERROR': 'dialog cancelled'});
    const on = BlurConfig(women: true, nudity: false, strictness: 0, failCover: true);
    const off = BlurConfig(women: false, nudity: false, strictness: 0, failCover: true);
    // not awaited, as fast clicks
    unawaited(b.apply(on));
    unawaited(b.apply(off));
    unawaited(b.apply(on));
    unawaited(b.apply(off));
    await b.apply(on);
    await until(() => b.last?.state, (s) => s == 'no_capture');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final pids = File('$log.pids').readAsLinesSync();
    expect(pids.where(alive).length, 1, reason: 'started ${pids.length}, all but the last stopped');
    // parked in no_capture: a change (strictness) starts it again
    await b.apply(const BlurConfig(women: true, nudity: false, strictness: 1, failCover: true));
    await until(() => File('$log.pids').readAsLinesSync().length, (n) => n == pids.length + 1);
    final now = File('$log.pids').readAsLinesSync();
    expect(now.length, pids.length + 1);
    expect(now.where(alive).length, 1);
    expect(File('$log.args').readAsStringSync(), contains('--strictness 1'));
    await b.dispose();
    expect(now.where(alive), isEmpty);
  });

  Future<DesktopBackend> backend(WidgetTester tester, String platform, {Map<String, String> extra = const {}}) async {
    final file = File('${dir.path}/settings.json')..writeAsStringSync('{"gender":"man","blur_women":true,"lang":"ar"}');
    return (await tester.runAsync(
      () => DesktopBackend.open(
        file: file,
        licencesDir: dir,
        findEngine: false,
        blur: helper(extra),
        findBlur: false,
        platform: platform,
        poll: null,
      ),
    ))!;
  }

  testWidgets('Linux: blur card with "who is left uncovered"; not in the settings card; status from the helper', (
    tester,
  ) async {
    final b = await backend(tester, 'linux', extra: {'FAKE_STATE': 'no_overlay', 'FAKE_ERROR': 'no layer-shell'});
    expect(b.state.capabilities.screenBlur, isTrue);
    expect(b.state.capabilities.blurStandalone, isTrue);
    await tester.runAsync(() => until(() => b.state.blur.state, (s) => s == BlurState.noOverlay));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    expect(find.text('تمويه الشاشة'), findsOneWidget); // the blur card
    final card = find.ancestor(of: find.text('تمويه الشاشة'), matching: find.byType(Card));
    final row = find.byKey(const Key('blur_strict'));
    expect(row, findsOneWidget);
    expect(find.descendant(of: card, matching: row), findsOneWidget);
    final settings = find.ancestor(of: find.text('الإعدادات'), matching: find.byType(Card));
    expect(find.descendant(of: settings, matching: row), findsNothing);
    // filtering is off, yet the blur reports: it runs on its own on desktop
    expect(b.state.filter.running, isFalse);
    final status = find.byKey(const Key('blur_status'));
    await tester.ensureVisible(status);
    expect(find.descendant(of: status, matching: find.textContaining('no layer-shell')), findsOneWidget);
    expect(find.descendant(of: status, matching: find.textContaining('لا يستطيع التمويه الرسم')), findsOneWidget);
    // no Android-only setup in the card
    expect(find.byKey(const Key('blur_fail_fix')), findsNothing);
    expect(find.textContaining('Shizuku'), findsNothing);
    await tester.runAsync(() => b.close());
  });

  testWidgets('Linux: turning the blur options off stops the helper', (tester) async {
    final b = await backend(tester, 'linux');
    await tester.runAsync(() => until(() => b.state.blur.state, (s) => s == BlurState.onCoversVisible));
    expect(b.blur!.running, isTrue);
    await tester.runAsync(() => b.setSetting(SettingKeys.blurStrictness, 2));
    await tester.runAsync(() => b.setSetting(SettingKeys.blurWomen, false));
    expect(b.blur!.running, isFalse);
    expect(b.state.blur.state, isNull);
    expect(await tester.runAsync(cmds), ['strictness 2', 'quit']);
    await tester.runAsync(() => b.close());
  });

  testWidgets('Windows: the same blur card, driven by waaiya-blur.exe through the same helper protocol', (tester) async {
    final b = await backend(tester, 'windows', extra: {'FAKE_STATE': 'on'});
    expect(b.state.capabilities.screenBlur, isTrue);
    expect(b.state.capabilities.blurStandalone, isTrue);
    await tester.runAsync(() => until(() => b.state.blur.state, (s) => s == BlurState.on));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    expect(find.text('تمويه الشاشة'), findsOneWidget);
    await tester.runAsync(() => b.close());
  });

  testWidgets('macOS: no blur, and no "who is left uncovered" anywhere', (tester) async {
    final b = await backend(tester, 'macos');
    expect(b.state.capabilities.screenBlur, isFalse);
    expect(b.blur, isNull);
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    expect(find.text('تمويه الشاشة'), findsNothing);
    await tester.scrollUntilVisible(find.text('الإعدادات'), 200);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blur_strict')), findsNothing);
    expect(find.textContaining('مَن يبقى دون تغطية'), findsNothing);
    expect(File('$log.args').existsSync(), isFalse); // never started
    await tester.runAsync(() => b.close());
  });
}
