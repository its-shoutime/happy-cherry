import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_cherry/data/progress_codec.dart';
import 'package:happy_cherry/data/save_store.dart';

/// SharedPreferences-backed progress store.
class LocalSaveStore implements SaveStore {
  LocalSaveStore({ProgressCodec? codec}) : _codec = codec ?? ProgressCodec();

  final ProgressCodec _codec;

  static const String _defaultPetKey = 'pet_save';

  static String petKey([String? userId]) {
    if (userId == null || userId.isEmpty) {
      return _defaultPetKey;
    }
    return 'pet_save_${userId.toLowerCase()}';
  }

  @override
  Future<Map<String, dynamic>?> loadRaw(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final petJson = prefs.getString(petKey(userId));
    if (petJson == null) return null;

    try {
      return jsonDecode(petJson) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      debugPrint('Failed to load local save: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<void> saveRaw(String? userId, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final key = petKey(userId);

    // Skip if a newer save is already on disk (guards concurrent writers).
    final existingRaw = prefs.getString(key);
    if (existingRaw != null) {
      try {
        final existing = jsonDecode(existingRaw) as Map<String, dynamic>;
        final existingAt = _codec.parseSavedAt(existing['savedAt'] as String?);
        final incomingAt = _codec.parseSavedAt(payload['savedAt'] as String?);
        if (existingAt != null &&
            incomingAt != null &&
            existingAt.isAfter(incomingAt)) {
          return;
        }
      } catch (_) {}
    }

    await prefs.setString(key, jsonEncode(payload));
  }

  @override
  Future<void> delete(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(petKey(userId));
  }
}
