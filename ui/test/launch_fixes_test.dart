import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// Counts the openings of Waaiya's page in Android's settings.
class _Recording extends MemoryBackend {
  _Recording({super.initial});
  int appSettings = 0;
  final written = <String, Object>{};

  @override
  Future<void> setSetting(String key, Object value) async {
    written[key] = value;
    if (key != 'keep_at_lock') await super.setSetting(key, value);
  }

  @override
  Future<void> openAppSettings() async => appSettings++;
}

const _play = Capabilities(shizukuSetup: true, adbSetup: true, captureConsent: true, screenBlur: true, womenSinging: true);

Future<_Recording> _open(WidgetTester tester, AppState state) async {
  final backend = _Recording(initial: state);
  await tester.pumpWidget(WaaiyaApp(backend: backend));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('microphone refused: a button opens Waaiya\'s page in Android\'s settings', (tester) async {
    final b = await _open(
        tester,
        const AppState(
          language: 'en',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities.android,
          setup: SetupInfo(originalsMuted: true, consentSkipped: true),
          filter: FilterInfo(micDenied: true),
        ));
    expect(find.textContaining('needs the microphone permission'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mic_settings')));
    await tester.pumpAndSettle();
    expect(b.appSettings, 1);
  });

  testWidgets('no button while the microphone is allowed', (tester) async {
    await _open(
        tester,
        const AppState(
          language: 'en',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities.android,
          setup: SetupInfo(originalsMuted: true, consentSkipped: true),
        ));
    expect(find.byKey(const Key('mic_settings')), findsNothing);
  });

  testWidgets('a build without links (Play) does not offer "Open a link" when the setup is missing', (tester) async {
    await _open(
        tester,
        const AppState(
          language: 'en',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: _play,
          setup: SetupInfo(originalsMuted: false, shizuku: ShizukuState.notInstalled),
        ));
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.text('The music will still be heard'), findsOneWidget);
    expect(find.textContaining('Open a link'), findsNothing);
  });

  testWidgets('with links the same question still mentions "Open a link"', (tester) async {
    await _open(
        tester,
        const AppState(
          language: 'en',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities.android,
          setup: SetupInfo(originalsMuted: false, shizuku: ShizukuState.notInstalled),
        ));
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.textContaining('"Open a link" works without any setup'), findsOneWidget);
  });

  testWidgets('battery restricted after the setup: a card asks to lift it and opens Waaiya\'s settings', (tester) async {
    final b = await _open(
        tester,
        const AppState(
          language: 'en',
          platform: 'android',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities.android,
          setup: SetupInfo(originalsMuted: true, consentSkipped: true, batteryRestricted: true, notificationsOff: true),
        ));
    await tester.ensureVisible(find.byKey(const Key('keep_running')));
    expect(find.textContaining('Unrestricted'), findsOneWidget);
    expect(find.textContaining('notifications are off'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('keep_running_open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('keep_running_open')));
    await tester.pumpAndSettle();
    expect(b.appSettings, 1);
  });

  testWidgets('no card when nothing restricts Waaiya, or before the setup', (tester) async {
    await _open(
        tester,
        const AppState(
          language: 'en',
          platform: 'android',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities.android,
          setup: SetupInfo(originalsMuted: true, consentSkipped: true),
        ));
    expect(find.byKey(const Key('keep_running')), findsNothing);
  });

  group('screen lock on a phone where Android asks before each start', () {
    AppState state(int keep) => AppState(
          language: 'en',
          platform: 'android',
          settings: const WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities.android,
          setup: SetupInfo(
              originalsMuted: true,
              consentSkipped: false,
              notificationText: NotificationTextInfo(supported: true, canWrite: true, lockApplies: true, keepAtLock: keep)),
        );

    testWidgets('not answered yet: Start asks first, and the answer is saved before starting', (tester) async {
      final b = await _open(tester, state(-1));
      await tester.tap(find.byKey(const Key('power')));
      await tester.pumpAndSettle();
      expect(find.text('Keep filtering when the screen locks?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lock_yes')));
      await tester.pumpAndSettle();
      expect(b.written['keep_at_lock'], 1);
      expect(b.state.filter.running, isTrue);
    });

    testWidgets('"Stop at each lock" is saved as 0 and filtering still starts', (tester) async {
      final b = await _open(tester, state(-1));
      await tester.tap(find.byKey(const Key('power')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lock_no')));
      await tester.pumpAndSettle();
      expect(b.written['keep_at_lock'], 0);
    });

    testWidgets('answered: no question, and a switch to change it', (tester) async {
      await _open(tester, state(0));
      expect(find.text('Keep filtering when the screen locks'), findsOneWidget);
      await tester.tap(find.byKey(const Key('power')));
      await tester.pumpAndSettle();
      expect(find.text('Keep filtering when the screen locks?'), findsNothing);
    });
  });
}
