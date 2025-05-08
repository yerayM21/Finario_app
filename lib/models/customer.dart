// Asegúrate de tener el helper o define el enumFromString aquí
import '../utils/enum_helpers.dart';

enum CustomerType {
  frequent,
  wholesale,
  regular; // Valor por defecto o general

  static CustomerType fromString(String? value, CustomerType defaultValue) {
    if (value == null) return defaultValue;
    for (var type in CustomerType.values) {
      if (type.name.toLowerCase() == value.toLowerCase().trim()) {
        return type;
      }
    }
    return defaultValue;
  }
}

class Customer {
  String? id;
  String name;
  Map<String, dynamic>? contactDetails;
  CustomerType customerType;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.contactDetails,
    this.customerType = CustomerType.regular,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String?,
      name: map['name'] as String,
      contactDetails: map['contact_details'] != null
          ? Map<String, dynamic>.from(map['contact_details'])
          : null,
      customerType: CustomerType.fromString(map['customer_type'] as String?, CustomerType.regular),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'name': name,
      'contact_details': contactDetails,
      'customer_type': customerType.name,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'contact_details': contactDetails,
      'customer_type': customerType.name,
      'notes': notes,
    };
  }
}