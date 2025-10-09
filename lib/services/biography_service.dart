import '../models/biography_model.dart';
import '../services/api_service.dart';

class BiographyService {
  final ApiService _apiService = ApiService();

  /// Get popular biographies (up to 5) - now using random endpoint for variety
  Future<List<BiographyModel>> getPopularBiographies({int limit = 5}) async {
    try {
      List<BiographyModel> biographies = [];
      
      // Since the API returns single biography, we need to make multiple calls
      // to get multiple random biographies
      final futures = <Future<BiographyModel?>>[];
      
      for (int i = 0; i < limit; i++) {
        futures.add(_getSingleRandomBiography());
      }
      
      final results = await Future.wait(futures, eagerError: false);
      
      for (final biography in results) {
        if (biography != null) {
          biographies.add(biography);
        }
      }
      
      // Remove duplicates based on ID
      final uniqueBiographies = <String, BiographyModel>{};
      for (final biography in biographies) {
        uniqueBiographies[biography.id] = biography;
      }
      
      final finalBiographies = uniqueBiographies.values.toList();
      
      return finalBiographies;
    } catch (e) {
      // If random endpoint fails, try the original popular endpoint as fallback
      try {
        final fallbackParams = {
          'limit': limit.toString(),
          'sort': 'popular',
        };
        
        final fallbackResponse = await _apiService.biographySearch(fallbackParams);

        if (fallbackResponse['biographies'] != null) {
          final biographiesList = fallbackResponse['biographies'] as List;
          final biographies = biographiesList
              .map(
                (json) => BiographyModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          return biographies;
        } else if (fallbackResponse['results'] != null) {
          final resultsList = fallbackResponse['results'] as List;
          final biographies = resultsList
              .map(
                (json) => BiographyModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          return biographies;
        }
      } catch (fallbackError) {
        // Continue to return empty list
      }

      return [];
    }
  }

  /// Get a single random biography
  Future<BiographyModel?> _getSingleRandomBiography() async {
    try {
      final response = await _apiService.getRandomBiographies(count: 1);

      if (response['biographies'] != null) {
        final biographiesList = response['biographies'] as List;
        if (biographiesList.isNotEmpty) {
          return BiographyModel.fromJson(biographiesList.first as Map<String, dynamic>);
        }
      } else if (response['results'] != null) {
        final resultsList = response['results'] as List;
        if (resultsList.isNotEmpty) {
          return BiographyModel.fromJson(resultsList.first as Map<String, dynamic>);
        }
      } else if (response['data'] != null) {
        final dataList = response['data'] as List;
        if (dataList.isNotEmpty) {
          return BiographyModel.fromJson(dataList.first as Map<String, dynamic>);
        }
      } else if (response is List && response.isNotEmpty) {
        return BiographyModel.fromJson((response as List).first as Map<String, dynamic>);
      } else if (response.containsKey('_id')) {
        // Handle single biography object response
        return BiographyModel.fromJson(response);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get a single biography by ID
  Future<BiographyModel?> getBiographyById(String biographyId) async {
    try {

      final response = await _apiService.makeRequest(
        'GET',
        '/biographies/$biographyId',
        timeout: const Duration(seconds: 10),
      );

      if (response['_id'] != null || response['id'] != null) {
        final biography = BiographyModel.fromJson(response);
        return biography;
      }

      return null;
    } catch (e) {
      
      return null;
    }
  }

  /// Search biographies with query parameters
  Future<List<BiographyModel>> searchBiographies({
    String? query,
    int limit = 10,
    int offset = 0,
    String? language,
  }) async {
    try {

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      if (language != null && language.isNotEmpty) {
        queryParams['language'] = language;
      }

      final response = await _apiService.makeRequest(
        'GET',
        '/biography-search',
        queryParams: queryParams,
        timeout: const Duration(seconds: 15),
      );

      if (response['biographies'] != null) {
        final biographiesList = response['biographies'] as List;
        final biographies = biographiesList
            .map(
              (json) => BiographyModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return biographies;
      } else if (response['results'] != null) {
        // Handle alternative response format
        final resultsList = response['results'] as List;
        final biographies = resultsList
            .map(
              (json) => BiographyModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return biographies;
      }

      
      return [];
    } catch (e) {
      
      return [];
    }
  }

  /// Get biography autocomplete suggestions
  Future<List<String>> getBiographyAutocomplete({
    required String query,
    int limit = 5,
  }) async {
    try {

      final response = await _apiService.makeRequest(
        'GET',
        '/biography-search/autocomplete',
        queryParams: {'q': query, 'limit': limit.toString()},
        timeout: const Duration(seconds: 5),
      );

      if (response['suggestions'] != null) {
        final suggestionsList = response['suggestions'] as List;
        final suggestions = suggestionsList
            .map((item) => item.toString())
            .toList();

        return suggestions;
      }

      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get random biographies
  Future<List<BiographyModel>> getRandomBiographies({int count = 5}) async {
    try {

      final response = await _apiService.makeRequest(
        'GET',
        '/biographies/random',
        queryParams: {'count': count.toString()},
        timeout: const Duration(seconds: 10),
      );

      if (response['biographies'] != null) {
        final biographiesList = response['biographies'] as List;
        final biographies = biographiesList
            .map(
              (json) => BiographyModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return biographies;
      } else if (response['results'] != null) {
        // Handle alternative response format
        final resultsList = response['results'] as List;
        final biographies = resultsList
            .map(
              (json) => BiographyModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return biographies;
      }

      
      return [];
    } catch (e) {
      
      return [];
    }
  }
}
