import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class for handling fonts across different languages and scripts
class FontUtils {
  FontUtils._();

  /// Get appropriate TextStyle for a given language
  static TextStyle getTextStyleForLanguage(
    String language, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
    double height = 1.2,
    TextDecoration decoration = TextDecoration.none,
  }) {
    final normalizedLanguage = language.toLowerCase();

    // Sanskrit/Devanagari scripts
    if (normalizedLanguage.contains('devanagari') ||
        normalizedLanguage.contains('hindi') ||
        normalizedLanguage.contains('sanskrit') ||
        normalizedLanguage.contains('bhaiksuki') ||
        normalizedLanguage.contains('brahmi') ||
        normalizedLanguage.contains('grantha') ||
        normalizedLanguage.contains('kharoshthi')) {
      return GoogleFonts.notoSansDevanagari(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Bengali/Bangla
    if (normalizedLanguage.contains('bengali') ||
        normalizedLanguage.contains('bangla')) {
      return GoogleFonts.notoSansBengali(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Tamil
    if (normalizedLanguage.contains('tamil')) {
      return GoogleFonts.notoSansTamil(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Telugu
    if (normalizedLanguage.contains('telugu')) {
      return GoogleFonts.notoSansTelugu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Gujarati
    if (normalizedLanguage.contains('gujarati')) {
      return GoogleFonts.notoSansGujarati(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Kannada
    if (normalizedLanguage.contains('kannada')) {
      return GoogleFonts.notoSansKannada(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Malayalam
    if (normalizedLanguage.contains('malayalam')) {
      return GoogleFonts.notoSansMalayalam(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Oriya/Odia
    if (normalizedLanguage.contains('oriya') ||
        normalizedLanguage.contains('odia')) {
      return GoogleFonts.notoSansOriya(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Punjabi/Gurmukhi
    if (normalizedLanguage.contains('punjabi') ||
        normalizedLanguage.contains('gurmukhi')) {
      return GoogleFonts.notoSansGurmukhi(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Assamese
    if (normalizedLanguage.contains('assamese')) {
      return GoogleFonts.notoSansBengali( // Assamese uses Bengali script
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Arabic scripts
    if (normalizedLanguage.contains('arabic') ||
        normalizedLanguage.contains('urdu') ||
        normalizedLanguage.contains('persian') ||
        normalizedLanguage.contains('aramaic') ||
        normalizedLanguage.contains('phoenician') ||
        normalizedLanguage.contains('samaritan') ||
        normalizedLanguage.contains('south arabian')) {
      return GoogleFonts.notoSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Hebrew
    if (normalizedLanguage.contains('hebrew')) {
      return GoogleFonts.notoSansHebrew(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Siddham
    if (normalizedLanguage.contains('siddham')) {
      return const TextStyle(
        fontFamily: 'Noto Sans Siddham',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
        height: 1.2,
        decoration: TextDecoration.none,
      ).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Sogdian
    if (normalizedLanguage.contains('sogdian')) {
      return GoogleFonts.notoSansSogdian(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Psalter Pahlavi
    if (normalizedLanguage.contains('pahlavi')) {
      return GoogleFonts.notoSansPsalterPahlavi(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Tibetan
    if (normalizedLanguage.contains('tibetan')) {
      return GoogleFonts.notoSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Thai
    if (normalizedLanguage.contains('thai')) {
      return GoogleFonts.notoSansThai(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Lao
    if (normalizedLanguage.contains('lao')) {
      return GoogleFonts.notoSansLao(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Khmer/Cambodian
    if (normalizedLanguage.contains('khmer') ||
        normalizedLanguage.contains('cambodian')) {
      return GoogleFonts.notoSansKhmer(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Burmese/Myanmar
    if (normalizedLanguage.contains('burmese') ||
        normalizedLanguage.contains('myanmar')) {
      return GoogleFonts.notoSansMyanmar(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Sinhala
    if (normalizedLanguage.contains('sinhala')) {
      return GoogleFonts.notoSansSinhala(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Japanese
    if (normalizedLanguage.contains('japanese') ||
        normalizedLanguage.contains('hiragana') ||
        normalizedLanguage.contains('katakana')) {
      return GoogleFonts.notoSansJp(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Mongolian
    if (normalizedLanguage.contains('mongolian')) {
      return GoogleFonts.notoSansMongolian(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Russian/Cyrillic
    if (normalizedLanguage.contains('russian') ||
        normalizedLanguage.contains('cyrillic')) {
      return GoogleFonts.notoSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Javanese
    if (normalizedLanguage.contains('javanese')) {
      return GoogleFonts.notoSansJavanese(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    // Default fallback for unsupported languages
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  /// Quick helper for common text styles
  static TextStyle getTitleStyle(String language) {
    return getTextStyleForLanguage(
      language,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getBodyStyle(String language) {
    return getTextStyleForLanguage(
      language,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle getSubtitleStyle(String language) {
    return getTextStyleForLanguage(
      language,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
  }
}
