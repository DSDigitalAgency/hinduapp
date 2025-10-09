import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hindu_connect/services/logger_service.dart';
import '../../../models/sacred_text_model.dart';
import '../../../services/sacred_text_search_service.dart';
import '../../../services/data_preloader_service.dart';
import '../../../providers/language_provider.dart';
import '../models/search_state.dart';
import 'base_search_provider.dart';

class SacredTextsSearchNotifier extends BaseSearchNotifier<SacredTextModel> {
  SacredTextsSearchNotifier(this._ref) : super() {
    // Listen to language changes and refresh search if needed
    _ref.listen<String>(currentLanguageProvider, (previous, next) {
      if (previous != null && previous != next && mounted) {
        refreshForLanguageChange();
      }
    });
  }

  final Ref _ref;

  @override
  Future<SearchResult<SacredTextModel>> performSearch(
    String query,
    int page,
    int limit,
  ) async {
    final userLanguage = _ref.read(currentLanguageProvider);

    try {
      logger.debug('🔍 Sacred Texts Provider: Starting search for query: "$query", page: $page, language: $userLanguage');
      final response = await SacredTextSearchService.searchSacredTexts(
        query: query,
        userPreferredLanguage: userLanguage,
        sortBy: 'title',
        page: page,
        limit: limit,
      );

      final results = response['results'] as List<SacredTextModel>;
      final total = response['total'] as int;
      
      logger.debug('🔍 Sacred Texts Provider: Search completed - ${results.length} results, total: $total');

      return SearchResult(
        items: results,
        hasMore: results.length >= limit,
        total: total,
      );
    } catch (e) {
      logger.debug('🔍 Sacred Texts Provider: Search failed with error: $e');
      

      // Fallback: try to get cached data from DataPreloaderService when no search query
      if (query.isEmpty && page == 1) {
        try {
          final dataPreloader = DataPreloaderService();
          final cachedResults = await dataPreloader
              .getSacredTextsWithFallback();
          logger.debug(
            'Using cached sacred texts as fallback: ${cachedResults.length} items',
          );

          final paginatedResults = cachedResults
              .skip((page - 1) * limit)
              .take(limit)
              .toList();

          return SearchResult(
            items: paginatedResults,
            hasMore: cachedResults.length > page * limit,
            total: cachedResults.length,
          );
        } catch (fallbackError) {
          // Handle error silently - will use empty result
        }
      }

      return SearchResult(items: <SacredTextModel>[], hasMore: false, total: 0);
    }
  }

  @override
  String getDisplayTitle(SacredTextModel item) => item.displayTitle;

  @override
  String getContentPreview(SacredTextModel item) => item.contentPreview;
}

final sacredTextsSearchProvider =
    StateNotifierProvider<
      SacredTextsSearchNotifier,
      SearchState<SacredTextModel>
    >((ref) => SacredTextsSearchNotifier(ref));
