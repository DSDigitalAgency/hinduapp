import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hindu_connect/services/logger_service.dart';
import '../../../models/biography_model.dart';
import '../../../services/api_service.dart';
import '../../../services/data_preloader_service.dart';
import '../../../providers/language_provider.dart';
import '../models/search_state.dart';
import 'base_search_provider.dart';

class BiographiesSearchNotifier extends BaseSearchNotifier<BiographyModel> {
  BiographiesSearchNotifier(this._ref) : super() {
    // Listen to language changes and refresh search if needed
    _ref.listen<String>(currentLanguageProvider, (previous, next) {
      if (previous != null && previous != next && mounted) {
        refreshForLanguageChange();
      }
    });
  }

  final Ref _ref;

  final ApiService _apiService = ApiService();

  @override
  Future<SearchResult<BiographyModel>> performSearch(
    String query,
    int page,
    int limit,
  ) async {
    List<BiographyModel> biographies = [];

    try {
      // Try main search API first
      final response = await _apiService.searchBiographies({
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
        'sortOrder': 'desc',
        'fuzzy': 'false',
        'sortBy': 'relevance',
      });

      final results = ApiService.safeCastToList(response, 'biographies');
      biographies = results
          .map((json) => BiographyModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback to alternative search method
      try {
        final response = await _apiService.biographySearch({
          'q': query,
          'page': page.toString(),
          'limit': limit.toString(),
          'sortOrder': 'desc',
          'fuzzy': 'false',
          'sortBy': 'relevance',
        });

        final results = ApiService.safeCastToList(response, 'biographies');
        biographies = results
            .map((json) => BiographyModel.fromJson(json))
            .toList();
      } catch (fallbackError) {
        

        // Final fallback: try to get cached data from DataPreloaderService when no search query
        if (query.isEmpty && page == 1) {
          try {
            final dataPreloader = DataPreloaderService();
            final cachedResults = await dataPreloader
                .getBiographiesWithFallback();
            logger.debug(
              'Using cached biographies as fallback: ${cachedResults.length} items',
            );

            biographies = cachedResults.take(limit).toList();
          } catch (dataFallbackError) {
            // Handle error silently - will use empty list
          }
        }
      }
    }

    return SearchResult(
      items: biographies,
      hasMore: biographies.length >= limit,
      total: biographies.length,
    );
  }

  @override
  String getDisplayTitle(BiographyModel item) => item.displayTitle;

  @override
  String getContentPreview(BiographyModel item) => item.displayContent;
}

final biographiesSearchProvider =
    StateNotifierProvider<
      BiographiesSearchNotifier,
      SearchState<BiographyModel>
    >((ref) => BiographiesSearchNotifier(ref));
