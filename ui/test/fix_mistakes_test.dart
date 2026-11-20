import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/fix_mistakes.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

/// Fix mistakes on the spot (lane A): which parts show where, and that changing the app lists goes through
/// setSetting (where the protection guard sits), including a refusal.
class _Fix extends MemoryBackend {
  _Fix(AppState s, {this.refuse = false}) : super(initial: s) {
    methods['fix.apps'] = (a) async {
      calls.add('apps ${a['list']}');
      return [
        {'package': 'com.video', 'label': 'Video', 'icon': Uint8List.fromList([1, 2, 3])}, // not an image
        {'package': 'com.music', 'label': 'Music'},
        {'package': 'bad,name', 'label': 'Broken'},
      ];
    };
    methods['fix.note'] = (a) async {
      calls.add('note ${a['kind']} ${a['where']}');
      return 3;
    };
    methods['fix.coverArea'] = (_) async {
      calls.add('coverArea');
      return 'opened';
    };
    methods['fix.removeCovers'] = (_) async => calls.add('removeCovers');
    methods['fix.notes'] = (_) async => 'Waaiya notes\n2026-11-20 10:00  missed something';
    methods['fix.clearNotes'] = (_) async => calls.add('clearNotes');
  }

  final bool refuse;
  final calls = <String>[];

  @override
  Future<void> setSetting(String key, Object value) async {
    calls.add('set $key=$value');
    if (refuse) throw const BackendException('protected', 'waiting period');
    return super.setSetting(key, value);
  }
}

const _androidFix = {
  'filterApps': true,
  'blurApps': true,
  'blurAppsReason': null,
  'handCover': true,
  'handCovers': 0,
  'blurRunning': true,
  'notes': 2,
  'labels': {'com.video': 'Video'},
};

AppState _android({Map<Object?, Object?> fix = _androidFix, WaaiyaSettings? settings}) => AppState(
      language: 'en',
      settings: settings ?? const WaaiyaSettings(gender: 'man', blurWomen: true),
      capabilities: Capabilities.android,
      filter: const FilterInfo(state: FilterState.filtering, delayMs: 40),
      features: {'fix': fix},
    );

Future<void> _pump(WidgetTester tester, MemoryBackend b) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: b));
  await tester.pumpAndSettle();
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

void main() {
  testWidgets('nothing shows without the fix section (older native side)', (tester) async {
    await _pump(tester, MemoryBackend(initial: _android(fix: const {})));
    expect(find.byKey(const Key('fix_filter_apps')), findsNothing);
    expect(find.byKey(const Key('fix_notes_filter')), findsNothing);
    await _go(tester, 'screen');
    expect(find.byKey(const Key('fix_blur_apps')), findsNothing);
    expect(find.byKey(const Key('fix_hand')), findsNothing);
    expect(find.byKey(const Key('fix_notes_screen')), findsNothing);
  });

  testWidgets('Android: every part, the notes listed on the Screen page', (tester) async {
    await _pump(tester, _Fix(_android()));
    expect(find.byKey(const Key('fix_filter_apps')), findsOneWidget);
    expect(find.byKey(const Key('fix_notes_filter')), findsOneWidget);
    expect(find.byKey(const Key('fix_notes_count')), findsNothing, reason: 'the count is on the Screen page');
    await _go(tester, 'screen');
    expect(find.byKey(const Key('fix_blur_apps')), findsOneWidget);
    expect(find.byKey(const Key('fix_blur_apps_reason')), findsNothing);
    expect(find.byKey(const Key('fix_hand')), findsOneWidget);
    expect(find.byKey(const Key('fix_remove_covers')), findsNothing);
    expect(find.text('Notes on this device: 2'), findsOneWidget);
  });

  testWidgets('desktop: filter apps and notes on the Filter page; no blur apps, no hand covers', (tester) async {
    await _pump(
        tester,
        _Fix(const AppState(
          platform: 'linux',
          language: 'en',
          settings: WaaiyaSettings(gender: 'man'),
          capabilities: Capabilities(autostart: true),
          features: {
            'fix': {'filterApps': true, 'notes': 1},
          },
        )));
    expect(find.byKey(const Key('nav_screen')), findsNothing);
    expect(find.byKey(const Key('fix_filter_apps')), findsOneWidget);
    expect(find.byKey(const Key('fix_notes_filter')), findsOneWidget);
    expect(find.text('Notes on this device: 1'), findsOneWidget, reason: 'no Screen page: the list is here');
    expect(find.byKey(const Key('fix_blur_apps')), findsNothing);
    expect(find.byKey(const Key('fix_hand')), findsNothing);

    // a desktop with a blur but no hand covers (capability-gated): the Screen page has no "Cover an area"
    await _pump(
        tester,
        _Fix(const AppState(
          platform: 'linux',
          language: 'en',
          settings: WaaiyaSettings(gender: 'man', blurWomen: true),
          capabilities: Capabilities(screenBlur: true, blurStandalone: true),
          features: {
            'fix': {'filterApps': true, 'notes': 0},
          },
        )));
    await _go(tester, 'screen');
    expect(find.byKey(const Key('fix_hand')), findsNothing);
    expect(find.byKey(const Key('fix_cover_area')), findsNothing);
    expect(find.byKey(const Key('fix_notes_screen')), findsOneWidget);
  });

  testWidgets('add and remove an app go through setSetting', (tester) async {
    final b = _Fix(_android(settings: const WaaiyaSettings(gender: 'man', filterOffApps: ['com.video'])));
    await _pump(tester, b);
    expect(find.text('Video'), findsOneWidget, reason: 'the label from the snapshot');
    await _tap(tester, find.byKey(const Key('fix_add_filter_off_apps')));
    expect(find.byKey(const Key('fix_pick_com.video')), findsNothing, reason: 'already chosen');
    expect(find.byKey(const Key('fix_pick_bad,name')), findsNothing, reason: 'a name with a comma is never offered');
    await _tap(tester, find.byKey(const Key('fix_pick_com.music')));
    expect(b.calls, contains('apps filter_off_apps'), reason: 'the picker says which list it fills');
    expect(b.calls, contains('set filter_off_apps=com.music,com.video'));
    expect(b.state.settings.filterOffApps, ['com.music', 'com.video']);

    await _tap(tester, find.byKey(const Key('fix_remove_filter_off_apps_com.video')));
    expect(b.calls.last, 'set filter_off_apps=com.music');
    expect(b.state.settings.filterOffApps, ['com.music']);
  });

  testWidgets('a protected refusal does not crash and changes nothing', (tester) async {
    final b = _Fix(_android(), refuse: true);
    await _pump(tester, b);
    await _go(tester, 'screen');
    await _tap(tester, find.byKey(const Key('fix_add_blur_off_apps')));
    await _tap(tester, find.byKey(const Key('fix_pick_com.video')));
    expect(b.calls, contains('apps blur_off_apps'), reason: 'Android offers system apps such as Settings only here');
    expect(b.calls, contains('set blur_off_apps=com.video'));
    expect(b.state.settings.blurOffApps, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsOneWidget, reason: 'onProtected says so');
  });

  testWidgets('blur apps: where the app on screen cannot be known, disabled with the reason', (tester) async {
    await _pump(
        tester,
        _Fix(_android(fix: {
          ..._androidFix,
          'blurApps': false,
          'blurAppsReason': 'helper_mode',
        })));
    await _go(tester, 'screen');
    expect(find.byKey(const Key('fix_blur_apps_reason')), findsOneWidget);
    expect(find.textContaining("Waaiya's helper"), findsOneWidget);
    final add = tester.widget<ButtonStyleButton>(find.byKey(const Key('fix_add_blur_off_apps')));
    expect(add.onPressed, isNull);
  });

  testWidgets('hand covers and notes call their methods', (tester) async {
    final b = _Fix(_android(fix: {..._androidFix, 'handCovers': 2}));
    await _pump(tester, b);
    await _tap(tester, find.byKey(const Key('fix_note_missed_filter')));
    expect(b.calls, contains('note missed filter'));
    expect(find.text('Noted (3 notes on this device).'), findsOneWidget);
    await _go(tester, 'screen');
    await _tap(tester, find.byKey(const Key('fix_cover_area')));
    expect(b.calls, contains('coverArea'));
    expect(find.text('Remove hand covers (2)'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('fix_remove_covers')));
    expect(b.calls, contains('removeCovers'));
    await _tap(tester, find.byKey(const Key('fix_note_wrong_screen')));
    expect(b.calls, contains('note wrong screen'));
    await _tap(tester, find.byKey(const Key('fix_notes_show')));
    expect(find.byKey(const Key('fix_notes_text')), findsOneWidget);
    expect(find.byKey(const Key('fix_notes_share')), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('fix_notes_delete')));
    await _tap(tester, find.byKey(const Key('fix_notes_delete_yes')));
    expect(b.calls, contains('clearNotes'));
  });

  testWidgets('cover an area is off while the blur does not run', (tester) async {
    await _pump(tester, _Fix(_android(fix: {..._androidFix, 'blurRunning': false})));
    await _go(tester, 'screen');
    final btn = tester.widget<ButtonStyleButton>(find.byKey(const Key('fix_cover_area')));
    expect(btn.onPressed, isNull);
  });

  for (final tag in appLanguages.keys) {
    testWidgets('$tag: the fix cards fit a small phone', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final s = _android(
          fix: {..._androidFix, 'handCovers': 3, 'blurApps': false, 'blurAppsReason': 'helper_mode'},
          settings: const WaaiyaSettings(gender: 'man', blurWomen: true, filterOffApps: ['com.video'], blurOffApps: ['com.x.y']));
      await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: _Fix(AppState(
          language: tag, settings: s.settings, capabilities: s.capabilities, filter: s.filter, features: s.features))));
      await tester.pumpAndSettle();
      for (final page in ['filter', 'screen']) {
        await _go(tester, page);
        final list = find.byType(Scrollable).first;
        for (var i = 0; i < 8; i++) {
          await tester.drag(list, const Offset(0, -500));
          await tester.pumpAndSettle();
        }
      }
      // the picker too
      await _go(tester, 'filter');
      await _tap(tester, find.byKey(const Key('fix_add_filter_off_apps')));
      expect(find.byKey(const Key('fix_pick_com.music')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('list value helper', () {
    expect(fixAppsValue(['b', 'a'], add: 'c'), 'a,b,c');
    expect(fixAppsValue(['b', 'a'], add: 'a'), 'a,b');
    expect(fixAppsValue(['b', 'a'], remove: 'b'), 'a');
    expect(fixAppsValue([], remove: 'x'), '');
    expect(FixApp.fromMap({'package': 'a,b'}), isNull);
    expect(FixApp.fromMap({'package': 'com.x'})!.label, 'com.x');
  });
}
