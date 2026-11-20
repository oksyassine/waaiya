/// Fix mistakes on the spot (docs/FEATURES_CONTRACT.md, lane A): the filter or the blur off for chosen apps, covering
/// an area by hand, local "wrong detection" notes. Snapshot section `fix`, methods `fix.*`.
///
/// `features.fix` (each key optional; a missing key hides its part):
///   filterApps (bool)        the filter can leave chosen apps alone here (setting filter_off_apps)
///   blurApps (bool)          the blur can leave chosen apps alone here (setting blur_off_apps); false = shown
///                            disabled with blurAppsReason: `needs_setup` (no DUMP), `helper_mode`
///   handCover (bool)         "Cover an area" exists here (Android); handCovers (int) = hand covers now
///   blurRunning (bool)       the blur runs now (hand covers can be drawn)
///   notes (int)              wrong-detection notes kept on this device (present = notes exist here)
///   labels (map)             package -> app name, for the apps in either list (Android)
///   playing (list)           desktop: application names playing sound now
/// Methods: fix.apps -> [{package, label, icon?}], fix.coverArea -> `opened` | `blur_off`, fix.removeCovers,
/// fix.note {kind: missed|wrong, where: filter|screen} -> count, fix.notes -> text, fix.clearNotes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'widgets.dart';

/// The `features.fix` section, read with defaults.
class FixInfo {
  FixInfo(this.m);

  final Map<Object?, Object?> m;

  bool get filterApps => m['filterApps'] == true;
  bool get blurAppsShown => m.containsKey('blurApps');
  bool get blurApps => m['blurApps'] == true;
  String? get blurAppsReason => m['blurAppsReason'] as String?;
  bool get handCover => m['handCover'] == true;
  int get handCovers => (m['handCovers'] as int?) ?? 0;
  bool get blurRunning => m['blurRunning'] == true;
  bool get notesShown => m.containsKey('notes');
  int get notes => (m['notes'] as int?) ?? 0;

  String label(String app) {
    final labels = m['labels'];
    final v = labels is Map ? labels[app] : null;
    return v is String && v.isNotEmpty ? v : app;
  }

  static FixInfo of(BuildContext context) => FixInfo(WaaiyaScope.of(context).state.feature('fix'));
}

/// One app the user can choose in the picker.
class FixApp {
  const FixApp(this.id, this.label, [this.icon]);

  /// Package name (Android) or application name (desktop): what is stored in the setting.
  final String id;
  final String label;
  final Uint8List? icon;

  static FixApp? fromMap(Object? o) {
    if (o is! Map) return null;
    final id = o['package'];
    if (id is! String || id.isEmpty || id.contains(',')) return null;
    final label = o['label'];
    final icon = o['icon'];
    return FixApp(id, label is String && label.isNotEmpty ? label : id, icon is Uint8List ? icon : null);
  }
}

/// The new setting value after adding or removing [app] (comma-separated, sorted, no duplicates).
String fixAppsValue(List<String> current, {String? add, String? remove}) {
  final s = {...current.where((a) => a.isNotEmpty)};
  if (add != null) s.add(add);
  if (remove != null) s.remove(remove);
  return (s.toList()..sort()).join(',');
}

/// Filter page, under the filter options: apps the filter leaves alone, and the sound notes.
class FilterAppsCard extends StatelessWidget {
  const FilterAppsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final fix = FixInfo(s.feature('fix'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fix.filterApps)
          SectionCard(
            key: const Key('fix_filter_apps'),
            title: l.fixFilterAppsTitle,
            body: l.fixFilterAppsBody,
            children: [
              _AppList(settingKey: SettingKeys.filterOffApps, apps: s.settings.filterOffApps, fix: fix),
            ],
          ),
        // without a Screen page (no blur here) the notes are kept and shown from this page
        if (fix.notesShown) _NotesCard(where: 'filter', withList: !s.capabilities.screenBlur),
      ],
    );
  }
}

/// Screen page, under the blur card: apps the blur leaves alone, cover by hand, wrong-detection notes.
class BlurAppsCard extends StatelessWidget {
  const BlurAppsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final fix = FixInfo(s.feature('fix'));
    final reason = fix.blurApps
        ? null
        : switch (fix.blurAppsReason) {
            'helper_mode' => l.fixBlurAppsHelperMode,
            _ => l.fixBlurAppsNeedsSetup,
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fix.blurAppsShown)
          SectionCard(
            key: const Key('fix_blur_apps'),
            title: l.fixBlurAppsTitle,
            body: l.fixBlurAppsBody,
            children: [
              // where the app on screen cannot be known the option is off (the blur stays on everywhere), with why
              if (reason != null) StatusText(reason, key: const Key('fix_blur_apps_reason'), isError: true),
              _AppList(
                  settingKey: SettingKeys.blurOffApps, apps: s.settings.blurOffApps, fix: fix, enabled: reason == null),
            ],
          ),
        if (fix.handCover) const _HandCoverCard(),
        if (fix.notesShown) const _NotesCard(where: 'screen', withList: true),
      ],
    );
  }
}

/// The chosen apps, each with a remove button, and "Add an app".
class _AppList extends StatelessWidget {
  const _AppList({required this.settingKey, required this.apps, required this.fix, this.enabled = true});

  final String settingKey;
  final List<String> apps;
  final FixInfo fix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        if (apps.isEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.fixNoApps, style: text.bodyMedium)),
        for (final a in apps)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.apps_rounded, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(fix.label(a), style: text.bodyLarge)),
                // removing makes protection stronger: always allowed, even when adding is not
                IconButton(
                  key: Key('fix_remove_${settingKey}_$a'),
                  tooltip: l.fixRemoveApp(fix.label(a)),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => runAction(
                      context, (b) => b.setSetting(settingKey, fixAppsValue(apps, remove: a))),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: Key('fix_add_$settingKey'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.fixAddApp),
            onPressed: enabled ? () => _add(context) : null,
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final found = await runAction(context, (b) => b.invoke('fix.apps'));
    if (found is! List || !context.mounted) return;
    final choices = [for (final o in found) ?FixApp.fromMap(o)].where((a) => !apps.contains(a.id)).toList();
    final picked = await showDialog<FixApp>(context: context, builder: (ctx) => _AppPicker(choices: choices));
    if (picked == null || !context.mounted) return;
    // adding weakens protection: the backend's guard may refuse it (runAction hands that to onProtected)
    await runAction(context, (b) => b.setSetting(settingKey, fixAppsValue(apps, add: picked.id)));
  }
}

class _AppPicker extends StatelessWidget {
  const _AppPicker({required this.choices});

  final List<FixApp> choices;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final desktop = WaaiyaScope.of(context).state.platform != 'android';
    return AlertDialog(
      title: Text(l.fixPickTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (desktop) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l.fixPickPlayingDesktop)),
            if (choices.isEmpty) Text(l.fixPickEmpty),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final a in choices)
                    ListTile(
                      key: Key('fix_pick_${a.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: a.icon != null
                          ? Image.memory(a.icon!,
                              width: 36,
                              height: 36,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const Icon(Icons.apps_rounded))
                          : const Icon(Icons.apps_rounded),
                      title: Text(a.label),
                      subtitle: a.label != a.id
                          ? Directionality(textDirection: TextDirection.ltr, child: Text(a.id, style: const TextStyle(fontSize: 12)))
                          : null,
                      onTap: () => Navigator.pop(context, a),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.fixCancel))],
    );
  }
}

/// "Cover an area" and "Remove hand covers" (Android: the blur's own cover host draws them).
class _HandCoverCard extends StatelessWidget {
  const _HandCoverCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fix = FixInfo.of(context);
    return SectionCard(
      key: const Key('fix_hand'),
      title: l.fixHandTitle,
      body: l.fixHandBody,
      children: [
        if (!fix.blurRunning) StatusText(l.fixHandNotRunning),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              key: const Key('fix_cover_area'),
              onPressed: fix.blurRunning
                  ? () async {
                      final r = await runAction(context, (b) => b.invoke('fix.coverArea'));
                      if (r == 'blur_off' && context.mounted) {
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.fixHandNotRunning)));
                      }
                    }
                  : null,
              child: Text(l.fixCoverArea),
            ),
            if (fix.handCovers > 0)
              OutlinedButton(
                key: const Key('fix_remove_covers'),
                onPressed: () => runAction(context, (b) => b.invoke('fix.removeCovers')),
                child: Text(l.fixRemoveCovers(fix.handCovers)),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Note a mistake": two buttons, and (where [withList]) the count with Show / share and Delete.
class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.where, required this.withList});

  /// `filter` (sound) or `screen` (blur): the words of the buttons, and the note's origin.
  final String where;
  final bool withList;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fix = FixInfo.of(context);
    final sound = where == 'filter';
    return SectionCard(
      key: Key('fix_notes_$where'),
      title: l.fixNoteTitle,
      body: l.fixNoteBody,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: Key('fix_note_missed_$where'),
              onPressed: () => _note(context, 'missed'),
              child: Text(sound ? l.fixMissedSound : l.fixMissedScreen),
            ),
            OutlinedButton(
              key: Key('fix_note_wrong_$where'),
              onPressed: () => _note(context, 'wrong'),
              child: Text(sound ? l.fixWrongSound : l.fixWrongScreen),
            ),
          ],
        ),
        if (withList) ...[
          const SizedBox(height: 12),
          Text(l.fixNotesCount(fix.notes), key: const Key('fix_notes_count'), style: Theme.of(context).textTheme.bodyLarge),
          if (fix.notes > 0)
            Wrap(
              spacing: 8,
              children: [
                TextButton(key: const Key('fix_notes_show'), onPressed: () => _show(context), child: Text(l.fixNotesShow)),
                TextButton(key: const Key('fix_notes_delete'), onPressed: () => _delete(context), child: Text(l.fixNotesDelete)),
              ],
            ),
        ],
      ],
    );
  }

  Future<void> _note(BuildContext context, String kind) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final n = await runAction(context, (b) => b.invoke('fix.note', {'kind': kind, 'where': where}));
    if (n is int) messenger?.showSnackBar(SnackBar(content: Text(l.fixNoted(n))));
  }

  Future<void> _show(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final android = WaaiyaScope.of(context).state.platform == 'android';
    final text = await runAction(context, (b) => b.invoke('fix.notes'));
    if (text is! String || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.fixNotesTitle),
        content: SingleChildScrollView(
          // the notes are technical English, like the diagnostics report: left to right in every language
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(text, key: const Key('fix_notes_text'), style: const TextStyle(fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.guideClose)),
          if (android)
            TextButton(
              key: const Key('fix_notes_share'),
              onPressed: () {
                Navigator.pop(ctx);
                runAction(context, (b) => b.shareText(text));
              },
              child: Text(l.linkShare),
            ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
              messenger?.showSnackBar(SnackBar(content: Text(l.copied)));
            },
            child: Text(l.copy),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.fixNotesDeleteAsk),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.fixCancel)),
          FilledButton(
              key: const Key('fix_notes_delete_yes'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.fixNotesDelete)),
        ],
      ),
    );
    if (yes == true && context.mounted) await runAction(context, (b) => b.invoke('fix.clearNotes'));
  }
}
