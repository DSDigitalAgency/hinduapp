import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHealthCheck {
  static const String baseUrl = 'https://api.hinduconnect.app';
  static const String apiPrefix = '/api/v1';
  
  static Future<bool> isApiAvailable() async {
    try {
      final uri = Uri.parse('$baseUrl$apiPrefix/health');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
  
  static Future<Map<String, dynamic>?> testEndpoint(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl$apiPrefix$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams)
          : uri;
      
      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 