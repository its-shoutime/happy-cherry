import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class CherryTapResult {
  final int score;
  final int happinessReward;
  final int coinReward;

  const CherryTapResult({
    required this.score,
    required this.happinessReward,
    required this.coinReward,
  });
}

class CherryTapGame extends StatefulWidget {
  final void Function(CherryTapResult result)? onGameFinished;

  const CherryTapGame({super.key, this.onGameFinished});

  @override
  State<CherryTapGame> createState() => _CherryTapGameState();
}

class _CherryTapGameState extends State<CherryTapGame> {
  static const int gameDuration = 20;

  final Random _random = Random();

  Timer? _gameTimer;

  int _score = 0;
  int _secondsRemaining = gameDuration;

  bool _gameStarted = false;
  bool _gameFinished = false;

  // Position values are percentages from 0.0 to 1.0.
  double _cherryX = 0.5;
  double _cherryY = 0.5;

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _gameTimer?.cancel();

    setState(() {
      _score = 0;
      _secondsRemaining = gameDuration;
      _gameStarted = true;
      _gameFinished = false;

      _moveCherry();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsRemaining <= 1) {
        timer.cancel();
        _finishGame();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _tapCherry() {
    if (!_gameStarted || _gameFinished) {
      return;
    }

    setState(() {
      _score++;
      _moveCherry();
    });
  }

  void _moveCherry() {
    // Keep the cherry away from the extreme edges.
    _cherryX = 0.05 + (_random.nextDouble() * 0.80);
    _cherryY = 0.05 + (_random.nextDouble() * 0.80);
  }

  void _finishGame() {
    final CherryTapResult result = CherryTapResult(
      score: _score,
      happinessReward: _happinessReward(_score),
      coinReward: _coinReward(_score),
    );

    setState(() {
      _secondsRemaining = 0;
      _gameStarted = false;
      _gameFinished = true;
    });

    widget.onGameFinished?.call(result);
  }

  int _happinessReward(int score) {
    if (score >= 25) {
      return 10;
    }

    if (score >= 15) {
      return 7;
    }

    if (score >= 8) {
      return 4;
    }

    return 2;
  }

  int _coinReward(int score) {
    if (score >= 25) {
      return 10;
    }

    if (score >= 15) {
      return 6;
    }

    if (score >= 8) {
      return 3;
    }

    return 1;
  }

  String _resultMessage() {
    if (_score >= 25) {
      return 'Amazing! Your tapping speed is incredible!';
    }

    if (_score >= 15) {
      return 'Great job! You caught lots of cherries!';
    }

    if (_score >= 8) {
      return 'Nice work! Keep practising!';
    }

    return 'Good try! Let\'s catch more next time!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cherry Tap'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Tap the cherry as many times as possible!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _buildGameInformation(),

              const SizedBox(height: 16),

              Expanded(child: _buildGameArea()),

              const SizedBox(height: 16),

              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameInformation() {
    if (!_gameStarted && !_gameFinished) {
      return const Text(
        'You have 20 seconds. Tap Start when you are ready!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      );
    }

    if (_gameFinished) {
      return Text(
        _resultMessage(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInformationCard(
          icon: Icons.timer,
          label: 'Time',
          value: '$_secondsRemaining',
        ),
        _buildInformationCard(
          icon: Icons.touch_app,
          label: 'Score',
          value: '$_score',
        ),
      ],
    );
  }

  Widget _buildInformationCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.pink.shade600),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cherrySize = 75;

        final double availableWidth = max(0, constraints.maxWidth - cherrySize);

        final double availableHeight = max(
          0,
          constraints.maxHeight - cherrySize,
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.shade200, width: 2),
          ),
          child: Stack(
            children: [
              if (!_gameStarted)
                Center(
                  child: _gameFinished
                      ? _buildFinishedDisplay()
                      : const Text('🍃', style: TextStyle(fontSize: 80)),
                ),

              if (_gameStarted)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  left: _cherryX * availableWidth,
                  top: _cherryY * availableHeight,
                  child: GestureDetector(
                    onTap: _tapCherry,
                    child: Container(
                      width: cherrySize,
                      height: cherrySize,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🍒', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinishedDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🍒', style: TextStyle(fontSize: 70)),
        const SizedBox(height: 12),
        Text(
          'Final Score: $_score',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    if (!_gameStarted && !_gameFinished) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Game'),
        ),
      );
    }

    if (_gameFinished) {
      final int happiness = _happinessReward(_score);
      final int coins = _coinReward(_score);

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$coins Coins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '+$happiness Happiness',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
            ),
          ),
        ],
      );
    }

    return const SizedBox(height: 48);
  }
}
