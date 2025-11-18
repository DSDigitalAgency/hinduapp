import 'dart:async';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/language_conversion_service.dart';
import '../services/biography_service.dart';
import '../models/sacred_text_model.dart';
import '../models/temple_model.dart';
import '../models/biography_model.dart';

class DataPreloaderService {
  static const int _maxSacredTexts = 5;
  static const String _defaultLanguage = 'Devanagari (Hindi)';

  final ApiService _apiService = ApiService();
  final LanguageConversionService _languageConversionService =
      LanguageConversionService();
  final BiographyService _biographyService = BiographyService();

  // Singleton pattern
  static final DataPreloaderService _instance =
      DataPreloaderService._internal();
  factory DataPreloaderService() => _instance;
  DataPreloaderService._internal();

  // Cached data
  List<SacredTextModel>? _cachedSacredTexts;
  List<TempleModel>? _cachedTemples;
  List<BiographyModel>? _cachedBiographies;
  String? _cachedUserLanguage;

  // Loading states
  bool _isPreloading = false;
  Completer<bool>? _preloadingCompleter;

  // Getters for cached data
  List<SacredTextModel>? get cachedSacredTexts => _cachedSacredTexts;
  List<TempleModel>? get cachedTemples => _cachedTemples;
  List<BiographyModel>? get cachedBiographies => _cachedBiographies;
  String? get cachedUserLanguage => _cachedUserLanguage;
  bool get isPreloading => _isPreloading;

  /// Preload all data in parallel for faster home screen loading
  Future<bool> preloadAllData({bool forceRefresh = false}) async {
    if (_isPreloading) {
      // If already preloading, wait for completion
      return await _preloadingCompleter!.future;
    }

    _isPreloading = true;
    _preloadingCompleter = Completer<bool>();

    try {
      // Always load user preferred language first to ensure consistency
      await _loadUserPreferredLanguage();
      

      // Check if language has changed and force refresh if needed
      if (!forceRefresh && await _hasLanguageChanged()) {
        forceRefresh = true;
        
      }

      // First, try to load from cache (unless forced refresh)
      if (!forceRefresh) {
        await _loadCachedDataFirst();

        // If we have recent cached data with matching language, return immediately
        if (_hasValidCachedData() && !await _hasLanguageChanged()) {
          _isPreloading = false;
          _preloadingCompleter!.complete(true);
          
          return true;
        }
      } else {
      }

      // Initialize empty lists if not already initialized
      _cachedSacredTexts ??= [];
      _cachedTemples ??= [];
      _cachedBiographies ??= [];

      // Preload all data in parallel for maximum speed
      
      final results = await Future.wait([
        _preloadSacredTexts(),
        _preloadTemples(), 
        _preloadBiographies(),
      ], eagerError: false);

      // Save to cache for future use
      await _saveToCache();

      _isPreloading = false;
      final success = results.any((result) => result == true);
      
      _preloadingCompleter!.complete(success);
      
      // Log detailed results
      
      
      return success;
    } catch (e) {
      
      _isPreloading = false;
      _preloadingCompleter!.complete(false);
      return false;
    }
  }

  /// Refresh data when language changes
  Future<bool> refreshForLanguageChange() async {
    // Clear current cache
    clearCache();

    // Preload with forced refresh
    return await preloadAllData(forceRefresh: true);
  }

  /// Ensure data is available - load from cache or fetch fresh data
  /// This method is safe to call even if preloading hasn't completed
  Future<bool> ensureDataAvailable() async {
    // If we already have cached data, return immediately
    if (_hasValidCachedData() && !await _hasLanguageChanged()) {
      return true;
    }

    // If preloading is in progress, wait for it
    if (_isPreloading) {
      return await _preloadingCompleter!.future;
    }

    // Otherwise, start preloading now
    return await preloadAllData();
  }

  /// Get sacred texts with fallback loading
  Future<List<SacredTextModel>> getSacredTextsWithFallback() async {
    if (_cachedSacredTexts != null && _cachedSacredTexts!.isNotEmpty) {
      return _cachedSacredTexts!;
    }

    // Try to load data if not available
    await ensureDataAvailable();
    return _cachedSacredTexts ?? [];
  }

  /// Get temples with fallback loading
  Future<List<TempleModel>> gettemplesWithFallback() async {
    if (_cachedTemples != null && _cachedTemples!.isNotEmpty) {
      return _cachedTemples!;
    }

    // Try to load data if not available
    await ensureDataAvailable();
    return _cachedTemples ?? [];
  }

  /// Get biographies with fallback loading
  Future<List<BiographyModel>> getBiographiesWithFallback() async {
    if (_cachedBiographies != null && _cachedBiographies!.isNotEmpty) {
      return _cachedBiographies!;
    }

    // Try to load data if not available
    await ensureDataAvailable();
    return _cachedBiographies ?? [];
  }

  /// Check if we have valid cached data (less than 1 hour old)
  bool _hasValidCachedData() {
    return _cachedSacredTexts != null &&
        _cachedTemples != null &&
        _cachedBiographies != null &&
        _cachedSacredTexts!.isNotEmpty &&
        _cachedTemples!.isNotEmpty &&
        _cachedBiographies!.isNotEmpty;
  }

  /// Check if the current language matches the cached language
  Future<bool> _hasLanguageChanged() async {
    try {
      final currentLanguage = await _getCurrentUserLanguage();
      return _cachedUserLanguage != currentLanguage;
    } catch (e) {
      return false;
    }
  }

  /// Get current user language from storage/auth - SINGLE SOURCE OF TRUTH
  Future<String> _getCurrentUserLanguage() async {
    try {
      // Use the same logic as LanguageProvider for consistency
      final languageName =
          await LocalStorageService.getUserLanguageNameQuickly();
      if (languageName != null && languageName.isNotEmpty) {
        
        return languageName;
      }

      // Fallback to full language preference check
      final fullLanguageName =
          await LocalStorageService.getUserPreferredLanguageName();
      return fullLanguageName ?? _defaultLanguage;
    } catch (e) {
      
      return _defaultLanguage;
    }
  }

  /// Load cached data first for instant display
  Future<void> _loadCachedDataFirst() async {
    try {
      final cachedData = await LocalStorageService.getCachedHomeData();

      if (cachedData != null) {
        if (cachedData['sacred_texts'] != null) {
          _cachedSacredTexts = (cachedData['sacred_texts'] as List)
              .map((item) => SacredTextModel.fromJson(item))
              .toList();
        }

        if (cachedData['temples'] != null) {
          _cachedTemples = (cachedData['temples'] as List)
              .map((item) => TempleModel.fromJson(item))
              .toList();
        }

        if (cachedData['biographies'] != null) {
          _cachedBiographies = (cachedData['biographies'] as List)
              .map((item) => BiographyModel.fromJson(item))
              .toList();
        }

        if (cachedData['user_language'] != null) {
          _cachedUserLanguage = cachedData['user_language'];
        }

        // Check if cache is still fresh (less than 1 hour)
        final cachedAt = DateTime.tryParse(cachedData['cached_at'] ?? '');
        if (cachedAt != null) {
          final now = DateTime.now();
          final difference = now.difference(cachedAt);

          if (difference.inHours < 1 && _hasValidCachedData()) {
            // Cache is fresh, no need to reload
            return;
          }
        }
      }
    } catch (e) {
      // Handle error silently - will use default language
    }
  }

  /// Load user preferred language
  Future<void> _loadUserPreferredLanguage() async {
    try {
      final languageName =
          await LocalStorageService.getUserPreferredLanguageName();
      _cachedUserLanguage = languageName ?? _defaultLanguage;
    } catch (e) {
      _cachedUserLanguage = _defaultLanguage;
    }
  }

  /// Force set the current language (for Riverpod integration)
  Future<void> setCurrentLanguage(String language) async {
    _cachedUserLanguage = language;

    // Also save to local storage to ensure consistency
    try {
      final languageCode = LocalStorageService.getLanguageCodeFromName(
        language,
      );
      await LocalStorageService.saveUserLanguagePreference(
        language,
        languageCode,
      );
    } catch (e) {
      // Handle error silently - will use default language
    }
  }

  /// Preload sacred texts
  Future<bool> _preloadSacredTexts() async {
    try {
      final userLanguage = _cachedUserLanguage ?? _defaultLanguage;
      if (_isNativeLanguage(userLanguage)) {
        return await _loadNativeLanguageSacredTexts(userLanguage);
      } else {
        return await _loadAndConvertSacredTexts(userLanguage);
      }
    } catch (e) {
      return false;
    }
  }

  /// Load native language sacred texts
  Future<bool> _loadNativeLanguageSacredTexts(String userLanguage) async {
    try {
      List<SacredTextModel> nativeSacredTexts = [];

      // Try bulk API first - USE RANDOM ENDPOINT for true randomness
      try {
        final languageCode = _getLanguageCode(userLanguage);
        final response = await _apiService.getRandomSacredTexts(
          count: _maxSacredTexts,
          language: languageCode,
        );

        List<Map<String, dynamic>> sacredTextsData = [];

        if (response.containsKey('results')) {
          sacredTextsData = ApiService.safeCastToList(response, 'results');
        } else if (response.containsKey('data')) {
          sacredTextsData = ApiService.safeCastToList(response, 'data');
        } else if (response is List) {
          sacredTextsData = (response as List)
              .map((item) => item is Map<String, dynamic> ? item : <String, dynamic>{})
              .toList();
        }

        // Shuffle the results to ensure randomness with multiple random seeds
        sacredTextsData.shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));
        sacredTextsData.shuffle(math.Random(DateTime.now().microsecondsSinceEpoch));

        for (final sacredTextData in sacredTextsData) {
          if (nativeSacredTexts.length >= _maxSacredTexts) break;
          try {
            final sacredText = SacredTextModel.fromJson(sacredTextData);
            if (sacredText.text != null && sacredText.text!.isNotEmpty) {
              // Ensure languageUsed is set correctly for native languages
              // Create a copy with correct language info to ensure it's not marked as converted
              final correctedSacredText = sacredText.copyWith(
                languageUsed: userLanguage,
                isConverted: false, // Native languages are never converted
              );
              nativeSacredTexts.add(correctedSacredText);
            }
          } catch (e) {
            // Skip invalid data
          }
        }
      } catch (e) {
        // Fallback to individual calls if bulk fails
      }

      // If bulk loading didn't get enough, try individual calls
      if (nativeSacredTexts.length < _maxSacredTexts) {
        final futures = <Future<SacredTextModel?>>[];

        for (int i = 0; i < _maxSacredTexts; i++) {
          futures.add(_fetchSingleSacredText());
        }

        final results = await Future.wait(futures, eagerError: false);

        for (final sacredText in results) {
          if (sacredText != null &&
              nativeSacredTexts.length < _maxSacredTexts) {
            bool isDuplicate = nativeSacredTexts.any(
              (existing) => existing.title == sacredText.title,
            );
            if (!isDuplicate) {
              // Ensure languageUsed is set correctly for native languages
              final correctedSacredText = sacredText.copyWith(
                languageUsed: userLanguage,
                isConverted: false, // Native languages are never converted
              );
              nativeSacredTexts.add(correctedSacredText);
            }
          }
        }
      }

      _cachedSacredTexts = nativeSacredTexts;
      
      return nativeSacredTexts.isNotEmpty;
    } catch (e) {
      
      _cachedSacredTexts = []; // Ensure we have an empty list rather than null
      return false;
    }
  }

  /// Load and convert sacred texts for non-native languages
  Future<bool> _loadAndConvertSacredTexts(String userLanguage) async {
    try {
      List<SacredTextModel> rawTexts = [];

      // Try bulk API first - using proper random endpoint
      try {
        // Get the appropriate language code for the API
        final apiLanguageCode = _getApiLanguageCode(userLanguage);
        final response = await _apiService.getRandomSacredTexts(
          count: _maxSacredTexts, 
          language: apiLanguageCode,
        );

        List<Map<String, dynamic>> sacredTextsData = [];

        if (response.containsKey('results')) {
          sacredTextsData = ApiService.safeCastToList(response, 'results');
        } else if (response.containsKey('data')) {
          sacredTextsData = ApiService.safeCastToList(response, 'data');
        } else if (response is List) {
          sacredTextsData = (response as List)
              .map((item) => item is Map<String, dynamic> ? item : <String, dynamic>{})
              .toList();
        }

        // Shuffle the results to ensure randomness with multiple random seeds
        sacredTextsData.shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));
        sacredTextsData.shuffle(math.Random(DateTime.now().microsecondsSinceEpoch));
        
        for (final sacredTextData in sacredTextsData) {
          if (rawTexts.length >= _maxSacredTexts) break;
          try {
            final sacredText = SacredTextModel.fromJson(sacredTextData);
            if (sacredText.text != null && sacredText.text!.isNotEmpty) {
              rawTexts.add(sacredText);
            }
          } catch (e) {
            // Skip invalid data
          }
        }
      } catch (e) {
        // Fallback to individual calls
      }

      // If bulk loading didn't get enough, use parallel individual calls
      if (rawTexts.length < _maxSacredTexts) {
        final futures = <Future<SacredTextModel?>>[];

        for (int i = 0; i < _maxSacredTexts; i++) {
          futures.add(_fetchSingleSacredText());
        }

        final results = await Future.wait(futures, eagerError: false);

        for (final sacredText in results) {
          if (sacredText != null && rawTexts.length < _maxSacredTexts) {
            bool isDuplicate = rawTexts.any(
              (existing) => existing.title == sacredText.title,
            );
            if (!isDuplicate) {
              rawTexts.add(sacredText);
            }
          }
        }
      }

      if (rawTexts.isEmpty) {
        return false;
      }

      // Convert texts in parallel if needed
      final targetScript = LanguageConversionService.getAksharamukhaTarget(
        userLanguage,
      );
      if (targetScript != null) {
        try {
          
          final textsToConvert = rawTexts
              .map((t) => t.text ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          final excerptsToConvert = rawTexts
              .map((t) => t.excerpt ?? t.text ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          final titlesToConvert = rawTexts
              .map((t) => t.title ?? t.text ?? '')
              .where((t) => t.isNotEmpty)
              .toList();


          // Use Devanagari as source for all non-native languages
          final sourceScript = 'Devanagari';
          
          // Convert all texts in parallel and capture results
          final conversionResults = await Future.wait([
            if (textsToConvert.isNotEmpty)
              _languageConversionService.convertTextsBatch(
                sourceTexts: textsToConvert,
                sourceScript: sourceScript,
                targetScript: targetScript,
              )
            else
              Future.value(<String>[]),
            if (excerptsToConvert.isNotEmpty)
              _languageConversionService.convertTextsBatch(
                sourceTexts: excerptsToConvert,
                sourceScript: sourceScript,
                targetScript: targetScript,
              )
            else
              Future.value(<String>[]),
            if (titlesToConvert.isNotEmpty)
              _languageConversionService.convertTextsBatch(
                sourceTexts: titlesToConvert,
                sourceScript: sourceScript,
                targetScript: targetScript,
              )
            else
              Future.value(<String>[]),
          ], eagerError: false);

          // Extract conversion results
          final convertedTexts = conversionResults.isNotEmpty
              ? conversionResults[0]
              : <String>[];
          final convertedExcerpts = conversionResults.length > 1
              ? conversionResults[1]
              : <String>[];
          final convertedTitles = conversionResults.length > 2
              ? conversionResults[2]
              : <String>[];

          

          // Create converted sacred text models
          final List<SacredTextModel> convertedSacredTexts = [];
          for (int i = 0; i < rawTexts.length; i++) {
            final originalText = rawTexts[i];

            String convertedContent = originalText.text ?? '';
            String convertedTitle = originalText.displayTitle;
            String convertedExcerpt = originalText.excerpt ?? '';

            // Map converted results back to the models, but validate they're not question marks
            bool textConverted = false;
            bool titleConverted = false;
            bool excerptConverted = false;
            
            if (i < convertedTexts.length && 
                convertedTexts[i].isNotEmpty && 
                !(convertedTexts[i].contains('?') && convertedTexts[i].replaceAll('?', '').isEmpty)) {
              convertedContent = convertedTexts[i];
              textConverted = true;
            }
            if (i < convertedTitles.length && 
                convertedTitles[i].isNotEmpty && 
                !(convertedTitles[i].contains('?') && convertedTitles[i].replaceAll('?', '').isEmpty)) {
              convertedTitle = convertedTitles[i];
              titleConverted = true;
            }
            if (i < convertedExcerpts.length && 
                convertedExcerpts[i].isNotEmpty && 
                !(convertedExcerpts[i].contains('?') && convertedExcerpts[i].replaceAll('?', '').isEmpty)) {
              convertedExcerpt = convertedExcerpts[i];
              excerptConverted = true;
            }
            
            // If API conversion failed (returned question marks), try fallback conversion
            if (!textConverted && originalText.text != null && originalText.text!.isNotEmpty) {
              try {
                final fallbackText = await _languageConversionService.convertSacredTextContent(
                  sacredTextId: originalText.sacredTextId ?? '',
                  userLanguage: userLanguage,
                  originalContent: originalText.text!,
                );
                if (fallbackText.isNotEmpty && fallbackText != originalText.text) {
                  convertedContent = fallbackText;
                  textConverted = true;
                }
              } catch (e) {
                // Fallback also failed, keep original
              }
            }
            
            if (!titleConverted && originalText.title != null && originalText.title!.isNotEmpty) {
              try {
                final fallbackTitle = await _languageConversionService.getConvertedTitleForSearch(
                  title: originalText.title!,
                  userLanguage: userLanguage,
                );
                if (fallbackTitle.isNotEmpty && fallbackTitle != originalText.title) {
                  convertedTitle = fallbackTitle;
                  titleConverted = true;
                }
              } catch (e) {
                // Fallback also failed, keep original
              }
            }

            // Note: Siddham conversion now uses proper Noto Sans Siddham font
            // No special fallback needed as we have proper font support

            // Determine if any conversion actually worked
            final wasActuallyConverted = textConverted || titleConverted || excerptConverted;
            
            final convertedModel = originalText.copyWith(
              text: convertedContent,
              title: convertedTitle,
              excerpt: convertedExcerpt,
              languageUsed: wasActuallyConverted ? userLanguage : originalText.languageUsed,
              isConverted: wasActuallyConverted,
              originalLanguage: wasActuallyConverted 
                  ? (originalText.languageUsed ?? 'Devanagari (Hindi)')
                  : null,
            );
            
            convertedSacredTexts.add(convertedModel);
          }

          _cachedSacredTexts = convertedSacredTexts;
        } catch (e) {
          // Continue without conversion if it fails
          
          _cachedSacredTexts = rawTexts
              .map((text) => text.copyWith(languageUsed: userLanguage))
              .toList();
        }
      } else {
        _cachedSacredTexts = rawTexts
            .map((text) => text.copyWith(languageUsed: userLanguage))
            .toList();
      }
      return true;
    } catch (e) {
      
      return false;
    }
  }

  /// Fetch a single sacred text
  Future<SacredTextModel?> _fetchSingleSacredText() async {
    try {
      // Use the current user language instead of hardcoded 'hi'
      final languageCode = _getApiLanguageCode(_cachedUserLanguage ?? _defaultLanguage);
      final response = await _apiService.getRandomSacredText(language: languageCode);

      SacredTextModel? sacredText;

      if (response.containsKey('results') && response['results'] is List) {
        final results = response['results'] as List;
        if (results.isNotEmpty) {
          sacredText = SacredTextModel.fromJson(results.first);
        }
      } else if (response.containsKey('data') && response['data'] is List) {
        final data = response['data'] as List;
        if (data.isNotEmpty) {
          sacredText = SacredTextModel.fromJson(data.first);
        }
      } else {
        sacredText = SacredTextModel.fromJson(response);
      }

      if (sacredText != null &&
          sacredText.text != null &&
          sacredText.text!.isNotEmpty) {
        return sacredText;
      }
    } catch (e) {
      // Continue silently
    }
    return null;
  }

  /// Preload temples
  Future<bool> _preloadTemples() async {
    try {
      List<TempleModel> temples = [];

      // Try bulk API first
      try {
        final response = await _apiService.getRandomTemples(
          count: _maxSacredTexts,
        )
            ;

        List<Map<String, dynamic>> templesData = [];

        if (response.containsKey('temples')) {
          templesData = ApiService.safeCastToList(response, 'temples');
        } else if (response.containsKey('results')) {
          templesData = ApiService.safeCastToList(response, 'results');
        } else if (response.containsKey('data')) {
          templesData = ApiService.safeCastToList(response, 'data');
        } else if (response is List) {
          templesData = (response as List)
              .map(
                (item) =>
                    item is Map<String, dynamic> ? item : <String, dynamic>{},
              )
              .toList();
        }
        
        // Shuffle the results to ensure randomness with multiple random seeds
        templesData.shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));
        templesData.shuffle(math.Random(DateTime.now().microsecondsSinceEpoch));

        for (final templeData in templesData) {
          if (temples.length >= _maxSacredTexts) break;

          try {
            final temple = TempleModel.fromJson(templeData);
            if (temple.title != null && temple.title!.isNotEmpty) {
              temples.add(temple);
            }
          } catch (e) {
            // Skip invalid data
          }
        }
      } catch (e) {
        // Fallback to individual calls
      }

      // If bulk loading didn't get enough, use parallel individual calls
      if (temples.length < _maxSacredTexts) {
        final futures = <Future<TempleModel?>>[];

        for (int i = 0; i < _maxSacredTexts; i++) {
          futures.add(_fetchSingleTemple());
        }

        final results = await Future.wait(futures, eagerError: false);

        for (final temple in results) {
          if (temple != null && temples.length < _maxSacredTexts) {
            bool isDuplicate = temples.any(
              (existing) => existing.title == temple.title,
            );
            if (!isDuplicate) {
              temples.add(temple);
            }
          }
        }
      }

      _cachedTemples = temples;
      
      return temples.isNotEmpty;
    } catch (e) {
      
      _cachedTemples = []; // Ensure we have an empty list rather than null
      return false;
    }
  }

  /// Fetch a single temple
  Future<TempleModel?> _fetchSingleTemple() async {
    try {
      final response = await _apiService
          .getRandomTemples(count: 1)
          ;

      Map<String, dynamic>? templeData;

      if (response.containsKey('temples')) {
        final list = ApiService.safeCastToList(response, 'temples');
        if (list.isNotEmpty) templeData = list.first;
      } else if (response.containsKey('results')) {
        final list = ApiService.safeCastToList(response, 'results');
        if (list.isNotEmpty) templeData = list.first;
      } else if (response.containsKey('data')) {
        final list = ApiService.safeCastToList(response, 'data');
        if (list.isNotEmpty) templeData = list.first;
      } else if (response is List) {
        final list = (response as List)
            .map(
              (item) =>
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
            )
            .toList();
        if (list.isNotEmpty) templeData = list.first;
      } else if (response.containsKey('title') ||
          response.containsKey('name')) {
        templeData = response;
      }

      if (templeData != null) {
        try {
          final temple = TempleModel.fromJson(templeData);
          if (temple.title != null && temple.title!.isNotEmpty) {
            return temple;
          }
        } catch (e) {
          // Skip invalid data
        }
      }
    } catch (e) {
      // Continue silently
    }
    return null;
  }

  /// Preload biographies
  Future<bool> _preloadBiographies() async {
    try {
      List<BiographyModel> biographies = [];

      // Try bulk API first
      try {
        final apiBiographies = await _biographyService.getPopularBiographies(limit: _maxSacredTexts);
        
        if (apiBiographies.isNotEmpty) {
          _cachedBiographies = apiBiographies;
          return true;
        }
      } catch (e) {
        // Continue to individual calls
      }

      // If bulk loading didn't get enough, use parallel individual calls
      if (biographies.length < _maxSacredTexts) {
        final futures = <Future<BiographyModel?>>[];

        for (int i = 0; i < _maxSacredTexts; i++) {
          futures.add(_fetchSingleBiography());
        }

        final results = await Future.wait(futures, eagerError: false);

        for (final biography in results) {
          if (biography != null && biographies.length < _maxSacredTexts) {
            bool isDuplicate = biographies.any(
              (existing) =>
                  (existing.name == biography.name) ||
                  (existing.title == biography.title),
            );
            if (!isDuplicate) {
              biographies.add(biography);
            }
          }
        }
      }

      _cachedBiographies = biographies;
      
      return biographies.isNotEmpty;
    } catch (e) {
      
      _cachedBiographies = []; // Ensure we have an empty list rather than null
      return false;
    }
  }

  /// Fetch a single biography
  Future<BiographyModel?> _fetchSingleBiography() async {
    try {
      final biographies = await _biographyService.getPopularBiographies(limit: 1);
      if (biographies.isNotEmpty) {
        return biographies.first;
      }
    } catch (e) {
      // Continue silently
    }
    return null;
  }

  /// Save preloaded data to cache
  Future<void> _saveToCache() async {
    try {
      
      await LocalStorageService.cacheHomeData(
        sacredTexts: _cachedSacredTexts?.map((e) => e.toJson()).toList() ?? [],
        temples: _cachedTemples?.map((e) => e.toJson()).toList() ?? [],
        biographies: _cachedBiographies?.map((e) => e.toJson()).toList() ?? [],
        userLanguage: _cachedUserLanguage ?? _defaultLanguage,
      );
      
    } catch (e) {
      // Handle error silently - cache will be cleared
    }
  }

  /// Clear cached data
  void clearCache() {
    _cachedSacredTexts = null;
    _cachedTemples = null;
    _cachedBiographies = null;
    _cachedUserLanguage = null;
  }

  /// Global method to refresh data for language changes
  static Future<void> refreshGlobalForLanguageChange() async {
    final instance = DataPreloaderService();
    await instance.refreshForLanguageChange();
  }

  /// Check if language is native (doesn't need conversion)
  bool _isNativeLanguage(String language) {
    final nativeLanguages = [
      'English',
      'Roman itrans (English)',
      'itrans (English)',
      _defaultLanguage,
      'Devanagari',
      'Devanagari (Hindi)',
      'Tamil',
      'Telugu',
      'Malayalam',
      'Kannada',
    ];
    // Check exact match first
    if (nativeLanguages.contains(language)) {
      return true;
    }
    // Also check case-insensitive match
    final languageLower = language.toLowerCase();
    return nativeLanguages.any((native) => native.toLowerCase() == languageLower);
  }

  /// Get language code from language name
  String _getLanguageCode(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'english':
      case 'roman itrans (english)':
      case 'itrans (english)':
      case 'en':
        return 'en';
      case 'devanagari (hindi)':
      case 'hindi':
      case 'hi':
        return 'hi';
      case 'tamil':
      case 'ta':
        return 'ta';
      case 'telugu':
      case 'te':
        return 'te';
      case 'malayalam':
      case 'ml':
        return 'ml';
      case 'kannada':
      case 'kn':
        return 'kn';
      case 'imperial aramaic':
      case 'arc':
      case 'aramaic':
        return 'arc';
      case 'arabic':
      case 'ar':
        return 'ar';
      case 'urdu':
      case 'ur':
        return 'ur';
      case 'sanskrit':
      case 'sa':
        return 'sa';
      case 'marathi':
      case 'mr':
        return 'mr';
      case 'gujarati':
      case 'gu':
        return 'gu';
      case 'bengali':
      case 'bn':
      case 'bangla':
        return 'bn';
      case 'punjabi':
      case 'pa':
      case 'gurmukhi':
        return 'pa';
      case 'odia':
      case 'or':
      case 'oriya':
        return 'or';
      case 'assamese':
      case 'as':
        return 'as';
      default:
        return 'en';
    }
  }

  /// Get API language code for fetching data
  String _getApiLanguageCode(String userLanguage) {
    // For API calls, we need to map user languages to API-supported language codes
    switch (userLanguage.toLowerCase()) {
      case 'english':
      case 'roman itrans (english)':
      case 'itrans (english)':
      case 'en':
        return 'en';
      case 'devanagari (hindi)':
      case 'hindi':
      case 'hi':
        return 'hi';
      case 'tamil':
      case 'ta':
        return 'ta';
      case 'telugu':
      case 'te':
        return 'te';
      case 'malayalam':
      case 'ml':
        return 'ml';
      case 'kannada':
      case 'kn':
        return 'kn';
      case 'bengali':
      case 'bn':
      case 'bangla':
        return 'bn';
      case 'gujarati':
      case 'gu':
        return 'gu';
      case 'marathi':
      case 'mr':
        return 'mr';
      case 'punjabi':
      case 'pa':
      case 'gurmukhi':
        return 'pa';
      case 'odia':
      case 'or':
        return 'or';
      case 'assamese':
      case 'as':
        return 'as';
      case 'kashmiri':
      case 'ks':
        return 'ks';
      case 'konkani':
      case 'kok':
        return 'kok';
      case 'manipuri':
      case 'mni':
        return 'mni';
      case 'nepali':
      case 'ne':
        return 'ne';
      case 'sanskrit':
      case 'sa':
        return 'sa';
      case 'sindhi':
      case 'sd':
        return 'sd';
      case 'urdu':
      case 'ur':
        return 'ur';
      // For script conversions (Siddham, Pahlavi, etc.), fetch from Devanagari and convert
      case 'siddham':
      case 'pahlavi':
      case 'sogdian':
      case 'brahmi':
      case 'grantha':
      case 'imperial aramaic':
      case 'arc':
      case 'aramaic':
      case 'arabic':
      case 'ar':
        return 'hi'; // Fetch from Devanagari source and convert
      default:
        return 'hi'; // Default to Hindi/Devanagari
    }
  }
}
