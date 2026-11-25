import 'app_move.dart';
import 'app_update.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'blur_card.dart';
import 'fix_mistakes.dart';
import 'licences.dart';
import 'links_page.dart';
import 'motion.dart';
import 'protection.dart';
import 'setup_card.dart';
import 'singing_option.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wireless_setup.dart';
import 'worship.dart';

/// The pages of the main screen, in bottom-bar order. Pages without the capability are left out (desktop: Filter,
/// Screen when it has a blur, Settings).
const homePages = ['filter', 'screen', 'links', 'setup', 'settings'];

/// Switches the main screen's page from anywhere below it ("Do the setup" in the start dialog).
class HomeNav extends InheritedWidget {
  const HomeNav({super.key, required this.go, required super.child});

  final void Function(String page) go;

  static HomeNav? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HomeNav>();

  @override
  bool updateShouldNotify(HomeNav old) => false;
}

/// Main screen: a bottom bar with one page per purpose, so that no page is long. Filter: the on/off control with
/// its state in words and the filter options. Screen: the screen blur. Links: playing a link filtered. Setup: the
/// one-time setup. Settings: who uses the phone, language, the report and licences. Shows the same things, under
/// the same conditions, as the native MainActivity. Settings apply live (the running filter and blur re-read them
/// every half second), so there is no "restart" note.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Future<void> set(BuildContext context, String key, Object value) =>
      runAction(context, (b) => b.setSetting(key, value));

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _page = 'filter';
  int? _handledRequest;

  List<String> _pages(AppState s) {
    final caps = s.capabilities;
    return [
      for (final p in homePages)
        if (switch (p) {
          'screen' => caps.screenBlur,
          'links' => caps.links,
          'setup' => caps.shizukuSetup || caps.adbSetup,
          _ => true,
        })
          p,
    ];
  }

  void _go(String page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = WaaiyaScope.of(context);
    final s = scope.state;
    final pages = _pages(s);
    // a page asked for by the platform (a Quick Settings tile's "Open Waaiya"): shown once
    final request = s.navigate;
    if (request != null && request.id != _handledRequest) {
      _handledRequest = request.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (pages.contains(request.page)) setState(() => _page = request.page);
        scope.backend.pageShown();
      });
    }
    final index = pages.indexOf(_page).clamp(0, pages.length - 1);
    final setupMissing = !s.setup.originalsMuted || s.setup.helperMissing;
    return HomeNav(
      go: (p) => pages.contains(p) ? _go(p) : null,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: index,
            children: [for (final p in pages) _PageIn(active: p == pages[index], child: _body(context, p, s))],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => _go(pages[i]),
          destinations: [
            for (final p in pages)
              TestId(
                'nav_$p',
                key: Key('nav_$p'),
                child: switch (p) {
                  'filter' => NavigationDestination(
                      icon: const Icon(Icons.graphic_eq_rounded), label: l.navFilter),
                  'screen' => NavigationDestination(
                      icon: const Icon(Icons.blur_on_rounded), label: l.navScreen),
                  'links' => NavigationDestination(icon: const Icon(Icons.link_rounded), label: l.navLinks),
                  'setup' => NavigationDestination(
                      icon: Badge(isLabelVisible: setupMissing, child: const Icon(Icons.build_circle_outlined)),
                      selectedIcon: Badge(isLabelVisible: setupMissing, child: const Icon(Icons.build_circle)),
                      label: l.navSetup),
                  _ => NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: l.navSettings),
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, String page, AppState s) {
    final l = AppLocalizations.of(context);
    final caps = s.capabilities;
    void set(String key, Object v) => HomeScreen.set(context, key, v);
    return switch (page) {
      'filter' => PageColumn(
          children: [
            const AppHeader(),
            const SizedBox(height: 24),
            const MoveCard(),
            const PowerSection(),
            const SizedBox(height: 16),
            if ((caps.shizukuSetup || caps.adbSetup) && !s.setup.originalsMuted) SetupBanner(onGo: () => _go('setup')),
            if (s.setup.originalsMuted && s.setup.helperMissing) const HelperMissingBanner(),
            const FilterOptionsCard(),
            const FilterAppsCard(),
          ],
        ),
      'screen' => PageColumn(
          children: [
            PageTitle(l.navScreen),
            const BlurPowerSection(),
            const SizedBox(height: 16),
            BlurCard(onChanged: set),
            const BlurAppsCard(),
            const CoverHelperCard(),
          ],
        ),
      'links' when caps.linkPage => PageColumn(children: [PageTitle(l.navLinks), const LinksPanel()]),
      'links' => PageColumn(
          children: [
            PageTitle(l.navLinks),
            SectionCard(
              title: l.linkEntryTitle,
              body: l.linkEntryBody,
              children: [
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => runAction(context, (b) => b.openLinkScreen()),
                  child: Text(l.linkOpen),
                ),
              ],
            ),
            SectionCard(title: l.playerTitle, body: l.playerBody),
          ],
        ),
      'setup' => PageColumn(children: [PageTitle(l.navSetup), const SetupSection()]),
      _ => PageColumn(
          children: [
            PageTitle(l.navSettings),
            const MoveCard(),
            const GeneralSettingsCard(),
            const WorshipCard(),
            const ProtectionCard(),
            const UpdateCard(),
            const SizedBox(height: 16),
            TestId(
              'diagnostics',
              child: TextButton(
                key: const Key('diagnostics'),
                onPressed: () => showDiagnostics(context),
                child: Text(l.diagButton),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LicencesScreen())),
              child: Text(l.licences),
            ),
            Center(child: Text('Waaiya ${s.version}', style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
    };
  }
}

/// How the filter works: what to do with apps that block it, holding silence, stereo, women's singing.
class FilterOptionsCard extends StatelessWidget {
  const FilterOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final st = s.settings;
    final singingNoModel = st.muteWomenSinging && !s.detectorModel;
    // the texts say "Android" and "phone"; a computer has its own (and no app there can refuse to be filtered)
    final android = s.platform == 'android';
    void set(String key, Object v) => HomeScreen.set(context, key, v);
    return SectionCard(
      title: l.filterOptionsTitle,
      children: [
        const SizedBox(height: 8),
        if (android)
          SettingSwitch(
            id: 'switch_silence',
            title: l.settingSilenceTitle,
            body: l.settingSilenceBody,
            value: st.silenceUnfilterable,
            onChanged: (v) => set(SettingKeys.silenceUnfilterable, v),
          ),
        SettingSwitch(
          key: const Key('hold_silence'),
          id: 'switch_hold_silence',
          title: l.settingHoldSilenceTitle,
          body: android ? l.settingHoldSilenceBody : l.settingHoldSilenceBodyDesktop,
          value: st.holdSilence,
          onChanged: (v) => set(SettingKeys.holdSilence, v),
        ),
        SettingSwitch(
          key: const Key('audio_stereo'),
          id: 'switch_stereo',
          title: l.settingStereoTitle,
          body: android ? l.settingStereoBody : l.settingStereoBodyDesktop,
          value: st.audioStereo,
          onChanged: (v) => set(SettingKeys.audioStereo, v),
        ),
        if (st.isMan && s.capabilities.womenSinging)
          SettingSwitch(
            id: 'switch_singing',
            title: l.settingSingingTitle,
            body: singingNoModel ? l.settingSingingNoModel : l.settingSingingBody,
            bodyIsError: singingNoModel,
            value: st.muteWomenSinging,
            onChanged: (v) => set(SettingKeys.muteWomenSinging, v),
          ),
        const SingingOptionSwitch(),
      ],
    );
  }
}

/// Who uses the phone, the language, starting at login (desktop).
class GeneralSettingsCard extends StatelessWidget {
  const GeneralSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final st = s.settings;
    return SectionCard(
      title: l.settingsGeneralTitle,
      children: [
        const SizedBox(height: 8),
        if (s.capabilities.autostart)
          SettingSwitch(
            key: const Key('autostart'),
            title: l.autostartTitle,
            body: l.autostartBody,
            value: s.filter.autostart,
            onChanged: (v) => runAction(context, (b) => b.setAutostart(v)),
          ),
        ValueRow(
          label: '${l.settingGenderTitle}: ${st.isMan ? l.genderMan : l.genderWoman}',
          action: l.change,
          onPressed: () async {
            final i = await chooseOne(context,
                title: l.settingGenderTitle, options: [l.genderMan, l.genderWoman], selected: st.isMan ? 0 : 1);
            if (i != null && context.mounted) await HomeScreen.set(context, SettingKeys.gender, i == 0 ? 'man' : 'woman');
          },
        ),
        ValueRow(
          label: l.settingLanguageTitle(appLanguages[s.language] ?? s.language),
          action: l.change,
          onPressed: () => chooseLanguage(context),
        ),
      ],
    );
  }
}

/// The diagnostics report (MainActivity.showDiagnostics): what the app sees, to copy and give to whoever helps.
Future<void> showDiagnostics(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final s = WaaiyaScope.of(context).state;
  final report = await runAction(context, (b) => b.diagnosticsReport());
  if (report == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.diagTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.platform == 'android' ? l.diagNote : l.diagNoteDesktop),
            const SizedBox(height: 12),
            // the report is technical English: read left to right whatever the language
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(report, key: const Key('diag_report'), style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.guideClose)),
        // Android: send it straight to whoever helps (MainActivity's Share button)
        if (s.platform == 'android')
          TextButton(
            key: const Key('diag_share'),
            onPressed: () {
              Navigator.pop(ctx);
              runAction(context, (b) => b.shareText(report));
            },
            child: Text(l.linkShare),
          ),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (ctx.mounted) Navigator.pop(ctx);
            messenger?.showSnackBar(SnackBar(content: Text(l.copied)));
          },
          child: Text(l.copy),
        ),
      ],
    ),
  );
}

/// Start was tapped (MainActivity.startFilter): without the one-time setup the original sound cannot be silenced,
/// so say so before starting, not only in the setup card.
Future<void> startFiltering(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final s = WaaiyaScope.of(context).state;
  if (s.capabilities.shizukuSetup && !s.setup.originalsMuted) {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true, // large text on a small screen: nothing is cut off
        title: Text(l.startNoSetupTitle),
        content: Text(l.startNoSetupBody),
        actions: [
          TextButton(key: const Key('start_anyway'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.startNoSetupAnyway)),
          FilledButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.startNoSetupSetup)),
        ],
      ),
    );
    if (!context.mounted || go == null) return;
    if (!go) {
      HomeNav.maybeOf(context)?.go('setup');
      return;
    }
  }
  // helper mode, the helper stopped and not coming back by itself (Wireless debugging off): say so before starting
  if (s.setup.helperMissing && !s.setup.helperRestarting) {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true, // large text on a small screen: nothing is cut off
        title: Text(l.helperStartAnywayTitle),
        content: Text(l.helperStartAnywayBody),
        actions: [
          TextButton(key: const Key('start_anyway'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.startNoSetupAnyway)),
          FilledButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.helperStart)),
        ],
      ),
    );
    if (!context.mounted || go == null) return;
    if (!go) {
      await startWirelessSetup(context);
      return;
    }
  }
  await runAction(context, (b) => b.startFilter());
}

/// The line under the title while filtering (MainActivity.refresh): a problem first, else the delay and what was
/// adapted for this device or silenced. Returns the text and whether it is a problem.
(String, bool) filteringDetail(AppLocalizations l, AppState s) {
  final f = s.filter;
  final problem = switch (f.problem) {
    FilterProblem.tooSlow => l.stateTooSlow,
    FilterProblem.notMuted => l.stateOnNotMuted,
    FilterProblem.helperMissing => l.stateOnHelperMissing,
    FilterProblem.muteFailing => l.stateOnMuteFailing,
    FilterProblem.detectorFailed => l.engineDetectorFailed,
    _ => null,
  };
  if (problem != null) return (problem, true);
  return (
    [
      // no measured delay (desktop host): the sentence without it
      f.delayMs > 0 ? l.stateOnDetail(f.delayMs) : l.stateOnDetailNoDelay,
      if (f.mono) l.stateMonoNote,
      if (s.settings.simpleMode && s.platform == 'android') l.simpleOnDetail,
      if (f.blockedApps.isNotEmpty)
        s.settings.silenceUnfilterable
            ? l.stateBlockedSilenced(f.blockedApps.join('، '))
            : l.stateBlockedUnfiltered(f.blockedApps.join('، ')),
    ].join('\n'),
    false
  );
}

/// The on/off control (state shown by its fill AND in words) and the state texts.
class PowerSection extends StatelessWidget {
  const PowerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    final s = WaaiyaScope.of(context).state;
    final f = s.filter;
    final on = f.running;

    final android = s.platform == 'android';
    final title = switch (f.state) {
      FilterState.starting => l.stateStarting,
      FilterState.filtering || FilterState.modelFailed => l.stateOnTitle,
      FilterState.silenced => l.stateSilencedTitle,
      // desktop: the service died or failed by itself ("Waaiya stopped", as Android's notification)
      FilterState.stoppedBySystem when !android => l.notifStoppedTitle,
      _ => l.stateOffTitle,
    };
    final filtering = f.state == FilterState.filtering ? filteringDetail(l, s) : null;
    var detail = switch (f.state) {
      FilterState.filtering => filtering!.$1,
      FilterState.modelFailed => l.stateModelFailed,
      FilterState.noCapturePermission => l.stateCaptureDenied,
      FilterState.stoppedBySystem => android ? l.stateStoppedBySystem : l.notifStoppedText,
      FilterState.captureFailed => l.stateCaptureFailed,
      FilterState.silenced => l.stateSilenced,
      FilterState.starting => '',
      FilterState.stopped => l.stateOffDetail,
    };
    var detailIsError = (filtering?.$2 ?? false) ||
        f.state == FilterState.modelFailed ||
        f.state == FilterState.noCapturePermission ||
        f.state == FilterState.captureFailed ||
        f.state == FilterState.silenced ||
        (f.state == FilterState.stoppedBySystem && !android);
    if (!on && (f.micDenied || f.captureCancelled)) {
      detail = f.micDenied ? l.needRecordAudio : l.stateCaptureCancelled;
      detailIsError = true;
    }
    final error = f.error;
    String? technical;
    if (error != null) {
      // the sentence in the app's language; the program's own lines apart, left to right (they are English, paths
      // and times: inside an Arabic sentence they came out jumbled)
      final withLines = const {'install_failed', 'start_failed', 'service_failed'}.contains(error.code);
      technical = withLines && error.detail.trim().isNotEmpty ? error.detail.trim() : null;
      detail = engineErrorText(l, withLines ? BackendMessage(error.code) : error).trim();
      detailIsError = true;
    }

    return Column(
      children: [
        Semantics(
          container: true, // its own node, so that the id stays on the button
          button: true,
          identifier: 'power',
          label: on ? l.powerStopCd : l.powerStartCd,
          excludeSemantics: true,
          child: PowerButton(
            on: on,
            starting: f.state == FilterState.starting,
            onTap: () {
              HapticFeedback.mediumImpact();
              on ? runAction(context, (b) => b.stopFilter()) : startFiltering(context);
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
            'state_detail',
            child: SwitchFade(
              child: Text(detail,
                  key: ValueKey('$detail$detailIsError'),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: detailIsError ? c.error : null)),
            ),
          ),
        ],
        if (technical != null) ...[
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              key: const Key('state_technical'),
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.codeBg, borderRadius: const BorderRadius.all(Radius.circular(12))),
              child: SingleChildScrollView(
                child: SelectableText(technical, style: text.bodySmall?.copyWith(fontFamily: 'monospace', color: c.error)),
              ),
            ),
          ),
        ],
        // apps are held silent: the power button starts again, this gives them back unfiltered (MainActivity)
        if (f.state == FilterState.silenced) ...[
          const SizedBox(height: 12),
          TestId(
            'release_silence',
            child: OutlinedButton(
              key: const Key('release_silence'),
              onPressed: () => runAction(context, (b) => b.stopFilter()),
              child: Text(l.releaseSilence),
            ),
          ),
        ],
        if (s.capabilities.captureConsent && !on && !s.setup.consentSkipped) ...[
          const SizedBox(height: 12),
          Text(l.captureHint, textAlign: TextAlign.center, style: text.bodyMedium),
        ],
        if (f.simulated) ...[
          const SizedBox(height: 12),
          Text(l.desktopPreview, textAlign: TextAlign.center, style: text.bodyMedium),
        ],
      ],
    );
  }
}

/// A page of the bottom bar fades in (and rises a little) when it is chosen.
class _PageIn extends StatelessWidget {
  const _PageIn({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.medium);
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: d,
      curve: Motion.curve,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.012),
        duration: d,
        curve: Motion.curve,
        child: child,
      ),
    );
  }
}

/// The on/off control: its fill, ring and icon blend between off, starting (half) and on; it shrinks a little under
/// the finger; a soft halo breathes twice when it turns on, then stays (never an endless animation).
class PowerButton extends StatefulWidget {
  const PowerButton({super.key, required this.on, required this.starting, required this.onTap});

  final bool on;
  final bool starting;
  final VoidCallback onTap;

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    if (widget.on) _glow.value = 1;
  }

  @override
  void didUpdateWidget(PowerButton old) {
    super.didUpdateWidget(old);
    final filtering = widget.on && !widget.starting, was = old.on && !old.starting;
    if (filtering && !was) _breathe();
  }

  Future<void> _breathe() async {
    if (Motion.of(context, Motion.slow) == Duration.zero) {
      _glow.value = 1;
      return;
    }
    try {
      for (var i = 0; i < 2; i++) {
        await _glow.forward(from: 0).orCancel;
      }
    } on TickerCanceled {
      // left the screen
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = WaaiyaColors.of(context);
    final target = widget.starting ? 0.45 : (widget.on ? 1.0 : 0.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      builder: (context, t, _) => AnimatedBuilder(
        animation: _glow,
        builder: (context, _) {
          // a breath: the halo swells and settles; while on, a soft steady halo
          final breath = _glow.isAnimating ? math.sin(_glow.value * math.pi) : 0.0;
          final halo = (t >= 1 ? 0.22 : 0.0) + 0.28 * breath;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (halo > 0)
                  BoxShadow(
                    color: c.primary.withValues(alpha: halo),
                    blurRadius: 28 + 28 * breath,
                    spreadRadius: 2 + 10 * breath,
                  ),
              ],
            ),
            child: Pressable(
              scale: 0.94,
              child: SizedBox.square(
                dimension: 168,
                child: Material(
                  key: const Key('power'),
                  color: Color.lerp(c.surface, c.primary, t),
                  shape: CircleBorder(
                    side: t >= 1 ? BorderSide.none : BorderSide(color: Color.lerp(c.offRing, c.primary, t)!, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onTap,
                    child: Icon(Icons.power_settings_new_rounded,
                        size: 72, color: Color.lerp(c.textPrimary, c.onPrimary, t)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Text for a `filter.error` code (docs/UI_CONTRACT.md).
String engineErrorText(AppLocalizations l, BackendMessage e) => switch (e.code) {
      'no_pactl' => l.engineErrorNoPactl,
      'no_sound_server' => l.engineErrorNoSoundServer,
      'no_systemd' => l.engineErrorNoSystemd,
      'no_output' => l.engineErrorNoOutput,
      'install_failed' => l.engineErrorInstallFailed(e.detail),
      'start_failed' => l.engineErrorStartFailed(e.detail),
      'service_failed' => l.engineErrorServiceFailed(e.detail),
      'model_failed' => l.stateModelFailed,
      'autostart_blocked' => l.engineErrorAutostartBlocked,
      'autostart_policy' => l.engineErrorAutostartPolicy,
      _ => l.actionFailed(e.detail.isEmpty ? e.code : e.detail),
    };
