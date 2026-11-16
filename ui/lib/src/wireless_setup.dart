import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'theme.dart';
import 'widgets.dart';

/// Words for an Android string name sent in `setup.wireless` (title, body, hint). Null for an unknown name (a
/// newer Android side): the caller then leaves the line out rather than showing a resource name.
String? wirelessText(AppLocalizations l, String? name) => switch (name) {
      'wsetup_notif_title' => l.wsetupNotifTitle,
      'wsetup_found_title' => l.wsetupFoundTitle,
      'wsetup_busy_title' => l.wsetupBusyTitle,
      'wsetup_done_title' => l.wsetupDoneTitle,
      'wsetup_failed_title' => l.wsetupFailedTitle,
      'wsetup_done_body' => l.wsetupDoneBody,
      'wsetup_pairing' => l.wsetupPairing,
      'wsetup_connecting' => l.wsetupConnecting,
      'wsetup_need_wifi' => l.wsetupNeedWifi,
      'wsetup_need_wireless_debugging' => l.wsetupNeedWirelessDebugging,
      'wsetup_open_dialog' => l.wsetupOpenDialog,
      'wsetup_enter_code_body' => l.wsetupEnterCodeBody,
      'wsetup_code_waiting' => l.wsetupCodeWaiting,
      'wsetup_wrong_code' => l.wsetupWrongCode,
      'wsetup_pairing_failed' => l.wsetupPairingFailed,
      'wsetup_waiting_connect' => l.wsetupWaitingConnect,
      'wsetup_not_paired' => l.wsetupNotPaired,
      'wsetup_connect_failed' => l.wsetupConnectFailed,
      'wsetup_grant_failed' => l.wsetupGrantFailed,
      'wsetup_timeout' => l.wsetupTimeout,
      'setup_refused_xiaomi' => l.setupRefusedXiaomi,
      'setup_refused_coloros' => l.setupRefusedColoros,
      'wsetup_notif_off' => l.wsetupNotifOff,
      'wsetup_dev_off' => l.wsetupDevOff,
      _ => null,
    };

/// Starts the on-phone setup (MainActivity.startWireless): Developer options off → explain and offer About phone.
Future<void> startWirelessSetup(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final r = await runAction(context, (b) => b.wirelessStart());
  if (r != 'dev_off' || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l.wsetupDevOff),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.wsetupCancel)),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            runAction(context, (b) => b.openAboutPhone());
          },
          child: Text(l.wsetupOpenAbout),
        ),
      ],
    ),
  );
}

/// The pairing code typed in Waaiya (split screen, when the notification cannot be used): MainActivity.askPairingCode.
Future<void> askPairingCode(BuildContext context) {
  final l = AppLocalizations.of(context);
  final field = TextEditingController();
  String? error;
  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> pair() async {
          final ok = await runAction(context, (b) => b.wirelessEnterCode(field.text));
          if (ok == true) {
            if (ctx.mounted) Navigator.pop(ctx);
          } else {
            setState(() => error = l.wsetupCodeUnreadable);
          }
        }

        return AlertDialog(
          title: Text(l.wsetupCodeDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.wsetupCodeDialogBody),
              const SizedBox(height: 12),
              TestId(
                'wsetup_code',
                child: TextField(
                  controller: field,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(7)],
                  decoration: InputDecoration(hintText: l.wsetupCodeHint, errorText: error),
                  onSubmitted: (_) => pair(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.wsetupCancel)),
            FilledButton(onPressed: pair, child: Text(l.wsetupCodeOk)),
          ],
        );
      },
    ),
  );
}

/// Where the on-phone setup is (title, sentence, raw detail, our hint), as MainActivity.refreshWireless.
class WirelessStatus extends StatelessWidget {
  const WirelessStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    final w = WaaiyaScope.of(context).state.setup.wireless;
    final title = wirelessText(l, w.title);
    final body = wirelessText(l, w.body);
    final hint = wirelessText(l, w.hint);
    if (title == null && body == null && hint == null) return const SizedBox.shrink();
    final color = w.isError ? c.error : null;
    return TestId(
      'wsetup_status',
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: color)),
              if (body != null) Text(body, style: text.bodyMedium?.copyWith(color: color)),
              if (w.detail != null && w.detail!.isNotEmpty)
                // command output: left to right whatever the language
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(l.wsetupDetail(w.detail!), style: text.bodySmall),
                ),
              if (hint != null) ...[const SizedBox(height: 6), Text(hint, style: text.bodyMedium)],
              // Developer options were off when the run started after Android's notification question
              if (w.hint == 'wsetup_dev_off')
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => runAction(context, (b) => b.openAboutPhone()),
                    child: Text(l.wsetupOpenAbout),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Start / Type the code here / Cancel (MainActivity: wsetup_start, wsetup_enter, wsetup_cancel).
class WirelessButtons extends StatelessWidget {
  const WirelessButtons({super.key, required this.startLabel});

  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = WaaiyaScope.of(context).state.setup.wireless;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TestId(
            'wsetup_start',
            child: FilledButton(onPressed: w.running ? null : () => startWirelessSetup(context), child: Text(startLabel)),
          ),
          if (w.running) ...[
            TestId(
              'wsetup_enter',
              child: FilledButton.tonal(onPressed: () => askPairingCode(context), child: Text(l.wsetupEnterHere)),
            ),
            TestId(
              'wsetup_cancel',
              child: TextButton(onPressed: () => runAction(context, (b) => b.wirelessCancel()), child: Text(l.wsetupCancel)),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Set up on this phone": Android's own Wireless debugging, no extra app (Android 11+).
class WirelessSetupCard extends StatelessWidget {
  const WirelessSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final w = WaaiyaScope.of(context).state.setup.wireless;
    if (!w.supported) return SectionCard(title: l.wsetupRouteTitle, body: l.wsetupAndroid10);
    return SectionCard(
      title: l.wsetupRouteTitle,
      body: l.wsetupRouteBody,
      children: [
        const SizedBox(height: 12),
        Text(l.wsetupSteps, style: text.bodyMedium),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TestId(
            'wsetup_guide',
            child: TextButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => runAction(context, (b) => b.openSetupGuide()),
              label: Text(l.wsetupGuide),
            ),
          ),
        ),
        const WirelessStatus(),
        WirelessButtons(startLabel: l.wsetupStart),
      ],
    );
  }
}

/// Screen page, Android 12+ with a blur option on: who draws the covers, so that touches pass through them, and
/// the button that starts Waaiya's own helper (CoverHelper, through the on-phone setup).
class CoverHelperCard extends StatelessWidget {
  const CoverHelperCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final b = s.blur;
    if (s.capabilities.blurStandalone || !b.layerSupported || !s.settings.blurOn) return const SizedBox.shrink();
    final String body;
    if (b.helperRunning) {
      body = l.helperOn;
    } else if (b.shizukuLayer) {
      body = l.helperShizukuOn;
    } else {
      body = l.helperBodyOff;
    }
    final offer = !b.helperRunning && b.helperStartable;
    return SectionCard(
      title: l.helperTitle,
      children: [
        StatusText(body, id: 'helper_status'),
        if (offer || s.setup.wireless.running) ...[
          const WirelessStatus(),
          WirelessButtons(startLabel: l.helperStart),
        ],
      ],
    );
  }
}
