import 'package:flutter/material.dart';

/// Ask-Jeeves Vault Design System
/// Futuristic, cinematic, military-grade aesthetic
class AppTheme {
  // Core Colors - Dark Matter Palette
  static const Color deepBlack = Color(0xFF0A0A0F);
  static const Color darkMatterViolet = Color(0xFF1A0B2E);
  static const Color electricCyan = Color(0xFF00F5FF);
  static const Color mercuryTeal = Color(0xFF00D9C0);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color quantumBlue = Color(0xFF3A0CA3);
  static const Color ghostWhite = Color(0xFFF8F9FA);
  static const Color warningRed = Color(0xFFFF6B9D); // Softer coral-pink (was 0xFFFF006E)
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color successGreen = Color(0xFF06FFA5);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricCyan, mercuryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient vaultGradient = LinearGradient(
    colors: [darkMatterViolet, quantumBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [warningRed, Color(0xFFE85D75)], // Softer gradient (was 0xFFD00000)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        secondary: mercuryTeal,
        tertiary: neonPurple,
        surface: Color(0xFF1A1A24),
        error: warningRed,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: ghostWhite,
        onError: ghostWhite,
      ),
      
      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontFamily: 'SpaceGrotesk',
          color: Color(0xFFB0B0B8),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'JetBrainsMono',
          color: ghostWhite,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'JetBrainsMono',
          color: ghostWhite,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'JetBrainsMono',
          color: Color(0xFFB0B0B8),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A24).withAlpha(153),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: electricCyan.withAlpha(26),
            width: 1,
          ),
        ),
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'SpaceGrotesk',
          color: ghostWhite,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricCyan,
          foregroundColor: deepBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A24).withAlpha(153),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: electricCyan.withAlpha(51),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: electricCyan.withAlpha(51),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: electricCyan,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: warningRed,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration vaultAnimation = Duration(milliseconds: 1200);
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  
  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double spaceXXLarge = 48.0;
}
