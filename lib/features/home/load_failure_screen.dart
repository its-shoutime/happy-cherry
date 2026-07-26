import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/app/audio_manager.dart';

/// Retry / back UI when cloud progress fails to load (SRP).
class LoadFailureScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const LoadFailureScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarPink,
        foregroundColor: AppTheme.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to login',
          onPressed: onBack,
        ),
        title: Text(
          'Load failed',
          style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load your progress.',
                  textAlign: TextAlign.center,
                  style: AppTheme.pixelText(
                    fontSize: 20,
                    color: AppTheme.textDark,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage.isEmpty
                      ? 'Check your connection and try again.'
                      : errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTheme.pixelText(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your cloud save was not overwritten.\n'
                  'Retry again, or go back to login.',
                  textAlign: TextAlign.center,
                  style: AppTheme.pixelText(
                    fontSize: 12,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                PixelButton(
                  logicalWidth: 36,
                  logicalHeight: 12,
                  width: 180,
                  pressChildOffset: const Offset(0, 1),
                  onPressed: () {
                    AudioManager.instance.playButton();
                    onRetry();
                  },
                  semanticsLabel: 'Retry',
                  child: Text(
                    'Retry',
                    style: AppTheme.buttonLabel(AppTheme.textDark),
                  ),
                ),
                const SizedBox(height: 12),
                PixelButton(
                  logicalWidth: 36,
                  logicalHeight: 12,
                  width: 180,
                  pressChildOffset: const Offset(0, 1),
                  onPressed: onBack,
                  semanticsLabel: 'Back to login',
                  child: Text(
                    'Back',
                    style: AppTheme.buttonLabel(AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
