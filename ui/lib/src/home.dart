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
/// settings. Shows the same things, under the same conditions, as the native MainActivity. Settings apply live
/// (the running filter and blur re-read them every half second), so there is no "restart" note.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static Future<void> _set(BuildContext context, String key, Object value) =>
      runAction(context, (b) => b.setSetting(key, value));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final caps = s.capabilities;
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
              BlurCard(onChanged: (key, v) => _set(context, key, v)),
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
        SettingSwitch(
          title: l.settingSilenceTitle,
          body: l.settingSilenceBody,
          value: st.silenceUnfilterable,
          onChanged: (v) => _set(context, SettingKeys.silenceUnfilterable, v),
        ),
        if (s.capabilities.autostart)
          SettingSwitch(
            key: const Key('autostart'),
            title: l.autostartTitle,
            body: l.autostartBody,
            value: s.filter.autostart,
            onChanged: (v) => runAction(context, (b) => b.setAutostart(v)),
          ),
        if (st.isMan && s.capabilities.womenSinging)
          SettingSwitch(
            title: l.settingSingingTitle,
            body: singingNoModel ? l.settingSingingNoModel : l.settingSingingBody,
            bodyIsError: singingNoModel,
            value: st.muteWomenSinging,
            onChanged: (v) => _set(context, SettingKeys.muteWomenSinging, v),
          ),
        if (!s.capabilities.screenBlur)
          BlurStrictnessRow(onChanged: (v) => _set(context, SettingKeys.blurStrictness, v)),
        const Divider(),
        ValueRow(
          label: '${l.settingGenderTitle}: ${st.isMan ? l.genderMan : l.genderWoman}',
          action: l.change,
          onPressed: () async {
            final i = await chooseOne(context,
                title: l.settingGenderTitle, options: [l.genderMan, l.genderWoman], selected: st.isMan ? 0 : 1);
            if (i != null && context.mounted) await _set(context, SettingKeys.gender, i == 0 ? 'man' : 'woman');
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
      // no measured delay (desktop host): the sentence without it
      FilterState.filtering => f.delayMs > 0 ? l.stateOnDetail(f.delayMs) : l.stateOnDetailNoDelay,
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
    final error = f.error;
    if (error != null) {
      detail = engineErrorText(l, error);
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

/// Text for a `filter.error` code (docs/UI_CONTRACT.md).
String engineErrorText(AppLocalizations l, BackendMessage e) => switch (e.code) {
      'no_pactl' => l.engineErrorNoPactl,
      'no_sound_server' => l.engineErrorNoSoundServer,
      'no_systemd' => l.engineErrorNoSystemd,
      'no_output' => l.engineErrorNoOutput,
      'install_failed' => l.engineErrorInstallFailed(e.detail),
      'start_failed' => l.engineErrorStartFailed(e.detail),
      'service_failed' => l.engineErrorServiceFailed(e.detail),
      _ => l.actionFailed(e.detail.isEmpty ? e.code : e.detail),
    };
