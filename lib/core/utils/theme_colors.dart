import 'package:flutter/material.dart';

extension ZenithThemeColors on BuildContext {
  Color get surfaceLight {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2C2C33) : const Color(0xFFEEEEF2);
  }

  Color get textDim {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF6B6B7D) : const Color(0xFF9E9EB0);
  }

  Color get backgroundAlt {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF5F5F7);
  }
}
