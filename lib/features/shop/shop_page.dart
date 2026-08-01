import 'package:flutter/material.dart';
import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/core/accessories.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/core/room_decorations.dart';
import 'package:happy_cherry/features/shop/shop_purchase_result.dart';
import 'package:happy_cherry/widgets/accessory_graphic.dart';
import 'package:happy_cherry/widgets/pet_graphic.dart';
import 'package:pixel_ui/pixel_ui.dart';

/// Buy clothing and room deco with coins. Purchases are account-owned (survive pet death).
class ShopPage extends StatefulWidget {
  final Pet pet;
  final int coins;
  final Set<String> ownedAccessories;
  final ValueChanged<ShopPurchaseResult> onPurchase;

  const ShopPage({
    super.key,
    required this.pet,
    required this.coins,
    required this.ownedAccessories,
    required this.onPurchase,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late int _coins = widget.coins;
  late Set<String> _owned = {
    ...AccessoryCatalog.canonicalizeOwned(widget.ownedAccessories),
  };
  late String? _selectedRoomDecoration = widget.pet.roomDecoration;

  Future<void> _buyAccessory(AccessoryItem item) async {
    if (AccessoryCatalog.owns(_owned, item.id)) return;
    if (_coins < item.cost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${item.cost} coins to buy ${item.label}.',
            style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textLight),
          ),
          backgroundColor: AppTheme.buttonPressedFill,
        ),
      );
      return;
    }

    setState(() {
      _coins -= item.cost;
      _owned = {..._owned, item.id};
    });
    widget.onPurchase(
      ShopPurchaseResult(coins: _coins, ownedAccessories: {..._owned}),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bought ${item.label}! Equip it in the Wardrobe.',
          style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textLight),
        ),
        backgroundColor: AppTheme.buttonFill,
      ),
    );
  }

  Future<void> _buyRoomDecoration(RoomDecorationItem item) async {
    if (RoomDecorationCatalog.owns(_owned, item.id)) return;
    if (_coins < item.cost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${item.cost} coins to buy ${item.label}.',
            style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textLight),
          ),
          backgroundColor: AppTheme.buttonPressedFill,
        ),
      );
      return;
    }

    setState(() {
      _coins -= item.cost;
      _owned = {..._owned, item.id};
    });
    widget.onPurchase(
      ShopPurchaseResult(coins: _coins, ownedAccessories: {..._owned}),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bought ${item.label}! Tap it again to equip it in the room preview.',
          style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textLight),
        ),
        backgroundColor: AppTheme.buttonFill,
      ),
    );
  }

  void _equipRoomDecoration(String id) {
    setState(() {
      _selectedRoomDecoration = id;
      widget.pet.roomDecoration = id;
    });
    widget.onPurchase(
      ShopPurchaseResult(coins: _coins, ownedAccessories: {..._owned}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopItems = AccessoryCatalog.shopItems;
    final decoItems = RoomDecorationCatalog.shopItems;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarPink,
        foregroundColor: AppTheme.textDark,
        title: Text(
          'Shop',
          style: AppTheme.pixelText(fontSize: 20, color: AppTheme.textDark),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Coins: $_coins',
              style: AppTheme.pixelText(
                fontSize: 18,
                color: AppTheme.textDark,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Spend coins to unlock new looks and room decor',
              style: AppTheme.pixelText(fontSize: 14, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PetGraphic(pet: widget.pet, height: 180),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Accessories',
                    style: AppTheme.pixelText(
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ).copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 280,
                    child: GridView.builder(
                      itemCount: shopItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                      itemBuilder: (context, index) {
                        final item = shopItems[index];
                        final owned = AccessoryCatalog.owns(_owned, item.id);
                        final canAfford = _coins >= item.cost;

                        return GestureDetector(
                          onTap: owned ? null : () => _buyAccessory(item),
                          child: Opacity(
                            opacity: owned ? 0.55 : 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: owned
                                    ? AppTheme.buttonDisabledFill
                                    : AppTheme.backgroundPink,
                                border: Border.all(
                                  color: AppTheme.borderDark,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AccessoryGraphic(item: item, size: 40),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.label,
                                    style: AppTheme.pixelText(
                                      fontSize: 14,
                                      color: AppTheme.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: AppTheme.pixelText(
                                      fontSize: 10,
                                      color: AppTheme.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    owned ? 'Owned' : '${item.cost} coins',
                                    style: AppTheme.pixelText(
                                      fontSize: 12,
                                      color: owned
                                          ? AppTheme.textDark
                                          : (canAfford
                                                ? AppTheme.buttonPressedFill
                                                : AppTheme.buttonShadow),
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Room Deco',
                    style: AppTheme.pixelText(
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ).copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: GridView.builder(
                      itemCount: decoItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                      itemBuilder: (context, index) {
                        final item = decoItems[index];
                        final owned = RoomDecorationCatalog.owns(
                          _owned,
                          item.id,
                        );
                        final canAfford = _coins >= item.cost;
                        final selected = _selectedRoomDecoration == item.id;

                        return GestureDetector(
                          onTap: () {
                            if (!owned) {
                              _buyRoomDecoration(item);
                              return;
                            }
                            _equipRoomDecoration(item.id);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.buttonFill
                                  : (owned
                                        ? AppTheme.buttonDisabledFill
                                        : AppTheme.backgroundPink),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.borderDark
                                    : AppTheme.buttonShadow,
                                width: selected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.emoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.label,
                                  style: AppTheme.pixelText(
                                    fontSize: 14,
                                    color: AppTheme.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: AppTheme.pixelText(
                                    fontSize: 10,
                                    color: AppTheme.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  owned
                                      ? (selected ? 'Equipped' : 'Owned')
                                      : '${item.cost} coins',
                                  style: AppTheme.pixelText(
                                    fontSize: 12,
                                    color: owned
                                        ? AppTheme.textDark
                                        : (canAfford
                                              ? AppTheme.buttonPressedFill
                                              : AppTheme.buttonShadow),
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
}
