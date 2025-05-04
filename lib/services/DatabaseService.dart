import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/transaction.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== PRODUCTOS ====================
  Future<List<Product>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select('*')
        .order('name', ascending: true);
    
    return (response as List).map((item) => Product.fromMap(item)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final response = await _supabase
        .from('products')
        .select('*')
        .eq('id', id)
        .single();
    
    return response != null ? Product.fromMap(response) : null;
  }

  Future<void> addProduct(Product product) async {
    await _supabase.from('products').insert(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _supabase
        .from('products')
        .update(product.toMap())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  // ==================== TRANSACCIONES ====================
  Future<List<Transaction>> getTransactions() async {
    final response = await _supabase
        .from('transactions')
        .select('*, products(name)')
        .order('date', ascending: false);

    return (response as List).map((item) => Transaction.fromMap(item)).toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _supabase.from('transactions').insert(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  // ==================== OPERACIONES COMBINADAS ====================
  Future<void> registerPurchase({
    required Product product,
    required int quantity,
    required double unitCost,
  }) async {
    // 1. Actualizar el producto (aumentar stock)
    final updatedProduct = product.copyWith(
      quantity: product.quantity + quantity,
      unitCost: unitCost,
      updatedAt: DateTime.now(),
    );
    await updateProduct(updatedProduct);

    // 2. Registrar la transacción
    await addTransaction(
      Transaction(
        id: DateTime.now().toIso8601String(), // Usar UUID en producción
        type: 'purchase',
        amount: -(unitCost * quantity), // Monto negativo (gasto)
        description: 'Compra de ${product.name}',
        category: 'Compra de Inventario',
        productId: product.id,
        quantity: quantity,
        date: DateTime.now(),
      ),
    );
  }

Future<void> registerSale({
  required Product product,
  required int quantity,
}) async {
  // Valida que el product.id sea un UUID válido
  if (!_isValidUuid(product.id)) {
    throw Exception('ID de producto no válido');
  }

  await _supabase.from('transactions').insert({
    'type': 'sale',
    'amount': product.salePrice * quantity,
    'description': 'Venta de ${product.name}',
    'category': 'Venta de Producto',
    'product_id': product.id, // <- UUID válido
    'quantity': quantity,
    'date': DateTime.now().toIso8601String(),
  });
}

bool _isValidUuid(String? id) {
  if (id == null) return false;
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(id);
}
}