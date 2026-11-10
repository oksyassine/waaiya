import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'theme.dart';
import 'widgets.dart';

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
      action: tooOld ? l.step2Update : l.step2Action,
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

/// The warning banner and the one-time setup card (Shizuku steps, or adb commands from a computer).
class SetupSection extends StatelessWidget {
  const SetupSection({super.key});

  @override
  Widget build(BuildContext context) {
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
            _ => message.detail,
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!setup.originalsMuted)
          Card(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!(setup.originalsMuted && setup.consentSkipped))
          SectionCard(
            title: l.setupTitle,
            body: l.setupBody,
            children: [
              if (caps.shizukuSetup) ..._steps(context, l, setup),
              if (messageText != null) StatusText(messageText, isError: message!.code != 'done_restart'),
              if (caps.adbSetup && setup.adbCommands != null) ...[
                const Divider(),
                _ComputerSetup(commands: setup.adbCommands!),
              ],
            ],
          ),
      ],
    );
  }

  List<Widget> _steps(BuildContext context, AppLocalizations l, SetupInfo setup) {
    final (steps, current) = setupSteps(l, setup);
    return [
      for (var i = 0; i < steps.length; i++)
        _StepRow(
          index: i,
          step: steps[i],
          current: i == current,
          enabled: !(i == 2 && setup.busy),
          onPressed: () => runAction(context, (b) => b.runSetupStep(i)),
        ),
    ];
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.current,
    required this.enabled,
    required this.onPressed,
  });

  final int index;
  final SetupStep step;
  final bool current;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.done ? c.primary : null,
                border: step.done ? null : Border.all(color: c.offRing, width: 2),
              ),
              child: step.done
                  ? Icon(Icons.check_rounded, size: 20, color: c.onPrimary)
                  : Text('${index + 1}', style: text.bodyLarge),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '${step.done ? l.stepDoneCd : l.stepTodoCd(index + 1)}. ${step.title}',
                  excludeSemantics: true,
                  child: Text(step.title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 2),
                Text(step.body, style: text.bodyMedium),
                if (current) ...[
                  const SizedBox(height: 8),
                  FilledButton(onPressed: enabled ? onPressed : null, child: Text(step.action)),
                ],
              ],
            ),
          ),
        ],
      ),
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
