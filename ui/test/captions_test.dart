// The captions card (captions.dart, docs/CAPTIONS.md): on the filter page only when the build bundles the Arabic
// speech model; its button opens the native captions screen. The card's texts fit in every language.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

AppState _state(Map<String, Object?>? captions, {String language = 'en'}) => AppState(
      platform: 'android',
      language: language,
      settings: const WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      features: {'captions': ?captions},
    );

Future<void> _open(WidgetTester tester, MemoryBackend b, {Size size = const Size(1080, 1920)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no model, or no captions at all: no card', (tester) async {
    for (final c in [<String, Object?>{'available': false, 'running': false}, null]) {
      await _open(tester, MemoryBackend(initial: _state(c)));
      expect(find.byKey(const Key('captions_card')), findsNothing);
    }
  });

  testWidgets('with the model: the card opens the captions screen', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state({'available': true, 'running': false}));
    final calls = <String>[];
    b.methods['captions.open'] = (args) async {
      calls.add('captions.open');
      return null;
    };
    await _open(tester, b);
    await tester.scrollUntilVisible(find.byKey(const Key('captions_open')), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text(l.captionsCardTitle), findsOneWidget);
    expect(find.text(l.captionsCardBody), findsOneWidget);
    await tester.tap(find.byKey(const Key('captions_open')));
    await tester.pumpAndSettle();
    expect(calls, ['captions.open']);
  });

  testWidgets('every language: the card fits on a small phone', (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final b = MemoryBackend(initial: _state({'available': true}, language: locale.toLanguageTag()));
      await _open(tester, b, size: const Size(720, 1280));
      await tester.scrollUntilVisible(find.byKey(const Key('captions_open')), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(locale);
      expect(l.captionsCardTitle.isNotEmpty && l.captionsCardBody.isNotEmpty && l.captionsCardOpen.isNotEmpty, isTrue,
          reason: locale.toString());
      expect(tester.takeException(), isNull, reason: locale.toString());
    }
  });
}
