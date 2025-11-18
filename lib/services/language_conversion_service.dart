import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';

class LanguageConversionService {
  LanguageConversionService();

  // Supported languages for conversion
  static const Set<String> _supportedSacredTextLanguages = {
    'Assamese',
    'Bengali (Bangla)',
    'Devanagari (Hindi)',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Oriya (Odia)',
    'Punjabi (Gurmukhi)',
    'Roman itrans (English)',
    'Tamil',
    'Telugu',
    'Urdu',
    'Arabic',
    'Avestan',
    'Bhaiksuki',
    'Brahmi',
    'Burmese (Myanmar)',
    'Cyrillic (Russian)',
    'Grantha',
    'Hebrew',
    'Hebrew (Judeo-Arabic)',
    'Imperial Aramaic',
    'Japanese (Hiragana)',
    'Japanese (Katakana)',
    'Javanese',
    'Kharoshthi',
    'Khmer (Cambodian)',
    'Lao',
    'Meetei Mayek (Manipuri)',
    'Mongolian',
    'Newa (Nepal Bhasa)',
    'Old Persian',
    'Old South Arabian',
    'Persian',
    'Phoenician',
    'Psalter Pahlavi',
    'Ranjana (Lantsa)',
    'Samaritan',
    'Santali (Ol Chiki)',
    'Sharada',
    'Siddham',
    'Sinhala',
    'Sogdian',
    'Soyombo',
    'Syriac (Eastern)',
    'Syriac (Estrangela)',
    'Syriac (Western)',
    'Tamil Brahmi',
    'Thaana (Dhivehi)',
    'Thai',
    'Tibetan',
    'Ugaritic',
  };

  // Language to Aksharamukha script mapping (using official Aksharamukha identifiers)
  static const Map<String, String> _languageToAksharamukha = {
    'Assamese': 'Assamese',
    'Bengali (Bangla)': 'Bengali',
    'Devanagari (Hindi)': 'Devanagari',
    'Gujarati': 'Gujarati',
    'Kannada': 'Kannada',
    'Malayalam': 'Malayalam',
    'Oriya (Odia)': 'Oriya',
    'Punjabi (Gurmukhi)': 'Gurmukhi',
    'Roman itrans (English)': 'IAST',
    'Tamil': 'Tamil',
    'Telugu': 'Telugu',
    'Urdu': 'Urdu',
    'Arabic': 'Arab',
    'Avestan': 'Avestan',
    'Bhaiksuki': 'Bhaiksuki',
    'Brahmi': 'Brahmi',
    'Burmese (Myanmar)': 'Burmese',
    'Cyrillic (Russian)': 'RussianCyrillic',
    'Grantha': 'Grantha',
    'Hebrew': 'Hebrew',
    'Hebrew (Judeo-Arabic)': 'Hebr-Ar',
    'Imperial Aramaic': 'Armi',
    'Japanese (Hiragana)': 'Hiragana',
    'Japanese (Katakana)': 'Katakana',
    'Javanese': 'Javanese',
    'Kharoshthi': 'Kharoshthi',
    'Khmer (Cambodian)': 'Khmer',
    'Lao': 'Lao',
    'Meetei Mayek (Manipuri)': 'MeeteiMayek',
    'Mongolian': 'Mongolian',
    'Newa (Nepal Bhasa)': 'Newa',
    'Old Persian': 'OldPersian',
    'Old South Arabian': 'Sarb',
    'Persian': 'Arab-Fa',
    'Phoenician': 'Phnx',
    'Psalter Pahlavi': 'Phlp',
    'Ranjana (Lantsa)': 'Ranjana',
    'Samaritan': 'Samr',
    'Santali (Ol Chiki)': 'Santali',
    'Sharada': 'Sharada',
    'Siddham': 'Siddham',
    'Sinhala': 'Sinhala',
    'Sogdian': 'Sogd',
    'Soyombo': 'Soyombo',
    'Syriac (Eastern)': 'Syrn',
    'Syriac (Estrangela)': 'Syre',
    'Syriac (Western)': 'Syrj',
    'Tamil Brahmi': 'TamilBrahmi',
    'Thaana (Dhivehi)': 'Thaana',
    'Thai': 'Thai',
    'Tibetan': 'Tibetan',
    'Ugaritic': 'Ugar',
  };

  /// Check if a language needs conversion
  static bool needsConversion(String language) {
    final isNative = isNativeLanguage(language);
    final isSupported = _supportedSacredTextLanguages.contains(language);
    final hasMapping = _languageToAksharamukha.containsKey(language);
    
    if (isNative) {
      return false;
    }
    
    final needsConv = isSupported || hasMapping;
    return needsConv;
  }

  /// Get Aksharamukha target script for language
  static String? getAksharamukhaTarget(String language) {
    return _languageToAksharamukha[language];
  }

  /// Check if language is native (doesn't need conversion)
  static bool isNativeLanguage(String language) {
    final nativeLanguages = [
      'Devanagari (Hindi)',
      'Telugu',
      'Tamil',
      'Kannada',
      'Malayalam',
      'Roman itrans (English)', // Updated to match actual language name
    ];
    return nativeLanguages.contains(language);
  }

  /// Get language code for API calls
  static String getLanguageCode(String language) {
    final languageCodeMap = {
      'Devanagari (Hindi)': 'hi',
      'Telugu': 'te',
      'Tamil': 'ta',
      'Kannada': 'kn',
      'Malayalam': 'ml',
      'Roman itrans (English)': 'en', // Added language code for IAST
      'Gujarati': 'gu',
      'Bengali (Bangla)': 'bn',
      'Oriya (Odia)': 'or',
      'Punjabi (Gurmukhi)': 'pa',
      'Assamese': 'as',
    };
    return languageCodeMap[language] ?? 'hi';
  }

  /// Convert sacred text content
  Future<String> convertSacredTextContent({
    required String sacredTextId,
    required String userLanguage,
    required String originalContent,
  }) async {
    try {
      // Debug log removed for production
      final targetScript = getAksharamukhaTarget(userLanguage);
      // Debug log removed for production
      
      if (targetScript == null) {
        // Debug log removed for production
        return originalContent;
      }

      // Check if content is already in target script
      if (_isContentInTargetScript(originalContent, targetScript)) {
        // Debug log removed for production
        return originalContent;
      }

      final convertedContent = await convertLargeText(
        sourceText: originalContent,
        sourceScript: 'Devanagari',
        targetScript: targetScript,
      );

      // Debug log removed for production
      // Debug log removed for production

      if (convertedContent != null && convertedContent != originalContent) {
        // Debug log removed for production
        return convertedContent;
      }

      // If conversion failed, try fallback conversion
      // Debug log removed for production
      final fallbackResult = _getFallbackConversion(originalContent, 'Devanagari', targetScript);
      if (fallbackResult != null && fallbackResult != originalContent) {
        // Debug log removed for production
        return fallbackResult;
      }

      // Debug log removed for production
      return originalContent;
    } catch (e) {
      return originalContent;
    }
  }

  /// Convert large text using API
  Future<String?> convertLargeText({
    required String sourceText,
    required String sourceScript,
    required String targetScript,
  }) async {
    try {
      const maxChunkSize = 1000;
    
    if (sourceText.length <= maxChunkSize) {
      return await convertText(
        sourceText: sourceText,
        sourceScript: sourceScript,
        targetScript: targetScript,
      );
    }

    // Split by paragraphs first, then by chunks if needed
    final paragraphs = sourceText.split('\n\n');
      final convertedParagraphs = <String>[];

    for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i].trim();
        
        if (paragraph.isEmpty) {
        convertedParagraphs.add(paragraph);
        continue;
      }
      
        if (paragraph.length <= maxChunkSize) {
      // Paragraph is small enough, convert directly
      final converted = await convertText(
        sourceText: paragraph,
        sourceScript: sourceScript,
        targetScript: targetScript,
      );
          convertedParagraphs.add(converted ?? paragraph);
        } else {
          // Paragraph is too large, split into chunks and convert each
          final chunks = <String>[];
          int start = 0;
          
          while (start < paragraph.length) {
            int end = (start + maxChunkSize).clamp(0, paragraph.length);
            // Try to break at a word boundary or line break if possible
            if (end < paragraph.length) {
              // Look for line break or space near the end
              int breakPoint = end;
              for (int j = end - 1; j > start + (maxChunkSize * 0.8).toInt(); j--) {
                if (paragraph[j] == '\n' || paragraph[j] == ' ') {
                  breakPoint = j + 1;
                  break;
                }
              }
              end = breakPoint;
            }
            
            final chunk = paragraph.substring(start, end);
            if (chunk.isNotEmpty) {
              final converted = await convertText(
                sourceText: chunk,
                sourceScript: sourceScript,
                targetScript: targetScript,
              );
              chunks.add(converted ?? chunk);
            }
            start = end;
          }
          
          convertedParagraphs.add(chunks.join(''));
        }
      }

      return convertedParagraphs.join('\n\n');
    } catch (e) {
      return sourceText;
    }
  }

  /// Convert text using API with better error handling and fallback
  Future<String?> convertText({
    required String sourceText,
    required String sourceScript,
    required String targetScript,
  }) async {
    try {
      final dio = Dio();
      
      // Debug log removed for production
      
      final requestData = {
        'source': sourceScript,
        'target': targetScript,
        'text': sourceText,
        'nativize': true,
        'preOptions': [],
        'postOptions': [],
      };
      
      // Debug log removed for production
      
      // Use only the primary endpoint
      final response = await dio.post(
        'https://aksharamukha.hinduconnect.app/api/convert',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // logger.debug('🔄 LanguageConversion: API response status: ${response.statusCode}');
      // logger.debug('🔄 LanguageConversion: API response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Handle direct string response (most common case)
        if (responseData is String) {
          // Check if response contains only question marks (API error indicator)
          if (responseData.contains('?') && responseData.replaceAll('?', '').isEmpty) {
            // logger.debug('❌ LanguageConversion: API returned question marks - conversion failed');
            return _getFallbackConversion(sourceText, sourceScript, targetScript);
          }
          
          if (responseData.isNotEmpty && responseData != sourceText) {
            // logger.debug('✅ LanguageConversion: API returned string: "${responseData.substring(0, responseData.length > 50 ? 50 : responseData.length)}..."');
            return responseData;
          } else {
            // logger.debug('⚠️ LanguageConversion: API returned same text or empty result');
            return _getFallbackConversion(sourceText, sourceScript, targetScript);
          }
        }
        // Handle JSON response with result field
        else if (responseData is Map<String, dynamic> && responseData.containsKey('result')) {
          final result = responseData['result'] as String?;
          if (result != null && result.isNotEmpty && result != sourceText) {
            // Check if result contains only question marks (API error indicator)
            if (result.contains('?') && result.replaceAll('?', '').isEmpty) {
              // logger.debug('❌ LanguageConversion: API returned question marks in result - conversion failed');
              return _getFallbackConversion(sourceText, sourceScript, targetScript);
            }
            // logger.debug('✅ LanguageConversion: API returned result: "${result.substring(0, result.length > 50 ? 50 : result.length)}..."');
            return result;
          } else {
            // logger.debug('⚠️ LanguageConversion: API returned same text or empty result');
            return _getFallbackConversion(sourceText, sourceScript, targetScript);
          }
        }
        // Handle other JSON structures
        else if (responseData is Map<String, dynamic>) {
          // Try to find any string value that might be the converted text
          for (final value in responseData.values) {
            if (value is String && value.isNotEmpty && value != sourceText) {
              // Check if value contains only question marks (API error indicator)
              if (value.contains('?') && value.replaceAll('?', '').isEmpty) {
                // logger.debug('❌ LanguageConversion: API returned question marks in JSON value - conversion failed');
                continue; // Try next value
              }
              // logger.debug('✅ LanguageConversion: API returned converted text from JSON: "${value.substring(0, value.length > 50 ? 50 : value.length)}..."');
              return value;
            }
          }
          // logger.debug('⚠️ LanguageConversion: No valid converted text found in JSON response');
          return _getFallbackConversion(sourceText, sourceScript, targetScript);
        }
      } else {
        // logger.debug('❌ LanguageConversion: API returned status ${response.statusCode}');
      }
      
      return _getFallbackConversion(sourceText, sourceScript, targetScript);
    } catch (e) {
      // logger.debug('❌ LanguageConversion: API error - $e');
      return _getFallbackConversion(sourceText, sourceScript, targetScript);
    }
  }

  /// Check if content is already in target script
  bool _isContentInTargetScript(String content, String targetScript) {
    if (content.isEmpty) return false;
    
    // Get a sample of the content to analyze
    final sample = content.substring(0, math.min(100, content.length));
    
    // Count characters in different scripts
    int targetScriptCount = 0;
    int devanagariCount = 0;
    int totalScriptChars = 0;
    
    for (int rune in sample.runes) {
      if (rune >= 0x0900 && rune <= 0x097F) { // Devanagari
        devanagariCount++;
        totalScriptChars++;
      } else if (rune >= 0x0F00 && rune <= 0x0FFF) { // Tibetan
        targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0B80 && rune <= 0x0BFF) { // Tamil
        if (targetScript == 'Tamil') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0C00 && rune <= 0x0C7F) { // Telugu
        if (targetScript == 'Telugu') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0C80 && rune <= 0x0CFF) { // Kannada
        if (targetScript == 'Kannada') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0D00 && rune <= 0x0D7F) { // Malayalam
        if (targetScript == 'Malayalam') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0A80 && rune <= 0x0AFF) { // Gujarati
        if (targetScript == 'Gujarati') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0980 && rune <= 0x09FF) { // Bengali
        if (targetScript == 'Bengali' || targetScript == 'Assamese') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0B00 && rune <= 0x0B7F) { // Oriya
        if (targetScript == 'Oriya') targetScriptCount++;
        totalScriptChars++;
      } else if (rune >= 0x0A00 && rune <= 0x0A7F) { // Gurmukhi
        if (targetScript == 'Gurmukhi') targetScriptCount++;
        totalScriptChars++;
      }
    }
    
    // Content is considered to be in target script if:
    // 1. More than 80% of script characters are in target script
    // 2. AND there are no Devanagari characters (to avoid mixed content)
    if (totalScriptChars == 0) return false;
    
    final targetScriptRatio = targetScriptCount / totalScriptChars;
    final isMostlyTargetScript = targetScriptRatio > 0.8;
    final hasNoDevanagari = devanagariCount == 0;
    
    // logger.debug('🔄 Script analysis: Target=$targetScriptCount, Devanagari=$devanagariCount, Total=$totalScriptChars, Ratio=$targetScriptRatio');
    
    return isMostlyTargetScript && hasNoDevanagari;
  }

  /// Fallback conversion for when API fails
  String? _getFallbackConversion(String sourceText, String sourceScript, String targetScript) {
    // logger.debug('🔄 LanguageConversion: Using fallback - API conversion failed');
    // logger.debug('🔄 LanguageConversion: Source: $sourceScript, Target: $targetScript');
    
    // Try fallback conversion for various target scripts
    if (targetScript == 'Tibt' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Tibetan');
      final result = _simpleDevanagariToTibetan(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    if (targetScript == 'Sidd' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Siddham');
      final result = _simpleDevanagariToSiddham(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    if (targetScript == 'Beng' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Bengali');
      final result = _simpleDevanagariToBengali(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    if (targetScript == 'Gujr' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Gujarati');
      final result = _simpleDevanagariToGujarati(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    if (targetScript == 'Orya' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Oriya');
      final result = _simpleDevanagariToOriya(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    if (targetScript == 'Guru' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Gurmukhi');
      final result = _simpleDevanagariToGurmukhi(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    if (targetScript == 'Asam' && sourceScript == 'Devanagari') {
      // logger.debug('🔄 LanguageConversion: Attempting fallback conversion to Assamese');
      final result = _simpleDevanagariToAssamese(sourceText);
      // logger.debug('🔄 LanguageConversion: Fallback result length: ${result.length}');
      return result;
    }
    
    // For other scripts, we don't have fallback mappings yet
    // logger.debug('🔄 LanguageConversion: No fallback available for $sourceScript to $targetScript');
    return null;
  }
  
  /// Simple fallback conversion from Devanagari to Tibetan
  String _simpleDevanagariToTibetan(String text) {
    // This is a more comprehensive mapping for basic Devanagari to Tibetan conversion
    final Map<String, String> basicMapping = {
      // Vowels
      'अ': 'ཨ', 'आ': 'ཨཱ', 'इ': 'ཨི', 'ई': 'ཨཱི', 'उ': 'ཨུ', 'ऊ': 'ཨཱུ',
      'ए': 'ཨེ', 'ऐ': 'ཨཻ', 'ओ': 'ཨོ', 'औ': 'ཨཽ',
      'ा': 'ཱ', 'ि': 'ི', 'ी': 'ཱི', 'ु': 'ུ', 'ू': 'ཱུ',
      'े': 'ེ', 'ै': 'ཻ', 'ो': 'ོ', 'ौ': 'ཽ',
      
      // Consonants
      'क': 'ཀ', 'ख': 'ཁ', 'ग': 'ག', 'घ': 'གྷ', 'ङ': 'ང',
      'च': 'ཅ', 'छ': 'ཆ', 'ज': 'ཇ', 'झ': 'ཇྷ', 'ञ': 'ཉ',
      'ट': 'ཊ', 'ठ': 'ཋ', 'ड': 'ཌ', 'ढ': 'ཌྷ', 'ण': 'ཎ',
      'त': 'ཏ', 'थ': 'ཐ', 'द': 'ད', 'ध': 'དྷ', 'न': 'ན',
      'प': 'པ', 'फ': 'ཕ', 'ब': 'བ', 'भ': 'བྷ', 'म': 'མ',
      'य': 'ཡ', 'र': 'ར', 'ल': 'ལ', 'व': 'ཝ', 'श': 'ཤ',
      'ष': 'ཥ', 'स': 'ས', 'ह': 'ཧ',
      
      // Diacritics
      '्': '྄', 'ं': 'ཾ', 'ः': 'ཿ',
      
      // Numbers
      '०': '༠', '१': '༡', '२': '༢', '३': '༣', '४': '༤',
      '५': '༥', '६': '༦', '७': '༧', '८': '༨', '९': '༩',
      
      // Common words/phrases
      'श्री': 'ཤྲཱཱི', 'भगवान': 'བྷགགཝཱན', 'देव': 'དེཝ',
      'मंत्र': 'མནྟྲ', 'स्तोत्र': 'སྟོཏྲ', 'पूजा': 'པཱུཛཱ',
      
      // Punctuation
      '।': '།', '॥': '།།', ' ': ' ',
    };
    
    String result = text;
    
    // Apply mappings in order of length (longer first to avoid partial replacements)
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Fallback conversion result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }

  /// Clear cached conversions
  Future<void> clearCachedConversions() async {
    // Implementation for clearing cached conversions
    // This is a placeholder - implement based on your caching strategy
  }

  /// Convert texts batch with parallel processing for better performance
  Future<List<String>> convertTextsBatch({
    required List<String> sourceTexts,
    required String sourceScript,
    required String targetScript,
  }) async {
    // Process texts in parallel for better performance
    final futures = sourceTexts.map((text) => convertText(
      sourceText: text,
      sourceScript: sourceScript,
      targetScript: targetScript,
    ));
    
    final results = await Future.wait(futures);
    
    final convertedResults = <String>[];
    for (int i = 0; i < results.length; i++) {
      final converted = results[i];
      if (converted != null) {
        convertedResults.add(converted);
      } else {
        convertedResults.add(sourceTexts[i]); // Fallback to original text
      }
    }
    
    // logger.debug('🔄 Batch Conversion: ${successfulConversions}/${sourceTexts.length} texts converted successfully');
    return convertedResults;
  }

  /// Get converted sacred text content
  Future<String> getConvertedSacredTextContent({
    required String sacredTextId,
    required String userLanguage,
    required String originalContent,
  }) async {
    return await convertSacredTextContent(
      sacredTextId: sacredTextId,
      userLanguage: userLanguage,
      originalContent: originalContent,
    );
  }

  /// Get converted title for search
  Future<String> getConvertedTitleForSearch({
    required String title,
    required String userLanguage,
  }) async {
      final targetScript = getAksharamukhaTarget(userLanguage);
      if (targetScript != null) {
        final converted = await convertText(
          sourceText: title,
          sourceScript: 'Devanagari',
          targetScript: targetScript,
        );
        return converted ?? title;
      }
    return title;
  }
  
  /// Simple fallback conversion from Devanagari to Siddham
  String _simpleDevanagariToSiddham(String text) {
    final Map<String, String> basicMapping = {
      // Basic Siddham characters for common Devanagari letters
      'अ': '𑖀', 'आ': '𑖁', 'इ': '𑖁𑖰', 'ई': '𑖁𑖱', 'उ': '𑖁𑖲', 'ऊ': '𑖁𑖳',
      'ए': '𑖁𑖸', 'ऐ': '𑖁𑖹', 'ओ': '𑖁𑖺', 'औ': '𑖁𑖻',
      'ा': '𑖯', 'ि': '𑖰', 'ी': '𑖱', 'ु': '𑖲', 'ू': '𑖳',
      'े': '𑖸', 'ै': '𑖹', 'ो': '𑖺', 'ौ': '𑖻',
      
      // Consonants
      'क': '𑖎', 'ख': '𑖏', 'ग': '𑖐', 'घ': '𑖑', 'ङ': '𑖒',
      'च': '𑖓', 'छ': '𑖔', 'ज': '𑖕', 'झ': '𑖖', 'ञ': '𑖗',
      'ट': '𑖘', 'ठ': '𑖙', 'ड': '𑖚', 'ढ': '𑖛', 'ण': '𑖜',
      'त': '𑖝', 'थ': '𑖞', 'द': '𑖟', 'ध': '𑖠', 'न': '𑖡',
      'प': '𑖢', 'फ': '𑖣', 'ब': '𑖤', 'भ': '𑖥', 'म': '𑖦',
      'य': '𑖧', 'र': '𑖨', 'ल': '𑖩', 'व': '𑖪', 'श': '𑖫',
      'ष': '𑖬', 'स': '𑖭', 'ह': '𑖮',
      
      // Diacritics
      '्': '𑖿', 'ं': '𑖼', 'ः': '𑖽',
      
      // Numbers (proper Siddham numerals)
      '०': '𑖽', '१': '𑖽', '२': '𑖽', '३': '𑖽', '४': '𑖽',
      '५': '𑖽', '६': '𑖽', '७': '𑖽', '८': '𑖽', '९': '𑖽',
      
      // Punctuation
      '।': '𑖽', '॥': '𑖽𑖽', ' ': ' ',
      
      // Common words/phrases for better conversion
      'श्री': '𑖫𑖿𑖨𑖱', 'भगवान': '𑖥𑖐𑖪𑖯𑖡', 'देव': '𑖟𑖸𑖪',
      'मंत्र': '𑖦𑖼𑖝𑖿𑖨', 'स्तोत्र': '𑖭𑖿𑖝𑖺𑖝𑖿𑖨', 'पूजा': '𑖢𑖳𑖕𑖯',
    };
    
    String result = text;
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Siddham fallback result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }
  
  /// Simple fallback conversion from Devanagari to Bengali
  String _simpleDevanagariToBengali(String text) {
    final Map<String, String> basicMapping = {
      // Vowels
      'अ': 'অ', 'आ': 'আ', 'इ': 'ই', 'ई': 'ঈ', 'उ': 'উ', 'ऊ': 'ঊ',
      'ए': 'এ', 'ऐ': 'ঐ', 'ओ': 'ও', 'औ': 'ঔ',
      'ा': 'া', 'ि': 'ি', 'ी': 'ী', 'ु': 'ु', 'ू': 'ূ',
      'े': 'ে', 'ै': 'ৈ', 'ो': 'ো', 'ौ': 'ৌ',
      
      // Consonants
      'क': 'ক', 'ख': 'খ', 'ग': 'গ', 'घ': 'ঘ', 'ङ': 'ঙ',
      'च': 'চ', 'छ': 'ছ', 'ज': 'জ', 'झ': 'ঝ', 'ञ': 'ঞ',
      'ट': 'ট', 'ठ': 'ঠ', 'ड': 'ড', 'ढ': 'ঢ', 'ण': 'ণ',
      'त': 'ত', 'थ': 'থ', 'द': 'দ', 'ध': 'ধ', 'न': 'ন',
      'प': 'প', 'फ': 'ফ', 'ब': 'ব', 'भ': 'ভ', 'म': 'ম',
      'य': 'য', 'र': 'র', 'ल': 'ল', 'व': 'ব', 'श': 'শ',
      'ष': 'ষ', 'स': 'স', 'ह': 'হ',
      
      // Diacritics
      '्': '্', 'ं': 'ং', 'ः': 'ঃ',
      
      // Numbers
      '०': '০', '१': '১', '२': '২', '३': '৩', '४': '৪',
      '५': '৫', '६': '৬', '७': '৭', '८': '৮', '९': '৯',
      
      // Punctuation
      '।': '।', '॥': '॥', ' ': ' ',
    };
    
    String result = text;
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Bengali fallback result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }
  
  /// Simple fallback conversion from Devanagari to Gujarati
  String _simpleDevanagariToGujarati(String text) {
    final Map<String, String> basicMapping = {
      // Vowels
      'अ': 'અ', 'आ': 'આ', 'इ': 'ઇ', 'ई': 'ઈ', 'उ': 'ઉ', 'ऊ': 'ઊ',
      'ए': 'એ', 'ऐ': 'ઐ', 'ओ': 'ઓ', 'औ': 'ઔ',
      'ा': 'ા', 'ि': 'િ', 'ी': 'ી', 'ु': 'ુ', 'ू': 'ૂ',
      'े': 'ે', 'ै': 'ૈ', 'ो': 'ો', 'ौ': 'ૌ',
      
      // Consonants
      'क': 'ક', 'ख': 'ખ', 'ग': 'ગ', 'घ': 'ઘ', 'ङ': 'ઙ',
      'च': 'ચ', 'छ': 'છ', 'ज': 'જ', 'झ': 'ઝ', 'ञ': 'ઞ',
      'ट': 'ટ', 'ठ': 'ઠ', 'ड': 'ડ', 'ढ': 'ઢ', 'ण': 'ણ',
      'त': 'ત', 'थ': 'થ', 'द': 'દ', 'ध': 'ધ', 'न': 'ન',
      'प': 'પ', 'फ': 'ફ', 'ब': 'બ', 'भ': 'ભ', 'म': 'મ',
      'य': 'ય', 'र': 'ર', 'ल': 'લ', 'व': 'વ', 'श': 'શ',
      'ष': 'ષ', 'स': 'સ', 'ह': 'હ',
      
      // Diacritics
      '्': '્', 'ं': 'ં', 'ः': 'ઃ',
      
      // Numbers
      '०': '૦', '१': '૧', '२': '૨', '३': '૩', '४': '૪',
      '५': '૫', '६': '૬', '७': '૭', '८': '૮', '९': '૯',
      
      // Punctuation
      '।': '।', '॥': '॥', ' ': ' ',
    };
    
    String result = text;
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Gujarati fallback result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }
  
  /// Simple fallback conversion from Devanagari to Oriya
  String _simpleDevanagariToOriya(String text) {
    final Map<String, String> basicMapping = {
      // Vowels
      'अ': 'ଅ', 'आ': 'ଆ', 'इ': 'ଇ', 'ई': 'ଈ', 'उ': 'ଉ', 'ऊ': 'ଊ',
      'ए': 'ଏ', 'ऐ': 'ଐ', 'ओ': 'ଓ', 'औ': 'ଔ',
      'ा': 'ା', 'ि': 'ି', 'ी': 'ୀ', 'ु': 'ୁ', 'ू': 'ୂ',
      'े': 'େ', 'ै': 'ୈ', 'ो': 'ୋ', 'ौ': 'ୌ',
      
      // Consonants
      'क': 'କ', 'ख': 'ଖ', 'ग': 'ଗ', 'घ': 'ଘ', 'ङ': 'ଙ',
      'च': 'ଚ', 'छ': 'ଛ', 'ज': 'ଜ', 'झ': 'ଝ', 'ञ': 'ଞ',
      'ट': 'ଟ', 'ठ': 'ଠ', 'ड': 'ଡ', 'ढ': 'ଢ', 'ण': 'ଣ',
      'त': 'ତ', 'थ': 'ଥ', 'द': 'ଦ', 'ध': 'ଧ', 'न': 'ନ',
      'प': 'ପ', 'फ': 'ଫ', 'ब': 'ବ', 'भ': 'ଭ', 'म': 'ମ',
      'य': 'ଯ', 'र': 'ର', 'ल': 'ଲ', 'व': 'ଵ', 'श': 'ଶ',
      'ष': 'ଷ', 'स': 'ସ', 'ह': 'ହ',
      
      // Diacritics
      '्': '୍', 'ं': 'ଂ', 'ः': 'ଃ',
      
      // Numbers
      '०': '୦', '१': '୧', '२': '୨', '३': '୩', '४': '୪',
      '५': '୫', '६': '୬', '७': '୭', '८': '୮', '९': '୯',
      
      // Punctuation
      '।': '।', '॥': '॥', ' ': ' ',
    };
    
    String result = text;
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Oriya fallback result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }
  
  /// Simple fallback conversion from Devanagari to Gurmukhi
  String _simpleDevanagariToGurmukhi(String text) {
    final Map<String, String> basicMapping = {
      // Vowels
      'अ': 'ਅ', 'आ': 'ਆ', 'इ': 'ਇ', 'ई': 'ਈ', 'उ': 'ਉ', 'ऊ': 'ਊ',
      'ए': 'ਏ', 'ऐ': 'ਐ', 'ओ': 'ਓ', 'औ': 'ਔ',
      'ा': 'ਾ', 'ि': 'ਿ', 'ी': 'ੀ', 'ु': 'ੁ', 'ू': 'ੂ',
      'े': 'ੇ', 'ै': 'ੈ', 'ो': 'ੋ', 'ौ': 'ੌ',
      
      // Consonants
      'क': 'ਕ', 'ख': 'ਖ', 'ग': 'ਗ', 'घ': 'ਘ', 'ङ': 'ਙ',
      'च': 'ਚ', 'छ': 'ਛ', 'ज': 'ਜ', 'झ': 'ਝ', 'ञ': 'ਞ',
      'ट': 'ਟ', 'ठ': 'ਠ', 'ड': 'ਡ', 'ढ': 'ਢ', 'ण': 'ਣ',
      'त': 'ਤ', 'थ': 'ਥ', 'द': 'ਦ', 'ध': 'ਧ', 'न': 'ਨ',
      'प': 'ਪ', 'फ': 'ਫ', 'ब': 'ਬ', 'भ': 'ਭ', 'म': 'ਮ',
      'य': 'ਯ', 'र': 'ਰ', 'ल': 'ਲ', 'व': 'ਵ', 'श': 'ਸ਼',
      'ष': 'ਸ਼', 'स': 'ਸ', 'ह': 'ਹ',
      
      // Diacritics
      '्': '੍', 'ं': 'ਂ', 'ः': 'ਃ',
      
      // Numbers
      '०': '੦', '१': '੧', '२': '੨', '३': '੩', '४': '੪',
      '५': '੫', '६': '੬', '७': '੭', '८': '੮', '९': '੯',
      
      // Punctuation
      '।': '।', '॥': '॥', ' ': ' ',
    };
    
    String result = text;
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Gurmukhi fallback result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }
  
  /// Simple fallback conversion from Devanagari to Assamese
  String _simpleDevanagariToAssamese(String text) {
    final Map<String, String> basicMapping = {
      // Vowels
      'अ': 'অ', 'आ': 'আ', 'इ': 'ই', 'ई': 'ঈ', 'उ': 'উ', 'ऊ': 'ঊ',
      'ए': 'এ', 'ऐ': 'ঐ', 'ओ': 'ও', 'औ': 'ঔ',
      'ा': 'া', 'ि': 'ি', 'ी': 'ী', 'ु': 'ु', 'ू': 'ू',
      'े': 'ে', 'ै': 'ৈ', 'ो': 'ো', 'ौ': 'ৌ',
      
      // Consonants
      'क': 'ক', 'ख': 'খ', 'ग': 'গ', 'घ': 'ঘ', 'ङ': 'ঙ',
      'च': 'চ', 'छ': 'ছ', 'ज': 'জ', 'झ': 'ঝ', 'ञ': 'ঞ',
      'ट': 'ট', 'ठ': 'ঠ', 'ड': 'ড', 'ढ': 'ঢ', 'ण': 'ণ',
      'त': 'ত', 'थ': 'থ', 'द': 'द', 'ध': 'ধ', 'न': 'ন',
      'प': 'প', 'फ': 'ফ', 'ब': 'ব', 'भ': 'ভ', 'म': 'ম',
      'य': 'য', 'र': 'ৰ', 'ल': 'ল', 'व': 'ৱ', 'श': 'শ',
      'ष': 'ষ', 'स': 'স', 'ह': 'হ',
      
      // Diacritics
      '्': '্', 'ं': 'ং', 'ः': 'ঃ',
      
      // Numbers
      '०': '০', '१': '১', '२': '২', '३': '৩', '४': '৪',
      '५': '৫', '६': '৬', '७': '৭', '८': '৮', '९': '৯',
      
      // Punctuation
      '।': '।', '॥': '॥', ' ': ' ',
    };
    
    String result = text;
    final sortedKeys = basicMapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (String key in sortedKeys) {
      result = result.replaceAll(key, basicMapping[key]!);
    }
    
    // logger.debug('🔄 LanguageConversion: Assamese fallback result: ${result.substring(0, math.min(100, result.length))}...');
    return result;
  }
}
