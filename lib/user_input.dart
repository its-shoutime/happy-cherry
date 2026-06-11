import 'package:flutter/material.dart';

class UserActions extends StatelessWidget {
  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final bool isSleeping;

  const UserActions({
    super.key,
    required this.onFeed,
    required this.onPlay,
    this.isSleeping = false,
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
      ],
    );
  }
}
