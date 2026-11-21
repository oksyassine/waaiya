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
/// Hidden for now on every platform (owner's decision, 2026-11-20: keep singing is meant to apply by itself to women,
/// with no setting; until that is decided it is not offered). Shown only while the setting is still on, so that
/// someone who turned it on before can turn it off; without the model it says so (the filter then stays silent).
class SingingOptionSwitch extends StatelessWidget {
  const SingingOptionSwitch({super.key});

  /// false: the switch is not offered (see above). The setting, the snapshot section and the engines stay.
  static const offered = false;

  @override
  Widget build(BuildContext context) {
    final s = WaaiyaScope.of(context).state;
    final available = s.feature('singing')['available'] == true;
    final on = s.settings.keepSinging;
    if (!on && !(offered && available)) return const SizedBox.shrink();
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
