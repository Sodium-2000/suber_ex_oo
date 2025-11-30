import 'package:flutter/material.dart';

/// Theme extension to hold custom color tokens used by the app.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color border;

  const AppColors({required this.primary, required this.border});

  @override
  AppColors copyWith({Color? primary, Color? border}) {
    return AppColors(
      primary: primary ?? this.primary,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light({
    required Color primaryColor,
    required Color borderColor,
  }) {
    final theme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
    return theme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppColors(primary: primaryColor, border: borderColor),
      ],
    );
  }

  static ThemeData dark({
    required Color primaryColor,
    required Color borderColor,
  }) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.black,
      // In dark mode we want the AppBar to blend with the background (hidden)
      // and use the primary color for icons/text so they pop on the dark bg.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: primaryColor,
      ),
      iconTheme: IconThemeData(color: primaryColor),
    );
    return theme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppColors(primary: primaryColor, border: borderColor),
      ],
    );
  }
}
