import 'package:flutter/material.dart';

class UserActions extends StatelessWidget {
  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onSleep;

  const UserActions({
    super.key,
    required this.onFeed,
    required this.onPlay,
    required this.onSleep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: onFeed, child: const Text("Feed")),
        ElevatedButton(onPressed: onPlay, child: const Text("Play")),
        ElevatedButton(onPressed: onSleep, child: const Text("Sleep")),
      ],
    );
  }
}
