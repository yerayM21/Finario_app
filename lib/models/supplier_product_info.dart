class SupplierProductInfo {
  String? id;
  String supplierId;
  String productId;
  String? supplierProductCode;
  double supplyCost;
  int? deliveryLeadTimeDays;
  String? deliveryTerms;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Campos opcionales para datos de join
  String? productName;
  String? supplierName; 
  double? productSalePrice;


  SupplierProductInfo({
    this.id,
    required this.supplierId,
    required this.productId,
    this.supplierProductCode,
    required this.supplyCost,
    this.deliveryLeadTimeDays,
    this.deliveryTerms,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.productName, // Para datos de join
    this.supplierName,
    this.productSalePrice,
  });

  factory SupplierProductInfo.fromMap(Map<String, dynamic> map) {
    return SupplierProductInfo(
      id: map['id'] as String?,
      supplierId: map['supplier_id'] as String,
      productId: map['product_id'] as String,
      supplierProductCode: map['supplier_product_code'] as String?,
      supplyCost: (map['supply_cost'] as num).toDouble(),
      deliveryLeadTimeDays: (map['delivery_lead_time_days'] as num?)?.toInt(),
      deliveryTerms: map['delivery_terms'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      productName: map['products']?['name'] as String?, // Ejemplo de cómo acceder a datos de join
      productSalePrice: (map['products']?['sale_price'] as num?)?.toDouble(),
      supplierName: map['suppliers']?['name'] as String?,
    );
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'supplier_id': supplierId,
      'product_id': productId,
      'supplier_product_code': supplierProductCode,
      'supply_cost': supplyCost,
      'delivery_lead_time_days': deliveryLeadTimeDays,
      'delivery_terms': deliveryTerms,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'supplier_id': supplierId, // Aunque usualmente no se cambia la FK
      'product_id': productId,   // Aunque usualmente no se cambia la FK
      'supplier_product_code': supplierProductCode,
      'supply_cost': supplyCost,
      'delivery_lead_time_days': deliveryLeadTimeDays,
      'delivery_terms': deliveryTerms,
      'notes': notes,
    };
  }
}