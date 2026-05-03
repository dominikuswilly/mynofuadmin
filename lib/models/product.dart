class Product {
  final String id;
  final String name;
  final String category;
  final int amountSell;
  final int active;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.amountSell,
    required this.active,
  });

  bool get isActive => active == 1;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      amountSell: json['amount_sell'] as int,
      active: json['active'] as int,
    );
  }
}
