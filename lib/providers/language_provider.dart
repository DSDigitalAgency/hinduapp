import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../services/data_preloader_service.dart';

/// Provider for current user language
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_defaultLanguage) {
    _initLanguageImmediately();
  }

  final AuthService _authService = AuthService();
  static const String _defaultLanguage = 'Devanagari (Hindi)';

  /// Initialize language immediately - first from cache, then from auth
  Future<void> _initLanguageImmediately() async {
    try {
      // Debug: Print all language preferences to identify conflicts
      await LocalStorageService.debugLanguagePreferences();

      // CRITICAL FIX: Check and fix language inconsistencies first
      await LocalStorageService.checkAndFixLanguageConsistency();

      // First, try to get language from SharedPreferences synchronously
      final cachedLanguage = await _getCachedLanguageQuickly();
      if (cachedLanguage != null && mounted) {
        state = cachedLanguage;

        // Synchronize all preferences to ensure consistency
        await LocalStorageService.synchronizeLanguagePreferences(
          cachedLanguage,
        );
      }

      // Then do a full language check (including auth)
      final fullLanguage = await getCurrentLanguage();
      if (mounted && state != fullLanguage) {
        state = fullLanguage;
        

        // Synchronize all preferences again if there was a change
        await LocalStorageService.synchronizeLanguagePreferences(fullLanguage);
      }
    } catch (e) {
      
      if (mounted) {
        state = _defaultLanguage;
        // Synchronize to default if all else fails
        await LocalStorageService.synchronizeLanguagePreferences(
          _defaultLanguage,
        );
      }
    }
  }

  /// Get language quickly from SharedPreferences only
  Future<String?> _getCachedLanguageQuickly() async {
    try {
      final languageName =
          await LocalStorageService.getUserLanguageNameQuickly();
      return languageName;
    } catch (e) {
      return null;
    }
  }

  /// Get current user language from storage/auth
  Future<String> getCurrentLanguage() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData?.language != null && userData!.language!.isNotEmpty) {
          return userData.language!;
        }
      }

      final languageName =
          await LocalStorageService.getUserPreferredLanguageName();
      return languageName ?? _defaultLanguage;
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

        // Refresh data preloader for new language
        final dataPreloader = DataPreloaderService();
        dataPreloader.refreshForLanguageChange();
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
