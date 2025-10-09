import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hindu_connect/services/logger_service.dart';
import '../../../models/temple_model.dart';
import '../../../services/api_service.dart';
import '../../../services/data_preloader_service.dart';
import '../../../providers/language_provider.dart';
import '../models/search_state.dart';
import 'base_search_provider.dart';

class TemplesSearchNotifier extends BaseSearchNotifier<TempleModel> {
  TemplesSearchNotifier(this._ref) : super() {
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
  Future<SearchResult<TempleModel>> performSearch(
    String query,
    int page,
    int limit,
  ) async {
    List<TempleModel> temples = [];
    int totalCount = 0;

    try {
      // Main search API
      final response = await _apiService.searchTemples({
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
        'sortOrder': 'desc',
        'fuzzy': 'true',
        'sortBy': 'title',
      });

      final results = ApiService.safeCastToList(response, 'temples');
      // Extract total count from metadata or fallback to direct response fields
      final metadata = response['metadata'];
      if (metadata != null && metadata is Map<String, dynamic>) {
        totalCount =
            metadata['total'] ?? metadata['totalCount'] ?? results.length;
      } else {
        totalCount =
            response['total'] ?? response['totalCount'] ?? results.length;
      }

      logger.debug(
        'API returned ${results.length} temples (total: $totalCount) for query "$query" $response',
      );

      temples = results.map((json) => TempleModel.fromJson(json)).toList();

      
      // Sort by relevance
      temples.sort(
        (a, b) => _calculateRelevanceScore(
          b.displayTitle,
          query,
        ).compareTo(_calculateRelevanceScore(a.displayTitle, query)),
      );

      // Fallback searches if results are limited
      if (temples.length < 5) {
        temples.addAll(await _getAdditionalTemples(query, temples));
      }
    } catch (e) {
      

      // Fallback to individual temple search
      try {
        final response = await _apiService.getTempleByTitle(query);
        if (response['templeId'] != null) {
          temples = [TempleModel.fromJson(response)];
          totalCount = 1;
        }
      } catch (fallbackError) {
        

        // Final fallback: try to get cached data from DataPreloaderService when no search query
        if (query.isEmpty && page == 1) {
          try {
            final dataPreloader = DataPreloaderService();
            final cachedResults = await dataPreloader.gettemplesWithFallback();
            logger.debug(
              'Using cached temples as fallback: ${cachedResults.length} items',
            );

            temples = cachedResults.take(limit).toList();
            totalCount = cachedResults.length;
          } catch (dataFallbackError) {
            logger.debug(
              'Error in fallback temples loading: $dataFallbackError',
            );
            totalCount = temples.length;
          }
        }
      }
    }

    return SearchResult(
      items: temples,
      hasMore: temples.length >= limit && totalCount > (page * limit),
      total: totalCount,
    );
  }

  Future<List<TempleModel>> _getAdditionalTemples(
    String query,
    List<TempleModel> existing,
  ) async {
    try {
      final randomResponse = await _apiService.getRandomTemples(count: 50);
      final randomTemples = ApiService.safeCastToList(
        randomResponse,
        'temples',
      );

      if (randomTemples.isNotEmpty) {
        final additionalTemples = randomTemples
            .map((json) => TempleModel.fromJson(json))
            .where((temple) {
              final title = temple.displayTitle.toLowerCase();
              final queryLower = query.toLowerCase();
              return title.contains(queryLower) &&
                  !existing.any(
                    (t) =>
                        (t.templeId ?? t.displayTitle) ==
                        (temple.templeId ?? temple.displayTitle),
                  );
            })
            .toList();

        additionalTemples.sort(
          (a, b) => _calculateRelevanceScore(
            b.displayTitle,
            query,
          ).compareTo(_calculateRelevanceScore(a.displayTitle, query)),
        );

        return additionalTemples;
      }
    } catch (e) {
      // Ignore errors in additional search
    }
    return [];
  }

  int _calculateRelevanceScore(String title, String query) {
    if (query.isEmpty) return 0;

    final t = title.toLowerCase();
    final q = query.toLowerCase();
    final queryWords = q.split(' ').where((word) => word.isNotEmpty).toList();

    int score = 0;

    // Exact match
    if (t == q) score += 10000;

    // Starts with query
    if (t.startsWith(q)) score += 5000;

    // Ends with query
    if (t.endsWith(q)) score += 3000;

    // Word matches
    for (final word in queryWords) {
      if (word.length < 2) continue;

      if (t.startsWith(word)) {
        score += 2000;
      } else if (t.endsWith(word)) {
        score += 1500;
      } else if (RegExp(
        r'(?:^|\s|[-_.,:/()])' + RegExp.escape(word),
      ).hasMatch(t)) {
        score += 1000;
      } else if (t.contains(word)) {
        score += 200;
      }
    }

    // Deity-specific bonuses
    _addDeityBonus(q, t, score);

    // Shorter titles bonus
    score += (200 - title.length).clamp(0, 100);

    return score;
  }

  void _addDeityBonus(String query, String title, int score) {
    final deityBonuses = {
      'ganesh': ['ganesh', 'ganesha', 'vignesh', 'vigneshwara'],
      'hanuman': ['hanuman', 'hanumana'],
      'shiva': ['shiva', 'siva'],
    };

    deityBonuses.forEach((deity, variants) {
      if (query.contains(deity)) {
        if (variants.any((variant) => title.contains(variant))) {
          score += 2000;
          if ((title.contains('temple') ||
              title.contains('mandir') ||
              title.contains('ashram'))) {
            score += 200;
          }
        }
      }
    });
  }

  @override
  String getDisplayTitle(TempleModel item) => item.displayTitle;

  @override
  String getContentPreview(TempleModel item) => item.contentPreview;
}

final templesSearchProvider =
    StateNotifierProvider<TemplesSearchNotifier, SearchState<TempleModel>>(
      (ref) => TemplesSearchNotifier(ref),
    );
