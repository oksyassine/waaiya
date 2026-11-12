import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'widgets.dart';

/// First launch: who is using the phone (it only decides which optional settings are shown), and a button to
/// switch the language before anything else.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final other = WaaiyaScope.of(context).state.language == 'ar' ? 'en' : 'ar';
    void choose(String gender) => runAction(context, (b) => b.setSetting(SettingKeys.gender, gender));
    return Scaffold(
      body: SafeArea(
        child: PageColumn(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('onboard_language'),
                onPressed: () => runAction(context, (b) => b.setLanguage(other)),
                child: Text(other == 'ar' ? l.languageAr : l.languageEn),
              ),
            ),
            const AppHeader(),
            const SizedBox(height: 32),
            Text(l.onboardTitle, style: text.titleLarge),
            const SizedBox(height: 8),
            Text(l.onboardBody, style: text.bodyLarge),
            const SizedBox(height: 24),
            Text(l.onboardQuestion, style: text.titleMedium),
            const SizedBox(height: 12),
            FilledButton(key: const Key('choose_man'), onPressed: () => choose('man'), child: Text(l.genderMan)),
            const SizedBox(height: 12),
            FilledButton(key: const Key('choose_woman'), onPressed: () => choose('woman'), child: Text(l.genderWoman)),
            const SizedBox(height: 16),
            Text(l.onboardWhy, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}
