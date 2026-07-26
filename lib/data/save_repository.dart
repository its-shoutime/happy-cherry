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

  /// Serializes saves so an older in-flight write cannot overwrite a newer one.
  Future<void> _saveChain = Future<void>.value();

  void resetSaveChain() {
    _saveChain = Future<void>.value();
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

  Future<LoadedSave?> loadCached({String? userId}) async {
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

    final syncedAt = DateTime.now();
    unawaited(
      _writeLocal(userId, resultPet, resultCoins, resultOwned, syncedAt),
    );

    if (remote != null && identical(stored, local)) {
      final payload = codec.encode(
        resultPet,
        resultCoins,
        resultOwned,
        syncedAt,
      );
      unawaited(
        remoteStore.saveRaw(userId, payload).catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint('Failed to sync remote save: $error\n$stackTrace');
        }),
      );
    }

    return (
      pet: resultPet,
      coins: resultCoins,
      ownedAccessories: resultOwned,
    );
  }

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

    final save = _saveChain.then((_) async {
      final saveData = codec.encode(
        petSnapshot,
        coinsSnapshot,
        ownedSnapshot,
        savedAt,
      );

      await _writeLocal(
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
        await remoteStore.saveRaw(userId, saveData);
      } catch (error, stackTrace) {
        debugPrint('Failed to save remote progress: $error\n$stackTrace');
      }
    });

    _saveChain = save.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Save queue error: $error\n$stackTrace');
    });

    return save;
  }

  Future<void> delete({String? userId}) async {
    await localStore.delete(userId);
    await remoteStore.delete(userId);
  }
}
