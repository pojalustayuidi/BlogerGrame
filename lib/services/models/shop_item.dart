class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String type; // 'hint', 'life', 'skip'

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.type,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      cost: json['cost'],
      type: json['type'],
    );
  }
}
