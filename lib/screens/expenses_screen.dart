import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart'; // Uuid no se usa directamente en este archivo
import '../models/product.dart';
import '../models/transaction.dart';
import '../services/DatabaseService.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();

  // Variables de estado
  String _transactionType = 'expense'; // 'expense' o 'income'
  String? _selectedCategory; // Se inicializará en initState
  String? _selectedProductId;
  DateTime _selectedDate = DateTime.now();
  List<Transaction> _transactions = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _showProductFields = false;

  // Mantenemos las categorías como estaban
  final Map<String, List<String>> _categories = {
    'expense': ['Compra de Inventario', 'Suministros', 'Salarios', 'Alquiler', 'Otros'],
    'income': ['Venta de Producto', 'Servicios', 'Reembolsos', 'Otros Ingresos'],
  };

  @override
  void initState() {
    super.initState();
    // CORRECCIÓN: Inicializar _selectedCategory basado en _transactionType
    _selectedCategory = _categories[_transactionType]?.first;
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Usando Record para desestructurar el resultado de Future.wait
      final (transactions, products) = await (
        _dbService.getTransactions(),
        _dbService.getProducts(),
      ).wait;

      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error al cargar datos: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
        _showError('El monto debe ser un número positivo.');
        return;
    }
    
    final isProductTransaction = _showProductFields && _selectedProductId != null;

    try {
      if (isProductTransaction) {
        final product = _products.firstWhere(
          (p) => p.id == _selectedProductId,
          // orElse no es necesario si estamos seguros que _selectedProductId es válido y está en _products
          // La validación del DropdownButtonFormField debería asegurar que _selectedProductId es válido.
        );

        final quantity = int.tryParse(_quantityController.text);
        if (quantity == null || quantity <= 0) {
          _showError('La cantidad del producto debe ser un número entero positivo.');
          return;
        }

        if (_transactionType == 'income') {
          // MEJORA: Validación de stock en el cliente
          if (product.quantity < quantity) {
            _showError('Stock insuficiente para ${product.name}. Stock actual: ${product.quantity}');
            return;
          }
          await _dbService.registerSale(
            product: product,
            quantity: quantity,
          );
        } else { // 'expense'
          // Con la UI mejorada, _selectedCategory debería ser 'Compra de Inventario'
          if (_selectedCategory != 'Compra de Inventario') {
             // Este error ahora es más una salvaguarda interna
            _showError('Error interno: La categoría para compra de producto no es "Compra de Inventario".');
            return;
          }
          await _dbService.registerPurchase(
            product: product,
            quantity: quantity,
            unitCost: amount / quantity, // 'amount' es el costo total
          );
        }
      } else { // Transacción genérica
        if (_selectedCategory == null || _descriptionController.text.isEmpty) {
             _showError('Descripción y categoría son requeridas para transacciones genéricas.');
            return;
        }
        if (_transactionType == 'income') {
          await _dbService.registerGenericIncome(
            amount: amount,
            description: _descriptionController.text,
            category: _selectedCategory!,
            date: _selectedDate,
          );
        } else { // 'expense'
          await _dbService.registerGenericExpense(
            amount: amount,
            description: _descriptionController.text,
            category: _selectedCategory!,
            date: _selectedDate,
          );
        }
      }

      _resetForm();
      await _loadInitialData(); // Recargar datos después de la transacción
      _showSuccess('Transacción registrada exitosamente');
    } catch (e) {
      // Simplificar el mensaje de error si es una excepción de la base de datos
      String errorMessage = e.toString();
      if (e is Exception) {
          final message = e.toString().replaceFirst('Exception: ', '');
          errorMessage = message;
      }
      _showError('Error al registrar transacción: $errorMessage');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    if (!mounted) return;
    setState(() {
      _selectedProductId = null;
      // _showProductFields se mantiene, el usuario decide si la siguiente es de producto
      // _transactionType se mantiene
      // _selectedCategory se ajusta según _transactionType y _showProductFields
      if (_showProductFields) {
        _selectedCategory = (_transactionType == 'expense') ? 'Compra de Inventario' : 'Venta de Producto';
      } else {
        _selectedCategory = _categories[_transactionType]?.first;
      }
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)), // Permitir fechas futuras si es necesario
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el balance aquí para asegurar que se actualiza con _transactions
    final balance = _transactions.fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Transacciones'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInitialData, // Deshabilitar si ya está cargando
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBalanceCard(balance),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(8.0), // Añadir padding general
                    children: [
                      _buildTransactionForm(),
                      SizedBox(height: 20),
                      _buildTransactionList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Balance Actual:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(balance), // Formato de moneda
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionForm() {
    // MEJORA: Determinar si el dropdown de categoría debe estar habilitado
    final bool isCategoryDropdownEnabled = !_showProductFields;
    final String? currentCategoryLabel = _showProductFields
        ? (_transactionType == 'expense' ? 'Compra de Inventario' : 'Venta de Producto')
        : _selectedCategory;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Ajuste de margen
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nueva Transacción', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTransactionTypeButton('Gasto', 'expense')),
                  SizedBox(width: 10),
                  Expanded(child: _buildTransactionTypeButton('Ingreso', 'income')),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  final val = double.tryParse(value);
                  if (val == null) return 'Monto inválido';
                  if (val <= 0) return 'El monto debe ser positivo';
                  return null;
                },
              ),
              SizedBox(height: 16),
              // La descripción es opcional para compras/ventas de producto (se autogenera)
              // pero requerida para genéricos.
              if (!_showProductFields)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => 
                    !_showProductFields && (value == null || value.isEmpty) ? 'Requerido para genéricos' : null,
                ),
              if (!_showProductFields) SizedBox(height: 16),

              // Dropdown de Categoría
              DropdownButtonFormField<String>(
                value: currentCategoryLabel, // Usar el label actual
                items: (_categories[_transactionType] ?? []).map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: isCategoryDropdownEnabled
                    ? (value) => setState(() => _selectedCategory = value)
                    : null, // Deshabilitado si _showProductFields es true
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  filled: !isCategoryDropdownEnabled,
                  fillColor: !isCategoryDropdownEnabled ? Colors.grey[200] : null,
                ),
                validator: (value) => value == null ? 'Seleccione una categoría' : null,
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('¿Vincular a producto de inventario?'),
                value: _showProductFields,
                onChanged: (newValue) {
                  setState(() {
                    _showProductFields = newValue;
                    _quantityController.clear(); // Limpiar cantidad al cambiar
                    _selectedProductId = null; // Deseleccionar producto
                    if (newValue) { // Si se activan los campos de producto
                      _descriptionController.clear(); // Descripción es automática para productos
                      _selectedCategory = (_transactionType == 'expense')
                          ? 'Compra de Inventario'
                          : 'Venta de Producto';
                    } else { // Si se desactivan (transacción genérica)
                      _selectedCategory = _categories[_transactionType]?.first;
                    }
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              if (_showProductFields) ...[
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  items: _products.map((product) {
                    return DropdownMenuItem(
                      value: product.id,
                      child: Text('${product.name} (Stock: ${product.quantity})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedProductId = value),
                  decoration: InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _showProductFields && value == null
                      ? 'Seleccione un producto'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad de Producto',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  // CORRECCIÓN: Validador de cantidad mejorado
                  validator: (value) {
                    if (!_showProductFields) return null; // No validar si no se muestra
                    if (value == null || value.isEmpty) return 'Requerido';
                    final quantity = int.tryParse(value);
                    if (quantity == null) return 'Cantidad debe ser un número';
                    if (quantity <= 0) return 'Cantidad debe ser positiva';
                    return null;
                  },
                ),
              ],
              SizedBox(height: 16),
              ListTile(
                title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : Text('Registrar Transacción'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeButton(String label, String typeValue) {
    final bool isActive = _transactionType == typeValue;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[300],
        foregroundColor: isActive ? Theme.of(context).colorScheme.onPrimary : Colors.black87,
        side: BorderSide(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () {
        if (_transactionType == typeValue) return; // No hacer nada si ya está seleccionado
        setState(() {
          _transactionType = typeValue;
          // MEJORA: Ajustar categoría al cambiar tipo
          if (_showProductFields) {
            _selectedCategory = (typeValue == 'expense')
                ? 'Compra de Inventario'
                : 'Venta de Producto';
          } else {
            _selectedCategory = _categories[typeValue]?.first;
          }
        });
      },
      child: Text(label),
    );
  }

 Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('No hay transacciones registradas.', style: TextStyle(fontSize: 16, color: Colors.grey[600]))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Historial de Transacciones', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            // El nombre del producto ya viene en transaction.productName si el join funcionó
            final String? displayProductName = transaction.productName;

            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: transaction.amount >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  transaction.amount >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: transaction.amount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
              ),
              title: Text(
                transaction.description,
                style: TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction.category} • ${DateFormat('dd/MM/yyyy, hh:mm a').format(transaction.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  if (displayProductName != null)
                    Text(
                      'Producto: $displayProductName${transaction.quantity != null ? " (x${transaction.quantity})" : ""}',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              trailing: Text(
                NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(transaction.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: transaction.amount >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}