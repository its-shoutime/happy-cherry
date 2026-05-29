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
      return Pet.fromJson(decoded);
    } catch (e) {
      print('Error loading pet: $e');
      return null;
    }
  }

  static Future<void> savePet(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    final petJson = jsonEncode(pet.toJson());
    await prefs.setString(_petKey, petJson);
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_petKey);
  }
}
