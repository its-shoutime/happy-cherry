import 'dart:math';

import 'package:flutter/material.dart';

import 'package:happy_cherry/widgets/accessory_graphic.dart';
import 'package:happy_cherry/core/pet.dart';

class PetGraphic extends StatelessWidget {
  final Pet pet;
  final double height;
  final bool showFood;
  final bool showStars;
  /// Optional preview override so callers need not clone the pet (LoD).
  final String? accessoryOverride;

  const PetGraphic({
    super.key,
    required this.pet,
    this.height = 200,
    this.showFood = false,
    this.showStars = false,
    this.accessoryOverride,
  });

  @override
  Widget build(BuildContext context) {
    final accessory = accessoryOverride ?? pet.accessory;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // Use a seed so positions change predictably when pet state changes
        final seed =
            pet.poopCount * 9973 +
            pet.secondsSinceLastPoop * 7 +
            pet.ageInMinutes;
        final rand = Random(seed);

        return SizedBox(
          width: maxWidth,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pet image centered
              Image.asset(pet.assetPath, height: height, fit: BoxFit.contain),

              if (accessory != null && accessory.isNotEmpty)
                Positioned(
                  top: height * 0.08,
                  child: AccessoryGraphic(
                    accessoryId: accessory,
                    size: height * 0.28,
                  ),
                ),

              if (pet.attentionVisible)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: height * 0.02),
                    child: Icon(
                      Icons.notification_important,
                      color: Colors.red,
                      size: height * 0.18,
                    ),
                  ),
                ),

              // stars effect when playing
              if (showStars)
                for (var i = 0; i < 6; i++)
                  Positioned(
                    left:
                        rand.nextDouble() * max(0.0, maxWidth - (height * 0.1)),
                    top: max(0.0, rand.nextDouble() * (height * 0.35)),
                    child: Transform.rotate(
                      angle: (rand.nextDouble() - 0.5) * 0.8,
                      child: Icon(
                        Icons.star,
                        color: Colors.yellowAccent,
                        size: height * 0.12,
                      ),
                    ),
                  ),

              // Poop overlays scattered within the same vertical bounds as the pet image
              // Food icon shown briefly when feeding
              if (showFood)
                Positioned(
                  left: max(
                    0.0,
                    min(maxWidth - height * 0.16, maxWidth * 0.55),
                  ),
                  top: max(0.0, min(height - height * 0.16, height * 0.45)),
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.orangeAccent,
                    size: height * 0.16,
                  ),
                ),

              // poop positions clamped to available area
              for (var i = 0; i < pet.poopCount; i++)
                Positioned(
                  left:
                      rand.nextDouble() * max(0.0, maxWidth - (height * 0.15)),
                  top: max(
                    0.0,
                    min(
                      height - height * 0.15,
                      (height * 0.1) + rand.nextDouble() * (height * 0.6),
                    ),
                  ),
                  child: Transform.rotate(
                    angle: (rand.nextDouble() - 0.5) * 0.6,
                    child: Text(
                      '💩',
                      style: TextStyle(fontSize: height * 0.15),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
