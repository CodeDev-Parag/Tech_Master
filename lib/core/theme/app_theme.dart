import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  // Primary Colors (Saiyan Theme)
  static const Color primaryLight = Color(0xFFFF8C00); // Spirit Orange
  static const Color primaryDark = Color(0xFFFF8C00); // Spirit Orange

  // Secondary Colors
  static const Color secondaryLight = Color(0xFF1B4F72); // Deep Blue
  static const Color secondaryDark = Color(0xFF85C1E9); // Light Blue

  // Background Colors
  static const Color backgroundLight = Color(0xFFF0F4F8); // Very light grey
  static const Color backgroundDark =
      Color(0xFF121212); // Saiyan Dark Background

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E); // Saiyan Surface

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E); // Matches surface

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF121212);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryLight = Color(0xFF495057);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);

  // Priority Colors
  static const Color priorityLow = Color(0xFF22C55E);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityUrgent = Color(0xFFEF4444);

  // Status Colors
  static const Color statusPending = Color(0xFF94A3B8);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF22C55E);

  // Accent Gradient
  // Accent Gradient
  // Accent Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF8C00),
      Color(0xFFFFA500)
    ], // Spirit Orange to Light Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryLight,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryLight,
      secondary: Color(0xFF8B5CF6),
      surface: surfaceLight,
      error: Color(0xFFEF4444),
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimaryLight,
      displayColor: textPrimaryLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
      ),
      iconTheme: const IconThemeData(color: textPrimaryLight),
    ),
    // cardTheme: CardTheme(
    //   color: cardLight,
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //   ),
    // ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceLight,
      selectedColor: primaryLight.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.inter(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryDark,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryDark,
      secondary: Color(0xFFA78BFA),
      surface: surfaceDark,
      error: Color(0xFFF87171),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimaryDark,
      displayColor: textPrimaryDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
      ),
      iconTheme: const IconThemeData(color: textPrimaryDark),
    ),
    // cardTheme: CardTheme(
    //   color: cardDark,
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //   ),
    // ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceDark,
      selectedColor: primaryDark.withValues(alpha: 0.3),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: textPrimaryDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
