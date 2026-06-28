import 'dart:async';
import 'package:flutter/material.dart';
import 'models/pet.dart';

class PetTimeTracker {
  final Pet pet;
  final VoidCallback onTick;
  final VoidCallback? onDeath;
  Timer? _timer;
  int _tickCount = 0;

  PetTimeTracker({required this.pet, required this.onTick, this.onDeath});

  void start() {
    _tickCount = 0;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      pet.decayStats();
      if (pet.isDead) {
        stop();
        if (onDeath != null) onDeath!();
        return;
      }

      _tickCount += 1;
      if (_tickCount % 12 == 0) {
        pet.ageInMinutes += 1;
        pet.maybeEvolve();
      }
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
