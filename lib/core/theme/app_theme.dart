import 'package:flutter/material.dart';

/// Charte graphique du club — chaque couleur est assignée à un rôle Material
/// 3 précis plutôt que dérivée algorithmiquement d'une seule couleur de base.
class AppTheme {
  static const _lightBackground = Color(0xFFF3F5FC);
  static const _darkBackground = Color(0xFF10131C);
  static const _darkCard = Color(0xFF1C2333);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF3261FF),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFCCD7FF),
      onPrimaryContainer: const Color(0xFF001A41),
      secondary: const Color(0xFF7F9CFF),
      onSecondary: const Color(0xFF001A41),
      secondaryContainer: const Color(0xFFCCD7FF),
      onSecondaryContainer: const Color(0xFF001A41),
      tertiary: const Color(0xFFFFB717),
      onTertiary: const Color(0xFF3D2E00),
      tertiaryContainer: const Color(0xFFFFE7B3),
      onTertiaryContainer: const Color(0xFF3D2E00),
      surface: _lightBackground,
    ),
    scaffoldBackgroundColor: _lightBackground,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      // Sans ça, Material 3 teinte automatiquement la carte avec la couleur
      // primaire selon son élévation — c'est cette teinte automatique,
      // proche du fond, qui rendait les cartes peu visibles.
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF7F9CFF),
      onPrimary: const Color(0xFF001A41),
      primaryContainer: const Color(0xFF3261FF),
      onPrimaryContainer: const Color(0xFFCCD7FF),
      secondary: const Color(0xFFCCD7FF),
      onSecondary: const Color(0xFF001A41),
      secondaryContainer: const Color(0xFF3261FF),
      onSecondaryContainer: const Color(0xFFCCD7FF),
      tertiary: const Color(0xFFFFB717),
      onTertiary: const Color(0xFF3D2E00),
      tertiaryContainer: const Color(0xFF5C4400),
      onTertiaryContainer: const Color(0xFFFFE7B3),
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
