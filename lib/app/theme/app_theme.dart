import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light() {
    const colors = AppColors.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      extensions: [colors],
      colorScheme: ColorScheme.light(
        primary: colors.coral,
        secondary: colors.violet,
        surface: colors.paper,
        error: Colors.red,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 14,
          color: colors.textBody,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.textBody,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textBody,
        ),
      ),
    );
  }

  static ThemeData dark() {
    const colors = AppColors.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      extensions: [colors],
      colorScheme: ColorScheme.dark(
        primary: colors.coral,
        secondary: colors.violet,
        surface: colors.paper,
        error: Colors.red,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 14,
          color: colors.textBody,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.textBody,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textBody,
        ),
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
