// The move card (app_move.dart): Waaiya moved from org.islamicmute.app to org.waaiya.app (0.2.15, docs/MOVE.md).
// Hidden when there is nothing to move; in the old app's last version: install the new app (through the updater),
// then open it or remove this one; in the new app while the old one is installed: remove it. Every language fits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

AppState _state(Map<String, Object?>? move, {Map<String, Object?>? update, String language = 'en'}) => AppState(
      platform: 'android',
      language: language,
      settings: const WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      features: {'move': ?move, 'update': ?update},
    );

Map<String, Object?> _update(String state) =>
    {'supported': true, 'state': state, 'canInstall': true, 'progress': state == 'downloading' ? 0.5 : 0.0};

List<String> _record(MemoryBackend b) {
  final calls = <String>[];
  for (final m in ['move.openNew', 'move.removeOld', 'update.start', 'update.check', 'update.openPage']) {
    b.methods[m] = (args) async {
      calls.add(m);
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
}

void main() {
  testWidgets('nothing to move: no card', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    for (final m in [<String, Object?>{'supported': false}, null]) {
      await _open(tester, MemoryBackend(initial: _state(m)));
      expect(find.text(l.moveOldTitle), findsNothing);
      expect(find.text(l.moveNewTitle), findsNothing);
    }
  });

  testWidgets('old app: install the new one through the updater, with its progress', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state({'supported': true, 'kind': 'old', 'newInstalled': false}, update: _update('available')));
    final calls = _record(b);
    await _open(tester, b);
    expect(find.text(l.moveOldTitle), findsOneWidget);
    expect(find.text(l.moveOldBody), findsOneWidget);
    await tester.tap(find.byKey(const Key('move_install')));
    await tester.pumpAndSettle();
    expect(calls, ['update.start']);

    b.emit(_state({'supported': true, 'kind': 'old', 'newInstalled': false}, update: _update('downloading')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text(l.updateDownloading('50%')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('move_install'))).onPressed, isNull); // busy

    // not known yet (offline): check again, or the download page
    b.emit(_state({'supported': true, 'kind': 'old', 'newInstalled': false}, update: _update('idle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('move_install')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('move_page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move_page')));
    await tester.pumpAndSettle();
    expect(calls.last, 'update.openPage');
  });

  testWidgets('old app once the new one is installed: open it, or remove this one', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state({'supported': true, 'kind': 'old', 'newInstalled': true}, update: _update('none')));
    final calls = _record(b);
    await _open(tester, b);
    expect(find.text(l.moveOldInstalled), findsOneWidget);
    expect(find.byKey(const Key('move_install')), findsNothing);
    await tester.tap(find.byKey(const Key('move_open_new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move_remove_this')));
    await tester.pumpAndSettle();
    expect(calls, ['move.openNew', 'move.removeOld']);
  });

  testWidgets('new app with the old one still installed: remove it; says when the settings came over', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state({'supported': true, 'kind': 'new', 'imported': true}));
    final calls = _record(b);
    await _open(tester, b);
    expect(find.text(l.moveNewTitle), findsOneWidget);
    expect(find.text(l.moveNewImported), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('move_remove_old')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move_remove_old')));
    await tester.pumpAndSettle();
    expect(calls, ['move.removeOld']);
    b.emit(_state({'supported': true, 'kind': 'new', 'imported': false}));
    await tester.pumpAndSettle();
    expect(find.text(l.moveNewImported), findsNothing);
  });

  testWidgets('every language on a small phone, both apps, without overflow', (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final move in [
        {'supported': true, 'kind': 'old', 'newInstalled': false},
        {'supported': true, 'kind': 'old', 'newInstalled': true},
        {'supported': true, 'kind': 'new', 'imported': true},
      ]) {
        await _open(tester, MemoryBackend(initial: _state(move, update: _update('available'), language: locale.languageCode)),
            size: const Size(720, 1280));
        final l = await AppLocalizations.delegate.load(locale);
        expect(find.text(move['kind'] == 'new' ? l.moveNewTitle : l.moveOldTitle), findsOneWidget, reason: '${locale.languageCode} $move');
        expect(tester.takeException(), isNull, reason: '${locale.languageCode} $move');
      }
    }
  });
}
