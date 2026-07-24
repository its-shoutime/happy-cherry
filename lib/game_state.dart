import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/pet.dart';

class GameState {
  static const String _defaultPetKey = 'pet_save';

  /// Serializes saves so an older in-flight write cannot overwrite a newer one.
  static Future<void> _saveChain = Future<void>.value();

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

  static DateTime? _parseSavedAt(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Map<String, dynamic>? _readPetJson(Map<String, dynamic> decoded) {
    final pet = decoded['pet'];
    if (pet is Map<String, dynamic>) {
      return pet;
    }
    if (pet is Map) {
      return Map<String, dynamic>.from(pet);
    }
    if (decoded.containsKey('name')) {
      return decoded;
    }
    return null;
  }

  static int _readCoins(
    Map<String, dynamic> decoded,
    Map<String, dynamic> petJson,
  ) {
    final accountCoins = (decoded['coins'] as num?)?.toInt();
    if (accountCoins != null) {
      return accountCoins;
    }
    // Migrate legacy pet XP into account coins once.
    return (petJson['xp'] as num?)?.toInt() ?? 0;
  }

  static ({Pet pet, int coins, DateTime savedAt})? _decodeStoredSave(
    Map<String, dynamic> decoded,
  ) {
    try {
      final petJson = _readPetJson(decoded);
      if (petJson == null) return null;

      final pet = Pet.fromJson(petJson);
      final coins = _readCoins(decoded, petJson);
      final savedAt =
          _parseSavedAt(decoded['savedAt'] as String?) ?? DateTime.now();
      return (pet: pet, coins: coins, savedAt: savedAt);
    } catch (error, stackTrace) {
      debugPrint('Failed to decode pet save: $error\n$stackTrace');
      return null;
    }
  }

  static Future<({Pet pet, int coins, DateTime savedAt})?> _loadLocalSave(
    String? userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final petJson = prefs.getString(_petKey(userId));
    if (petJson == null) return null;

    try {
      final decoded = jsonDecode(petJson) as Map<String, dynamic>;
      return _decodeStoredSave(decoded);
    } catch (error, stackTrace) {
      debugPrint('Failed to load local save: $error\n$stackTrace');
      return null;
    }
  }

  static Future<({Pet pet, int coins, DateTime savedAt})?> _loadRemoteSave(
    String userId,
  ) async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!document.exists) return null;

      final data = document.data();
      if (data == null) return null;

      return _decodeStoredSave(Map<String, dynamic>.from(data));
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'unavailable' || error.code == 'failed-precondition') {
        debugPrint('Firestore offline, using cached save: $error\n$stackTrace');
        return null;
      }
      debugPrint('Unexpected Firestore error: $error\n$stackTrace');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Failed to load remote save: $error\n$stackTrace');
      rethrow;
    }
  }

  static ({Pet pet, int coins, DateTime savedAt})? _pickNewestSave(
    ({Pet pet, int coins, DateTime savedAt})? local,
    ({Pet pet, int coins, DateTime savedAt})? remote,
  ) {
    if (local == null) return remote;
    if (remote == null) return local;
    // Prefer local on a tie so same-device lights/settings win.
    return remote.savedAt.isAfter(local.savedAt) ? remote : local;
  }

  static void _advancePetToNow(Pet pet, DateTime savedAt) {
    final elapsed = DateTime.now().difference(savedAt);
    if (elapsed > Duration.zero) {
      pet.advanceTime(elapsed);
    }
  }

  static Map<String, dynamic> _savePayload(
    Pet pet,
    int coins,
    DateTime savedAt,
  ) {
    return {
      'pet': pet.toJson(),
      'coins': coins,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  static Future<void> _cacheSave(
    String? userId,
    Pet pet,
    int coins,
    DateTime savedAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _petKey(userId);

    // Skip if a newer save is already on disk (guards concurrent writers).
    final existingRaw = prefs.getString(key);
    if (existingRaw != null) {
      try {
        final existing = jsonDecode(existingRaw) as Map<String, dynamic>;
        final existingAt = _parseSavedAt(existing['savedAt'] as String?);
        if (existingAt != null && existingAt.isAfter(savedAt)) {
          return;
        }
      } catch (_) {}
    }

    await prefs.setString(key, jsonEncode(_savePayload(pet, coins, savedAt)));
  }

  static Future<({Pet pet, int coins})?> loadCachedPet({String? userId}) async {
    final stored = await _loadLocalSave(userId);
    if (stored == null) return null;

    _advancePetToNow(stored.pet, stored.savedAt);
    return (pet: stored.pet, coins: stored.coins);
  }

  static Pet _copyPet(Pet pet) => Pet.fromJson(pet.toJson());

  static Future<({Pet pet, int coins})?> loadPet({
    String? userId,
    void Function(Pet pet, int coins)? onLocalReady,
  }) async {
    if (userId == null || userId.isEmpty) {
      return loadCachedPet(userId: userId);
    }

    final localFuture = _loadLocalSave(userId);
    final remoteFuture = _loadRemoteSave(userId);

    final local = await localFuture;
    Pet? previewPet;
    int? previewCoins;
    if (local != null && onLocalReady != null) {
      previewPet = _copyPet(local.pet);
      previewCoins = local.coins;
      _advancePetToNow(previewPet, local.savedAt);
      onLocalReady(previewPet, previewCoins);
    }

    ({Pet pet, int coins, DateTime savedAt})? remote;
    try {
      remote = await remoteFuture;
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'unavailable' || error.code == 'failed-precondition') {
        debugPrint(
          'Remote load failed due to offline mode: $error\n$stackTrace',
        );
        remote = null;
      } else {
        rethrow;
      }
    }

    final stored = _pickNewestSave(local, remote);
    if (stored == null) {
      if (previewPet == null || previewCoins == null) return null;
      return (pet: previewPet, coins: previewCoins);
    }

    final Pet resultPet;
    final int resultCoins;
    if (previewPet != null && identical(stored, local)) {
      resultPet = previewPet;
      resultCoins = previewCoins!;
    } else {
      resultPet = stored.pet;
      resultCoins = stored.coins;
      _advancePetToNow(resultPet, stored.savedAt);
    }

    final syncedAt = DateTime.now();
    unawaited(_cacheSave(userId, resultPet, resultCoins, syncedAt));

    if (remote != null && identical(stored, local)) {
      unawaited(
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(_savePayload(resultPet, resultCoins, syncedAt))
            .catchError((Object error, StackTrace stackTrace) {
              debugPrint('Failed to sync remote save: $error\n$stackTrace');
            }),
      );
    }

    return (pet: resultPet, coins: resultCoins);
  }

  static Future<void> savePet(Pet pet, {required int coins, String? userId}) {
    // Snapshot state now; run after prior saves so order is preserved.
    final petSnapshot = Pet.fromJson(pet.toJson());
    final coinsSnapshot = coins;
    final savedAt = DateTime.now();

    final save = _saveChain.then((_) async {
      final saveData = _savePayload(petSnapshot, coinsSnapshot, savedAt);

      await _cacheSave(userId, petSnapshot, coinsSnapshot, savedAt);

      if (userId == null || userId.isEmpty) {
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(saveData)
            .timeout(const Duration(seconds: 8));
      } on FirebaseException catch (error, stackTrace) {
        if (error.code == 'unavailable' ||
            error.code == 'failed-precondition') {
          debugPrint('Save queued offline, will sync when online: $error');
        } else {
          debugPrint('Failed to save remote progress: $error\n$stackTrace');
          rethrow;
        }
      } catch (error, stackTrace) {
        debugPrint('Failed to save remote progress: $error\n$stackTrace');
      }
    });

    _saveChain = save.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Save queue error: $error\n$stackTrace');
    });

    return save;
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

    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    } catch (error, stackTrace) {
      debugPrint('Failed to delete remote save: $error\n$stackTrace');
    }
  }

  static Future<void> clearLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoggedInUserKey);
  }
}
