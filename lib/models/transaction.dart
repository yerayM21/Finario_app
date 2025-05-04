import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String type; // 'purchase', 'sale', 'generic_expense', 'generic_income'
  final double amount;
  final String description;
  final String category;
  final String? productId;
  final int? quantity;
  final DateTime date;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    this.productId,
    this.quantity,
    required this.date,
  }) : id = id ?? Uuid().v4();

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      category: map['category'] as String,
      productId: map['product_id'] as String?,
      quantity: map['quantity'] as int?,
      date: DateTime.parse(map['date']),
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
    };
  }
}