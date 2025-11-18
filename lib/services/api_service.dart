import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.hinduconnect.app';
  static const String apiPrefix = '/api/v1';

  // Get headers without auth token
  Future<Map<String, String>> getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    // No authentication tokens - app works without authentication
    return headers;
  }
  
  // Generic API request method with enhanced authentication
  Future<Map<String, dynamic>> makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool retryOnAuthFailure = true,
    String? baseUrl,
    bool log = true,
    Duration? timeout,
  }) async {
    final requestBaseUrl = baseUrl ?? ApiService.baseUrl;
    final requestApiPrefix = baseUrl != null ? '' : ApiService.apiPrefix;
    final uri = Uri.parse('$requestBaseUrl$requestApiPrefix$endpoint');
    final uriWithParams = queryParams != null 
        ? uri.replace(queryParameters: queryParams)
        : uri;
        

        
    final headers = await getHeaders();
    
      // Log request details for debugging
      if (log) {
        // Request logging can be added here if needed
      }
    
    http.Response response;
    
    try {
      // Use custom timeout or default based on method
      final requestTimeout = timeout ?? (method.toUpperCase() == 'GET' 
          ? const Duration(seconds: 30)   // Reasonable timeout for GET requests
          : const Duration(seconds: 30)); // Standard timeout for other methods
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uriWithParams, headers: headers)
              .timeout(requestTimeout);
          break;
        case 'POST':
          response = await http.post(
            uriWithParams,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'PUT':
          response = await http.put(
            uriWithParams,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'PATCH':
          response = await http.patch(
            uriWithParams,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'DELETE':
          response = await http.delete(uriWithParams, headers: headers)
              .timeout(requestTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      
      
    } catch (e) {
      throw Exception('Network error: $e');
    }
    
    // Handle authentication errors (no longer needed, but kept for API error handling)
    if (response.statusCode == 401 && retryOnAuthFailure) {
      // No authentication - just throw error
    }
    
    // Handle other error status codes
    if (response.statusCode >= 400) {

    }
    

    
    if (response.body.isEmpty) {

      return {'data': [], 'message': 'Empty response'};
    }
    
    dynamic responseData;
    try {
      responseData = jsonDecode(response.body);

    } catch (e) {

      throw Exception('Invalid JSON response: $e');
    }
    
    // Handle both array and object responses
    Map<String, dynamic> finalResponse;
    if (responseData is List) {
      // If response is an array, wrap it in a Map with 'results' key
      finalResponse = {'results': responseData};

    } else if (responseData is Map<String, dynamic>) {
      // If response is already a Map, use it as is
      finalResponse = responseData;

      // Normalize videos endpoint shape for faster client parsing
      if (endpoint.contains('/videos') && !finalResponse.containsKey('videos') && finalResponse.containsKey('results')) {
        finalResponse['videos'] = finalResponse['results'];
      }
    } else {

      throw Exception('Unexpected response format: ${responseData.runtimeType}');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {

      return finalResponse;
    } else {

      
      // Handle different error response formats
      String errorMessage = 'Unknown error occurred';
      if (finalResponse.containsKey('message')) {
        final message = finalResponse['message'];
        if (message is String) {
          errorMessage = message;
        } else if (message is List) {
          errorMessage = message.join(', ');
        }
      } else if (finalResponse.containsKey('error')) {
        errorMessage = finalResponse['error'].toString();
      }
      
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        data: finalResponse,
      );
    }
  }
  
  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await makeRequest('GET', '/health');
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // Search endpoints
  Future<Map<String, dynamic>> searchSacredTexts(Map<String, String> params) async {
    
    // Use longer timeout for search requests as they can take time
    final result = await makeRequest(
      'GET', 
      '/stotras/search', 
      queryParams: params,
      timeout: const Duration(seconds: 15), // Increased timeout for search
    );
    
    return result;
  }
  
  // Get Sacred Text by ID
  Future<Map<String, dynamic>> getSacredTextById(String id, {String? language}) async {
    final Map<String, String> queryParams = {};
    if (language != null && language.isNotEmpty) {
      queryParams['language'] = language;
    }
    return await makeRequest('GET', '/stotras/$id', queryParams: queryParams);
  }

  // Get random sacred text
  Future<Map<String, dynamic>> getRandomSacredText({String? language}) async {
    final Map<String, String> queryParams = {};
    if (language != null && language.isNotEmpty) {
      queryParams['language'] = language;
    }
    return await makeRequest('GET', '/stotras/random', queryParams: queryParams);
  }
  
  // Get multiple random sacred texts with language filtering
  Future<Map<String, dynamic>> getRandomSacredTexts({int count = 5, String? language}) async {
    final now = DateTime.now();
    final Map<String, String> queryParams = {
      'count': count.toString(),
      'random': 'true', // Ensure randomness
      'timestamp': now.millisecondsSinceEpoch.toString(), // Prevent caching
      'seed': now.microsecondsSinceEpoch.toString(), // Additional randomness seed
      'offset': (now.millisecondsSinceEpoch % 1000).toString(), // Random offset
      'request_id': '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}', // Unique request ID
    };
    if (language != null && language.isNotEmpty) {
      queryParams['language'] = language;
    }
    return await makeRequest('GET', '/stotras/random', queryParams: queryParams);
  }
  
  Future<Map<String, dynamic>> searchTemples(Map<String, String> params) async {
    return await makeRequest('GET', '/temples/search', queryParams: params);
  }
  
  Future<Map<String, dynamic>> searchPosts(Map<String, String> params) async {
    // Try the regular posts endpoint for search
    return await makeRequest('GET', '/blogs', queryParams: params);
  }

  Future<Map<String, dynamic>> getPosts(Map<String, String> params) async {
    return await makeRequest('GET', '/blogs', queryParams: params);
  }

  // Get all posts
  Future<Map<String, dynamic>> getAllPosts() async {
    return await makeRequest('GET', '/blogs');
  }

  // Get posts by category
  Future<Map<String, dynamic>> getPostsByCategory(String category, Map<String, String> params) async {
    return await makeRequest('GET', '/blogs/category/$category', queryParams: params);
  }
  
  // Get post by ID
  Future<Map<String, dynamic>> getPostById({required String postId}) async {
    return await makeRequest('GET', '/blogs/$postId');
  }
  
  // Biographies endpoints (fixed to use correct API prefix)
  Future<Map<String, dynamic>> biographySearch(Map<String, String> params) async {
    return await makeRequest('GET', '/biography-search', queryParams: params);
  }
  
  Future<Map<String, dynamic>> searchBiographies(Map<String, String> params) async {
    return await makeRequest('GET', '/biography-search', queryParams: params);
  }
    
  Future<Map<String, dynamic>> getBiographyByTitle(String title) async {
    return await makeRequest('GET', '/biographies/title/$title');
  }
  
  Future<Map<String, dynamic>> getBiographies(Map<String, String> params) async {
    return await makeRequest('GET', '/biographies', queryParams: params);
  }
  
  // Get biography by ID
  Future<Map<String, dynamic>> getBiographyById(String id) async {
    return await makeRequest('GET', '/biographies/$id');
  }

  Future<Map<String, dynamic>> getBiographiesAutocomplete(Map<String, String> params) async {
    return await makeRequest('GET', '/biography-search/autocomplete', queryParams: params);
  }
  
  Future<Map<String, dynamic>> getVideos(Map<String, String> params) async {
    final response = await makeRequest('GET', '/videos', queryParams: params);
    return response;
  }
  
  Future<Map<String, dynamic>> sharePost(String postId) async {
    return await makeRequest('POST', '/blogs/$postId/share');
  }
  
  Future<Map<String, dynamic>> viewPost(String postId) async {
    return await makeRequest('POST', '/blogs/$postId/view');
  }
  
  // Additional Sacred Texts endpoints
  Future<Map<String, dynamic>> getRecentSacredTexts(Map<String, String> params) async {
    return await makeRequest('GET', '/stotras/search/recent', queryParams: params);
  }
 
  // Get temple by title
  Future<Map<String, dynamic>> getTempleByTitle(String title) async {
    return await makeRequest('GET', '/temples/title/$title');
  }
  
  // Get temple by ID
  Future<Map<String, dynamic>> getTempleById(String id) async {
    return await makeRequest('GET', '/temples/$id');
  }
  
  // Get random temples
  Future<Map<String, dynamic>> getRandomTemples({int count = 5}) async {
    final now = DateTime.now();
    return await makeRequest('GET', '/temples/random', queryParams: {
      'count': count.toString(),
      'random': 'true', // Ensure randomness
      'timestamp': now.millisecondsSinceEpoch.toString(), // Prevent caching
      'seed': now.microsecondsSinceEpoch.toString(), // Additional randomness seed
      'offset': (now.millisecondsSinceEpoch % 1000).toString(), // Random offset
      'request_id': '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}', // Unique request ID
    });
  }
  
  // Get random biographies
  Future<Map<String, dynamic>> getRandomBiographies({int count = 5}) async {
    final now = DateTime.now();
    return await makeRequest('GET', '/biographies/random', queryParams: {
      'count': count.toString(),
      'random': 'true', // Ensure randomness
      'timestamp': now.millisecondsSinceEpoch.toString(), // Prevent caching
      'seed': now.microsecondsSinceEpoch.toString(), // Additional randomness seed
      'offset': (now.millisecondsSinceEpoch % 1000).toString(), // Random offset
      'request_id': '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}', // Unique request ID
    });
  }
  
  // Additional search endpoints
  Future<Map<String, dynamic>> getSearchAutocomplete(Map<String, String> params) async {
    return await makeRequest('GET', '/search/autocomplete', queryParams: params);
  }
  
  Future<Map<String, dynamic>> getSearchSuggestions(Map<String, String> params) async {
    return await makeRequest('GET', '/search/suggestions', queryParams: params);
  }
  
  // Content viewing operations
  Future<Map<String, dynamic>> markContentAsViewed(String contentId, String contentType) async {
    return await makeRequest('POST', '/content/view', body: {
      'content_id': contentId,
      'content_type': contentType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<Map<String, dynamic>> addToFavorites(String contentId, String contentType) async {
    return await makeRequest('POST', '/favorites', body: {
      'content_id': contentId,
      'content_type': contentType,
    });
  }
  
  Future<Map<String, dynamic>> removeFromFavorites(String contentId, String contentType) async {
    // Many servers ignore DELETE bodies; use query parameters instead
    return await makeRequest('DELETE', '/favorites', queryParams: {
      'content_id': contentId,
      'content_type': contentType,
    });
  }

  // Utility method to safely convert List<dynamic> to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> safeCastToList(Map<String, dynamic> response, String key) {
    final data = response[key];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          return <String, dynamic>{};
        }
      }).toList();
    }
    return [];
  }

  // Utility method to safely convert List<dynamic> to List<String>
  static List<String> safeCastToStringList(Map<String, dynamic> response, String key) {
    final data = response[key];
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    return [];
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic> data;
  
  ApiException({
    required this.statusCode,
    required this.message,
    required this.data,
  });
  
  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
} 