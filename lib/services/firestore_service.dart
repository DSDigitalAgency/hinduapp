import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Create or update user in Firestore
  static Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
      
    } catch (e) {
      throw FirestoreException('Failed to save user: $e');
    }
  }

  // Get user from Firestore
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw FirestoreException('Failed to get user: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      // Add updated timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      // Use set() with merge: true instead of update() to handle cases where document doesn't exist
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(updates, SetOptions(merge: true));
      
    } catch (e) {
      throw FirestoreException('Failed to update profile: $e');
    }
  }

  // Create user from Firebase Auth User
  static Future<UserModel> createUserFromFirebaseUser(
    User firebaseUser, 
    String provider,
    {Map<String, dynamic>? additionalData}
  ) async {
    final now = DateTime.now();
    
    final user = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      createdAt: now,
      // Add any additional data
      phone: additionalData?['phone'],
      pincode: additionalData?['pincode'],
      city: additionalData?['city'],
      state: additionalData?['state'],
      language: additionalData?['language'],
      languageCode: additionalData?['languageCode'],
    );

    await createOrUpdateUser(user);
    return user;
  }

  // Complete user profile (called after profile setup)
  static Future<void> completeUserProfile(
    String uid, {
    required String name,
    required String phone,
    required String pincode,
    required String city,
    required String state,
    String? language,
    String? languageCode,
  }) async {
    try {
      final updates = {
        'name': name,
        'phone': phone,
        'pincode': pincode,
        'city': city,
        'state': state,
        'language': language,
        'languageCode': languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await updateUserProfile(uid, updates);
    } catch (e) {
      throw FirestoreException('Failed to complete profile: $e');
    }
  }

  // Update language preference
  static Future<void> updateLanguagePreference(
    String uid, 
    String language, 
    String languageCode
  ) async {
    try {
      await updateUserProfile(uid, {
        'language': language,
        'languageCode': languageCode,
      });
    } catch (e) {
      throw FirestoreException('Failed to update language preference: $e');
    }
  }

  // Get all users (for admin purposes)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get users: $e');
    }
  }

  // Get users with completed profiles
  static Future<List<UserModel>> getUsersWithCompletedProfiles() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('name', isNotEqualTo: null)
          .where('phone', isNotEqualTo: null)
          .where('pincode', isNotEqualTo: null)
          .where('city', isNotEqualTo: null)
          .where('state', isNotEqualTo: null)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get users with completed profiles: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final totalUsers = await _firestore
          .collection(_usersCollection)
          .count()
          .get();

      final completedProfiles = await _firestore
          .collection(_usersCollection)
          .where('name', isNotEqualTo: null)
          .where('phone', isNotEqualTo: null)
          .where('pincode', isNotEqualTo: null)
          .where('city', isNotEqualTo: null)
          .where('state', isNotEqualTo: null)
          .count()
          .get();

      return {
        'totalUsers': totalUsers.count ?? 0,
        'completedProfiles': completedProfiles.count ?? 0,
        'incompleteProfiles': (totalUsers.count ?? 0) - (completedProfiles.count ?? 0),
      };
    } catch (e) {
      throw FirestoreException('Failed to get user statistics: $e');
    }
  }

  // Delete user
  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .delete();
      
    } catch (e) {
      throw FirestoreException('Failed to delete user: $e');
    }
  }
}

// Custom exception for Firestore errors
class FirestoreException implements Exception {
  final String message;
  
  FirestoreException(this.message);
  
  @override
  String toString() => message;
} 