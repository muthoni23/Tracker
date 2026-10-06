import 'package:flutter/material.dart';

/// Central color palette matching the StudyTrack design.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4C3FE0);
  static const Color splashNavy = Color(0xFF14123B);

  // Backgrounds (light mode)
  static const Color background = Color(0xFFF5F5FB);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Backgrounds (dark mode) - same navy family as the splash screen so the
  // dark theme still reads as StudyTrack.
  static const Color darkBackground = Color(0xFF100E26);
  static const Color darkCardNavy = Color(0xFF1C1A3B);

  // Text (light mode)
  static const Color textPrimary = Color(0xFF1B1A2B);
  static const Color textSecondary = Color(0xFF8C8AA0);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Text (dark mode)
  static const Color textPrimaryDark = Color(0xFFF2F1FA);
  static const Color textSecondaryDark = Color(0xFFA6A3C4);

  // Course card colors (matches mockup: CS blue, Web teal, DB pink, Math orange)
  static const Color courseBlue = Color(0xFF3B5BDB);
  static const Color courseTeal = Color(0xFF0CA678);
  static const Color coursePink = Color(0xFFD6336C);
  static const Color courseOrange = Color(0xFFF08C00);
  static const List<Color> coursePalette = [
    courseBlue,
    courseTeal,
    coursePink,
    courseOrange,
  ];

  // Priority
  static const Color priorityHigh = Color(0xFFE64980);
  static const Color priorityMedium = Color(0xFFF59F00);
  static const Color priorityLow = Color(0xFF2F9E44);

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      default:
        return priorityLow;
    }
  }

  // Divider (light mode)
  static const Color divider = Color(0xFFE9E8F2);
  // Divider (dark mode)
  static const Color dividerDark = Color(0xFF322F58);
}

/// Surface/text colors that flip between the light and dark StudyTrack
/// palettes. Registered on [ThemeData.extensions] so every screen reads the
/// right shade through `Theme.of(context)` instead of hard-coded constants.
@immutable
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const AppSurfaceColors({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  static const light = AppSurfaceColors(
    background: AppColors.background,
    card: AppColors.cardWhite,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
  );

  static const dark = AppSurfaceColors(
    background: AppColors.darkBackground,
    card: AppColors.darkCardNavy,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    divider: AppColors.dividerDark,
  );

  @override
  AppSurfaceColors copyWith({
    Color? background,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
  }) {
    return AppSurfaceColors(
      background: background ?? this.background,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<AppSurfaceColors>()`.
extension AppSurfaceColorsContext on BuildContext {
  AppSurfaceColors get surfaceColors =>
      Theme.of(this).extension<AppSurfaceColors>() ?? AppSurfaceColors.light;
}
