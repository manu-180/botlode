// Archivo: lib/core/config/theme/app_theme.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Oxanium', 
    scaffoldBackgroundColor: AppColors.background,
    
    // Esquema de Colores Dorado
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,     // Oro
      secondary: AppColors.secondary, // Cian secundario
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),

    // Inputs ahora brillan en dorado al enfocar
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGlass),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGlass),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2), 
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),

    // Botones Dorados con texto Negro (Alto contraste industrial)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black, 
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Oxanium',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Oxanium',
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}