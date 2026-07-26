import 'package:shared_preferences/shared_preferences.dart';

/// Personal cherry-catch high scores (SRP).
class HighScoreStore {
  static String _key([String? userId]) {
    if (userId == null || userId.isEmpty) {
      return 'cherry_catch_high_score';
    }
    return 'cherry_catch_high_score_${userId.toLowerCase()}';
  }

  Future<int> load({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId)) ?? 0;
  }

  /// Persists [score] when it beats the stored personal best. Returns the best.
  Future<int> record(int score, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(userId);
    final current = prefs.getInt(key) ?? 0;
    if (score > current) {
      await prefs.setInt(key, score);
      return score;
    }
    return current;
  }
}
