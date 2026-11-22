/// The place for the prayer times: the phone's location ("Use my location", read once when tapped), a city from the
/// bundled list (search in any language), or coordinates and a time zone. Nothing online: the list, the search and
/// the place are worked out on the phone (`worship.cities`, `worship.locate`).
///
/// Morocco: the place is one of the Ministry of Habous's 190 cities and the times are its official table (the
/// method is Morocco's, nothing to choose). Elsewhere the user chooses the calculation method, the country's usual
/// one preselected.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'widgets.dart';
import 'worship.dart';

/// Opens the place dialog. Picking a city sets `prayer_place` and preselects the method usually used in its country
/// (`prayer_method`, shown on the card and changeable). Coordinates leave the method as it is.
Future<void> chooseWorshipPlace(BuildContext context, WorshipInfo info) async {
  final picked = await showDialog<_Picked>(context: context, builder: (_) => const _PlaceDialog());
  if (picked == null || !context.mounted) return;
  if (picked.locate) return useMyLocation(context);
  if (picked.custom) {
    final setting = await showDialog<String>(
        context: context, builder: (_) => _CustomPlaceDialog(zone: info.zone ?? info.deviceZone ?? ''));
    if (setting == null || !context.mounted) return;
    await HomeScreen.set(context, SettingKeys.prayerPlace, setting);
    return;
  }
  await HomeScreen.set(context, SettingKeys.prayerPlace, picked.id);
  if (picked.method != null && context.mounted) await HomeScreen.set(context, SettingKeys.prayerMethod, picked.method!);
}

class _Picked {
  const _Picked.city(this.id, this.method)
      : custom = false,
        locate = false;
  const _Picked.custom()
      : id = '',
        method = null,
        custom = true,
        locate = false;
  const _Picked.locate()
      : id = '',
        method = null,
        custom = false,
        locate = true;
  final String id;
  final int? method;
  final bool custom;
  final bool locate;
}

/// "Use my location": Android's question for the approximate location (asked only now, because the user tapped),
/// one position read on the phone (`worship.locate`), then the place. In Morocco: the nearest of the Ministry of
/// Habous's cities and its official times. Elsewhere: the coordinates, and the user picks the calculation method
/// (the country's usual one preselected; closing the list keeps it).
Future<void> useMyLocation(BuildContext context) async {
  final l = AppLocalizations.of(context);
  if (!await worshipAsk(context, 'location', l.worshipWhyLocation)) {
    if (context.mounted) await _tell(context, l.worshipLocationDenied);
    return;
  }
  if (!context.mounted) return;
  final r = await showDialog<Map<Object?, Object?>>(
      context: context, barrierDismissible: false, builder: (_) => const _LocatingDialog());
  if (r == null || !context.mounted) return; // cancelled
  switch (r['state']) {
    case 'found':
      final setting = r['setting'];
      if (setting is! String) return;
      final method = r['method'] is int ? r['method'] as int : 0;
      await HomeScreen.set(context, SettingKeys.prayerPlace, setting);
      if (!context.mounted) return;
      if (r['habous'] == true) {
        await HomeScreen.set(context, SettingKeys.prayerMethod, method);
        return;
      }
      final i = await chooseOne(context,
          title: l.worshipMethodTitle,
          options: [for (var i = 0; i < worshipMethodKeys.length; i++) worshipMethodName(l, i)],
          selected: method);
      if (context.mounted) await HomeScreen.set(context, SettingKeys.prayerMethod, i ?? method);
    case 'off':
      final open = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          scrollable: true,
          content: Text(l.worshipLocationOff),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel)),
            TextButton(
                key: const Key('worship_location_settings'),
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(l.worshipLocationSettings)),
          ],
        ),
      );
      if (open == true && context.mounted) await runAction(context, (b) => b.invoke('worship.openLocationSettings'));
    case 'denied':
      await _tell(context, l.worshipLocationDenied);
    default:
      await _tell(context, l.worshipLocationFailed);
  }
}

Future<void> _tell(BuildContext context, String text) => showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialog), child: Text(MaterialLocalizations.of(dialog).okButtonLabel)),
        ],
      ),
    );

/// "Finding where you are…" while the phone reads one position (at most 30 s natively); pops with the snapshot's
/// `locate` once it is no longer working, or null on Cancel.
class _LocatingDialog extends StatefulWidget {
  const _LocatingDialog();

  @override
  State<_LocatingDialog> createState() => _LocatingDialogState();
}

class _LocatingDialogState extends State<_LocatingDialog> {
  StreamSubscription<AppState>? _sub;
  Timer? _timeout;
  Object? _id;
  Map<Object?, Object?>? _last;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 45), () => _done(const {'state': 'none'}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final backend = WaaiyaScope.of(context).backend;
      // listen before asking, so that a quick answer cannot slip by
      _sub = backend.states.listen((s) {
        final a = s.feature('worship')['locate'];
        if (a is Map) {
          _last = a;
          _check();
        }
      });
      try {
        final r = await backend.invoke('worship.locate');
        if (r is Map) _id = r['id'];
        _check();
      } on BackendException {
        _done(const {'state': 'none'});
      }
    });
  }

  void _check() {
    final a = _last;
    if (_id != null && a != null && a['id'] == _id && a['state'] != 'working') _done(a);
  }

  bool _popped = false;

  void _done(Map<Object?, Object?>? result) {
    _timeout?.cancel();
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('worship_locating'),
      content: Row(
        children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 16),
          Expanded(child: Text(l.worshipLocating)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => _done(null), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
      ],
    );
  }
}

/// Search field and the matching cities; "Enter coordinates" at the bottom.
class _PlaceDialog extends StatefulWidget {
  const _PlaceDialog();

  @override
  State<_PlaceDialog> createState() => _PlaceDialogState();
}

class _PlaceDialogState extends State<_PlaceDialog> {
  List<Map<Object?, Object?>> _cities = const [];
  Timer? _debounce;
  int _asked = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final n = ++_asked;
    final r = await runAction(context, (b) => b.invoke('worship.cities', {'query': q, 'limit': 60}));
    if (!mounted || n != _asked) return;
    setState(() => _cities = r is List ? r.whereType<Map>().toList() : const []);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('worship_place_search'),
                autofocus: true,
                decoration: InputDecoration(hintText: l.worshipPlaceSearch, prefixIcon: const Icon(Icons.search)),
                onChanged: (q) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 200), () => _search(q));
                },
              ),
              ListTile(
                key: const Key('worship_place_locate'),
                leading: const Icon(Icons.my_location),
                title: Text(l.worshipUseLocation),
                onTap: () => Navigator.pop(context, const _Picked.locate()),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: _cities.isEmpty
                    ? Padding(padding: const EdgeInsets.all(8), child: Text(l.worshipPlaceNoMatch, style: text.bodyMedium))
                    : ListView.builder(
                        itemCount: _cities.length,
                        itemBuilder: (context, i) {
                          final c = _cities[i];
                          final id = '${c['id']}';
                          final other = c['en'] != c['name'] ? '${c['en']}' : (c['ar'] != c['name'] ? '${c['ar']}' : '');
                          return ListTile(
                            key: Key('worship_city_$id'),
                            dense: true,
                            title: Text('${c['name']}'),
                            subtitle: Text([if (other.isNotEmpty) other, '${c['cc']}'].join(' · ')),
                            onTap: () => Navigator.pop(context, _Picked.city(id, c['method'] is int ? c['method'] as int : null)),
                          );
                        },
                      ),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
                  TextButton(
                    key: const Key('worship_place_custom'),
                    onPressed: () => Navigator.pop(context, const _Picked.custom()),
                    child: Text(l.worshipPlaceCustom),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Latitude, longitude and an IANA time zone; checked natively (`worship.customPlace`) before it is saved.
class _CustomPlaceDialog extends StatefulWidget {
  const _CustomPlaceDialog({required this.zone});

  final String zone;

  @override
  State<_CustomPlaceDialog> createState() => _CustomPlaceDialogState();
}

class _CustomPlaceDialogState extends State<_CustomPlaceDialog> {
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  late final _zone = TextEditingController(text: widget.zone);
  bool _invalid = false;

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    _zone.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.').replaceAll('−', '-'));

  Future<void> _ok() async {
    final lat = _num(_lat.text), lon = _num(_lon.text);
    if (lat == null || lon == null) return setState(() => _invalid = true);
    final backend = WaaiyaScope.of(context).backend;
    try {
      final r = await backend.invoke('worship.customPlace', {'lat': lat, 'lon': lon, 'tz': _zone.text.trim()});
      if (mounted && r is String) Navigator.pop(context, r);
    } on BackendException {
      if (mounted) setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ml = MaterialLocalizations.of(context);
    const numbers = TextInputType.numberWithOptions(signed: true, decimal: true);
    return AlertDialog(
      title: Text(l.worshipPlaceCustom),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(key: const Key('worship_lat'), controller: _lat, keyboardType: numbers,
              decoration: InputDecoration(labelText: l.worshipLat)),
          TextField(key: const Key('worship_lon'), controller: _lon, keyboardType: numbers,
              decoration: InputDecoration(labelText: l.worshipLon)),
          TextField(key: const Key('worship_tz'), controller: _zone, autocorrect: false,
              decoration: InputDecoration(labelText: l.worshipZone)),
          if (_invalid)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(l.worshipCustomInvalid, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(ml.cancelButtonLabel)),
        TextButton(key: const Key('worship_custom_ok'), onPressed: _ok, child: Text(ml.okButtonLabel)),
      ],
    );
  }
}
