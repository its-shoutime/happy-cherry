import 'dart:math';

import 'package:flutter/material.dart';

import 'models/pet.dart';

class PetGraphic extends StatelessWidget {
  final Pet pet;
  final double height;

  const PetGraphic({super.key, required this.pet, this.height = 200});

  @override
  Widget build(BuildContext context) {
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

              // Poop overlays scattered within the same vertical bounds as the pet image
              for (var i = 0; i < pet.poopCount; i++)
                Positioned(
                  left: rand.nextDouble() * (maxWidth - (height * 0.15)),
                  top: (height * 0.1) + rand.nextDouble() * (height * 0.6),
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
