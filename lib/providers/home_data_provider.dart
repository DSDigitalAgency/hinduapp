import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sacred_text_model.dart';
import '../models/temple_model.dart';
import '../models/biography_model.dart';
import '../services/data_preloader_service.dart';
import '../services/biography_service.dart';
import 'language_provider.dart';

/// State class for home data
class HomeDataState {
  final List<SacredTextModel> sacredTexts;
  final List<TempleModel> temples;
  final List<BiographyModel> biographies;
  final bool isLoading;
  final String? errorMessage;

  const HomeDataState({
    required this.sacredTexts,
    required this.temples,
    required this.biographies,
    required this.isLoading,
    this.errorMessage,
  });

  HomeDataState copyWith({
    List<SacredTextModel>? sacredTexts,
    List<TempleModel>? temples,
    List<BiographyModel>? biographies,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeDataState(
      sacredTexts: sacredTexts ?? this.sacredTexts,
      temples: temples ?? this.temples,
      biographies: biographies ?? this.biographies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get hasData =>
      sacredTexts.isNotEmpty || temples.isNotEmpty || biographies.isNotEmpty;

  bool get isEmpty =>
      sacredTexts.isEmpty && temples.isEmpty && biographies.isEmpty;
}

/// Notifier for managing home data
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  HomeDataNotifier(this.ref)
    : super(
        const HomeDataState(
          sacredTexts: [],
          temples: [],
          biographies: [],
          isLoading: true, // Start with loading true so UI shows skeletons
        ),
      ) {
    _init();
  }

  final Ref ref;
  final DataPreloaderService _dataPreloader = DataPreloaderService();
  final BiographyService _biographyService = BiographyService();
  String? _lastLanguage;

  /// Get biographies from API
  Future<List<BiographyModel>> _getBiographiesFromAPI() async {
    try {
      final biographies = await _biographyService.getPopularBiographies(
        limit: 5,
      );
      return biographies;
    } catch (e) {
      return [];
    }
  }

  /// Initialize and listen to language changes
  void _init() {
    // Listen to language changes
    ref.listen<String>(currentLanguageProvider, (previous, next) {
      if (previous != null && previous != next) {
        _refreshDataForLanguageChange(next);
      } else if (_lastLanguage == null) {
        // First time initialization
        _lastLanguage = next;
        // Always load initial data on first initialization
        Future.microtask(() => loadInitialData());
      }
    });
    
    // Also ensure we load data immediately if language is already available
    final currentLanguage = ref.read(currentLanguageProvider);
    if (_lastLanguage == null) {
      _lastLanguage = currentLanguage;
      Future.microtask(() => loadInitialData());
    }
  }

  /// Load initial data from cache or API
  Future<void> loadInitialData() async {
    // Don't return early - allow loading even if already loading to ensure data loads
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Ensure current language is set in DataPreloader
      final currentLanguage = ref.read(currentLanguageProvider);
      await _dataPreloader.setCurrentLanguage(currentLanguage);

      // Always load fresh data for home screen to ensure random content
      await _preloadFreshData();

    } catch (e) {
      
      // Even on error, try to get biographies from API
      final apiBiographies = await _getBiographiesFromAPI();
      state = state.copyWith(
        biographies: apiBiographies,
        isLoading: false,
        errorMessage: 'Failed to load data: $e',
      );
    }
  }

  /// Preload fresh data
  Future<void> _preloadFreshData() async {
    try {
      
      // Clear cache to ensure fresh data
      _dataPreloader.clearCache();
      
      // Ensure DataPreloader has the current language before loading
      final currentLanguage = ref.read(currentLanguageProvider);
      await _dataPreloader.setCurrentLanguage(currentLanguage);
      
      // Always force refresh for initial load to ensure we get data
      final success = await _dataPreloader.preloadAllData(forceRefresh: true);
      final apiBiographies = await _getBiographiesFromAPI();

      if (success) {
        final freshSacredTexts = _dataPreloader.cachedSacredTexts ?? [];
        final freshTemples = _dataPreloader.cachedTemples ?? [];

        
        state = state.copyWith(
          sacredTexts: freshSacredTexts,
          temples: freshTemples,
          biographies: apiBiographies, // Use API biographies
          isLoading: false,
        );
      } else {
        
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load fresh data',
        );
      }
    } catch (e) {
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading data: $e',
      );
    }
  }

  /// Refresh data when language changes
  Future<void> _refreshDataForLanguageChange(String newLanguage) async {
    if (_lastLanguage == newLanguage) return;

    _lastLanguage = newLanguage;

    // Set loading state
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Clear cache and refresh with new language
      _dataPreloader.clearCache();
      
      // Force the DataPreloader to use the new language immediately
      await _dataPreloader.setCurrentLanguage(newLanguage);

      final success = await _dataPreloader.preloadAllData(forceRefresh: true);

      if (success) {
        final apiBiographies = await _getBiographiesFromAPI();
        final cachedSacredTexts = _dataPreloader.cachedSacredTexts ?? [];
        final cachedTemples = _dataPreloader.cachedTemples ?? [];
        
        state = state.copyWith(
          sacredTexts: cachedSacredTexts,
          temples: cachedTemples,
          biographies: apiBiographies, // Use API biographies
          isLoading: false,
        );
        
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to refresh data for new language',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error refreshing data: $e',
      );
    }
  }

  /// Manually refresh all data
  Future<void> refreshData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Ensure DataPreloader has the current language before refreshing
      final currentLanguage = ref.read(currentLanguageProvider);
      await _dataPreloader.setCurrentLanguage(currentLanguage);
      
      _dataPreloader.clearCache();
      final success = await _dataPreloader.preloadAllData(forceRefresh: true);

      if (success) {
        final apiBiographies = await _getBiographiesFromAPI();
        
        state = state.copyWith(
          sacredTexts: _dataPreloader.cachedSacredTexts ?? [],
          temples: _dataPreloader.cachedTemples ?? [],
          biographies: apiBiographies, // Use API biographies
          isLoading: false,
        );
        
      } else {
        
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to refresh data',
        );
      }
    } catch (e) {
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error refreshing data: $e',
      );
    }
  }
}

/// Provider for home data that automatically refreshes on language changes
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>(
  (ref) => HomeDataNotifier(ref),
);

/// Individual providers for each data type
final sacredTextsProvider = Provider<List<SacredTextModel>>((ref) {
  return ref.watch(homeDataProvider).sacredTexts;
});

final templesProvider = Provider<List<TempleModel>>((ref) {
  return ref.watch(homeDataProvider).temples;
});

final biographiesProvider = Provider<List<BiographyModel>>((ref) {
  return ref.watch(homeDataProvider).biographies;
});

final homeDataLoadingProvider = Provider<bool>((ref) {
  return ref.watch(homeDataProvider).isLoading;
});

final homeDataErrorProvider = Provider<String?>((ref) {
  return ref.watch(homeDataProvider).errorMessage;
});
