import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
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
      'wsetup_done_helper_body' => l.wsetupDoneHelperBody,
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
      'wsetup_filter_on' => l.wsetupFilterOn,
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
      scrollable: true, // large text on a small screen: nothing is cut off
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
          scrollable: true, // large text on a small screen: nothing is cut off
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

/// The guided steps and which one is current (4: nothing left to do here). The ticks come from what Waaiya can see
/// of the phone; they are hints, so the last two steps stay reachable whatever the first two say.
(List<bool>, int) wirelessSteps(SetupInfo setup) {
  final w = setup.wireless;
  // this run finished (a stale "done" does not count once the helper it started is gone)
  final finished = w.phase == 'DONE' && !setup.helperMissing;
  // seen on, or the run got far enough to prove it (a pairing screen was found, pairing, connecting)
  final debuggingOn = w.wirelessDebugging == true ||
      (w.running && (w.phase == 'PAIRING' || w.phase == 'CONNECTING' || w.title == 'wsetup_found_title'));
  final done = [
    w.devOptions || debuggingOn || finished,
    w.wifi || debuggingOn || finished,
    debuggingOn || finished,
    finished,
  ];
  return (done, done.indexWhere((d) => !d).let((i) => i < 0 ? 4 : i));
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// "Set up on this phone": Android's own Wireless debugging, no extra app (Android 11+), as four steps that tick
/// themselves, with one button for the current step.
/// What the phone shows at a step, with the place to tap marked: the illustrated guide's pictures, in the app's
/// language. Nothing where the backend has no pictures (desktop, tests).
class GuidePictures extends StatelessWidget {
  const GuidePictures(this.names, {super.key});

  final List<String> names;

  static final _cache = <String, Future<Uint8List?>>{};

  @override
  Widget build(BuildContext context) {
    final scope = WaaiyaScope.of(context);
    return Column(
      children: [
        for (final name in names)
          FutureBuilder<Uint8List?>(
            future: _cache.putIfAbsent('${scope.state.language}/$name',
                () => scope.backend.guidePicture(name).catchError((Object _) => null)),
            builder: (context, snap) {
              final bytes = snap.data;
              if (bytes == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.memory(bytes, key: Key('guide_pic_$name'), gaplessPlayback: true),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class WirelessSetupCard extends StatelessWidget {
  const WirelessSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final setup = WaaiyaScope.of(context).state.setup;
    final w = setup.wireless;
    if (!w.supported) return SectionCard(title: l.wsetupRouteTitle, body: l.wsetupAndroid10);
    final (done, current) = wirelessSteps(setup);
    // The make's own path, and always the way out: these names change with the phone's language and version.
    final makeBody = switch (w.aboutHint) {
      'samsung' => l.wizDevBodySamsung,
      'xiaomi' => l.wizDevBodyXiaomi,
      'coloros' => l.wizDevBodyColoros,
      'vivo' => l.wizDevBodyVivo,
      'huawei' => l.wizDevBodyHuawei,
      'transsion' => l.wizDevBodyTranssion,
      _ => null,
    };
    final devBody = makeBody == null ? l.wizDevBody : '$makeBody ${l.wizDevSearch}';
    // Steps 3 and 4 share one run of the setup service: its button, its live status, the code field, cancel.
    // The same block stays reachable outside them: under the first steps once a run exists (its status must show),
    // and when every step is ticked (to run the setup again).
    final run = [
      const WirelessStatus(),
      WirelessButtons(startLabel: switch (current) { 3 => l.wizPairAction, 4 => l.wizAgain, _ => l.wizWdAction }),
    ];
    final ranBefore = w.running || w.phase != null;
    return SectionCard(
      title: l.wsetupRouteTitle,
      body: l.wsetupRouteBody,
      children: [
        StepRow(
          index: 0,
          done: done[0],
          title: l.wizDevTitle,
          body: devBody,
          current: current == 0,
          children: [
            TestId(
              'wiz_about',
              child: FilledButton(
                onPressed: () => runAction(context, (b) => b.openAboutPhone()),
                child: Text(l.wizDevAction),
              ),
            ),
            const GuidePictures(['guide_1_about']),
          ],
        ),
        StepRow(
          index: 1,
          done: done[1],
          title: l.wizWifiTitle,
          body: l.wizWifiBody,
          current: current == 1,
          children: [
            TestId(
              'wiz_wifi',
              child: FilledButton(
                onPressed: () => runAction(context, (b) => b.openWifiSettings()),
                child: Text(l.wizWifiAction),
              ),
            ),
          ],
        ),
        StepRow(
          index: 2,
          done: done[2],
          title: l.wizWdTitle,
          body: l.wizWdBody,
          current: current == 2,
          children: [...run, const GuidePictures(['guide_2_dev', 'guide_3_allow'])],
        ),
        StepRow(
          index: 3,
          done: done[3],
          title: l.wizPairTitle,
          body: w.paired ? l.wizPairBodyPaired : l.wizPairBody,
          current: current == 3,
          children: [
            ...run,
            if (!w.paired) const GuidePictures(['guide_4_pair', 'guide_7_notif', 'guide_8_reply']),
          ],
        ),
        // the first two ticks are guesses (Wi-Fi by the interface name): never a dead end
        if (current < 2 && !ranBefore)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TestId(
                'wsetup_start',
                child: TextButton(onPressed: () => startWirelessSetup(context), child: Text(l.wizSkip)),
              ),
            ),
          ),
        if ((current < 2 && ranBefore) || current == 4) ...run,
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
    } else if (b.shellLayer) {
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
