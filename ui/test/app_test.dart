import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

TextDirection directionOf(WidgetTester tester, Finder f) => Directionality.of(tester.element(f));

void main() {
  testWidgets('starts in Arabic, right to left, and switches to English', (tester) async {
    final backend = MemoryBackend();
    await tester.pumpWidget(WaaiyaApp(backend: backend));
    await tester.pumpAndSettle();

    // First launch: onboarding in Arabic.
    expect(find.text('أهلًا بك'), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);
    expect(directionOf(tester, find.text('أهلًا بك')), TextDirection.rtl);

    // The language button names the other language and goes through the backend.
    await tester.tap(find.byKey(const Key('onboard_language')));
    await tester.pumpAndSettle();
    expect(backend.state.language, 'en');
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('أهلًا بك'), findsNothing);
    expect(directionOf(tester, find.text('Welcome')), TextDirection.ltr);
    expect(find.text('العربية'), findsOneWidget);

    // And back.
    await tester.tap(find.byKey(const Key('onboard_language')));
    await tester.pumpAndSettle();
    expect(backend.state.language, 'ar');
    expect(directionOf(tester, find.text('أهلًا بك')), TextDirection.rtl);
  });

  testWidgets('choosing "a man" opens the main screen; the button starts and stops filtering', (tester) async {
    final backend = MemoryBackend(initial: const AppState(capabilities: Capabilities(womenSinging: true)));
    await tester.pumpWidget(WaaiyaApp(backend: backend));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choose_man')));
    await tester.pumpAndSettle();
    expect(backend.state.settings.gender, 'man');
    expect(find.text('التصفية متوقفة'), findsOneWidget);
    expect(find.text('كتم غناء النساء'), findsOneWidget); // men only

    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(backend.state.filter.running, isTrue);
    expect(find.text('التصفية تعمل'), findsOneWidget);
    expect(find.textContaining('40'), findsOneWidget); // delay in words

    // Settings apply live: no "stop and start" note.
    await tester.tap(find.text('كتم غناء النساء'));
    await tester.pumpAndSettle();
    expect(backend.state.settings.muteWomenSinging, isTrue);
    expect(find.text('أوقف التصفية ثم شغّلها لتطبيق التغييرات.'), findsNothing);

    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(backend.state.filter.running, isFalse);
  });

  testWidgets('women do not see the singing option; Android-only cards follow the capabilities', (tester) async {
    final backend = MemoryBackend(
      initial: const AppState(
        settings: WaaiyaSettings(gender: 'woman'),
        capabilities: Capabilities(womenSinging: true),
      ),
    );
    await tester.pumpWidget(WaaiyaApp(backend: backend));
    await tester.pumpAndSettle();
    expect(find.text('كتم غناء النساء'), findsNothing);
    expect(find.text('تمويه الشاشة'), findsNothing);
    expect(find.text('إعداد لمرة واحدة'), findsNothing);
  });

  testWidgets('Android: setup checklist with the current step and the adb commands', (tester) async {
    final backend = MemoryBackend(
      initial: const AppState(
        settings: WaaiyaSettings(gender: 'man'),
        capabilities: Capabilities.android,
        setup: SetupInfo(
          originalsMuted: false,
          consentSkipped: false,
          shizuku: ShizukuState.notRunning,
          adbCommands: 'adb shell pm grant org.islamicmute.app android.permission.DUMP',
        ),
      ),
    );
    await tester.pumpWidget(WaaiyaApp(backend: backend));
    await tester.pumpAndSettle();
    expect(find.text('بقيت خطوة واحدة'), findsOneWidget);
    expect(find.text('إعداد لمرة واحدة'), findsOneWidget);
    expect(find.text('كيف أشغّل Shizuku؟'), findsOneWidget); // step 2 is current: the guide
    expect(find.text('تحميل Shizuku'), findsNothing); // step 1 done
    await tester.ensureVisible(find.text('كيف أشغّل Shizuku؟'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كيف أشغّل Shizuku؟'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shizuku_guide')), findsOneWidget);
    expect(find.text('تشغيل Shizuku خطوة بخطوة'), findsOneWidget);
    expect(find.text('خيارات المطور'), findsOneWidget);
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shizuku_guide')), findsNothing);
    await tester.ensureVisible(find.text('استخدم حاسوبًا بدلًا من ذلك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('استخدم حاسوبًا بدلًا من ذلك'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pm grant'), findsOneWidget);
    expect(directionOf(tester, find.textContaining('pm grant')), TextDirection.ltr);
  });

  test('setup steps follow MainActivity.refreshSteps', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    var (steps, current) = setupSteps(l, const SetupInfo(originalsMuted: false, shizuku: ShizukuState.notInstalled));
    expect(current, 0);
    (steps, current) = setupSteps(l, const SetupInfo(originalsMuted: false, shizuku: ShizukuState.tooOld));
    expect(current, 1);
    expect(steps[1].action, l.step2Update);
    (steps, current) =
        setupSteps(l, const SetupInfo(originalsMuted: false, shizuku: ShizukuState.deniedPermanently));
    expect(current, 2);
    expect(steps[2].body, l.step2Denied);
    (steps, current) = setupSteps(l, const SetupInfo(originalsMuted: true, shizuku: ShizukuState.ready));
    expect(current, -1);
  });

  test('blur status follows MainActivity.refreshBlur', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    const off = AppState();
    expect(blurStatus(l, off), isNull);
    final needsOverlay = off.copyWith(settings: const WaaiyaSettings(blurWomen: true));
    expect(blurStatus(l, needsOverlay), (l.blurStatusNeedsOverlay, true));
    final running = needsOverlay.copyWith(
      filter: const FilterInfo(state: FilterState.filtering),
      blur: const BlurInfo(overlayAllowed: true, state: BlurState.failing),
    );
    expect(blurStatus(l, running), (l.blurStatusFailing, true));
    // Shizuku layer (Android 12+): nothing to allow; not applied yet = starting.
    final layer = needsOverlay.copyWith(
      filter: const FilterInfo(state: FilterState.filtering),
      blur: const BlurInfo(shizukuLayer: true),
    );
    expect(blurStatus(l, layer), (l.blurStatusStarting, false));
    final failed = running.copyWith(blur: const BlurInfo(message: BackendMessage('setup_failed', 'log')));
    expect(blurStatus(l, failed), (l.blurSetupFailed('log'), true));
  });

  test('greyed-out cover switch: note and next Shizuku step (MainActivity 0.2.4)', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    AppState with_(ShizukuState? s, {bool layer = true, bool pass = false}) => AppState(
          setup: SetupInfo(shizuku: s),
          blur: BlurInfo(layerSupported: layer, touchPassThrough: pass),
        );
    expect(blurFailFix(l, with_(ShizukuState.notInstalled)), l.step1Action);
    expect(blurFailFix(l, with_(ShizukuState.tooOld)), l.step2Update);
    expect(blurFailFix(l, with_(ShizukuState.notRunning)), l.step2Guide);
    expect(blurFailFix(l, with_(ShizukuState.needsPermission)), l.step3Action);
    expect(blurFailFix(l, with_(ShizukuState.deniedPermanently)), l.step2Action);
    expect(blurFailFix(l, with_(ShizukuState.ready)), isNull);
    expect(blurFailFix(l, with_(ShizukuState.notRunning, pass: true)), isNull); // taps already pass through
    expect(blurFailFix(l, with_(ShizukuState.notRunning, layer: false)), isNull); // Android < 12
  });

  testWidgets('blur card: greyed-out switch shows the note and opens the guide', (tester) async {
    final backend = MemoryBackend(
      initial: const AppState(
        settings: WaaiyaSettings(gender: 'man', blurWomen: true),
        capabilities: Capabilities.android,
        setup: SetupInfo(shizuku: ShizukuState.notRunning),
        blur: BlurInfo(layerSupported: true, overlayAllowed: true),
      ),
    );
    await tester.pumpWidget(WaaiyaApp(backend: backend));
    await tester.pumpAndSettle();
    final fix = find.byKey(const Key('blur_fail_fix'));
    await tester.ensureVisible(fix);
    await tester.pumpAndSettle();
    expect(find.textContaining('معطّل مؤقتًا'), findsOneWidget); // blur_fail_unavailable note
    await tester.tap(fix);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shizuku_guide')), findsOneWidget);
  });

  testWidgets('blur card: "who is left uncovered" row and dialog', (tester) async {
    final backend = MemoryBackend(
      initial: const AppState(
        settings: WaaiyaSettings(gender: 'man'),
        capabilities: Capabilities.android,
        blur: BlurInfo(touchPassThrough: true),
      ),
    );
    await tester.pumpWidget(WaaiyaApp(backend: backend));
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('blur_strict'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(find.text('مَن يبقى دون تغطية: صارم'), findsOneWidget);
    await tester.tap(find.descendant(of: row, matching: find.text('تغيير')));
    await tester.pumpAndSettle();
    expect(find.text('مَن يبقى دون تغطية'), findsOneWidget); // dialog title
    await tester.tap(find.text('متوازن: نحو ضعف عدد الرجال دون تغطية'));
    await tester.pumpAndSettle();
    expect(backend.state.settings.blurStrictness, 1);
    expect(find.text('مَن يبقى دون تغطية: متوازن'), findsOneWidget);
  });

  test('snapshots: missing keys take defaults, names round-trip', () {
    final s = AppState.fromMap({
      'language': 'en',
      'filter': {'state': 'MODEL_FAILED', 'delayMs': 42},
      'setup': {'shizuku': 'DENIED_PERMANENTLY'},
      'blur': {'state': 'ON_COVERS_VISIBLE'},
      'unknown_key': 1,
    });
    expect(s.language, 'en');
    expect(s.filter.state, FilterState.modelFailed);
    expect(s.filter.running, isTrue);
    expect(s.setup.shizuku, ShizukuState.deniedPermanently);
    expect(s.blur.state, BlurState.onCoversVisible);
    expect(s.settings.silenceUnfilterable, isTrue);
    expect(AppState.fromMap(s.toMap()).toMap(), s.toMap());
  });

  test('only the Settings.kt keys are accepted', () async {
    final b = MemoryBackend();
    await b.setSetting(SettingKeys.blurNudity, true);
    expect(b.state.settings.blurNudity, isTrue);
    expect(() => b.setSetting('lang', 'en'), throwsA(isA<BackendException>()));
    expect(() => b.setSetting(SettingKeys.gender, 'other'), throwsA(isA<BackendException>()));
    expect(() => b.setSetting(SettingKeys.blurWomen, 'yes'), throwsA(isA<BackendException>()));
    expect(() => b.setSetting(SettingKeys.blurStrictness, 3), throwsA(isA<BackendException>()));
    await b.setSetting(SettingKeys.blurStrictness, 2);
    expect(b.state.settings.blurStrictness, 2);
  });

  test('ChannelBackend speaks the contract', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final calls = <MethodCall>[];
    const channel = MethodChannel('waaiya/app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getState' => {'language': 'en', 'platform': 'android'},
        'startFilter' => 'mic_denied',
        'setSetting' => throw PlatformException(code: 'bad_args'),
        _ => null,
      };
    });
    final b = ChannelBackend();
    expect((await b.getState()).language, 'en');
    expect(await b.startFilter(), StartResult.micDenied);
    await b.runSetupStep(2);
    expect(calls.last.arguments, {'step': 2});
    expect(() => b.setSetting('gender', 'man'), throwsA(isA<BackendException>()));
  });
}
