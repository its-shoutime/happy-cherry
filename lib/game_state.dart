import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/accessories.dart';
import 'models/pet.dart';

typedef StoredSave = ({
  Pet pet,
  int coins,
  List<String> ownedAccessories,
  DateTime savedAt,
});

typedef LoadedSave = ({Pet pet, int coins, List<String> ownedAccessories});

class GameState {
  static const String _defaultPetKey = 'pet_save';

  /// Serializes saves so an older in-flight write cannot overwrite a newer one.
  static Future<void> _saveChain = Future<void>.value();

  /// Test-only hooks so progress tests can exercise remote merge without Firebase.
  @visibleForTesting
  static Future<StoredSave?> Function(String userId)? debugLoadRemoteOverride;

  @visibleForTesting
  static Future<void> Function(String userId, Map<String, dynamic> data)?
  debugSaveRemoteOverride;

  @visibleForTesting
  static void debugResetForTest() {
    _saveChain = Future<void>.value();
    debugLoadRemoteOverride = null;
    debugSaveRemoteOverride = null;
  }

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

  static List<String> _readOwnedAccessories(
    Map<String, dynamic> decoded,
    Pet pet,
  ) {
    final owned = <String>{};
    final raw = decoded['ownedAccessories'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.isNotEmpty) {
          owned.add(item);
        }
      }
    }
    // Migrate: anything already equipped counts as owned.
    final equipped = pet.accessory;
    if (equipped != null && equipped.isNotEmpty) {
      owned.add(equipped);
    }
    // Normalize legacy ids (e.g. hat → straw_hat) for newer catalogs.
    return AccessoryCatalog.canonicalizeOwned(owned);
  }

  static StoredSave? _decodeStoredSave(Map<String, dynamic> decoded) {
    try {
      final petJson = _readPetJson(decoded);
      if (petJson == null) return null;

      final pet = Pet.fromJson(petJson);
      final coins = _readCoins(decoded, petJson);
      final ownedAccessories = _readOwnedAccessories(decoded, pet);
      // Keep equipped accessory aligned with the canonical owned id.
      if (pet.accessory != null && pet.accessory!.isNotEmpty) {
        pet.accessory = AccessoryCatalog.canonicalizeId(pet.accessory!);
      }
      final savedAt =
          _parseSavedAt(decoded['savedAt'] as String?) ?? DateTime.now();
      return (
        pet: pet,
        coins: coins,
        ownedAccessories: ownedAccessories,
        savedAt: savedAt,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to decode pet save: $error\n$stackTrace');
      return null;
    }
  }

  static Future<StoredSave?> _loadLocalSave(String? userId) async {
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

  static Future<StoredSave?> _loadRemoteSave(String userId) async {
    final override = debugLoadRemoteOverride;
    if (override != null) {
      try {
        return await override(userId);
      } catch (error, stackTrace) {
        debugPrint('Remote load override failed: $error\n$stackTrace');
        return null;
      }
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!document.exists) return null;

      final data = document.data();
      if (data == null) return null;

      return _decodeStoredSave(Map<String, dynamic>.from(data));
    } catch (error, stackTrace) {
      // Treat unreachable/denied cloud as "no remote save" so new accounts and
      // wiped local caches can still enter the game. Local cache still wins
      // when present (see loadPet).
      debugPrint('Firestore remote load failed: $error\n$stackTrace');
      return null;
    }
  }

  static StoredSave? _pickNewestSave(StoredSave? local, StoredSave? remote) {
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
    List<String> ownedAccessories,
    DateTime savedAt,
  ) {
    return {
      'pet': pet.toJson(),
      'coins': coins,
      'ownedAccessories': ownedAccessories,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  static Future<void> _cacheSave(
    String? userId,
    Pet pet,
    int coins,
    List<String> ownedAccessories,
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

    await prefs.setString(
      key,
      jsonEncode(_savePayload(pet, coins, ownedAccessories, savedAt)),
    );
  }

  static Future<LoadedSave?> loadCachedPet({String? userId}) async {
    final stored = await _loadLocalSave(userId);
    if (stored == null) return null;

    _advancePetToNow(stored.pet, stored.savedAt);
    return (
      pet: stored.pet,
      coins: stored.coins,
      ownedAccessories: stored.ownedAccessories,
    );
  }

  static Pet _copyPet(Pet pet) => Pet.fromJson(pet.toJson());

  static Future<LoadedSave?> loadPet({
    String? userId,
    void Function(Pet pet, int coins, List<String> ownedAccessories)?
    onLocalReady,
  }) async {
    if (userId == null || userId.isEmpty) {
      return loadCachedPet(userId: userId);
    }

    final localFuture = _loadLocalSave(userId);
    // Capture remote errors immediately so a fast failure cannot become an
    // unhandled async error while local is still loading.
    final remoteFuture = _loadRemoteSave(userId).then<StoredSave?>(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Remote load failed, using cache if any: $error\n$stackTrace',
        );
        return null;
      },
    );

    final local = await localFuture;
    Pet? previewPet;
    int? previewCoins;
    List<String>? previewOwned;
    if (local != null && onLocalReady != null) {
      previewPet = _copyPet(local.pet);
      previewCoins = local.coins;
      previewOwned = List<String>.from(local.ownedAccessories);
      _advancePetToNow(previewPet, local.savedAt);
      onLocalReady(previewPet, previewCoins, previewOwned);
    }

    final remote = await remoteFuture;

    final stored = _pickNewestSave(local, remote);
    if (stored == null) {
      if (previewPet == null || previewCoins == null || previewOwned == null) {
        // No local and no remote → brand-new account (or cloud unreachable).
        return null;
      }
      return (
        pet: previewPet,
        coins: previewCoins,
        ownedAccessories: previewOwned,
      );
    }

    final Pet resultPet;
    final int resultCoins;
    final List<String> resultOwned;
    if (previewPet != null && identical(stored, local)) {
      resultPet = previewPet;
      resultCoins = previewCoins!;
      resultOwned = previewOwned!;
    } else {
      resultPet = stored.pet;
      resultCoins = stored.coins;
      resultOwned = stored.ownedAccessories;
      _advancePetToNow(resultPet, stored.savedAt);
    }

    final syncedAt = DateTime.now();
    unawaited(
      _cacheSave(userId, resultPet, resultCoins, resultOwned, syncedAt),
    );

    if (remote != null && identical(stored, local)) {
      final payload = _savePayload(
        resultPet,
        resultCoins,
        resultOwned,
        syncedAt,
      );
      final saveRemote = debugSaveRemoteOverride;
      if (saveRemote != null) {
        unawaited(
          saveRemote(userId, payload).catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint('Failed to sync remote save: $error\n$stackTrace');
          }),
        );
      } else {
        unawaited(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(payload)
              .catchError((Object error, StackTrace stackTrace) {
                debugPrint('Failed to sync remote save: $error\n$stackTrace');
              }),
        );
      }
    }

    return (
      pet: resultPet,
      coins: resultCoins,
      ownedAccessories: resultOwned,
    );
  }

  static Future<void> savePet(
    Pet pet, {
    required int coins,
    List<String> ownedAccessories = const [],
    String? userId,
  }) {
    // Snapshot state now; run after prior saves so order is preserved.
    final petSnapshot = Pet.fromJson(pet.toJson());
    final coinsSnapshot = coins;
    final ownedSnapshot = List<String>.from(ownedAccessories);
    final savedAt = DateTime.now();

    final save = _saveChain.then((_) async {
      final saveData = _savePayload(
        petSnapshot,
        coinsSnapshot,
        ownedSnapshot,
        savedAt,
      );

      await _cacheSave(
        userId,
        petSnapshot,
        coinsSnapshot,
        ownedSnapshot,
        savedAt,
      );

      if (userId == null || userId.isEmpty) {
        return;
      }

      try {
        final saveRemote = debugSaveRemoteOverride;
        if (saveRemote != null) {
          await saveRemote(userId, saveData);
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(saveData)
              .timeout(const Duration(seconds: 8));
        }
      } catch (error, stackTrace) {
        // Local cache already succeeded; do not fail the save Future.
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

    // In tests, remote I/O is overridden — skip live Firestore deletes.
    if (debugSaveRemoteOverride != null) {
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

  static String _cherryHighScoreKey([String? userId]) {
    if (userId == null || userId.isEmpty) {
      return 'cherry_catch_high_score';
    }
    return 'cherry_catch_high_score_${userId.toLowerCase()}';
  }

  static Future<int> loadCherryHighScore({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cherryHighScoreKey(userId)) ?? 0;
  }

  /// Persists [score] when it beats the stored personal best. Returns the best.
  static Future<int> recordCherryHighScore(int score, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cherryHighScoreKey(userId);
    final current = prefs.getInt(key) ?? 0;
    if (score > current) {
      await prefs.setInt(key, score);
      return score;
    }
    return current;
  }
}
