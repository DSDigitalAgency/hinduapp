import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontService {
  /// Get text style for a specific language
  static TextStyle getTextStyleForLanguage(
    String language, {
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    final fontFamily = _pickFontFamily(language);
    
    switch (fontFamily) {
      case 'English':
        // Try custom font first, fallback to Google Fonts
        try {
          return TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
            fontFamily: 'Noto Sans',
          );
        } catch (e) {
          return GoogleFonts.notoSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
          );
        }
      
      case 'Devanagari':
        // Try custom font first, fallback to Google Fonts
        try {
          return TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
            fontFamily: 'Noto Sans Devanagari',
          );
        } catch (e) {
          return GoogleFonts.notoSansDevanagari(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
          );
        }
      
      case 'Tamil':
        // Try custom font first, fallback to Google Fonts
        try {
          return TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
            fontFamily: 'Noto Sans Tamil',
          );
        } catch (e) {
          return GoogleFonts.notoSansTamil(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
          );
        }
      
      case 'Telugu':
        // Try custom font first, fallback to Google Fonts
        try {
          return TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
            fontFamily: 'Ramabhadra',
          );
        } catch (e) {
          return GoogleFonts.notoSansTelugu(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
          );
        }
      
      case 'Kannada':
        // Try custom font first, fallback to Google Fonts
        try {
          return TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
            fontFamily: 'Noto Sans Kannada',
          );
        } catch (e) {
          return GoogleFonts.notoSansKannada(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
          );
        }
      
      case 'Malayalam':
        // Try custom font first, fallback to Google Fonts
        try {
          return TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
            fontFamily: 'Noto Sans Malayalam',
          );
        } catch (e) {
          return GoogleFonts.notoSansMalayalam(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            decoration: decoration,
          );
        }
      
      case 'Bengali':
        return GoogleFonts.notoSansBengali(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
        );
      
      case 'Gujarati':
        return GoogleFonts.notoSansGujarati(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
        );
      
      case 'Punjabi':
        return GoogleFonts.notoSansGurmukhi(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
        );
      
      case 'Odia':
        return GoogleFonts.notoSansOriya(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
        );
      
      case 'Assamese':
        return GoogleFonts.notoSansBengali(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
        );
      
      case 'Siddham Custom':
        // Use our custom Noto Sans Siddham font
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
          fontFamily: 'Noto Sans Siddham',
        );
      
      case 'Unicode Fallback':
        // For scripts that might not be fully supported, use a comprehensive Unicode font
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
          fontFamily: 'Noto Sans, Roboto, sans-serif',
        );
      
      case 'Default':
      default:
        return GoogleFonts.notoSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          decoration: decoration,
        );
    }
  }

  /// Pick the appropriate font family for a given language
  static String _pickFontFamily(String language) {
    final lower = language.toLowerCase();
    
    // English language
    if (lower.contains('english') || lower.contains('roman itrans')) {
      return 'English';
    }
    
    // Indian scripts
    if (lower.contains('devanagari') || lower.contains('hindi') || lower.contains('sanskrit')) {
      return 'Devanagari';
    }
    if (lower.contains('tamil')) return 'Tamil';
    if (lower.contains('telugu')) return 'Telugu';
    if (lower.contains('kannada')) return 'Kannada';
    if (lower.contains('malayalam')) return 'Malayalam';
    if (lower.contains('bengali')) return 'Bengali';
    if (lower.contains('gujarati')) return 'Gujarati';
    if (lower.contains('punjabi') || lower.contains('gurmukhi')) return 'Punjabi';
    if (lower.contains('odia') || lower.contains('oriya')) return 'Odia';
    if (lower.contains('assamese')) return 'Assamese';
    
    // Special scripts that need custom fonts
    if (lower.contains('siddham')) return 'Siddham Custom';
    
    // Ancient and historical scripts
    if (lower.contains('imperial aramaic') || 
        lower.contains('old south arabian') || 
        lower.contains('phoenician') || 
        lower.contains('samaritan') || 
        lower.contains('sogdian') || 
        lower.contains('syriac') || 
        lower.contains('avestan') || 
        lower.contains('bhaiksuki') || 
        lower.contains('brahmi') || 
        lower.contains('grantha') || 
        lower.contains('javanese') || 
        lower.contains('kharoshthi') || 
        lower.contains('meetei mayek') || 
        lower.contains('newa') || 
        lower.contains('old persian') || 
        lower.contains('ranjana') || 
        lower.contains('santali') || 
        lower.contains('sharada') || 
        lower.contains('soyombo')) {
      return 'Unicode Fallback';
    }
    
    // Default fallback
    return 'Default';
  }

  /// Check if a language requires special font handling
  static bool requiresSpecialFont(String language) {
    final fontFamily = _pickFontFamily(language);
    return fontFamily == 'Siddham Custom' || fontFamily == 'Unicode Fallback';
  }

  /// Get font family name for debugging
  static String getFontFamilyName(String language) {
    return _pickFontFamily(language);
  }
}