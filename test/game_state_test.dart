import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_cherry/game_state.dart';
import 'package:happy_cherry/models/pet.dart';
import 'package:happy_cherry/models/pet_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Pet makePet({
    String name = 'Mochi',
    double hunger = 8,
    double happiness = 8,
    int ageInMinutes = 0,
    String? accessory,
  }) {
    return Pet(
      name: name,
      type: blob,
      stage: PetStage.baby,
      hunger: hunger,
      happiness: happiness,
      ageInMinutes: ageInMinutes,
      accessory: accessory,
    );
  }

  Future<void> seedLocalSave({
    required String? userId,
    required Pet pet,
    required int coins,
    required DateTime savedAt,
    List<String> ownedAccessories = const [],
  }) async {
    final key = userId == null || userId.isEmpty
        ? 'pet_save'
        : 'pet_save_${userId.toLowerCase()}';
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({
        'pet': pet.toJson(),
        'coins': coins,
        'ownedAccessories': ownedAccessories,
        'savedAt': savedAt.toIso8601String(),
      }),
    });
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameState.debugResetForTest();
    // Default to local-only I/O so tests do not need a Firebase app.
    GameState.debugSaveRemoteOverride = (_, _) async {};
    GameState.debugLoadRemoteOverride = (_) async => null;
  });

  tearDown(() {
    GameState.debugResetForTest();
  });

  group('GameState local progress', () {
    test('savePet and loadCachedPet round-trip pet and coins', () async {
      final pet = makePet(name: 'Bean', ageInMinutes: 12, accessory: 'bow');

      await GameState.savePet(
        pet,
        coins: 37,
        ownedAccessories: const ['bow', 'crown'],
      );

      final loaded = await GameState.loadCachedPet();
      expect(loaded, isNotNull);
      expect(loaded!.coins, 37);
      expect(loaded.pet.name, 'Bean');
      expect(loaded.pet.ageInMinutes, 12);
      expect(loaded.pet.accessory, 'bow');
      expect(loaded.ownedAccessories, ['bow', 'crown']);
    });

    test('owned clothing persists independently of equipped accessory', () async {
      await GameState.savePet(
        makePet(name: 'Dressed', accessory: null),
        coins: 40,
        ownedAccessories: const ['crown', 'scarf'],
      );

      final loaded = await GameState.loadCachedPet();
      expect(loaded!.ownedAccessories, ['crown', 'scarf']);
      expect(loaded.pet.accessory, isNull);
    });

    test('legacy hat id migrates to straw_hat on load', () async {
      await seedLocalSave(
        userId: null,
        pet: makePet(accessory: 'hat'),
        coins: 10,
        ownedAccessories: const ['hat', 'bow'],
        savedAt: DateTime.now(),
      );

      final loaded = await GameState.loadCachedPet();
      expect(loaded!.pet.accessory, 'straw_hat');
      expect(loaded.ownedAccessories, containsAll(['bow', 'straw_hat']));
      expect(loaded.ownedAccessories, isNot(contains('hat')));
    });

    test('progress is isolated per userId', () async {
      await GameState.savePet(makePet(name: 'AlicePet'), coins: 10, userId: 'alice');
      await GameState.savePet(makePet(name: 'BobPet'), coins: 99, userId: 'bob');

      final alice = await GameState.loadCachedPet(userId: 'alice');
      final bob = await GameState.loadCachedPet(userId: 'bob');

      expect(alice!.pet.name, 'AlicePet');
      expect(alice.coins, 10);
      expect(bob!.pet.name, 'BobPet');
      expect(bob.coins, 99);
    });

    test('userId keys are case-insensitive', () async {
      await GameState.savePet(makePet(name: 'Casey'), coins: 5, userId: 'Casey');

      final loaded = await GameState.loadCachedPet(userId: 'casey');
      expect(loaded, isNotNull);
      expect(loaded!.pet.name, 'Casey');
      expect(loaded.coins, 5);
    });

    test('later save overwrites earlier progress for the same user', () async {
      await GameState.savePet(makePet(name: 'V1'), coins: 1, userId: 'u1');
      await GameState.savePet(makePet(name: 'V2'), coins: 2, userId: 'u1');

      final loaded = await GameState.loadCachedPet(userId: 'u1');
      expect(loaded!.pet.name, 'V2');
      expect(loaded.coins, 2);
    });

    test('serialized saves keep order under concurrency', () async {
      final first = GameState.savePet(makePet(name: 'First'), coins: 1);
      final second = GameState.savePet(makePet(name: 'Second'), coins: 2);

      await Future.wait([first, second]);

      final loaded = await GameState.loadCachedPet();
      expect(loaded!.pet.name, 'Second');
      expect(loaded.coins, 2);
    });

    test('deleteSave removes only that user local progress', () async {
      await GameState.savePet(makePet(name: 'Keep'), coins: 3, userId: 'keep');
      await GameState.savePet(makePet(name: 'Drop'), coins: 4, userId: 'drop');

      await GameState.deleteSave(userId: 'drop');

      expect(await GameState.loadCachedPet(userId: 'keep'), isNotNull);
      expect(await GameState.loadCachedPet(userId: 'drop'), isNull);
    });

    test('loadCachedPet advances pet from savedAt', () async {
      await seedLocalSave(
        userId: null,
        pet: makePet(hunger: 8, happiness: 8),
        coins: 0,
        savedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final loaded = await GameState.loadCachedPet();
      expect(loaded, isNotNull);
      expect(loaded!.pet.hunger, lessThan(8));
    });

    test('legacy flat pet json migrates xp into coins', () async {
      SharedPreferences.setMockInitialValues({
        'pet_save': jsonEncode({
          'name': 'Legacy',
          'type': 'blob',
          'stage': 'baby',
          'hunger': 8,
          'happiness': 8,
          'ageInMinutes': 0,
          'xp': 15,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      });

      final loaded = await GameState.loadCachedPet();
      expect(loaded, isNotNull);
      expect(loaded!.pet.name, 'Legacy');
      expect(loaded.coins, 15);
    });

    test('corrupt local save returns null instead of throwing', () async {
      SharedPreferences.setMockInitialValues({'pet_save': '{not-json'});

      expect(await GameState.loadCachedPet(), isNull);
    });
  });

  group('GameState remote fallback', () {
    test('savePet keeps local progress when remote save fails', () async {
      GameState.debugSaveRemoteOverride = (userId, data) async {
        throw StateError('remote unavailable');
      };

      await GameState.savePet(
        makePet(name: 'OfflineHero'),
        coins: 21,
        userId: 'uid-offline',
      );

      final loaded = await GameState.loadCachedPet(userId: 'uid-offline');
      expect(loaded, isNotNull);
      expect(loaded!.pet.name, 'OfflineHero');
      expect(loaded.coins, 21);
    });

    test('loadPet falls back to local when remote load fails', () async {
      await seedLocalSave(
        userId: 'uid-local',
        pet: makePet(name: 'LocalOnly'),
        coins: 44,
        savedAt: DateTime.now(),
      );
      GameState.debugLoadRemoteOverride = (userId) async {
        throw StateError('remote boom');
      };

      final loaded = await GameState.loadPet(userId: 'uid-local');
      expect(loaded, isNotNull);
      expect(loaded!.pet.name, 'LocalOnly');
      expect(loaded.coins, 44);
    });

    test('loadPet starts fresh when remote fails and local is empty', () async {
      GameState.debugLoadRemoteOverride = (userId) async {
        throw StateError('remote boom');
      };

      final loaded = await GameState.loadPet(userId: 'uid-empty');
      expect(loaded, isNull);
    });

    test('loadPet prefers newer remote save over local', () async {
      final older = DateTime.now().subtract(const Duration(days: 1));
      final newer = DateTime.now();

      await seedLocalSave(
        userId: 'uid-merge',
        pet: makePet(name: 'OldLocal'),
        coins: 1,
        savedAt: older,
      );

      GameState.debugLoadRemoteOverride = (userId) async {
        return (
          pet: makePet(name: 'NewRemote'),
          coins: 88,
          ownedAccessories: const <String>['hat'],
          savedAt: newer,
        );
      };

      final loaded = await GameState.loadPet(userId: 'uid-merge');
      expect(loaded!.pet.name, 'NewRemote');
      expect(loaded.coins, 88);
    });

    test('loadPet prefers newer local save over remote', () async {
      final older = DateTime.now().subtract(const Duration(days: 1));
      final newer = DateTime.now();

      await seedLocalSave(
        userId: 'uid-merge-2',
        pet: makePet(name: 'NewLocal'),
        coins: 55,
        savedAt: newer,
      );

      GameState.debugLoadRemoteOverride = (userId) async {
        return (
          pet: makePet(name: 'OldRemote'),
          coins: 3,
          ownedAccessories: const <String>[],
          savedAt: older,
        );
      };

      final loaded = await GameState.loadPet(userId: 'uid-merge-2');
      expect(loaded!.pet.name, 'NewLocal');
      expect(loaded.coins, 55);
    });

    test('loadPet onLocalReady receives local preview before remote', () async {
      await seedLocalSave(
        userId: 'uid-preview',
        pet: makePet(name: 'Preview'),
        coins: 7,
        savedAt: DateTime.now(),
      );

      final remoteCompleter = Future<StoredSave?>.delayed(
        const Duration(milliseconds: 30),
        () => (
          pet: makePet(name: 'Remote'),
          coins: 9,
          ownedAccessories: const <String>['bow'],
          savedAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
      GameState.debugLoadRemoteOverride = (_) => remoteCompleter;

      String? previewName;
      int? previewCoins;
      final loaded = await GameState.loadPet(
        userId: 'uid-preview',
        onLocalReady: (pet, coins, owned) {
          previewName = pet.name;
          previewCoins = coins;
        },
      );

      expect(previewName, 'Preview');
      expect(previewCoins, 7);
      expect(loaded!.pet.name, 'Remote');
      expect(loaded.coins, 9);
    });
  });

  group('GameState auth helpers', () {
    test('firebaseEmailForUsername normalizes username emails', () {
      expect(
        GameState.firebaseEmailForUsername('  Cherry '),
        'cherry@happy-cherry.app',
      );
      expect(
        GameState.firebaseEmailForUsername('Owner@Email.com'),
        'owner@email.com',
      );
    });

    test('last logged in user persists', () async {
      await GameState.saveLastLoggedInUser('Mochi');
      expect(await GameState.loadLastLoggedInUser(), 'mochi');

      await GameState.clearLastLoggedInUser();
      expect(await GameState.loadLastLoggedInUser(), isNull);
    });

    test('cherry high score is personal per user', () async {
      expect(await GameState.loadCherryHighScore(userId: 'alice'), 0);

      expect(
        await GameState.recordCherryHighScore(12, userId: 'alice'),
        12,
      );
      expect(
        await GameState.recordCherryHighScore(8, userId: 'alice'),
        12,
      );
      expect(
        await GameState.recordCherryHighScore(20, userId: 'alice'),
        20,
      );

      expect(await GameState.loadCherryHighScore(userId: 'bob'), 0);
      expect(await GameState.loadCherryHighScore(userId: 'alice'), 20);
    });
  });
}
