import 'dart:async';
import 'package:flutter/material.dart';
import 'models/pet.dart';

class PetTimeTracker {
  final Pet pet;
  final VoidCallback onTick;
  Timer? _timer;
  int _tickCount = 0;

  PetTimeTracker({required this.pet, required this.onTick});

  void start() {
    _tickCount = 0;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      pet.decayStats();
      _tickCount += 1;
      if (_tickCount % 12 == 0) {
        pet.ageInMinutes += 1;
        pet.evolve();
      }
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

}
