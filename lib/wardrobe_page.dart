import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'app_theme.dart';
import 'models/pet.dart';
import 'pet_animation.dart';

class WardrobePage extends StatefulWidget {
  final Pet pet;
  final ValueChanged<String?> onAccessorySelected;

  const WardrobePage({
    super.key,
    required this.pet,
    required this.onAccessorySelected,
  });

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  late String? _selectedAccessory = widget.pet.accessory;

  final List<_AccessoryOption> _options = const [
    _AccessoryOption(
      id: null,
      label: 'None',
      emoji: '✨',
      description: 'Default look',
    ),
    _AccessoryOption(
      id: 'hat',
      label: 'Hat',
      emoji: '🎩',
      description: 'A tiny topper',
    ),
    _AccessoryOption(
      id: 'bow',
      label: 'Bow',
      emoji: '🎀',
      description: 'Cute and bright',
    ),
    _AccessoryOption(
      id: 'glasses',
      label: 'Glasses',
      emoji: '🕶️',
      description: 'Cool and clever',
    ),
    _AccessoryOption(
      id: 'crown',
      label: 'Crown',
      emoji: '👑',
      description: 'Royal style',
    ),
    _AccessoryOption(
      id: 'scarf',
      label: 'Scarf',
      emoji: '🧣',
      description: 'Warm and cozy',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final previewPet = Pet.fromJson(widget.pet.toJson())
      ..accessory = _selectedAccessory;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarPink,
        foregroundColor: AppTheme.textDark,
        title: Text(
          'Wardrobe',
          style: AppTheme.pixelText(fontSize: 20, color: AppTheme.textDark),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Choose an accessory',
              style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PetGraphic(pet: previewPet, height: 220),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: _options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final selected = _selectedAccessory == option.id;

                  return GestureDetector(
                    onTap: () => _selectAccessory(option.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.buttonFill
                            : AppTheme.backgroundPink,
                        border: Border.all(
                          color: selected
                              ? AppTheme.borderDark
                              : AppTheme.buttonShadow,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option.label,
                            style: AppTheme.pixelText(
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            option.description,
                            style: AppTheme.pixelText(
                              fontSize: 10,
                              color: AppTheme.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            PixelButton(
              logicalWidth: 40,
              logicalHeight: 12,
              width: 220,
              pressChildOffset: const Offset(0, 1),
              onPressed: () => Navigator.of(context).pop(),
              semanticsLabel: 'Back',
              child: Text(
                'Back',
                style: AppTheme.buttonLabel(AppTheme.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAccessory(String? accessory) {
    setState(() {
      _selectedAccessory = accessory;
    });
    widget.onAccessorySelected(accessory);
  }
}

class _AccessoryOption {
  final String? id;
  final String label;
  final String emoji;
  final String description;

  const _AccessoryOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
  });
}
