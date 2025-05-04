import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
  final Uuid _uuid = Uuid();

  // Variables de estado
  String _transactionType = 'expense';
  String? _selectedCategory = 'Suministros';
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _dbService.getTransactions();
      final products = await _dbService.getProducts();
      
      // Verificación de UUIDs válidos
      for (final product in products) {
        if (!_isValidUuid(product.id)) {
          throw Exception('Producto con ID inválido: ${product.id}');
        }
      }

      setState(() {
        _transactions = transactions;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error al cargar datos: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  bool _isValidUuid(String id) {
    return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(id);
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final isProductTransaction = _showProductFields && _selectedProductId != null;

    try {
      if (isProductTransaction) {
        if (!_isValidUuid(_selectedProductId!)) {
          throw Exception('ID de producto no válido');
        }

        final product = _products.firstWhere(
          (p) => p.id == _selectedProductId,
          orElse: () => throw Exception('Producto no encontrado')
        );

        final quantity = int.parse(_quantityController.text);

        if (_transactionType == 'income') {
          await _dbService.registerSale(
            product: product,
            quantity: quantity,
          );
        } else {
          await _dbService.registerPurchase(
            product: product,
            quantity: quantity,
            unitCost: amount / quantity,
          );
        }
      } else {
        await _dbService.addTransaction(
          Transaction(
            type: _transactionType,
            amount: _transactionType == 'income' ? amount : -amount,
            description: _descriptionController.text,
            category: _selectedCategory!,
            productId: null,
            quantity: null,
            date: _selectedDate,
          ),
        );
      }

      _resetForm();
      await _loadInitialData();
      _showSuccess('Transacción registrada exitosamente');
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    setState(() {
      _selectedProductId = null;
      _showProductFields = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
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
            onPressed: _loadInitialData,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${balance.toStringAsFixed(2)}',
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
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nueva Transacción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTransactionTypeButton('Gasto', 'expense'),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTransactionTypeButton('Ingreso', 'income'),
                  ),
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
                validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories[_transactionType]!.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('¿Vinculado a producto?'),
                value: _showProductFields,
                onChanged: (value) => setState(() => _showProductFields = value),
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
                  validator: (value) => _showProductFields && value == null ? 'Seleccione un producto' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_showProductFields && (value?.isEmpty ?? true)) return 'Requerido';
                    if (_showProductFields && int.tryParse(value ?? '0') == 0) return 'Cantidad inválida';
                    return null;
                  },
                ),
              ],
              SizedBox(height: 16),
              ListTile(
                title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitTransaction,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Registrar Transacción',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeButton(String label, String value) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: _transactionType == value ? Colors.blue[50] : null,
        side: BorderSide(
          color: _transactionType == value ? Colors.blue : Colors.grey,
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () {
        setState(() {
          _transactionType = value;
          _selectedCategory = _categories[value]?.first;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: _transactionType == value ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Historial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          separatorBuilder: (context, index) => Divider(height: 1),
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            final product = transaction.productId != null
                ? _products.firstWhere(
                    (p) => p.id == transaction.productId,
                    orElse: () => Product(
                      id: '',
                      name: 'Producto eliminado',
                      quantity: 0,
                      unitCost: 0,
                      salePrice: 0,
                      updatedAt: DateTime.now(),
                    ),
                  )
                : null;

            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transaction.type == 'income'
                      ? Colors.green[50]
                      : Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.type == 'income'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: transaction.type == 'income'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              title: Text(transaction.description),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product != null)
                    Text(
                      '${product.name}${transaction.quantity != null ? ' (x${transaction.quantity})' : ''}',
                      style: TextStyle(fontSize: 12),
                    ),
                  Text(
                    '${transaction.category} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Text(
                '${transaction.type == 'income' ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'income'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}