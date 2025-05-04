import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/DatabaseService.dart';

enum DateType { restock, expiration }

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = Uuid();
  
  // Controladores para el formulario
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _salePriceController = TextEditingController();
  
  DateTime? _restockDate;
  DateTime? _expirationDate;
  List<Product> _products = [];
  bool _isLoading = true;
  bool _showForm = false;
  bool _isSaving = false;
  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error al cargar productos: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final product = Product(
      id: _editingProduct?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      unitCost: double.parse(_unitCostController.text),
      salePrice: double.parse(_salePriceController.text),
      restockDate: _restockDate,
      expirationDate: _expirationDate,
      updatedAt: DateTime.now(),
    );

    try {
      if (_editingProduct != null) {
        await _dbService.updateProduct(product);
      } else {
        await _dbService.addProduct(product);
      }
      
      _resetForm();
      await _loadProducts();
      _showSuccess(_editingProduct != null ? 'Producto actualizado' : 'Producto agregado');
    } catch (e) {
      _showError('Error al guardar: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _editingProduct = product;
      _nameController.text = product.name;
      _quantityController.text = product.quantity.toString();
      _unitCostController.text = product.unitCost.toStringAsFixed(2);
      _salePriceController.text = product.salePrice.toStringAsFixed(2);
      _restockDate = product.restockDate;
      _expirationDate = product.expirationDate;
      _showForm = true;
    });
  }

  Future<void> _deleteProduct(String id) async {
    try {
      setState(() => _isLoading = true);
      await _dbService.deleteProduct(id);
      await _loadProducts();
      _showSuccess('Producto eliminado');
    } catch (e) {
      _showError('Error al eliminar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _quantityController.clear();
    _unitCostController.clear();
    _salePriceController.clear();
    setState(() {
      _restockDate = null;
      _expirationDate = null;
      _editingProduct = null;
      _showForm = false;
    });
  }

  Future<void> _selectDate(BuildContext context, DateType dateType) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: dateType == DateType.restock 
          ? 'SELECCIONAR FECHA DE REABASTECIMIENTO'
          : 'SELECCIONAR FECHA DE CADUCIDAD',
    );
    
    if (picked != null) {
      setState(() {
        if (dateType == DateType.restock) {
          _restockDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Inventario'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.list : Icons.add),
            onPressed: () {
              if (_showForm) _resetForm();
              setState(() => _showForm = !_showForm);
            },
            tooltip: _showForm ? 'Ver lista' : 'Agregar producto',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _showForm
              ? _buildProductForm()
              : _buildProductList(),
      floatingActionButton: _showForm
          ? FloatingActionButton(
              onPressed: _isSaving ? null : _saveProduct,
              tooltip: 'Guardar Producto',
              child: _isSaving 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
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
                if (value?.isEmpty ?? true) return 'Campo requerido';
                final quantity = int.tryParse(value!);
                if (quantity == null) return 'Ingrese un número válido';
                if (quantity < 0) return 'La cantidad no puede ser negativa';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _unitCostController,
              decoration: InputDecoration(
                labelText: 'Costo Unitario',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                final cost = double.tryParse(value!);
                if (cost == null) return 'Ingrese un valor válido';
                if (cost < 0) return 'El costo no puede ser negativo';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _salePriceController,
              decoration: InputDecoration(
                labelText: 'Precio de Venta',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                final price = double.tryParse(value!);
                if (price == null) return 'Ingrese un valor válido';
                if (price < 0) return 'El precio no puede ser negativo';
                
                final cost = double.tryParse(_unitCostController.text);
                if (cost != null && price < cost) {
                  return 'El precio debe ser mayor al costo';
                }
                
                return null;
              },
            ),
            SizedBox(height: 20),
            _buildDateTile(
              context,
              date: _restockDate,
              label: 'Fecha de Reabastecimiento',
              isRequired: true,
              dateType: DateType.restock,
            ),
            _buildDateTile(
              context,
              date: _expirationDate,
              label: 'Fecha de Caducidad (opcional)',
              isRequired: false,
              dateType: DateType.expiration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required DateTime? date,
    required String label,
    required bool isRequired,
    required DateType dateType,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          date == null ? label : _formatDate(date),
          style: TextStyle(
            color: date == null && isRequired ? Colors.grey[600] : null,
          ),
        ),
        trailing: Icon(Icons.calendar_today),
        onTap: () => _selectDate(context, dateType),
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: _products.isEmpty
          ? Center(
              child: Text(
                'No hay productos registrados',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final isLowStock = product.quantity < 5;
                final isExpired = product.expirationDate != null && 
                    product.expirationDate!.isBefore(DateTime.now());

                return Dismissible(
                  key: Key(product.id),
                  background: Container(color: Colors.red),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirmar'),
                        content: Text('¿Eliminar este producto?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) => _deleteProduct(product.id),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    color: isExpired 
                        ? Colors.red[50] 
                        : isLowStock 
                            ? Colors.orange[50] 
                            : null,
                    child: ListTile(
                      title: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stock: ${product.quantity}'),
                          Text('Costo: ${_formatCurrency(product.unitCost)}'),
                          Text('Precio: ${_formatCurrency(product.salePrice)}'),
                          if (product.restockDate != null)
                            Text('Reabastecer: ${_formatDate(product.restockDate)}'),
                          if (product.expirationDate != null)
                            Text(
                              'Caduca: ${_formatDate(product.expirationDate)}',
                              style: TextStyle(
                                color: isExpired ? Colors.red : null,
                                fontWeight: isExpired ? FontWeight.bold : null,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editProduct(product),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}