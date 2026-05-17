// lib/features/dashboard/presentation/widgets/unit_mood_colors.dart
// Shared mood index → color/name helpers used by UnitAvatarPanel and UnitTelemetryConsole.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Returns the accent color for the given Rive mood index (0–5).
/// Map: 0=online→success, 1=angry→danger, 2=happy→accentMagenta,
///      3=vendor→gold, 4=confused→accentViolet, 5+=tech→cyan
Color unitMoodColor(int moodIndex) => switch (moodIndex) {
      0 => AppColors.success,
      1 => AppColors.danger,
      2 => AppColors.accentMagenta,
      3 => AppColors.gold,
      4 => AppColors.accentViolet,
      _ => AppColors.cyan,
    };

/// Returns the Spanish display name for the given mood index.
String unitMoodName(int moodIndex) => switch (moodIndex) {
      0 => 'EN LÍNEA',
      1 => 'ENOJADO',
      2 => 'FELIZ',
      3 => 'VENDEDOR',
      4 => 'CONFUNDIDO',
      _ => 'TÉCNICO',
    };
