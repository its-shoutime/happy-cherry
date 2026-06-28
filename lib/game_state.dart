import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/pet.dart';

class GameState {
  static const String _defaultPetKey = 'pet_save';

  static String _petKey([String? userId]) {
    if (userId == null || userId.isEmpty) {
      return _defaultPetKey;
    }
    return 'pet_save_${userId.toLowerCase()}';
  }

  static const String _lastLoggedInUserKey = 'last_logged_in_user';

  static String firebaseEmailForUsername(String username) {
    final normalized = username.trim().toLowerCase();
    if (normalized.contains('@')) {
      return normalized;
    }
    return '$normalized@happy-cherry.app';
  }

  static Future<void> saveLastLoggedInUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoggedInUserKey, username.trim().toLowerCase());
  }

  static Future<String?> loadLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLoggedInUserKey);
  }

  static Future<Pet?> loadCachedPet({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final petJson = prefs.getString(_petKey(userId));
    if (petJson == null) return null;

    try {
      final decoded = jsonDecode(petJson) as Map<String, dynamic>;
      final savedAt = decoded['savedAt'] as String?;
      final savedPet = decoded['pet'] as Map<String, dynamic>?;
      final pet = savedPet != null
          ? Pet.fromJson(savedPet)
          : Pet.fromJson(decoded);

      if (savedAt != null) {
        final lastSaved = DateTime.tryParse(savedAt) ?? DateTime.now();
        final elapsed = DateTime.now().difference(lastSaved);
        if (elapsed > Duration.zero) {
          pet.advanceTime(elapsed);
        }
      }

      return pet;
    } catch (_) {
      return null;
    }
  }

  static Future<Pet?> loadPet({String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return await loadCachedPet(userId: userId);
    }

    final cachedPet = await loadCachedPet(userId: userId);

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!document.exists) {
        return cachedPet;
      }

      final data = document.data();
      if (data == null) {
        return cachedPet;
      }

      final savedAt = data['savedAt'] as String?;
      final savedPet = data['pet'] as Map<String, dynamic>?;
      final pet = savedPet != null ? Pet.fromJson(savedPet) : null;
      if (pet == null) {
        return cachedPet;
      }

      if (savedAt != null) {
        final lastSaved = DateTime.tryParse(savedAt) ?? DateTime.now();
        final elapsed = DateTime.now().difference(lastSaved);
        if (elapsed > Duration.zero) {
          pet.advanceTime(elapsed);
        }
      }

      final saveData = {
        'pet': pet.toJson(),
        'savedAt': savedAt ?? DateTime.now().toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_petKey(userId), jsonEncode(saveData));

      return pet;
    } catch (_) {
      return cachedPet;
    }
  }

  static Future<void> savePet(Pet pet, {String? userId}) async {
    final saveData = {
      'pet': pet.toJson(),
      'savedAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petKey(userId), jsonEncode(saveData));

    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(saveData, SetOptions(merge: true));
    } catch (_) {
      // Ignore Firestore write failures here; local cache preserves play state.
    }
  }

  static Future<bool> loginUser(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return false;
    }
    final email = firebaseEmailForUsername(username);
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

  static Future<bool> registerUser(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return false;
    }
    final email = firebaseEmailForUsername(username);
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

  static Future<void> deleteSave({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_petKey(userId));
  }

  static Future<void> clearLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoggedInUserKey);
  }
}
