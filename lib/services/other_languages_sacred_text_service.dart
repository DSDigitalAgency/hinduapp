import '../models/sacred_text_model.dart';
import 'language_conversion_service.dart';

/// Dedicated service to convert Devanagari sacred texts into the user's
/// preferred language using the LanguageConversionService
class OtherLanguagesSacredTextService {
  OtherLanguagesSacredTextService();

  final LanguageConversionService _conv = LanguageConversionService();

  /// Check if a language needs conversion
  /// 
  /// We exclude the 6 primary sacred text languages, which are handled natively.
  /// For these languages, we return the original content without conversion.
  /// 
  /// The 6 primary languages are:
  /// - Devanagari (Hindi) - Native support
  /// - Roman itrans (English) - Native support  
  /// - Tamil - Native support
  /// - Telugu - Native support
  /// - Malayalam - Native support
  /// - Kannada - Native support
  /// 
  /// These 6 languages have sacred text data, so no conversion needed
  static const Set<String> _primaryLanguages = {
    'Devanagari (Hindi)',
    'Roman itrans (English)',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Kannada',
  };

  /// Check if a language needs conversion
  bool needsConversion(String languageName) {
    return !_primaryLanguages.contains(languageName);
  }

  /// Get the target script for conversion using the same mapping as LanguageConversionService
  String? getTargetScript(String languageName) {
    // Use the same mapping as LanguageConversionService for consistency
    return LanguageConversionService.getAksharamukhaTarget(languageName);
  }

  /// Convert a single sacred text (assumed Devanagari source) to the target language.
  /// Returns a new SacredTextModel with converted content.
  Future<SacredTextModel> convertFromDevanagari({
    required SacredTextModel source,
    required String targetLanguage,
  }) async {
    try {
      final targetScript = getTargetScript(targetLanguage);
      if (targetScript == null) {
        // If we can't determine the target script, return the original
        return _createFallbackSacredText(source, source.title ?? '', source.text ?? source.excerpt ?? '');
      }

      final originalTitle = source.title ?? '';
      final originalContent = source.text ?? source.excerpt ?? '';

      if (originalTitle.isEmpty && originalContent.isEmpty) {
        return _createFallbackSacredText(source, 'No content available', 'No content available');
      }

      // Convert the content using the improved conversion service
      String converted = await _conv.convertSacredTextContent(
        sacredTextId: source.sacredTextId ?? '',
        userLanguage: targetLanguage,
        originalContent: originalContent,
      );

      if (converted.isEmpty || converted == originalContent) {
        // If conversion fails or returns same content, return fallback
        return _createFallbackSacredText(source, originalTitle, originalContent);
      }

      // Convert the title if it exists
      String convertedTitle = originalTitle;
      if (originalTitle.isNotEmpty) {
        convertedTitle = await _conv.getConvertedTitleForSearch(
          title: originalTitle,
          userLanguage: targetLanguage,
        );
        if (convertedTitle.isEmpty || convertedTitle == originalTitle) {
          convertedTitle = originalTitle;
        }
      }

      // Return converted sacred text
      return SacredTextModel(
        sacredTextId: source.sacredTextId,
        title: convertedTitle,
        excerpt: converted,
        text: converted,
        languageUsed: targetLanguage,
        highlights: source.highlights,
        subtitle: source.subtitle,
      );
    } catch (e) {
      // Return fallback sacred text with original content and English subtitle
      return _createFallbackSacredText(source, source.title ?? '', source.text ?? source.excerpt ?? '');
    }
  }

  /// Create a fallback sacred text when conversion fails
  SacredTextModel _createFallbackSacredText(SacredTextModel source, String title, String content) {
    return SacredTextModel(
      sacredTextId: source.sacredTextId,
      title: title,
      excerpt: content,
      text: content,
      languageUsed: source.languageUsed,
      highlights: source.highlights,
      subtitle: source.subtitle,
    );
  }

  /// Batch convert a list of Devanagari sacred texts for the target language.
  /// This is useful for converting search results in bulk.
  Future<List<SacredTextModel>> convertListFromDevanagari({
    required List<SacredTextModel> sacredTexts,
    required String targetLanguage,
  }) async {
    final List<Future<SacredTextModel>> jobs = [];
    for (final s in sacredTexts) {
      jobs.add(convertFromDevanagari(
        source: s,
        targetLanguage: targetLanguage,
      ));
    }

    try {
      final results = await Future.wait(jobs);
      return results;
    } catch (e) {
      // If batch conversion fails, return original sacred texts
      return sacredTexts;
    }
  }
}
