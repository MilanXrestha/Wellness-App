import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/services/data_repository.dart'; // Add DataRepository import
import 'dart:developer';

import '../../../profile/data/user_model.dart';

// AuthService class to handle authentication-related operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataRepository _dataRepository = DataRepository.instance; // Initialize DataRepository

  // Saves user data to Firestore 'users' collection, preserving existing userRole
  Future<void> saveUserData(UserModel userModel) async {
    try {
      final docRef = _firestore.collection('users').doc(userModel.userId);
      final existingDoc = await docRef.get();

      // Create data map, excluding userRole if it exists in the document
      final data = userModel.toFirestore();
      if (existingDoc.exists && existingDoc.data()?['userRole'] != null) {
        data.remove('userRole'); // Preserve existing userRole
      }

      await docRef.set(data, SetOptions(merge: true));
      log('User data saved to Firestore for ${userModel.userId}');

      // Verify the write
      final updatedDoc = await docRef.get();
      if (updatedDoc.exists) {
        log('Verified user data in Firestore: ${updatedDoc.data()}');
      } else {
        log('Failed to verify user data in Firestore for ${userModel.userId}');
        throw Exception('User data not found after write');
      }

      // Cache user data locally
      await _dataRepository.updateUser(userModel);
      log('User data cached locally for ${userModel.userId}');
    } catch (e) {
      log('Failed to save user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  // Caches userRole and preferenceCompleted in SharedPreferences
  Future<void> cacheUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', doc.data()!['userRole'] ?? 'user');
        await prefs.setBool(
          'preferenceCompleted',
          doc.data()!['preferenceCompleted'] ?? false,
        );
        log('Cached user data in SharedPreferences for $userId');
      } else {
        log('No user data found in Firestore for $userId');
      }
    } catch (e) {
      log('Error caching user data in SharedPreferences: $e');
    }
  }

  // Checks user role and preference completion, returns navigation route
  Future<String> getUserNavigationRoute(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        log('No user document found for $userId, routing to userPrefsScreen');
        return RoutesName.userPrefsScreen; // Default for new users
      }
      final data = doc.data()!;
      final userRole = data['userRole'] as String? ?? 'user';
      final preferenceCompleted = data['preferenceCompleted'] as bool? ?? false;

      if (userRole == 'admin') {
        log('User $userId is admin, routing to adminDashboardScreen');
        return RoutesName.adminDashboardScreen;
      } else {
        final route = preferenceCompleted
            ? RoutesName.mainScreen
            : RoutesName.userPrefsScreen;
        log(
          'User $userId, preferenceCompleted=$preferenceCompleted, routing to $route',
        );
        return route;
      }
    } catch (e) {
      log('Error checking user role/preferences: $e');
      return RoutesName.userPrefsScreen; // Fallback to userPrefsScreen
    }
  }

  // Checks if the user has completed preferences (for user role only)
  Future<bool> hasCompletedPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final completed =
          doc.exists && (doc.data()?['preferenceCompleted'] as bool? ?? false);
      log('Preference completed for $userId: $completed');
      return completed;
    } catch (e) {
      log('Error checking preferenceCompleted: $e');
      return false;
    }
  }

  // Method to sign up a user with email and password
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await userCredential.user?.updateDisplayName(name.trim());

      final userModel = UserModel(
        userId: userCredential.user!.uid,
        userEmail: email.trim(),
        userName: name.trim(),
        userRole: 'user',
        preferenceCompleted: false,
        createdAt: DateTime.now(),
        photoURL: null,
        fcmToken: null,
      );
      await saveUserData(userModel); // Saves to Firestore and local database
      await cacheUserData(userCredential.user!.uid); // Cache user data in SharedPreferences
      log('Signed up user ${userCredential.user!.uid} with email $email');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      log('Sign-up error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected sign-up error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        log('Google sign-in canceled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      UserModel userModel;
      if (!userDoc.exists) {
        // Only create new user document for new users
        userModel = UserModel(
          userId: userCredential.user!.uid,
          userEmail: googleUser.email,
          userName: googleUser.displayName ?? 'Google User',
          userRole: 'user',
          preferenceCompleted: false,
          createdAt: DateTime.now(),
          photoURL: userCredential.user?.photoURL,
          fcmToken: null,
        );
        await saveUserData(userModel); // Saves to Firestore and local database
      } else {
        // Update existing user document, preserving userRole
        userModel = UserModel(
          userId: userCredential.user!.uid,
          userEmail: googleUser.email,
          userName: googleUser.displayName ?? 'Google User',
          userRole: userDoc.data()!['userRole'] ?? 'user',
          preferenceCompleted: userDoc.data()!['preferenceCompleted'] ?? false,
          createdAt: (userDoc.data()?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          photoURL: userCredential.user?.photoURL,
          fcmToken: userDoc.data()!['fcmToken'],
        );
        await saveUserData(userModel); // Saves to Firestore and local database
      }
      await cacheUserData(userCredential.user!.uid); // Cache user data in SharedPreferences
      // Update last login timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_login_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      log('Signed in user ${userCredential.user!.uid} with Google');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid Google credentials.';
          break;
        default:
          errorMessage = 'Google Sign-In failed: ${e.message}';
      }
      log('Google sign-in error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected Google sign-in error: $e');
      throw Exception('An unexpected error occurred during Google Sign-In: $e');
    }
  }

  // Method to sign in a user with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Fetch or create user model
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      UserModel userModel;
      if (!userDoc.exists) {
        // Create user model for new user (unlikely for email login, but handle edge case)
        userModel = UserModel(
          userId: userCredential.user!.uid,
          userEmail: email.trim(),
          userName: userCredential.user?.displayName ?? 'User',
          userRole: 'user',
          preferenceCompleted: false,
          createdAt: DateTime.now(),
          photoURL: null,
          fcmToken: null,
        );
        await saveUserData(userModel); // Saves to Firestore and local database
      } else {
        // Update existing user model
        userModel = UserModel(
          userId: userCredential.user!.uid,
          userEmail: email.trim(),
          userName: userCredential.user?.displayName ?? 'User',
          userRole: userDoc.data()!['userRole'] ?? 'user',
          preferenceCompleted: userDoc.data()!['preferenceCompleted'] ?? false,
          createdAt: (userDoc.data()?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          photoURL: userCredential.user?.photoURL,
          fcmToken: userDoc.data()!['fcmToken'],
        );
        await saveUserData(userModel); // Saves to Firestore and local database
      }

      await cacheUserData(userCredential.user!.uid); // Cache user data in SharedPreferences
      log('Signed in user ${userCredential.user!.uid} with email $email');
      // Update last login timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_login_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      log('Sign-in error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected sign-in error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to send a password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      log('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      log('Password reset error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected password reset error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to get the current user
  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      log('Current user: ${user.uid}');
    } else {
      log('No current user');
    }
    return user;
  }

  // Method to re-authenticate the user with email and password
  Future<void> reAuthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password.trim(),
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      log('User re-authenticated with email $email');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect current password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'Re-authentication failed: ${e.message}';
      }
      log('Re-authentication error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected re-authentication error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to re-authenticate the user with Google
  Future<void> reAuthenticateWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        log('Google re-authentication canceled');
        throw Exception('Google re-authentication canceled.');
      }
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      log('User re-authenticated with Google');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
          'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid Google credentials.';
          break;
        default:
          errorMessage = 'Google re-authentication failed: ${e.message}';
      }
      log('Google re-authentication error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected Google re-authentication error: $e');
      throw Exception(
        'An unexpected error occurred during Google re-authentication: $e',
      );
    }
  }

  // Method to update the user's password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword.trim());
      log('Password updated for user ${_auth.currentUser?.uid}');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The new password is too weak.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please re-authenticate to change your password.';
          break;
        default:
          errorMessage = 'Failed to update password: ${e.message}';
      }
      log('Password update error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected password update error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      // Clear cached user data on sign-out
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole');
      await prefs.remove('preferenceCompleted');
      log('User signed out');
    } catch (e) {
      log('Unexpected sign-out error: $e');
      throw Exception('An unexpected error occurred during sign-out: $e');
    }
  }

  // Method to promote a user to admin (only callable by admins)
  Future<void> promoteToAdmin(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        log('No authenticated user found for promoteToAdmin');
        throw Exception('No authenticated user found.');
      }
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (currentUserDoc.data()?['userRole'] != 'admin') {
        log('Non-admin user ${currentUser.uid} attempted to promote $userId');
        throw Exception('Only admins can promote users.');
      }
      await _firestore.collection('users').doc(userId).update({
        'userRole': 'admin',
      });
      // Update cache for the promoted user
      await cacheUserData(userId);
      log('User $userId promoted to admin');
    } catch (e) {
      log('Failed to promote user: $e');
      throw Exception('Failed to promote user: $e');
    }
  }

  // Method to update user profile
  Future<void> updateUserProfile({
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log('No authenticated user found for updateUserProfile');
        throw Exception('No authenticated user found.');
      }
      await user.updateDisplayName(displayName.trim());
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL.trim());
      }
      // Update Firestore user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userModel = UserModel(
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: displayName.trim(),
        userRole: userDoc.data()?['userRole'] ?? 'user',
        preferenceCompleted: userDoc.data()?['preferenceCompleted'] ?? false,
        createdAt: (userDoc.data()?['createdAt'] is Timestamp)
            ? (userDoc.data()?['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(
          userDoc.data()?['createdAt']?.toString() ?? '',
        ) ??
            DateTime.now(),
        photoURL: photoURL,
        fcmToken: userDoc.data()?['fcmToken'],
      );
      await saveUserData(userModel); // Saves to Firestore and local database
      await cacheUserData(user.uid); // Update cache in SharedPreferences
      log('Updated profile for user ${user.uid}');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-display-name':
          errorMessage = 'The display name is not valid.';
          break;
        default:
          errorMessage = 'Failed to update profile: ${e.message}';
      }
      log('Profile update error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('Unexpected profile update error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Demotes a user to 'user' role in Firestore
  Future<void> demoteToUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'userRole': 'user',
      });
      await cacheUserData(userId); // Update cache in SharedPreferences
      log('User $userId demoted to user');
    } catch (e) {
      log('Failed to demote user: $e');
      throw Exception('Failed to demote user: $e');
    }
  }
}