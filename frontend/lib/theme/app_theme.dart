import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Orange & Blue Palette
  static const Color primaryBlue = Color(0xFF1565C0); // Blue 800
  static const Color primaryOrange = Color(0xFFEF6C00); // Orange 800
  static const Color accentOrange = Color(0xFFFF9800); // Orange 500
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF0D47A1)], // Blue 800 -> Blue 900
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primaryOrange, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  // Border Radius
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(20));

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Light Theme
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryOrange,
        surface: cardLight,
        background: backgroundLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      
      // Typography
      textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: cardLight,
        shadowColor: Colors.black12,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        border: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: cardLight,
        indicatorColor: primaryBlue.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            );
          }
          return GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryOrange,
        secondary: primaryBlue,
        surface: cardDark,
        background: backgroundDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      
      textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.white,
          height: 1.6,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: cardDark,
      ),
    );
  }
}
