import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/cherry_catch_logic.dart';

void main() {
  group('CherryCatchLogic', () {
    test('starts with three lives and a zero score', () {
      final game = CherryCatchLogic(gameWidth: 300);
      game.start(randomCherryX: () => 100);

      expect(game.lives, 3);
      expect(game.score, 0);
      expect(game.gameOver, isFalse);
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

      expect(game.isCatching(), isTrue);
      final reset = game.tick(randomCherryX: () => 40);
      expect(reset, isTrue);
      expect(game.score, 1);
      expect(game.lives, 3);
      expect(game.cherryY, 0);
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
      expect(game.cherryY, 0);
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
      final beforeY = game.cherryY;
      expect(game.tick(randomCherryX: () => 10), isFalse);
      expect(game.cherryY, beforeY);
    });

    test('falling cherries move by fallSpeed each tick', () {
      final game = CherryCatchLogic(cherryY: 0, cherryX: 0, basketX: 200);
      game.tick(randomCherryX: () => 0);
      expect(game.cherryY, CherryCatchLogic.fallSpeed);
    });

    test('play reward threshold matches home screen rule (score > 3)', () {
      expect(CherryCatchLogic.awardsPlayReward(3), isFalse);
      expect(CherryCatchLogic.awardsPlayReward(4), isTrue);
    });
  });
}
