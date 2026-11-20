/// "Reply to calls by SMS during prayer" (owner's request, 2026-11-20): native side WorshipSms.kt, rules in
/// WorshipSmsRules.kt. Shown only where the build has it (`features.worship.smsSupported`; not in Play builds).
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'widgets.dart';
import 'worship.dart';

const worshipSmsSeconds = [3, 5, 8, 10, 15, 20, 30, 45, 60];

class WorshipSmsSection extends StatelessWidget {
  const WorshipSmsSection({super.key, required this.info, required this.missing, required this.turnOn});

  final WorshipInfo info;

  /// `phone` or `sms` when the user refused it at the last turn-on; null otherwise.
  final String? missing;

  /// Asks the permissions one after another, then turns the option on (WorshipCard).
  final Future<void> Function() turnOn;

  Future<void> _editText(BuildContext context, String current) async {
    final l = AppLocalizations.of(context);
    final ml = MaterialLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final r = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.worshipSmsTextTitle),
        content: TextField(
          key: const Key('worship_sms_text_field'),
          controller: controller,
          maxLength: 300,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(hintText: l.worshipSmsDefault),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, ''), child: Text(l.worshipSmsTextDefault)),
          TextButton(onPressed: () => Navigator.pop(dialog), child: Text(ml.cancelButtonLabel)),
          TextButton(
              key: const Key('worship_sms_text_ok'),
              onPressed: () => Navigator.pop(dialog, controller.text.trim()),
              child: Text(ml.okButtonLabel)),
        ],
      ),
    );
    controller.dispose();
    if (r != null && context.mounted) await HomeScreen.set(context, SettingKeys.prayerSmsText, r);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final st = WaaiyaScope.of(context).state.settings;
    final text = Theme.of(context).textTheme;
    final on = st.prayerSmsReply;
    return Column(
      key: const Key('worship_sms'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingSwitch(
          key: const Key('worship_sms_switch'),
          id: 'switch_worship_sms',
          title: l.worshipSmsTitle,
          body: l.worshipSmsBody,
          value: on,
          onChanged: info.placeValid || on
              ? (v) => v ? turnOn() : HomeScreen.set(context, SettingKeys.prayerSmsReply, false)
              : null,
        ),
        if (missing != null && !on)
          Column(
            key: const Key('worship_sms_missing'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusText(missing == 'phone' ? l.worshipMissingPhone : l.worshipMissingSms, isError: true),
              TextButton(onPressed: turnOn, child: Text(l.worshipTryAgain)),
            ],
          ),
        if (on) ...[
          ValueRow(
            key: const Key('worship_sms_delay'),
            label: l.worshipSmsDelay(st.prayerSmsDelaySeconds),
            action: l.change,
            onPressed: () async {
              final i = await chooseOne(context,
                  title: l.worshipSmsDelayTitle,
                  options: [for (final s in worshipSmsSeconds) l.worshipSmsSecondsOption(s)],
                  selected: worshipSmsSeconds.indexOf(st.prayerSmsDelaySeconds));
              if (i != null && context.mounted) {
                await HomeScreen.set(context, SettingKeys.prayerSmsDelaySeconds, worshipSmsSeconds[i]);
              }
            },
          ),
          ValueRow(
            key: const Key('worship_sms_text'),
            label: l.worshipSmsText(st.prayerSmsText.isEmpty ? l.worshipSmsDefault : st.prayerSmsText),
            action: l.change,
            onPressed: () => _editText(context, st.prayerSmsText),
          ),
          // a permission taken back later in Android's settings
          if (!info.smsPhone || !info.smsSend)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusText(!info.smsPhone ? l.worshipMissingPhone : l.worshipMissingSms, isError: true),
                TextButton(onPressed: turnOn, child: Text(l.worshipTryAgain)),
              ],
            ),
          StatusText(info.smsRoaming ? l.worshipSmsRoaming : l.worshipSmsCost, isError: info.smsRoaming),
          if (info.smsLog.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.worshipSmsLogTitle, style: text.titleSmall),
            for (final (hm, number) in info.smsLog.take(10))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                // a time and a phone number: left to right in every language
                child: Text('$hm   $number', style: text.bodyMedium, textDirection: TextDirection.ltr),
              ),
          ],
        ],
      ],
    );
  }
}
