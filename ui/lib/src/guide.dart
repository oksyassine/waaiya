import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';

/// Wireless-debugging steps to start Shizuku, with shortcuts to Developer options and Shizuku
/// (MainActivity.showShizukuGuide).
Future<void> showShizukuGuide(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      key: const Key('shizuku_guide'),
      title: Text(l.guideTitle),
      content: SingleChildScrollView(child: Text(l.guideBody, style: Theme.of(dialog).textTheme.bodyLarge)),
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: Text(l.guideClose)),
        TextButton(
          onPressed: () {
            Navigator.pop(dialog);
            runAction(context, (b) => b.openDeveloperOptions());
          },
          child: Text(l.guideOpenDev),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialog);
            runAction(context, (b) => b.openShizuku());
          },
          child: Text(l.guideOpenShizuku),
        ),
      ],
    ),
  );
}
