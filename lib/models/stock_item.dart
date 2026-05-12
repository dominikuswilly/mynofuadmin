class StockItem {
  final String productId;
  final String productName;
  final String productCategory;
  final int qtyBase;
  final int qtyCurrent;
  final int confirmed;

  StockItem({
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.qtyBase,
    required this.qtyCurrent,
    required this.confirmed,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String? ?? '',
      qtyBase: (json['qty_base'] as num).toInt(),
      qtyCurrent: (json['qty_current'] as num).toInt(),
      confirmed: (json['confirmed'] as num).toInt(),
    );
  }
}
