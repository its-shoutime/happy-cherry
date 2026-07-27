import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class CherrySaysGame extends StatefulWidget {
  const CherrySaysGame({super.key});

  @override
  State<CherrySaysGame> createState() => _CherrySaysGameState();
}

class _CherrySaysGameState extends State<CherrySaysGame> {
  final Random _random = Random();

  final List<int> _sequence = [];
  final List<int> _playerInput = [];

  int? _highlightedIndex;
  int _score = 0;

  bool _showingSequence = false;
  bool _gameStarted = false;
  bool _gameOver = false;

  bool _disposed = false;

  static const List<IconData> _icons = [
    Icons.local_florist,
    Icons.star,
    Icons.favorite,
    Icons.park,
  ];

  static const List<String> _labels = ['Flower', 'Star', 'Heart', 'Tree'];

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _startGame() async {
    if (_showingSequence) return;

    setState(() {
      _sequence.clear();
      _playerInput.clear();
      _score = 0;
      _gameOver = false;
      _gameStarted = true;
      _highlightedIndex = null;
    });

    await _startNextRound();
  }

  Future<void> _startNextRound() async {
    if (_disposed) return;

    _sequence.add(_random.nextInt(_icons.length));
    _playerInput.clear();

    await _showSequence();
  }

  Future<void> _showSequence() async {
    if (_disposed) return;

    setState(() {
      _showingSequence = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    for (final index in _sequence) {
      if (_disposed) return;

      setState(() {
        _highlightedIndex = index;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (_disposed) return;

      setState(() {
        _highlightedIndex = null;
      });

      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (_disposed) return;

    setState(() {
      _showingSequence = false;
    });
  }

  Future<void> _handleTap(int index) async {
    if (!_gameStarted || _gameOver || _showingSequence) {
      return;
    }

    final expectedIndex = _sequence[_playerInput.length];

    if (index != expectedIndex) {
      setState(() {
        _gameOver = true;
      });

      return;
    }

    _playerInput.add(index);

    setState(() {
      _highlightedIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (_disposed) return;

    setState(() {
      _highlightedIndex = null;
    });

    if (_playerInput.length == _sequence.length) {
      setState(() {
        _score++;
        _showingSequence = true;
      });

      await Future.delayed(const Duration(milliseconds: 700));

      if (_disposed) return;

      await _startNextRound();
    }
  }

  int _calculateHappinessReward() {
    if (_score <= 0) return 0;
    if (_score >= 10) return 10;
    if (_score >= 6) return 8;
    if (_score >= 3) return 5;
    return 2;
  }

  void _finishGame() {
    final reward = _calculateHappinessReward();
    Navigator.pop(context, reward);
  }

  @override
  Widget build(BuildContext context) {
    final reward = _calculateHappinessReward();

    return Scaffold(
      appBar: AppBar(title: const Text('Cherry Says')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoCard(label: 'Score', value: '$_score'),
                  _InfoCard(label: 'Reward', value: '+$reward happiness'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _statusText(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final highlighted = _highlightedIndex == index;

                    return AnimatedScale(
                      scale: highlighted ? 1.04 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: Material(
                        color: highlighted
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _handleTap(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _icons[index],
                                  size: 38,
                                  color: highlighted
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _labels[index],
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (!_gameStarted)
                FilledButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start game'),
                )
              else if (_gameOver)
                Column(
                  children: [
                    Text(
                      'Game over! You earned +$reward happiness.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _startGame,
                          child: const Text('Play again'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _finishGame,
                          child: const Text('Collect reward'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: _showingSequence ? null : _finishGame,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('End game'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText() {
    if (!_gameStarted) {
      return 'Watch the pattern, then repeat it.';
    }

    if (_gameOver) {
      return 'Oops! That was the wrong symbol.';
    }

    if (_showingSequence) {
      return 'Watch carefully...';
    }

    return 'Your turn!';
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
