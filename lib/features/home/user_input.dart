import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'package:happy_cherry/app/app_theme.dart';

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
    final labelColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.textLight
        : AppTheme.textDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          label: 'Feed',
          labelColor: labelColor,
          onPressed: isSleeping ? null : onFeed,
        ),
        _ActionButton(
          label: 'Play',
          labelColor: labelColor,
          onPressed: isSleeping ? null : onPlay,
        ),
        _ActionButton(
          label: 'Clean',
          labelColor: labelColor,
          onPressed: onClean,
        ),
        _ActionButton(
          label: 'Heal',
          labelColor: labelColor,
          onPressed: canHeal ? onHeal : null,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color labelColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.labelColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PixelButton(
      logicalWidth: 14,
      logicalHeight: 10,
      width: 76,
      pressChildOffset: const Offset(0, 1),
      onPressed: onPressed,
      semanticsLabel: label,
      child: Text(label, style: AppTheme.buttonLabel(labelColor)),
    );
  }
}
