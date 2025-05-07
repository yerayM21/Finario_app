import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  // ==================== VALIDACIÓN UUID ====================
  bool _isValidUuid(String? id) {
    if (id == null) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  // ==================== PRODUCTOS ====================
  Future<List<Product>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select('*')
        .order('name', ascending: true);
    
    return (response as List).map((item) => Product.fromMap(item)).toList();
  }

  Future<Product?> getProductById(String id) async {
    if (!_isValidUuid(id)) throw Exception('ID de producto no válido');
    
    final response = await _supabase
        .from('products')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    
    return response != null ? Product.fromMap(response) : null;
  }

  Future<void> addProduct(Product product) async {
    if (!_isValidUuid(product.id)) throw Exception('ID de producto no válido');
    await _supabase.from('products').insert(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    if (!_isValidUuid(product.id)) throw Exception('ID de producto no válido');
    await _supabase
        .from('products')
        .update(product.toMap())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    if (!_isValidUuid(id)) throw Exception('ID de producto no válido');
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
    if (transaction.productId != null && !_isValidUuid(transaction.productId)) {
      throw Exception('ID de producto no válido');
    }
    
    await _supabase.from('transactions').insert({
      ...transaction.toMap(),
      'id': _uuid.v4(), // Generar un UUID para la transacción
    });
  }

  Future<void> deleteTransaction(String id) async {
    if (!_isValidUuid(id)) throw Exception('ID de transacción no válido');
    await _supabase.from('transactions').delete().eq('id', id);
  }

  // ==================== OPERACIONES COMBINADAS ====================
  Future<void> registerPurchase({
    required Product product,
    required int quantity,
    required double unitCost,
  }) async {
    if (!_isValidUuid(product.id)) throw Exception('ID de producto no válido');
    if (quantity <= 0) throw Exception('La cantidad debe ser positiva');
    if (unitCost <= 0) throw Exception('El costo unitario debe ser positivo');

    await _supabase.rpc('register_purchase_transaction', params: {
      'product_id': product.id,
      'quantity': quantity,
      'unit_cost': unitCost,
      'description': 'Compra de ${product.name}',
    });
  }

  Future<void> registerSale({
    required Product product,
    required int quantity,
  }) async {
    if (!_isValidUuid(product.id)) throw Exception('ID de producto no válido');
    if (quantity <= 0) throw Exception('La cantidad debe ser positiva');
    if (product.quantity < quantity) throw Exception('Stock insuficiente');

    await _supabase.rpc('register_sale_transaction', params: {
      'product_id': product.id,
      'quantity': quantity,
      'description': 'Venta de ${product.name}',
    });
  }

  Future<void> registerGenericExpense({
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    if (amount <= 0) throw Exception('El monto debe ser positivo');
    
    await addTransaction(
      Transaction(
        type: 'generic_expense',
        amount: -amount.abs(),
        description: description,
        category: category,
        productId: null,
        quantity: null,
        date: date ?? DateTime.now(),
      ),
    );
  }

  Future<void> registerGenericIncome({
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    if (amount <= 0) throw Exception('El monto debe ser positivo');
    
    await addTransaction(
      Transaction(
        type: 'generic_income',
        amount: amount.abs(),
        description: description,
        category: category,
        productId: null,
        quantity: null,
        date: date ?? DateTime.now(),
      ),
    );
  }
}