import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:happy_cherry/app/audio_manager.dart';
import 'package:happy_cherry/core/cherry_catch_logic.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/core/time_tracker.dart';
import 'package:happy_cherry/data/game_state.dart';

/// Session / load / save / tick / death for the home screen (SRP).
class HomeController extends ChangeNotifier {
  HomeController({required this.userId, required this.onLogout}) {
    pet = Pet(name: 'Mochi');
    timeTracker = PetTimeTracker(pet: pet, onTick: onTick, onDeath: onDeath);
  }

  final String userId;
  final Future<void> Function() onLogout;

  late Pet pet;
  late PetTimeTracker timeTracker;
  int coins = 0;
  Set<String> ownedAccessories = {};
  bool isLoading = true;
  bool loadFailed = false;
  String loadErrorMessage = '';
  bool isHatching = false;
  bool isDead = false;
  bool showFood = false;
  bool showStars = false;
  bool muted = AudioManager.instance.muted;

  Future<void> start() async {
    await loadGame();
    AudioManager.instance.playBgm();
  }

  @override
  void dispose() {
    timeTracker.stop();
    super.dispose();
  }

  Future<void> loadGame() async {
    isLoading = true;
    loadFailed = false;
    loadErrorMessage = '';
    notifyListeners();

    try {
      try {
        await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (error) {
        debugPrint('Auth token warm-up failed: $error');
      }

      final loaded = await GameState.loadPet(userId: userId);
      final fallbackName = await GameState.loadPetName(userId: userId);

      timeTracker.stop();
      if (loaded != null) {
        pet = loaded.pet;
        if ((pet.name.isEmpty || pet.name == 'Mochi') &&
            fallbackName != null &&
            fallbackName.isNotEmpty) {
          pet.name = fallbackName;
        }
        coins = loaded.coins;
        ownedAccessories = {...loaded.ownedAccessories};
        timeTracker = PetTimeTracker(
          pet: pet,
          onTick: onTick,
          onDeath: onDeath,
        );
        timeTracker.start();
        isHatching = false;
      } else {
        pet = Pet(name: 'Mochi');
        ownedAccessories = {};
        timeTracker = PetTimeTracker(
          pet: pet,
          onTick: onTick,
          onDeath: onDeath,
        );
        isHatching = true;
      }
      isLoading = false;
      loadFailed = false;
      loadErrorMessage = '';
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Failed to load progress: $error\n$stackTrace');
      timeTracker.stop();
      isLoading = false;
      loadFailed = true;
      isHatching = false;
      loadErrorMessage = describeLoadError(error);
      notifyListeners();
    }
  }

  String describeLoadError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Cloud save permission was denied. Check Firestore rules, then retry.';
    }
    if (text.contains('unavailable') || text.contains('failed-precondition')) {
      return 'Cloud save is offline or unavailable right now.';
    }
    if (text.contains('network')) {
      return 'Network error while loading your cloud save.';
    }
    return 'Could not reach your cloud save.';
  }

  Future<void> backFromLoadFailure() async {
    AudioManager.instance.playButton();
    timeTracker.stop();
    await onLogout();
  }

  void beginNewBaby({required String name}) {
    timeTracker.stop();
    pet = Pet(name: name);
    isDead = false;
    showFood = false;
    showStars = false;
    isHatching = true;
    timeTracker = PetTimeTracker(pet: pet, onTick: onTick, onDeath: onDeath);
    notifyListeners();
  }

  void onHatchComplete() {
    isHatching = false;
    timeTracker = PetTimeTracker(pet: pet, onTick: onTick, onDeath: onDeath);
    timeTracker.start();
    notifyListeners();
    unawaited(saveProgress());
  }

  Future<void> saveProgress() {
    return GameState.savePet(
      pet,
      coins: coins,
      ownedAccessories: ownedAccessories.toList()..sort(),
      userId: userId,
    );
  }

  Future<void> logout() async {
    timeTracker.stop();
    AudioManager.instance.playButton();
    try {
      await saveProgress().timeout(const Duration(seconds: 3));
    } catch (_) {}
    await onLogout();
  }

  Future<void> toggleMute() async {
    await AudioManager.instance.toggleMute();
    muted = AudioManager.instance.muted;
    notifyListeners();
  }

  void onDeath() {
    AudioManager.instance.pauseBgm();
    AudioManager.instance.playDeath();
    isDead = true;
    notifyListeners();
    unawaited(saveProgress());
  }

  void restartFromDeath() {
    AudioManager.instance.playButton();
    beginNewBaby(name: 'Mochi');
    AudioManager.instance.playBgm();
  }

  void abandonPet() {
    AudioManager.instance.playButton();
    beginNewBaby(name: pet.name);
  }

  void onTick() {
    notifyListeners();
    unawaited(saveProgress());
  }

  Future<void> rename(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == pet.name) return;

    pet.name = trimmed;
    notifyListeners();
    await saveProgress();
    await GameState.savePetName(trimmed, userId: userId);
  }

  void setAccessory(String? accessory) {
    pet.accessory = accessory;
    notifyListeners();
    unawaited(saveProgress());
  }

  void applyPurchase({required int newCoins, required Set<String> owned}) {
    coins = newCoins;
    ownedAccessories = {...owned};
    notifyListeners();
    unawaited(saveProgress());
  }

  void toggleLights({required bool lightsOn}) {
    pet.toggleLights(lightsOn: lightsOn);
    notifyListeners();
    unawaited(saveProgress());
  }

  void onFeed() {
    if (pet.hunger >= Pet.maxStat) return;
    AudioManager.instance.playFeed();
    pet.feed();
    showFood = true;
    notifyListeners();
    unawaited(saveProgress());

    Future.delayed(const Duration(seconds: 2), () {
      showFood = false;
      notifyListeners();
    });
  }

  void onPlayFinished(int? score) {
    AudioManager.instance.playBgm();
    if (score == null) return;

    coins += score;
    if (score > 0) {
      AudioManager.instance.playCoin();
    }
    if (CherryCatchLogic.awardsPlayReward(score)) {
      if (pet.happiness < Pet.maxStat) {
        showStars = true;
      }
      pet.play();
    }
    notifyListeners();
    unawaited(saveProgress());

    if (showStars) {
      Future.delayed(const Duration(seconds: 2), () {
        showStars = false;
        notifyListeners();
      });
    }
  }

  void onCherrySaysFinished(int happinessReward) {
    AudioManager.instance.playBgm();
    if (happinessReward <= 0) return;

    coins += happinessReward;
    AudioManager.instance.playCoin();

    pet.happiness = (pet.happiness + happinessReward).clamp(0.0, Pet.maxStat);
    showStars = true;
    notifyListeners();
    unawaited(saveProgress());

    Future.delayed(const Duration(seconds: 2), () {
      showStars = false;
      notifyListeners();
    });
  }

  void onClean() {
    AudioManager.instance.playClean();
    pet.cleanPoop();
    notifyListeners();
    unawaited(saveProgress());
  }

  void onHeal() {
    AudioManager.instance.playHeal();
    pet.heal();
    notifyListeners();
    unawaited(saveProgress());
  }
}
