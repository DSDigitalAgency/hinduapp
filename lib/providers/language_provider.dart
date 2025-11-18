import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../services/data_preloader_service.dart';

/// Provider for current user language
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_defaultLanguage) {
    // Start initialization immediately but don't block
    _initLanguageImmediately();
  }

  static const String _defaultLanguage = 'Devanagari (Hindi)';
  bool _isInitialized = false;

  /// Initialize language immediately - first from cache, then from auth
  Future<void> _initLanguageImmediately() async {
    try {
      // CRITICAL: Refresh SharedPreferences cache to ensure we have latest data from disk
      await LocalStorageService.refreshPrefsCache();
      
      // CRITICAL FIX: Check and fix language inconsistencies first
      await LocalStorageService.checkAndFixLanguageConsistency();

      // First, try to get language from SharedPreferences
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
        
        // Always synchronize to ensure consistency - this ensures the flag is set
        // Only skip if this is truly first launch (no language selected flag)
        final isLanguageSelected = await LocalStorageService.isLanguageSelected();
        if (isLanguageSelected && fullLanguage != _defaultLanguage) {
          // Only sync if we have a non-default language and it was selected before
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
      // First check if language has been selected (first launch check)
      final isLanguageSelected = await LocalStorageService.isLanguageSelected();
      
      if (!isLanguageSelected) {
        // First launch - return default
        return _defaultLanguage;
      }
      
      // Language has been selected before, try to get it
      final languageName =
          await LocalStorageService.getUserPreferredLanguageName();
      
      // If we have a saved language, use it; otherwise keep default
      if (languageName != null && languageName.isNotEmpty) {
        return languageName;
      }
      
      // If language was selected before but not found, try to get from code
      final languageCode = await LocalStorageService.getUserPreferredLanguageCode();
      if (languageCode != null) {
        final languageNameFromCode = LocalStorageService.getLanguageNameFromCode(languageCode);
        if (languageNameFromCode != null && languageNameFromCode.isNotEmpty) {
          // Save it back to fix the issue
          await LocalStorageService.saveUserLanguagePreference(languageNameFromCode, languageCode);
          return languageNameFromCode;
        }
      }
      
      // Fallback to default only if truly no language found
      return _defaultLanguage;
    } catch (e) {
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
