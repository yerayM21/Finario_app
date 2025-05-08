import '../utils/enum_helpers.dart'; 
import './supplier_invoice.dart'; // Si usas el mismo InvoiceStatus

class CustomerReceivable {
  String? id;
  String saleTransactionId;
  String customerId;
  DateTime issueDate;       // SQL DATE
  DateTime dueDate;         // SQL DATE
  double totalDue;
  double amountPaid;
  InvoiceStatus status; // Reutilizando InvoiceStatus o crea ReceivableStatus
  String? paymentTerms;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Campos opcionales para datos de join
  String? customerName;
  String? transactionDescription;
  String? productNameFromTransaction;


  CustomerReceivable({
    this.id,
    required this.saleTransactionId,
    required this.customerId,
    required this.issueDate,
    required this.dueDate,
    required this.totalDue,
    this.amountPaid = 0.0,
    this.status = InvoiceStatus.pending,
    this.paymentTerms,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.transactionDescription,
    this.productNameFromTransaction,
  });

  factory CustomerReceivable.fromMap(Map<String, dynamic> map) {
    return CustomerReceivable(
      id: map['id'] as String?,
      saleTransactionId: map['sale_transaction_id'] as String,
      customerId: map['customer_id'] as String,
      issueDate: DateTime.parse(map['issue_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      totalDue: (map['total_due'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatus.fromString(map['status'] as String?, InvoiceStatus.pending),
      paymentTerms: map['payment_terms'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      customerName: map['customers']?['name'] as String?,
      transactionDescription: map['transactions']?['description'] as String?,
      productNameFromTransaction: map['transactions']?['products']?['name'] as String?,
    );
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'sale_transaction_id': saleTransactionId,
      'customer_id': customerId,
      'issue_date': issueDate.toIso8601String().substring(0, 10),
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'total_due': totalDue,
      'amount_paid': amountPaid,
      'status': status.name,
      'payment_terms': paymentTerms,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      // FKs usualmente no se cambian, pero depende de tu lógica
      // 'sale_transaction_id': saleTransactionId, 
      // 'customer_id': customerId,
      'issue_date': issueDate.toIso8601String().substring(0, 10),
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'total_due': totalDue, // Puede que el total no deba cambiar una vez emitido
      'amount_paid': amountPaid,
      'status': status.name,
      'payment_terms': paymentTerms,
      'notes': notes,
    };
  }
}