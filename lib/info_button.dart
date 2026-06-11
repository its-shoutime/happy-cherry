import 'package:flutter/material.dart';
import 'models/pet.dart';

class InfoButton extends StatelessWidget {
  final Pet pet;

  const InfoButton({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () async {
        final info =
            'Type: ${pet.type.name}\n'
            'Stage: ${pet.stage.name}\n'
            'Age: ${pet.ageInMinutes} mins\n'
            'XP: ${pet.xp}';

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Pet Info'),
            content: Text(info),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
