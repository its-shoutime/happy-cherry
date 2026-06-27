import 'package:flutter/material.dart';

class DeathScreen extends StatelessWidget {
  final VoidCallback onRestart;

  const DeathScreen({super.key, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your pet has died")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Your pet has died. Please restart the game.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRestart, child: const Text("Restart")),
          ],
        ),
      ),
    );
  }
}
