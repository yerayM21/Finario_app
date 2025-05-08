import '../utils/enum_helpers.dart'; 

enum InvoiceStatus {
  pending,
  paid,
  partially_paid,
  overdue,
  cancelled; // Un estado adicional posible

  static InvoiceStatus fromString(String? value, InvoiceStatus defaultValue) {
     if (value == null) return defaultValue;
    for (var status in InvoiceStatus.values) {
      if (status.name.toLowerCase() == value.toLowerCase().trim()) {
        return status;
      }
    }
    return defaultValue;
  }
}

class SupplierInvoice {
  String? id;
  String supplierId;
  String? invoiceNumber;
  DateTime invoiceDate; // SQL DATE
  DateTime dueDate;     // SQL DATE
  double totalAmount;
  double amountPaid;
  InvoiceStatus status;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Campo opcional para datos de join
  String? supplierName;

  SupplierInvoice({
    this.id,
    required this.supplierId,
    this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.totalAmount,
    this.amountPaid = 0.0,
    this.status = InvoiceStatus.pending,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.supplierName,
  });

  factory SupplierInvoice.fromMap(Map<String, dynamic> map) {
    return SupplierInvoice(
      id: map['id'] as String?,
      supplierId: map['supplier_id'] as String,
      invoiceNumber: map['invoice_number'] as String?,
      invoiceDate: DateTime.parse(map['invoice_date'] as String), // Viene como YYYY-MM-DD
      dueDate: DateTime.parse(map['due_date'] as String),       // Viene como YYYY-MM-DD
      totalAmount: (map['total_amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatus.fromString(map['status'] as String?, InvoiceStatus.pending),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      supplierName: map['suppliers']?['name'] as String?,
    );
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'due_date': dueDate.toIso8601String().substring(0, 10),       // YYYY-MM-DD
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'status': status.name,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'supplier_id': supplierId, // Podría no ser actualizable
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().substring(0, 10),
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'status': status.name,
      'notes': notes,
    };
  }
}