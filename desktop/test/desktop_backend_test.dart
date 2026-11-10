import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('waaiya_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('settings and language are kept in a JSON file with the Android keys', () async {
    final file = File('${dir.path}/settings.json');
    var b = await DesktopBackend.open(file: file, licencesDir: dir);
    expect(b.state.language, 'ar');
    expect(b.state.filter.simulated, isTrue);
    expect(b.state.capabilities.shizukuSetup, isFalse);

    await b.setSetting(SettingKeys.gender, 'man');
    await b.setSetting(SettingKeys.silenceUnfilterable, false);
    await b.setLanguage('en');
    final json = jsonDecode(file.readAsStringSync()) as Map;
    expect(json['gender'], 'man');
    expect(json['silence_unfilterable'], false);
    expect(json['lang'], 'en');

    b = await DesktopBackend.open(file: file, licencesDir: dir);
    expect(b.state.settings.gender, 'man');
    expect(b.state.settings.silenceUnfilterable, isFalse);
    expect(b.state.language, 'en');
    await expectLater(b.runSetupStep(0), throwsA(isA<BackendException>()));
  });

  test('licence texts come from the folder next to the app', () async {
    File('${dir.path}/NOTICE.txt').writeAsStringSync('Waaiya NOTICE');
    final b = await DesktopBackend.open(file: File('${dir.path}/s.json'), licencesDir: dir);
    expect((await b.getLicences()).notice, 'Waaiya NOTICE');
    expect(await b.getLicenceText('THIRD_PARTY_LICENSES.txt'), contains('github.com'));
    await expectLater(b.getLicenceText('../secret'), throwsA(isA<BackendException>()));
  });

  testWidgets('desktop app starts in Arabic with the preview note', (tester) async {
    final b = await tester.runAsync(() => DesktopBackend.open(
          file: File('${dir.path}/w.json')..writeAsStringSync('{"gender":"woman"}'),
          licencesDir: dir,
        ));
    await tester.pumpWidget(WaaiyaApp(backend: b!));
    await tester.pumpAndSettle();
    expect(find.text('التصفية متوقفة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('التصفية متوقفة'))), TextDirection.rtl);
    expect(find.textContaining('معاينة'), findsOneWidget);
    expect(find.text('تمويه الشاشة'), findsNothing);
  });
}
