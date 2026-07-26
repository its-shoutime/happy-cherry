import 'dart:async';
import 'package:happy_cherry/core/pet.dart';

class PetTimeTracker {
  final Pet pet;
  final void Function() onTick;
  final void Function()? onDeath;
  final Duration tickInterval;
  Timer? _timer;
  int _tickCount = 0;

  PetTimeTracker({
    required this.pet,
    required this.onTick,
    this.onDeath,
    this.tickInterval = const Duration(seconds: 5),
  });

  void start() {
    _tickCount = 0;
    _timer = Timer.periodic(tickInterval, (_) => handleTick());
  }

  /// One simulation step — also used by tests without waiting on a Timer.
  void handleTick() {
    pet.decayStats();
    if (pet.isDead) {
      stop();
      onDeath?.call();
      return;
    }

    _tickCount += 1;
    if (_tickCount % 12 == 0) {
      pet.ageInMinutes += 1;
      pet.maybeEvolve();
    }
    onTick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
