import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class CherryMemoryResult {
  final int score;
  final int happinessReward;
  final int coinReward;

  const CherryMemoryResult({
    required this.score,
    required this.happinessReward,
    required this.coinReward,
  });
}

class CherryMemoryGame extends StatefulWidget {
  final void Function(CherryMemoryResult result)? onGameFinished;

  const CherryMemoryGame({super.key, this.onGameFinished});

  @override
  State<CherryMemoryGame> createState() => _CherryMemoryGameState();
}

class _CherryMemoryGameState extends State<CherryMemoryGame> {
  static const int gridSize = 3;
  static const int totalTiles = gridSize * gridSize;
  static const int cherryCount = 3;

  final Random _random = Random();

  Set<int> _cherryPositions = {};
  Set<int> _selectedPositions = {};

  bool _showingCherries = false;
  bool _roundFinished = false;
  bool _gameStarted = false;

  int _score = 0;
  int _secondsRemaining = 3;

  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _countdownTimer?.cancel();

    final Set<int> positions = {};

    while (positions.length < cherryCount) {
      positions.add(_random.nextInt(totalTiles));
    }

    setState(() {
      _cherryPositions = positions;
      _selectedPositions = {};
      _showingCherries = true;
      _roundFinished = false;
      _gameStarted = true;
      _score = 0;
      _secondsRemaining = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();

        if (!mounted) return;

        setState(() {
          _secondsRemaining = 0;
          _showingCherries = false;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _selectTile(int index) {
    if (!_gameStarted || _showingCherries || _roundFinished) {
      return;
    }

    if (_selectedPositions.contains(index)) {
      return;
    }

    setState(() {
      _selectedPositions.add(index);

      if (_selectedPositions.length == cherryCount) {
        _finishRound();
      }
    });
  }

  void _finishRound() {
    int correctSelections = 0;

    for (final index in _selectedPositions) {
      if (_cherryPositions.contains(index)) {
        correctSelections++;
      }
    }

    final reward = CherryMemoryResult(
      score: correctSelections,
      happinessReward: _happinessReward(correctSelections),
      coinReward: _coinReward(correctSelections),
    );

    setState(() {
      _score = correctSelections;
      _roundFinished = true;
    });

    widget.onGameFinished?.call(reward);
  }

  void _playAgain() {
    _startGame();
  }

  String _resultMessage() {
    if (_score == cherryCount) {
      return 'Perfect! You remembered every cherry!';
    }

    if (_score == cherryCount - 1) {
      return 'So close! You found $_score cherries.';
    }

    return 'You found $_score out of $cherryCount cherries.';
  }

  int _happinessReward(int score) {
    if (score == cherryCount) {
      return 5;
    }

    if (score == cherryCount - 1) {
      return 8;
    }

    return 3;
  }

  int _coinReward(int score) {
    if (score == cherryCount) {
      return 1;
    }

    if (score == cherryCount - 1) {
      return 5;
    }

    return 2;
  }

  Color _tileColor(int index) {
    if (_showingCherries && _cherryPositions.contains(index)) {
      return Colors.pink.shade100;
    }

    if (_roundFinished) {
      final bool isCherry = _cherryPositions.contains(index);
      final bool wasSelected = _selectedPositions.contains(index);

      if (isCherry && wasSelected) {
        return Colors.green.shade200;
      }

      if (!isCherry && wasSelected) {
        return Colors.red.shade200;
      }

      if (isCherry) {
        return Colors.amber.shade200;
      }
    }

    if (_selectedPositions.contains(index)) {
      return Colors.pink.shade200;
    }

    return Colors.green.shade100;
  }

  Widget _tileContent(int index) {
    if (_showingCherries && _cherryPositions.contains(index)) {
      return const Text('🍒', style: TextStyle(fontSize: 40));
    }

    if (_roundFinished) {
      if (_cherryPositions.contains(index)) {
        return const Text('🍒', style: TextStyle(fontSize: 40));
      }

      if (_selectedPositions.contains(index)) {
        return const Icon(Icons.close, size: 38, color: Colors.red);
      }
    }

    if (_selectedPositions.contains(index)) {
      return const Icon(Icons.check, size: 38, color: Colors.white);
    }

    return const Text('🍃', style: TextStyle(fontSize: 36));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cherry Memory'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Remember where the cherries are hiding!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInstructionText(),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalTiles,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _selectTile(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: _tileColor(index),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.pink.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  key: ValueKey(
                                    '${index}_${_showingCherries}_${_roundFinished}_${_selectedPositions.contains(index)}',
                                  ),
                                  child: _tileContent(index),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    if (!_gameStarted) {
      return const Text(
        'Press Start. You will have 3 seconds to memorise the cherries.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      );
    }

    if (_showingCherries) {
      return Text(
        'Memorise them! $_secondsRemaining',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      );
    }

    if (_roundFinished) {
      return Text(
        _resultMessage(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      );
    }

    return Text(
      'Choose $cherryCount tiles '
      '(${_selectedPositions.length}/$cherryCount selected)',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildBottomSection() {
    if (!_gameStarted) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Game'),
        ),
      );
    }

    if (_roundFinished) {
      final happiness = _happinessReward(_score);
      final coins = _coinReward(_score);
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
              onPressed: _playAgain,
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
