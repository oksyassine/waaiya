import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';
import 'package:waaiya_ui/src/wireless_setup.dart';

class _Recording extends MemoryBackend {
  _Recording(AppState s) : super(initial: s);
  final calls = <String>[];

  @override
  Future<void> pageShown() async => calls.add('pageShown');

  @override
  Future<String> wirelessStart() async {
    calls.add('wirelessStart');
    return 'started';
  }
}

Future<void> goTo(WidgetTester tester, String page) async {
  await tester.tap(find.byKey(Key('nav_$page')));
  await tester.pumpAndSettle();
}

List<String> navKeys(WidgetTester tester) => [
      for (final p in ['filter', 'screen', 'links', 'setup', 'settings'])
        if (find.byKey(Key('nav_$p')).evaluate().isNotEmpty) p,
    ];

void main() {
  testWidgets('bottom bar: Android has five pages; desktop only the ones it can use', (tester) async {
    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(
            initial: const AppState(settings: WaaiyaSettings(gender: 'man'), capabilities: Capabilities.android))));
    await tester.pumpAndSettle();
    expect(navKeys(tester), ['filter', 'screen', 'links', 'setup', 'settings']);

    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(
            initial: const AppState(
                platform: 'linux',
                settings: WaaiyaSettings(gender: 'man'),
                capabilities: Capabilities(screenBlur: true, blurStandalone: true)))));
    await tester.pumpAndSettle();
    expect(navKeys(tester), ['filter', 'screen', 'settings']);

    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(initial: const AppState(platform: 'macos', settings: WaaiyaSettings(gender: 'man')))));
    await tester.pumpAndSettle();
    expect(navKeys(tester), ['filter', 'settings']);
  });

  testWidgets('each page holds its own part: filter options, blur, setup, settings', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(
            initial: const AppState(
                settings: WaaiyaSettings(gender: 'man'),
                capabilities: Capabilities.android,
                setup: SetupInfo(originalsMuted: false)))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('power')), findsOneWidget);
    expect(find.text(ar.filterOptionsTitle), findsOneWidget);
    expect(find.text(ar.blurTitle), findsNothing);
    // the setup is missing: the Filter page says so and leads to the Setup page
    await tester.ensureVisible(find.text(ar.setupGo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.setupGo));
    await tester.pumpAndSettle();
    expect(find.text(ar.wsetupRouteTitle), findsOneWidget);
    expect(find.byKey(const Key('power')), findsNothing);
    await goTo(tester, 'screen');
    expect(find.text(ar.blurTitle), findsOneWidget);
    await goTo(tester, 'settings');
    expect(find.text(ar.settingGenderTitle, findRichText: true), findsNothing); // inside "label: value"
    expect(find.textContaining(ar.settingGenderTitle), findsOneWidget);
    expect(find.byKey(const Key('diagnostics')), findsOneWidget);
  });

  testWidgets('setup done: a short card, the steps one tap away', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(
            initial: const AppState(
                settings: WaaiyaSettings(gender: 'man'),
                capabilities: Capabilities.android,
                setup: SetupInfo(originalsMuted: true, consentSkipped: true, shizuku: ShizukuState.ready)))));
    await tester.pumpAndSettle();
    expect(find.text(ar.setupBannerTitle), findsNothing);
    await goTo(tester, 'setup');
    expect(find.text(ar.setupDoneTitle), findsOneWidget);
    expect(find.text(ar.wsetupRouteTitle), findsNothing);
    await tester.tap(find.text(ar.setupRedo));
    await tester.pumpAndSettle();
    expect(find.text(ar.wsetupRouteTitle), findsOneWidget);
  });

  testWidgets('a page asked for by Android (a tile\'s "Open Waaiya") is shown once, then confirmed', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final b = _Recording(const AppState(
        settings: WaaiyaSettings(gender: 'man'),
        capabilities: Capabilities.android,
        setup: SetupInfo(originalsMuted: false)));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    b.emit(AppState.fromMap({
      ...b.state.toMap(),
      'navigate': {'page': 'setup', 'id': 1},
    }));
    await tester.pumpAndSettle();
    expect(find.text(ar.wsetupRouteTitle), findsOneWidget);
    expect(b.calls, ['pageShown']);
    // the same request again (no new id) does not move the user away from where they went
    await goTo(tester, 'filter');
    b.emit(AppState.fromMap({
      ...b.state.toMap(),
      'navigate': {'page': 'setup', 'id': 1},
    }));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('power')), findsOneWidget);
  });

  testWidgets('on-phone setup: status in words, code and cancel buttons while it runs', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final b = _Recording(const AppState(
      settings: WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      setup: SetupInfo(originalsMuted: false, wireless: WirelessInfo(supported: true)),
    ));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    await goTo(tester, 'setup');
    expect(find.text(ar.wsetupEnterHere), findsNothing);
    await tester.ensureVisible(find.text(ar.wsetupStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.wsetupStart));
    await tester.pumpAndSettle();
    expect(b.calls, ['wirelessStart']);
    b.emit(b.state.copyWith(
        setup: const SetupInfo(
            originalsMuted: false,
            wireless: WirelessInfo(
                supported: true,
                running: true,
                phase: 'FAILED',
                title: 'wsetup_failed_title',
                body: 'setup_refused_xiaomi',
                isError: true,
                hint: 'wsetup_notif_off'))));
    await tester.pumpAndSettle();
    expect(find.text(ar.wsetupFailedTitle), findsOneWidget);
    expect(find.text(ar.setupRefusedXiaomi), findsOneWidget);
    expect(find.text(ar.wsetupNotifOff), findsOneWidget);
    expect(find.text(ar.wsetupEnterHere), findsOneWidget);
    expect(find.text(ar.wsetupCancel), findsOneWidget);
  });

  test('every string name Android can send in setup.wireless has words', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final kotlin = File('../android/app/src/main/java/org/islamicmute/app/WirelessSetup.kt').readAsStringSync();
    final texts = kotlin.substring(kotlin.indexOf('object WirelessSetupTexts'));
    final names = RegExp(r'R\.string\.(\w+)').allMatches(texts.substring(0, texts.indexOf('fun title('))).map((m) => m[1]!).toSet();
    final bridge = File('../android/app/src/main/java/org/islamicmute/app/UiBridge.kt').readAsStringSync();
    names.addAll(RegExp(r'wirelessHint = "(\w+)"').allMatches(bridge).map((m) => m[1]!));
    expect(names.length, greaterThan(20));
    for (final n in names) {
      expect(wirelessText(l, n), isNotNull, reason: n);
    }
  });

  testWidgets('Screen page: who draws the covers, and the button for Waaiya\'s helper', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final b = _Recording(const AppState(
      settings: WaaiyaSettings(gender: 'man', blurWomen: true),
      capabilities: Capabilities.android,
      setup: SetupInfo(shizuku: ShizukuState.notInstalled, wireless: WirelessInfo(supported: true)),
      blur: BlurInfo(layerSupported: true, overlayAllowed: true, helperStartable: true),
    ));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    await goTo(tester, 'screen');
    expect(find.text(ar.helperBodyOff), findsOneWidget);
    await tester.ensureVisible(find.text(ar.helperStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.helperStart));
    await tester.pumpAndSettle();
    expect(b.calls, ['wirelessStart']);
    b.emit(b.state.copyWith(
        blur: const BlurInfo(
            layerSupported: true, overlayAllowed: true, helperRunning: true, shizukuLayer: true, touchPassThrough: true)));
    await tester.pumpAndSettle();
    expect(find.text(ar.helperOn), findsOneWidget);
    expect(find.text(ar.helperStart), findsNothing);
    // blur options off: nothing to say about covers
    b.emit(b.state.copyWith(settings: const WaaiyaSettings(gender: 'man')));
    await tester.pumpAndSettle();
    expect(find.text(ar.helperTitle), findsNothing);
  });
}
