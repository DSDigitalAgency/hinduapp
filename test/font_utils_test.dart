import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hindu_connect/utils/font_utils.dart';

void main() {
  group('FontUtils Tests', () {
    test('should return proper fonts for major language families', () {
      // Test Devanagari scripts
      final hindiStyle = FontUtils.getTextStyleForLanguage('Devanagari (Hindi)');
      expect(hindiStyle.fontFamily, contains('NotoSansDevanagari'));

      // Test Bengali
      final bengaliStyle = FontUtils.getTextStyleForLanguage('Bengali (Bangla)');
      expect(bengaliStyle.fontFamily, contains('NotoSansBengali'));

      // Test Tamil
      final tamilStyle = FontUtils.getTextStyleForLanguage('Tamil');
      expect(tamilStyle.fontFamily, contains('NotoSansTamil'));

      // Test Arabic
      final arabicStyle = FontUtils.getTextStyleForLanguage('Arabic');
      expect(arabicStyle.fontFamily, contains('NotoSansArabic'));

      // Test default fallback
      final englishStyle = FontUtils.getTextStyleForLanguage('English');
      expect(englishStyle.fontFamily, contains('NotoSans'));
    });

    test('should handle custom styling parameters', () {
      final customStyle = FontUtils.getTextStyleForLanguage(
        'Devanagari (Hindi)',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      );

      expect(customStyle.fontSize, equals(20));
      expect(customStyle.fontWeight, equals(FontWeight.bold));
      expect(customStyle.color, equals(Colors.red));
    });

    test('should provide helper methods for common styles', () {
      final titleStyle = FontUtils.getTitleStyle('Tamil');
      expect(titleStyle.fontSize, equals(16));
      expect(titleStyle.fontWeight, equals(FontWeight.bold));

      final bodyStyle = FontUtils.getBodyStyle('Telugu');
      expect(bodyStyle.fontSize, equals(14));
      expect(bodyStyle.fontWeight, equals(FontWeight.normal));

      final subtitleStyle = FontUtils.getSubtitleStyle('Gujarati');
      expect(subtitleStyle.fontSize, equals(12));
      expect(subtitleStyle.fontWeight, equals(FontWeight.w500));
    });

    test('should handle case insensitive language names', () {
      final upperCaseStyle = FontUtils.getTextStyleForLanguage('DEVANAGARI (HINDI)');
      final lowerCaseStyle = FontUtils.getTextStyleForLanguage('devanagari (hindi)');
      
      expect(upperCaseStyle.fontFamily, equals(lowerCaseStyle.fontFamily));
    });

    test('should handle special scripts correctly', () {
      // Test Siddham (custom font)
      final siddhamStyle = FontUtils.getTextStyleForLanguage('Siddham');
      expect(siddhamStyle.fontFamily, equals('Noto Sans Siddham'));

      // Test Sogdian
      final sogdianStyle = FontUtils.getTextStyleForLanguage('Sogdian');
      expect(sogdianStyle.fontFamily, contains('NotoSansSogdian'));

      // Test Pahlavi
      final pahlaviStyle = FontUtils.getTextStyleForLanguage('Psalter Pahlavi');
      expect(pahlaviStyle.fontFamily, contains('NotoSansPsalterPahlavi'));
    });
  });
}
