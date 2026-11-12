// The 0.2.9 screens (Android MainActivity): problem lines while filtering, capture failed / cancelled, the
// start-without-setup dialog, the diagnostics report, "Waaiya stopped" on desktop, uncovered monitors.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

AppState _filtering({String? problem, bool mono = false, List<String> blocked = const [], bool silence = true}) =>
    AppState(
      settings: WaaiyaSettings(gender: 'man', silenceUnfilterable: silence),
      filter: FilterInfo(
          state: FilterState.filtering, delayMs: 40, problem: problem, mono: mono, blockedApps: blocked),
    );

class _ReportBackend extends MemoryBackend {
  _ReportBackend(AppState s) : super(initial: s);
  @override
  Future<String> diagnosticsReport() async => 'Waaiya 0.2.9\nFilter: FILTERING\nmuter: OK';
}

void main() {
  test('while filtering: a problem first, else the delay, mono and blocked apps (MainActivity.refresh)', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(filteringDetail(l, _filtering(problem: FilterProblem.tooSlow)), (l.stateTooSlow, true));
    expect(filteringDetail(l, _filtering(problem: FilterProblem.notMuted)), (l.stateOnNotMuted, true));
    expect(filteringDetail(l, _filtering(problem: FilterProblem.muteFailing)), (l.stateOnMuteFailing, true));
    expect(filteringDetail(l, _filtering(problem: FilterProblem.detectorFailed)), (l.engineDetectorFailed, true));
    expect(filteringDetail(l, _filtering()), (l.stateOnDetail(40), false));
    final d = filteringDetail(l, _filtering(mono: true, blocked: ['Spotify', 'Deezer']));
    expect(d.$2, isFalse);
    expect(d.$1.split('\n'), [l.stateOnDetail(40), l.stateMonoNote, l.stateBlockedSilenced('Spotify، Deezer')]);
    expect(filteringDetail(l, _filtering(blocked: ['Spotify'], silence: false)).$1,
        contains(l.stateBlockedUnfiltered('Spotify')));
  });

  testWidgets('capture failed, capture cancelled, a problem line in the error colour', (tester) async {
    final b = MemoryBackend(initial: const AppState(
      settings: WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      filter: FilterInfo(state: FilterState.captureFailed),
    ));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(ar.stateCaptureFailed), findsOneWidget);
    expect(find.text(ar.stateOffTitle), findsOneWidget);
    b.emit(b.state.copyWith(filter: const FilterInfo(captureCancelled: true)));
    await tester.pumpAndSettle();
    expect(find.text(ar.stateCaptureCancelled), findsOneWidget);
    b.emit(b.state.copyWith(filter: const FilterInfo(state: FilterState.filtering, problem: FilterProblem.muteFailing)));
    await tester.pumpAndSettle();
    final line = tester.widget<Text>(find.text(ar.stateOnMuteFailing));
    expect(line.style?.color, WaaiyaColors.of(tester.element(find.text(ar.stateOnMuteFailing))).error);
  });

  testWidgets('desktop: a filter that stopped by itself says "Waaiya stopped"', (tester) async {
    final b = MemoryBackend(initial: const AppState(
      platform: 'linux',
      settings: WaaiyaSettings(gender: 'woman'),
      capabilities: Capabilities(autostart: true),
      filter: FilterInfo(state: FilterState.stoppedBySystem),
    ));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(ar.notifStoppedTitle), findsOneWidget);
    expect(find.text(ar.notifStoppedText), findsOneWidget);
    expect(find.text(ar.stateStoppedBySystem), findsNothing); // "Android stopped filtering" is Android's
  });

  testWidgets('Android without the setup: Start asks first; "Start anyway" starts, "Do the setup" does not',
      (tester) async {
    final b = MemoryBackend(initial: const AppState(
      settings: WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      setup: SetupInfo(originalsMuted: false, shizuku: ShizukuState.notInstalled),
    ));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.text(ar.startNoSetupTitle), findsOneWidget);
    await tester.tap(find.text(ar.startNoSetupSetup));
    await tester.pumpAndSettle();
    expect(b.state.filter.running, isFalse);
    expect(find.text(ar.startNoSetupTitle), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_anyway')));
    await tester.pumpAndSettle();
    expect(b.state.filter.running, isTrue);
    // with the setup done, no question
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    b.emit(b.state.copyWith(setup: const SetupInfo(originalsMuted: true, shizuku: ShizukuState.ready)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.text(ar.startNoSetupTitle), findsNothing);
    expect(b.state.filter.running, isTrue);
  });

  testWidgets('desktop never asks (no setup there)', (tester) async {
    final b = MemoryBackend(initial: const AppState(
        platform: 'linux', settings: WaaiyaSettings(gender: 'man'), setup: SetupInfo(originalsMuted: false)));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(b.state.filter.running, isTrue);
  });

  testWidgets('diagnostics report: shown, left to right, copied', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    final b = _ReportBackend(const AppState(platform: 'linux', settings: WaaiyaSettings(gender: 'man')));
    await tester.pumpWidget(WaaiyaApp(backend: b));
    await tester.pumpAndSettle();
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final button = find.byKey(const Key('diagnostics'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(find.text(ar.diagButton), findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text(ar.diagTitle), findsOneWidget);
    expect(find.text(ar.diagNoteDesktop), findsOneWidget);
    expect(find.textContaining('muter: OK'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('diag_report')))), TextDirection.ltr);
    await tester.tap(find.text(ar.copy));
    await tester.pumpAndSettle();
    expect(copied.single, contains('Filter: FILTERING'));
    expect(find.text(ar.diagTitle), findsNothing);
  });

  test('desktop blur: a monitor left out is said; models missing has its own text', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    AppState s(BlurState st, {int uncovered = 0, BackendMessage? e}) => AppState(
          settings: const WaaiyaSettings(blurNudity: true),
          capabilities: const Capabilities(screenBlur: true, blurStandalone: true),
          blur: BlurInfo(state: st, uncovered: uncovered, error: e, overlayAllowed: true, touchPassThrough: true),
        );
    expect(blurStatus(l, s(BlurState.onCoversVisible, uncovered: 1)), (l.blurStatusUncovered, true));
    expect(blurStatus(l, s(BlurState.onCoversVisible)), (l.blurStatusOnVisibleDesktop, false));
    expect(blurStatus(l, s(BlurState.modelsMissing))!.$1, l.blurStatusModelsMissingDesktop);
    expect(blurStatus(l, s(BlurState.modelsMissing, e: const BackendMessage('models_missing', 'gender_v2.onnx')))!.$1,
        contains('gender_v2.onnx'));
  });

  test('snapshot: the 0.2.9 keys round-trip and default when missing', () async {
    final s = AppState.fromMap({
      'filter': {
        'state': 'CAPTURE_FAILED',
        'problem': 'too_slow',
        'mono': true,
        'blockedApps': ['Spotify', 3],
        'captureCancelled': true,
      },
      'blur': {'uncovered': 2},
    });
    expect(s.filter.state, FilterState.captureFailed);
    expect(s.filter.running, isFalse);
    expect(s.filter.problem, 'too_slow');
    expect(s.filter.mono, isTrue);
    expect(s.filter.blockedApps, ['Spotify']);
    expect(s.filter.captureCancelled, isTrue);
    expect(s.blur.uncovered, 2);
    expect(AppState.fromMap(s.toMap()).toMap(), s.toMap());
    final empty = AppState.fromMap(const {});
    expect(empty.filter.problem, isNull);
    expect(empty.filter.blockedApps, isEmpty);
    expect(empty.blur.uncovered, 0);
  });

  test('ChannelBackend: diagnosticsReport', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('waaiya/app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (call) async => call.method == 'diagnosticsReport' ? 'report text' : null);
    expect(await ChannelBackend().diagnosticsReport(), 'report text');
  });
}
