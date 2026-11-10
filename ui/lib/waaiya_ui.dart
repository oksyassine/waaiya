/// Waaiya's shared screens. The platform side is a [WaaiyaBackend] (docs/UI_CONTRACT.md).
library;

export 'l10n/app_localizations.dart';
export 'src/app.dart' show WaaiyaApp, WaaiyaScope;
export 'src/backend.dart';
export 'src/blur_card.dart' show blurFailFix, blurStatus;
export 'src/channel_backend.dart';
export 'src/memory_backend.dart';
export 'src/setup_card.dart' show SetupStep, setupSteps;
export 'src/theme.dart' show WaaiyaColors, waaiyaTheme;
