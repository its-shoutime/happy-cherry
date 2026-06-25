import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class CherryCatchGame extends StatefulWidget {
  const CherryCatchGame({super.key});

  @override
  State<CherryCatchGame> createState() => _CherryCatchGameState();
}

class _CherryCatchGameState extends State<CherryCatchGame> {
  static const double cherrySize = 45.0;
  static const double basketWidth = 70.0;

  double cherryX = 150;
  double cherryY = 0;
  double basketX = 150;
  double gameWidth = 300;

  int score = 0;
  int lives = 3;

  bool gameOver = false;
  Timer? gameTimer;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  double get maxCherryX => max(gameWidth - cherrySize, 0);
  double get maxBasketX => max(gameWidth - basketWidth, 0);

  void startGame() {
    gameTimer?.cancel();

    setState(() {
      score = 0;
      lives = 1;
      gameOver = false;
      cherryY = 0;
      cherryX = random.nextDouble() * maxCherryX;
      basketX = gameWidth / 2;
      if (basketX > maxBasketX) {
        basketX = maxBasketX;
      }
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (gameOver) return;

      setState(() {
        cherryY += 5;

        if (cherryY > 650) {
          lives--;
          resetCherry();
        }

        if (cherryY > 560 && cherryX > basketX - 30 && cherryX < basketX + 90) {
          score++;
          resetCherry();
        }

        if (lives <= 0) {
          gameOver = true;
          gameTimer?.cancel();
        }
      });
    });
  }

  void resetCherry() {
    cherryY = 0;
    cherryX = random.nextDouble() * maxCherryX;
  }

  void moveBasket(DragUpdateDetails details) {
    setState(() {
      basketX += details.delta.dx;

      if (basketX < 0) {
        basketX = 0;
      }

      if (basketX > maxBasketX) {
        basketX = maxBasketX;
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text('Catch the Cherries 🍒'),
        backgroundColor: Colors.pink[200],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          gameWidth = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: moveBasket,
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Score: $score',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                Positioned(
                  top: 20,
                  right: 20,
                  child: Text(
                    'Lives: $lives',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                if (!gameOver)
                  Positioned(
                    left: cherryX,
                    top: cherryY,
                    child: const Text('🍒', style: TextStyle(fontSize: 45)),
                  ),

                Positioned(
                  left: basketX,
                  bottom: 40,
                  child: const Text('🧺', style: TextStyle(fontSize: 70)),
                ),

                if (gameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Game Over!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Final Score: $score',
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context, score);
                            }
                          },
                          child: const Text('Home'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
