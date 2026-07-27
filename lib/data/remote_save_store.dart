import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:happy_cherry/data/save_store.dart';

/// Firestore-backed progress store. Interchangeable with [LocalSaveStore] (LSP).
class RemoteSaveStore implements SaveStore {
  RemoteSaveStore({
    this.loadOverride,
    this.saveOverride,
    this.skipDeleteWhenOverridden = true,
  });

  /// Test hook: replace Firestore load.
  Future<Map<String, dynamic>?> Function(String userId)? loadOverride;

  /// Test hook: replace Firestore save.
  Future<void> Function(String userId, Map<String, dynamic> data)? saveOverride;

  final bool skipDeleteWhenOverridden;

  @override
  Future<Map<String, dynamic>?> loadRaw(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    final override = loadOverride;
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

      return Map<String, dynamic>.from(data);
    } catch (error, stackTrace) {
      debugPrint('Firestore remote load failed: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<void> saveRaw(String? userId, Map<String, dynamic> payload) async {
    if (userId == null || userId.isEmpty) return;

    final override = saveOverride;
    if (override != null) {
      await override(userId, payload);
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(payload);
  }

  @override
  Future<void> delete(String? userId) async {
    if (userId == null || userId.isEmpty) return;

    if (skipDeleteWhenOverridden && saveOverride != null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    } catch (error, stackTrace) {
      debugPrint('Failed to delete remote save: $error\n$stackTrace');
    }
  }
}
