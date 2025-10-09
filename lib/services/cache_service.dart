import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Utility class to prevent excessive scroll events and improve performance
class ScrollUtils {
  static const int _defaultDebounceMs = 100;
  static const int _defaultThrottleMs = 50;
  
  /// Debounces scroll events to prevent excessive calls
  static void debounceScroll(Function callback, {int debounceMs = _defaultDebounceMs}) {
    // Implementation will be added in a separate utility file
  }
  
  /// Throttles scroll events to limit call frequency
  static void throttleScroll(Function callback, {int throttleMs = _defaultThrottleMs}) {
    // Implementation will be added in a separate utility file
  }
}

class CacheService {
  static const String _cachedSacredTextsKey = 'cached_sacred_texts';
  static const String _cachedTemplesKey = 'cached_temples';
  static const String _cachedBiographiesKey = 'cached_biographies';
  static const String _cacheTimestampKey = 'cache_timestamp';
  
  final ApiService _apiService = ApiService();
  
  // Cache Sacred Text data
  Future<void> cacheSacredText(String sacredTextId, Map<String, dynamic> sacredTextData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = await getCachedSacredTexts();
      
      cached[sacredTextId] = {
        ...sacredTextData,
        'cached_at': DateTime.now().toIso8601String(),
        'type': 'sacred_text',
      };
      
      await prefs.setString(_cachedSacredTextsKey, jsonEncode(cached));
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Cache Temple data
  Future<void> cacheTemple(String templeId, Map<String, dynamic> templeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = await getCachedTemples();
      
      cached[templeId] = {
        ...templeData,
        'cached_at': DateTime.now().toIso8601String(),
        'type': 'temple',
      };
      
      await prefs.setString(_cachedTemplesKey, jsonEncode(cached));
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Cache biography data
  Future<void> cacheBiography(String biographyTitle, Map<String, dynamic> biographyData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = await getCachedBiographies();
      
      cached[biographyTitle] = {
        ...biographyData,
        'cached_at': DateTime.now().toIso8601String(),
        'type': 'biography',
      };
      
      await prefs.setString(_cachedBiographiesKey, jsonEncode(cached));
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Get cached Sacred Texts
  Future<Map<String, dynamic>> getCachedSacredTexts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cachedSacredTextsKey);
    
    if (cachedStr != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(cachedStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return {};
  }
  
  // Get cached temples
  Future<Map<String, dynamic>> getCachedTemples() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cachedTemplesKey);
    
    if (cachedStr != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(cachedStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return {};
  }
  
  // Get cached biographies
  Future<Map<String, dynamic>> getCachedBiographies() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cachedBiographiesKey);
    
    if (cachedStr != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(cachedStr));
      } catch (e) {
        // Handle parsing error silently
      }
    }
    
    return {};
  }
  
  // Get cached Sacred Text by ID
  Future<Map<String, dynamic>?> getCachedSacredText(String sacredTextId) async {
    final cached = await getCachedSacredTexts();
    return cached[sacredTextId];
  }
  
  // Get cached temple by ID
  Future<Map<String, dynamic>?> getCachedTemple(String templeId) async {
    final cached = await getCachedTemples();
    return cached[templeId];
  }
  
  // Get cached biography by title
  Future<Map<String, dynamic>?> getCachedBiography(String biographyTitle) async {
    final cached = await getCachedBiographies();
    return cached[biographyTitle];
  }
  
  // Check if Sacred Text is cached
  Future<bool> isSacredTextCached(String sacredTextId) async {
    final cached = await getCachedSacredTexts();
    return cached.containsKey(sacredTextId);
  }
  
  // Check if temple is cached
  Future<bool> isTempleCached(String templeId) async {
    final cached = await getCachedTemples();
    return cached.containsKey(templeId);
  }
  
  // Check if biography is cached
  Future<bool> isBiographyCached(String biographyTitle) async {
    final cached = await getCachedBiographies();
    return cached.containsKey(biographyTitle);
  }
  
  // Get Sacred Text with caching (fetch from API if not cached)
  Future<Map<String, dynamic>> getSacredTextWithCache(String sacredTextId) async {
    // First check if it's cached
    final cached = await getCachedSacredText(sacredTextId);
    if (cached != null) {
      return cached;
    }
    
    // If not cached, fetch from API and cache it
    try {
      final sacredTextData = await _apiService.getSacredTextById(sacredTextId);
      await cacheSacredText(sacredTextId, sacredTextData);
      return sacredTextData;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get temple with caching (fetch from API if not cached)
  Future<Map<String, dynamic>> getTempleWithCache(String templeId) async {
    // First check if it's cached
    final cached = await getCachedTemple(templeId);
    if (cached != null) {
      return cached;
    }
    
    // If not cached, fetch from API and cache it
    try {
      final templeData = await _apiService.getTempleById(templeId);
      await cacheTemple(templeId, templeData);
      return templeData;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get biography with caching (fetch from API if not cached)
  Future<Map<String, dynamic>> getBiographyWithCache(String biographyTitle) async {
    // First check if it's cached
    final cached = await getCachedBiography(biographyTitle);
    if (cached != null) {
      return cached;
    }
    
    // If not cached, fetch from API and cache it
    try {
      final biographyData = await _apiService.getBiographyByTitle(biographyTitle);
      await cacheBiography(biographyTitle, biographyData);
      return biographyData;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get biography by ID with caching (fetch from API if not cached)
  Future<Map<String, dynamic>> getBiographyByIdWithCache(String biographyId) async {
    // First check if it's cached
    final cached = await getCachedBiography(biographyId);
    if (cached != null) {
      return cached;
    }
    
    // If not cached, fetch from API and cache it
    try {
      final biographyData = await _apiService.getBiographyById(biographyId);
      await cacheBiography(biographyId, biographyData);
      return biographyData;
    } catch (e) {
      rethrow;
    }
  }
  
  // Clear all cached content
  Future<void> clearAllCachedContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedSacredTextsKey);
    await prefs.remove(_cachedTemplesKey);
    await prefs.remove(_cachedBiographiesKey);
    await prefs.remove(_cacheTimestampKey);
  }
  
  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final sacredTexts = await getCachedSacredTexts();
    final temples = await getCachedTemples();
    final biographies = await getCachedBiographies();
    
    return {
      'cached_sacred_texts': sacredTexts.length,
      'cached_temples': temples.length,
      'cached_biographies': biographies.length,
      'total_cached_items': sacredTexts.length + temples.length + biographies.length,
    };
  }
  
  // Get cache size in bytes (approximate)
  Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final sacredTextsStr = prefs.getString(_cachedSacredTextsKey) ?? '';
    final templesStr = prefs.getString(_cachedTemplesKey) ?? '';
    final biographiesStr = prefs.getString(_cachedBiographiesKey) ?? '';
    
    return sacredTextsStr.length + templesStr.length + biographiesStr.length;
  }
  
  // Remove old cached items (older than specified days)
  Future<void> removeOldCachedItems(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    // Clean Sacred Texts
    final sacredTexts = await getCachedSacredTexts();
    final updatedSacredTexts = <String, dynamic>{};
    sacredTexts.forEach((key, value) {
      final cachedAt = value['cached_at'];
      if (cachedAt != null) {
        final cachedDate = DateTime.tryParse(cachedAt);
        if (cachedDate != null && cachedDate.isAfter(cutoffDate)) {
          updatedSacredTexts[key] = value;
        }
      }
    });
    
    // Clean temples
    final temples = await getCachedTemples();
    final updatedTemples = <String, dynamic>{};
    temples.forEach((key, value) {
      final cachedAt = value['cached_at'];
      if (cachedAt != null) {
        final cachedDate = DateTime.tryParse(cachedAt);
        if (cachedDate != null && cachedDate.isAfter(cutoffDate)) {
          updatedTemples[key] = value;
        }
      }
    });
    
    // Clean biographies
    final biographies = await getCachedBiographies();
    final updatedBiographies = <String, dynamic>{};
    biographies.forEach((key, value) {
      final cachedAt = value['cached_at'];
      if (cachedAt != null) {
        final cachedDate = DateTime.tryParse(cachedAt);
        if (cachedDate != null && cachedDate.isAfter(cutoffDate)) {
          updatedBiographies[key] = value;
        }
      }
    });
    
    // Save updated caches
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedSacredTextsKey, jsonEncode(updatedSacredTexts));
    await prefs.setString(_cachedTemplesKey, jsonEncode(updatedTemples));
    await prefs.setString(_cachedBiographiesKey, jsonEncode(updatedBiographies));
  }

  // Update access time methods
  Future<void> updateSacredTextAccessTime(String sacredTextId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSacredTexts = await getCachedSacredTexts();
    
    if (cachedSacredTexts.containsKey(sacredTextId)) {
      final sacredTextData = cachedSacredTexts[sacredTextId];
      if (sacredTextData is Map<String, dynamic>) {
        sacredTextData['cached_at'] = DateTime.now().toIso8601String();
        cachedSacredTexts[sacredTextId] = sacredTextData;
        await prefs.setString(_cachedSacredTextsKey, jsonEncode(cachedSacredTexts));
      }
    }
  }

  Future<void> updateTempleAccessTime(String templeId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTemples = await getCachedTemples();
    
    if (cachedTemples.containsKey(templeId)) {
      final templeData = cachedTemples[templeId];
      if (templeData is Map<String, dynamic>) {
        templeData['cached_at'] = DateTime.now().toIso8601String();
        cachedTemples[templeId] = templeData;
        await prefs.setString(_cachedTemplesKey, jsonEncode(cachedTemples));
      }
    }
  }

  Future<void> updateBiographyAccessTime(String biographyTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedBiographies = await getCachedBiographies();
    
    if (cachedBiographies.containsKey(biographyTitle)) {
      final biographyData = cachedBiographies[biographyTitle];
      if (biographyData is Map<String, dynamic>) {
        biographyData['cached_at'] = DateTime.now().toIso8601String();
        cachedBiographies[biographyTitle] = biographyData;
        await prefs.setString(_cachedBiographiesKey, jsonEncode(cachedBiographies));
      }
    }
  }
} 