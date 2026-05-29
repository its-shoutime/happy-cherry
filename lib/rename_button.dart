import 'package:flutter/material.dart';
import 'models/pet.dart';

class RenameButton extends StatelessWidget {
  final Pet pet;
  final ValueChanged<String> onRename;

  const RenameButton({super.key, required this.pet, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) {
            String newName = pet.name;
            return AlertDialog(
              title: const Text("Rename Pet"),
              content: TextField(
                onChanged: (value) => newName = value,
                controller: TextEditingController(text: pet.name),
                decoration: const InputDecoration(labelText: "New Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    onRename(newName);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
