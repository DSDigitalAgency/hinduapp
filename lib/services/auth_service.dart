import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Unused
import 'api_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Request additional scopes to ensure proper authentication
    scopes: ['email', 'profile'],
    // Add web client ID for release builds
    serverClientId: '960380088360-jmq3l4sh8lof7tgfq1ek8f0mp94r3a16.apps.googleusercontent.com',
  );
  final ApiService _apiService = ApiService();
  
  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;
  
  // Log current user details for debugging
  void logCurrentUserDetails() {
    // Logging disabled for production
  }
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google user credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Save user to Firestore
      await _handleUserSignIn(userCredential.user!, 'google');
      
      // Send user data to our backend (optional)
      try {
        await _sendUserDataToBackend(userCredential.user!);
      } catch (e) {
        // Backend sync failed, but continuing with Firestore data
      }
      
      return userCredential;
    } catch (e) {
      throw AuthException('Google Sign In failed: ${e.toString()}');
    }
  }
  
  // Apple Sign In (iOS only)
  Future<UserCredential?> signInWithApple() async {
    if (!Platform.isIOS) {
      throw AuthException('Apple Sign In is only available on iOS');
    }
    
    try {
      // Check if Apple Sign In is available
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw AuthException('Apple Sign In is not available on this device');
      }
      
      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      
      // Save user to Firestore
      await _handleUserSignIn(userCredential.user!, 'apple');
      
      // Send user data to our backend (optional)
      try {
        await _sendUserDataToBackend(userCredential.user!);
      } catch (e) {
        // Backend sync failed, but continuing with Firestore data
      }
      
      return userCredential;
    } catch (e) {
      throw AuthException('Apple Sign In failed: ${e.toString()}');
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      // Clear local storage
      await LocalStorageService.clearAllData();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }
  
  // Handle user sign in (save to Firestore)
  Future<void> _handleUserSignIn(User user, String provider) async {
    try {
      // Check if user already exists in Firestore
      final existingUser = await FirestoreService.getUser(user.uid);
      
      if (existingUser != null) {
        return;
      }
      
      // Create new user in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        createdAt: DateTime.now(),
      );
      
      await FirestoreService.createOrUpdateUser(userModel);
      
    } catch (e) {
      // Don't throw here as the main auth flow should continue
    }
  }

  // Check if user profile is complete
  Future<bool> isUserProfileComplete() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      final userData = await FirestoreService.getUser(user.uid);
      if (userData == null) return false;
      
      // Check if required fields are filled
      return userData.name.isNotEmpty && 
             userData.phone != null && 
             userData.phone!.isNotEmpty &&
             userData.pincode != null && 
             userData.pincode!.isNotEmpty &&
             userData.city != null && 
             userData.city!.isNotEmpty &&
             userData.state != null && 
             userData.state!.isNotEmpty &&
             userData.language != null && 
             userData.language!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Send user data to backend
  Future<void> _sendUserDataToBackend(User user) async {
    try {
      await _apiService.makeRequest(
        'POST',
        '/users',
        body: {
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'provider': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'unknown',
        },
      );
    } catch (e) {
      // Don't throw as this is optional
    }
  }
  
  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final userData = await FirestoreService.getUser(uid);
      return userData;
    } catch (e) {
      return null;
    }
  }
  
  // Update user data
  Future<void> updateUserData(UserModel userModel) async {
    try {
      await FirestoreService.createOrUpdateUser(userModel);
    } catch (e) {
      throw AuthException('Failed to update user data: ${e.toString()}');
    }
  }
  
  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('No user is currently signed in');
      }
      
      // Delete from Firestore first
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      
      // Delete from Firebase Auth
      await user.delete();
      
      // Clear local storage
      await LocalStorageService.clearAllData();
    } catch (e) {
      throw AuthException('Failed to delete user account: ${e.toString()}');
    }
  }
  
  // Sync language preference to Firestore
  Future<void> syncLanguagePreferenceToFirestore() async {
    try {
      final user = currentUser;
      if (user == null) return;
      
      final languageName = await LocalStorageService.getUserPreferredLanguageName();
      final languageCode = await LocalStorageService.getUserPreferredLanguageCode();
      
      if (languageName != null && languageCode != null) {
        await FirestoreService.updateUserProfile(user.uid, {
          'language': languageName,
          'languageCode': languageCode,
        });
      }
    } catch (e) {
      // Don't throw as this is a background operation
    }
  }
}

// Custom exception for auth errors
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => message;
} 