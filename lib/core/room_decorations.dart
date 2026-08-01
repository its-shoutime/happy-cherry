class RoomDecorationItem {
  final String id;
  final String label;
  final String description;
  final int cost;
  final String emoji;

  const RoomDecorationItem({
    required this.id,
    required this.label,
    required this.description,
    required this.cost,
    required this.emoji,
  });
}

class RoomDecorationCatalog {
  static const List<RoomDecorationItem> shopItems = [
    RoomDecorationItem(
      id: 'room_tree',
      label: 'Tree',
      description: 'A cozy tree in the corner',
      cost: 15,
      emoji: '🌳',
    ),
    RoomDecorationItem(
      id: 'room_cloud',
      label: 'Cloud',
      description: 'Cloudy dreamy room vibe',
      cost: 18,
      emoji: '☁️',
    ),
    RoomDecorationItem(
      id: 'room_star',
      label: 'Star',
      description: 'Sparkly room decoration',
      cost: 20,
      emoji: '⭐',
    ),
    RoomDecorationItem(
      id: 'room_cake',
      label: 'Cake',
      description: 'A dessert-room accent',
      cost: 14,
      emoji: '🍰',
    ),
  ];

  static bool owns(Set<String> owned, String id) => owned.contains(id);

  static String emojiFor(String? id) {
    for (final item in shopItems) {
      if (item.id == id) return item.emoji;
    }
    return '';
  }
}
