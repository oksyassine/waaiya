import 'package:flutter/material.dart';

/// Colour tokens of the Android app (res/values/colors.xml and values-night/colors.xml).
class WaaiyaColors extends ThemeExtension<WaaiyaColors> {
  const WaaiyaColors({
    required this.bg,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.offRing,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.error,
    required this.codeBg,
  });

  static const light = WaaiyaColors(
    bg: Color(0xFFF6F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFECEFEC),
    outline: Color(0xFFC9CFCB),
    textPrimary: Color(0xFF17201C),
    textSecondary: Color(0xFF4A5550),
    primary: Color(0xFF0D6B5E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD3EFE8),
    onPrimaryContainer: Color(0xFF053D35),
    offRing: Color(0xFF76817C),
    warningContainer: Color(0xFFFFF1D6),
    onWarningContainer: Color(0xFF5A3B00),
    error: Color(0xFFB3261E),
    codeBg: Color(0xFFECEFEC),
  );

  static const dark = WaaiyaColors(
    bg: Color(0xFF0F1513),
    surface: Color(0xFF18201D),
    surfaceVariant: Color(0xFF232D29),
    outline: Color(0xFF3D4A45),
    textPrimary: Color(0xFFE6ECE9),
    textSecondary: Color(0xFFAAB6B1),
    primary: Color(0xFF7AD8C6),
    onPrimary: Color(0xFF00382F),
    primaryContainer: Color(0xFF0E4E44),
    onPrimaryContainer: Color(0xFFC8F2E9),
    offRing: Color(0xFF6F7A76),
    warningContainer: Color(0xFF4A3407),
    onWarningContainer: Color(0xFFFFE3B0),
    error: Color(0xFFF2B8B5),
    codeBg: Color(0xFF232D29),
  );

  final Color bg, surface, surfaceVariant, outline, textPrimary, textSecondary, primary, onPrimary;
  final Color primaryContainer, onPrimaryContainer, offRing, warningContainer, onWarningContainer, error, codeBg;

  static WaaiyaColors of(BuildContext context) => Theme.of(context).extension<WaaiyaColors>()!;

  @override
  WaaiyaColors copyWith() => this;

  @override
  WaaiyaColors lerp(WaaiyaColors? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData waaiyaTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? WaaiyaColors.dark : WaaiyaColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primaryContainer,
    onPrimaryContainer: c.onPrimaryContainer,
    secondary: c.primary,
    onSecondary: c.onPrimary,
    secondaryContainer: c.primaryContainer,
    onSecondaryContainer: c.onPrimaryContainer,
    error: c.error,
    onError: brightness == Brightness.dark ? const Color(0xFF601410) : Colors.white,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceVariant,
    surfaceContainerHighest: c.surfaceVariant,
    outline: c.outline,
    outlineVariant: c.outline,
  );
  // Text sizes of the Android styles: Title 28, Headline 20, Section 18, Body 16, Secondary 14.
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final text = base.textTheme.copyWith(
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w500, color: c.textPrimary),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, color: c.textPrimary),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w500, color: c.textPrimary),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.4, color: c.textPrimary),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4, color: c.textSecondary),
  );
  const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24)));
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    textTheme: text,
    extensions: [c],
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: c.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: shape),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : null),
    ),
    dividerTheme: DividerThemeData(color: c.outline, space: 32),
  );
}
