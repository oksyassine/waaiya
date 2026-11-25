import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/waaiya_ui.dart';
import 'package:waaiya_ui/src/widgets.dart';

/// Remembers the settings written, and the Developer options opened, so the test can check what a tap did.
class _Recording extends MemoryBackend {
  _Recording({super.initial});
  final written = <String, Object>{};
  final opened = <String?>[];

  @override
  Future<void> setSetting(String key, Object value) async => written[key] = value;

  @override
  Future<void> openDeveloperOptions({String? highlight}) async => opened.add(highlight);
}

Future<_Recording> _open(WidgetTester tester, NotificationTextInfo nt,
    {bool running = false, bool consentSkipped = true, bool originalsMuted = true}) async {
  final backend = _Recording(
    initial: AppState(
      language: 'en',
      settings: const WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      setup: SetupInfo(notificationText: nt, consentSkipped: consentSkipped, originalsMuted: originalsMuted),
      filter: running ? const FilterInfo(state: FilterState.filtering, delayMs: 40) : const FilterInfo(),
    ),
  );
  await tester.pumpWidget(WaaiyaApp(backend: backend));
  await tester.pumpAndSettle();
  return backend;
}

Future<void> goTo(WidgetTester tester, String page) async {
  await tester.tap(find.byKey(Key('nav_$page')));
  await tester.pumpAndSettle();
}

Finder _switch() => find.descendant(of: find.byKey(const Key('notification_text')), matching: find.byType(Switch));

void main() {
  testWidgets('before Android 15 there is no notification-text switch', (tester) async {
    await _open(tester, const NotificationTextInfo());
    expect(find.text('Show notification text while filtering'), findsNothing);
  });

  testWidgets('with the setup: a plain switch, saved as show_notification_text', (tester) async {
    final backend = await _open(tester, const NotificationTextInfo(supported: true, canWrite: true));
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    expect(tester.widget<Switch>(_switch()).value, isFalse);
    expect(find.text('Open Developer options'), findsNothing);
    await tester.pumpAndSettle();
    await tester.tap(_switch());
    await tester.pumpAndSettle();
    expect(backend.written, {'show_notification_text': true});
    expect(backend.opened, isEmpty);
  });

  testWidgets('without the setup: the setup first, Developer options only as an option', (tester) async {
    final backend = await _open(tester, const NotificationTextInfo(supported: true));
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(_switch()).value, isFalse);
    expect(find.textContaining('After the one-time setup'), findsOneWidget);
    expect(find.textContaining('Optional, without the setup'), findsOneWidget);
    await tester.tap(_switch()); // the switch leads to the setup, not to a hidden setting
    await tester.pumpAndSettle();
    expect(backend.written, isEmpty);
    expect(backend.opened, isEmpty);
    expect(find.byKey(const Key('notification_text')), findsNothing); // the Setup page is in front now
    await goTo(tester, 'filter');
    await tester.ensureVisible(find.text('Open Developer options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Developer options'));
    await tester.pumpAndSettle();
    expect(backend.opened, ['screen_share']);
  });

  testWidgets('setup done but Android asks before each start: kept on, the switch cannot turn it off', (tester) async {
    final backend = await _open(
        tester, const NotificationTextInfo(supported: true, canWrite: true, forcedForLock: true),
        consentSkipped: false);
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    await tester.pumpAndSettle();
    final sw = tester.widget<Switch>(_switch());
    expect(sw.value, isTrue);
    expect(sw.onChanged, isNull);
    expect(find.textContaining('would then stop filtering at every screen lock'), findsOneWidget);
    expect(find.text('Open Developer options'), findsNothing);
    expect(backend.written, isEmpty);
  });

  testWidgets('Android\'s switch turned on by hand shows as on, with what it means', (tester) async {
    await _open(tester, const NotificationTextInfo(supported: true, protectionOff: true));
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    expect(tester.widget<Switch>(_switch()).value, isTrue);
    expect(find.textContaining('It stays off for every screen share'), findsOneWidget);
  });

  testWidgets('turned on while filtering: says it applies at the next start', (tester) async {
    await _open(tester, const NotificationTextInfo(supported: true, canWrite: true, wanted: true, shownNow: false),
        running: true);
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    expect(tester.widget<Switch>(_switch()).value, isTrue);
    expect(find.textContaining('Stop and start filtering again'), findsOneWidget);
  });

  testWidgets('Android asks at each start: the switch also says filtering ends at screen lock', (tester) async {
    await _open(tester, const NotificationTextInfo(supported: true), consentSkipped: false);
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    expect(find.textContaining('stops filtering when the screen locks'), findsOneWidget);
  });

  testWidgets('no lock note once Android\'s protection is off', (tester) async {
    await _open(tester, const NotificationTextInfo(supported: true, protectionOff: true), consentSkipped: false);
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    expect(find.textContaining('stops filtering when the screen locks'), findsNothing);
  });

  testWidgets('Android 16 without the setup: share only Waaiya, and pairing is advised', (tester) async {
    // simple mode: the originals are muted, but the pairing is still advised
    await _open(tester, const NotificationTextInfo(supported: true, oneAppOffered: true, pairAdvised: true),
        consentSkipped: false, originalsMuted: true);
    expect(find.byKey(const Key('one_app_notice')), findsOneWidget);
    expect(find.textContaining('asks what to share'), findsOneWidget);
    expect(find.textContaining('pair it once with Wireless debugging'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is TestId && w.id == 'one_app_setup'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('notification_text')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Shown when you choose “Share one app”'), findsOneWidget);
    expect(find.text('Open Developer options'), findsNothing); // no hidden setting offered on this route
  });

  testWidgets('no one-app notice where Android does not offer it', (tester) async {
    await _open(tester, const NotificationTextInfo(supported: true), consentSkipped: false);
    expect(find.byKey(const Key('one_app_notice')), findsNothing);
  });

  testWidgets('paired but Android still asks (phone refused the grant): no pairing advice', (tester) async {
    await _open(tester, const NotificationTextInfo(supported: true, oneAppOffered: true), consentSkipped: false);
    expect(find.byKey(const Key('one_app_notice')), findsOneWidget);
    expect(find.textContaining('pair it once with Wireless debugging'), findsNothing);
    expect(find.byWidgetPredicate((w) => w is TestId && w.id == 'one_app_setup'), findsNothing);
  });
}
