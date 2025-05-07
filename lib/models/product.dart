// lib/models/product.dart
class Product {
  final String id;
  final String name;
  final int quantity;
  final double unitCost;
  final double salePrice;
  final DateTime? restockDate;
  final DateTime? expirationDate;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitCost,
    required this.salePrice,
    this.restockDate,
    this.expirationDate,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      unitCost: (map['unit_cost'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      restockDate: map['restock_date'] != null ? DateTime.parse(map['restock_date']) : null,
      expirationDate: map['expiration_date'] != null ? DateTime.parse(map['expiration_date']) : null,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_cost': unitCost,
      'sale_price': salePrice,
      'restock_date': restockDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método para copiar un producto con nuevos valores
  Product copyWith({
    String? name,
    int? quantity,
    double? unitCost,
    double? salePrice,
    DateTime? restockDate,
    DateTime? expirationDate,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      salePrice: salePrice ?? this.salePrice,
      restockDate: restockDate ?? this.restockDate,
      expirationDate: expirationDate ?? this.expirationDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}