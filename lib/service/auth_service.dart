import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// AuthService class to handle authentication-related operations
class AuthService {
  // Instance of FirebaseAuth for authentication operations
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to sign up a user with email and password
  // Parameters: email, password, and name for user profile
  // Returns: User object on success, null on failure
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create a new user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Update the user's display name
      await userCredential.user?.updateDisplayName(name.trim());

      // Return the created user
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
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
      // Re-throw the exception with a user-friendly message
      throw Exception(errorMessage);
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to sign in a user with email and password
  // Parameters: email and password
  // Returns: User object on success, null on failure
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in the user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Return the signed-in user
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
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
      // Re-throw the exception with a user-friendly message
      throw Exception(errorMessage);
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to sign in with Google
  // Forces the account chooser by signing out first
  // Returns: User object on success, null if the user cancels the sign-in
  Future<User?> signInWithGoogle() async {
    try {
      // Initialize GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Sign out the previous Google account to force account chooser
      await googleSignIn.signOut();

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // If the user cancels the sign-in, return null
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Return the signed-in user
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
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
      throw Exception(errorMessage);
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred during Google Sign-In: $e');
    }
  }

  // Method to send a password reset email
  // Parameters: email address
  // Returns: Future that completes when the email is sent or throws an error
  Future<void> resetPassword({required String email}) async {
    try {
      // Send password reset email using Firebase Authentication
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
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
      throw Exception(errorMessage);
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to get the current user
  // Returns: Current User object or null if no user is signed in
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Method to re-authenticate the user with email and password
  // Parameters: email and password
  // Returns: Future that completes on successful re-authentication or throws an error
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
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to re-authenticate the user with Google
  // Returns: Future that completes on successful re-authentication or throws an error
  Future<void> reAuthenticateWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google re-authentication canceled.');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
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
          errorMessage = 'Google re-authentication failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred during Google re-authentication: $e');
    }
  }

  // Method to update the user's password
  // Parameters: new password
  // Returns: Future that completes on successful password update or throws an error
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword.trim());
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
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to sign out the current user
  // Returns: Future that completes when sign-out is successful
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Sign out from Google to ensure fresh sign-in next time
      await GoogleSignIn().signOut();
    } catch (e) {
      throw Exception('An unexpected error occurred during sign-out: $e');
    }
  }
}