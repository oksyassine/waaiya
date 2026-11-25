/// Worship helpers (docs/FEATURES_CONTRACT.md, lane C): silent at prayer times, media muted at the adhan, plain
/// tones. Snapshot section `worship`, methods `worship.*`. Off by default.
///
/// The prayer times, the place list and the alarms are native (Android: Worship*.kt); this card only shows the
/// snapshot's facts and calls the methods. Platforms without the section (desktop) do not show the card.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'widgets.dart';
import 'worship_place.dart';
import 'worship_sms.dart';
import 'worship_tones.dart';

/// One prayer time of today at the place: `name` is fajr, sunrise, dhuhr, asr, maghrib or isha.
class WorshipTime {
  const WorshipTime(this.name, this.hm, this.at);
  final String name;
  final String hm;
  final int at;
}

/// A typed view of the snapshot's `features.worship` (Worship.kt documents every key).
class WorshipInfo {
  WorshipInfo(this.m);

  final Map<Object?, Object?> m;

  bool _b(String k) => m[k] == true;
  String? _s(String k) => m[k] is String ? m[k] as String : null;
  int _i(String k) => m[k] is num ? (m[k] as num).toInt() : 0;

  /// False off Android: the card is hidden.
  bool get supported => _b('supported');
  bool get placeSet => _b('placeSet');
  bool get placeValid => _b('placeValid');
  String? get placeLabel => _s('placeLabel');
  bool get placeCustom => _b('placeCustom');

  /// Coordinates near a listed city: its name ("near Paris"); null otherwise.
  String? get placeNear => _s('placeNear');

  /// The place is one of the Ministry of Habous's cities with Morocco's method: the times are its official table.
  bool get habous => _b('habous');
  bool get location => _b('location');
  String? get zone => _s('zone');
  String? get deviceZone => _s('deviceZone');
  int? get suggestedMethod => m['suggestedMethod'] is int ? m['suggestedMethod'] as int : null;
  List<String> get methods => m['methods'] is List ? (m['methods'] as List).whereType<String>().toList() : const [];
  String? get date => _s('date');

  /// Null: no place, or no sunrise or sunset today at the place.
  List<WorshipTime>? get times => m['times'] is List
      ? [
          for (final t in (m['times'] as List).whereType<Map>())
            WorshipTime('${t['name']}', '${t['hm']}', t['at'] is int ? t['at'] as int : 0),
        ]
      : null;

  /// The next prayer that will act: (prayer key, "HH:mm"), or null.
  (String, String)? get next {
    final n = m['next'];
    return n is Map && n['prayer'] is String && n['hm'] is String ? (n['prayer'] as String, n['hm'] as String) : null;
  }

  int get silentUntil => _i('silentUntil');
  String? get silentUntilHm => _s('silentUntilHm');
  int get muteUntil => _i('muteUntil');
  String? get muteUntilHm => _s('muteUntilHm');
  bool get dndAccess => _b('dndAccess');
  bool get exactAlarms => _b('exactAlarms');
  bool get notifications => _b('notifications');
  bool get writeSettings => _b('writeSettings');

  /// Plain tones: (id, kind `ring` or `notification`, number).
  List<(String, String, int)> get tones => m['tones'] is List
      ? [
          for (final t in (m['tones'] as List).whereType<Map>())
            ('${t['id']}', '${t['kind']}', t['number'] is int ? t['number'] as int : 0),
        ]
      : const [];
  String get ringtone => _s('ringtone') ?? '';
  bool get smsSupported => _b('smsSupported');
  bool get smsPhone => _b('smsPhone');
  bool get smsSend => _b('smsSend');
  bool get smsRoaming => _b('smsRoaming');

  /// SMS replies sent, newest first: ("HH:mm", number).
  List<(String, String)> get smsLog => m['smsLog'] is List
      ? [for (final e in (m['smsLog'] as List).whereType<Map>()) ('${e['hm']}', '${e['number']}')]
      : const [];

  /// Whether the permission named as in `worship.askPermission` is allowed now.
  bool allowed(String name) => switch (name) {
        'dnd' => dndAccess,
        'exact' => exactAlarms,
        'notifications' => notifications,
        'write' => writeSettings,
        'phone' => smsPhone,
        'sms' => smsSend,
        'location' => location,
        _ => false,
      };
  String get notificationTone => _s('notificationTone') ?? '';
}

/// The prayer's name in the app's language.
String worshipPrayerName(AppLocalizations l, String key) => switch (key) {
      'fajr' => l.worshipPrayerFajr,
      'sunrise' => l.worshipPrayerSunrise,
      'dhuhr' => l.worshipPrayerDhuhr,
      'asr' => l.worshipPrayerAsr,
      'maghrib' => l.worshipPrayerMaghrib,
      _ => l.worshipPrayerIsha,
    };

/// Method keys in Settings.prayerMethod order (WorshipTimes.METHODS); the snapshot's `methods` must match.
const worshipMethodKeys = [
  'mwl', 'isna', 'egypt', 'umm_al_qura', 'karachi', 'tehran', 'gulf', 'kuwait', //
  'qatar', 'singapore', 'turkey', 'france', 'morocco', 'indonesia', 'malaysia', 'dubai',
];

String worshipMethodName(AppLocalizations l, int index) =>
    switch (index >= 0 && index < worshipMethodKeys.length ? worshipMethodKeys[index] : 'mwl') {
      'isna' => l.worshipMethodIsna,
      'egypt' => l.worshipMethodEgypt,
      'umm_al_qura' => l.worshipMethodUmmAlQura,
      'karachi' => l.worshipMethodKarachi,
      'tehran' => l.worshipMethodTehran,
      'gulf' => l.worshipMethodGulf,
      'kuwait' => l.worshipMethodKuwait,
      'qatar' => l.worshipMethodQatar,
      'singapore' => l.worshipMethodSingapore,
      'turkey' => l.worshipMethodTurkey,
      'france' => l.worshipMethodFrance,
      'morocco' => l.worshipMethodMorocco,
      'indonesia' => l.worshipMethodIndonesia,
      'malaysia' => l.worshipMethodMalaysia,
      'dubai' => l.worshipMethodDubai,
      _ => l.worshipMethodMwl,
    };

const worshipSilentMinutes = [5, 10, 15, 20, 25, 30, 40, 45, 60, 90];
const worshipMuteMinutes = [1, 2, 3, 5, 10, 15, 20, 30];

/// Asks Android for one permission ([WorshipInfo.allowed] names), only because the user just turned on the option
/// that needs it: one sentence saying why ([why]), then Android's question or settings page
/// (`worship.askPermission`), then waits until the user is back. True when allowed. Nothing is ever asked without
/// such a tap (owner's decision, 2026-11-20).
Future<bool> worshipAsk(BuildContext context, String name, String why) async {
  final backend = WaaiyaScope.of(context).backend;
  if (WorshipInfo((await backend.getState()).feature('worship')).allowed(name)) return true;
  if (!context.mounted) return false;
  final l = AppLocalizations.of(context);
  final go = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      scrollable: true, // large text on a small screen: nothing is cut off
      content: Text(why),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel)),
        TextButton(key: const Key('worship_ask_continue'), onPressed: () => Navigator.pop(dialog, true), child: Text(l.worshipContinue)),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  // listen before asking, so that a quick answer cannot slip by
  Map<Object?, Object?>? last;
  Object? wanted;
  final back = Completer<void>();
  bool matches(Map<Object?, Object?>? a) => a != null && wanted != null && a['id'] == wanted && a['done'] == true;
  final sub = backend.states.listen((s) {
    final a = s.feature('worship')['ask'];
    if (a is Map) last = a;
    if (matches(last) && !back.isCompleted) back.complete();
  });
  try {
    final r = await runAction(context, (b) => b.invoke('worship.askPermission', {'name': name}));
    if (r is! Map) return false;
    if (r['done'] == true) return r['granted'] == true;
    // Android's question or page is open: the snapshot's `ask` says when the user is back
    wanted = r['id'];
    if (!matches(last)) await back.future.timeout(const Duration(minutes: 5));
    return last?['granted'] == true;
  } on TimeoutException {
    return false;
  } finally {
    unawaited(sub.cancel());  // not awaited: a generator-backed stream may finish its cancel only later
  }
}

/// Settings page, under the general settings: place, method, Asr rule, today's times, the switches with their
/// minutes, what the phone still has to allow, the SMS reply during prayer, and the plain tones.
class WorshipCard extends StatefulWidget {
  const WorshipCard({super.key});

  @override
  State<WorshipCard> createState() => _WorshipCardState();
}

class _WorshipCardState extends State<WorshipCard> {
  /// The permission refused when the user last turned an option on (`dnd`, `phone`, `sms`), shown with Try again.
  String? _missing;

  void _set(String key, Object v) => HomeScreen.set(context, key, v);

  /// Exact alarms and notifications make the options better but are not needed: asked once, after turning on.
  Future<void> _askExtras() async {
    final l = AppLocalizations.of(context);
    await worshipAsk(context, 'exact', l.worshipWhyExact);
    if (mounted) await worshipAsk(context, 'notifications', l.worshipWhyNotifications);
  }

  Future<void> _turnOnSilent() async {
    final l = AppLocalizations.of(context);
    if (!await worshipAsk(context, 'dnd', l.worshipWhyDnd)) {
      if (mounted) setState(() => _missing = 'dnd');
      return;
    }
    if (!mounted) return;
    setState(() => _missing = null);
    await HomeScreen.set(context, SettingKeys.prayerSilent, true);
    if (mounted) await _askExtras();
  }

  Future<void> _turnOnMute() async {
    await HomeScreen.set(context, SettingKeys.prayerAdhanMute, true);
    if (mounted) await _askExtras();
  }

  Future<void> _turnOnSms() async {
    final l = AppLocalizations.of(context);
    for (final (name, why) in [('phone', l.worshipWhyPhone), ('sms', l.worshipWhySms)]) {
      if (!mounted) return;
      if (!await worshipAsk(context, name, why)) {
        if (mounted) setState(() => _missing = name);
        return;
      }
    }
    if (!mounted) return;
    setState(() => _missing = null);
    await HomeScreen.set(context, SettingKeys.prayerSmsReply, true);
    // without exact alarms the reply can only wait up to 9 s after the ring starts
    if (mounted) await _askExtras();
  }

  @override
  Widget build(BuildContext context) {
    final s = WaaiyaScope.of(context).state;
    final w = WorshipInfo(s.feature('worship'));
    if (!w.supported) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final st = s.settings;
    final text = Theme.of(context).textTheme;
    void set(String key, Object v) => _set(key, v);
    void invoke(String method) => runAction(context, (b) => b.invoke('worship.$method'));
    void ask(String name, String why) => worshipAsk(context, name, why);

    Future<void> chooseMinutes(String key, List<int> options, int current) async {
      final i = await chooseOne(context,
          title: l.worshipMinutesTitle,
          options: [for (final m in options) l.worshipMinutesOption(m)],
          selected: options.indexOf(current));
      if (i != null && context.mounted) set(key, options[i]);
    }

    final on = st.prayerSilent || st.prayerAdhanMute;
    final smsOn = w.smsSupported && st.prayerSmsReply;
    final times = w.times;
    return KeyedSubtree(
      key: const Key('worship_card'),
      child: SectionCard(
        title: l.worshipTitle,
        body: l.worshipBody,
        children: [
          ValueRow(
            key: const Key('worship_place'),
            label: !w.placeSet || w.placeLabel == null
                ? l.worshipPlaceNone
                : l.worshipPlace(w.placeNear != null ? l.worshipPlaceNear(w.placeNear!) : w.placeLabel!),
            action: w.placeSet ? l.change : l.worshipChoose,
            onPressed: () => chooseWorshipPlace(context, w),
          ),
          if (!w.placeSet)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                key: const Key('worship_use_location'),
                icon: const Icon(Icons.my_location),
                label: Text(l.worshipUseLocation),
                onPressed: () => useMyLocation(context),
              ),
            ),
          if (w.placeSet && !w.placeValid) StatusText(l.worshipPlaceInvalid, isError: true),
          if (w.placeValid) ...[
            ValueRow(
              key: const Key('worship_method'),
              label: l.worshipMethod(worshipMethodName(l, st.prayerMethod)),
              action: l.change,
              onPressed: () async {
                final i = await chooseOne(context,
                    title: l.worshipMethodTitle,
                    options: [for (var i = 0; i < worshipMethodKeys.length; i++) worshipMethodName(l, i)],
                    selected: st.prayerMethod);
                if (i != null && context.mounted) set(SettingKeys.prayerMethod, i);
              },
            ),
            if (w.habous && w.placeLabel != null)
              Text(l.worshipHabousNote(w.placeLabel!), key: const Key('worship_habous'), style: text.bodySmall)
            else if (w.suggestedMethod != null)
              Text(l.worshipMethodNote, style: text.bodySmall),
            ValueRow(
              key: const Key('worship_asr'),
              label: l.worshipAsr(st.prayerAsr == 1 ? l.worshipAsrHanafi : l.worshipAsrStandard),
              action: l.change,
              onPressed: () async {
                final i = await chooseOne(context,
                    title: l.worshipAsrTitle,
                    options: [l.worshipAsrStandard, l.worshipAsrHanafi],
                    selected: st.prayerAsr);
                if (i != null && context.mounted) set(SettingKeys.prayerAsr, i);
              },
            ),
            const SizedBox(height: 8),
            if (times == null)
              StatusText(l.worshipNoTimes)
            else
              _TimesTable(title: l.worshipToday, times: times),
          ],
          const SizedBox(height: 8),
          SettingSwitch(
            key: const Key('worship_silent'),
            id: 'switch_worship_silent',
            title: l.worshipSilentTitle,
            body: l.worshipSilentBody,
            value: st.prayerSilent,
            onChanged: w.placeValid || st.prayerSilent ? (v) => v ? _turnOnSilent() : set(SettingKeys.prayerSilent, v) : null,
          ),
          if (st.prayerSilent)
            ValueRow(
              key: const Key('worship_silent_minutes'),
              label: l.worshipSilentMinutes(st.prayerSilentMinutes),
              action: l.change,
              onPressed: () => chooseMinutes(SettingKeys.prayerSilentMinutes, worshipSilentMinutes, st.prayerSilentMinutes),
            ),
          SettingSwitch(
            key: const Key('worship_mute'),
            id: 'switch_worship_mute',
            title: l.worshipMuteTitle,
            body: l.worshipMuteBody,
            value: st.prayerAdhanMute,
            onChanged: w.placeValid || st.prayerAdhanMute ? (v) => v ? _turnOnMute() : set(SettingKeys.prayerAdhanMute, v) : null,
          ),
          if (st.prayerAdhanMute)
            ValueRow(
              key: const Key('worship_mute_minutes'),
              label: l.worshipMuteMinutes(st.prayerAdhanMinutes),
              action: l.change,
              onPressed: () => chooseMinutes(SettingKeys.prayerAdhanMinutes, worshipMuteMinutes, st.prayerAdhanMinutes),
            ),
          if (!w.placeValid) StatusText(l.worshipNeedPlace),
          if (_missing == 'dnd' && !st.prayerSilent)
            _LineWithButton(key: const Key('worship_missing'), text: l.worshipMissingDnd, isError: true,
                button: l.worshipTryAgain, onPressed: _turnOnSilent),
          // what is happening now, and what comes next
          if (w.silentUntil > 0 && w.silentUntilHm != null)
            _LineWithButton(text: l.worshipSilentNow(w.silentUntilHm!), button: l.worshipEndSilent,
                onPressed: () => invoke('endSilentNow')),
          if (w.muteUntil > 0 && w.muteUntilHm != null)
            _LineWithButton(text: l.worshipMutedNow(w.muteUntilHm!), button: l.worshipUnmute,
                onPressed: () => invoke('unmuteNow')),
          if (on && w.next != null)
            StatusText(l.worshipNext(worshipPrayerName(l, w.next!.$1), w.next!.$2), id: 'worship_next'),
          // what the phone still has to allow
          if (st.prayerSilent && !w.dndAccess)
            _LineWithButton(key: const Key('worship_dnd'), text: l.worshipDndNeeded, isError: true,
                button: l.worshipAllow, onPressed: () => ask('dnd', l.worshipWhyDnd)),
          if ((on || smsOn) && !w.exactAlarms)
            _LineWithButton(key: const Key('worship_exact'), text: l.worshipExactNeeded, isError: true,
                button: l.worshipAllow, onPressed: () => ask('exact', l.worshipWhyExact)),
          if (on && !w.notifications)
            _LineWithButton(key: const Key('worship_notifications'), text: l.worshipNotificationsNeeded,
                button: l.worshipAllow, onPressed: () => ask('notifications', l.worshipWhyNotifications)),
          if (w.smsSupported) ...[
            const Divider(height: 32),
            WorshipSmsSection(
              info: w,
              missing: _missing == 'phone' || _missing == 'sms' ? _missing : null,
              turnOn: _turnOnSms,
            ),
          ],
          const Divider(height: 32),
          WorshipTonesSection(info: w),
        ],
      ),
    );
  }
}

/// Today's six times (the five prayers and sunrise) in two columns.
class _TimesTable extends StatelessWidget {
  const _TimesTable({required this.title, required this.times});

  final String title;
  final List<WorshipTime> times;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      key: const Key('worship_times'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: 4),
        for (final t in times)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(worshipPrayerName(l, t.name), style: text.bodyLarge)),
                // times are digits and a colon: always left to right
                Text(t.hm, style: text.bodyLarge, textDirection: TextDirection.ltr),
              ],
            ),
          ),
      ],
    );
  }
}

/// A status line with a button under it.
class _LineWithButton extends StatelessWidget {
  const _LineWithButton({super.key, required this.text, required this.button, required this.onPressed, this.isError = false});

  final String text;
  final String button;
  final VoidCallback onPressed;
  final bool isError;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusText(text, isError: isError),
          TextButton(onPressed: onPressed, child: Text(button)),
        ],
      );
}
