import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/models/pet.dart';
import 'package:happy_cherry/models/pet_types.dart';
import 'package:happy_cherry/time_tracker.dart';

void main() {
  group('PetTimeTracker', () {
    test('each tick decays stats', () {
      final pet = Pet(
        name: 'Ticked',
        stage: PetStage.baby,
        hunger: 8,
        happiness: 8,
      );
      var ticks = 0;
      final tracker = PetTimeTracker(pet: pet, onTick: () => ticks++);

      tracker.handleTick();

      expect(ticks, 1);
      expect(pet.hunger, lessThan(8));
      expect(pet.happiness, lessThan(8));
    });

    test('calls onDeath and skips onTick when pet dies', () {
      final pet = Pet(
        name: 'Dying',
        stage: PetStage.baby,
        hunger: 0.0001,
        happiness: 0.0001,
      );
      var died = false;
      var ticks = 0;
      final tracker = PetTimeTracker(
        pet: pet,
        onTick: () => ticks++,
        onDeath: () => died = true,
      );

      tracker.handleTick();

      expect(pet.isDead, isTrue);
      expect(died, isTrue);
      expect(ticks, 0);
    });

    test('ages one minute every 12 ticks and can evolve', () {
      final pet = Pet(
        name: 'Aging',
        type: blob,
        stage: PetStage.baby,
        ageInMinutes: 59,
        hunger: 8,
        happiness: 8,
      );
      final tracker = PetTimeTracker(pet: pet, onTick: () {});

      for (var i = 0; i < 11; i++) {
        tracker.handleTick();
      }
      expect(pet.ageInMinutes, 59);
      expect(pet.stage, PetStage.baby);

      tracker.handleTick(); // 12th tick
      expect(pet.ageInMinutes, 60);
      expect(pet.stage, PetStage.child);
      expect(pet.type, sprout);
    });
  });
}
