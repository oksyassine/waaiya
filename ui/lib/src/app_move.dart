/// Waaiya moved from org.islamicmute.app to org.waaiya.app (Android, 0.2.15; AppMove.kt, docs/MOVE.md): the card at the
/// top of the Filter and Settings pages.
///
/// Snapshot `features.move` (absent or `supported: false` when there is nothing to do): `kind` `old` (the old app's
/// last version: install the new app, then remove this one; `newInstalled`) or `new` (the new app while the old one is
/// still installed: remove it; `imported`: its settings were taken). Installing uses `features.update` (its state and
/// progress) and `update.start`. Methods: `move.openNew`, `move.removeOld`.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'widgets.dart';

class MoveCard extends StatelessWidget {
  const MoveCard({super.key});

  @override
  Widget build(BuildContext context) {
    final st = WaaiyaScope.of(context).state;
    final f = st.feature('move');
    if (f['supported'] != true) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    void invoke(String m) => runAction(context, (b) => b.invoke(m, const {}));
    Widget para(String s, {bool error = false}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(s, style: error ? text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error) : text.bodyMedium),
        );

    if (f['kind'] == 'new') {
      return TestId(
        'move_card',
        child: SectionCard(
          title: l.moveNewTitle,
          body: l.moveNewBody,
          children: [
            if (f['imported'] == true) para(l.moveNewImported),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                key: const Key('move_remove_old'),
                onPressed: () => invoke('move.removeOld'),
                child: Text(l.moveRemoveOld),
              ),
            ),
          ],
        ),
      );
    }

    // the old app's last version
    final installed = f['newInstalled'] == true;
    final u = st.feature('update');
    final state = u['state'] as String? ?? 'idle';
    final progress = (u['progress'] as num?)?.toDouble() ?? 0;
    final busy = const {'checking', 'downloading', 'preparing', 'installing'}.contains(state);
    final canInstall = u['supported'] == true && u['canInstall'] != false;
    final lines = <Widget>[];
    if (!installed) {
      if (state == 'downloading') lines.add(para(l.updateDownloading('${(progress * 100).round()}%')));
      if (state == 'preparing') lines.add(para(l.updatePreparing));
      if (state == 'installing') lines.add(para(l.updateInstalling));
      if (state == 'permission') lines.add(para(l.updatePermission, error: true));
      if (state == 'error') lines.add(para(l.updateFailed, error: true));
      if (busy && state != 'checking') {
        lines.add(Padding(padding: const EdgeInsets.only(top: 12), child: LinearProgressIndicator(value: progress > 0 ? progress : null)));
      }
    }
    return TestId(
      'move_card',
      child: SectionCard(
        title: l.moveOldTitle,
        body: installed ? l.moveOldInstalled : l.moveOldBody,
        children: [
          ...lines,
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (installed) ...[
                FilledButton(key: const Key('move_open_new'), onPressed: () => invoke('move.openNew'), child: Text(l.moveOpenNew)),
                OutlinedButton(key: const Key('move_remove_this'), onPressed: () => invoke('move.removeOld'), child: Text(l.moveRemoveThis)),
              ] else if (canInstall && const {'available', 'ready', 'permission', 'error', 'downloading', 'preparing', 'installing'}.contains(state))
                FilledButton(
                  key: const Key('move_install'),
                  onPressed: busy ? null : () => invoke('update.start'),
                  child: Text(l.moveInstall),
                )
              else ...[
                // not known yet (checking, offline) or this build cannot install it: check again, or the download page
                OutlinedButton(key: const Key('move_check'), onPressed: busy ? null : () => invoke('update.check'), child: Text(l.updateCheck)),
                TextButton(key: const Key('move_page'), onPressed: () => invoke('update.openPage'), child: Text(l.updateOpenPage)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
