import 'package:flutter/material.dart';

const Color _seed = Color(0xFF00BFA5);

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1A1A1E),
      surfaceContainerLowest: const Color(0xFF151518),
      surfaceContainerLow: const Color(0xFF1E1E23),
      surfaceContainer: const Color(0xFF232328),
      surfaceContainerHigh: const Color(0xFF2C2C33),
      surfaceContainerHighest: const Color(0xFF363640),
      onSurface: const Color(0xFFE8E8EC),
      onSurfaceVariant: const Color(0xFF9E9EB0),
      outline: const Color(0xFF6B6B7D),
      outlineVariant: const Color(0xFF3A3A42),
      error: const Color(0xFFFF5252),
    );

    return _buildTheme(cs, Brightness.dark);
  }

  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF5F5F7),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF0F0F4),
      surfaceContainer: const Color(0xFFFFFFFF),
      surfaceContainerHigh: const Color(0xFFEEEEF2),
      surfaceContainerHighest: const Color(0xFFE4E4EA),
      onSurface: const Color(0xFF1A1A1E),
      onSurfaceVariant: const Color(0xFF6B6B7D),
      outline: const Color(0xFF9E9EB0),
      outlineVariant: const Color(0xFFD0D0D8),
      error: const Color(0xFFB3261E),
    );

    return _buildTheme(cs, Brightness.light);
  }

  static ThemeData _buildTheme(ColorScheme cs, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plangothic',
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(size: 18),
      sliderTheme: SliderThemeData(
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.outlineVariant,
        thumbColor: cs.primary,
        overlayColor: cs.primary.withAlpha(30),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : const Color(0xFF2C2C33),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(color: cs.onSurface, fontSize: 11),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: cs.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cs.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        ),
      ),
    );
  }
}
