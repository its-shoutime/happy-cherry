import 'package:flutter/foundation.dart';

import 'package:happy_cherry/core/accessories.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/data/save_models.dart';

/// Encodes/decodes save payloads and applies legacy migrations (SRP).
class ProgressCodec {
  DateTime? parseSavedAt(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, dynamic>? readPetJson(Map<String, dynamic> decoded) {
    final pet = decoded['pet'];
    if (pet is Map<String, dynamic>) {
      return pet;
    }
    if (pet is Map) {
      return Map<String, dynamic>.from(pet);
    }
    if (decoded.containsKey('name')) {
      return decoded;
    }
    return null;
  }

  int readCoins(Map<String, dynamic> decoded, Map<String, dynamic> petJson) {
    final accountCoins = (decoded['coins'] as num?)?.toInt();
    if (accountCoins != null) {
      return accountCoins;
    }
    // Migrate legacy pet XP into account coins once.
    return (petJson['xp'] as num?)?.toInt() ?? 0;
  }

  List<String> readOwnedAccessories(Map<String, dynamic> decoded, Pet pet) {
    final owned = <String>{};
    final raw = decoded['ownedAccessories'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.isNotEmpty) {
          owned.add(item);
        }
      }
    }
    final equipped = pet.accessory;
    if (equipped != null && equipped.isNotEmpty) {
      owned.add(equipped);
    }
    return AccessoryCatalog.canonicalizeOwned(owned);
  }

  StoredSave? decode(Map<String, dynamic> decoded) {
    try {
      final petJson = readPetJson(decoded);
      if (petJson == null) return null;

      final pet = Pet.fromJson(petJson);
      final coins = readCoins(decoded, petJson);
      final ownedAccessories = readOwnedAccessories(decoded, pet);
      if (pet.accessory != null && pet.accessory!.isNotEmpty) {
        pet.accessory = AccessoryCatalog.canonicalizeId(pet.accessory!);
      }
      final savedAt = parseSavedAt(decoded['savedAt'] as String?) ?? DateTime.now();
      return (
        pet: pet,
        coins: coins,
        ownedAccessories: ownedAccessories,
        savedAt: savedAt,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to decode pet save: $error\n$stackTrace');
      return null;
    }
  }

  Map<String, dynamic> encode(
    Pet pet,
    int coins,
    List<String> ownedAccessories,
    DateTime savedAt,
  ) {
    return {
      'pet': pet.toJson(),
      'coins': coins,
      'ownedAccessories': ownedAccessories,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
