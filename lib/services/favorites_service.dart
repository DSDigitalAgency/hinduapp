import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  // Get current user email for debugging
  String? get currentUserEmail => _auth.currentUser?.email;

  // Add item to favorites
  Future<void> addToFavorites({
    required String itemId,
    required String itemType, // 'biography', 'temple', 'stotra', 'video', 'post'
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(itemId)
          .set({
        'itemId': itemId,
        'itemType': itemType,
        'title': title,
        'description': description ?? '',
        'imageUrl': imageUrl ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove item from favorites
  Future<void> removeFromFavorites(String itemId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(itemId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Check if item is favorited
  Future<bool> isFavorited(String itemId) async {
    if (currentUserId == null) {
      return false;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(itemId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all favorites
  Stream<QuerySnapshot> getFavorites() {
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Get favorites by type
  Stream<QuerySnapshot> getFavoritesByType(String itemType) {
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .where('itemType', isEqualTo: itemType)
        // Temporarily removed orderBy to fix index error
        // .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Toggle favorite status
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
} 