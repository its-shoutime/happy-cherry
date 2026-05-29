import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/pet.dart';

class GameState {
  static const String _petKey = 'pet_save';

  static Future<Pet?> loadPet() async {
    final prefs = await SharedPreferences.getInstance();
    final petJson = prefs.getString(_petKey);

    if (petJson == null) return null;

    try {
      final decoded = jsonDecode(petJson) as Map<String, dynamic>;
      final savedAt = decoded['savedAt'] as String?;
      final savedPet = decoded['pet'] as Map<String, dynamic>?;

      final pet = savedPet != null
          ? Pet.fromJson(savedPet)
          : Pet.fromJson(decoded);

      if (savedAt != null) {
        final lastSaved = DateTime.tryParse(savedAt) ?? DateTime.now();
        final elapsed = DateTime.now().difference(lastSaved);
        if (elapsed > Duration.zero) {
          pet.advanceTime(elapsed);
        }
      }

      return pet;
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePet(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    final saveData = {
      'pet': pet.toJson(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_petKey, jsonEncode(saveData));
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_petKey);
  }
}
