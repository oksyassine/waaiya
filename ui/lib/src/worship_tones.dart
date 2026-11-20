/// Plain ringtone and notification sound (docs/ROADMAP.md item 9): Android plays them itself, so they cannot be
/// filtered, only replaced. Native side: WorshipTones.kt (methods `worship.previewTone`, `worship.setTone`,
/// `worship.openSoundSettings`).
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'worship.dart';

class WorshipTonesSection extends StatelessWidget {
  const WorshipTonesSection({super.key, required this.info});

  final WorshipInfo info;

  Future<void> _set(BuildContext context, String id) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    // "Modify system settings" is asked here, when the user picks a tone, and never before
    if (!info.writeSettings && !await worshipAsk(context, 'write', l.worshipWhyWrite)) return;
    if (!context.mounted) return;
    final r = await runAction(context, (b) => b.invoke('worship.setTone', {'id': id}));
    if (!context.mounted) return;
    switch (r) {
      case 'set':
        messenger?.showSnackBar(SnackBar(content: Text(l.worshipToneDone)));
      case 'needs_permission':
        messenger?.showSnackBar(SnackBar(content: Text(l.worshipTonePermission)));
      case 'failed':
        await showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            content: Text(l.worshipToneFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
              ),
              TextButton(
                key: const Key('worship_open_sound'),
                onPressed: () {
                  Navigator.pop(dialog);
                  runAction(context, (b) => b.invoke('worship.openSoundSettings'));
                },
                child: Text(l.worshipOpenSound),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      key: const Key('worship_tones'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l.worshipTonesTitle, style: text.titleSmall)),
        const SizedBox(height: 4),
        Text(l.worshipTonesBody, style: text.bodyMedium),
        for (final (id, kind, number) in info.tones)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                IconButton(
                  key: Key('worship_play_$id'),
                  tooltip: l.worshipTonePlay,
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => runAction(context, (b) => b.invoke('worship.previewTone', {'id': id})),
                ),
                Expanded(
                  child: Text(kind == 'ring' ? l.worshipToneRing(number) : l.worshipToneNotification(number),
                      style: text.bodyLarge),
                ),
                if ((kind == 'ring' ? info.ringtone : info.notificationTone) == id)
                  // may take two lines in a long language (Somali) on a small phone
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(l.worshipToneInUse, style: text.bodyMedium, textAlign: TextAlign.end),
                    ),
                  )
                else
                  TextButton(key: Key('worship_use_$id'), onPressed: () => _set(context, id), child: Text(l.worshipToneSet)),
              ],
            ),
          ),
      ],
    );
  }
}
