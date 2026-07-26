import 'package:flutter/material.dart';

import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/core/pet.dart';

TextStyle homePixelBodyText(
  Pet pet,
  double fontSize, {
  FontWeight? fontWeight,
}) {
  final bodyTextColor =
      pet.lightsOff ? AppTheme.textLight : AppTheme.textDark;
  return AppTheme.pixelText(
    fontSize: fontSize,
    color: bodyTextColor,
    shadowColor: pet.lightsOff ? const Color(0x80000000) : null,
  ).copyWith(fontWeight: fontWeight);
}

/// Hunger / happiness heart row (SRP).
class HeartMeter extends StatelessWidget {
  final String label;
  final double value;
  final Pet pet;

  const HeartMeter({
    super.key,
    required this.label,
    required this.value,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    // 1 unit = half a heart. Use ceil so a segment stays filled until that
    // whole half-heart has been lost (avoids dropping immediately after refill).
    final halfHearts = value <= 0
        ? 0
        : value.ceil().clamp(0, Pet.maxStat.toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: homePixelBodyText(pet, 18)),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final unitsInHeart = (halfHearts - index * 2).clamp(0, 2);
            if (unitsInHeart >= 2) {
              return const Icon(Icons.favorite, color: Colors.red, size: 28);
            }
            if (unitsInHeart >= 1) {
              return const _HalfHeart();
            }
            return const Icon(
              Icons.favorite_border,
              color: Colors.red,
              size: 28,
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _HalfHeart extends StatelessWidget {
  const _HalfHeart();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        const Icon(Icons.favorite_border, color: Colors.red, size: 28),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 0.5,
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          ),
        ),
      ],
    );
  }
}

/// Low-stat attention banner (SRP).
class AttentionIndicator extends StatelessWidget {
  final Pet pet;

  const AttentionIndicator({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final lowHearts = pet.hunger <= 4 || pet.happiness <= 4;
    final bodyTextColor =
        pet.lightsOff ? AppTheme.textLight : AppTheme.textDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lowHearts) ...[
          const Icon(Icons.notification_important, color: Colors.red, size: 30),
          const SizedBox(width: 8),
        ],
        Text(
          lowHearts ? 'Attention needed' : 'All good!',
          style: homePixelBodyText(
            pet,
            16,
            fontWeight: FontWeight.bold,
          ).copyWith(color: lowHearts ? Colors.red : bodyTextColor),
        ),
      ],
    );
  }
}

/// Lights switch that talks to [Pet.toggleLights] (LoD) (SRP).
class LightsControl extends StatelessWidget {
  final Pet pet;
  final ValueChanged<bool> onLightsChanged;

  const LightsControl({
    super.key,
    required this.pet,
    required this.onLightsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Lights', style: homePixelBodyText(pet, 16)),
        Switch(
          value: !pet.lightsOff,
          onChanged: onLightsChanged,
        ),
      ],
    );
  }
}
