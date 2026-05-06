class StockItem {
  final String productId;
  final String productName;
  final int qtyBase;
  final int qtyCurrent;

  StockItem({
    required this.productId,
    required this.productName,
    required this.qtyBase,
    required this.qtyCurrent,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      qtyBase: json['qty_base'] as int,
      qtyCurrent: json['qty_current'] as int,
    );
  }
}
