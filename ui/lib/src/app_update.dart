/// New versions of Waaiya: the Updates card on the Settings page.
///
/// Snapshot `features.update` (Android: AppUpdate.kt; desktop: a notice with a link; absent or `supported: false`
/// where the store updates the app): `auto`, `state` (idle checking none available downloading preparing ready
/// installing error permission), `current`, `latest`, `notes` (language -> text), `download` and `full` (bytes),
/// `patch` (only the changes are downloaded), `progress` (0..1), `error`, `canInstall` (false on desktop: the page
/// opens instead), `page`.
/// Methods: `update.check`, `update.setAuto {on}`, `update.start` (may be refused with 'protected': installing stops
/// the filter), `update.openPage`.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'widgets.dart';

class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key});

  static String size(Object? bytes) {
    final b = (bytes as num?)?.toDouble() ?? 0;
    final mb = b / 1048576;
    return mb >= 10 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final f = WaaiyaScope.of(context).state.feature('update');
    if (f['supported'] != true) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final state = f['state'] as String? ?? 'idle';
    final current = f['current'] as String? ?? '';
    final latest = f['latest'] as String?;
    final canInstall = f['canInstall'] != false;
    final progress = (f['progress'] as num?)?.toDouble() ?? 0;
    final busy = const {'checking', 'downloading', 'preparing', 'installing'}.contains(state);
    final newer = latest != null && const {'available', 'downloading', 'preparing', 'ready', 'installing', 'permission', 'error'}.contains(state);
    final lang = Localizations.localeOf(context).languageCode;
    final notesMap = f['notes'] is Map ? f['notes'] as Map : const {};
    final notes = (notesMap[lang] ?? notesMap['en']) as String?;
    void invoke(String m, [Map<String, Object?> args = const {}]) => runAction(context, (b) => b.invoke('update.$m', args));

    final lines = <Widget>[];
    void line(String s, {bool error = false}) => lines.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(s, style: error ? text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error) : text.bodyMedium),
        ));

    if (state == 'checking') line(l.updateChecking);
    if (state == 'none') line(l.updateNone(current));
    if (newer) {
      line(l.updateAvailable(latest, current));
      if (notes != null && notes.isNotEmpty) line(notes);
      if (canInstall && f['download'] != null) {
        line(f['patch'] == true ? l.updateSizePatch(size(f['download']), size(f['full'])) : l.updateSizeFull(size(f['download'])));
      }
    }
    if (state == 'downloading') line(l.updateDownloading('${(progress * 100).round()}%'));
    if (state == 'preparing') line(l.updatePreparing);
    if (state == 'installing') line(l.updateInstalling);
    if (state == 'permission') line(l.updatePermission, error: true);
    final err = f['error'] as String?;
    if (state == 'error') line(l.updateFailed, error: true);
    if (err == 'network' && !newer && state != 'checking') line(l.updateCheckFailed, error: true);
    if (busy && state != 'checking') {
      lines.add(Padding(padding: const EdgeInsets.only(top: 12), child: LinearProgressIndicator(value: progress > 0 ? progress : null)));
    }

    return TestId(
      'update_card',
      child: SectionCard(
        title: l.updateTitle,
        children: [
          SettingSwitch(
            key: const Key('update_auto'),
            id: 'switch_update_auto',
            title: l.updateAuto,
            body: l.updateAutoBody,
            value: f['auto'] == true,
            onChanged: (v) => invoke('setAuto', {'on': v}),
          ),
          ...lines,
          if (newer && canInstall) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.updateStopsFilter, style: text.bodySmall)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (newer && canInstall)
                FilledButton(
                  key: const Key('update_now'),
                  onPressed: busy ? null : () => invoke('start'),
                  child: Text(l.updateNow),
                ),
              if (!newer || !canInstall || state == 'error')
                OutlinedButton(
                  key: const Key('update_check'),
                  onPressed: busy ? null : () => invoke('check'),
                  child: Text(l.updateCheck),
                ),
              if ((newer && !canInstall) || state == 'error')
                TextButton(
                  key: const Key('update_page'),
                  onPressed: () => invoke('openPage'),
                  child: Text(l.updateOpenPage),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
