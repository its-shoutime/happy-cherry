import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'audio_manager.dart';
import 'cherry_catch_logic.dart';

class CherryCatchGame extends StatefulWidget {
  const CherryCatchGame({super.key});

  @override
  State<CherryCatchGame> createState() => _CherryCatchGameState();
}

class _CherryCatchGameState extends State<CherryCatchGame> {
  final CherryCatchLogic _logic = CherryCatchLogic();
  final Random random = Random();
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _restoreAndStart();
  }

  Future<void> _restoreAndStart() async {
    // Keep home BGM going softly under the minigame.
    startGame();
  }

  Future<void> _saveGameState() async {
    // Chrome users keep local persistence in the pet state only.
  }

  void startGame() {
    gameTimer?.cancel();

    setState(() {
      _logic.start(
        randomCherryX: () => random.nextDouble() * _logic.maxCherryX,
      );
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_logic.gameOver) return;

      setState(() {
        final previousLives = _logic.lives;
        final previousScore = _logic.score;
        _logic.tick(
          randomCherryX: () => random.nextDouble() * _logic.maxCherryX,
        );

        if (_logic.score > previousScore) {
          AudioManager.instance.playCatch();
          _saveGameState();
        } else if (_logic.lives < previousLives) {
          _saveGameState();
          if (_logic.gameOver) {
            gameTimer?.cancel();
            AudioManager.instance.playGameOver();
          } else {
            AudioManager.instance.playMiss();
          }
        }
      });
    });
  }

  void moveBasket(DragUpdateDetails details) {
    setState(() {
      _logic.moveBasket(details.delta.dx);
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _saveGameState();
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
          _logic.gameWidth = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: moveBasket,
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Score: ${_logic.score}',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                Positioned(
                  top: 20,
                  right: 20,
                  child: Text(
                    'Lives: ${_logic.lives}',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                if (!_logic.gameOver)
                  Positioned(
                    left: _logic.cherryX,
                    top: _logic.cherryY,
                    child: const Text(
                      '🍒',
                      style: TextStyle(fontSize: CherryCatchLogic.cherrySize),
                    ),
                  ),

                Positioned(
                  left: _logic.basketX,
                  bottom: 40,
                  child: const Text('🧺', style: TextStyle(fontSize: 70)),
                ),

                if (_logic.gameOver)
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
                          'Final Score: ${_logic.score}',
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            AudioManager.instance.playButton();
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context, _logic.score);
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
