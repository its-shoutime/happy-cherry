import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/app/audio_manager.dart';
import 'package:happy_cherry/core/cherry_catch_logic.dart';
import 'package:happy_cherry/data/game_state.dart';

class CherryCatchGame extends StatefulWidget {
  final String? userId;

  const CherryCatchGame({super.key, this.userId});

  @override
  State<CherryCatchGame> createState() => _CherryCatchGameState();
}

class _CherryCatchGameState extends State<CherryCatchGame> {
  final CherryCatchLogic _logic = CherryCatchLogic();
  final Random random = Random();
  Timer? gameTimer;
  int _highScore = 0;
  bool _isNewHighScore = false;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _restoreAndStart();
  }

  Future<void> _restoreAndStart() async {
    final best = await GameState.loadCherryHighScore(userId: widget.userId);
    if (!mounted) return;
    setState(() => _highScore = best);
    startGame();
  }

  Future<void> _recordScoreIfNeeded() async {
    final previousBest = _highScore;
    final best = await GameState.recordCherryHighScore(
      _logic.score,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _highScore = best;
      _isNewHighScore = _logic.score > previousBest && _logic.score > 0;
    });
  }

  void startGame() {
    gameTimer?.cancel();
    _isNewHighScore = false;

    setState(() {
      _logic.start(
        randomCherryX: () => random.nextDouble() * _logic.maxCherryX,
      );
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_logic.gameOver || _exiting) return;

      setState(() {
        final previousLives = _logic.lives;
        final previousScore = _logic.score;
        _logic.tick(
          randomCherryX: () => random.nextDouble() * _logic.maxCherryX,
        );

        if (_logic.score > previousScore) {
          AudioManager.instance.playCatch();
        } else if (_logic.lives < previousLives) {
          if (_logic.gameOver) {
            gameTimer?.cancel();
            AudioManager.instance.playGameOver();
            unawaited(_recordScoreIfNeeded());
          } else {
            AudioManager.instance.playMiss();
          }
        }
      });
    });
  }

  void moveBasket(DragUpdateDetails details) {
    if (_logic.gameOver || _exiting) return;
    setState(() {
      _logic.moveBasket(details.delta.dx);
    });
  }

  Future<void> _exitWithScore() async {
    if (_exiting) return;
    _exiting = true;
    gameTimer?.cancel();

    if (!_logic.gameOver) {
      setState(() => _logic.cashOut());
      AudioManager.instance.playButton();
      await _recordScoreIfNeeded();
    }

    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, _logic.score);
    }
  }

  Future<void> _confirmExit() async {
    if (_logic.gameOver || _exiting) {
      await _exitWithScore();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundPink,
          title: Text(
            'Cash out?',
            style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
          ),
          content: Text(
            'End the run now and keep your score of ${_logic.score} '
            '(coins + happiness if you scored enough).',
            style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Keep playing',
                style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textDark),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Exit & keep score',
                style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textDark),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      await _exitWithScore();
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmExit());
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPink,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarPink,
          foregroundColor: AppTheme.textDark,
          title: Text(
            'Catch the Cherries',
            style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
          ),
          actions: [
            if (!_logic.gameOver)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PixelButton(
                  logicalWidth: 22,
                  logicalHeight: 10,
                  width: 96,
                  pressChildOffset: const Offset(0, 1),
                  onPressed: _confirmExit,
                  semanticsLabel: 'Exit and keep score',
                  child: Text(
                    'Exit',
                    style: AppTheme.buttonLabel(AppTheme.textDark),
                  ),
                ),
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            _logic.gameWidth = constraints.maxWidth;
            return GestureDetector(
              onHorizontalDragUpdate: moveBasket,
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          'High Score: $_highScore',
                          textAlign: TextAlign.center,
                          style: AppTheme.pixelText(
                            fontSize: 18,
                            color: AppTheme.textDark,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_isNewHighScore)
                          Text(
                            'New personal best!',
                            textAlign: TextAlign.center,
                            style: AppTheme.pixelText(
                              fontSize: 12,
                              color: AppTheme.buttonPressedFill,
                            ),
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 56,
                    left: 20,
                    child: Text(
                      'Score: ${_logic.score}',
                      style: AppTheme.pixelText(
                        fontSize: 22,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 56,
                    right: 20,
                    child: Text(
                      'Lives: ${_logic.lives}',
                      style: AppTheme.pixelText(
                        fontSize: 22,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),

                  if (!_logic.gameOver)
                    for (final cherry in _logic.cherries)
                      Positioned(
                        left: cherry.x,
                        top: cherry.y,
                        child: Image.asset(
                          CherryCatchLogic.cherryAssetPath,
                          width: CherryCatchLogic.cherrySize,
                          height: CherryCatchLogic.cherrySize,
                          filterQuality: FilterQuality.none,
                          fit: BoxFit.contain,
                        ),
                      ),

                  Positioned(
                    left: _logic.basketX,
                    bottom: 40,
                    child: Image.asset(
                      CherryCatchLogic.basketAssetPath,
                      width: CherryCatchLogic.basketWidth,
                      height: CherryCatchLogic.basketHeight,
                      filterQuality: FilterQuality.none,
                      fit: BoxFit.contain,
                    ),
                  ),

                  if (_logic.gameOver && !_exiting)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Game Over!',
                            style: AppTheme.pixelText(
                              fontSize: 32,
                              color: AppTheme.textDark,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Final Score: ${_logic.score}',
                            style: AppTheme.pixelText(
                              fontSize: 22,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (_isNewHighScore)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Personal best!',
                                style: AppTheme.pixelText(
                                  fontSize: 14,
                                  color: AppTheme.buttonPressedFill,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          PixelButton(
                            logicalWidth: 30,
                            logicalHeight: 12,
                            width: 160,
                            pressChildOffset: const Offset(0, 1),
                            onPressed: () {
                              AudioManager.instance.playButton();
                              unawaited(_exitWithScore());
                            },
                            semanticsLabel: 'Home',
                            child: Text(
                              'Home',
                              style: AppTheme.buttonLabel(AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
