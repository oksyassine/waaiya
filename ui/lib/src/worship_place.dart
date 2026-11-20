/// The place for the prayer times: a city from the bundled list (search in any language), or coordinates and a time
/// zone. No location permission and nothing online: the list and the search are on the phone (`worship.cities`).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'worship.dart';

/// Opens the place dialog. Picking a city sets `prayer_place` and preselects the method usually used in its country
/// (`prayer_method`, shown on the card and changeable). Coordinates leave the method as it is.
Future<void> chooseWorshipPlace(BuildContext context, WorshipInfo info) async {
  final picked = await showDialog<_Picked>(context: context, builder: (_) => const _PlaceDialog());
  if (picked == null || !context.mounted) return;
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
  const _Picked.city(this.id, this.method) : custom = false;
  const _Picked.custom()
      : id = '',
        method = null,
        custom = true;
  final String id;
  final int? method;
  final bool custom;
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
