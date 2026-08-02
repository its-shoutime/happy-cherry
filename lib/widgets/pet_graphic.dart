import 'dart:math';

import 'package:flutter/material.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/core/room_decorations.dart';
import 'package:happy_cherry/widgets/accessory_graphic.dart';

class PetGraphic extends StatelessWidget {
  final Pet pet;
  final double height;
  final bool showFood;
  final bool showStars;
  final String? foodId;

  /// Optional preview override so callers need not clone the pet (LoD).
  final String? accessoryOverride;

  const PetGraphic({
    super.key,
    required this.pet,
    this.height = 200,
    this.showFood = false,
    this.showStars = false,
    this.foodId,
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
              // Room decoration displayed completely outside/beside the pet so it's not blocked at all
              if (pet.roomDecoration != null &&
                  pet.roomDecoration!.isNotEmpty) ...[
                Positioned(
                  left: max(0.0, (maxWidth / 2) - (height * 0.70)),
                  bottom: height * 0.10,
                  child: Text(
                    RoomDecorationCatalog.emojiFor(pet.roomDecoration),
                    style: TextStyle(fontSize: height * 0.25),
                  ),
                ),
                Positioned(
                  right: max(0.0, (maxWidth / 2) - (height * 0.70)),
                  bottom: height * 0.10,
                  child: Text(
                    RoomDecorationCatalog.emojiFor(pet.roomDecoration),
                    style: TextStyle(fontSize: height * 0.25),
                  ),
                ),
              ],

              Image.asset(pet.assetPath, height: height, fit: BoxFit.contain),

              // Natural cloud thought bubble with tail dots above character (positioned on top-right)
              Positioned(
                top: 0,
                right: max(0.0, (maxWidth / 2) - (height * 0.70)),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: height * 0.08,
                        vertical: height * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.pink.shade200,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _thoughtText(pet),
                        style: TextStyle(
                          fontSize: height * 0.10,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink.shade900,
                        ),
                      ),
                    ),
                    // Small trailing thought circles pointing down towards the pet
                    Positioned(
                      left: height * 0.06,
                      bottom: -8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.pink.shade200,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: height * 0.03,
                      bottom: -15,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.pink.shade200,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (accessory != null && accessory.isNotEmpty)
                Positioned(
                  top: height * 0.08,
                  child: AccessoryGraphic(
                    accessoryId: accessory,
                    size: height * 0.28,
                  ),
                ),

              // Attention notification icon positioned top-left to avoid thought bubble overlap
              if (pet.attentionVisible)
                Positioned(
                  top: 0,
                  left: max(0.0, (maxWidth / 2) - (height * 0.55)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade300, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notification_important,
                      color: Colors.red,
                      size: height * 0.18,
                    ),
                  ),
                ),

              // stars effect when playing
              if (showStars)
                for (var i = 0; i < 15; i++)
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
              // Food icons shown briefly when feeding:
              // - a restaurant icon near the pet center-bottom so it looks like
              //   the pet is eating
              // - a hamburger icon to the pet's right
              if (showFood) ...[
                // centered restaurant plate/icon (appears at the pet's feet)
                Positioned(
                  left: max(0.0, (maxWidth - height * 0.16) / 2),
                  bottom: height * 0.04,
                  child: Text(
                    _foodEmoji(foodId),
                    style: TextStyle(fontSize: height * 0.16),
                  ),
                ),

                // hamburger icon positioned to the right of the pet so it's "next to" it
                Positioned(
                  left: min(
                    maxWidth - height * 0.16,
                    maxWidth / 2 + height * 0.38,
                  ),
                  bottom: height * 0.06,
                  child: Text(
                    _foodEmoji(foodId),
                    style: TextStyle(fontSize: height * 0.12),
                  ),
                ),
              ],

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

  String _thoughtText(Pet pet) {
    if (pet.isSick) {
      return '🤒 Need medicine...';
    }
    if (pet.isAsleep) {
      return '💤 zzz...';
    }
    if (pet.hunger <= 2 && pet.happiness <= 2) {
      return '🍔 Need food & fun!';
    }
    if (pet.hunger <= 2) {
      return '🍔 I\'m hungry!';
    }
    if (pet.happiness <= 2) {
      return '🎾 Let\'s play!';
    }
    if (pet.poopCount > 0) {
      return '💩 Clean please!';
    }
    if (pet.hunger >= Pet.maxStat && pet.happiness >= Pet.maxStat) {
      return '✨ Feeling great!';
    }
    return '💭 Content ~';
  }

  String _foodEmoji(String? foodId) {
    switch (foodId) {
      case 'apple':
        return '🍎';
      case 'cookie':
        return '🍪';
      case 'cake':
        return '🍰';
      case 'berry':
        return '🫐';
      default:
        return '🍽️';
    }
  }
}
