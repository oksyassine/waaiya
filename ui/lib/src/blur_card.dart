import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'guide.dart';
import 'widgets.dart';

/// The blur card's status line: text and whether it is a problem. Null: nothing to say.
/// Same rules as MainActivity.refreshBlur().
(String, bool)? blurStatus(AppLocalizations l, AppState s) {
  if (s.capabilities.blurStandalone) return _desktopBlurStatus(l, s);
  final b = s.blur;
  final on = s.filter.running;
  final needsSetup = blurNeedsSetup(s);
  final setupText = b.a11yBuild ? l.blurStatusNeedsSetup : l.blurStatusNeedsOverlay;
  final msg = b.message;
  if (msg != null) return (msg.code == 'setup_failed' ? l.blurSetupFailed(msg.detail) : msg.detail, true);
  if (!s.settings.blurOn) return null;
  if (needsSetup && !b.overlayAllowed) return (setupText, true);
  if (!on) return needsSetup ? (setupText, false) : null;
  return switch (b.state) {
    null || BlurState.starting => (l.blurStatusStarting, false), // settings apply within half a second
    BlurState.on => (l.blurStatusOn, false),
    BlurState.onCoversVisible => (l.blurStatusOnVisible, false),
    BlurState.modelsMissing => (l.blurStatusModels, true),
    BlurState.failing => (l.blurStatusFailing, true),
    BlurState.noOverlay => (l.blurStatusNoOverlay, true),
    BlurState.noCapture => (l.blurStatusNoCapture(b.error?.detail ?? ''), true),
  };
}

/// Desktop (capability `blurStandalone`): the blur runs whenever a blur option is on and the app is open; the
/// helper's reasons come in `blur.error`.
(String, bool)? _desktopBlurStatus(AppLocalizations l, AppState s) {
  final b = s.blur;
  if (!s.settings.blurOn) return null;
  final e = b.error;
  if (e?.code == 'exited') return (l.blurStatusExited(e!.detail), true);
  final detail = e?.detail ?? '';
  return switch (b.state) {
    null || BlurState.starting =>
      e?.code == 'share_dialog' ? (l.blurStatusShareDialog, false) : (l.blurStatusStarting, false),
    BlurState.on => (l.blurStatusOn, false),
    BlurState.onCoversVisible => (l.blurStatusOnVisibleDesktop, false),
    BlurState.modelsMissing => (l.blurStatusModels, true),
    BlurState.failing => (detail.isEmpty ? l.blurStatusFailing : '${l.blurStatusFailing}\n$detail', true),
    BlurState.noOverlay => (l.blurStatusNoOverlayDesktop(detail), true),
    BlurState.noCapture => (l.blurStatusNoCapture(detail), true),
  };
}

/// The blur needs an Android permission or Shizuku before it can draw (never on desktop).
bool blurNeedsSetup(AppState s) {
  final b = s.blur;
  return !s.capabilities.blurStandalone &&
      s.settings.blurOn &&
      !b.shizukuLayer &&
      (b.a11yBuild ? !b.a11yEnabled : !b.overlayAllowed);
}

/// Label of the button under the greyed-out "cover the screen" switch: the next Shizuku step, after which the
/// covers let taps through. Null: no button (taps already pass through, Android < 12, or Shizuku is ready).
/// Same rules as MainActivity.refreshBlur() (0.2.4).
String? blurFailFix(AppLocalizations l, AppState s) {
  if (s.blur.touchPassThrough || !s.blur.layerSupported) return null;
  return switch (s.setup.shizuku) {
    null || ShizukuState.ready => null,
    ShizukuState.notInstalled => l.step1Action,
    ShizukuState.tooOld => l.step2Update,
    ShizukuState.needsPermission => l.step3Action,
    ShizukuState.deniedPermanently => l.step2Action,
    ShizukuState.notRunning => l.step2Guide,
  };
}

/// Screen blur: what to cover, what to do when it cannot keep up, and the permission it needs.
class BlurCard extends StatelessWidget {
  const BlurCard({super.key, required this.onChanged});

  /// A blur setting changed (key, value); the running blur follows it within half a second.
  final void Function(String key, Object value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final b = s.blur;
    final st = s.settings;
    final desktop = s.capabilities.blurStandalone;
    final needsSetup = blurNeedsSetup(s);
    // A full-screen cover is only safe when touches pass through it; otherwise the phone could get stuck.
    final passThrough = b.touchPassThrough;
    final status = blurStatus(l, s);
    final fix = blurFailFix(l, s);
    return SectionCard(
      title: l.blurTitle,
      body: desktop ? l.blurBodyDesktop : l.blurBody,
      children: [
        const SizedBox(height: 8),
        SettingSwitch(
          title: l.blurWomenTitle,
          body: l.blurWomenBody,
          value: st.blurWomen,
          onChanged: (v) => onChanged(SettingKeys.blurWomen, v),
        ),
        SettingSwitch(
          title: l.blurNudityTitle,
          body: l.blurNudityBody,
          value: st.blurNudity,
          onChanged: (v) => onChanged(SettingKeys.blurNudity, v),
        ),
        BlurStrictnessRow(onChanged: (v) => onChanged(SettingKeys.blurStrictness, v)),
        SettingSwitch(
          key: const Key('blur_fail'),
          title: l.blurFailTitle,
          body: desktop ? l.blurFailBodyDesktop : l.blurFailBody,
          value: passThrough && st.blurFailCover,
          onChanged: passThrough ? (v) => onChanged(SettingKeys.blurFailCover, v) : null,
        ),
        if (!passThrough && !desktop)
          StatusText(
            b.a11yBuild ? l.blurFailNeedsA11y : (b.layerSupported ? l.blurFailUnavailable : l.blurFailOldAndroid),
            color: Theme.of(context).colorScheme.primary, // as the native note
          ),
        if (fix != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('blur_fail_fix'),
              onPressed: () => blurShizukuStep(context),
              child: Text(fix),
            ),
          ),
        if (status != null) StatusText(status.$1, key: const Key('blur_status'), isError: status.$2),
        if (needsSetup) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: b.busy ? null : () => blurShizukuStep(context),
            child: Text(l.blurSetupShizuku),
          ),
          if (!b.overlayAllowed) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => runAction(context, (be) => be.openOverlaySettings()),
              child: Text(l.blurSetupManual),
            ),
          ],
        ],
      ],
    );
  }
}

/// "Who is left uncovered" (Settings.blurStrictness): value, Change button and help, as
/// MainActivity.askBlurStrictness. Only in the blur card, so only where a blur exists (capability `screenBlur`).
class BlurStrictnessRow extends StatelessWidget {
  const BlurStrictnessRow({super.key, required this.onChanged});

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final level = WaaiyaScope.of(context).state.settings.blurStrictness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueRow(
          key: const Key('blur_strict'),
          label: l.blurStrictValue([l.blurStrict0Short, l.blurStrict1Short, l.blurStrict2Short][level]),
          action: l.change,
          onPressed: () async {
            final i = await chooseOne(context,
                title: l.blurStrictTitle, options: [l.blurStrict0, l.blurStrict1, l.blurStrict2], selected: level);
            if (i != null) onChanged(i);
          },
        ),
        Text(l.blurStrictHelp, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
