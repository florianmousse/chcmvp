import 'package:flutter/material.dart';

/// Charte graphique du club - chaque couleur est assignée à un rôle Material
/// 3 précis plutôt que dérivée algorithmiquement d'une seule couleur de base.
class AppTheme {
  static const _lightBackground = Color(0xFFF3F5FC);
  static const _darkBackground = Color(0xFF10131C);
  static const _darkCard = Color(0xFF1C2333);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3261FF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCCD7FF),
      onPrimaryContainer: Color(0xFF001A41),
      secondary: Color(0xFF7F9CFF),
      onSecondary: Color(0xFF001A41),
      secondaryContainer: Color(0xFFCCD7FF),
      onSecondaryContainer: Color(0xFF001A41),
      tertiary: Color(0xFFFFB717),
      onTertiary: Color(0xFF3D2E00),
      tertiaryContainer: Color(0xFFFFE7B3),
      onTertiaryContainer: Color(0xFF3D2E00),
      surface: _lightBackground,
    ),
    scaffoldBackgroundColor: _lightBackground,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      // Sans ça, Material 3 teinte automatiquement la carte avec la couleur
      // primaire selon son élévation - c'est cette teinte automatique,
      // proche du fond, qui rendait les cartes peu visibles.
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7F9CFF),
      onPrimary: Color(0xFF001A41),
      primaryContainer: Color(0xFF3261FF),
      onPrimaryContainer: Color(0xFFCCD7FF),
      secondary: Color(0xFFCCD7FF),
      onSecondary: Color(0xFF001A41),
      secondaryContainer: Color(0xFF3261FF),
      onSecondaryContainer: Color(0xFFCCD7FF),
      tertiary: Color(0xFFFFB717),
      onTertiary: Color(0xFF3D2E00),
      tertiaryContainer: Color(0xFF5C4400),
      onTertiaryContainer: Color(0xFFFFE7B3),
      surface: _darkBackground,
    ),
    scaffoldBackgroundColor: _darkBackground,
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
