import 'package:flutter/material.dart';

/// Centralized theme constants for the Hindu Connect app
/// This file contains all color definitions, spacing, and theme-related constants
/// to ensure consistency across the app and make maintenance easier.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ===== COLORS =====
  
  /// Primary saffron color used throughout the app
  static const Color primaryColor = Color(0xFFFF9933);
  
  /// Deeper orange color for secondary elements
  static const Color secondaryColor = Color(0xFFFF6600);
  
  /// Cream color for surfaces and backgrounds
  static const Color creamColor = Color(0xFFFFF8DC);
  
  /// Warm cream color for light backgrounds
  static const Color warmCreamColor = Color(0xFFFFFAF0);
  
  /// Light gray for semi-light backgrounds
  static const Color lightGrayColor = Color(0xFFF5F5F5);
  
  /// Medium gray for semi-dark backgrounds
  static const Color mediumGrayColor = Color(0xFFE0E0E0);
  
  /// Dark gray for dark backgrounds
  static const Color darkGrayColor = Color(0xFF1A1A1A);
  
  /// Darker gray for dark theme surfaces
  static const Color darkerGrayColor = Color(0xFF2A2A2A);
  
  /// Lighter gray for light theme surfaces
  static const Color lighterGrayColor = Color(0xFFD0D0D0);
  
  /// Blue color for language indicators
  static const Color languageBlueColor = Colors.blue;
  
  /// Red color for favorite icons
  static const Color favoriteRedColor = Colors.red;
  
  /// Error color for error messages
  static const Color errorColor = Colors.red;
  
  /// Success color for success messages
  static const Color successColor = Colors.green;
  
  /// Warning color for warning messages
  static const Color warningColor = Colors.orange;

  // ===== ADDITIONAL COLORS =====
  
  /// Text primary color for main text
  static const Color textPrimaryColor = Colors.black87;
  
  /// Text secondary color for secondary text
  static const Color textSecondaryColor = Colors.grey;
  
  /// Border color for borders and dividers
  static const Color borderColor = Colors.grey;
  
  /// Ash color (semi-dark) for backgrounds
  static const Color ashColor = Color(0xFFB0B0B0);
  
  /// Dark color for dark backgrounds
  static const Color darkColor = Color(0xFF494949);

  // ===== SPACING =====
  
  /// Extra small spacing (4px)
  static const double spacingXS = 4.0;
  
  /// Small spacing (8px)
  static const double spacingS = 8.0;
  
  /// Medium spacing (12px)
  static const double spacingM = 12.0;
  
  /// Large spacing (16px)
  static const double spacingL = 16.0;
  
  /// Extra large spacing (20px)
  static const double spacingXL = 20.0;
  
  /// Double extra large spacing (24px)
  static const double spacingXXL = 24.0;
  
  /// Triple extra large spacing (32px)
  static const double spacingXXXL = 32.0;

  // ===== BORDER RADIUS =====
  
  /// Small border radius (6px)
  static const double borderRadiusS = 6.0;
  
  /// Medium border radius (8px)
  static const double borderRadiusM = 8.0;
  
  /// Large border radius (12px)
  static const double borderRadiusL = 12.0;
  
  /// Extra large border radius (16px)
  static const double borderRadiusXL = 16.0;

  // ===== TEXT SIZES =====
  
  /// Extra small text size (10px)
  static const double textSizeXS = 10.0;
  
  /// Small text size (12px)
  static const double textSizeS = 12.0;
  
  /// Medium text size (14px)
  static const double textSizeM = 14.0;
  
  /// Large text size (16px)
  static const double textSizeL = 16.0;
  
  /// Extra large text size (18px)
  static const double textSizeXL = 18.0;
  
  /// Double extra large text size (20px)
  static const double textSizeXXL = 20.0;
  
  /// Triple extra large text size (24px)
  static const double textSizeXXXL = 24.0;

  // ===== DIMENSIONS =====
  
  /// Logo size for app logos
  static const double logoSize = 120.0;
  
  /// Standard button height
  static const double buttonHeight = 56.0;
  
  /// Standard icon size
  static const double iconSize = 24.0;
  
  /// Loading indicator size
  static const double loadingSize = 24.0;
  
  /// Standard border width
  static const double borderWidth = 3.0;
  
  /// Stroke width for progress indicators
  static const double strokeWidth = 2.0;
  
  /// Standard dialog height
  static const double dialogHeight = 400.0;

  // ===== DURATIONS =====
  
  /// Short animation duration (200ms)
  static const Duration animationShort = Duration(milliseconds: 200);
  
  /// Medium animation duration (300ms)
  static const Duration animationMedium = Duration(milliseconds: 300);
  
  /// Long animation duration (500ms)
  static const Duration animationLong = Duration(milliseconds: 500);

  // ===== SHADOWS =====
  
  /// Light shadow for cards
  static BoxShadow get lightShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  
  /// Medium shadow for elevated elements
  static BoxShadow get mediumShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.15),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // ===== THEME DATA =====
  
  /// Main app theme data
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: creamColor,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    fontFamily: 'Roboto',
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusL),
        ),
      ),
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thickness: WidgetStatePropertyAll(6.0),
      radius: Radius.circular(8.0),
    ),
  );

  // ===== HELPER METHODS =====
  
  /// Get appropriate text color based on background color
  static Color getTextColorForBackground(Color backgroundColor) {
    if (backgroundColor == darkGrayColor) {
      return Colors.white;
    } else if (backgroundColor == mediumGrayColor) {
      return Colors.black54;
    } else {
      return Colors.black87;
    }
  }
  
  /// Get background color variant for cards
  static Color getCardBackgroundColor(Color baseBackgroundColor) {
    if (baseBackgroundColor == darkGrayColor) {
      return darkerGrayColor;
    } else if (baseBackgroundColor == mediumGrayColor) {
      return lighterGrayColor;
    } else {
      return Colors.white;
    }
  }
}
