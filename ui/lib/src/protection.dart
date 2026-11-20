/// Protection that survives a weak moment (docs/FEATURES_CONTRACT.md, lane B): a waiting period and a local PIN.
/// Snapshot section `protect`, methods `protect.*`.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'backend.dart';

/// Settings page, under the worship card.
class ProtectionCard extends StatelessWidget {
  const ProtectionCard({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Called by runAction when the backend refused a change with `protected` (waiting period or PIN).
Future<void> onProtected(BuildContext context, BackendException e) async {
  final l = AppLocalizations.of(context);
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.actionFailed(e.code))));
}
