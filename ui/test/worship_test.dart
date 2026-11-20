// Worship helpers card (lane C, docs/FEATURES_CONTRACT.md): hidden off Android, the place dialog, the switches, the
// plain tones, and every language on a small phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';
import 'package:waaiya_ui/src/worship.dart';

const _methods = [
  'mwl', 'isna', 'egypt', 'umm_al_qura', 'karachi', 'tehran', 'gulf', 'kuwait', //
  'qatar', 'singapore', 'turkey', 'france', 'morocco', 'indonesia', 'malaysia', 'dubai',
];

Map<String, Object?> _worship({bool place = true, bool permissions = true, bool sms = false}) => {
      'supported': true,
      'placeSet': place,
      'placeValid': place,
      'placeLabel': place ? 'Cairo' : null,
      'placeCustom': false,
      'zone': place ? 'Africa/Cairo' : null,
      'deviceZone': 'Africa/Cairo',
      'suggestedMethod': place ? 2 : null,
      'methods': _methods,
      'date': '2026-11-20',
      'times': place
          ? [
              for (final (n, hm) in [
                ('fajr', '04:52'), ('sunrise', '06:20'), ('dhuhr', '11:41'), //
                ('asr', '14:38'), ('maghrib', '17:01'), ('isha', '18:20'),
              ])
                {'name': n, 'hm': hm, 'at': 0},
            ]
          : null,
      'next': place ? {'prayer': 'asr', 'hm': '14:38', 'at': 0} : null,
      'silentUntil': 0,
      'muteUntil': permissions ? 0 : 1,
      'muteUntilHm': permissions ? null : '11:46',
      'dndAccess': permissions,
      'exactAlarms': permissions,
      'notifications': permissions,
      'writeSettings': permissions,
      'tones': [
        for (final (k, n) in [('ring', 1), ('ring', 2), ('ring', 3), ('notification', 1), ('notification', 2), ('notification', 3)])
          {'id': '${k}_$n', 'kind': k, 'number': n},
      ],
      'ringtone': 'ring_2',
      'notificationTone': '',
      'smsSupported': sms,
      'smsPhone': permissions,
      'smsSend': permissions,
      'smsRoaming': false,
      'smsLog': [
        if (sms) {'at': 0, 'hm': '12:03', 'number': '+201001234567'},
      ],
    };

/// Records every feature method; askPermission answers [granted] at once.
List<String> _record(MemoryBackend b, {bool granted = true, Object? setTone}) {
  final calls = <String>[];
  for (final m in ['askPermission', 'unmuteNow', 'endSilentNow', 'openSoundSettings', 'previewTone', 'setTone',
      'cities', 'customPlace']) {
    b.methods['worship.$m'] = (args) async {
      calls.add(m == 'askPermission' ? 'ask ${args['name']}' : m == 'setTone' ? 'setTone ${args['id']}' : m);
      if (m == 'askPermission') return {'id': calls.length, 'done': true, 'granted': granted};
      if (m == 'setTone') return setTone;
      return m == 'cities' ? const [] : null;
    };
  }
  return calls;
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('worship_ask_continue')));
  await tester.pumpAndSettle();
}

AppState _state({String language = 'en', Map<String, Object?>? worship, WaaiyaSettings? settings, String platform = 'android'}) =>
    AppState(
      platform: platform,
      language: language,
      settings: settings ?? const WaaiyaSettings(gender: 'man'),
      capabilities: Capabilities.android,
      features: {'worship': ?worship},
    );

Future<void> _openSettings(WidgetTester tester, MemoryBackend b) async {
  tester.view.physicalSize = const Size(1080, 1920);
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
  test('method keys are in the order Settings.prayerMethod stores (WorshipTimes.METHODS)', () async {
    expect(worshipMethodKeys, _methods);
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(worshipMethodName(l, 3), l.worshipMethodUmmAlQura);
    expect(worshipMethodName(l, 99), l.worshipMethodMwl);
    expect(worshipPrayerName(l, 'maghrib'), l.worshipPrayerMaghrib);
  });

  testWidgets('the card is hidden where the platform has no worship section (desktop)', (tester) async {
    await _openSettings(tester, MemoryBackend(initial: _state(platform: 'linux')));
    expect(find.byKey(const Key('worship_card')), findsNothing);
    // an Android backend that reports it unsupported hides it too
    await _openSettings(tester, MemoryBackend(initial: _state(worship: {'supported': false})));
    expect(find.byKey(const Key('worship_card')), findsNothing);
  });

  testWidgets('no place yet: the switches wait for one', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(worship: _worship(place: false)));
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_silent')));
    expect(find.text(l.worshipPlaceNone), findsOneWidget);
    expect(find.text(l.worshipNeedPlace), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.descendant(of: find.byKey(const Key('worship_silent')),
        matching: find.byType(SwitchListTile))).onChanged, isNull);
  });

  testWidgets('choosing a city sets prayer_place and preselects its country\'s method', (tester) async {
    final b = MemoryBackend(initial: _state(worship: _worship(place: false)));
    final queries = <Object?>[];
    b.methods['worship.cities'] = (args) async {
      queries.add(args['query']);
      final q = '${args['query']}'.toLowerCase();
      return [
        if ('cairo'.contains(q)) {'id': 'cairo', 'name': 'Cairo', 'en': 'Cairo', 'ar': 'القاهرة', 'cc': 'EG', 'tz': 'Africa/Cairo', 'method': 2},
        if ('istanbul'.contains(q)) {'id': 'istanbul', 'name': 'Istanbul', 'en': 'Istanbul', 'ar': 'إسطنبول', 'cc': 'TR', 'tz': 'Europe/Istanbul', 'method': 10},
      ];
    };
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_place')));
    await tester.tap(find.descendant(of: find.byKey(const Key('worship_place')), matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('worship_city_istanbul')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('worship_place_search')), 'cai');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(queries.last, 'cai');
    expect(find.byKey(const Key('worship_city_istanbul')), findsNothing);
    await tester.tap(find.byKey(const Key('worship_city_cairo')));
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerPlace, 'cairo');
    expect(b.state.settings.prayerMethod, 2);
  });

  testWidgets('coordinates: checked natively, then saved as the place; the method is left alone', (tester) async {
    final b = MemoryBackend(initial: _state(worship: _worship(place: false), settings: const WaaiyaSettings(gender: 'man', prayerMethod: 4)));
    b.methods['worship.cities'] = (args) async => const [];
    Map<String, Object?>? asked;
    b.methods['worship.customPlace'] = (args) async {
      asked = args;
      if (args['tz'] != 'Asia/Karachi') throw const BackendException('bad_args', 'tz');
      return 'custom:24.8600,67.0100,Asia/Karachi';
    };
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_place')));
    await tester.tap(find.descendant(of: find.byKey(const Key('worship_place')), matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('worship_place_custom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('worship_lat')), '24,86');
    await tester.enterText(find.byKey(const Key('worship_lon')), '67.01');
    await tester.enterText(find.byKey(const Key('worship_tz')), 'Nowhere/Town');
    await tester.tap(find.byKey(const Key('worship_custom_ok')));
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.worshipCustomInvalid), findsOneWidget);
    expect(b.state.settings.prayerPlace, '');
    await tester.enterText(find.byKey(const Key('worship_tz')), 'Asia/Karachi');
    await tester.tap(find.byKey(const Key('worship_custom_ok')));
    await tester.pumpAndSettle();
    expect(asked, {'lat': 24.86, 'lon': 67.01, 'tz': 'Asia/Karachi'});
    expect(b.state.settings.prayerPlace, 'custom:24.8600,67.0100,Asia/Karachi');
    expect(b.state.settings.prayerMethod, 4);
  });

  testWidgets('the switches and minutes call setSetting; method and Asr are the user\'s choice', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(worship: _worship(), settings: const WaaiyaSettings(gender: 'man', prayerPlace: 'cairo', prayerMethod: 2)));
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_times')));
    expect(find.text('11:41'), findsOneWidget);
    expect(find.text(l.worshipPlace('Cairo')), findsOneWidget);
    expect(find.text(l.worshipMethod(l.worshipMethodEgypt)), findsOneWidget);

    await _show(tester, find.byKey(const Key('worship_silent')));
    await tester.tap(find.byKey(const Key('worship_silent')));
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerSilent, isTrue);
    await _show(tester, find.byKey(const Key('worship_mute')));
    await tester.tap(find.byKey(const Key('worship_mute')));
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerAdhanMute, isTrue);
    expect(find.text(l.worshipNext(l.worshipPrayerAsr, '14:38')), findsOneWidget);

    await _show(tester, find.byKey(const Key('worship_silent_minutes')));
    await tester.tap(find.descendant(of: find.byKey(const Key('worship_silent_minutes')), matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.worshipMinutesOption(45)));
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerSilentMinutes, 45);

    await _show(tester, find.byKey(const Key('worship_asr')));
    await tester.tap(find.descendant(of: find.byKey(const Key('worship_asr')), matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.worshipAsrHanafi).last);
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerAsr, 1);

    await _show(tester, find.byKey(const Key('worship_method')));
    await tester.tap(find.descendant(of: find.byKey(const Key('worship_method')), matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l.worshipMethodTurkey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.worshipMethodTurkey));
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerMethod, 10);

    await _show(tester, find.byKey(const Key('worship_silent')));
    await tester.tap(find.byKey(const Key('worship_silent')));
    await tester.pumpAndSettle();
    expect(b.state.settings.prayerSilent, isFalse);
  });

  testWidgets('the card asks for nothing by itself: not when it first shows, not while scrolling', (tester) async {
    final b = MemoryBackend(initial: _state(
        worship: _worship(permissions: false, sms: true),
        settings: const WaaiyaSettings(gender: 'man', prayerPlace: 'cairo')));
    final calls = _record(b);
    await _openSettings(tester, b);
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 10; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('worship_sms_switch')), findsOneWidget);
    expect(calls, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('turning on the SMS reply asks Phone, then SMS, each after one sentence, then turns it on', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(
        worship: _worship(permissions: false, sms: true),
        settings: const WaaiyaSettings(gender: 'man', prayerPlace: 'cairo')));
    final calls = _record(b);
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_sms_switch')));
    await tester.tap(find.byKey(const Key('worship_sms_switch')));
    await tester.pumpAndSettle();
    expect(find.text(l.worshipWhyPhone), findsOneWidget);
    expect(calls, isEmpty);  // nothing before the sentence is read
    await _continue(tester);
    expect(find.text(l.worshipWhySms), findsOneWidget);
    await _continue(tester);
    expect(calls, ['ask phone', 'ask sms']);
    expect(b.state.settings.prayerSmsReply, isTrue);
  });

  testWidgets('a refused permission leaves the switch off, says which one, and offers Try again', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(
        worship: _worship(permissions: false, sms: true),
        settings: const WaaiyaSettings(gender: 'man', prayerPlace: 'cairo')));
    final calls = _record(b);
    // Android's question is open (done: false); the answer comes back in the snapshot's `ask`
    b.methods['worship.askPermission'] = (args) async {
      calls.add('ask ${args['name']}');
      return {'id': 7, 'done': false, 'granted': false};
    };
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_sms_switch')));
    await tester.tap(find.byKey(const Key('worship_sms_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('worship_ask_continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));  // the question is open; the user answers
    b.emit(b.state.copyWith(features: {
      'worship': {..._worship(permissions: false, sms: true), 'ask': {'id': 7, 'name': 'phone', 'done': true, 'granted': false}},
    }));
    await tester.pumpAndSettle();
    expect(calls, ['ask phone']);
    expect(b.state.settings.prayerSmsReply, isFalse);
    await _show(tester, find.byKey(const Key('worship_sms_missing')));
    expect(find.text(l.worshipMissingPhone), findsOneWidget);
    expect(find.text(l.worshipTryAgain), findsOneWidget);

    // the silence: Do Not Disturb access refused -> the switch stays off
    b.methods['worship.askPermission'] = (args) async {
      calls.add('ask ${args['name']}');
      return {'id': 8, 'done': true, 'granted': false};
    };
    await _show(tester, find.byKey(const Key('worship_silent')));
    await tester.tap(find.byKey(const Key('worship_silent')));
    await tester.pumpAndSettle();
    expect(find.text(l.worshipWhyDnd), findsOneWidget);
    await _continue(tester);
    expect(calls.last, 'ask dnd');
    expect(b.state.settings.prayerSilent, isFalse);
    expect(find.text(l.worshipMissingDnd), findsOneWidget);
  });

  testWidgets('turning on the silence asks Do Not Disturb, then exact alarms and notifications', (tester) async {
    final b = MemoryBackend(initial: _state(
        worship: _worship(permissions: false),
        settings: const WaaiyaSettings(gender: 'man', prayerPlace: 'cairo')));
    final calls = _record(b);
    await _openSettings(tester, b);
    await _show(tester, find.byKey(const Key('worship_silent')));
    await tester.tap(find.byKey(const Key('worship_silent')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await _continue(tester);
    }
    expect(calls, ['ask dnd', 'ask exact', 'ask notifications']);
    expect(b.state.settings.prayerSilent, isTrue);
  });

  testWidgets('permissions taken back later: Allow asks again; Unmute now; a refused tone opens Sound settings', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final b = MemoryBackend(initial: _state(
        worship: _worship(permissions: false),
        settings: const WaaiyaSettings(gender: 'man', prayerPlace: 'cairo', prayerSilent: true, prayerAdhanMute: true)));
    final calls = _record(b, setTone: 'failed');
    await _openSettings(tester, b);
    for (final (key, name) in [('worship_dnd', 'dnd'), ('worship_exact', 'exact'), ('worship_notifications', 'notifications')]) {
      await _show(tester, find.byKey(Key(key)));
      await tester.tap(find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextButton)));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(calls.last, 'ask $name');
    }
    await _show(tester, find.text(l.worshipUnmute));
    await tester.tap(find.text(l.worshipUnmute));
    await tester.pumpAndSettle();
    expect(calls.last, 'unmuteNow');

    await _show(tester, find.byKey(const Key('worship_play_ring_1')));
    await tester.tap(find.byKey(const Key('worship_play_ring_1')));
    await tester.pumpAndSettle();
    expect(calls.last, 'previewTone');
    // ring_2 is the phone's ringtone already: no button there
    expect(find.byKey(const Key('worship_use_ring_2')), findsNothing);
    expect(find.text(l.worshipToneInUse), findsOneWidget);
    await _show(tester, find.byKey(const Key('worship_use_notification_1')));
    await tester.tap(find.byKey(const Key('worship_use_notification_1')));
    await tester.pumpAndSettle();
    expect(find.text(l.worshipWhyWrite), findsOneWidget);  // "Modify system settings" only now
    await _continue(tester);
    expect(calls.sublist(calls.length - 2), ['ask write', 'setTone notification_1']);
    expect(find.text(l.worshipToneFailed), findsOneWidget);
    await tester.tap(find.byKey(const Key('worship_open_sound')));
    await tester.pumpAndSettle();
    expect(calls.last, 'openSoundSettings');
  });

  for (final tag in appLanguages.keys) {
    testWidgets('$tag: the card with everything on fits a small phone', (tester) async {
      final b = MemoryBackend(initial: _state(
          language: tag,
          worship: _worship(permissions: false, sms: true),
          settings: const WaaiyaSettings(
              gender: 'man', prayerPlace: 'cairo', prayerSilent: true, prayerAdhanMute: true, prayerSmsReply: true)));
      await _openSettings(tester, b);
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
