import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';

  /// Get SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Add item to favorites
  Future<void> addToFavorites({
    required String itemId,
    required String itemType, // 'biography', 'temple', 'stotra', 'video', 'post'
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final prefs = await _getPrefs();
      final favorites = await getAllFavorites();
      
      // Check if already favorited
      if (favorites.any((fav) => fav['itemId'] == itemId)) {
        return; // Already favorited
      }

      // Add new favorite
      favorites.add({
        'itemId': itemId,
        'itemType': itemType,
        'title': title,
        'description': description ?? '',
        'imageUrl': imageUrl ?? '',
        'addedAt': DateTime.now().toIso8601String(),
      });

      // Save to SharedPreferences
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
      
      // Ensure data is persisted - reload to confirm save
      await prefs.reload();
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove item from favorites
  Future<void> removeFromFavorites(String itemId) async {
    try {
      final prefs = await _getPrefs();
      final favorites = await getAllFavorites();
      
      // Remove the favorite
      favorites.removeWhere((fav) => fav['itemId'] == itemId);

      // Save to SharedPreferences
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
      
      // Ensure data is persisted - reload to confirm save
      await prefs.reload();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Check if item is favorited
  Future<bool> isFavorited(String itemId) async {
    try {
      final favorites = await getAllFavorites();
      return favorites.any((fav) => fav['itemId'] == itemId);
    } catch (e) {
      return false;
    }
  }

  /// Get all favorites
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    try {
      final prefs = await _getPrefs();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList()
        ..sort((a, b) {
          // Sort by addedAt descending (newest first)
          final aDate = a['addedAt'] as String?;
          final bDate = b['addedAt'] as String?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });
    } catch (e) {
      return [];
    }
  }

  /// Get favorites by type
  Future<List<Map<String, dynamic>>> getFavoritesByType(String itemType) async {
    try {
      final favorites = await getAllFavorites();
      return favorites.where((fav) => fav['itemType'] == itemType).toList();
    } catch (e) {
      return [];
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite({
    required String itemId,
    required String itemType,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    final isFav = await isFavorited(itemId);
    
    if (isFav) {
      await removeFromFavorites(itemId);
    } else {
      await addToFavorites(
        itemId: itemId,
        itemType: itemType,
        title: title,
        description: description,
        imageUrl: imageUrl,
      );
    }
  }

  /// Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_favoritesKey);
    } catch (e) {
      throw Exception('Failed to clear favorites: $e');
    }
  }
}
