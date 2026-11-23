import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';
import 'package:waaiya_ui/src/protection_core.dart';

/// The icon next to the clock (Windows): what the screens send the runner (desktop/windows/runner/tray.cpp), and
/// Start / Stop chosen there, Stop held back by the waiting period like the power button.
class _Clock implements ProtectionClock {
  @override
  int wallMs() => 1000000;
  @override
  int elapsedMs() => 1000000;
  @override
  String bootId() => 'b1';
}

class _Backend extends MemoryBackend {
  _Backend(AppState s) : super(initial: s) {
    gate = ProtectionGate(
      ProtectionCore(
        store: <String, Object?>{},
        clock: _Clock(),
        delayMinutes: () => state.settings.protectDelayMinutes,
        current: (k) => state.settings.toMap()[k],
        iterations: 50,
      ),
      apply: (what, v) async => what == 'stop' ? super.stopFilter() : super.setSetting(what, v!),
      changed: () {},
    );
    methods.addAll(gate.methods);
  }

  late final ProtectionGate gate;

  @override
  Future<void> stopFilter() async {
    gate.checkStop();
    await super.stopFilter();
  }
}

const _tray = MethodChannel('waaiya/tray');

AppState _state({required bool tray, bool on = true, int delay = 0}) => AppState(
      language: 'en',
      platform: 'windows',
      settings: WaaiyaSettings(gender: 'man', protectDelayMinutes: delay),
      capabilities: Capabilities(autostart: true, tray: tray),
      filter: FilterInfo(state: on ? FilterState.filtering : FilterState.stopped),
    );

Future<(_Backend, List<Map<Object?, Object?>>)> _open(WidgetTester tester, AppState s) async {
  final sent = <Map<Object?, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_tray, (call) async {
    if (call.method == 'update') sent.add(call.arguments as Map<Object?, Object?>);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_tray, null));
  final b = _Backend(s);
  await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
  await tester.pumpAndSettle();
  return (b, sent);
}

/// The runner sends what was chosen in the menu (not awaited: a Stop held back answers once its dialog is closed).
Future<void> _choose(WidgetTester tester, String action) async {
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      _tray.name, _tray.codec.encodeMethodCall(MethodCall('action', action)), (_) {});
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the menu in the app language, with the state; sent again when the filter stops', (tester) async {
    final (b, sent) = await _open(tester, _state(tray: true));
    expect(sent, isNotEmpty);
    expect(sent.last, {
      'tooltip': 'Waaiya',
      'open': 'Open Waaiya',
      'start': 'Start filtering',
      'stop': 'Stop filtering',
      'quit': 'Quit',
      'on': true,
      'rtl': false,
    });
    final n = sent.length;
    await b.stopFilter();
    await tester.pumpAndSettle();
    expect(sent.length, n + 1);
    expect(sent.last['on'], isFalse);
  });

  testWidgets('Arabic: the menu right to left', (tester) async {
    final (_, sent) = await _open(tester, _state(tray: true).copyWith(language: 'ar'));
    expect(sent.last['rtl'], isTrue);
    expect(sent.last['quit'], 'خروج');
  });

  testWidgets('no tray (Android, Linux): nothing is sent', (tester) async {
    final (_, sent) = await _open(tester, _state(tray: false));
    expect(sent, isEmpty);
  });

  testWidgets('Start and Stop from the menu', (tester) async {
    final (b, sent) = await _open(tester, _state(tray: true, on: false));
    await _choose(tester, 'start');
    expect(b.state.filter.running, isTrue);
    expect(sent.last['on'], isTrue);
    await _choose(tester, 'stop');
    expect(b.state.filter.running, isFalse);
  });

  testWidgets('Stop from the menu waits like the power button (waiting period)', (tester) async {
    final (b, _) = await _open(tester, _state(tray: true, delay: 5));
    await _choose(tester, 'stop');
    expect(b.state.filter.running, isTrue);
    expect(find.byKey(const Key('protect_wait_start')), findsOneWidget);
  });
}
