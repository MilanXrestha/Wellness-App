import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preference_model.dart';
import '../models/user_preference_model.dart';

/// A service to manage user preferences in Firestore.
class PreferenceService {
  final _firestore = FirebaseFirestore.instance;
  final String _preferencesCollection = 'preferences';
  final String _userPreferencesCollection = 'userPreferences';

  /// Streams preferences in real-time from Firestore.
  Stream<List<PreferenceModel>> streamPreferences() {
    return _firestore.collection(_preferencesCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PreferenceModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Streams user preferences in real-time from Firestore.
  Stream<UserPreferenceModel?> streamUserPreferences(String userId) {
    return _firestore
        .collection(_userPreferencesCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserPreferenceModel.fromFirestore(snapshot.data()!, userId);
      }
      return null;
    });
  }

  /// Fetches all preferences from Firestore (one-time fetch).
  Future<List<PreferenceModel>> fetchPreferences() async {
    try {
      final snapshot = await _firestore.collection(_preferencesCollection).get();
      return snapshot.docs.map((doc) {
        return PreferenceModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Access denied. Please check your account permissions.');
      }
      throw Exception('Failed to fetch preferences: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetches user preferences from userPreferences collection.
  Future<UserPreferenceModel?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection(_userPreferencesCollection).doc(userId).get();
      if (doc.exists) {
        return UserPreferenceModel.fromFirestore(doc.data()!, userId);
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Access denied. Please check your account permissions.');
      }
      throw Exception('Failed to fetch user preferences: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Adds a new preference to Firestore.
  Future<void> addPreference(PreferenceModel preference) async {
    try {
      await _firestore.collection(_preferencesCollection).add(preference.toFirestore());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You are not allowed to add preferences.');
      }
      throw Exception('Failed to add preference: ${e.message}');
    }
  }

  /// Updates an existing preference in Firestore.
  Future<void> updatePreference(PreferenceModel preference) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(preference.preferenceId)
          .update(preference.toFirestore());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You are not allowed to update preferences.');
      }
      throw Exception('Failed to update preference: ${e.message}');
    }
  }

  /// Deletes a preference from Firestore using its ID.
  Future<void> deletePreference(String id) async {
    try {
      await _firestore.collection(_preferencesCollection).doc(id).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You are not allowed to delete preferences.');
      }
      throw Exception('Failed to delete preference: ${e.message}');
    }
  }

  /// Saves user preferences to a single document in userPreferences.
  Future<void> saveUserPreferences(String userId, List<UserPreferenceEntry> preferences) async {
    try {
      final docRef = _firestore.collection(_userPreferencesCollection).doc(userId);
      await docRef.set({
        'userId': userId,
        'preferences': preferences.map((entry) => entry.toFirestore()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You are not allowed to save preferences.');
      }
      throw Exception('Failed to save user preferences: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Updates user preferences by adding or removing a single preference.
  Future<void> updateUserPreference(String userId, UserPreferenceEntry preference, bool add) async {
    try {
      final docRef = _firestore.collection(_userPreferencesCollection).doc(userId);
      if (add) {
        await docRef.update({
          'preferences': FieldValue.arrayUnion([preference.toFirestore()]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'preferences': FieldValue.arrayRemove([preference.toFirestore()]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You are not allowed to update preferences.');
      }
      throw Exception('Failed to update user preference: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}