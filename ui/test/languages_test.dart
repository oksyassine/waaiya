import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

/// Every language on a small phone (360 x 640 dp): each page opens with no text overflowing (an overflow fails the
/// test) and in the language's direction. Long languages (French, Bengali) and right-to-left ones (Urdu, Persian)
/// are where a layout breaks first.
void main() {
  const rtl = {'ar', 'ur', 'fa'};

  test('every app language has its texts, and Flutter knows them all', () {
    final supported = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(supported, appLanguages.keys.toSet());
    expect(appLanguageOf('fr_FR.UTF-8'), 'fr');
    expect(appLanguageOf('in'), 'id');
    expect(appLanguageOf('id-ID'), 'id');
    expect(appLanguageOf('de_DE'), isNull);
    expect(appLanguageOf(null), isNull);
  });

  for (final tag in appLanguages.keys) {
    testWidgets('$tag: onboarding and the five pages fit a small phone', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // First launch.
      await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: MemoryBackend(initial: AppState(language: tag))));
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(Locale(tag));
      expect(find.text(l.onboardTitle), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(l.onboardTitle))),
          rtl.contains(tag) ? TextDirection.rtl : TextDirection.ltr);

      // A new phone that still needs the setup, filtering on: the most text on each page.
      await tester.pumpWidget(WaaiyaApp(
          key: UniqueKey(),
          backend: MemoryBackend(
              initial: AppState(
            language: tag,
            settings: const WaaiyaSettings(gender: 'man'),
            capabilities: Capabilities.android,
            filter: const FilterInfo(state: FilterState.filtering, delayMs: 40),
            setup: const SetupInfo(
              originalsMuted: false,
              consentSkipped: false,
              wireless: WirelessInfo(supported: true, devOptions: false, wifi: false, aboutHint: 'samsung'),
            ),
          ))));
      await tester.pumpAndSettle();
      for (final page in ['filter', 'screen', 'links', 'setup', 'settings']) {
        await tester.tap(find.byKey(Key('nav_$page')));
        await tester.pumpAndSettle();
        // scroll through the page so every part is laid out at least once
        final list = find.byType(Scrollable).first;
        for (var i = 0; i < 6; i++) {
          await tester.drag(list, const Offset(0, -500));
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
}
