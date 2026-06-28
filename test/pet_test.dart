import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/models/pet.dart';
import 'package:happy_cherry/models/pet_types.dart';

void main() {
  group('Pet.evolve', () {
    test('baby pets evolve to sprout with no mistakes or squeaky otherwise', () {
      final goodBaby = Pet(
        name: 'Good Baby',
        type: blob,
        stage: PetStage.baby,
        careMistakes: 0,
      );
      goodBaby.evolve();

      expect(goodBaby.type, sprout);
      expect(goodBaby.stage, PetStage.child);

      final badBaby = Pet(
        name: 'Bad Baby',
        type: blob,
        stage: PetStage.baby,
        careMistakes: 1,
      );
      badBaby.evolve();

      expect(badBaby.type, squeaky);
      expect(badBaby.stage, PetStage.child);
    });

    test('child pets evolve based on care mistake thresholds', () {
      final lowMistakeChild = Pet(
        name: 'Low Mistake Child',
        type: sprout,
        stage: PetStage.child,
        careMistakes: 1,
      );
      lowMistakeChild.evolve();
      expect(lowMistakeChild.type, starfruit);

      final midMistakeChild = Pet(
        name: 'Mid Mistake Child',
        type: squeaky,
        stage: PetStage.child,
        careMistakes: 3,
      );
      midMistakeChild.evolve();
      expect(midMistakeChild.type, mousse);

      final highMistakeChild = Pet(
        name: 'High Mistake Child',
        type: sprout,
        stage: PetStage.child,
        careMistakes: 5,
      );
      highMistakeChild.evolve();
      expect(highMistakeChild.type, lloyd);
    });

    test('teen pets evolve into the correct adult forms', () {
      final starfruitTeen = Pet(
        name: 'Starfruit Teen',
        type: starfruit,
        stage: PetStage.teen,
        careMistakes: 0,
      );
      starfruitTeen.evolve();
      expect(starfruitTeen.type, cherry);

      final flowerTeen = Pet(
        name: 'Flower Teen',
        type: starfruit,
        stage: PetStage.teen,
        careMistakes: 2,
      );
      flowerTeen.evolve();
      expect(flowerTeen.type, flower);

      final angelTeen = Pet(
        name: 'Angel Teen',
        type: starfruit,
        stage: PetStage.teen,
        careMistakes: 4,
      );
      angelTeen.evolve();
      expect(angelTeen.type, angel);

      final demonTeen = Pet(
        name: 'Demon Teen',
        type: lloyd,
        stage: PetStage.teen,
        careMistakes: 10,
      );
      demonTeen.evolve();
      expect(demonTeen.type, demon);

      final puffalooTeen = Pet(
        name: 'Puffaloo Teen',
        type: mousse,
        stage: PetStage.teen,
        careMistakes: 4,
      );
      puffalooTeen.evolve();
      expect(puffalooTeen.type, puffaloo);

      final bearTeen = Pet(
        name: 'Bear Teen',
        type: lloyd,
        stage: PetStage.teen,
        careMistakes: 8,
      );
      bearTeen.evolve();
      expect(bearTeen.type, bear);
    });
  });

  group('Pet.maybeEvolve', () {
    test('does not evolve before the required real-time age', () {
      final baby = Pet(
        name: 'Young Baby',
        type: blob,
        stage: PetStage.baby,
        ageInMinutes: 59,
      );
      baby.maybeEvolve();
      expect(baby.stage, PetStage.baby);
      expect(baby.type, blob);

      final child = Pet(
        name: 'Young Child',
        type: sprout,
        stage: PetStage.child,
        ageInMinutes: 60 + 60,
      );
      child.maybeEvolve();
      expect(child.stage, PetStage.child);

      final teen = Pet(
        name: 'Young Teen',
        type: starfruit,
        stage: PetStage.teen,
        ageInMinutes: 24 * 60 + 60,
      );
      teen.maybeEvolve();
      expect(teen.stage, PetStage.teen);
    });

    test('evolves once age thresholds are reached', () {
      final baby = Pet(
        name: 'Ready Baby',
        type: blob,
        stage: PetStage.baby,
        ageInMinutes: 60,
      );
      baby.maybeEvolve();
      expect(baby.stage, PetStage.child);
      expect(baby.type, sprout);

      final child = Pet(
        name: 'Ready Child',
        type: sprout,
        stage: PetStage.child,
        ageInMinutes: 24 * 60,
      );
      child.maybeEvolve();
      expect(child.stage, PetStage.teen);
      expect(child.type, starfruit);

      final teen = Pet(
        name: 'Ready Teen',
        type: starfruit,
        stage: PetStage.teen,
        ageInMinutes: 3 * 24 * 60,
      );
      teen.maybeEvolve();
      expect(teen.stage, PetStage.adult);
      expect(teen.type, cherry);
    });

    test('advanceTime does not evolve on immediate reload', () {
      final baby = Pet(
        name: 'Fresh Baby',
        type: blob,
        stage: PetStage.baby,
        ageInMinutes: 10,
      );
      baby.advanceTime(Duration.zero);
      expect(baby.stage, PetStage.baby);
      expect(baby.ageInMinutes, 10);
    });

    test('catches up through multiple stages after long absence', () {
      final baby = Pet(
        name: 'Absent Baby',
        type: blob,
        stage: PetStage.baby,
        ageInMinutes: 3 * 24 * 60,
      );
      baby.maybeEvolve();
      expect(baby.stage, PetStage.adult);
      expect(baby.type, cherry);
    });
  });

  group('Pet.advancePoopTimer', () {
    test('adds a poop every 4 hours', () {
      final pet = Pet(name: 'Poop Test');
      pet.advancePoopTimer(const Duration(hours: 4));
      expect(pet.poopCount, 1);
      expect(pet.isSick, false);

      pet.advancePoopTimer(const Duration(hours: 4));
      expect(pet.poopCount, 2);
      expect(pet.isSick, false);
    });

    test('only becomes sick after 3 poops sit for 4 hours', () {
      final pet = Pet(name: 'Poop Test');
      pet.advancePoopTimer(const Duration(hours: 12));
      expect(pet.poopCount, 3);
      expect(pet.isSick, false);

      pet.advancePoopTimer(const Duration(hours: 3, minutes: 59));
      expect(pet.isSick, false);

      pet.advancePoopTimer(const Duration(minutes: 1));
      expect(pet.isSick, true);
    });

    test('cleaning poops does not clear sickness', () {
      final pet = Pet(name: 'Poop Test');
      pet.advancePoopTimer(const Duration(hours: 16));
      expect(pet.isSick, true);

      pet.cleanPoop();
      expect(pet.poopCount, 0);
      expect(pet.isSick, true);
    });
  });
}
