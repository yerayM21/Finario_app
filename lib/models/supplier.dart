class Supplier {
  String? id;
  String name;
  Map<String, dynamic>? contactDetails; // Para JSONB
  DateTime? createdAt;
  DateTime? updatedAt;

  Supplier({
    this.id,
    required this.name,
    this.contactDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String?,
      name: map['name'] as String,
      contactDetails: map['contact_details'] != null
          ? Map<String, dynamic>.from(map['contact_details'])
          : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'name': name,
      'contact_details': contactDetails,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'contact_details': contactDetails,
    };
  }
}