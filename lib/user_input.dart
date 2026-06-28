import 'package:flutter/material.dart';

class UserActions extends StatelessWidget {
  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onClean;
  final VoidCallback onHeal;
  final bool isSleeping;
  final bool canHeal;

  const UserActions({
    super.key,
    required this.onFeed,
    required this.onPlay,
    required this.onClean,
    required this.onHeal,
    this.isSleeping = false,
    this.canHeal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: isSleeping ? null : onFeed,
          child: const Text("Feed"),
        ),
        ElevatedButton(
          onPressed: isSleeping ? null : onPlay,
          child: const Text("Play"),
        ),
        ElevatedButton(
          onPressed: onClean,
          child: const Text("Clean"),
        ),
        ElevatedButton(
          onPressed: canHeal ? onHeal : null,
          child: const Text("Heal"),
        ),
      ],
    );
  }
}
