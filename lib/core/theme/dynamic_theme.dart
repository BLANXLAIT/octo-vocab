// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

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
