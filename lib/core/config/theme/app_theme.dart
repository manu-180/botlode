// lib/core/config/theme/app_theme.dart
// Tema Material 3 oscuro único. No hay light mode.
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Oxanium',
    scaffoldBackgroundColor: AppColors.background,

    colorScheme: const ColorScheme.dark(
      primary:          AppColors.gold,
      onPrimary:        AppColors.textOnGold,
      secondary:        AppColors.cyan,
      onSecondary:      AppColors.voidBlack,
      surface:          AppColors.surface,
      onSurface:        AppColors.textPrimary,
      error:            AppColors.danger,
      onError:          AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceRaised,
    ),

    textTheme: TextTheme(
      displayLarge:   AppTextStyles.displayXL,
      displayMedium:  AppTextStyles.displayL,
      displaySmall:   AppTextStyles.displayM,
      headlineMedium: AppTextStyles.titleL,
      titleLarge:     AppTextStyles.titleL,
      titleMedium:    AppTextStyles.titleM,
      labelLarge:    AppTextStyles.label,
      labelMedium:   AppTextStyles.label,
      labelSmall:    AppTextStyles.labelSmall,
      bodyLarge:     AppTextStyles.bodyL,
      bodyMedium:    AppTextStyles.bodyM,
      bodySmall:     AppTextStyles.bodyS,
    ),

    // Fallback for third-party widgets; app code uses AppTextField directly.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHud,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      border: OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppDimens.brM,
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      labelStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textTertiary),
      errorStyle: TextStyle(
        fontSize: AppTextStyles.bodyS.fontSize,
        color: AppColors.danger,
      ),
      helperStyle: TextStyle(
        fontSize: AppTextStyles.bodyS.fontSize,
        color: AppColors.textTertiary,
      ),
    ),

    // Fallback for third-party widgets using ElevatedButton — app code uses AppButton instead.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textOnGold,
        elevation: 0,
        textStyle: AppTextStyles.label.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(0, 48),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderDefault),
        textStyle: AppTextStyles.label,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(0, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: AppTextStyles.label,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleM,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borderDefault,
      thickness: 1,
      space: 1,
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      textStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        AppColors.borderStrong,
      ),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(4),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.gold;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textOnGold),
      side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.textOnGold;
        return AppColors.textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.gold;
        return AppColors.surfaceRaised;
      }),
    ),
  );
}
