import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/core/cherry_catch_logic.dart';

void main() {
  group('CherryCatchLogic', () {
    test('starts with three lives and a zero score', () {
      final game = CherryCatchLogic(gameWidth: 300);
      game.start(randomCherryX: () => 100);

      expect(game.lives, 3);
      expect(game.score, 0);
      expect(game.gameOver, isFalse);
      expect(game.cherries, hasLength(1));
      expect(game.cherryY, 0);
      expect(game.basketX, 150);
    });

    test('basket movement clamps to playfield edges', () {
      final game = CherryCatchLogic(gameWidth: 300, basketX: 0);
      game.moveBasket(-20);
      expect(game.basketX, 0);

      game.moveBasket(1000);
      expect(game.basketX, game.maxBasketX);
    });

    test('catching a cherry increments score and resets height', () {
      final game = CherryCatchLogic(
        gameWidth: 300,
        basketX: 100,
        cherryX: 100,
        cherryY: CherryCatchLogic.catchY + 1,
      );

      expect(game.isCatchingCherry(game.cherries.first), isTrue);
      final reset = game.tick(randomCherryX: () => 40);
      expect(reset, isTrue);
      expect(game.score, 1);
      expect(game.lives, 3);
      expect(game.cherries, isNotEmpty);
      expect(game.cherryY, lessThanOrEqualTo(0));
      expect(game.cherryX, 40);
    });

    test('missing a cherry costs a life', () {
      final game = CherryCatchLogic(
        gameWidth: 300,
        basketX: 0,
        cherryX: 250,
        cherryY: CherryCatchLogic.missY,
      );

      // One more tick pushes past missY.
      game.tick(randomCherryX: () => 10);
      expect(game.lives, 2);
      expect(game.score, 0);
      expect(game.cherries, isNotEmpty);
      expect(game.gameOver, isFalse);
    });

    test('losing all lives ends the game', () {
      final game = CherryCatchLogic(
        gameWidth: 300,
        lives: 1,
        basketX: 0,
        cherryX: 250,
        cherryY: CherryCatchLogic.missY,
      );

      game.tick(randomCherryX: () => 10);
      expect(game.lives, 0);
      expect(game.gameOver, isTrue);

      // Further ticks are no-ops while game over.
      final beforeCount = game.cherries.length;
      expect(game.tick(randomCherryX: () => 10), isFalse);
      expect(game.cherries, hasLength(beforeCount));
    });

    test('falling cherries move by currentFallSpeed each tick', () {
      final game = CherryCatchLogic(cherryY: 0, cherryX: 0, basketX: 200);
      game.tick(randomCherryX: () => 0);
      expect(game.cherryY, CherryCatchLogic.baseFallSpeed);
    });

    test('fall speed increases with score and caps at max', () {
      final game = CherryCatchLogic(score: 0);
      expect(game.currentFallSpeed, CherryCatchLogic.baseFallSpeed);

      game.score = 10;
      expect(
        game.currentFallSpeed,
        CherryCatchLogic.baseFallSpeed + 10 * CherryCatchLogic.fallSpeedPerPoint,
      );

      game.score = 1000;
      expect(game.currentFallSpeed, CherryCatchLogic.maxFallSpeed);
    });

    test('active cherry count rises with score', () {
      final game = CherryCatchLogic(gameWidth: 300);
      game.start(randomCherryX: () => 50);
      expect(game.targetCherryCount, 1);
      expect(game.cherries, hasLength(1));

      game.score = CherryCatchLogic.scorePerExtraCherry;
      game.tick(randomCherryX: () => 80);
      expect(game.targetCherryCount, 2);
      expect(game.cherries, hasLength(2));

      game.score = CherryCatchLogic.scorePerExtraCherry * 10;
      game.tick(randomCherryX: () => 20);
      expect(game.targetCherryCount, CherryCatchLogic.maxActiveCherries);
      expect(game.cherries, hasLength(CherryCatchLogic.maxActiveCherries));
    });

    test('cashOut ends the run without changing score or lives', () {
      final game = CherryCatchLogic(score: 7, lives: 2);
      game.cashOut();

      expect(game.gameOver, isTrue);
      expect(game.score, 7);
      expect(game.lives, 2);
      expect(game.tick(randomCherryX: () => 0), isFalse);
    });

    test('play reward threshold matches home screen rule (score > 3)', () {
      expect(CherryCatchLogic.awardsPlayReward(3), isFalse);
      expect(CherryCatchLogic.awardsPlayReward(4), isTrue);
    });
  });
}
