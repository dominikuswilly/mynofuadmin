class StockItem {
  final String productId;
  final String productName;
  final String productCategory;
  final int qtyBase;
  final int qtyCurrent;
  final int confirmed;
  final String createdAt;
  final String riderName;

  StockItem({
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.qtyBase,
    required this.qtyCurrent,
    required this.confirmed,
    this.createdAt = '',
    this.riderName = '',
  });

  factory StockItem.fromJson(Map<String, dynamic> json, {String? createdAt, String? riderName}) {
    return StockItem(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      productCategory: json['product_category']?.toString() ?? '',
      qtyBase: _toInt(json['qty_base']),
      qtyCurrent: _toInt(json['qty_current']),
      confirmed: _toInt(json['confirmed']),
      createdAt: createdAt ?? json['created_at']?.toString() ?? '',
      riderName: riderName ?? json['rider_name']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
