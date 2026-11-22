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
    // Android: the simple-mode test card comes first
    await tester.scrollUntilVisible(find.text(ar.setupDoneTitle), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(ar.setupDoneTitle), findsOneWidget);
    expect(find.text(ar.wsetupRouteTitle), findsNothing);
    await tester.ensureVisible(find.text(ar.setupRedo));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200)); // out from under the bottom bar
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.setupRedo));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(ar.wsetupRouteTitle), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(ar.wsetupRouteTitle), findsOneWidget);
  });

  testWidgets('helper mode (grants refused, Xiaomi/OPPO): setup counts as done; after a restart one button',
      (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    const running = SetupInfo(
        originalsMuted: true, consentSkipped: false, helperMode: true, helperTip: 'coloros',
        wireless: WirelessInfo(supported: true));
    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(
            initial: const AppState(
                settings: WaaiyaSettings(gender: 'man'), capabilities: Capabilities.android, setup: running))));
    await tester.pumpAndSettle();
    // no "one step left" although Android will ask before each capture (PROJECT_MEDIA refused too)
    expect(find.text(ar.setupBannerTitle), findsNothing);
    expect(find.text(ar.helperMissingTitle), findsNothing);
    await goTo(tester, 'setup');
    expect(find.text(ar.setupDoneTitle), findsOneWidget);
    expect(find.text(ar.helperModeNote), findsOneWidget);
    expect(find.text(ar.helperTipColoros), findsOneWidget);

    // the phone restarted: the helper is gone; Filter page and Setup page offer to start it, no code needed
    final b = _Recording(AppState(
        settings: const WaaiyaSettings(gender: 'man'),
        capabilities: Capabilities.android,
        setup: SetupInfo(
            originalsMuted: true, consentSkipped: false, helperMode: true, helperMissing: true,
            wireless: const WirelessInfo(supported: true))));
    await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
    await tester.pumpAndSettle();
    expect(find.text(ar.helperMissingTitle), findsOneWidget);
    expect(find.text(ar.setupBannerTitle), findsNothing);
    await tester.ensureVisible(find.text(ar.helperStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.helperStart));
    await tester.pumpAndSettle();
    expect(b.calls, contains('wirelessStart'));
    await goTo(tester, 'setup');
    expect(find.text(ar.helperMissingTitle), findsOneWidget);
    // an automatic restart is trying: still the short card, the button stays usable, a line says "starting"
    b.emit(b.state.copyWith(
        setup: const SetupInfo(
            originalsMuted: true, consentSkipped: false, helperMode: true, helperMissing: true, helperRestarting: true,
            wireless: WirelessInfo(supported: true, running: true, phase: 'WAITING'))));
    await tester.pumpAndSettle();
    expect(find.text(ar.helperStarting), findsOneWidget);
    expect(find.text(ar.wizWdTitle), findsNothing);
    // a run the user started (pairing lost: a code is needed): the steps, the status and Cancel are on screen
    b.emit(b.state.copyWith(
        setup: const SetupInfo(
            originalsMuted: true, consentSkipped: false, helperMode: true, helperMissing: true,
            wireless: WirelessInfo(supported: true, running: true, phase: 'WAITING', title: 'wsetup_notif_title'))));
    await tester.pumpAndSettle();
    expect(find.text(ar.wizWdTitle), findsOneWidget);
    expect(find.text(ar.wsetupCancel), findsOneWidget);
    b.emit(b.state.copyWith(
        setup: const SetupInfo(
            originalsMuted: true, consentSkipped: false, helperMode: true, helperMissing: true,
            wireless: WirelessInfo(supported: true))));
    await tester.pumpAndSettle();

    // Start while the helper is stopped (and not coming back by itself): warned first, the music would be heard
    await goTo(tester, 'filter');
    await tester.ensureVisible(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.text(ar.helperStartAnywayBody), findsOneWidget);
    await tester.tap(find.byKey(const Key('start_anyway')));
    await tester.pumpAndSettle();
    expect(find.text(ar.helperStartAnywayBody), findsNothing);
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

  testWidgets('computer route: the page that needs no adb comes before the adb commands', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(ar.computerWeb, contains('waaiya.mssid.org/usb'));
    final b = _Recording(const AppState(
        settings: WaaiyaSettings(gender: 'man'),
        capabilities: Capabilities.android,
        setup: SetupInfo(originalsMuted: false, shizuku: ShizukuState.notInstalled,
            wireless: WirelessInfo(supported: true), adbCommands: 'adb shell cmd package grant x y')));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    await goTo(tester, 'setup');
    await tester.ensureVisible(find.text(ar.setupOtherWays));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.setupOtherWays));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(ar.computerToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.computerToggle));
    await tester.pumpAndSettle();
    expect(find.text(ar.computerWeb), findsOneWidget);
    expect(find.text(ar.computerBody), findsOneWidget);
    expect(tester.getTopLeft(find.text(ar.computerWeb)).dy, lessThan(tester.getTopLeft(find.text(ar.computerBody)).dy));
  });

  testWidgets('guided setup: steps tick themselves, one button for the current step, never a dead end',
      (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    AppState at(WirelessInfo w) => AppState(
        settings: const WaaiyaSettings(gender: 'man'),
        capabilities: Capabilities.android,
        setup: SetupInfo(originalsMuted: false, shizuku: ShizukuState.notInstalled, wireless: w));
    // a new Samsung: Developer options off, no Wi-Fi
    final b = _Recording(at(const WirelessInfo(supported: true, devOptions: false, wifi: false, aboutHint: 'samsung')));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    await goTo(tester, 'setup');
    expect(wirelessSteps(b.state.setup).$1, [false, false, false, false]);
    expect(wirelessSteps(b.state.setup).$2, 0);
    expect(find.text('${ar.wizDevBodySamsung} ${ar.wizDevSearch}'), findsOneWidget); // where "Build number" is on this make
    expect(find.text(ar.wizDevAction), findsOneWidget);
    expect(find.text(ar.wizWifiAction), findsNothing); // one button at a time
    expect(find.text(ar.wizWdAction), findsNothing);
    expect(find.text(ar.wizSkip), findsOneWidget); // the ticks are hints: Wireless debugging stays reachable
    expect(find.text(ar.step1Title), findsNothing); // Shizuku and the computer are folded away
    await tester.ensureVisible(find.text(ar.setupOtherWays));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.setupOtherWays));
    await tester.pumpAndSettle();
    expect(find.text(ar.step1Title), findsOneWidget);

    // Developer options on: the Wi-Fi step is current
    b.emit(at(const WirelessInfo(supported: true, devOptions: true, wifi: false)));
    await tester.pumpAndSettle();
    expect(wirelessSteps(b.state.setup).$2, 1);
    expect(find.text(ar.wizDevAction), findsNothing);
    expect(find.text(ar.wizWifiAction), findsOneWidget);

    // Wi-Fi on, switch state unreadable on this phone (null): step 3 with its button
    b.emit(at(const WirelessInfo(supported: true)));
    await tester.pumpAndSettle();
    expect(wirelessSteps(b.state.setup).$2, 2);
    expect(find.text(ar.wizWdAction), findsOneWidget);
    expect(find.text(ar.wizSkip), findsNothing);

    // Wireless debugging seen on: the code step; paired before: no code needed
    b.emit(at(const WirelessInfo(supported: true, wirelessDebugging: true)));
    await tester.pumpAndSettle();
    expect(wirelessSteps(b.state.setup).$2, 3);
    expect(find.text(ar.wizPairBody), findsOneWidget);
    b.emit(at(const WirelessInfo(supported: true, wirelessDebugging: true, paired: true)));
    await tester.pumpAndSettle();
    expect(find.text(ar.wizPairBodyPaired), findsOneWidget);

    // step 4 without a run: its button starts one (nothing "finishes by itself" before that)
    expect(find.text(ar.wizPairAction), findsOneWidget);

    // a finished run: every step ticked, and still a button to run the setup again (no dead end)
    b.emit(at(const WirelessInfo(supported: true, wirelessDebugging: true, paired: true, phase: 'DONE')));
    await tester.pumpAndSettle();
    expect(wirelessSteps(b.state.setup).$2, 4);
    expect(find.text(ar.wizAgain), findsOneWidget);

    // a failed run while the first step looks undone: its reason is on screen, with the button to try again
    b.emit(at(const WirelessInfo(
        supported: true, devOptions: false, phase: 'FAILED', title: 'wsetup_failed_title', body: 'wsetup_timeout', isError: true)));
    await tester.pumpAndSettle();
    expect(find.text(ar.wsetupTimeout), findsOneWidget);
    expect(find.text(ar.wizWdAction), findsOneWidget);

    // the pairing screen was found although the switch cannot be read: step 3 is proven done
    expect(
        wirelessSteps(at(const WirelessInfo(supported: true, running: true, phase: 'WAITING', title: 'wsetup_found_title'))
                .setup)
            .$2,
        3);
  });

  testWidgets('setup with Shizuku already running: its one-tap grant comes first', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(WaaiyaApp(
        key: UniqueKey(),
        backend: MemoryBackend(
            initial: const AppState(
                settings: WaaiyaSettings(gender: 'man'),
                capabilities: Capabilities.android,
                setup: SetupInfo(
                    originalsMuted: false, shizuku: ShizukuState.ready, wireless: WirelessInfo(supported: true))))));
    await tester.pumpAndSettle();
    await goTo(tester, 'setup');
    expect(find.text(ar.step3Action), findsOneWidget);
    expect(find.text(ar.setupShizukuReadyTitle), findsOneWidget);
    expect(find.text(ar.wsetupRouteTitle), findsNothing); // one way on screen: the steps are under "Other ways"
    await tester.ensureVisible(find.text(ar.setupOtherWaysPlain));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.setupOtherWaysPlain));
    await tester.pumpAndSettle();
    expect(find.text(ar.wsetupRouteTitle), findsOneWidget);
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
    await tester.ensureVisible(find.text(ar.wizWdAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.wizWdAction));
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
    final kotlin = File('../android/app/src/main/java/org/waaiya/app/WirelessSetup.kt').readAsStringSync();
    final texts = kotlin.substring(kotlin.indexOf('object WirelessSetupTexts'));
    final names = RegExp(r'R\.string\.(\w+)').allMatches(texts.substring(0, texts.indexOf('fun title('))).map((m) => m[1]!).toSet();
    final bridge = File('../android/app/src/main/java/org/waaiya/app/UiBridge.kt').readAsStringSync();
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
