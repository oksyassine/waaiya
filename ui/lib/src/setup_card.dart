import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'guide.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wireless_setup.dart';

/// One step of the Shizuku checklist, as the UI shows it.
class SetupStep {
  const SetupStep({required this.done, required this.title, required this.body, required this.action});
  final bool done;
  final String title;
  final String body;
  final String action;
}

/// The three Shizuku steps (install, start, grant) and which one is current (-1: all done).
/// Same rules as MainActivity.refreshSteps().
(List<SetupStep>, int) setupSteps(AppLocalizations l, SetupInfo setup) {
  final s = setup.shizuku;
  final installed = s != ShizukuState.notInstalled;
  final running = installed && s != ShizukuState.notRunning && s != ShizukuState.tooOld;
  final tooOld = s == ShizukuState.tooOld;
  final denied = s == ShizukuState.deniedPermanently;
  final steps = [
    SetupStep(done: installed, title: l.step1Title, body: l.step1Body, action: l.step1Action),
    SetupStep(
      done: running,
      title: l.step2Title,
      body: tooOld ? l.step2TooOld : l.step2Body,
      action: tooOld ? l.step2Update : l.step2Guide,
    ),
    SetupStep(
      done: setup.originalsMuted,
      title: l.step3Title,
      body: denied ? l.step2Denied : l.step3Body,
      action: denied ? l.step2Action : (setup.busy ? l.step3Busy : l.step3Action),
    ),
  ];
  return (steps, steps.indexWhere((st) => !st.done));
}

/// "One step left": the original sound cannot be silenced yet (Filter page and Setup page).
class SetupBanner extends StatelessWidget {
  const SetupBanner({super.key, this.onGo});

  /// Shows a "Go to the setup" button (Filter page).
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      color: c.warningContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: c.onWarningContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.setupBannerTitle, style: text.titleMedium?.copyWith(color: c.onWarningContainer)),
                  const SizedBox(height: 4),
                  Text(l.setupBannerBody, style: text.bodyMedium?.copyWith(color: c.onWarningContainer)),
                  if (onGo != null) ...[
                    const SizedBox(height: 8),
                    TestId('setup_go', child: FilledButton(onPressed: onGo, child: Text(l.setupGo))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The setup is needed: the original sound, the capture question, or the notification-text permission is missing.
/// In helper mode the phone refused the capture question's permission: Android asks at each start, nothing to fix.
/// Android's question before each capture ([SetupInfo.consentSkipped] false) is not a missing setup: some phones
/// never let it be skipped (vivo ignores the command, Xiaomi and the OPPO family refuse it), and the Filter page
/// says that Android will ask.
bool setupNeeded(SetupInfo setup) => !setup.originalsMuted || setup.notificationTextNeedsSetup;

/// Helper mode after a restart of the phone: Waaiya's helper must run again (Filter page and Setup page).
/// Waaiya starts it by itself when Wireless debugging is on; the button starts it (or explains) at once.
class HelperMissingBanner extends StatelessWidget {
  const HelperMissingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    final setup = WaaiyaScope.of(context).state.setup;
    return Card(
      color: c.warningContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: c.onWarningContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.helperMissingTitle, style: text.titleMedium?.copyWith(color: c.onWarningContainer)),
                  const SizedBox(height: 4),
                  Text(l.helperMissingBody, style: text.bodyMedium?.copyWith(color: c.onWarningContainer)),
                  const SizedBox(height: 8),
                  // stays usable while an automatic restart tries: a tap turns it into a normal run
                  TestId(
                    'helper_restart',
                    child: FilledButton(
                      onPressed: setup.wireless.running && !setup.helperRestarting
                          ? null
                          : () => startWirelessSetup(context),
                      child: Text(l.helperStart),
                    ),
                  ),
                  if (setup.helperRestarting) ...[
                    const SizedBox(height: 4),
                    Text(l.helperStarting, style: text.bodyMedium?.copyWith(color: c.onWarningContainer)),
                  ],
                  // a run the user started that failed: why (the steps are one tap away on the Setup page)
                  if (!setup.wireless.running && setup.wireless.phase == 'FAILED') const WirelessStatus(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple mode (TEST, Android): filtering without the one-time setup by muting media while Waaiya filters
/// (SimpleMode.kt). English only until real phones prove it.
class SimpleModeCard extends StatelessWidget {
  const SimpleModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final st = WaaiyaScope.of(context).state.settings;
    final channel = st.simpleChannel == 'notification' ? l.simpleChannelNotification : l.simpleChannelAlarm;
    return SectionCard(
      title: l.simpleTitle,
      body: l.simpleBody,
      children: [
        SettingSwitch(
          key: const Key('simple_mode'),
          id: 'switch_simple_mode',
          title: l.simpleSwitch,
          value: st.simpleMode,
          onChanged: (v) => runAction(context, (b) => b.setSetting(SettingKeys.simpleMode, v)),
        ),
        if (st.simpleMode) ...[
          ValueRow(
            label: l.simpleChannelTitle(channel),
            action: l.change,
            onPressed: () async {
              const values = ['alarm', 'notification'];
              final i = await chooseOne(context,
                  title: l.simpleChannelTitle(''),
                  options: [l.simpleChannelAlarm, l.simpleChannelNotification],
                  selected: values.indexOf(st.simpleChannel));
              if (i != null && context.mounted) {
                await runAction(context, (b) => b.setSetting(SettingKeys.simpleChannel, values[i]));
              }
            },
          ),
          Text(l.simpleChannelHelp, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l.simpleTestNote, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// The Setup page: the one-time setup on the phone (Wireless debugging), with Shizuku, or from a computer.
/// When it is done, a short "done" card, with the steps one tap away.
class SetupSection extends StatefulWidget {
  const SetupSection({super.key});

  @override
  State<SetupSection> createState() => _SetupSectionState();
}

class _SetupSectionState extends State<SetupSection> {
  bool _showAgain = false;

  @override
  Widget build(BuildContext context) {
    final s = WaaiyaScope.of(context).state;
    // simple mode (test) on Android: its card first; the real setup stays below it
    if (!s.capabilities.shizukuSetup) return _setup(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const SimpleModeCard(), _setup(context)],
    );
  }

  Widget _setup(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    final s = WaaiyaScope.of(context).state;
    final setup = s.setup;
    final caps = s.capabilities;
    final message = setup.message;
    final messageText = message == null
        ? null
        : switch (message.code) {
            'failed' => l.setupFailed(message.detail),
            'refused' => l.shizukuRefused,
            'done_restart' => l.setupDoneRestart,
            'slow' => l.setupSlow,
            'timeout' => l.setupTimeout,
            // Shizuku was refused by the phone: the on-phone setup works without the switch (Waaiya's helper)
            'refused_xiaomi' => '${l.setupRefusedXiaomi}\n${l.setupRefusedTryWireless}',
            'refused_coloros' => '${l.setupRefusedColoros}\n${l.setupRefusedTryWireless}',
            _ => message.detail,
          };
    // Xiaomi / OPPO family: the Developer options switch to change before the setup (Android SetupHelp).
    final deviceNote = switch (setup.deviceNote) {
      'xiaomi' => l.setupNoteXiaomi,
      'huawei' => l.setupNoteHuawei,
      _ => null,
    };
    final needed = setupNeeded(setup);
    final helperTip = switch (setup.helperTip) {
      'xiaomi' => l.helperTipXiaomi,
      'coloros' => l.helperTipColoros,
      _ => null,
    };
    // a run in progress stays on screen even when the permissions arrived meanwhile; the helper's own automatic
    // restart is not such a run (the banner says "starting")
    // simple mode counts as "originals muted" (no banner, no warning), but the setup itself is still offered
    if (!needed && !_showAgain && !s.settings.simpleMode && (!setup.wireless.running || setup.helperRestarting)) {
      return SectionCard(
        title: l.setupDoneTitle,
        body: setup.helperMode ? l.helperModeNote : l.setupDoneBody,
        children: [
          if (setup.helperMissing) ...[const SizedBox(height: 12), const HelperMissingBanner()],
          if (setup.helperMode && helperTip != null) ...[
            const SizedBox(height: 12),
            Text(helperTip, style: text.bodyMedium),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TestId(
              'setup_redo',
              child: TextButton(onPressed: () => setState(() => _showAgain = true), child: Text(l.setupRedo)),
            ),
          ),
        ],
      );
    }
    // One way on top, chosen by what this phone has: Shizuku already running is one tap; else the steps on the
    // phone itself (Android 11+). The others are folded under "Other ways".
    final shizukuUp = setup.shizuku == ShizukuState.ready || setup.shizuku == ShizukuState.needsPermission;
    final shizukuCard = !caps.shizukuSetup
        ? null
        : SectionCard(
            title: shizukuUp ? l.setupShizukuReadyTitle : l.wsetupShizukuHeading,
            body: l.wsetupShizukuNote,
            children: [
              ..._steps(context, l, setup),
              if (messageText != null)
                StatusText(messageText, isError: message!.code != 'done_restart' && message.code != 'slow'),
            ],
          );
    final computerCard = !(caps.adbSetup && setup.adbCommands != null)
        ? null
        : Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _ComputerSetup(commands: setup.adbCommands!),
            ),
          );
    final wizard = caps.shizukuSetup ? const WirelessSetupCard() : null;
    // a run of the on-phone setup in progress is never folded away
    final wizardOnTop = !shizukuUp || setup.wireless.running;
    final others = [if (!shizukuUp) ?shizukuCard, if (!wizardOnTop) ?wizard, ?computerCard];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!setup.originalsMuted) const SetupBanner(),
        if (setup.originalsMuted && setup.helperMissing) const HelperMissingBanner(),
        if (shizukuUp) ?shizukuCard,
        if (wizardOnTop) ?wizard,
        if (deviceNote != null)
          Card(
            color: c.warningContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(deviceNote, style: text.bodyMedium?.copyWith(color: c.onWarningContainer)),
            ),
          ),
        if (others.isNotEmpty)
          // open from the start when they are the only way (Android 10) or hold a message to read
          _OtherWays(
            label: shizukuUp ? l.setupOtherWaysPlain : l.setupOtherWays,
            initiallyOpen: !setup.wireless.supported || (messageText != null && !shizukuUp),
            children: others,
          ),
      ],
    );
  }

  List<Widget> _steps(BuildContext context, AppLocalizations l, SetupInfo setup) {
    final (steps, current) = setupSteps(l, setup);
    return [
      for (var i = 0; i < steps.length; i++)
        StepRow(
          index: i,
          done: steps[i].done,
          title: steps[i].title,
          body: steps[i].body,
          current: i == current,
          children: [
            FilledButton(
              // Step 2 (installed, not running): the wireless-debugging guide, as MainActivity.onStepAction.
              onPressed: i == 2 && setup.busy
                  ? null
                  : () => i == 1 && setup.shizuku != ShizukuState.tooOld
                      ? showShizukuGuide(context)
                      : runAction(context, (b) => b.runSetupStep(i)),
              child: Text(steps[i].action),
            ),
          ],
        ),
    ];
  }
}

/// "Other ways: Shizuku or a computer", folded so that the page shows one way to follow.
class _OtherWays extends StatefulWidget {
  const _OtherWays({required this.label, required this.children, required this.initiallyOpen});

  final String label;
  final List<Widget> children;
  final bool initiallyOpen;

  @override
  State<_OtherWays> createState() => _OtherWaysState();
}

class _OtherWaysState extends State<_OtherWays> {
  late bool _open = widget.initiallyOpen;

  @override
  void didUpdateWidget(_OtherWays old) {
    super.didUpdateWidget(old);
    if (widget.initiallyOpen && !old.initiallyOpen) _open = true; // a message arrived inside: show it
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TestId(
            'setup_other',
            child: TextButton.icon(
              onPressed: () => setState(() => _open = !_open),
              icon: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text(widget.label),
            ),
          ),
        ),
        if (_open) ...widget.children,
      ],
    );
  }
}

/// "Use a computer instead": the adb commands with a copy button.
class _ComputerSetup extends StatefulWidget {
  const _ComputerSetup({required this.commands});

  final String commands;

  @override
  State<_ComputerSetup> createState() => _ComputerSetupState();
}

class _ComputerSetupState extends State<_ComputerSetup> {
  bool _open = false;
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(l.computerToggle),
          ),
        ),
        if (_open) ...[
          Text(l.computerBody, style: text.bodyMedium),
          const SizedBox(height: 8),
          // Shell commands read left to right, also in an Arabic page.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.codeBg, borderRadius: BorderRadius.circular(12)),
              child: SelectableText(
                widget.commands,
                style: text.bodyMedium?.copyWith(fontFamily: 'monospace', color: c.textPrimary),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(_copied ? l.copied : l.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.commands));
                setState(() => _copied = true);
                _timer?.cancel();
                _timer = Timer(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _copied = false);
                });
              },
            ),
          ),
          Text(l.computerNote, style: text.bodyMedium),
        ],
      ],
    );
  }
}
