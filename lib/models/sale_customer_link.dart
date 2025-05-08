import './customer.dart';
import './transaction.dart';

class SaleCustomerLink {
  String saleTransactionId; // PK, FK
  String customerId;        // PK, FK
  DateTime? createdAt;

  // Opcional: para traer info del cliente o transacción directamente
  Customer? customer; 
  Transaction? transaction;

  SaleCustomerLink({
    required this.saleTransactionId,
    required this.customerId,
    this.createdAt,
    this.customer,
    this.transaction,
  });

  factory SaleCustomerLink.fromMap(Map<String, dynamic> map) {
    return SaleCustomerLink(
      saleTransactionId: map['sale_transaction_id'] as String,
      customerId: map['customer_id'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      customer: map['customers'] != null ? Customer.fromMap(map['customers']) : null,
      transaction: map['transactions'] != null ? Transaction.fromMap(map['transactions']) : null,
    );
  }

  // Solo se inserta, no se actualiza usualmente. Las FKs son la PK.
  Map<String, dynamic> toMapForInsert() {
    return {
      'sale_transaction_id': saleTransactionId,
      'customer_id': customerId,
      // createdAt es manejado por la BD
    };
  }
}