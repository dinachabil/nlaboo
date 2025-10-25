import 'package:flutter/material.dart';

/// Provides a safe replacement for the deprecated `Color.withOpacity`.
/// Use `.withOpacitySafe(opacity)` which converts opacity to an integer alpha.
extension ColorWithOpacitySafe on Color {
  /// Returns a color with the given opacity (0.0 - 1.0) using `withAlpha`.
  Color withOpacitySafe(double opacity) {
    final int alpha = (opacity * 255).round();
    final int clamped = alpha < 0 ? 0 : (alpha > 255 ? 255 : alpha);
    return withAlpha(clamped);
  }
}