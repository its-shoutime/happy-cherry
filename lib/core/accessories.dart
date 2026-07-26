/// Catalog of purchasable / equippable pet clothing.
class AccessoryItem {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final String? assetPath;
  final int cost;
  final bool availableInShop;

  const AccessoryItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    this.assetPath,
    this.cost = AccessoryCatalog.defaultCost,
    this.availableInShop = true,
  });

  bool get hasAsset => assetPath != null && assetPath!.isNotEmpty;
}

class AccessoryCatalog {
  static const int defaultCost = 20;

  /// Older saves used these ids; map them onto the new catalog.
  static const Map<String, String> legacyIdAliases = {
    'hat': 'straw_hat',
  };

  static const List<AccessoryItem> shopItems = [
    AccessoryItem(
      id: 'beanie',
      label: 'Beanie',
      emoji: '🧢',
      description: 'Cozy and casual',
      assetPath: 'assets/accessories/beanie.png',
    ),
    AccessoryItem(
      id: 'bow',
      label: 'Bow',
      emoji: '🎀',
      description: 'Cute and bright',
      assetPath: 'assets/accessories/bow.png',
    ),
    AccessoryItem(
      id: 'cone',
      label: 'Cone',
      emoji: '🚦',
      description: 'Why would you wear this?',
      assetPath: 'assets/accessories/cone.png',
    ),
    AccessoryItem(
      id: 'crown',
      label: 'Crown',
      emoji: '👑',
      description: 'Just for royalty',
      assetPath: 'assets/accessories/crown.png',
      cost: 1000,
    ),
    AccessoryItem(
      id: 'daisy',
      label: 'Daisy',
      emoji: '🌼',
      description: 'Freshly plucked',
      assetPath: 'assets/accessories/daisy.png',
    ),
    AccessoryItem(
      id: 'santa_hat',
      label: 'Santa Hat',
      emoji: '🎅',
      description: 'Ho ho ho',
      assetPath: 'assets/accessories/santa hat.png',
    ),
    AccessoryItem(
      id: 'sprout',
      label: 'Sprout',
      emoji: '🌱',
      description: 'Its very bouncy',
      assetPath: 'assets/accessories/sprout.png',
    ),
    AccessoryItem(
      id: 'straw_hat',
      label: 'Straw Hat',
      emoji: '👒',
      description: 'Just a hat',
      assetPath: 'assets/accessories/straw hat.png',
    ),
  ];

  /// Kept so older owned/equipped ids still work in the wardrobe.
  static const List<AccessoryItem> legacyItems = [
    AccessoryItem(
      id: 'glasses',
      label: 'Glasses',
      emoji: '🕶️',
      description: 'Cool and clever',
      availableInShop: false,
    ),
    AccessoryItem(
      id: 'scarf',
      label: 'Scarf',
      emoji: '🧣',
      description: 'Warm and cozy',
      availableInShop: false,
    ),
  ];

  static List<AccessoryItem> get all => [...shopItems, ...legacyItems];

  /// Resolves legacy ids (e.g. `hat` → `straw_hat`) for save compatibility.
  static String canonicalizeId(String id) {
    return legacyIdAliases[id] ?? id;
  }

  static AccessoryItem? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    final canonical = canonicalizeId(id);
    for (final item in all) {
      if (item.id == canonical || item.id == id) {
        return item;
      }
    }
    return null;
  }

  static bool owns(Iterable<String> ownedIds, String id) {
    final canonical = canonicalizeId(id);
    for (final owned in ownedIds) {
      if (canonicalizeId(owned) == canonical) return true;
    }
    return false;
  }

  static List<String> canonicalizeOwned(Iterable<String> ownedIds) {
    final normalized = <String>{};
    for (final id in ownedIds) {
      if (id.isEmpty) continue;
      normalized.add(canonicalizeId(id));
    }
    final list = normalized.toList()..sort();
    return list;
  }

  static String emojiFor(String? id) => byId(id)?.emoji ?? '';

  static String? assetPathFor(String? id) => byId(id)?.assetPath;
}
