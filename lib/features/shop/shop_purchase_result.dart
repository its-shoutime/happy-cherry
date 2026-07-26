/// Result of buying one shop item (ISP: one callback instead of two).
class ShopPurchaseResult {
  final int coins;
  final Set<String> ownedAccessories;

  const ShopPurchaseResult({
    required this.coins,
    required this.ownedAccessories,
  });
}
