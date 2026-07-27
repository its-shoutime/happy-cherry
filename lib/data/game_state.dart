import 'package:flutter/foundation.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/data/auth_service.dart';
import 'package:happy_cherry/data/high_score_store.dart';
import 'package:happy_cherry/data/local_save_store.dart';
import 'package:happy_cherry/data/progress_codec.dart';
import 'package:happy_cherry/data/remote_save_store.dart';
import 'package:happy_cherry/data/save_models.dart';
import 'package:happy_cherry/data/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:happy_cherry/data/save_models.dart';

/// Thin static facade over focused data services (keeps call sites stable).
class GameState {
  static final ProgressCodec _codec = ProgressCodec();
  static final RemoteSaveStore _remote = RemoteSaveStore();
  static final LocalSaveStore _local = LocalSaveStore(codec: _codec);
  static final SaveRepository _repository = SaveRepository(
    localStore: _local,
    remoteStore: _remote,
    codec: _codec,
  );
  static final AuthService _auth = AuthService();
  static final HighScoreStore _highScores = HighScoreStore();

  static Future<StoredSave?> Function(String userId)? _loadOverride;

  /// Test-only hooks so progress tests can exercise remote merge without Firebase.
  @visibleForTesting
  static Future<StoredSave?> Function(String userId)?
  get debugLoadRemoteOverride => _loadOverride;

  @visibleForTesting
  static set debugLoadRemoteOverride(
    Future<StoredSave?> Function(String userId)? value,
  ) {
    _loadOverride = value;
    _remote.loadOverride = value == null
        ? null
        : (userId) async {
            final stored = await value(userId);
            if (stored == null) return null;
            return _codec.encode(
              stored.pet,
              stored.coins,
              stored.ownedAccessories,
              stored.savedAt,
            );
          };
  }

  @visibleForTesting
  static Future<void> Function(String userId, Map<String, dynamic> data)?
  get debugSaveRemoteOverride => _remote.saveOverride;

  @visibleForTesting
  static set debugSaveRemoteOverride(
    Future<void> Function(String userId, Map<String, dynamic> data)? value,
  ) {
    _remote.saveOverride = value;
  }

  @visibleForTesting
  static void debugResetForTest() {
    _repository.resetSaveChain();
    debugLoadRemoteOverride = null;
    debugSaveRemoteOverride = null;
  }

  static String firebaseEmailForUsername(String username) =>
      _auth.emailForUsername(username);

  static Future<void> saveLastLoggedInUser(String username) =>
      _auth.saveLastLoggedInUser(username);

  static Future<String?> loadLastLoggedInUser() => _auth.loadLastLoggedInUser();

  static Future<void> clearLastLoggedInUser() => _auth.clearLastLoggedInUser();

  static String _petNameKey(String? userId) {
    if (userId == null || userId.isEmpty) {
      return 'pet_name';
    }
    return 'pet_name_${userId.toLowerCase()}';
  }

  static Future<void> savePetName(String name, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petNameKey(userId), name);
  }

  static Future<String?> loadPetName({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_petNameKey(userId));
  }

  static Future<LoadedSave?> loadCachedPet({String? userId}) =>
      _repository.loadCached(userId: userId);

  static Future<LoadedSave?> loadPet({
    String? userId,
    void Function(Pet pet, int coins, List<String> ownedAccessories)?
    onLocalReady,
  }) => _repository.load(userId: userId, onLocalReady: onLocalReady);

  static Future<void> savePet(
    Pet pet, {
    required int coins,
    List<String> ownedAccessories = const [],
    String? userId,
  }) => _repository.save(
    pet,
    coins: coins,
    ownedAccessories: ownedAccessories,
    userId: userId,
  );

  static Future<bool> loginUser(String username, String password) =>
      _auth.login(username, password);

  static Future<bool> registerUser(String username, String password) =>
      _auth.register(username, password);

  static Future<void> deleteSave({String? userId}) =>
      _repository.delete(userId: userId);

  static Future<int> loadCherryHighScore({String? userId}) =>
      _highScores.load(userId: userId);

  static Future<int> recordCherryHighScore(int score, {String? userId}) =>
      _highScores.record(score, userId: userId);
}
