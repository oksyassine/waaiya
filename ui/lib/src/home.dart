import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'blur_card.dart';
import 'licences.dart';
import 'setup_card.dart';
import 'theme.dart';
import 'widgets.dart';

/// Main screen: one large on/off control with its state in words, the one-time setup, links, screen blur,
/// settings. Shows the same things, under the same conditions, as the native MainActivity.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// A setting that the service reads at start changed while it runs: say "stop and start".
  bool _restartNote = false;

  void _changedWhileRunning() {
    if (WaaiyaScope.of(context).state.filter.running) setState(() => _restartNote = true);
  }

  Future<void> _set(String key, Object value, {bool needsRestart = false}) async {
    await runAction(context, (b) => b.setSetting(key, value));
    if (needsRestart && mounted) _changedWhileRunning();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final caps = s.capabilities;
    if (!s.filter.running) _restartNote = false;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageColumn(
          children: [
            const AppHeader(),
            const SizedBox(height: 24),
            const PowerSection(),
            if (caps.shizukuSetup || caps.adbSetup) const SetupSection(),
            if (caps.links)
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
            if (caps.screenBlur)
              BlurCard(onChanged: (key, v) => _set(key, v, needsRestart: key != SettingKeys.blurFailCover)),
            _settings(context, s),
            if (caps.links) SectionCard(title: l.playerTitle, body: l.playerBody),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LicencesScreen())),
              child: Text(l.licences),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  Widget _settings(BuildContext context, AppState s) {
    final l = AppLocalizations.of(context);
    final st = s.settings;
    final singingNoModel = st.muteWomenSinging && !s.detectorModel;
    return SectionCard(
      title: l.settingsTitle,
      children: [
        const SizedBox(height: 8),
        // Read by the running muter on every poll: applies at once.
        SettingSwitch(
          title: l.settingSilenceTitle,
          body: l.settingSilenceBody,
          value: st.silenceUnfilterable,
          onChanged: (v) => _set(SettingKeys.silenceUnfilterable, v),
        ),
        if (st.isMan && s.capabilities.womenSinging)
          SettingSwitch(
            title: l.settingSingingTitle,
            body: singingNoModel ? l.settingSingingNoModel : l.settingSingingBody,
            bodyIsError: singingNoModel,
            value: st.muteWomenSinging,
            onChanged: (v) => _set(SettingKeys.muteWomenSinging, v, needsRestart: true),
          ),
        if (_restartNote) StatusText(l.settingRestart),
        const Divider(),
        ValueRow(
          label: '${l.settingGenderTitle}: ${st.isMan ? l.genderMan : l.genderWoman}',
          action: l.change,
          onPressed: () async {
            final i = await chooseOne(context,
                title: l.settingGenderTitle, options: [l.genderMan, l.genderWoman], selected: st.isMan ? 0 : 1);
            if (i != null) await _set(SettingKeys.gender, i == 0 ? 'man' : 'woman', needsRestart: true);
          },
        ),
        ValueRow(
          label: l.settingLanguageTitle(s.language == 'ar' ? l.languageAr : l.languageEn),
          action: l.change,
          onPressed: () async {
            const tags = ['ar', 'en'];
            final i = await chooseOne(context,
                title: l.languageTitle, options: [l.languageAr, l.languageEn], selected: tags.indexOf(s.language));
            if (i != null && tags[i] != s.language && context.mounted) {
              await runAction(context, (b) => b.setLanguage(tags[i]));
            }
          },
        ),
      ],
    );
  }
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

    final title = switch (f.state) {
      FilterState.starting => l.stateStarting,
      FilterState.filtering || FilterState.modelFailed => l.stateOnTitle,
      _ => l.stateOffTitle,
    };
    var detail = switch (f.state) {
      FilterState.filtering => l.stateOnDetail(f.delayMs),
      FilterState.modelFailed => l.stateModelFailed,
      FilterState.noCapturePermission => l.stateCaptureDenied,
      FilterState.stoppedBySystem => l.stateStoppedBySystem,
      FilterState.starting => '',
      FilterState.stopped => l.stateOffDetail,
    };
    var detailIsError = f.state == FilterState.modelFailed || f.state == FilterState.noCapturePermission;
    if (f.micDenied && !on) {
      detail = l.needRecordAudio;
      detailIsError = true;
    }

    return Column(
      children: [
        Semantics(
          button: true,
          label: on ? l.powerStopCd : l.powerStartCd,
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: 168,
            child: Material(
              key: const Key('power'),
              color: on ? c.primary : c.surface,
              shape: CircleBorder(side: on ? BorderSide.none : BorderSide(color: c.offRing, width: 3)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => runAction(context, (b) => on ? b.stopFilter() : b.startFilter()),
                child: Icon(Icons.power_settings_new_rounded, size: 72, color: on ? c.onPrimary : c.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(liveRegion: true, child: Text(title, style: text.titleLarge, textAlign: TextAlign.center)),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(detail,
              textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: detailIsError ? c.error : null)),
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
