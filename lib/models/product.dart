import 'package:intl/intl.dart'; // Para formatear fechas si es necesario

class Product {
  String? id; // Nullable si es nuevo y la BD genera el ID
  String name;
  int quantity;
  double unitCost;
  double salePrice;
  DateTime? restockDate;
  DateTime? expirationDate;
  DateTime? createdAt;
  DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.quantity = 0,
    required this.unitCost,
    required this.salePrice,
    this.restockDate,
    this.expirationDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      restockDate: map['restock_date'] != null ? DateTime.parse(map['restock_date'] as String) : null,
      expirationDate: map['expiration_date'] != null ? DateTime.parse(map['expiration_date'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  // Para inserciones donde la BD genera el ID y timestamps
  Map<String, dynamic> toMapForInsert() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_cost': unitCost,
      'sale_price': salePrice,
      'restock_date': restockDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      // id, created_at, updated_at son manejados por la BD
    };
  }
  
  // Si el ID es generado por el cliente y quieres incluirlo en la inserción
  Map<String, dynamic> toMapAllFields() {
    return {
      'id': id, // Asume que el ID ya fue asignado
      'name': name,
      'quantity': quantity,
      'unit_cost': unitCost,
      'sale_price': salePrice,
      'restock_date': restockDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      // created_at, updated_at son manejados por la BD
    };
  }


  // Para actualizaciones
  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_cost': unitCost,
      'sale_price': salePrice,
      'restock_date': restockDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      // id se usa en .eq(), created_at no se actualiza, updated_at es manejado por trigger
    };
  }
}