/// Keep singing (docs/FEATURES_CONTRACT.md, lane D): the voice_v1 model, a test, off by default.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'widgets.dart';

/// Last line of the filter options card: "Keep singing (test)", setting `keep_singing`.
///
/// Snapshot `features.singing`: `available` (this build has the model), `active` (the running filter uses it).
/// Hidden when the model is not available, unless the setting is still on (then it says so, so that it can be
/// turned off: while it is on without the model, the filter stays silent).
class SingingOptionSwitch extends StatelessWidget {
  const SingingOptionSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WaaiyaScope.of(context).state;
    final available = s.feature('singing')['available'] == true;
    final on = s.settings.keepSinging;
    if (!available && !on) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return SettingSwitch(
      key: const Key('keep_singing'),
      id: 'switch_keep_singing',
      title: l.singingKeepTitle,
      body: available ? l.singingKeepBody : l.singingKeepNoModel,
      bodyIsError: !available,
      value: on,
      onChanged: (v) => HomeScreen.set(context, SettingKeys.keepSinging, v),
    );
  }
}
