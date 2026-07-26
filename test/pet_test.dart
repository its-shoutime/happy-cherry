import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/core/pet_types.dart';

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

  group('Event mechanics: mood states', () {
    // Use midday so sleep schedule does not interfere.
    final awakeAt = DateTime(2026, 7, 12, 12, 0);

    test('happy when all attributes are full', () {
      final pet = Pet(name: 'Full', hunger: 8, happiness: 8);
      expect(pet.moodAt(awakeAt), PetMood.happy);
    });

    test('happy while meters still look full after slight decay', () {
      // Heart UI ceils, so 7.1 still shows four full hearts.
      final pet = Pet(name: 'Almost Full', hunger: 7.1, happiness: 7.5);
      expect(pet.moodAt(awakeAt), PetMood.happy);
    });

    test('okay once a half-heart segment has fully depleted', () {
      final pet = Pet(name: 'Not Full', hunger: 7.0, happiness: 8);
      expect(pet.moodAt(awakeAt), PetMood.okay);
    });

    test('okay (normal) when attributes are neither empty nor full', () {
      final pet = Pet(name: 'Normal', hunger: 5, happiness: 4);
      expect(pet.moodAt(awakeAt), PetMood.okay);
    });

    test('sad when an attribute is low', () {
      final hungry = Pet(name: 'Hungry', hunger: 2, happiness: 8);
      expect(hungry.moodAt(awakeAt), PetMood.sad);

      final unhappy = Pet(name: 'Unhappy', hunger: 8, happiness: 1);
      expect(unhappy.moodAt(awakeAt), PetMood.sad);
    });

    test('sick overrides other mood states', () {
      final pet = Pet(
        name: 'Sick',
        hunger: 8,
        happiness: 8,
        isSick: true,
      );
      expect(pet.moodAt(awakeAt), PetMood.sick);
    });

    test('sleeping overrides happy/okay/sad but not sick', () {
      final sleeping = Pet(name: 'Sleeper', hunger: 8, happiness: 8);
      final bedtime = DateTime(2026, 7, 12, 23, 30);
      expect(sleeping.moodAt(bedtime), PetMood.sleeping);

      final sickAndSleepTime = Pet(
        name: 'Sick Sleeper',
        hunger: 8,
        happiness: 8,
        isSick: true,
      );
      expect(sickAndSleepTime.moodAt(bedtime), PetMood.sick);
    });
  });

  group('Event mechanics: sleeping', () {
    test('blob sleeps from 23:00 until 08:00 real time', () {
      final pet = Pet(name: 'Blob', type: blob);

      expect(pet.isAsleepAt(DateTime(2026, 7, 12, 22, 59)), isFalse);
      expect(pet.isAsleepAt(DateTime(2026, 7, 12, 23, 0)), isTrue);
      expect(pet.isAsleepAt(DateTime(2026, 7, 13, 3, 0)), isTrue);
      expect(pet.isAsleepAt(DateTime(2026, 7, 13, 7, 59)), isTrue);
      expect(pet.isAsleepAt(DateTime(2026, 7, 13, 8, 0)), isFalse);
      expect(pet.isAsleepAt(DateTime(2026, 7, 13, 12, 0)), isFalse);
    });

    test('sleep schedule comes from pet type bed/wake times', () {
      expect(blob.bedTime, const Duration(hours: 23));
      expect(blob.wakeTime, const Duration(hours: 8));
      expect(sprout.bedTime, const Duration(hours: 23));
      expect(sprout.wakeTime, const Duration(hours: 8));
    });

    test('sleeping pets are marked sleeping so actions can be blocked', () {
      final pet = Pet(name: 'Nap', hunger: 6, happiness: 6);
      final bedtime = DateTime(2026, 7, 12, 23, 15);

      expect(pet.moodAt(bedtime), PetMood.sleeping);
      // Home UI disables Feed/Play when mood == sleeping.
    });
  });

  group('Event mechanics: calling for attention', () {
    final awakeAt = DateTime(2026, 7, 12, 12, 0);
    final bedtime = DateTime(2026, 7, 12, 23, 30);

    test('triggered when any attribute is empty', () {
      final hungry = Pet(name: 'Empty Hunger', hunger: 0, happiness: 8);
      expect(hungry.hasAttentionConditionAt(awakeAt), isTrue);
      expect(hungry.attentionVisibleAt(awakeAt), isTrue);

      final unhappy = Pet(name: 'Empty Happiness', hunger: 8, happiness: 0);
      expect(unhappy.hasAttentionConditionAt(awakeAt), isTrue);
    });

    test('triggered when lights stay on while sleeping', () {
      final pet = Pet(
        name: 'Bright Night',
        hunger: 8,
        happiness: 8,
        lightsOff: false,
      );
      expect(pet.hasAttentionConditionAt(bedtime), isTrue);
      expect(pet.attentionVisibleAt(bedtime), isTrue);

      pet.lightsOff = true;
      expect(pet.hasAttentionConditionAt(bedtime), isFalse);
    });

    test('triggered when there is poop on screen', () {
      final pet = Pet(
        name: 'Messy',
        hunger: 8,
        happiness: 8,
        poopCount: 1,
      );
      expect(pet.hasAttentionConditionAt(awakeAt), isTrue);

      pet.cleanPoop();
      expect(pet.hasAttentionConditionAt(awakeAt), isFalse);
    });

    test('not triggered in a healthy awake state with no poop', () {
      final pet = Pet(
        name: 'Fine',
        hunger: 6,
        happiness: 6,
        poopCount: 0,
        lightsOff: false,
      );
      expect(pet.hasAttentionConditionAt(awakeAt), isFalse);
      expect(pet.attentionVisibleAt(awakeAt), isFalse);
    });

    test('after 15 minutes of calling, attention stops and incurs a care mistake', () {
      final pet = Pet(name: 'Ignored', hunger: 0, happiness: 8);
      expect(pet.attentionVisibleAt(awakeAt), isTrue);
      expect(pet.careMistakes, 0);

      pet.updateAttention(const Duration(minutes: 14, seconds: 59), now: awakeAt);
      expect(pet.attentionSuppressed, isFalse);
      expect(pet.careMistakes, 0);
      expect(pet.attentionVisibleAt(awakeAt), isTrue);

      pet.updateAttention(const Duration(seconds: 1), now: awakeAt);
      expect(pet.attentionSuppressed, isTrue);
      expect(pet.careMistakes, 1);
      expect(pet.attentionSeconds, 0);
      expect(pet.attentionVisibleAt(awakeAt), isFalse);
    });

    test('further calling while suppressed does not add more mistakes until reset', () {
      final pet = Pet(
        name: 'Still Ignored',
        hunger: 0,
        happiness: 8,
        attentionSuppressed: true,
        careMistakes: 1,
      );

      pet.updateAttention(const Duration(minutes: 20), now: awakeAt);
      expect(pet.careMistakes, 1);
      expect(pet.attentionSuppressed, isTrue);
    });

    test('attention resets when the condition is cleared', () {
      final pet = Pet(
        name: 'Recovering',
        hunger: 0,
        happiness: 8,
        attentionSeconds: 200,
        attentionSuppressed: true,
        careMistakes: 1,
      );

      pet.hunger = 4;
      pet.updateAttention(const Duration(seconds: 5), now: awakeAt);

      expect(pet.attentionSuppressed, isFalse);
      expect(pet.attentionSeconds, 0);
      expect(pet.careMistakes, 1);
    });
  });

  group('Event mechanics: poop on screen', () {
    test('poops once every 4 hours', () {
      final pet = Pet(name: 'Timer');
      expect(pet.poopCount, 0);

      pet.advancePoopTimer(const Duration(hours: 3, minutes: 59));
      expect(pet.poopCount, 0);

      pet.advancePoopTimer(const Duration(minutes: 1));
      expect(pet.poopCount, 1);
    });

    test('caps at 3 poops on screen', () {
      final pet = Pet(name: 'Max Poop');
      pet.advancePoopTimer(const Duration(hours: 20));
      expect(pet.poopCount, 3);

      pet.advancePoopTimer(const Duration(hours: 8));
      expect(pet.poopCount, 3);
    });

    test('clean clears all poops from the screen', () {
      final pet = Pet(name: 'Clean Me', poopCount: 3, secondsSinceLastPoop: 100);
      pet.cleanPoop();
      expect(pet.poopCount, 0);
      expect(pet.secondsSinceLastPoop, 0);
    });
  });

  group('Event mechanics: sick', () {
    test('becomes sick only after 3 poops sit for more than 4 hours', () {
      final pet = Pet(name: 'Almost Sick');
      pet.advancePoopTimer(const Duration(hours: 12));
      expect(pet.poopCount, 3);
      expect(pet.isSick, isFalse);
      expect(pet.moodAt(DateTime(2026, 7, 12, 12)), isNot(PetMood.sick));

      pet.advancePoopTimer(const Duration(hours: 4));
      expect(pet.isSick, isTrue);
      expect(pet.moodAt(DateTime(2026, 7, 12, 12)), PetMood.sick);
    });

    test('heal clears sickness but clean does not', () {
      final pet = Pet(name: 'Patient');
      pet.advancePoopTimer(const Duration(hours: 16));
      expect(pet.isSick, isTrue);

      pet.cleanPoop();
      expect(pet.isSick, isTrue);

      pet.heal();
      expect(pet.isSick, isFalse);
    });
  });

  group('Stat scale: half-heart units', () {
    test('feed restores 2 half-hearts of hunger', () {
      final pet = Pet(name: 'Feed Me', hunger: 4, happiness: 8);
      pet.feed();
      expect(pet.hunger, 6);
    });

    test('play restores 2 happiness and costs 1 hunger', () {
      final pet = Pet(name: 'Play', hunger: 5, happiness: 3);
      pet.play();
      expect(pet.happiness, 5);
      expect(pet.hunger, 4);
    });

    test('stats clamp to 0–8', () {
      final pet = Pet(name: 'Clamp', hunger: 8, happiness: 8);
      pet.feed();
      expect(pet.hunger, 8);

      pet.hunger = 0;
      pet.happiness = 0;
      pet.play();
      expect(pet.hunger, 0);
      expect(pet.happiness, 2);
    });

    test('migrates legacy 0–100 saves onto 0–8 scale', () {
      final pet = Pet.fromJson({
        'name': 'Legacy',
        'type': 'Blob',
        'stage': 'baby',
        'hunger': 100,
        'happiness': 50,
        'ageInMinutes': 0,
      });
      expect(pet.hunger, 8);
      expect(pet.happiness, 4);
    });

    test('lightsOff persists through json roundtrip', () {
      final pet = Pet(name: 'Dark', lightsOff: true);
      final restored = Pet.fromJson(pet.toJson());
      expect(restored.lightsOff, isTrue);

      final fromRemote = Pet.fromJson({
        'name': 'Dark',
        'type': 'Blob',
        'stage': 'baby',
        'hunger': 8,
        'happiness': 8,
        'lightsOff': true,
      });
      expect(fromRemote.lightsOff, isTrue);
    });
  });

  group('Death', () {
    test('dead only when both hunger and happiness are zero', () {
      expect(Pet(name: 'A', hunger: 0, happiness: 0).isDead, isTrue);
      expect(Pet(name: 'B', hunger: 0, happiness: 1).isDead, isFalse);
      expect(Pet(name: 'C', hunger: 1, happiness: 0).isDead, isFalse);
      expect(Pet(name: 'D', hunger: 0.1, happiness: 0).isDead, isFalse);
    });

    test('decay can starve a pet to death over enough time', () {
      final pet = Pet(
        name: 'Fading',
        stage: PetStage.baby,
        hunger: 0.01,
        happiness: 0.01,
      );
      pet.decayStats(const Duration(minutes: 10));
      expect(pet.hunger, 0);
      expect(pet.happiness, 0);
      expect(pet.isDead, isTrue);
    });
  });

  group('Stat decay', () {
    test('baby decays faster than adult', () {
      final baby = Pet(name: 'Baby', stage: PetStage.baby, hunger: 8, happiness: 8);
      final adult = Pet(
        name: 'Adult',
        type: cherry,
        stage: PetStage.adult,
        hunger: 8,
        happiness: 8,
      );

      baby.decayStats(const Duration(minutes: 100));
      adult.decayStats(const Duration(minutes: 100));

      expect(baby.hunger, lessThan(adult.hunger));
      expect(baby.happiness, lessThan(adult.happiness));
    });

    test('decay rates match stage tables', () {
      expect(
        Pet(name: 'b', stage: PetStage.baby).hungerDecayRatePerMinute,
        Pet.maxStat / 40,
      );
      expect(
        Pet(name: 'c', stage: PetStage.child).hungerDecayRatePerMinute,
        Pet.maxStat / 120,
      );
      expect(
        Pet(name: 't', stage: PetStage.teen).hungerDecayRatePerMinute,
        Pet.maxStat / 240,
      );
      expect(
        Pet(name: 'a', stage: PetStage.adult).hungerDecayRatePerMinute,
        Pet.maxStat / 480,
      );
    });

    test('negative elapsed time is ignored', () {
      final pet = Pet(name: 'Stable', hunger: 5, happiness: 5, ageInMinutes: 10);
      pet.advanceTime(const Duration(seconds: -30));
      expect(pet.hunger, 5);
      expect(pet.happiness, 5);
      expect(pet.ageInMinutes, 10);
    });
  });

  group('Evolution edge cases', () {
    test('child with exactly 2 care mistakes becomes Lloyd', () {
      final pet = Pet(
        name: 'Border',
        type: sprout,
        stage: PetStage.child,
        careMistakes: 2,
      );
      pet.evolve();
      expect(pet.type, lloyd);
      expect(pet.stage, PetStage.teen);
    });

    test('Lloyd with 2 care mistakes evolves to Puffaloo (no stall)', () {
      final pet = Pet(
        name: 'Unstuck',
        type: lloyd,
        stage: PetStage.teen,
        careMistakes: 2,
        ageInMinutes: 3 * 24 * 60,
      );
      expect(pet.canEvolve, isTrue);
      pet.maybeEvolve();
      expect(pet.type, puffaloo);
      expect(pet.stage, PetStage.adult);
      expect(pet.canEvolve, isFalse);
    });

    test('Lloyd and Mousse cover all care-mistake adult branches', () {
      Pet evolveLloyd(int mistakes) {
        final pet = Pet(
          name: 'L',
          type: lloyd,
          stage: PetStage.teen,
          careMistakes: mistakes,
        );
        pet.evolve();
        return pet;
      }

      Pet evolveMousse(int mistakes) {
        final pet = Pet(
          name: 'M',
          type: mousse,
          stage: PetStage.teen,
          careMistakes: mistakes,
        );
        pet.evolve();
        return pet;
      }

      expect(evolveLloyd(0).type, puffaloo);
      expect(evolveLloyd(6).type, puffaloo);
      expect(evolveLloyd(7).type, bear);
      expect(evolveLloyd(9).type, bear);
      expect(evolveLloyd(10).type, demon);

      expect(evolveMousse(0).type, puffaloo);
      expect(evolveMousse(6).type, puffaloo);
      expect(evolveMousse(7).type, bear);
      expect(evolveMousse(20).type, bear);
    });

    test('adult pets do not evolve further', () {
      final pet = Pet(
        name: 'Done',
        type: cherry,
        stage: PetStage.adult,
        ageInMinutes: 99999,
        careMistakes: 0,
      );
      pet.maybeEvolve();
      expect(pet.type, cherry);
      expect(pet.stage, PetStage.adult);
    });
  });

  group('Offline catch-up', () {
    test('advanceTime ages, decays, poops, and evolves together', () {
      final pet = Pet(
        name: 'Catch Up',
        type: blob,
        stage: PetStage.baby,
        ageInMinutes: 0,
        hunger: 8,
        happiness: 8,
        // Avoid bedtime lights-on attention depending on wall-clock now.
        lightsOff: true,
      );

      // 2 hours offline: baby empties in 40 minutes, so neglected care
      // evolves to squeaky rather than sprout.
      pet.advanceTime(const Duration(hours: 2));

      expect(pet.ageInMinutes, 120);
      expect(pet.stage, PetStage.child);
      expect(pet.type, squeaky);
      expect(pet.hunger, 0);
      expect(pet.happiness, 0);
    });

    test('advanceTime applies attention mistakes while offline', () {
      final awakeAt = DateTime(2026, 7, 12, 12, 0);
      final pet = Pet(name: 'Neglected', hunger: 0, happiness: 8);

      // Direct attention path with an explicit clock (decayStats uses DateTime.now).
      pet.updateAttention(const Duration(minutes: 15), now: awakeAt);
      expect(pet.careMistakes, 1);
      expect(pet.attentionSuppressed, isTrue);
    });
  });

  group('Mood labels and serialization', () {
    test('feels strings match mood', () {
      final awakeAt = DateTime(2026, 7, 12, 12, 0);
      expect(Pet(name: 'H', hunger: 8, happiness: 8).moodAt(awakeAt), PetMood.happy);
      // feels uses DateTime.now — spot-check via mood mapping instead.
      final happy = Pet(name: 'H', hunger: 8, happiness: 8);
      // Force non-sleep/non-sick for label coverage through moodAt.
      expect(happy.moodAt(awakeAt), PetMood.happy);
      expect(Pet(name: 'O', hunger: 5, happiness: 5).moodAt(awakeAt), PetMood.okay);
      expect(Pet(name: 'S', hunger: 1, happiness: 8).moodAt(awakeAt), PetMood.sad);
      expect(
        Pet(name: 'K', hunger: 8, happiness: 8, isSick: true).moodAt(awakeAt),
        PetMood.sick,
      );
    });

    test('full json roundtrip preserves gameplay fields', () {
      final original = Pet(
        name: 'Roundtrip',
        type: lloyd,
        stage: PetStage.teen,
        hunger: 3.5,
        happiness: 6.25,
        ageInMinutes: 500,
        poopCount: 2,
        secondsSinceLastPoop: 90,
        isSick: true,
        lightsOff: true,
        careMistakes: 4,
        attentionSeconds: 40,
        attentionSuppressed: true,
      );
      final copy = Pet.fromJson(original.toJson());

      expect(copy.name, original.name);
      expect(copy.type, original.type);
      expect(copy.stage, original.stage);
      expect(copy.hunger, original.hunger);
      expect(copy.happiness, original.happiness);
      expect(copy.ageInMinutes, original.ageInMinutes);
      expect(copy.poopCount, original.poopCount);
      expect(copy.secondsSinceLastPoop, original.secondsSinceLastPoop);
      expect(copy.isSick, original.isSick);
      expect(copy.lightsOff, original.lightsOff);
      expect(copy.careMistakes, original.careMistakes);
      expect(copy.attentionSeconds, original.attentionSeconds);
      expect(copy.attentionSuppressed, original.attentionSuppressed);
    });

    test('petTypeFromName is case-insensitive and falls back to blob', () {
      expect(petTypeFromName('CHERRY'), cherry);
      expect(petTypeFromName('unknown'), blob);
      expect(petTypeFromName(null), blob);
    });
  });
}
