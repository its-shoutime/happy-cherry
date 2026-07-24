import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'models/pet.dart';

class InfoButton extends StatelessWidget {
  final Pet pet;
  final int coins;
  final bool lightsOff;
  final VoidCallback onAbandon;

  const InfoButton({
    super.key,
    required this.pet,
    required this.coins,
    required this.lightsOff,
    required this.onAbandon,
  });

  Color get _textColor => lightsOff ? AppTheme.textLight : AppTheme.textDark;

  Future<bool> _confirmAbandon(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Abandon ${pet.name}?',
          style: AppTheme.pixelText(fontSize: 20, color: _textColor),
        ),
        content: Text(
          'This will reset pet progress and start over with a new pet. Your coins and owned clothing will be kept.',
          style: AppTheme.pixelText(fontSize: 16, color: _textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTheme.pixelText(fontSize: 14, color: _textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Abandon',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () async {
        final info =
            'Type: ${pet.type.name}\n'
            'Stage: ${pet.stage.name}\n'
            'Age: ${pet.ageInMinutes} mins\n'
            'Coins: $coins';

        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Pet Info',
              style: AppTheme.pixelText(fontSize: 20, color: _textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  info,
                  style: AppTheme.pixelText(fontSize: 16, color: _textColor),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    final confirmed = await _confirmAbandon(dialogContext);
                    if (!confirmed || !dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    onAbandon();
                  },
                  child: const Text(
                    'Abandon Pet',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Close',
                  style: AppTheme.pixelText(fontSize: 14, color: _textColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
