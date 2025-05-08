import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart'; // No se usa directamente
import '../models/product.dart'; // Asegúrate que la ruta es correcta
import '../models/transaction.dart'; // Asegúrate que la ruta es correcta
import '../services/DatabaseService.dart'; // Asegúrate que la ruta es correcta

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
  String? _selectedCategory;
  String? _selectedProductId;
  DateTime _selectedDate = DateTime.now();
  List<Transaction> _transactions = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _showProductFields = false;

  final Map<String, List<String>> _categories = {
    'expense': ['Compra de Inventario', 'Suministros', 'Salarios', 'Alquiler', 'Otros'],
    'income': ['Venta de Producto', 'Servicios', 'Reembolsos', 'Otros Ingresos'],
  };

  @override
  void initState() {
    super.initState();
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
      _showError('Error al cargar datos: ${e.toString().replaceFirst("Exception: ", "")}');
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
    // Bloquear el botón mientras se procesa
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String? transactionId; // Para almacenar el ID devuelto, aunque no se use directamente aquí

      if (isProductTransaction) {
        final product = _products.firstWhere((p) => p.id == _selectedProductId);
        final quantity = int.tryParse(_quantityController.text);

        if (quantity == null || quantity <= 0) {
          _showError('La cantidad del producto debe ser un número entero positivo.');
          setState(() => _isLoading = false); // Desbloquear botón
          return;
        }

        if (_transactionType == 'income') { // Venta de producto
          if (product.quantity < quantity) {
            _showError('Stock insuficiente para ${product.name}. Stock actual: ${product.quantity}');
            setState(() => _isLoading = false); // Desbloquear botón
            return;
          }
          // LLAMADA ACTUALIZADA A registerSale
          transactionId = await _dbService.registerSale(
            productId: product.id!, // Pasar productId como String
            productName: product.name, // Pasar productName como String
            quantity: quantity,
          );
        } else { // Compra de producto ('expense')
          if (_selectedCategory != 'Compra de Inventario') {
            _showError('Error interno: La categoría para compra de producto no es "Compra de Inventario".');
            setState(() => _isLoading = false); // Desbloquear botón
            return;
          }
          // LLAMADA ACTUALIZADA A registerPurchase
          transactionId = await _dbService.registerPurchase(
            productId: product.id!, // Pasar productId como String
            productName: product.name, // Pasar productName como String
            quantity: quantity,
            unitCost: amount / quantity, // 'amount' es el costo total de la compra para esta UI
          );
        }
      } else { // Transacción genérica
        if (_selectedCategory == null || _descriptionController.text.isEmpty) {
          _showError('Descripción y categoría son requeridas para transacciones genéricas.');
          setState(() => _isLoading = false); // Desbloquear botón
          return;
        }
        if (_transactionType == 'income') {
          // addGenericIncome devuelve Transaction, podemos obtener el ID si es necesario
          final genericTx = await _dbService.registerGenericIncome(
            amount: amount,
            description: _descriptionController.text,
            category: _selectedCategory!,
            date: _selectedDate,
          );
          transactionId = genericTx.id;
        } else { // 'expense'
          final genericTx = await _dbService.registerGenericExpense(
            amount: amount,
            description: _descriptionController.text,
            category: _selectedCategory!,
            date: _selectedDate,
          );
          transactionId = genericTx.id;
        }
      }

      _resetForm();
      await _loadInitialData(); // Recarga los datos, lo que ya quita el _isLoading
      _showSuccess('Transacción registrada exitosamente${transactionId != null ? " (ID: ${transactionId.substring(0,8)}...)" : ""}');
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }
      _showError('Error al registrar transacción: $errorMessage');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Asegurar que se desbloquee el botón
      }
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
      lastDate: DateTime.now().add(Duration(days: 365)),
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
    final balance = _transactions.fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Transacciones'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInitialData,
          ),
        ],
      ),
      body: _isLoading && _transactions.isEmpty // Mostrar loading solo si no hay transacciones cargadas aún
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBalanceCard(balance),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(8.0),
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
              NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(balance),
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
    final bool isCategoryDropdownEnabled = !_showProductFields;
    final String? currentCategoryLabel = _showProductFields
        ? (_transactionType == 'expense' ? 'Compra de Inventario' : 'Venta de Producto')
        : _selectedCategory;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  labelText: _showProductFields && _transactionType == 'expense'
                      ? 'Monto Total de Compra' // Para Compra de Inventario, este es el costo total
                      : 'Monto', // Para Ventas (se calcula) o Genéricos
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
              DropdownButtonFormField<String>(
                value: currentCategoryLabel,
                items: (_categories[_transactionType] ?? []).map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: isCategoryDropdownEnabled
                    ? (value) => setState(() => _selectedCategory = value)
                    : null,
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
                    _quantityController.clear();
                    _selectedProductId = null;
                    if (newValue) {
                      _descriptionController.clear();
                      _selectedCategory = (_transactionType == 'expense')
                          ? 'Compra de Inventario'
                          : 'Venta de Producto';
                      // Para ventas, el monto se calcula desde el precio del producto,
                      // así que podríamos deshabilitar o limpiar el _amountController
                      // o cambiar su etiqueta para reflejar que es informativo o no aplica.
                      // Para compras, _amountController es el costo total.
                      if (_transactionType == 'income') {
                        //_amountController.clear(); // Opcional: limpiar monto si es venta de producto
                      }
                    } else {
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
                  validator: (value) {
                    if (!_showProductFields) return null;
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
                child: _isLoading 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
                    : Text('Registrar Transacción'),
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
        if (_transactionType == typeValue) return;
        setState(() {
          _transactionType = typeValue;
          if (_showProductFields) {
            _selectedCategory = (typeValue == 'expense')
                ? 'Compra de Inventario'
                : 'Venta de Producto';
            // Si cambia a venta de producto, el campo de monto podría ser interpretado diferente.
            // if (typeValue == 'income') _amountController.clear(); 
          } else {
            _selectedCategory = _categories[typeValue]?.first;
          }
        });
      },
      child: Text(label),
    );
  }

 Widget _buildTransactionList() {
    if (_transactions.isEmpty && !_isLoading) { // Mostrar mensaje solo si no está cargando y no hay transacciones
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('No hay transacciones registradas.', style: TextStyle(fontSize: 16, color: Colors.grey[600]))),
      );
    }
    if (_isLoading && _transactions.isEmpty) { // Si está cargando y no hay nada, no mostrar lista aún (ya hay un loader global)
        return SizedBox.shrink();
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
                  if (displayProductName != null && displayProductName.isNotEmpty)
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