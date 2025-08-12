import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  UserProvider() {
    // Listen to user changes stream from Firebase Auth
    FirebaseAuth.instance.userChanges().listen((User? firebaseUser) {
      _user = firebaseUser;
      notifyListeners(); // Notify all listening widgets to rebuild
    });
  }

  // Optional: Manual refresh method if needed
  Future<void> refreshUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
    }
  }
}
