import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class VideoCacheService {
  static const String _cacheKey = 'videos_cache';
  static const String _cacheTimestampKey = 'videos_cache_timestamp';
  static const String _filtersCacheKey = 'videos_filters_cache';
  static const Duration _cacheValidity = Duration(hours: 2); // Cache for 2 hours

  // Cache videos with filters
  static Future<void> cacheVideos(List<VideoModel> videos, Map<String, String> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert videos to JSON for storage
      final videosJson = videos.map((video) => video.toJson()).toList();
      
      // Store videos
      await prefs.setString(_cacheKey, jsonEncode(videosJson));
      
      // Store filters
      await prefs.setString(_filtersCacheKey, jsonEncode(filters));
      
      // Store timestamp
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail if caching fails

    }
  }

  // Get cached videos if they exist and are valid
  static Future<List<VideoModel>?> getCachedVideos(Map<String, String> currentFilters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists
      if (!prefs.containsKey(_cacheKey)) return null;
      
      // Check if cache is still valid
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheValidity) {
        // Cache expired, clear it
        await clearCache();
        return null;
      }
      
      // Check if filters match
      final cachedFiltersJson = prefs.getString(_filtersCacheKey);
      if (cachedFiltersJson != null) {
        final cachedFilters = Map<String, String>.from(jsonDecode(cachedFiltersJson));
        
        // Check if current filters match cached filters
        if (!_filtersMatch(cachedFilters, currentFilters)) {
          return null; // Filters don't match, don't use cache
        }
      }
      
      // Get cached videos
      final videosJson = prefs.getString(_cacheKey);
      if (videosJson == null) return null;
      
      final videosList = jsonDecode(videosJson) as List;
      return videosList.map((json) => VideoModel.fromJson(json)).toList();
    } catch (e) {
      // If there's any error, clear cache and return null
      await clearCache();
      return null;
    }
  }

  // Check if cached filters match current filters
  static bool _filtersMatch(Map<String, String> cached, Map<String, String> current) {
    // Only check important filters
    final importantKeys = ['language', 'category', 'language_code'];
    
    for (final key in importantKeys) {
      final cachedValue = cached[key];
      final currentValue = current[key];
      
      if (cachedValue != currentValue) {
        return false;
      }
    }
    
    return true;
  }

  // Clear the cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_filtersCacheKey);
    } catch (e) {
      // Silently fail if clearing fails

    }
  }

  // Check if cache is valid
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_cacheKey) || !prefs.containsKey(_cacheTimestampKey)) {
        return false;
      }
      
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime) <= _cacheValidity;
    } catch (e) {
      return false;
    }
  }

  // Get cache age
  static Future<Duration?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_cacheTimestampKey)) return null;
      
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime);
    } catch (e) {
      return null;
    }
  }
}
