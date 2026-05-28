import 'dart:async';
import 'package:flutter/material.dart';
import 'models/pet.dart';

class PetTimeTracker {
  final Pet pet;
  final VoidCallback onTick;
  Timer? _timer;

  PetTimeTracker({required this.pet, required this.onTick});

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      pet.decayStats();
      onTick();
    });

    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      pet.ageInMinutes += 1;
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
