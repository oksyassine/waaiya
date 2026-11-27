/// Live captions (docs/CAPTIONS.md): Arabic speech from the microphone as large text on the phone's screen.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'widgets.dart';

/// The filter page's captions card: what it does, and a button that opens the native captions screen
/// (`captions.open`). Snapshot `features.captions`: `available` = this build bundles the Arabic speech model.
/// Shown only where that section exists and the model is bundled, so a build without it offers nothing it cannot do.
class CaptionsCard extends StatelessWidget {
  const CaptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final f = WaaiyaScope.of(context).state.feature('captions');
    if (f['available'] != true) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return SectionCard(
      key: const Key('captions_card'),
      title: l.captionsCardTitle,
      body: l.captionsCardBody,
      children: [
        const SizedBox(height: 12),
        TestId(
          'captions_open',
          child: FilledButton.tonal(
            key: const Key('captions_open'),
            onPressed: () => runAction(context, (b) => b.invoke('captions.open')),
            child: Text(l.captionsCardOpen),
          ),
        ),
      ],
    );
  }
}
