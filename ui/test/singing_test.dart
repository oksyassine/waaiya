import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';
import 'package:waaiya_ui/src/singing_option.dart';

/// Keep singing (lane D): `SingingOptionSwitch`, setting `keep_singing`, snapshot `features.singing`.
void main() {
  AppState state({required bool available, bool on = false, String language = 'en'}) => AppState(
        language: language,
        settings: WaaiyaSettings(gender: 'man', keepSinging: on),
        features: {
          'singing': {'available': available, 'active': false},
        },
      );

  Future<MemoryBackend> pump(WidgetTester tester, AppState s) async {
    final b = MemoryBackend(initial: s);
    await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
    await tester.pumpAndSettle();
    return b;
  }

  testWidgets('hidden when the model is not in this build', (tester) async {
    await pump(tester, state(available: false));
    expect(find.byKey(const Key('keep_singing')), findsNothing);
    // no snapshot section at all (an older backend): hidden too
    await pump(tester, const AppState(settings: WaaiyaSettings(gender: 'woman')));
    expect(find.byKey(const Key('keep_singing')), findsNothing);
  });

  testWidgets('not offered for now, even with the model: hidden on every platform', (tester) async {
    expect(SingingOptionSwitch.offered, isFalse);
    expect(WaaiyaSettings.fromMap(SettingKeys.defaults).keepSinging, isFalse);
    await pump(tester, state(available: true));
    expect(find.byKey(const Key('keep_singing')), findsNothing);
  });

  testWidgets('still on from before: shown, so it can be turned off, then gone', (tester) async {
    final b = await pump(tester, state(available: true, on: true));
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final sw = find.byKey(const Key('keep_singing'));
    await tester.ensureVisible(sw);
    await tester.pumpAndSettle();
    expect(find.text(l.singingKeepTitle), findsOneWidget);
    expect(find.text(l.singingKeepBody), findsOneWidget);
    expect(l.singingKeepTitle, contains('(test)'));
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(b.state.settings.keepSinging, isFalse);
    expect(b.state.settings.toMap()[SettingKeys.keepSinging], isFalse);
    expect(find.byKey(const Key('keep_singing')), findsNothing);
  });

  testWidgets('on without the model: shown with a warning, so it can be turned off', (tester) async {
    final b = await pump(tester, state(available: false, on: true));
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final sw = find.byKey(const Key('keep_singing'));
    await tester.ensureVisible(sw);
    await tester.pumpAndSettle();
    expect(find.text(l.singingKeepNoModel), findsOneWidget);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(b.state.settings.keepSinging, isFalse);
    expect(find.byKey(const Key('keep_singing')), findsNothing);
  });

  testWidgets('Arabic text', (tester) async {
    await pump(tester, state(available: true, on: true, language: 'ar'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.ensureVisible(find.byKey(const Key('keep_singing')));
    await tester.pumpAndSettle();
    expect(find.text(ar.singingKeepTitle), findsOneWidget);
    expect(find.text(ar.singingKeepBody), findsOneWidget);
  });

  test('snapshot section round trip', () {
    final s = AppState.fromMap({
      'features': {
        'singing': {'available': true, 'active': true},
      },
    });
    expect(s.feature('singing')['available'], isTrue);
    expect(s.feature('singing')['active'], isTrue);
    expect(const AppState().feature('singing'), isEmpty);
  });
}
