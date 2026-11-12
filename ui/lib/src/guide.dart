import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';

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

/// The blur's Shizuku action (MainActivity.onBlurSetup): installed but not running -> the guide; otherwise the
/// backend does the next step (store, update, Shizuku's permission dialog then the grant, or open Shizuku).
Future<void> blurShizukuStep(BuildContext context) async {
  if (WaaiyaScope.of(context).state.setup.shizuku == ShizukuState.notRunning) return showShizukuGuide(context);
  await runAction(context, (b) => b.blurSetup());
}
