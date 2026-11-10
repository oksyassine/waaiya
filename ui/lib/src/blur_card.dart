import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'guide.dart';
import 'widgets.dart';

/// The blur card's status line: text and whether it is a problem. Null: nothing to say.
/// Same rules as MainActivity.refreshBlur().
(String, bool)? blurStatus(AppLocalizations l, AppState s) {
  final b = s.blur;
  final on = s.filter.running;
  final needsSetup = s.settings.blurOn && !b.shizukuLayer && (b.a11yBuild ? !b.a11yEnabled : !b.overlayAllowed);
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
  };
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
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final b = s.blur;
    final st = s.settings;
    final needsSetup = st.blurOn && !b.shizukuLayer && (b.a11yBuild ? !b.a11yEnabled : !b.overlayAllowed);
    // A full-screen cover is only safe when touches pass through it; otherwise the phone could get stuck.
    final passThrough = b.touchPassThrough;
    final status = blurStatus(l, s);
    final fix = blurFailFix(l, s);
    return SectionCard(
      title: l.blurTitle,
      body: l.blurBody,
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
        SettingSwitch(
          title: l.blurFailTitle,
          body: l.blurFailBody,
          value: passThrough && st.blurFailCover,
          onChanged: passThrough ? (v) => onChanged(SettingKeys.blurFailCover, v) : null,
        ),
        if (!passThrough)
          StatusText(b.a11yBuild
              ? l.blurFailNeedsA11y
              : (b.layerSupported ? l.blurFailUnavailable : l.blurFailOldAndroid)),
        if (fix != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('blur_fail_fix'),
              onPressed: () => blurShizukuStep(context),
              child: Text(fix),
            ),
          ),
        if (status != null) StatusText(status.$1, isError: status.$2),
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
