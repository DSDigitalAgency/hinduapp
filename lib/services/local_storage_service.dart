import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Added for Color

class LocalStorageService {
  static const String _cachedContentKey = 'cached_content';
  static const String _favoritesKey = 'favorites';
  static const String _recentlyViewedKey = 'recently_viewed';
  static const String _readingHistoryKey = 'reading_history';
  static const String _selectedLanguageKey = 'selected_language';
  static const String _selectedLanguageCodeKey = 'selected_language_code';
  static const String _userLanguageKey = 'user_language';
  static const String _userLanguageCodeKey = 'user_language_code';
  static const String _languageSelectedKey = 'language_selected';
  
  // Cache SharedPreferences instance for faster language access
  static SharedPreferences? _cachedPrefs;
  
  // Store pre-loaded language from main() for immediate access
  static String? _preloadedLanguage;
  
  /// Set pre-loaded language (called from main() before app starts)
  static void setPreloadedLanguage(String language) {
    _preloadedLanguage = language;
  }
  
  /// Get pre-loaded language (called by language provider)
  static String? getPreloadedLanguage() {
    return _preloadedLanguage;
  }

  /// Get SharedPreferences instance (cached for performance)
  static Future<SharedPreferences> _getPrefs() async {
    if (_cachedPrefs == null) {
      _cachedPrefs = await SharedPreferences.getInstance();
      // Always reload on first access to ensure we have latest data from disk
      await _cachedPrefs!.reload();
    }
    return _cachedPrefs!;
  }
  
  /// Force refresh SharedPreferences cache (useful after saves)
  static Future<void> refreshPrefsCache() async {
    _cachedPrefs = await SharedPreferences.getInstance();
    // Reload to ensure we have latest data from disk
    await _cachedPrefs!.reload();
  }

  /// Get user language name quickly from cache if available
  static Future<String?> getUserLanguageNameQuickly() async {
    try {
      // Get a fresh instance to ensure we have latest data from disk
      final prefs = await SharedPreferences.getInstance();
      
      // CRITICAL: Reload preferences to ensure we have latest data from disk
      await prefs.reload();
      
      // Update cached instance
      _cachedPrefs = prefs;

      // First try user language (from Firestore/auth)
      String? userLanguage = prefs.getString(_userLanguageKey);
      String? selectedLanguage = prefs.getString(_selectedLanguageKey);

      // Fix legacy "English" to "Roman itrans (English)"
      if (userLanguage == 'English') {
        userLanguage = 'Roman itrans (English)';
        await prefs.setString(_userLanguageKey, userLanguage);
        await prefs.setString(_selectedLanguageKey, userLanguage);
        await prefs.setString(_selectedLanguageCodeKey, 'en');
        await prefs.reload();
      }
      if (selectedLanguage == 'English') {
        selectedLanguage = 'Roman itrans (English)';
        await prefs.setString(_selectedLanguageKey, selectedLanguage);
        await prefs.setString(_selectedLanguageCodeKey, 'en');
        await prefs.reload();
      }

      // If both exist and are different, there's a conflict - use user language (more authoritative)
      if (userLanguage != null && userLanguage.isNotEmpty) {
        if (selectedLanguage != userLanguage) {
          // Sync selected language to match user language
          final userLanguageCode = getLanguageCodeFromName(userLanguage);
          await prefs.setString(_selectedLanguageKey, userLanguage);
          await prefs.setString(_selectedLanguageCodeKey, userLanguageCode);
          await prefs.reload();
        }
        return userLanguage;
      }

      // Fallback to selected language (from language selection)
      if (selectedLanguage != null && selectedLanguage.isNotEmpty) {
        return selectedLanguage;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Synchronize all language preferences to a single value
  static Future<void> synchronizeLanguagePreferences(String language) async {
    try {
      final languageCode = getLanguageCodeFromName(language);
      
      // CRITICAL: Use a loop to ensure the save succeeds
      int attempts = 0;
      const maxAttempts = 3;
      bool saved = false;
      
      while (!saved && attempts < maxAttempts) {
        attempts++;
        
        // Get a fresh instance to ensure we're working with latest data
        final prefs = await SharedPreferences.getInstance();

        // Set both user and selected language to the same value
        final setUserLang = await prefs.setString(_userLanguageKey, language);
        final setUserCode = await prefs.setString(_userLanguageCodeKey, languageCode);
        final setSelectedLang = await prefs.setString(_selectedLanguageKey, language);
        final setSelectedCode = await prefs.setString(_selectedLanguageCodeKey, languageCode);
        final setFlag = await prefs.setBool(_languageSelectedKey, true);
        
        // Check if all sets succeeded
        if (setUserLang && setUserCode && setSelectedLang && setSelectedCode && setFlag) {
          // CRITICAL: Force reload to ensure data is written to disk
          await prefs.reload();
          
          // CRITICAL: Verify the save by reading back immediately
          await Future.delayed(const Duration(milliseconds: 100));
          
          final verifyPrefs = await SharedPreferences.getInstance();
          await verifyPrefs.reload();
          
          final savedUserLang = verifyPrefs.getString(_userLanguageKey);
          final savedSelectedLang = verifyPrefs.getString(_selectedLanguageKey);
          final savedFlag = verifyPrefs.getBool(_languageSelectedKey) ?? false;
          
          if (savedUserLang == language && savedSelectedLang == language && savedFlag) {
            // Success! Update cached instance
            _cachedPrefs = verifyPrefs;
            saved = true;
          } else {
            // Not saved correctly, wait a bit longer and retry
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } else {
          // Some sets failed, wait and retry
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      // If still not saved after max attempts, try one more time with a longer delay
      if (!saved) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userLanguageKey, language);
        await prefs.setString(_userLanguageCodeKey, languageCode);
        await prefs.setString(_selectedLanguageKey, language);
        await prefs.setString(_selectedLanguageCodeKey, languageCode);
        await prefs.setBool(_languageSelectedKey, true);
        await Future.delayed(const Duration(milliseconds: 300));
        await prefs.reload();
        _cachedPrefs = prefs;
      }
      
      // Verify synchronization
      await debugLanguagePreferences();
    } catch (e) {
      // Handle error silently - language preference will remain unchanged
    }
  }

  /// Debug: Print all language preferences to identify conflicts
  static Future<void> debugLanguagePreferences() async {
    try {
      
      
    } catch (e) {
      // Handle error silently - debug preferences will be skipped
    }
  }

  /// Check and fix any language inconsistencies
  static Future<void> checkAndFixLanguageConsistency() async {
    try {
      // Get a fresh instance to ensure we have latest data from disk
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      _cachedPrefs = prefs;

      String? userLanguage = prefs.getString(_userLanguageKey);
      String? selectedLanguage = prefs.getString(_selectedLanguageKey);
      final isLanguageSelected = prefs.getBool(_languageSelectedKey) ?? false;

      // Fix legacy "English" to "Roman itrans (English)"
      if (userLanguage == 'English') {
        userLanguage = 'Roman itrans (English)';
        await prefs.setString(_userLanguageKey, userLanguage);
      }
      if (selectedLanguage == 'English') {
        selectedLanguage = 'Roman itrans (English)';
        await prefs.setString(_selectedLanguageKey, selectedLanguage);
      }

      // If we have any language saved, ensure the flag is set
      if ((userLanguage != null && userLanguage.isNotEmpty) ||
          (selectedLanguage != null && selectedLanguage.isNotEmpty)) {
        if (!isLanguageSelected) {
          await prefs.setBool(_languageSelectedKey, true);
        }
      }

      // If we have userLanguage but no selectedLanguage (the current issue)
      if (userLanguage != null &&
          userLanguage.isNotEmpty &&
          (selectedLanguage == null || selectedLanguage.isEmpty)) {
        final userLanguageCode = getLanguageCodeFromName(userLanguage);
        await prefs.setString(_selectedLanguageKey, userLanguage);
        await prefs.setString(_selectedLanguageCodeKey, userLanguageCode);
        await prefs.setBool(_languageSelectedKey, true);
        await Future.delayed(const Duration(milliseconds: 100));
        await prefs.reload();
        _cachedPrefs = prefs;
      }
      // If we have selectedLanguage but no userLanguage
      else if (selectedLanguage != null &&
          selectedLanguage.isNotEmpty &&
          (userLanguage == null || userLanguage.isEmpty)) {
        final selectedLanguageCode = getLanguageCodeFromName(selectedLanguage);
        await prefs.setString(_userLanguageKey, selectedLanguage);
        await prefs.setString(_userLanguageCodeKey, selectedLanguageCode);
        await prefs.setBool(_languageSelectedKey, true);
        await Future.delayed(const Duration(milliseconds: 100));
        await prefs.reload();
        _cachedPrefs = prefs;
      }
      // If both exist but are different
      else if (userLanguage != null &&
          selectedLanguage != null &&
          userLanguage != selectedLanguage) {
        // Use userLanguage as the authoritative source (since it comes from Firestore)
        final userLanguageCode = getLanguageCodeFromName(userLanguage);
        await prefs.setString(_selectedLanguageKey, userLanguage);
        await prefs.setString(_selectedLanguageCodeKey, userLanguageCode);
        await prefs.setBool(_languageSelectedKey, true);
        await Future.delayed(const Duration(milliseconds: 100));
        await prefs.reload();
        _cachedPrefs = prefs;
      }
    } catch (e) {
      // Handle error silently - language consistency check will be skipped
    }
  }
  
  // Cache content locally for offline access
  static Future<void> cacheContent(Map<String, dynamic> content) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = await getCachedContent();
    
    final contentId = content['id']?.toString() ?? content['title']?.toString() ?? '';
    if (contentId.isNotEmpty) {
      cached[contentId] = {
        ...content,
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_cachedContentKey, jsonEncode(cached));
    }
  }
  
  // Get cached content
  static Future<Map<String, dynamic>> getCachedContent() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cachedContentKey);
    
    if (cachedStr != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(cachedStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return {};
  }
  
  // Get specific cached content by ID
  static Future<Map<String, dynamic>?> getCachedContentById(String contentId) async {
    final cached = await getCachedContent();
    return cached[contentId];
  }
  
  // Add to favorites
  static Future<void> addToFavorites(Map<String, dynamic> content) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    final contentId = content['id']?.toString() ?? content['title']?.toString() ?? '';
    if (contentId.isNotEmpty && !favorites.any((fav) => _getContentId(fav) == contentId)) {
      favorites.add({
        ...content,
        'favorited_at': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
    }
  }
  
  // Remove from favorites
  static Future<void> removeFromFavorites(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    favorites.removeWhere((fav) => _getContentId(fav) == contentId);
    await prefs.setString(_favoritesKey, jsonEncode(favorites));
  }
  
  // Get favorites
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesStr = prefs.getString(_favoritesKey);
    
    if (favoritesStr != null) {
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(favoritesStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return [];
  }
  
  // Check if content is favorited
  static Future<bool> isFavorited(String contentId) async {
    final favorites = await getFavorites();
    return favorites.any((fav) => _getContentId(fav) == contentId);
  }

  // Post-specific favorites methods
  static const String _favoritePostsKey = 'favorite_posts';

  // Get favorite post IDs
  static Future<List<String>> getFavoritePosts() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesStr = prefs.getString(_favoritePostsKey);
    
    if (favoritesStr != null) {
      try {
        return List<String>.from(jsonDecode(favoritesStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return [];
  }

  // Set favorite post IDs
  static Future<void> setFavoritePosts(List<String> postIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritePostsKey, jsonEncode(postIds));
  }

  // Add post to favorites
  static Future<void> addPostToFavorites(String postId) async {
    final favorites = await getFavoritePosts();
    if (!favorites.contains(postId)) {
      favorites.add(postId);
      await setFavoritePosts(favorites);
    }
  }

  // Remove post from favorites
  static Future<void> removePostFromFavorites(String postId) async {
    final favorites = await getFavoritePosts();
    favorites.remove(postId);
    await setFavoritePosts(favorites);
  }

  // Check if post is favorited
  static Future<bool> isPostFavorited(String postId) async {
    final favorites = await getFavoritePosts();
    return favorites.contains(postId);
  }
  
  // Add to recently viewed
  static Future<void> addToRecentlyViewed(Map<String, dynamic> content) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = await getRecentlyViewed();
    
    final contentId = content['id']?.toString() ?? content['title']?.toString() ?? '';
    if (contentId.isNotEmpty) {
      // Remove if already exists to avoid duplicates
      recent.removeWhere((item) => _getContentId(item) == contentId);
      
      // Add to beginning of list
      recent.insert(0, {
        ...content,
        'viewed_at': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 20 items
      if (recent.length > 20) {
        recent.removeRange(20, recent.length);
      }
      
      await prefs.setString(_recentlyViewedKey, jsonEncode(recent));
    }
  }
  
  // Get recently viewed content
  static Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentStr = prefs.getString(_recentlyViewedKey);
    
    if (recentStr != null) {
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(recentStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return [];
  }
  
  // Add reading progress
  static Future<void> saveReadingProgress(String contentId, double scrollPosition, String currentSection) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getReadingHistory();
    
    history[contentId] = {
      'scroll_position': scrollPosition,
      'current_section': currentSection,
      'last_read': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_readingHistoryKey, jsonEncode(history));
  }
  
  // Get reading progress
  static Future<Map<String, dynamic>?> getReadingProgress(String contentId) async {
    final history = await getReadingHistory();
    return history[contentId];
  }
  
  // Get all reading history
  static Future<Map<String, dynamic>> getReadingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString(_readingHistoryKey);
    
    if (historyStr != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(historyStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return {};
  }

  // Get reading history as a list of items
  static Future<List<Map<String, dynamic>>> getReadingHistoryList() async {
    final history = await getReadingHistory();
    final List<Map<String, dynamic>> historyList = [];
    
    history.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        historyList.add(value);
      }
    });
    
    // Sort by last_read (most recent first)
    historyList.sort((a, b) {
      final aTime = a['last_read'];
      final bTime = b['last_read'];
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      final aDateTime = aTime is String ? DateTime.tryParse(aTime) : aTime;
      final bDateTime = bTime is String ? DateTime.tryParse(bTime) : bTime;
      
      if (aDateTime == null && bDateTime == null) return 0;
      if (aDateTime == null) return 1;
      if (bDateTime == null) return -1;
      
      return bDateTime.compareTo(aDateTime);
    });
    
    return historyList;
  }

  // Clear reading history
  static Future<void> clearReadingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readingHistoryKey);
  }
  
  // Clear cached content (for storage management)
  static Future<void> clearCachedContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedContentKey);
  }
  
  // Clear all user data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedContentKey);
    await prefs.remove(_favoritesKey);
    await prefs.remove(_recentlyViewedKey);
    await prefs.remove(_readingHistoryKey);
    await prefs.remove(_selectedLanguageKey);
    await prefs.remove(_selectedLanguageCodeKey);
    await prefs.remove(_userLanguageKey);
    await prefs.remove(_userLanguageCodeKey);
  }
  
  // Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    final cached = await getCachedContent();
    final favorites = await getFavorites();
    final recent = await getRecentlyViewed();
    final history = await getReadingHistory();
    
    return {
      'cached_items': cached.length,
      'favorites_count': favorites.length,
      'recent_items': recent.length,
      'reading_sessions': history.length,
    };
  }
  
  // Get user's preferred language
  static Future<String?> getUserPreferredLanguage() async {
    // Get a fresh instance to ensure we have latest data from disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _cachedPrefs = prefs;
    
    // First try to get from user profile (from Firestore)
    String? language = prefs.getString(_userLanguageKey);
    
    // Fix legacy "English" to "Roman itrans (English)"
    if (language == 'English') {
      language = 'Roman itrans (English)';
      await prefs.setString(_userLanguageKey, language);
      await prefs.setString(_selectedLanguageKey, language);
      await prefs.setString(_selectedLanguageCodeKey, 'en');
      await prefs.reload();
    }
    
    if (language != null && language.isNotEmpty) {
      return language;
    }
    
    // Fallback to selected language (from language selection screen)
    language = prefs.getString(_selectedLanguageKey);
    
    // Fix legacy "English" to "Roman itrans (English)"
    if (language == 'English') {
      language = 'Roman itrans (English)';
      await prefs.setString(_selectedLanguageKey, language);
      await prefs.setString(_selectedLanguageCodeKey, 'en');
      await prefs.reload();
    }
    
    if (language != null && language.isNotEmpty) {
      return language;
    }
    
    // Only return null if no language is set (don't default here - let caller decide)
    return null;
  }

  // Get user's preferred language code
  static Future<String?> getUserPreferredLanguageCode() async {
    // Get a fresh instance to ensure we have latest data from disk
    final prefs = await SharedPreferences.getInstance();
    
    // Reload to ensure we have latest data
    await prefs.reload();
    
    // Update cached instance
    _cachedPrefs = prefs;
    
    // First try to get from user profile (from Firestore)
    String? languageCode = prefs.getString(_userLanguageCodeKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      return languageCode;
    }
    
    // Fallback to selected language code (from language selection screen)
    languageCode = prefs.getString(_selectedLanguageCodeKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      return languageCode;
    }
    
    // Don't return a default - return null if no language code is set
    // This prevents overriding saved languages
    return null;
  }

  // Get both language and language code
  static Future<Map<String, String?>> getUserLanguagePreferences() async {
    final language = await getUserPreferredLanguage();
    final languageCode = await getUserPreferredLanguageCode();
    
    return {
      'language': language,
      'languageCode': languageCode,
    };
  }

  // Save language preference from user profile
  static Future<void> saveUserLanguagePreference(String language, String languageCode) async {
    // Get a fresh instance to ensure we're working with latest data
    final prefs = await SharedPreferences.getInstance();
    
    // Save all language-related keys
    await prefs.setString(_userLanguageKey, language);
    await prefs.setString(_userLanguageCodeKey, languageCode);
    
    // CRITICAL FIX: Also sync selected language to prevent inconsistencies
    await prefs.setString(_selectedLanguageKey, language);
    await prefs.setString(_selectedLanguageCodeKey, languageCode);
    
    // Ensure language selected flag is set to true
    await prefs.setBool(_languageSelectedKey, true);
    
    // CRITICAL: Add delay to ensure write operations complete before app can be killed
    await Future.delayed(const Duration(milliseconds: 200));
    
    // CRITICAL: Force reload to ensure we have the latest data and it's written to disk
    await prefs.reload();
    
    // CRITICAL: Verify the save by reading back immediately
    final verifyPrefs = await SharedPreferences.getInstance();
    await verifyPrefs.reload();
    final savedLanguage = verifyPrefs.getString(_userLanguageKey);
    if (savedLanguage != language) {
      // If not saved correctly, try again
      await verifyPrefs.setString(_userLanguageKey, language);
      await verifyPrefs.setString(_userLanguageCodeKey, languageCode);
      await verifyPrefs.setString(_selectedLanguageKey, language);
      await verifyPrefs.setString(_selectedLanguageCodeKey, languageCode);
      await verifyPrefs.setBool(_languageSelectedKey, true);
      await Future.delayed(const Duration(milliseconds: 200));
      await verifyPrefs.reload();
    }
    
    // Update cached instance
    _cachedPrefs = verifyPrefs;
  }

  /// Check if language has been selected (first launch check)
  static Future<bool> isLanguageSelected() async {
    // Get a fresh instance to ensure we have latest data from disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _cachedPrefs = prefs;
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  /// Mark that language has been selected
  static Future<void> setLanguageSelected(bool value) async {
    // Get a fresh instance to ensure we're working with latest data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageSelectedKey, value);
    
    // CRITICAL: Add small delay to ensure write operations complete before app can be killed
    await Future.delayed(const Duration(milliseconds: 100));
    
    // CRITICAL: Force commit by reloading - this ensures data is written to disk
    await prefs.reload();
    // Update cached instance
    _cachedPrefs = prefs;
  }

  // Save language preference from language selection screen
  static Future<void> saveSelectedLanguagePreference(String language, String languageCode) async {
    // Get a fresh instance to ensure we're working with latest data
    final prefs = await SharedPreferences.getInstance();
    
    // Save all language-related keys
    await prefs.setString(_selectedLanguageKey, language);
    await prefs.setString(_selectedLanguageCodeKey, languageCode);
    
    // CRITICAL FIX: Also sync user language to prevent inconsistencies
    await prefs.setString(_userLanguageKey, language);
    await prefs.setString(_userLanguageCodeKey, languageCode);
    
    // Ensure language selected flag is set to true
    await prefs.setBool(_languageSelectedKey, true);
    
    // CRITICAL: Add delay to ensure write operations complete before app can be killed
    await Future.delayed(const Duration(milliseconds: 200));
    
    // CRITICAL: Force reload to ensure we have the latest data and it's written to disk
    await prefs.reload();
    
    // CRITICAL: Verify the save by reading back immediately
    final verifyPrefs = await SharedPreferences.getInstance();
    await verifyPrefs.reload();
    final savedLanguage = verifyPrefs.getString(_selectedLanguageKey);
    if (savedLanguage != language) {
      // If not saved correctly, try again
      await verifyPrefs.setString(_selectedLanguageKey, language);
      await verifyPrefs.setString(_selectedLanguageCodeKey, languageCode);
      await verifyPrefs.setString(_userLanguageKey, language);
      await verifyPrefs.setString(_userLanguageCodeKey, languageCode);
      await verifyPrefs.setBool(_languageSelectedKey, true);
      await Future.delayed(const Duration(milliseconds: 200));
      await verifyPrefs.reload();
    }
    
    // Update cached instance
    _cachedPrefs = verifyPrefs;
  }

  // Clear all language preferences
  static Future<void> clearLanguagePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLanguageKey);
    await prefs.remove(_selectedLanguageCodeKey);
    await prefs.remove(_userLanguageKey);
    await prefs.remove(_userLanguageCodeKey);
  }

  // Check if language preference is set
  static Future<bool> hasLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUserLanguage = prefs.getString(_userLanguageKey)?.isNotEmpty ?? false;
    final hasSelectedLanguage = prefs.getString(_selectedLanguageKey)?.isNotEmpty ?? false;
    return hasUserLanguage || hasSelectedLanguage;
  }
  
  // Language mapping between app codes and database language names
  static const Map<String, String> _languageCodeToName = {
    'as': 'Assamese',
    'bn': 'Bengali (Bangla)',
    'hi': 'Devanagari (Hindi)',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'or': 'Oriya (Odia)',
    'pa': 'Punjabi (Gurmukhi)',
    'en': 'Roman itrans (English)', // Fixed: Map 'en' to 'Roman itrans (English)' not 'English'
    'ta': 'Tamil',
    'te': 'Telugu',
    'ur': 'Urdu',
    'ar': 'Arabic',
    'ae': 'Avestan',
    'bhks': 'Bhaiksuki',
    'brah': 'Brahmi',
    'my': 'Burmese (Myanmar)',
    'ru': 'Cyrillic (Russian)',
    'gran': 'Grantha',
    'he': 'Hebrew',
    'he-arab': 'Hebrew (Judeo-Arabic)',
    'arc': 'Imperial Aramaic',
    'ja-hira': 'Japanese (Hiragana)',
    'ja-kata': 'Japanese (Katakana)',
    'jv': 'Javanese',
    'khar': 'Kharoshthi',
    'km': 'Khmer (Cambodian)',
    'lo': 'Lao',
    'mni': 'Meetei Mayek (Manipuri)',
    'mn': 'Mongolian',
    'new': 'Newa (Nepal Bhasa)',
    'peo': 'Old Persian',
    'sarb': 'Old South Arabian',
    'fa': 'Persian',
    'phn': 'Phoenician',
    'phlp': 'Psalter Pahlavi',
    'ranj': 'Ranjana (Lantsa)',
    'sam': 'Samaritan',
    'sat': 'Santali (Ol Chiki)',
    'shrd': 'Sharada',
    'sidd': 'Siddham',
    'si': 'Sinhala',
    'sog': 'Sogdian',
    'soyo': 'Soyombo',
    'syr-east': 'Syriac (Eastern)',
    'syr-estr': 'Syriac (Estrangela)',
    'syr-west': 'Syriac (Western)',
    'tamb': 'Tamil Brahmi',
    'dv': 'Thaana (Dhivehi)',
    'th': 'Thai',
    'bo': 'Tibetan',
  };

  // Convert language code to database language name
  static String? getLanguageNameFromCode(String? languageCode) {
    if (languageCode == null) return null;
    return _languageCodeToName[languageCode];
  }

  // Get user's preferred language name for database queries
  static Future<String?> getUserPreferredLanguageName() async {
    // First try to get the stored language name directly
    // Get a fresh instance to ensure we have latest data from disk
    final prefs = await SharedPreferences.getInstance();
    
    // Reload to ensure we have latest data
    await prefs.reload();
    
    // Update cached instance
    _cachedPrefs = prefs;
    
    String? language = prefs.getString(_userLanguageKey);
    
    // Fix legacy "English" to "Roman itrans (English)"
    if (language == 'English') {
      language = 'Roman itrans (English)';
      await prefs.setString(_userLanguageKey, language);
      await prefs.setString(_selectedLanguageKey, language);
      await prefs.setString(_selectedLanguageCodeKey, 'en');
      await prefs.reload();
      return language;
    }
    
    if (language != null && language.isNotEmpty) {
      return language;
    }
    
    // Fallback to selected language
    language = prefs.getString(_selectedLanguageKey);
    if (language == 'English') {
      language = 'Roman itrans (English)';
      await prefs.setString(_selectedLanguageKey, language);
      await prefs.setString(_selectedLanguageCodeKey, 'en');
      await prefs.reload();
      return language;
    }
    
    if (language != null && language.isNotEmpty) {
      return language;
    }
    
    // Last resort: get from code
    final languageCode = await getUserPreferredLanguageCode();
    if (languageCode != null) {
      final languageName = getLanguageNameFromCode(languageCode);
      
      // Fix if code returned "English" (shouldn't happen now, but just in case)
      if (languageName == 'English') {
        return 'Roman itrans (English)';
      }
      
      if (languageName != null && languageName.isNotEmpty) {
        return languageName;
      }
    }
    
    // Return null if no language found (don't default here)
    return null;
  }

  // Convert language name to API language code
  static String getLanguageCodeFromName(String? languageName) {
    if (languageName == null) return 'en';
    
    // Map language names to API language codes
    final languageNameToCode = {
      'Assamese': 'as',
      'Bengali (Bangla)': 'bn',
      'Devanagari (Hindi)': 'hi',
      'Gujarati': 'gu',
      'Kannada': 'kn',
      'Malayalam': 'ml',
      'Oriya (Odia)': 'or',
      'Punjabi (Gurmukhi)': 'pa',
      'English': 'en',
      'Roman itrans (English)': 'en',
      'Tamil': 'ta',
      'Telugu': 'te',
      'Urdu': 'ur',
      'Arabic': 'ar',
      'Avestan': 'ae',
      'Bhaiksuki': 'bhks',
      'Brahmi': 'brah',
      'Burmese (Myanmar)': 'my',
      'Cyrillic (Russian)': 'ru',
      'Grantha': 'gran',
      'Hebrew': 'he',
      'Hebrew (Judeo-Arabic)': 'he-arab',
      'Imperial Aramaic': 'arc',
      'Japanese (Hiragana)': 'ja-hira',
      'Japanese (Katakana)': 'ja-kata',
      'Javanese': 'jv',
      'Kharoshthi': 'khar',
      'Khmer (Cambodian)': 'km',
      'Lao': 'lo',
      'Meetei Mayek (Manipuri)': 'mni',
      'Mongolian': 'mn',
      'Newa (Nepal Bhasa)': 'new',
      'Old Persian': 'peo',
      'Old South Arabian': 'sarb',
      'Persian': 'fa',
      'Phoenician': 'phn',
      'Psalter Pahlavi': 'phlp',
      'Ranjana (Lantsa)': 'ranj',
      'Samaritan': 'sam',
      'Santali (Ol Chiki)': 'sat',
      'Sharada': 'shrd',
      'Siddham': 'sidd',
      'Sinhala': 'si',
      'Sogdian': 'sog',
      'Soyombo': 'soyo',
      'Syriac (Eastern)': 'syr-east',
      'Syriac (Estrangela)': 'syr-estr',
      'Syriac (Western)': 'syr-west',
      'Tamil Brahmi': 'tamb',
      'Thaana (Dhivehi)': 'dv',
      'Thai': 'th',
      'Tibetan': 'bo',
    };
    
    final languageCode = languageNameToCode[languageName];
    return languageCode ?? 'en'; // Default to English if not found
  }
  
  // Helper method to get content ID
  static String _getContentId(Map<String, dynamic> content) {
    return content['id']?.toString() ?? 
           content['templeId']?.toString() ?? 
           content['sacredTextId']?.toString() ?? 
           content['biographyId']?.toString() ?? 
           content['title']?.toString() ?? 
           '';
  }
  
  // ===== READING SETTINGS =====
  
  /// Save reading settings for a specific content type
  static Future<void> saveReadingSettings({
    required String contentType, // 'temple', 'sacred_text', 'biography', 'post'
    required double textSize,
    required Color backgroundColor,
    required double textSpacing,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reading_settings_$contentType';
    
    final settings = {
      'textSize': textSize,
      'backgroundColor': backgroundColor.toARGB32(), // Save as int
      'textSpacing': textSpacing,
      'savedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(key, jsonEncode(settings));
  }
  
  /// Save global reading settings (shared across all content types)
  static Future<void> saveGlobalReadingSettings({
    required double textSize,
    required Color backgroundColor,
    required double textSpacing,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'global_reading_settings';
    
    final settings = {
      'textSize': textSize,
      'backgroundColor': backgroundColor.toARGB32(), // Save as int
      'textSpacing': textSpacing,
      'savedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(key, jsonEncode(settings));
  }
  
  /// Load reading settings for a specific content type
  static Future<Map<String, dynamic>?> loadReadingSettings(String contentType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reading_settings_$contentType';
    
    final settingsStr = prefs.getString(key);
    if (settingsStr != null) {
      try {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsStr));
        
        // Convert backgroundColor back to Color object
        if (settings['backgroundColor'] != null) {
          settings['backgroundColor'] = Color(settings['backgroundColor'] as int);
        }
        
        return settings;
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return null;
  }
  
  /// Load global reading settings (shared across all content types)
  static Future<Map<String, dynamic>?> loadGlobalReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'global_reading_settings';
    
    final settingsStr = prefs.getString(key);
    
    if (settingsStr != null) {
      try {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsStr));
        
        // Convert backgroundColor back to Color object
        if (settings['backgroundColor'] != null) {
          settings['backgroundColor'] = Color(settings['backgroundColor'] as int);
        }
        
        return settings;
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return null;
  }
  
  /// Get default reading settings
  static Map<String, dynamic> getDefaultReadingSettings() {
    return {
      'textSize': 16.0,
      'backgroundColor': const Color(0xFFFFFFFF), // Light color (white)
      'textSpacing': 1.6,
    };
  }
  
  /// Get effective reading settings (global settings take precedence over content-specific)
  static Future<Map<String, dynamic>> getEffectiveReadingSettings(String contentType) async {
    // First try to get global settings
    final globalSettings = await loadGlobalReadingSettings();
    if (globalSettings != null) {
      return globalSettings;
    }
    
    // Fallback to content-specific settings
    final contentSettings = await loadReadingSettings(contentType);
    if (contentSettings != null) {
      return contentSettings;
    }
    
    // Finally fallback to default settings
    return getDefaultReadingSettings();
  }

  // Cache home screen data
  static Future<void> cacheHomeData({
    required List<Map<String, dynamic>> sacredTexts,
    required List<Map<String, dynamic>> temples,
    required List<Map<String, dynamic>> biographies,
    required String userLanguage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final homeData = {
      'sacred_texts': sacredTexts,
      'temples': temples,
      'biographies': biographies,
      'user_language': userLanguage,
      'cached_at': DateTime.now().toIso8601String(),
      'cache_version': '1.0', // For future cache format updates
    };
    
    await prefs.setString('home_data', jsonEncode(homeData));
  }
  
  // Get cached home data
  static Future<Map<String, dynamic>?> getCachedHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final homeDataStr = prefs.getString('home_data');
    
    if (homeDataStr != null) {
      try {
        final homeData = Map<String, dynamic>.from(jsonDecode(homeDataStr));
        
        // Check if cache is still valid (24 hours)
        final cachedAt = DateTime.tryParse(homeData['cached_at'] ?? '');
        if (cachedAt != null) {
          final now = DateTime.now();
          final difference = now.difference(cachedAt);
          
          // Cache is valid for 24 hours
          if (difference.inHours < 24) {
            return homeData;
          }
        }
        
        // Cache expired, remove it
        await prefs.remove('home_data');
      } catch (e) {
        // Handle parsing error silently
        await prefs.remove('home_data');
      }
    }
    
    return null;
  }
  
  // Clear home data cache
  static Future<void> clearHomeDataCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('home_data');
  }
  
  // Check if home data cache exists and is valid
  static Future<bool> hasValidHomeDataCache() async {
    final homeData = await getCachedHomeData();
    return homeData != null;
  }
} 