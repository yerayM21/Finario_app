class Transaction {
  String? id; // Puede ser generado por el cliente para transacciones genéricas o por la BD
  String type; // 'purchase', 'sale', 'generic_expense', 'generic_income'
  double amount;
  String description;
  String category;
  String? productId;
  int? quantity; // Cantidad de producto, si aplica
  DateTime date;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Campo opcional para datos de join desde la tabla products
  String? productName;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    this.productId,
    this.quantity,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.productName,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      productId: map['product_id'] as String?,
      quantity: (map['quantity'] as num?)?.toInt(),
      date: DateTime.parse(map['date'] as String),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      productName: map['products'] != null ? map['products']['name'] as String? : null,
    );
  }

  // Usado para insertar transacciones genéricas donde el ID puede ser generado por el cliente
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Se incluye si el cliente lo genera
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'product_id': productId,
      'quantity': quantity,
      'date': date.toIso8601String(),
      // createdAt y updatedAt son manejados por la BD
    };
  }
}