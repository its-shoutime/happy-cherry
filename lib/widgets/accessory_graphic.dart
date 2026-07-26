import 'package:flutter/material.dart';

import 'package:happy_cherry/core/accessories.dart';

/// Renders an accessory as its pixel art asset, falling back to emoji.
class AccessoryGraphic extends StatelessWidget {
  final AccessoryItem? item;
  final String? accessoryId;
  final double size;

  const AccessoryGraphic({
    super.key,
    this.item,
    this.accessoryId,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = item ?? AccessoryCatalog.byId(accessoryId);
    if (resolved == null) {
      return SizedBox(width: size, height: size);
    }

    if (resolved.hasAsset) {
      return Image.asset(
        resolved.assetPath!,
        width: size,
        height: size,
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      );
    }

    return Text(resolved.emoji, style: TextStyle(fontSize: size * 0.85));
  }
}
