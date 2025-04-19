import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para el formulario
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _salePriceController = TextEditingController();
  DateTime? _restockDate;
  DateTime? _expirationDate;
  
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _showForm = false;
  String? _editingProductId;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .order('name', ascending: true);
      
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    final productData = {
      'name': _nameController.text,
      'quantity': int.parse(_quantityController.text),
      'unit_cost': double.parse(_unitCostController.text),
      'sale_price': double.parse(_salePriceController.text),
      'restock_date': _restockDate?.toIso8601String(),
      'expiration_date': _expirationDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (_editingProductId != null) {
        // Actualizar producto existente
        await _supabase
            .from('products')
            .update(productData)
            .eq('id', _editingProductId!);
      } else {
        // Crear nuevo producto
        await _supabase.from('products').insert(productData);
      }
      
      _resetForm();
      _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto guardado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    setState(() {
      _editingProductId = product['id'].toString();
      _nameController.text = product['name'];
      _quantityController.text = product['quantity'].toString();
      _unitCostController.text = product['unit_cost'].toString();
      _salePriceController.text = product['sale_price'].toString();
      _restockDate = product['restock_date'] != null 
          ? DateTime.parse(product['restock_date']) 
          : null;
      _expirationDate = product['expiration_date'] != null
          ? DateTime.parse(product['expiration_date'])
          : null;
      _showForm = true;
    });
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
      _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
      );
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
      _editingProductId = null;
      _showForm = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isRestock) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isRestock) {
          _restockDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
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
              onPressed: _saveProduct,
              child: Icon(Icons.save),
              tooltip: 'Guardar Producto',
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
              decoration: InputDecoration(labelText: 'Nombre del Producto'),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _unitCostController,
              decoration: InputDecoration(labelText: 'Costo Unitario'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _salePriceController,
              decoration: InputDecoration(labelText: 'Precio de Venta'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(_restockDate == null
                  ? 'Seleccionar Fecha de Reabastecimiento'
                  : 'Reabastecimiento: ${DateFormat('dd/MM/yyyy').format(_restockDate!)}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: Text(_expirationDate == null
                  ? 'Seleccionar Fecha de Caducidad (opcional)'
                  : 'Caducidad: ${DateFormat('dd/MM/yyyy').format(_expirationDate!)}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cantidad: ${product['quantity']}'),
                  Text('Costo: \$${product['unit_cost']?.toStringAsFixed(2) ?? '0.00'}'),
                  Text('Precio: \$${product['sale_price']?.toStringAsFixed(2) ?? '0.00'}'),
                  if (product['restock_date'] != null)
                    Text('Reabastecer: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(product['restock_date']))}'),
                  if (product['expiration_date'] != null)
                    Text('Caduca: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(product['expiration_date']))}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editProduct(product),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(product['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(String id) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de eliminar este producto?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(id);
              },
            ),
          ],
        );
      },
    );
  }
}