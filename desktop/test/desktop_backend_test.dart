import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_desktop/version.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('waaiya_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a release build without its filter says so and never shows filtering on (Linux and Windows)', () async {
    for (final platform in ['windows', 'linux']) {
      final b = await DesktopBackend.open(
          file: File('${dir.path}/$platform.json'),
          licencesDir: dir,
          findEngine: false,
          findBlur: false,
          platform: platform,
          poll: null,
          simulateWithoutEngine: false);
      expect(b.state.filter.simulated, isFalse, reason: platform);
      expect(b.state.filter.error?.code, 'start_failed', reason: platform);
      expect(b.state.filter.error?.detail, contains('missing'), reason: platform);
      expect(await b.startFilter(), StartResult.failed, reason: platform);
      expect(b.state.filter.state, FilterState.stopped, reason: platform);
      expect(b.state.filter.running, isFalse, reason: platform);
      expect(b.state.filter.error?.code, 'start_failed', reason: platform);
    }
    // a development run (debug, as tests run): the simulated preview
    final dev = await DesktopBackend.open(
        file: File('${dir.path}/dev.json'), licencesDir: dir, findEngine: false, findBlur: false, platform: 'windows', poll: null);
    expect(dev.state.filter.simulated, isTrue);
    expect(dev.state.filter.error, isNull);
    expect(await dev.startFilter(), StartResult.started);
  });

  test('settings and language are kept in a JSON file with the Android keys', () async {
    final file = File('${dir.path}/settings.json');
    // first run: the computer's language when Waaiya has it, else Arabic
    final fresh = File('${dir.path}/fresh.json');
    var b = await DesktopBackend.open(
        file: fresh, licencesDir: dir, findEngine: false, findBlur: false, systemLocale: 'fr_FR.UTF-8');
    expect(b.state.language, 'fr');
    b = await DesktopBackend.open(file: file, licencesDir: dir, findEngine: false, findBlur: false, systemLocale: 'zh_CN');
    expect(b.state.language, 'ar');
    expect(b.state.filter.simulated, isTrue);
    expect(b.state.capabilities.shizukuSetup, isFalse);

    await b.setSetting(SettingKeys.gender, 'man');
    await b.setSetting(SettingKeys.silenceUnfilterable, false);
    await b.setLanguage('en');
    await b.setSetting(SettingKeys.blurStrictness, 1);
    final json = jsonDecode(file.readAsStringSync()) as Map;
    expect(json['gender'], 'man');
    expect(json['silence_unfilterable'], false);
    expect(json['lang'], 'en');
    expect(json['blur_strictness'], 1);

    b = await DesktopBackend.open(file: file, licencesDir: dir, findEngine: false, findBlur: false);
    expect(b.state.settings.gender, 'man');
    expect(b.state.settings.silenceUnfilterable, isFalse);
    expect(b.state.language, 'en');
    expect(b.state.settings.blurStrictness, 1);
    await expectLater(b.runSetupStep(0), throwsA(isA<BackendException>()));
  });

  test('the version shown is the build\'s (pubspec), not a constant left behind', () async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(r'^version: *([0-9.]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, v);
    final b = await DesktopBackend.open(
        file: File('${dir.path}/s.json'), licencesDir: dir, findEngine: false, findBlur: false, poll: null);
    expect(b.state.version, appVersion);
  });

  test('licence texts come from the folder next to the app', () async {
    File('${dir.path}/NOTICE.txt').writeAsStringSync('Waaiya NOTICE');
    final b = await DesktopBackend.open(file: File('${dir.path}/s.json'), licencesDir: dir, findEngine: false, findBlur: false);
    expect((await b.getLicences()).notice, 'Waaiya NOTICE');
    expect(await b.getLicenceText('THIRD_PARTY_LICENSES.txt'), contains('github.com'));
    await expectLater(b.getLicenceText('../secret'), throwsA(isA<BackendException>()));
  });

  testWidgets('desktop app starts in Arabic with the preview note', (tester) async {
    final b = await tester.runAsync(() => DesktopBackend.open(
          file: File('${dir.path}/w.json')..writeAsStringSync('{"gender":"woman"}'),
          licencesDir: dir,
          findEngine: false,
          findBlur: false,
        ));
    await tester.pumpWidget(WaaiyaApp(backend: b!));
    await tester.pumpAndSettle();
    expect(find.text('التصفية متوقفة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('التصفية متوقفة'))), TextDirection.rtl);
    expect(find.textContaining('معاينة'), findsOneWidget);
    expect(find.text('ما الذي يُموَّه'), findsNothing);
    // no blur here (a development run): "who is left uncovered" is not shown anywhere
    expect(find.byKey(const Key('blur_strict')), findsNothing);
  });
}
