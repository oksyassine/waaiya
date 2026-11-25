import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations_en.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/blur_card.dart';

void main() {
  test('blur turned on during a one-app filtering asks for a restart', () {
    final l = AppLocalizationsEn();
    const s = AppState(
      settings: WaaiyaSettings(gender: 'man', blurWomen: true),
      capabilities: Capabilities.android,
      filter: FilterInfo(state: FilterState.filtering, blurNeedsRestart: true),
      blur: BlurInfo(overlayAllowed: true),
    );
    final st = blurStatus(l, s);
    expect(st?.$1, l.blurNeedsRestart);
    expect(st?.$2, isTrue);
  });
}
