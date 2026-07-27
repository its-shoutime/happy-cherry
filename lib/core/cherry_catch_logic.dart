/// Pure rules for the Catch the Cherries minigame (testable without widgets).
class FallingCherry {
  double x;
  double y;

  FallingCherry({required this.x, this.y = 0});
}

class CherryCatchLogic {
  static const String cherryAssetPath = 'assets/minigame/cherry.png';
  static const String basketAssetPath = 'assets/minigame/basket.png';
  static const double cherrySize = 45.0;
  static const double basketWidth = 70.0;
  static const double basketHeight = 70.0;
  static const double baseFallSpeed = 5.0;
  static const double fallSpeedPerPoint = 0.35;
  static const double maxFallSpeed = 16.0;
  static const double catchY = 560.0;
  static const double missY = 650.0;
  static const double catchLeftPad = 30.0;
  static const double catchRightPad = 90.0;
  static const int startingLives = 1;
  static const int playRewardScoreThreshold = 3;

  /// Extra cherry every N points, up to [maxActiveCherries].
  static const int scorePerExtraCherry = 5;
  static const int maxActiveCherries = 5;
  static const double cherrySpawnStagger = 140.0;

  /// Legacy alias used by older call sites / docs.
  static const double fallSpeed = baseFallSpeed;

  final List<FallingCherry> cherries = [];
  double basketX;
  double gameWidth;
  int score;
  int lives;
  bool gameOver;

  CherryCatchLogic({
    double cherryX = 150,
    double cherryY = 0,
    this.basketX = 150,
    this.gameWidth = 300,
    this.score = 0,
    this.lives = startingLives,
    this.gameOver = false,
    List<FallingCherry>? initialCherries,
  }) {
    if (initialCherries != null) {
      cherries.addAll(initialCherries);
    } else {
      cherries.add(FallingCherry(x: cherryX, y: cherryY));
    }
  }

  /// Fall speed ramps with score so longer runs get harder.
  double get currentFallSpeed {
    final speed = baseFallSpeed + score * fallSpeedPerPoint;
    if (speed > maxFallSpeed) return maxFallSpeed;
    return speed;
  }

  /// How many cherries should be on screen for the current score.
  int get targetCherryCount {
    final count = 1 + score ~/ scorePerExtraCherry;
    if (count > maxActiveCherries) return maxActiveCherries;
    return count;
  }

  double get maxCherryX {
    final max = gameWidth - cherrySize;
    return max < 0 ? 0 : max;
  }

  double get maxBasketX {
    final max = gameWidth - basketWidth;
    return max < 0 ? 0 : max;
  }

  /// Convenience for single-cherry tests / legacy callers.
  double get cherryX => cherries.isEmpty ? 0 : cherries.first.x;
  double get cherryY => cherries.isEmpty ? 0 : cherries.first.y;

  void start({double Function()? randomCherryX}) {
    score = 0;
    lives = startingLives;
    gameOver = false;
    cherries
      ..clear()
      ..add(_spawnCherry(randomCherryX, y: 0));
    basketX = gameWidth / 2;
    if (basketX > maxBasketX) basketX = maxBasketX;
  }

  void moveBasket(double deltaX) {
    basketX += deltaX;
    if (basketX < 0) basketX = 0;
    if (basketX > maxBasketX) basketX = maxBasketX;
  }

  bool isCatchingCherry(FallingCherry cherry) {
    return cherry.y > catchY &&
        cherry.x > basketX - catchLeftPad &&
        cherry.x < basketX + catchRightPad;
  }

  bool isMissedCherry(FallingCherry cherry) => cherry.y > missY;

  /// End the run early while keeping the current score for rewards.
  void cashOut() {
    gameOver = true;
  }

  /// Advance one physics tick. Returns true if any cherry was caught or missed.
  bool tick({double Function()? randomCherryX}) {
    if (gameOver) return false;

    var changed = false;
    final speed = currentFallSpeed;

    for (final cherry in cherries) {
      cherry.y += speed;
    }

    final remaining = <FallingCherry>[];
    for (final cherry in cherries) {
      if (isMissedCherry(cherry)) {
        lives--;
        changed = true;
        if (lives <= 0) {
          gameOver = true;
        }
        continue;
      }

      if (isCatchingCherry(cherry)) {
        score++;
        changed = true;
        continue;
      }

      remaining.add(cherry);
    }

    cherries
      ..clear()
      ..addAll(remaining);

    if (!gameOver) {
      _ensureCherryCount(randomCherryX);
    }

    return changed;
  }

  void _ensureCherryCount(double Function()? randomCherryX) {
    while (cherries.length < targetCherryCount) {
      final stagger = cherries.length * cherrySpawnStagger;
      cherries.add(_spawnCherry(randomCherryX, y: -stagger));
    }
  }

  FallingCherry _spawnCherry(double Function()? randomCherryX, {double y = 0}) {
    var x = randomCherryX?.call() ?? 0;
    if (x > maxCherryX) x = maxCherryX;
    if (x < 0) x = 0;
    return FallingCherry(x: x, y: y);
  }

  /// Home screen applies [Pet.play] when the returned score clears this bar.
  static bool awardsPlayReward(int finalScore) =>
      finalScore > playRewardScoreThreshold;
}
