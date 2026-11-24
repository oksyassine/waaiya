import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

/// The blur card's status line: text and whether it is a problem. Null: nothing to say.
/// Same rules as MainActivity.refreshBlur().
(String, bool)? blurStatus(AppLocalizations l, AppState s) {
  if (s.capabilities.blurStandalone) return _desktopBlurStatus(l, s);
  final b = s.blur;
  final on = s.filter.running;
  final needsSetup = blurNeedsSetup(s);
  final setupText = b.a11yBuild ? l.blurStatusNeedsSetup : l.blurStatusNeedsOverlay;
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
  final on = b.state == BlurState.on || b.state == BlurState.onCoversVisible;
  // on, but a monitor is left out (not shared, plugged in later): said first, in the error colour
  if (on && b.uncovered > 0) return (l.blurStatusUncovered, true);
  return switch (b.state) {
    null || BlurState.starting =>
      e?.code == 'share_dialog' ? (l.blurStatusShareDialog, false) : (l.blurStatusStarting, false),
    BlurState.on => (l.blurStatusOn, false),
    BlurState.onCoversVisible => (l.blurStatusOnVisibleDesktop, false),
    BlurState.modelsMissing =>
      (detail.isEmpty ? l.blurStatusModelsMissingDesktop : '${l.blurStatusModelsMissingDesktop}\n$detail', true),
    BlurState.failing => (detail.isEmpty ? l.blurStatusFailing : '${l.blurStatusFailing}\n$detail', true),
    BlurState.noOverlay => (l.blurStatusNoOverlayDesktop(detail), true),
    BlurState.noCapture => (l.blurStatusNoCapture(detail), true),
  };
}

/// The blur needs an Android permission, or the setup's helper, before it can draw (never on desktop).
bool blurNeedsSetup(AppState s) {
  final b = s.blur;
  return !s.capabilities.blurStandalone &&
      s.settings.blurOn &&
      !b.shellLayer &&
      (b.a11yBuild ? !b.a11yEnabled : !b.overlayAllowed);
}

/// The Setup page exists and its helper would let taps through the covers (Android 12+).
bool _setupHelps(AppState s) =>
    s.blur.layerSupported && (s.capabilities.adbSetup || s.capabilities.shizukuSetup);

/// The blur is covering now, or about to: on Android it runs while filtering is on.
bool blurActive(AppState s) =>
    s.settings.blurOn && (s.capabilities.blurStandalone || s.filter.running);

/// Screen page, top: the blur's own on/off control and its state in words, as the Filter page's.
/// On Android the blur runs with filtering, so turning it on also starts filtering when it is off.
class BlurPowerSection extends StatelessWidget {
  const BlurPowerSection({super.key});

  Future<void> _turnOn(BuildContext context) async {
    final s = WaaiyaScope.of(context).state;
    final st = s.settings;
    await runAction(context, (b) async {
      if (!st.blurEnabled) await b.setSetting(SettingKeys.blurEnabled, true);
      if (!st.blurWomen && !st.blurNudity) {
        // nothing chosen yet: everything the blur can cover (the choices are below)
        await b.setSetting(SettingKeys.blurWomen, true);
        await b.setSetting(SettingKeys.blurNudity, true);
      }
    });
    if (!context.mounted || s.capabilities.blurStandalone || s.filter.running) return;
    await startFiltering(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    final s = WaaiyaScope.of(context).state;
    final b = s.blur;
    final desktop = s.capabilities.blurStandalone;
    final on = blurActive(s);
    final starting = s.settings.blurOn && !desktop && s.filter.state == FilterState.starting;
    final title = on ? l.blurOnTitle : l.blurOffTitle;
    final status = on || s.settings.blurOn ? blurStatus(l, s) : null;
    final (detail, isError) = status ?? (on ? ('', false) : (desktop ? l.stateOffDetail : l.blurOffDetail, false));
    final needsSetup = blurNeedsSetup(s);
    return Column(
      children: [
        Text(desktop ? l.blurBodyDesktop : l.blurBody, style: text.bodyMedium),
        const SizedBox(height: 24),
        Semantics(
          container: true,
          button: true,
          identifier: 'blur_power',
          label: on ? l.blurStopCd : l.blurStartCd,
          excludeSemantics: true,
          child: PowerButton(
            key: const Key('blur_power'),
            on: on,
            starting: starting,
            onTap: () {
              HapticFeedback.mediumImpact();
              on
                  ? runAction(context, (be) => be.setSetting(SettingKeys.blurEnabled, false))
                  : _turnOn(context);
            },
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: SwitchFade(child: Text(title, key: ValueKey(title), style: text.titleLarge, textAlign: TextAlign.center)),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 6),
          TestId(
            'blur_status',
            key: const Key('blur_status'),
            child: SwitchFade(
              child: Text(detail,
                  key: ValueKey('$detail$isError'),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: isError ? c.error : null)),
            ),
          ),
        ],
        if (needsSetup) ...[
          const SizedBox(height: 16),
          if (_setupHelps(s))
            FilledButton(
              key: const Key('blur_go_setup'),
              onPressed: () => HomeNav.maybeOf(context)?.go('setup'),
              child: Text(l.setupGo),
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

/// Screen page: what the blur covers, and what it does when it cannot keep up.
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
    // A full-screen cover is only safe when touches pass through it; otherwise the phone could get stuck.
    final passThrough = b.touchPassThrough;
    return SectionCard(
      title: l.blurWhatTitle,
      children: [
        const SizedBox(height: 8),
        SettingSwitch(
          id: 'switch_blur_women',
          title: l.blurWomenTitle,
          body: l.blurWomenBody,
          value: st.blurWomen,
          onChanged: (v) => onChanged(SettingKeys.blurWomen, v),
        ),
        SettingSwitch(
          id: 'switch_blur_nudity',
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
        if (!passThrough && !desktop) ...[
          StatusText(
            b.a11yBuild ? l.blurFailNeedsA11y : (b.layerSupported ? l.blurFailUnavailable : l.blurFailOldAndroid),
            color: Theme.of(context).colorScheme.primary, // as the native note
          ),
          // the setup starts the helper, after which this switch turns on (the power section shows it when needed)
          if (_setupHelps(s) && !blurNeedsSetup(s))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('blur_fail_fix'),
                onPressed: () => HomeNav.maybeOf(context)?.go('setup'),
                child: Text(l.setupGo),
              ),
            ),
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
