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
      onPressed: () async {
        final controller = TextEditingController(text: pet.name);
        final result = await showDialog<String?>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("Rename Pet"),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: "New Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, controller.text);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
        if (result != null && result.isNotEmpty) {
          onRename(result);
        }
        controller.dispose();
      },
    );
  }
}
