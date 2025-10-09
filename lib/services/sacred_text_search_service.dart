import 'dart:async';
import '../models/sacred_text_model.dart';
import 'language_conversion_service.dart';
import 'api_service.dart';
import 'logger_service.dart';

class SacredTextSearchService {
  static const int _maxResults = 20;
  static final ApiService _apiService = ApiService();
  
  // Cache for search results
  static final Map<String, List<SacredTextModel>> _searchCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Languages that have content available directly from API (no conversion needed)
  static const Set<String> _availableLanguages = {
    'Devanagari (Hindi)',
    'Roman itrans (English)',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
  };

  // Helper method to check if language has direct content available
  static bool _hasDirectContent(String language) {
    return _availableLanguages.contains(language);
  }

  /// Get random sacred texts with language conversion
  static Future<List<SacredTextModel>> getRandomSacredTextsWithConversion({
    required String? userPreferredLanguage,
    int limit = 10,
  }) async {
    try {
      // Use ApiService for authenticated requests
      final response = await _apiService.getRandomSacredTexts(count: limit);

      final List<dynamic> data = response['results'] ?? [];
      final List<SacredTextModel> sacredTexts = [];

      for (final item in data) {
        try {
          final sacredText = SacredTextModel.fromJson(item);
          
        // Skip conversion if language has direct content available from API
        if (userPreferredLanguage != null && _hasDirectContent(userPreferredLanguage)) {
          sacredTexts.add(sacredText);
        } else if (userPreferredLanguage != null && 
            LanguageConversionService.needsConversion(userPreferredLanguage)) {
          
          try {
            final convertedSacredText = await _convertSacredTextContent(
              sacredText: sacredText,
              targetLanguage: userPreferredLanguage,
            );
            sacredTexts.add(convertedSacredText);
          } catch (e) {
            // If conversion fails, add original text
            sacredTexts.add(sacredText);
          }
        } else {
          sacredTexts.add(sacredText);
        }
        } catch (e) {
          continue; // Skip invalid items
        }
      }

      return sacredTexts;
    } catch (e) {
      return [];
    }
  }

  /// Search sacred texts with optimized performance
  static Future<Map<String, dynamic>> searchSacredTexts({
    required String query,
    required String? userPreferredLanguage,
    String? sortBy = 'title',
    int page = 1,
    int limit = _maxResults,
  }) async {
    try {
      // Check cache first (only for first page to avoid pagination issues)
      if (page == 1) {
      final cacheKey = '${query}_${userPreferredLanguage}_$sortBy';
      if (_isCacheValid(cacheKey)) {
          final cachedResults = _searchCache[cacheKey] ?? [];
          return {
            'results': cachedResults,
            'metadata': {},
            'total': cachedResults.length,
          };
        }
      }

      // Simplified search parameters for better performance
      final Map<String, String> queryParams = {
        'q': query,
        'limit': limit.toString(),
      };

      // Only add sortBy for first page to avoid memory issues
      if (page == 1) {
        queryParams['sortBy'] = sortBy ?? 'title';
      }

      if (page > 1) {
        queryParams['page'] = page.toString();
      }

      // Language handling - use direct content for 6 languages, Devanagari + conversion for others
      if (userPreferredLanguage != null) {
        if (_hasDirectContent(userPreferredLanguage)) {
          // For the 6 languages, search directly in that language
          final languageCode = LanguageConversionService.getLanguageCode(userPreferredLanguage);
          queryParams['language'] = languageCode;
          logger.debug('🔍 Sacred Text Search: Requesting direct content in language: $languageCode');
        } else {
          // For other languages, search in Devanagari for conversion
          queryParams['language'] = 'hi';
          logger.debug('🔍 Sacred Text Search: Requesting Devanagari content for conversion to $userPreferredLanguage');
        }
      }
      


      // Try search with retry logic
      Map<String, dynamic> response;
      try {
        // Use ApiService for authenticated requests
        logger.debug('🔍 Sacred Text Search: Starting search with params: $queryParams');
        response = await _apiService.searchSacredTexts(queryParams);
        logger.debug('🔍 Sacred Text Search: Search completed successfully');
              } catch (e) {
        logger.debug('🔍 Sacred Text Search: Search failed with error: $e');
        
          
          // If it's a timeout or memory limit error, try with simpler parameters
          if (e.toString().contains('TimeoutException') || 
              e.toString().contains('memory limit') ||
              e.toString().contains('Sort exceeded memory limit')) {
          logger.debug(
            'Search timed out, trying with simplified parameters...',
          );
          
          // Try with minimal parameters (no sorting to avoid memory issues)
          final simplifiedParams = {
            'q': query, // API uses 'q' for query
            'limit': limit.toString(), // Use the provided limit
          };
          
          // Keep language filter - use same logic as main request
          if (userPreferredLanguage != null) {
            if (_hasDirectContent(userPreferredLanguage)) {
              final languageCode = LanguageConversionService.getLanguageCode(userPreferredLanguage);
              simplifiedParams['language'] = languageCode;
            } else {
              simplifiedParams['language'] = 'hi'; // Devanagari code
            }
          }
          
          try {
            logger.debug('🔍 Sacred Text Search: Retrying with simplified params: $simplifiedParams');
            response = await _apiService.searchSacredTexts(simplifiedParams);
            logger.debug('🔍 Sacred Text Search: Retry search completed successfully');
            
          } catch (retryError) {
            logger.debug(
              '🔍 Sacred Text Search: Search failed even with simplified parameters: $retryError',
            );
            return {
              'results': [],
              'metadata': {},
              'total': 0,
            };
          }
        } else {
          return {
            'results': [],
            'metadata': {},
            'total': 0,
          };
        }
      }

      logger.debug('🔍 Sacred Text Search: Processing response - keys: ${response.keys.toList()}');
      final List<dynamic> data = response['results'] ?? [];
      logger.debug('🔍 Sacred Text Search: Found ${data.length} items in response');
      
      final List<SacredTextModel> sacredTexts = [];

      for (int i = 0; i < data.length; i++) {
        try {
          final item = data[i];
          
          // Ensure item is a Map<String, dynamic> before passing to fromJson
          Map<String, dynamic> itemMap;
          if (item is Map<String, dynamic>) {
            itemMap = item;
          } else if (item is SacredTextModel) {
            // If it's already a SacredTextModel, use it directly
            sacredTexts.add(item);
            continue;
          } else {
            continue;
          }
          
          final sacredText = SacredTextModel.fromJson(itemMap);
          logger.debug('🔍 Sacred Text Search: Created model for "${sacredText.title}"');
          
          // Add to list for batch processing
          sacredTexts.add(sacredText);
        } catch (e) {
          continue; // Skip invalid items
        }
      }

      // Clear raw data to free memory
      data.clear();

      // Skip conversion for direct content languages, convert for others
      if (userPreferredLanguage != null && _hasDirectContent(userPreferredLanguage)) {
        // No conversion needed - content is already in the correct language
        logger.debug('🔍 Sacred Text Search: Using direct content, no conversion needed');
      } else if (userPreferredLanguage != null && 
          LanguageConversionService.needsConversion(userPreferredLanguage)) {
        
        logger.debug('🔍 Sacred Text Search: Converting content to $userPreferredLanguage');
        final convertedTexts = await _convertSacredTextsBatchTitlesOnly(
          sacredTexts: sacredTexts,
          targetLanguage: userPreferredLanguage,
        );
        
        // Clear original list and add converted items
        sacredTexts.clear();
        sacredTexts.addAll(convertedTexts);
        
        // Clear converted list to free memory
        convertedTexts.clear();
      } else {
        
        // Fix language field mapping for native languages
        for (int i = 0; i < sacredTexts.length; i++) {
          final sacredText = sacredTexts[i];
          if (sacredText.languageUsed == 'Itrans' && userPreferredLanguage == 'English') {
            // Create new model with corrected language field
            final correctedModel = SacredTextModel(
              sacredTextId: sacredText.sacredTextId,
              title: sacredText.title,
              excerpt: sacredText.excerpt,
              text: sacredText.text,
              languageUsed: 'English', // Fix the language field
              category: sacredText.category,
              tags: sacredText.tags,
              isConverted: false,
              originalLanguage: sacredText.languageUsed,
            );
            sacredTexts[i] = correctedModel;
          } else if (sacredText.languageUsed == 'Devanagari' && userPreferredLanguage == 'Devanagari (Hindi)') {
            // Create new model with corrected language field
            final correctedModel = SacredTextModel(
              sacredTextId: sacredText.sacredTextId,
              title: sacredText.title,
              excerpt: sacredText.excerpt,
              text: sacredText.text,
              languageUsed: 'Devanagari (Hindi)', // Fix the language field
              category: sacredText.category,
              tags: sacredText.tags,
              isConverted: false,
              originalLanguage: sacredText.languageUsed,
            );
            sacredTexts[i] = correctedModel;
          }
        }
      }

      // Cache results (only for first page to avoid pagination issues)
      if (page == 1) {
        final cacheKey = '${query}_${userPreferredLanguage}_$sortBy';
      _searchCache[cacheKey] = sacredTexts;
      _cacheTimestamps[cacheKey] = DateTime.now();
      }

      // Return both results and metadata
      return {
        'results': sacredTexts,
        'metadata': response['metadata'] ?? {},
        'total': response['metadata']?['total'] ?? sacredTexts.length,
      };
    } catch (e) {
      // Silent fail
      return {
        'results': [],
        'metadata': {},
        'total': 0,
      };
    }
  }

  /// Batch convert titles and content previews for search results
  static Future<List<SacredTextModel>> _convertSacredTextsBatchTitlesOnly({
    required List<SacredTextModel> sacredTexts,
    required String targetLanguage,
  }) async {
    if (sacredTexts.isEmpty) return sacredTexts;
    
    final conversionService = LanguageConversionService();
    final targetScript = LanguageConversionService.getAksharamukhaTarget(targetLanguage);
    
    logger.debug(
      '🔍 Batch Conversion: Target language: $targetLanguage, target script: $targetScript',
    );
    
    if (targetScript == null) {
      logger.debug(
        '🔍 Batch Conversion: No target script found for $targetLanguage, using original',
      );
      return sacredTexts;
    }

    logger.debug(
      '🔍 Batch Conversion: Converting ${sacredTexts.length} titles and previews from Devanagari to $targetLanguage (script: $targetScript)',
    );

    // Prepare titles and content for batch conversion
    final List<String> titles = [];
    final List<String> contentPreviews = [];
    final List<int> titleIndices = [];
    final List<int> contentIndices = [];
    
    for (int i = 0; i < sacredTexts.length; i++) {
      final sacredText = sacredTexts[i];
      
      // Add title for conversion
      if (sacredText.title != null && sacredText.title!.isNotEmpty) {
        titles.add(sacredText.title!);
        titleIndices.add(i);
      }
      
      // Add content for preview conversion - prefer excerpt, fallback to text
      String? contentForPreview;
      if (sacredText.excerpt != null && sacredText.excerpt!.isNotEmpty) {
        contentForPreview = sacredText.excerpt!.trim();
        // Check for truncated content (ends mid-word or with incomplete sentence)
        if (contentForPreview.length > 10 &&
            !contentForPreview.endsWith('।') &&
            !contentForPreview.endsWith('॥') &&
            !contentForPreview.endsWith('.') &&
            !contentForPreview.endsWith('|') &&
            contentForPreview.length < sacredText.excerpt!.length) {
          // Try to find a better breaking point
          final words = contentForPreview.split(' ');
          if (words.length > 3) {
            // Take all but the last potentially incomplete word
            contentForPreview =
                '${words.sublist(0, words.length - 1).join(' ')}...';
          }
        }
      } else if (sacredText.text != null && sacredText.text!.isNotEmpty) {
        // Extract a preview from the full text content (first ~150 characters)
        final textContent = sacredText.text!.trim();
        contentForPreview = textContent.length > 150
            ? '${textContent.substring(0, 150)}...'
            : textContent;
      } else {
        // If no content available, create a basic description from title
        if (sacredText.title != null && sacredText.title!.isNotEmpty) {
          contentForPreview = '${sacredText.title!} - Sacred text content';
        }
      }

      if (contentForPreview != null && contentForPreview.trim().isNotEmpty) {
        contentPreviews.add(contentForPreview);
        contentIndices.add(i);
      }
    }

    // Batch convert titles and content previews
    List<String?> convertedTitles = [];
    List<String?> convertedContentPreviews = [];
    
    try {
      if (titles.isNotEmpty) {
        logger.debug('🔍 Batch Conversion: Converting ${titles.length} titles');
        try {
          final convertedTitlesResult = await conversionService
              .convertTextsBatch(
                sourceTexts: titles,
                sourceScript: 'Devanagari',
                targetScript: targetScript,
              );
          // Ensure we maintain the same count as input, filling nulls for failed conversions
          convertedTitles = List<String?>.filled(
            titles.length,
            null,
            growable: true,
          );
          for (
            int i = 0;
            i < convertedTitlesResult.length && i < titles.length;
            i++
          ) {
            if (convertedTitlesResult[i].toString().trim().isNotEmpty &&
                convertedTitlesResult[i].toString() != titles[i]) {
              convertedTitles[i] = convertedTitlesResult[i].toString();
            }
          }
          final successfulTitles = convertedTitles
              .where((t) => t != null)
              .length;
          logger.debug(
            '🔍 Batch Conversion: $successfulTitles/${titles.length} titles converted successfully',
          );
        } catch (e) {
          logger.debug('🔍 Batch Conversion: Title conversion failed: $e');
          convertedTitles = List<String?>.filled(
            titles.length,
            null,
            growable: true,
          );
        }
      }
      
      if (contentPreviews.isNotEmpty) {
        logger.debug(
          '🔍 Batch Conversion: Converting ${contentPreviews.length} content previews',
        );
        try {
          final convertedContentResult = await conversionService
              .convertTextsBatch(
                sourceTexts: contentPreviews,
                sourceScript: 'Devanagari',
                targetScript: targetScript,
              );
          // Ensure we maintain the same count as input, filling nulls for failed conversions
          convertedContentPreviews = List<String?>.filled(
            contentPreviews.length,
            null,
            growable: true,
          );
          for (
            int i = 0;
            i < convertedContentResult.length && i < contentPreviews.length;
            i++
          ) {
            if (convertedContentResult[i].toString().trim().isNotEmpty &&
                convertedContentResult[i].toString() != contentPreviews[i]) {
              convertedContentPreviews[i] = convertedContentResult[i]
                  .toString();
            }
          }
          final successfulPreviews = convertedContentPreviews
              .where((p) => p != null)
              .length;
          logger.debug(
            '🔍 Batch Conversion: $successfulPreviews/${contentPreviews.length} content previews converted successfully',
          );
        } catch (e) {
          logger.debug('🔍 Batch Conversion: Content conversion failed: $e');
          convertedContentPreviews = List<String?>.filled(
            contentPreviews.length,
            null,
            growable: true,
          );
        }
      }

      // Apply converted titles and content previews to models
      final List<SacredTextModel> convertedModels = [];
      int titleIndex = 0;
      int contentIndex = 0;
      
      for (int i = 0; i < sacredTexts.length; i++) {
        final originalModel = sacredTexts[i];
        
        String? convertedTitle;
        String? convertedContentPreview;

        // Get converted title if available
        if (titleIndices.contains(i) &&
            titleIndex < convertedTitles.length) {
          convertedTitle = convertedTitles[titleIndex];
          titleIndex++;
        }

        // Get converted content preview if available
        if (contentIndices.contains(i) &&
            contentIndex < convertedContentPreviews.length) {
          convertedContentPreview = convertedContentPreviews[contentIndex];
          contentIndex++;
        }

        // Determine if this text was actually converted
        final hasConvertedTitle = convertedTitle != null && convertedTitle != originalModel.title;
        final hasConvertedContent = convertedContentPreview != null && convertedContentPreview != originalModel.excerpt;
        final wasConverted = hasConvertedTitle || hasConvertedContent;

        // Use converted content if available, otherwise show original
        String displayTitle = convertedTitle ?? originalModel.title ?? '';
        String displayExcerpt = convertedContentPreview ?? originalModel.excerpt ?? '';
        
        // Only show fallback message if conversion actually failed
        if (!wasConverted && targetLanguage != originalModel.languageUsed) {
          displayTitle = '${originalModel.title ?? 'Untitled'} (Conversion not available)';
          displayExcerpt = 'Content conversion to $targetLanguage is currently not available. Showing original content.';
        }

        // Create new model with converted content
        final convertedModel = SacredTextModel(
          sacredTextId: originalModel.sacredTextId,
          title: displayTitle,
          subtitle: originalModel.subtitle,
          excerpt: displayExcerpt,
          text: originalModel
              .text, // Keep original full text for now - will be converted in reading screen
          languageUsed: wasConverted
              ? targetLanguage
              : originalModel.languageUsed,
          category: originalModel.category,
          author: originalModel.author,
          description: originalModel.description,
          tags: originalModel.tags,
          isConverted: wasConverted,
          originalLanguage: wasConverted ? originalModel.languageUsed : null,
        );
        convertedModels.add(convertedModel);
      }
      
      // Clear temporary lists to free memory  
      titles.clear();
      contentPreviews.clear();
      titleIndices.clear();
      contentIndices.clear();
      // Now safe to clear since we made them growable
      convertedTitles.clear();
      convertedContentPreviews.clear();

      logger.debug(
        '🔍 Batch Conversion: Created ${convertedModels.length} converted models',
      );
      return convertedModels;
      
    } catch (e) {
      logger.debug('🔍 Batch Conversion: Error during conversion: $e');
      return sacredTexts; // Return original if conversion fails
    }
  }

  /// Convert sacred text content to user's preferred language (individual method)
  static Future<SacredTextModel> _convertSacredTextContent({
    required SacredTextModel sacredText,
    required String targetLanguage,
  }) async {
    final conversionService = LanguageConversionService();
    final targetScript = LanguageConversionService.getAksharamukhaTarget(targetLanguage);
    
    if (targetScript == null) {
      return sacredText;
    }

    // Convert title
    String? convertedTitle;
    if (sacredText.title != null && sacredText.title!.isNotEmpty) {
      try {
        convertedTitle = await conversionService.convertText(
          sourceText: sacredText.title!,
          sourceScript: 'Devanagari',
          targetScript: targetScript,
        );
        // Check if conversion actually worked
        if (convertedTitle == sacredText.title) {
          convertedTitle = null; // Mark as failed if same content returned
        }
      } catch (e) {
        convertedTitle = null;
      }
    }

    // Convert content (excerpt or text)
    String? convertedContent;
    if (sacredText.excerpt != null && sacredText.excerpt!.isNotEmpty) {
      try {
        convertedContent = await conversionService.convertText(
          sourceText: sacredText.excerpt!,
          sourceScript: 'Devanagari',
          targetScript: targetScript,
        );
        // Check if conversion actually worked
        if (convertedContent == sacredText.excerpt) {
          convertedContent = null; // Mark as failed if same content returned
        }
      } catch (e) {
        convertedContent = null;
      }
    } else if (sacredText.text != null && sacredText.text!.isNotEmpty) {
      try {
        convertedContent = await conversionService.convertText(
          sourceText: sacredText.text!,
          sourceScript: 'Devanagari',
          targetScript: targetScript,
        );
        // Check if conversion actually worked
        if (convertedContent == sacredText.text) {
          convertedContent = null; // Mark as failed if same content returned
        }
      } catch (e) {
        convertedContent = null;
      }
    }

    // Create converted model
    final hasConvertedTitle = convertedTitle != null;
    final hasConvertedContent = convertedContent != null;
    final wasConverted = hasConvertedTitle || hasConvertedContent;
    
    final convertedModel = SacredTextModel(
      sacredTextId: sacredText.sacredTextId,
      title: convertedTitle ?? sacredText.title,
      subtitle: sacredText.subtitle,
      excerpt: convertedContent ?? sacredText.excerpt,
      text: convertedContent ?? sacredText.text,
      languageUsed: wasConverted ? targetLanguage : sacredText.languageUsed,
      usedFallback: sacredText.usedFallback,
      highlights: sacredText.highlights,
      category: sacredText.category,
      author: sacredText.author,
      description: sacredText.description,
      tags: sacredText.tags,
      isConverted: wasConverted,
      originalLanguage: wasConverted ? sacredText.languageDisplay : null,
    );

    return convertedModel;
  }

  /// Check if cache is still valid
  static bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clear search cache
  static void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cached results count
  static int getCachedResultsCount() {
    return _searchCache.length;
  }
}
