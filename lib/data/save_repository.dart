import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/data/local_save_store.dart';
import 'package:happy_cherry/data/progress_codec.dart';
import 'package:happy_cherry/data/remote_save_store.dart';
import 'package:happy_cherry/data/save_models.dart';
import 'package:happy_cherry/data/save_store.dart';

/// Orchestrates local + remote progress merge and serialized saves (SRP / DIP).
class SaveRepository {
  SaveRepository({
    SaveStore? localStore,
    SaveStore? remoteStore,
    ProgressCodec? codec,
  }) : localStore = localStore ?? LocalSaveStore(codec: codec ?? ProgressCodec()),
       remoteStore = remoteStore ?? RemoteSaveStore(),
       codec = codec ?? ProgressCodec();

  final SaveStore localStore;
  final SaveStore remoteStore;
  final ProgressCodec codec;

  /// Serializes local writes so an older in-flight write cannot overwrite a newer one.
  Future<void> _localChain = Future<void>.value();

  /// Serializes remote writes independently so Firestore latency cannot block
  /// local persistence (rename/logout must land on disk quickly).
  Future<void> _remoteChain = Future<void>.value();

  void resetSaveChain() {
    _localChain = Future<void>.value();
    _remoteChain = Future<void>.value();
  }

  StoredSave? _pickNewestSave(StoredSave? local, StoredSave? remote) {
    if (local == null) return remote;
    if (remote == null) return local;
    return remote.savedAt.isAfter(local.savedAt) ? remote : local;
  }

  void _advancePetToNow(Pet pet, DateTime savedAt) {
    final elapsed = DateTime.now().difference(savedAt);
    if (elapsed > Duration.zero) {
      pet.advanceTime(elapsed);
    }
  }

  Pet _copyPet(Pet pet) => Pet.fromJson(pet.toJson());

  Future<StoredSave?> _loadFromStore(SaveStore store, String? userId) async {
    final raw = await store.loadRaw(userId);
    if (raw == null) return null;
    return codec.decode(raw);
  }

  Future<void> _writeLocal(
    String? userId,
    Pet pet,
    int coins,
    List<String> ownedAccessories,
    DateTime savedAt,
  ) {
    return localStore.saveRaw(
      userId,
      codec.encode(pet, coins, ownedAccessories, savedAt),
    );
  }

  Future<void> _enqueueLocal(
    String? userId,
    Pet pet,
    int coins,
    List<String> ownedAccessories,
    DateTime savedAt,
  ) {
    final write = _localChain.then(
      (_) => _writeLocal(userId, pet, coins, ownedAccessories, savedAt),
    );
    _localChain = write.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Local save queue error: $error\n$stackTrace');
    });
    return write;
  }

  Future<void> _enqueueRemote(String userId, Map<String, dynamic> payload) {
    final write = _remoteChain.then((_) async {
      try {
        await remoteStore.saveRaw(userId, payload);
      } catch (error, stackTrace) {
        debugPrint('Failed to save remote progress: $error\n$stackTrace');
      }
    });
    _remoteChain = write.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Remote save queue error: $error\n$stackTrace');
    });
    return write;
  }

  Future<LoadedSave?> loadCached({String? userId}) async {
    await _localChain;
    final stored = await _loadFromStore(localStore, userId);
    if (stored == null) return null;

    _advancePetToNow(stored.pet, stored.savedAt);
    return (
      pet: stored.pet,
      coins: stored.coins,
      ownedAccessories: stored.ownedAccessories,
    );
  }

  Future<LoadedSave?> load({
    String? userId,
    void Function(Pet pet, int coins, List<String> ownedAccessories)?
    onLocalReady,
  }) async {
    // Flush in-flight local writes so a rename just before logout/login is visible.
    await _localChain;

    if (userId == null || userId.isEmpty) {
      return loadCached(userId: userId);
    }

    final localFuture = _loadFromStore(localStore, userId);
    final remoteFuture = _loadFromStore(remoteStore, userId).then<StoredSave?>(
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

    // Stamp "now" after advancing so the next load does not re-apply elapsed time.
    // Safe because in-flight local saves are flushed at the start of load().
    final syncedAt = DateTime.now();
    unawaited(
      _enqueueLocal(userId, resultPet, resultCoins, resultOwned, syncedAt),
    );

    if (remote != null && identical(stored, local)) {
      final payload = codec.encode(
        resultPet,
        resultCoins,
        resultOwned,
        syncedAt,
      );
      unawaited(_enqueueRemote(userId, payload));
    }

    return (
      pet: resultPet,
      coins: resultCoins,
      ownedAccessories: resultOwned,
    );
  }

  /// Persists progress locally (awaited) and syncs remotely in the background.
  ///
  /// Callers that `await` this (e.g. logout) get a local durability guarantee
  /// without waiting on Firestore.
  Future<void> save(
    Pet pet, {
    required int coins,
    List<String> ownedAccessories = const [],
    String? userId,
  }) {
    final petSnapshot = Pet.fromJson(pet.toJson());
    final coinsSnapshot = coins;
    final ownedSnapshot = List<String>.from(ownedAccessories);
    final savedAt = DateTime.now();
    final saveData = codec.encode(
      petSnapshot,
      coinsSnapshot,
      ownedSnapshot,
      savedAt,
    );

    final localSave = _enqueueLocal(
      userId,
      petSnapshot,
      coinsSnapshot,
      ownedSnapshot,
      savedAt,
    );

    if (userId != null && userId.isNotEmpty) {
      unawaited(_enqueueRemote(userId, saveData));
    }

    return localSave;
  }

  Future<void> delete({String? userId}) async {
    await localStore.delete(userId);
    await remoteStore.delete(userId);
  }
}
