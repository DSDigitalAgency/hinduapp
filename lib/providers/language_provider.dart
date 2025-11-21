import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import '../services/data_preloader_service.dart';

/// Provider for current user language
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_getPreloadedLanguage()) {
    // Start initialization immediately but don't block
    _initLanguageImmediately();
  }

  static const String _defaultLanguage = 'Devanagari (Hindi)';
  bool _isInitialized = false;
  
  /// Get pre-loaded language from main() if available
  static String _getPreloadedLanguage() {
    // Get pre-loaded language from LocalStorageService (set in main() before runApp())
    final preloaded = LocalStorageService.getPreloadedLanguage();
    return preloaded ?? _defaultLanguage;
  }

  /// Initialize language immediately - first from cache, then from auth
  Future<void> _initLanguageImmediately() async {
    try {
      // CRITICAL: Refresh SharedPreferences cache to ensure we have latest data from disk
      await LocalStorageService.refreshPrefsCache();
      
      // CRITICAL FIX: Check and fix language inconsistencies first
      await LocalStorageService.checkAndFixLanguageConsistency();

      // CRITICAL: First check if we have a pre-loaded language from main()
      // This ensures we use the language that was loaded before the app started
      final preloadedLanguage = LocalStorageService.getPreloadedLanguage();
      if (preloadedLanguage != null && preloadedLanguage.isNotEmpty) {
        if (mounted) {
          state = preloadedLanguage;
          // Ensure it's synchronized (already done in main(), but double-check)
          await LocalStorageService.synchronizeLanguagePreferences(preloadedLanguage);
          _isInitialized = true;
          return; // Early return - use pre-loaded language
        }
      }
      
      // Fallback: Try to get language from SharedPreferences (fastest path)
      final cachedLanguage = await _getCachedLanguageQuickly();
      if (cachedLanguage != null && cachedLanguage.isNotEmpty) {
        if (mounted) {
          state = cachedLanguage;
          // Always synchronize to ensure consistency, even if it's the default
          await LocalStorageService.synchronizeLanguagePreferences(cachedLanguage);
          _isInitialized = true;
          return; // Early return if we got a cached language
        }
      }

      // If no cached language, do a full language check
      final fullLanguage = await getCurrentLanguage();
      if (mounted) {
        // Always update state with the result, even if it's the default
        state = fullLanguage;
        
        // CRITICAL: Always synchronize if language was selected before, even if it's default
        // This ensures the flag and all language keys are properly set
        final isLanguageSelected = await LocalStorageService.isLanguageSelected();
        if (isLanguageSelected) {
          // Always sync to ensure consistency, even if it's the default language
          await LocalStorageService.synchronizeLanguagePreferences(fullLanguage);
        }
        _isInitialized = true;
      }
    } catch (e) {
      // On error, try to get language one more time before defaulting
      try {
        // Refresh cache again before retry
        await LocalStorageService.refreshPrefsCache();
        final fallbackLanguage = await getCurrentLanguage();
        if (mounted) {
          state = fallbackLanguage;
          _isInitialized = true;
        }
      } catch (_) {
        // Only set to default if everything fails
        if (mounted) {
          state = _defaultLanguage;
          _isInitialized = true;
        }
      }
    }
  }

  /// Get language quickly from SharedPreferences only
  Future<String?> _getCachedLanguageQuickly() async {
    try {
      // Try to get the language name first (fastest path)
      final languageName = await LocalStorageService.getUserLanguageNameQuickly();
      if (languageName != null && languageName.isNotEmpty) {
        return languageName;
      }
      
      // Check if language has been selected
      final isLanguageSelected = await LocalStorageService.isLanguageSelected();
      if (!isLanguageSelected) {
        return null; // First launch, no language saved yet
      }
      
      // If name not found but language was selected, try to get from code
      final languageCode = await LocalStorageService.getUserPreferredLanguageCode();
      if (languageCode != null) {
        final languageNameFromCode = LocalStorageService.getLanguageNameFromCode(languageCode);
        if (languageNameFromCode != null && languageNameFromCode.isNotEmpty) {
          // Save it back to fix the issue
          await LocalStorageService.saveUserLanguagePreference(languageNameFromCode, languageCode);
          return languageNameFromCode;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user language from storage
  Future<String> getCurrentLanguage() async {
    try {
      // CRITICAL: Refresh cache first to ensure we have latest data
      await LocalStorageService.refreshPrefsCache();
      
      // First check if language has been selected (first launch check)
      final isLanguageSelected = await LocalStorageService.isLanguageSelected();
      
      if (!isLanguageSelected) {
        // First launch - return default
        return _defaultLanguage;
      }
      
      // Language has been selected before, try to get it
      // Try multiple methods to get the language
      String? languageName = await LocalStorageService.getUserPreferredLanguageName();
      
      // If not found, try the quick method
      if (languageName == null || languageName.isEmpty) {
        languageName = await LocalStorageService.getUserLanguageNameQuickly();
      }
      
      // If we have a saved language, use it
      if (languageName != null && languageName.isNotEmpty) {
        return languageName;
      }
      
      // If language was selected before but not found, try to get from code
      final languageCode = await LocalStorageService.getUserPreferredLanguageCode();
      if (languageCode != null && languageCode.isNotEmpty) {
        final languageNameFromCode = LocalStorageService.getLanguageNameFromCode(languageCode);
        if (languageNameFromCode != null && languageNameFromCode.isNotEmpty) {
          // Save it back to fix the issue and ensure persistence
          await LocalStorageService.saveUserLanguagePreference(languageNameFromCode, languageCode);
          return languageNameFromCode;
        }
      }
      
      // CRITICAL: If language was selected but not found, this is a data corruption issue
      // Try to recover by checking all possible keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      // Check both keys directly
      final userLang = prefs.getString('user_language');
      final selectedLang = prefs.getString('selected_language');
      
      if (userLang != null && userLang.isNotEmpty) {
        // Found it! Save it properly
        final langCode = LocalStorageService.getLanguageCodeFromName(userLang);
        await LocalStorageService.saveUserLanguagePreference(userLang, langCode);
        return userLang;
      }
      
      if (selectedLang != null && selectedLang.isNotEmpty) {
        // Found it! Save it properly
        final langCode = LocalStorageService.getLanguageCodeFromName(selectedLang);
        await LocalStorageService.saveUserLanguagePreference(selectedLang, langCode);
        return selectedLang;
      }
      
      // Last resort: if flag is set but no language found, keep default but log the issue
      // This should not happen if saving worked correctly
      return _defaultLanguage;
    } catch (e) {
      // On error, return default
      return _defaultLanguage;
    }
  }

  /// Update language and notify listeners
  Future<void> updateLanguage(String newLanguage) async {
    if (state != newLanguage) {
      final oldLanguage = state;
      state = newLanguage;
      
      // Synchronize ALL language preferences to ensure consistency
      try {
        await LocalStorageService.synchronizeLanguagePreferences(newLanguage);

        // Refresh data preloader for new language (non-blocking)
        // The home_data_provider will also listen to language changes and refresh automatically
        // So we do this in the background without blocking
        final dataPreloader = DataPreloaderService();
        // Don't await - let it run in background to avoid blocking UI
        dataPreloader.refreshForLanguageChange().catchError((e) {
          // Silently handle errors in background refresh
        });
      } catch (e) {
        // Revert state if save failed
        state = oldLanguage;
      }
    } else {
    }
  }

  /// Force refresh current language from storage
  Future<void> forceRefreshLanguage() async {
    final currentLanguage = await getCurrentLanguage();
    if (mounted) {
      state = currentLanguage;
      
    }
  }

  /// Refresh language from storage (useful when language is changed externally)
  Future<void> refreshLanguage() async {
    final currentLanguage = await getCurrentLanguage();
    if (mounted && state != currentLanguage) {
      state = currentLanguage;
      
    }
  }
}

/// Provider instance for language
final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(),
);

/// Provider for watching language changes
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(languageProvider);
});
