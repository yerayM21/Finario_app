import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Importa tus modelos aquí. Asegúrate que las rutas y nombres de archivo sean correctos.
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/supplier_product_info.dart';
import '../models/sale_customer_link.dart';
import '../models/supplier_invoice.dart';
import '../models/customer_receivable.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  // ==================== VALIDACIÓN UUID ====================
  bool isValidUuid(String? id) {
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
    if (!isValidUuid(id)) throw ArgumentError('ID de producto no válido');
    final response = await _supabase
        .from('products')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response != null ? Product.fromMap(response) : null;
  }

  Future<Product> addProduct(Product product) async {
    if (product.id == null || !isValidUuid(product.id)) {
      product.id = _uuid.v4();
    }
    final response = await _supabase
        .from('products')
        .insert(product.toMapAllFields()) 
        .select()
        .single();
    return Product.fromMap(response);
  }

  Future<Product> updateProduct(Product product) async {
    if (product.id == null || !isValidUuid(product.id)) {
      throw ArgumentError('ID de producto no válido para actualizar');
    }
    final response = await _supabase
        .from('products')
        .update(product.toMapForUpdate()) 
        .eq('id', product.id!)
        .select()
        .single();
    return Product.fromMap(response);
  }

  Future<void> deleteProduct(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de producto no válido');
    await _supabase.from('products').delete().eq('id', id);
  }

  // ==================== TRANSACCIONES ====================
  Future<List<Transaction>> getTransactions({String? productId}) async {
    // CORRECCIÓN AQUÍ: Aplicar filtros antes de .order()
    PostgrestFilterBuilder<List<Map<String, dynamic>>> queryBuilder = _supabase
        .from('transactions')
        .select('*, products(name)');
    
    if (productId != null && isValidUuid(productId)) {
      queryBuilder = queryBuilder.eq('product_id', productId);
    }

    // Aplicar .order() después de todos los filtros
    final response = await queryBuilder.order('date', ascending: false);
    return (response).map((item) => Transaction.fromMap(item)).toList();
  }
  
  Future<Transaction?> getTransactionById(String transactionId) async {
    if (!isValidUuid(transactionId)) throw ArgumentError('ID de transacción no válido');
    
    final response = await _supabase
        .from('transactions')
        .select('*, products(name)')
        .eq('id', transactionId)
        .maybeSingle();
    
    return response != null ? Transaction.fromMap(response) : null;
  }

  Future<Transaction> addGenericTransaction(Transaction transaction) async {
    if (transaction.id == null || !isValidUuid(transaction.id)) {
      transaction.id = _uuid.v4();
    }
    if (transaction.productId != null && !isValidUuid(transaction.productId)) {
      throw ArgumentError('ID de producto no válido en la transacción');
    }
    
    final response = await _supabase
        .from('transactions')
        .insert(transaction.toMap()) 
        .select()
        .single();
    return Transaction.fromMap(response);
  }

  Future<void> deleteTransaction(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de transacción no válido');
    await _supabase.from('transactions').delete().eq('id', id);
  }

  // ==================== PROVEEDORES (Suppliers) ====================
  Future<List<Supplier>> getSuppliers() async {
    final response = await _supabase
        .from('suppliers')
        .select('*')
        .order('name', ascending: true);
    return (response as List).map((item) => Supplier.fromMap(item)).toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de proveedor no válido');
    final response = await _supabase
        .from('suppliers')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response != null ? Supplier.fromMap(response) : null;
  }

  Future<Supplier> addSupplier(Supplier supplier) async {
    final response = await _supabase
        .from('suppliers')
        .insert(supplier.toMapForInsert()) 
        .select()
        .single();
    return Supplier.fromMap(response);
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    if (supplier.id == null || !isValidUuid(supplier.id)) {
      throw ArgumentError('ID de proveedor no válido para actualizar');
    }
    final response = await _supabase
        .from('suppliers')
        .update(supplier.toMapForUpdate())
        .eq('id', supplier.id!)
        .select()
        .single();
    return Supplier.fromMap(response);
  }

  Future<void> deleteSupplier(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de proveedor no válido');
    await _supabase.from('suppliers').delete().eq('id', id);
  }

  // ==================== INFORMACIÓN DE PRODUCTOS POR PROVEEDOR ====================
  Future<List<SupplierProductInfo>> getSupplierProductInfoForSupplier(String supplierId) async {
    if (!isValidUuid(supplierId)) throw ArgumentError('ID de proveedor no válido');
    // No hay .order() aquí, por lo que .eq() funciona directamente después de .select()
    final response = await _supabase
        .from('supplier_product_info')
        .select('*, products(id, name, sale_price)')
        .eq('supplier_id', supplierId); // Esto está bien
    return (response as List).map((item) => SupplierProductInfo.fromMap(item)).toList();
  }
  
  Future<SupplierProductInfo> addSupplierProductInfo(SupplierProductInfo spi) async {
    final response = await _supabase
        .from('supplier_product_info')
        .insert(spi.toMapForInsert())
        .select('*, products(id, name, sale_price)')
        .single();
    return SupplierProductInfo.fromMap(response);
  }

  Future<SupplierProductInfo> updateSupplierProductInfo(SupplierProductInfo spi) async {
    if (spi.id == null || !isValidUuid(spi.id)) {
      throw ArgumentError('ID de SupplierProductInfo no válido para actualizar');
    }
    final response = await _supabase
        .from('supplier_product_info')
        .update(spi.toMapForUpdate())
        .eq('id', spi.id!)
        .select('*, products(id, name, sale_price)')
        .single();
    return SupplierProductInfo.fromMap(response);
  }

  Future<void> deleteSupplierProductInfo(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de SupplierProductInfo no válido');
    await _supabase.from('supplier_product_info').delete().eq('id', id);
  }

  // ==================== CLIENTES (Customers) ====================
  Future<List<Customer>> getCustomers() async {
    final response = await _supabase
        .from('customers')
        .select('*')
        .order('name', ascending: true);
    return (response as List).map((item) => Customer.fromMap(item)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de cliente no válido');
    final response = await _supabase
        .from('customers')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response != null ? Customer.fromMap(response) : null;
  }
  
   Future<CustomerReceivable?> getCustomerReceivableById(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de cuenta por cobrar no válido');
    final response = await _supabase
      .from('customer_receivables')
      .select('*, customers(id, name), transactions(id, description, products(id, name))') // Ajusta joins según necesites
      .eq('id', id)
      .maybeSingle();
    return response != null ? CustomerReceivable.fromMap(response) : null;
  }

  Future<Customer> addCustomer(Customer customer) async {
    final response = await _supabase
        .from('customers')
        .insert(customer.toMapForInsert())
        .select()
        .single();
    return Customer.fromMap(response);
  }

  Future<Customer> updateCustomer(Customer customer) async {
    if (customer.id == null || !isValidUuid(customer.id)) {
      throw ArgumentError('ID de cliente no válido para actualizar');
    }
    final response = await _supabase
        .from('customers')
        .update(customer.toMapForUpdate())
        .eq('id', customer.id!)
        .select()
        .single();
    return Customer.fromMap(response);
  }

  Future<void> deleteCustomer(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de cliente no válido');
    await _supabase.from('customers').delete().eq('id', id);
  }

  // ==================== ENLACE VENTA-CLIENTE (Sale Customer Link) ====================
  Future<SaleCustomerLink> linkSaleToCustomer(String saleTransactionId, String customerId) async {
    if (!isValidUuid(saleTransactionId)) throw ArgumentError('ID de transacción de venta no válido');
    if (!isValidUuid(customerId)) throw ArgumentError('ID de cliente no válido');
    
    final response = await _supabase.from('sale_customer_link').insert({
      'sale_transaction_id': saleTransactionId,
      'customer_id': customerId,
    }).select().single();
    return SaleCustomerLink.fromMap(response);
  }

  Future<Customer?> getCustomerForSale(String saleTransactionId) async {
    if (!isValidUuid(saleTransactionId)) throw ArgumentError('ID de transacción de venta no válido');
    final response = await _supabase
        .from('sale_customer_link')
        .select('customers(*)')
        .eq('sale_transaction_id', saleTransactionId)
        .maybeSingle();

    if (response != null && response['customers'] != null) {
      return Customer.fromMap(response['customers'] as Map<String, dynamic>);
    }
    return null;
  }

  // ==================== FACTURAS DE PROVEEDORES (Supplier Invoices) ====================
  Future<List<SupplierInvoice>> getSupplierInvoices({String? supplierId, String? status}) async {
    // CORRECCIÓN AQUÍ: Aplicar filtros antes de .order()
    PostgrestFilterBuilder<List<Map<String, dynamic>>> queryBuilder = _supabase
        .from('supplier_invoices')
        .select('*, suppliers(id, name)');

    if (supplierId != null && isValidUuid(supplierId)) {
      queryBuilder = queryBuilder.eq('supplier_id', supplierId);
    }
    if (status != null && status.isNotEmpty) {
      queryBuilder = queryBuilder.eq('status', status);
    }
    
    // Aplicar .order() después de todos los filtros
    final response = await queryBuilder.order('due_date', ascending: true);
    return (response).map((item) => SupplierInvoice.fromMap(item)).toList();
  }

  Future<SupplierInvoice> addSupplierInvoice(SupplierInvoice invoice) async {
    final response = await _supabase
        .from('supplier_invoices')
        .insert(invoice.toMapForInsert())
        .select('*, suppliers(id, name)')
        .single();
    return SupplierInvoice.fromMap(response);
  }

  Future<SupplierInvoice> updateSupplierInvoice(SupplierInvoice invoice) async {
    if (invoice.id == null || !isValidUuid(invoice.id)) {
      throw ArgumentError('ID de factura no válido para actualizar');
    }
    final response = await _supabase
        .from('supplier_invoices')
        .update(invoice.toMapForUpdate())
        .eq('id', invoice.id!)
        .select('*, suppliers(id, name)')
        .single();
    return SupplierInvoice.fromMap(response);
  }

  Future<void> deleteSupplierInvoice(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de factura no válido');
    await _supabase.from('supplier_invoices').delete().eq('id', id);
  }

  // ==================== CUENTAS POR COBRAR A CLIENTES (Customer Receivables) ====================
  Future<List<CustomerReceivable>> getCustomerReceivables({String? customerId, String? status}) async {
    // CORRECCIÓN AQUÍ: Aplicar filtros antes de .order()
    PostgrestFilterBuilder<List<Map<String, dynamic>>> queryBuilder = _supabase
        .from('customer_receivables')
        .select('*, customers(id, name), transactions(id, description, products(id, name))'); 
    
    if (customerId != null && isValidUuid(customerId)) {
      queryBuilder = queryBuilder.eq('customer_id', customerId);
    }
    if (status != null && status.isNotEmpty) {
      queryBuilder = queryBuilder.eq('status', status);
    }

    // Aplicar .order() después de todos los filtros
    final response = await queryBuilder.order('due_date', ascending: true);
    return (response).map((item) => CustomerReceivable.fromMap(item)).toList();
  }

  Future<CustomerReceivable> addCustomerReceivable(CustomerReceivable receivable) async {
    if (!isValidUuid(receivable.saleTransactionId)) throw ArgumentError('ID de transacción de venta no válido');
    if (!isValidUuid(receivable.customerId)) throw ArgumentError('ID de cliente no válido');

    final response = await _supabase
        .from('customer_receivables')
        .insert(receivable.toMapForInsert())
        .select('*, customers(id, name), transactions(id, description, products(id, name))')
        .single();
    return CustomerReceivable.fromMap(response);
  }

  Future<CustomerReceivable> updateCustomerReceivable(CustomerReceivable receivable) async {
    if (receivable.id == null || !isValidUuid(receivable.id)) {
      throw ArgumentError('ID de cuenta por cobrar no válido para actualizar');
    }
    final response = await _supabase
        .from('customer_receivables')
        .update(receivable.toMapForUpdate())
        .eq('id', receivable.id!)
        .select('*, customers(id, name), transactions(id, description, products(id, name))')
        .single();
    return CustomerReceivable.fromMap(response);
  }

  Future<void> deleteCustomerReceivable(String id) async {
    if (!isValidUuid(id)) throw ArgumentError('ID de cuenta por cobrar no válido');
    await _supabase.from('customer_receivables').delete().eq('id', id);
  }

  // ==================== OPERACIONES COMBINADAS CON RPC (CON ID DEVUELTO) ====================
  Future<String> registerPurchase({
    required String productId,
    required String productName,
    required int quantity,
    required double unitCost,
  }) async {
    if (!isValidUuid(productId)) throw ArgumentError('ID de producto no válido');
    if (quantity <= 0) throw ArgumentError('La cantidad debe ser positiva');
    if (unitCost < 0) throw ArgumentError('El costo unitario no puede ser negativo');

    try {
      final dynamic transactionIdResponse = await _supabase.rpc('register_purchase_transaction', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_unit_cost': unitCost,
        'p_description': 'Compra de $productName',
      });

      if (transactionIdResponse == null) {
        throw Exception('No se pudo registrar la compra o la función RPC no devolvió un ID.');
      }
      return transactionIdResponse as String;
    } catch (e) {
      print('Error en registerPurchase RPC: $e');
      rethrow;
    }
  }

  Future<String> registerSale({
    required String productId,
    required String productName,
    required int quantity,
  }) async {
    if (!isValidUuid(productId)) throw ArgumentError('ID de producto no válido');
    if (quantity <= 0) throw ArgumentError('La cantidad debe ser positiva');

    try {
      final dynamic transactionIdResponse = await _supabase.rpc('register_sale_transaction', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_description': 'Venta de $productName',
      });

      if (transactionIdResponse == null) {
        throw Exception('No se pudo registrar la venta o la función RPC no devolvió un ID.');
      }
      return transactionIdResponse as String;
    } on PostgrestException catch (error) {
        if (error.message.contains('Stock insuficiente')) {
            throw Exception('Stock insuficiente para realizar la venta.');
        }
        print('Error de PostgREST en registerSale RPC: ${error.message}');
        rethrow;
    } catch (e) {
      print('Error en registerSale RPC: $e');
      rethrow;
    }
  }

  // ==================== GASTOS E INGRESOS GENÉRICOS (Usando addGenericTransaction) ====================
  Future<Transaction> registerGenericExpense({
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    if (amount <= 0) throw ArgumentError('El monto debe ser positivo');
    
    return await addGenericTransaction(
      Transaction(
        id: _uuid.v4(),
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

  Future<Transaction> registerGenericIncome({
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    if (amount <= 0) throw ArgumentError('El monto debe ser positivo');
    
    return await addGenericTransaction(
      Transaction(
        id: _uuid.v4(),
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