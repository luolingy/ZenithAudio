import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 18,
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontFamily: 'Roboto',
        ),
        labelSmall: TextStyle(
          color: AppColors.textDim,
          fontSize: 10,
          fontFamily: 'Roboto',
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.border;
        }),
        checkColor: WidgetStateProperty.all(AppColors.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 4,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        surface: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1A1A1E),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: const Color(0xFFD0D0D8),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD0D0D8),
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF6B6B7D),
        size: 18,
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
          color: Color(0xFF6B6B7D),
          fontSize: 11,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF1A1A1E),
          fontSize: 13,
          fontFamily: 'Roboto',
        ),
        labelSmall: TextStyle(
          color: Color(0xFF9E9EB0),
          fontSize: 10,
          fontFamily: 'Roboto',
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          color: Color(0xFF1A1A1E),
          fontSize: 12,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          color: Color(0xFF1A1A1E),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF1A1A1E),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: const Color(0xFFD0D0D8),
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return const Color(0xFFD0D0D8);
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEEEF2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD0D0D8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD0D0D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C33),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C33),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 4,
      ),
    );
  }
}
