// Release audit of every screen (before 0.2.13): every language, on a phone and on Windows and Linux, with the
// optional parts switched on (prayer times, apps heard unfiltered, protection with a change waiting), at the normal
// text size and at the large sizes people choose in their phone's settings. Fails on any text that overflows.
// Then Flutter's accessibility checks on each page, in light and dark: buttons big enough to tap (48 x 48),
// every button named for screen readers, and enough contrast between text and background.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

const _windows = Capabilities(
    screenBlur: true, links: true, womenSinging: true, autostart: true, blurStandalone: true, linkPage: true);
const _linux = Capabilities(
    screenBlur: true,
    links: true,
    womenSinging: true,
    autostart: true,
    blurStandalone: true,
    linkPage: true,
    linkSave: true);

Map<String, Object?> _worship() => {
      'supported': true,
      'placeSet': true,
      'placeValid': true,
      'placeLabel': 'Cairo',
      'placeCustom': false,
      'zone': 'Africa/Cairo',
      'deviceZone': 'Africa/Cairo',
      'suggestedMethod': 2,
      'methods': ['mwl', 'egypt', 'umm_al_qura'],
      'date': '2026-11-20',
      'times': [
        for (final (n, hm) in [
          ('fajr', '04:52'), ('sunrise', '06:20'), ('dhuhr', '11:41'), //
          ('asr', '14:38'), ('maghrib', '17:01'), ('isha', '18:20'),
        ])
          {'name': n, 'hm': hm, 'at': 0},
      ],
      'next': {'prayer': 'asr', 'hm': '14:38', 'at': 0},
      'silentUntil': 0,
      'muteUntil': 0,
      'dndAccess': false,
      'exactAlarms': false,
      'notifications': false,
      'writeSettings': true,
      'tones': [
        for (final (k, n) in [('ring', 1), ('ring', 2), ('notification', 1)]) {'id': '${k}_$n', 'kind': k, 'number': n},
      ],
      'ringtone': 'ring_2',
      'notificationTone': '',
      'smsSupported': true,
      'smsPhone': true,
      'smsSend': true,
      'smsRoaming': false,
      'smsLog': [
        {'at': 0, 'hm': '12:03', 'number': '+201001234567'},
      ],
    };

Map<String, Object?> _protect() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return {
    'pinSet': true,
    'delayMinutes': 30,
    'pending': {'what': 'stop', 'value': null, 'dueAt': now + 1800000, 'confirmUntil': now + 2700000, 'ready': false},
    'lockedUntil': null,
  };
}

/// The most text each platform can show at once.
AppState _rich(String platform, String language) {
  final android = platform == 'android';
  return AppState(
    platform: platform,
    language: language,
    settings: WaaiyaSettings(
      gender: 'man',
      blurWomen: true,
      muteWomenSinging: true,
      protectDelayMinutes: 30,
      filterOffApps: android ? const ['com.video'] : const ['telegram.exe'],
      blurOffApps: android ? const ['com.video'] : const [],
      prayerSilent: true,
      prayerAdhanMute: true,
      prayerSmsReply: true,
    ),
    capabilities: android ? Capabilities.android : (platform == 'windows' ? _windows : _linux),
    filter: const FilterInfo(state: FilterState.filtering, delayMs: 40),
    setup: android
        ? const SetupInfo(
            originalsMuted: false,
            consentSkipped: false,
            wireless: WirelessInfo(supported: true, devOptions: false, wifi: false, aboutHint: 'samsung'),
          )
        : const SetupInfo(),
    features: {
      'fix': android
          ? {
              'filterApps': true,
              'blurApps': true,
              'handCover': true,
              'handCovers': 2,
              'blurRunning': true,
              'notes': 3,
              'labels': {'com.video': 'Video player'},
            }
          : {
              'filterApps': true,
              'notes': 3,
              'labels': {'telegram.exe': 'Telegram Desktop'},
            },
      if (android) 'worship': _worship(),
      'protect': _protect(),
    },
  );
}

Future<void> _open(WidgetTester tester, AppState s, {required Size dp, double text = 1, bool dark = true}) async {
  tester.view.physicalSize = dp * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(WaaiyaApp(key: UniqueKey(), backend: MemoryBackend(initial: s)));
  await tester.pumpAndSettle();
}

List<String> _pages(WidgetTester tester) => [
      for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('nav_')).evaluate())
        (e.widget.key! as ValueKey<String>).value,
    ];

/// Every page, scrolled from top to bottom so that each part is laid out.
Future<void> _visitAll(WidgetTester tester, Future<void> Function(String page)? onPage) async {
  for (final nav in _pages(tester)) {
    await tester.tap(find.byKey(Key(nav)));
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await onPage?.call('$nav ${i * 400}');
      await tester.drag(list, const Offset(0, -400), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }
}

const _languages = [
  'ar', 'en', 'fr', 'ur', 'id', 'tr', 'bn', 'fa', 'ms', 'es', 'nl', 'de', 'it', 'ru', 'uz', 'sw', 'ha', 'so', //
];

void main() {
  // Phone: a small one (360 x 640 dp). Computer: a small window (800 x 600). Text: normal and the large sizes.
  final sizes = {'android': const Size(360, 640), 'windows': const Size(800, 600), 'linux': const Size(800, 600)};
  for (final platform in sizes.keys) {
    for (final text in [1.0, 1.3, 2.0]) {
      testWidgets('$platform, text x$text: every page in every language without overflow', (tester) async {
        final problems = <String>[];
        for (final lang in _languages) {
          await _open(tester, _rich(platform, lang), dp: sizes[platform]!, text: text);
          await _visitAll(tester, (where) async {
            final e = tester.takeException();
            if (e != null) problems.add('$lang $where: ${e.toString().split('\n').first}');
          });
          final e = tester.takeException();
          if (e != null) problems.add('$lang: ${e.toString().split('\n').first}');
        }
        expect(problems, isEmpty, reason: problems.take(30).join('\n'));
      });
    }
  }

  for (final platform in sizes.keys) {
    for (final dark in [true, false]) {
      for (final lang in ['en', 'ar']) {
        testWidgets('$platform ${dark ? 'dark' : 'light'} $lang: tap targets, labels, contrast', (tester) async {
          final handle = tester.ensureSemantics();
          final problems = <String>[];
          await _open(tester, _rich(platform, lang), dp: sizes[platform]!, dark: dark);
          await _visitAll(tester, (where) async {
            for (final (name, g) in [
              ('tap target', androidTapTargetGuideline),
              ('label', labeledTapTargetGuideline),
              ('contrast', textContrastGuideline),
            ]) {
              final r = await g.evaluate(tester);
              if (!r.passed) problems.add('$where $name: ${r.reason}');
            }
          });
          handle.dispose();
          final unique = problems.map((p) => p.substring(p.indexOf(' ', p.indexOf(' ') + 1) + 1)).toSet();
          expect(unique, isEmpty, reason: unique.take(40).join('\n---\n'));
        });
      }
    }
  }

  // The dialogs at the largest text on a small phone: the wait picker and the PIN dialog.
  testWidgets('android, text x2.0: the dialogs in every language without overflow', (tester) async {
    final problems = <String>[];
    Future<void> dialog(String lang, String what, Finder opener) async {
      await tester.scrollUntilVisible(opener, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(opener);
      await tester.pumpAndSettle();
      final e = tester.takeException();
      if (e != null) problems.add('$lang $what: ${e.toString().split('\n').first}');
      // every dialog's scrollable content, to its end
      for (final s in find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable)).evaluate().toList()) {
        await tester.drag(find.byWidget(s.widget), const Offset(0, -2000), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      final e2 = tester.takeException();
      if (e2 != null) problems.add('$lang $what scrolled: ${e2.toString().split('\n').first}');
      Navigator.of(tester.element(find.byType(Dialog).last)).pop();
      await tester.pumpAndSettle();
    }

    for (final lang in _languages) {
      await _open(tester, _rich('android', lang), dp: sizes['android']!, text: 2);
      await tester.tap(find.byKey(const Key('nav_settings')));
      await tester.pumpAndSettle();
      await dialog(lang, 'wait', find.descendant(of: find.byKey(const Key('protect_delay')), matching: find.byType(TextButton)));
      await dialog(lang, 'pin', find.byKey(const Key('protect_pin_change')));
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  // A computer is not a phone: no screen of the Windows or Linux app talks about "this phone" (first launch included).
  for (final platform in ['windows', 'linux']) {
    testWidgets('$platform: no text speaks of a phone', (tester) async {
      final found = <String>{};
      void collect() {
        for (final e in find.byType(RichText).evaluate()) {
          final t = (e.widget as RichText).text.toPlainText();
          if (RegExp(r'\bphones?\b', caseSensitive: false).hasMatch(t)) found.add(t);
        }
      }

      await _open(tester, AppState(platform: platform, language: 'en'), dp: sizes[platform]!);
      collect();
      await _open(tester, _rich(platform, 'en'), dp: sizes[platform]!);
      await _visitAll(tester, (_) async => collect());
      expect(found, isEmpty, reason: found.join('\n'));
    });
  }
}
