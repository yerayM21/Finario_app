import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String type; // 'purchase', 'sale', 'generic_expense', 'generic_income'
  final double amount;
  final String description;
  final String category;
  final String? productId;
  final String? productName;
  final int? quantity;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    this.productId,
    this.productName,
    this.quantity,
    required this.date,
    DateTime? createdAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      category: map['category'],
      productId: map['product_id'],
      productName: map['products'] != null ? map['products']['name'] : null,
      quantity: map['quantity'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'product_id': productId,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}