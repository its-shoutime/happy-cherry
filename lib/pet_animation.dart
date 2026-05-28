import 'package:flutter/material.dart';
import 'models/pet.dart';

class PetGraphic extends StatelessWidget {
  final Pet pet;
  final double height;

  const PetGraphic({super.key, required this.pet, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Image.asset(pet.assetPath, height: height, fit: BoxFit.contain);
  }
}
