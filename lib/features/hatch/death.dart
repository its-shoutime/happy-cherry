import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'package:happy_cherry/app/app_theme.dart';

class DeathScreen extends StatelessWidget {
  final VoidCallback onRestart;

  const DeathScreen({super.key, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your pet has died',
          style: AppTheme.pixelText(fontSize: 20, color: AppTheme.textDark),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your pet has died. Please restart the game.',
              style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PixelButton(
              logicalWidth: 30,
              logicalHeight: 12,
              width: 180,
              pressChildOffset: const Offset(0, 1),
              onPressed: onRestart,
              semanticsLabel: 'Restart',
              child: Text(
                'Restart',
                style: AppTheme.buttonLabel(AppTheme.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
