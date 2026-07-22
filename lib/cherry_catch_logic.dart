/// Pure rules for the Catch the Cherries minigame (testable without widgets).
class CherryCatchLogic {
  static const double cherrySize = 45.0;
  static const double basketWidth = 70.0;
  static const double fallSpeed = 5.0;
  static const double catchY = 560.0;
  static const double missY = 650.0;
  static const double catchLeftPad = 30.0;
  static const double catchRightPad = 90.0;
  static const int startingLives = 3;
  static const int playRewardScoreThreshold = 3;

  double cherryX;
  double cherryY;
  double basketX;
  double gameWidth;
  int score;
  int lives;
  bool gameOver;

  CherryCatchLogic({
    this.cherryX = 150,
    this.cherryY = 0,
    this.basketX = 150,
    this.gameWidth = 300,
    this.score = 0,
    this.lives = startingLives,
    this.gameOver = false,
  });

  double get maxCherryX {
    final max = gameWidth - cherrySize;
    return max < 0 ? 0 : max;
  }

  double get maxBasketX {
    final max = gameWidth - basketWidth;
    return max < 0 ? 0 : max;
  }

  void start({double Function()? randomCherryX}) {
    score = 0;
    lives = startingLives;
    gameOver = false;
    cherryY = 0;
    cherryX = randomCherryX?.call() ?? 0;
    if (cherryX > maxCherryX) cherryX = maxCherryX;
    basketX = gameWidth / 2;
    if (basketX > maxBasketX) basketX = maxBasketX;
  }

  void moveBasket(double deltaX) {
    basketX += deltaX;
    if (basketX < 0) basketX = 0;
    if (basketX > maxBasketX) basketX = maxBasketX;
  }

  bool isCatching() {
    return cherryY > catchY &&
        cherryX > basketX - catchLeftPad &&
        cherryX < basketX + catchRightPad;
  }

  bool isMissed() => cherryY > missY;

  /// Advance one physics tick. Returns true if the cherry was reset.
  bool tick({double Function()? randomCherryX}) {
    if (gameOver) return false;

    cherryY += fallSpeed;

    if (isMissed()) {
      lives--;
      _resetCherry(randomCherryX);
      if (lives <= 0) {
        gameOver = true;
      }
      return true;
    }

    if (isCatching()) {
      score++;
      _resetCherry(randomCherryX);
      return true;
    }

    return false;
  }

  void _resetCherry(double Function()? randomCherryX) {
    cherryY = 0;
    cherryX = randomCherryX?.call() ?? 0;
    if (cherryX > maxCherryX) cherryX = maxCherryX;
  }

  /// Home screen applies [Pet.play] when the returned score clears this bar.
  static bool awardsPlayReward(int finalScore) =>
      finalScore > playRewardScoreThreshold;
}
