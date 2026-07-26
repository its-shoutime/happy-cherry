import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Auth + last-user helpers (SRP).
class AuthService {
  static const String _lastLoggedInUserKey = 'last_logged_in_user';

  String emailForUsername(String username) {
    final normalized = username.trim().toLowerCase();
    if (normalized.contains('@')) {
      return normalized;
    }
    return '$normalized@happy-cherry.app';
  }

  Future<void> saveLastLoggedInUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoggedInUserKey, username.trim().toLowerCase());
  }

  Future<String?> loadLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLoggedInUserKey);
  }

  Future<void> clearLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoggedInUserKey);
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return false;
    }
    final email = emailForUsername(username);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return false;
    }
    final email = emailForUsername(username);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }
}
