import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';
import 'package:waaiya_ui/src/protection_core.dart';

/// Protection that survives a weak moment (lane B): the dialogs and the card over the real guard
/// (ProtectionGate, the same one the desktop uses), with a clock the test moves.
class _Clock implements ProtectionClock {
  int wall = DateTime.now().millisecondsSinceEpoch;
  int elapsed = 1000000;
  String boot = 'b1';
  @override
  int wallMs() => wall;
  @override
  int elapsedMs() => elapsed;
  @override
  String bootId() => boot;
  void pass(Duration d) {
    wall += d.inMilliseconds;
    elapsed += d.inMilliseconds;
  }
}

class _Backend extends MemoryBackend {
  _Backend(AppState s, this.clock) : super(initial: s) {
    gate = ProtectionGate(
      ProtectionCore(
        store: store,
        clock: clock,
        delayMinutes: () => state.settings.protectDelayMinutes,
        current: (k) => state.settings.toMap()[k],
        iterations: 50,
      ),
      apply: (what, v) => what == 'stop' ? _stop() : _set(what, v!),
      changed: show,
    );
    methods.addAll(gate.methods);
    show();
  }

  final _Clock clock;
  final store = <String, Object?>{};
  late final ProtectionGate gate;
  final calls = <String>[];

  void show() => emit(state.copyWith(features: {...state.features, 'protect': gate.section()}));

  Future<void> _set(String key, Object value) async {
    calls.add('set $key=$value');
    await super.setSetting(key, value);
    show();
  }

  Future<void> _stop() async {
    calls.add('stop');
    await super.stopFilter();
  }

  @override
  Future<void> setSetting(String key, Object value) async {
    gate.checkSetting(key, value);
    await _set(key, value);
  }

  @override
  Future<void> stopFilter() async {
    gate.checkStop();
    await _stop();
  }
}

AppState _state({int delay = 0, bool hold = true, String platform = 'android'}) => AppState(
      language: 'en',
      platform: platform,
      settings: WaaiyaSettings(gender: 'man', holdSilence: hold, protectDelayMinutes: delay),
      capabilities: Capabilities.android,
      filter: const FilterInfo(state: FilterState.filtering, delayMs: 40),
    );

Future<_Backend> _open(WidgetTester tester,
    {int delay = 0, String? pin, bool hold = true, String platform = 'android'}) async {
  final b = _Backend(_state(delay: delay, hold: hold, platform: platform), _Clock());
  if (pin != null) await b.invoke('protect.setPin', {'pin': pin});
  await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _go(WidgetTester tester, String page) async {
  await tester.tap(find.byKey(Key('nav_$page')));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _typePin(WidgetTester tester, String pin) async {
  await tester.enterText(find.byKey(const Key('protect_pin_current')), pin);
  await tester.tap(find.byKey(const Key('protect_pin_ok')));
  await tester.pumpAndSettle();
}

void main() {
  group('rules', () {
    test('PBKDF2-HMAC-SHA256 matches Python and Android', () {
      // python3 -c "import hashlib;print(hashlib.pbkdf2_hmac('sha256',b'1234',bytes(range(16)),1000).hex())"
      final h = pbkdf2Sha256('1234', List.generate(16, (i) => i), 1000);
      expect(h.map((x) => x.toRadixString(16).padLeft(2, '0')).join(),
          '2240ea2a22754a3c4610356ef8e4d7acf25af2ac3d2d11866de97a8b7812c52c');
      final r = pinRecord('12345678', 1000);
      expect(r.split(':')[1].length, 32);
      expect(pinMatches('12345678', r), isTrue);
      expect(pinMatches('12345679', r), isFalse);
      expect(r.contains('12345678'), isFalse);
    });

    test('what weakens', () {
      const w = ProtectionRules.isWeakening;
      expect(w('blur_women', true, false), isTrue);
      expect(w('blur_women', false, true), isFalse);
      expect(w('keep_singing', false, true), isTrue);
      expect(w('blur_strictness', 0, 1), isTrue);
      expect(w('filter_off_apps', 'a', 'a,b'), isTrue);
      expect(w('filter_off_apps', 'a,b', 'a'), isFalse);
      expect(w('gender', '', 'man'), isFalse);
      expect(w('gender', 'man', 'woman'), isTrue);
      expect(w('protect_delay_minutes', 60, 5), isTrue);
      expect(w('prayer_silent', true, false), isFalse);
      expect(w('audio_stereo', true, false), isFalse);
      expect(ProtectionRules.lockMs(5), 30000);
      expect(ProtectionRules.lockMs(10), 60000);
    });

    test('a reboot or a clock change never shortens the wait', () {
      final c = _Clock();
      var cd = Countdown.start(60 * 60000, c);
      c.wall += 24 * 3600000; // the wall clock jumps a day
      expect(cd.remaining(c), 60 * 60000);
      c.pass(const Duration(minutes: 10));
      cd = cd.checkpoint(c);
      c.pass(const Duration(minutes: 5)); // lost at the shutdown
      c
        ..boot = 'b2'
        ..elapsed = 2 * 60000;
      expect(cd.remaining(c), 48 * 60000);
    });
  });

  testWidgets('a refused Stop asks the PIN; a wrong PIN says so; the right one stops', (tester) async {
    final b = await _open(tester, pin: '2468');
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the PIN'), findsOneWidget);
    expect(b.calls, isNot(contains('stop')));
    await _typePin(tester, '1111');
    expect(find.text('Wrong PIN. Tries left before a pause: 4.'), findsOneWidget);
    await _typePin(tester, '2468');
    expect(find.text('Enter the PIN'), findsNothing);
    expect(b.calls, contains('stop'));
    expect(b.state.filter.running, isFalse);
  });

  testWidgets('cancelling the PIN dialog changes nothing', (tester) async {
    final b = await _open(tester, pin: '2468');
    await _tap(tester, find.byKey(const Key('hold_silence')));
    expect(find.text('Enter the PIN'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(b.state.settings.holdSilence, isTrue);
  });

  testWidgets('a waiting period: the change waits, shows on the Settings page, and Cancel drops it', (tester) async {
    final b = await _open(tester, delay: 15);
    await _tap(tester, find.byKey(const Key('hold_silence')));
    expect(find.text('This change waits'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('protect_wait_start')));
    expect(b.state.settings.holdSilence, isTrue, reason: 'not applied yet');
    expect(find.textContaining('Waiting until'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the message goes
    await tester.pumpAndSettle();
    await _go(tester, 'settings');
    expect(find.textContaining('Keep apps silent'), findsWidgets);
    expect(find.textContaining(': waiting until'), findsOneWidget);
    expect(find.byKey(const Key('protect_confirm')), findsNothing);
    // the same change again does not restart the wait
    await _go(tester, 'filter');
    await _tap(tester, find.byKey(const Key('hold_silence')));
    expect(find.textContaining('Already waiting'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await _go(tester, 'settings');
    await _tap(tester, find.byKey(const Key('protect_cancel')));
    expect(find.textContaining('waiting until'), findsNothing);
    expect(b.state.settings.holdSilence, isTrue);
  });

  testWidgets('after the wait the change needs Confirm, then applies', (tester) async {
    final b = await _open(tester, delay: 1);
    await b.invoke('protect.request', {'what': 'hold_silence', 'value': false});
    await _go(tester, 'settings');
    expect(find.byKey(const Key('protect_confirm')), findsNothing);
    b.clock.pass(const Duration(minutes: 1));
    b.show();
    await tester.pumpAndSettle();
    expect(find.textContaining('Do you still want it?'), findsOneWidget);
    expect(b.state.settings.holdSilence, isTrue, reason: 'never applied silently');
    await _tap(tester, find.byKey(const Key('protect_confirm')));
    expect(b.state.settings.holdSilence, isFalse);
    expect(find.byKey(const Key('protect_confirm')), findsNothing);
  });

  testWidgets('a change not confirmed in 15 minutes lapses', (tester) async {
    final b = await _open(tester, delay: 1);
    await b.invoke('protect.request', {'what': 'stop'});
    b.clock.pass(const Duration(minutes: 16));
    b.show();
    await _go(tester, 'settings');
    expect(find.byKey(const Key('protect_cancel')), findsNothing);
    expect(await b.invoke('protect.confirm'), {'status': 'none'});
    expect(b.state.filter.running, isTrue);
  });

  testWidgets('strengthening goes through at once, PIN and waiting period or not', (tester) async {
    final b = await _open(tester, delay: 60, pin: '2468', hold: false);
    await _tap(tester, find.byKey(const Key('hold_silence')));
    expect(find.text('Enter the PIN'), findsNothing);
    expect(find.text('This change waits'), findsNothing);
    expect(b.state.settings.holdSilence, isTrue);
    // not about protection: stereo
    await _tap(tester, find.byKey(const Key('audio_stereo')));
    expect(b.state.settings.audioStereo, isTrue);
  });

  testWidgets('setting, then removing the PIN (the removal waits too)', (tester) async {
    final b = await _open(tester, delay: 5);
    await _go(tester, 'settings');
    await _tap(tester, find.descendant(of: find.byKey(const Key('protect_pin_set')), matching: find.byType(TextButton)));
    await tester.enterText(find.byKey(const Key('protect_pin_newPin')), '1357');
    await tester.enterText(find.byKey(const Key('protect_pin_again')), '1358');
    await tester.tap(find.byKey(const Key('protect_pin_ok')));
    await tester.pumpAndSettle();
    expect(find.text('The two new PINs are not the same.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('protect_pin_again')), '1357');
    await tester.tap(find.byKey(const Key('protect_pin_ok')));
    await tester.pumpAndSettle();
    expect(b.gate.core.pinSet, isTrue);
    expect(b.store['pin'], isNot(contains('1357')));
    await _tap(tester, find.byKey(const Key('protect_pin_remove')));
    await _typePin(tester, '1357');
    expect(b.gate.core.pinSet, isTrue, reason: 'removing the PIN waits');
    expect(find.textContaining('Remove the PIN: waiting until'), findsOneWidget);
  });

  testWidgets('raising the waiting period with a PIN asks the PIN only', (tester) async {
    final b = await _open(tester, delay: 5, pin: '2468');
    await _go(tester, 'settings');
    await _tap(tester, find.descendant(of: find.byKey(const Key('protect_delay')), matching: find.byType(TextButton)));
    await _tap(tester, find.text('1 hour'));
    expect(find.text('Enter the PIN'), findsOneWidget);
    await _typePin(tester, '2468');
    expect(b.state.settings.protectDelayMinutes, 60);
    expect(b.gate.core.pending(), isNull);
  });

  testWidgets('five wrong PINs lock for 30 s', (tester) async {
    final b = await _open(tester, pin: '2468');
    for (var i = 0; i < 4; i++) {
      expect((await b.invoke('protect.request', {'what': 'stop', 'pin': '0000'}) as Map)['status'], 'pin_wrong');
    }
    final r = await b.invoke('protect.request', {'what': 'stop', 'pin': '0000'}) as Map;
    expect(r['status'], 'locked');
    expect(r['lockedUntil'], b.clock.wall + 30000);
    await _go(tester, 'settings');
    expect(find.textContaining('Too many wrong tries'), findsOneWidget);
  });

  testWidgets('a Stop refused outside the app is asked on the Settings page', (tester) async {
    final b = await _open(tester, pin: '2468');
    b.emit(b.state.copyWith(features: {
      ...b.state.features,
      'protect': {...b.gate.section(), 'prompt': {'id': 1, 'need': 'pin', 'what': 'stop', 'delayMinutes': 0}},
    }));
    await tester.pumpAndSettle();
    expect(find.text('Enter the PIN'), findsOneWidget);
    await _typePin(tester, '2468');
    expect(b.calls, contains('stop'));
  });

  testWidgets('a refusal without the detail changes nothing and says so', (tester) async {
    final b = _Raw(_state());
    await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(find.text('Not now: your protection settings make this change wait, or ask for the PIN.'), findsOneWidget);
    expect(b.state.filter.running, isTrue);
  });

  testWidgets('what protection cannot stop names the right command on each platform', (tester) async {
    for (final (platform, command) in [('android', 'force stop'), ('linux', 'the waaiya command'),
        ('windows', 'the waaiya-filter.exe command')]) {
      await _open(tester, platform: platform);
      await _go(tester, 'settings');
      expect(find.textContaining(command), findsOneWidget, reason: platform);
    }
  });
}

class _Raw extends MemoryBackend {
  _Raw(AppState s) : super(initial: s);
  @override
  Future<void> stopFilter() async => throw const BackendException('protected', 'waiting period');
}
