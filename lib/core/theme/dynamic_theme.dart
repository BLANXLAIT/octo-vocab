// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language.dart';

/// Theme variants for different moods and contexts
enum ThemeVariant {
  vibrant('Vibrant', Colors.teal),
  warm('Warm', Colors.orange),
  cool('Cool', Colors.blue),
  nature('Nature', Colors.green),
  royal('Royal', Colors.deepPurple);

  const ThemeVariant(this.displayName, this.seedColor);

  final String displayName;
  final Color seedColor;
}

/// Dynamic color schemes that adapt to different contexts
class DynamicColorSchemes {
  /// Language-specific color palettes
  static Color getSeedColorForLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.latin:
        return const Color(0xFF6B73FF); // Vibrant purple-blue for classical
      case AppLanguage.spanish:
        return const Color(0xFFFF6B6B); // Warm coral-red for passion
    }
  }

  /// Generate a vibrant color scheme with high fidelity to seed color
  static ColorScheme createVibrantScheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
  }

  /// Create content-based color scheme with subtle variations
  static ColorScheme createContentScheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    );
  }

  /// Create expressive color scheme with high contrast
  static ColorScheme createExpressiveScheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.expressive,
    );
  }
}

/// Current theme variant provider
final themeVariantProvider = StateProvider<ThemeVariant>(
  (ref) => ThemeVariant.vibrant,
);

/// Dynamic theme data provider that adapts to language and variant
final dynamicThemeProvider = Provider<ThemeData>((ref) {
  final variant = ref.watch(themeVariantProvider);
  final language = ref.watch(appLanguageProvider);

  // Use language-specific color if variant is vibrant, otherwise use variant color
  final seedColor = variant == ThemeVariant.vibrant
      ? DynamicColorSchemes.getSeedColorForLanguage(language)
      : variant.seedColor;

  final colorScheme = DynamicColorSchemes.createVibrantScheme(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    // Enhanced typography for Material 3
    textTheme: _createEnhancedTextTheme(colorScheme),
    // Custom card theme with elevated surfaces
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    // Enhanced FAB theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 6,
    ),
    // Enhanced AppBar theme
    appBarTheme: AppBarTheme(
      centerTitle: false,
      surfaceTintColor: colorScheme.surfaceTint,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    ),
    // Enhanced navigation bar theme
    navigationBarTheme: NavigationBarThemeData(
      elevation: 3,
      surfaceTintColor: colorScheme.surfaceTint,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    // Enhanced button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
});

/// Enhanced text theme with better hierarchy and readability
TextTheme _createEnhancedTextTheme(ColorScheme colorScheme) {
  const baseTextTheme = TextTheme();

  return baseTextTheme.copyWith(
    // Display styles for large text like vocabulary words
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: colorScheme.onSurface,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    ),
    // Headline styles for sections and questions
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: colorScheme.onSurface,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    ),
    // Title styles for app bars and cards
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: colorScheme.onSurface,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: colorScheme.onSurface,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: colorScheme.onSurface,
    ),
    // Label styles for buttons and small text
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: colorScheme.onSurface,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: colorScheme.onSurface,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: colorScheme.onSurface,
    ),
  );
}
