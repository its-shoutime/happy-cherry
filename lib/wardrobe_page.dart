import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'app_theme.dart';
import 'models/accessories.dart';
import 'models/accessory_graphic.dart';
import 'models/pet.dart';
import 'pet_animation.dart';

/// Equip clothing the account already owns.
class WardrobePage extends StatefulWidget {
  final Pet pet;
  final Set<String> ownedAccessories;
  final ValueChanged<String?> onAccessorySelected;

  const WardrobePage({
    super.key,
    required this.pet,
    required this.ownedAccessories,
    required this.onAccessorySelected,
  });

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  late String? _selectedAccessory = widget.pet.accessory == null
      ? null
      : AccessoryCatalog.canonicalizeId(widget.pet.accessory!);

  List<AccessoryItem> get _ownedItems {
    final owned = AccessoryCatalog.canonicalizeOwned(widget.ownedAccessories);
    return AccessoryCatalog.all
        .where((item) => owned.contains(item.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final previewPet = Pet.fromJson(widget.pet.toJson())
      ..accessory = _selectedAccessory;
    final ownedItems = _ownedItems;

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
              ownedItems.isEmpty
                  ? 'No clothes yet — visit the Shop!'
                  : 'Equip owned clothing',
              style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PetGraphic(pet: previewPet, height: 220),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: ownedItems.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _WardrobeTile(
                      item: null,
                      label: 'None',
                      description: 'Default look',
                      fallbackEmoji: '✨',
                      selected: _selectedAccessory == null,
                      onTap: () => _selectAccessory(null),
                    );
                  }

                  final item = ownedItems[index - 1];
                  return _WardrobeTile(
                    item: item,
                    label: item.label,
                    description: item.description,
                    selected: _selectedAccessory == item.id,
                    onTap: () => _selectAccessory(item.id),
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

class _WardrobeTile extends StatelessWidget {
  final AccessoryItem? item;
  final String label;
  final String description;
  final String? fallbackEmoji;
  final bool selected;
  final VoidCallback onTap;

  const _WardrobeTile({
    required this.item,
    required this.label,
    required this.description,
    this.fallbackEmoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppTheme.buttonFill : AppTheme.backgroundPink,
          border: Border.all(
            color: selected ? AppTheme.borderDark : AppTheme.buttonShadow,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item != null)
              AccessoryGraphic(item: item, size: 32)
            else
              Text(fallbackEmoji ?? '✨', style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTheme.pixelText(fontSize: 13, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: AppTheme.pixelText(fontSize: 10, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
