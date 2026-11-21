// The Updates card (app_update.dart): hidden where the store updates the app, the states, the patch size line, the
// buttons, and every language on a small phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/app_update.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

Map<String, Object?> _update(String state, {bool patch = true, bool canInstall = true, String? error}) => {
      'supported': true,
      'auto': true,
      'state': state,
      'current': '0.2.14',
      'latest': state == 'none' || state == 'idle' ? null : '0.2.15',
      'notes': {'en': 'A new logo.', 'ar': 'شعار جديد.'},
      'download': patch ? 6 * 1048576 : 108 * 1048576,
      'full': 108 * 1048576,
      'patch': patch,
      'progress': state == 'downloading' ? 0.42 : 0.0,
      'error': error,
      'canInstall': canInstall,
      'page': 'https://waaiya.mssid.org/#download',
    };

AppState _state(Map<String, Object?>? update, {String language = 'en'}) => AppState(
      platform: 'android',
      language: language,
      settings: const WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      features: {'update': ?update},
    );

List<String> _record(MemoryBackend b) {
  final calls = <String>[];
  for (final m in ['check', 'setAuto', 'start', 'openPage']) {
    b.methods['update.$m'] = (args) async {
      calls.add(m == 'setAuto' ? 'setAuto ${args['on']}' : m);
      return null;
    };
  }
  return calls;
}

Future<void> _open(WidgetTester tester, MemoryBackend b, {Size size = const Size(1080, 1920)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav_settings')));
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  test('sizes read like the notification', () {
    expect(UpdateCard.size(6 * 1048576), '6.0 MB');
    expect(UpdateCard.size(108 * 1048576), '108 MB');
  });

  testWidgets('hidden when the build has no updater (store builds)', (tester) async {
    await _open(tester, MemoryBackend(initial: _state({'supported': false})));
    expect(find.byKey(const Key('update_card')), findsNothing);
    await _open(tester, MemoryBackend(initial: _state(null)));
    expect(find.byKey(const Key('update_card')), findsNothing);
  });

  testWidgets('up to date: check now and the daily switch', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(_update('none')));
    final calls = _record(b);
    await _open(tester, b);
    await _show(tester, find.byKey(const Key('update_check')));
    expect(find.text(l.updateNone('0.2.14')), findsOneWidget);
    expect(find.byKey(const Key('update_now')), findsNothing);
    await tester.tap(find.byKey(const Key('update_check')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byKey(const Key('update_auto')), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(calls, ['check', 'setAuto false']);
  });

  testWidgets('a new version: notes, only the changes to download, update now', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(_update('available')));
    final calls = _record(b);
    await _open(tester, b);
    await _show(tester, find.byKey(const Key('update_now')));
    expect(find.text(l.updateAvailable('0.2.15', '0.2.14')), findsOneWidget);
    expect(find.text('A new logo.'), findsOneWidget);
    expect(find.text(l.updateSizePatch('6.0 MB', '108 MB')), findsOneWidget);
    expect(find.text(l.updateStopsFilter), findsOneWidget);
    await tester.tap(find.byKey(const Key('update_now')));
    await tester.pumpAndSettle();
    expect(calls, ['start']);
  });

  testWidgets('downloading shows the progress and disables the button; a failure offers the page', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    await _open(tester, MemoryBackend(initial: _state(_update('downloading'))));
    await _show(tester, find.byKey(const Key('update_now')));
    expect(find.text(l.updateDownloading('42%')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('update_now'))).onPressed, isNull);

    final b = MemoryBackend(initial: _state(_update('error', patch: false, error: 'failed')));
    final calls = _record(b);
    await _open(tester, b);
    await _show(tester, find.byKey(const Key('update_page')));
    expect(find.text(l.updateFailed), findsOneWidget);
    expect(find.text(l.updateSizeFull('108 MB')), findsOneWidget);
    await tester.tap(find.byKey(const Key('update_page')));
    await tester.pumpAndSettle();
    expect(calls, ['openPage']);
  });

  testWidgets('desktop notice: no install button, the download page instead', (tester) async {
    final b = MemoryBackend(initial: _state(_update('available', canInstall: false)));
    await _open(tester, b);
    await _show(tester, find.byKey(const Key('update_page')));
    expect(find.byKey(const Key('update_now')), findsNothing);
  });

  testWidgets('every language fits a small phone', (tester) async {
    for (final lang in AppLocalizations.supportedLocales.map((e) => e.languageCode)) {
      await _open(tester, MemoryBackend(initial: _state(_update('available'), language: lang)), size: const Size(720, 1280));
      await _show(tester, find.byKey(const Key('update_now')));
      expect(tester.takeException(), isNull, reason: lang);
    }
  });
}
