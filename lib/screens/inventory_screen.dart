import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart'; // Asegúrate que la ruta es correcta
import '../services/DatabaseService.dart'; // Asegúrate que la ruta es correcta

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

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error al cargar productos: ${e.toString().replaceFirst("Exception: ", "")}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    // Construir el objeto Product.
    // El ID se genera aquí para nuevos productos.
    // createdAt y updatedAt son manejados por la BD y los triggers, no se envían desde el cliente.
    final product = Product(
      id: _editingProduct?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 0,
      unitCost: double.tryParse(_unitCostController.text) ?? 0.0,
      salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
      restockDate: _restockDate,
      expirationDate: _expirationDate,
      // No se establece 'createdAt' ni 'updatedAt' aquí.
      // El modelo Product y DatabaseService se encargarán de usar el toMap correcto.
    );

    try {
      Product savedProduct;
      if (_editingProduct != null) {
        // DatabaseService.updateProduct usará product.toMapForUpdate() (o similar)
        savedProduct = await _dbService.updateProduct(product); 
      } else {
        // DatabaseService.addProduct usará product.toMapAllFields() (o similar que incluya el ID del cliente)
        savedProduct = await _dbService.addProduct(product);
      }
      
      _resetForm();
      await _loadProducts(); // Recarga la lista, que también actualiza _isLoading
      _showSuccess(_editingProduct != null ? 'Producto "${savedProduct.name}" actualizado' : 'Producto "${savedProduct.name}" agregado');
    } catch (e) {
      _showError('Error al guardar: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _editProduct(Product product) {
    if (!mounted) return;
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

  Future<void> _deleteProduct(String id, String productName) async {
    // Confirmación antes de eliminar
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el producto "$productName"? Esta acción no se puede deshacer.'),
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

    if (confirmed != true) return; // Si no se confirma, no hacer nada

    if (!mounted) return;
    setState(() => _isLoading = true); // Mostrar indicador mientras se elimina
    try {
      await _dbService.deleteProduct(id);
      await _loadProducts(); // Recarga la lista
      _showSuccess('Producto "$productName" eliminado');
    } catch (e) {
      _showError('Error al eliminar: ${e.toString().replaceFirst("Exception: ", "")}');
      // No es necesario _isLoading = false aquí porque _loadProducts lo maneja si tiene éxito o falla.
      // Pero si _loadProducts falla y no actualiza _isLoading, podría ser necesario.
      // _loadProducts ya se encarga de _isLoading = false en su try/catch.
    } 
    // No es necesario un finally para _isLoading si _loadProducts siempre lo actualiza.
    // Pero por seguridad, si _loadProducts pudiera no llamarse:
    // finally { if (mounted) setState(() => _isLoading = false); }
  }


  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _quantityController.clear();
    _unitCostController.clear();
    _salePriceController.clear();
    if (!mounted) return;
    setState(() {
      _restockDate = null;
      _expirationDate = null;
      _editingProduct = null;
      _showForm = false; // Opcional: decidir si ocultar el form después de guardar/resetear
    });
  }

  Future<void> _selectDate(BuildContext context, DateType dateType) async {
    DateTime initialSelection = DateTime.now();
    if (dateType == DateType.restock && _restockDate != null) {
        initialSelection = _restockDate!;
    } else if (dateType == DateType.expiration && _expirationDate != null) {
        initialSelection = _expirationDate!;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialSelection,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101), // Extendido por un año
      helpText: dateType == DateType.restock 
          ? 'FECHA DE REABASTECIMIENTO'
          : 'FECHA DE CADUCIDAD',
    );
    
    if (picked != null) {
      if (!mounted) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Widget build y otros widgets (sin cambios significativos, se mantienen como estaban)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showForm 
            ? (_editingProduct == null ? 'Agregar Producto' : 'Editar Producto') 
            : 'Gestión de Inventario'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.list : Icons.add_circle_outline),
            onPressed: () {
              if (_showForm && _editingProduct != null) {
                 _resetForm(); // Si estaba editando y cambia a lista, resetea el form
              } else if (_showForm && _editingProduct == null) {
                // Si estaba en form de nuevo producto y cambia a lista, resetea
                _resetForm();
              }
              setState(() => _showForm = !_showForm);
            },
            tooltip: _showForm ? 'Ver Lista de Productos' : 'Agregar Nuevo Producto',
          ),
          if (!_showForm) // Botón de refrescar solo en la lista
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadProducts,
              tooltip: 'Refrescar Lista',
            )
        ],
      ),
      body: _isLoading && !_showForm // Mostrar loader solo si está cargando la lista
          ? Center(child: CircularProgressIndicator())
          : _showForm
              ? _buildProductForm()
              : _buildProductList(),
      floatingActionButton: _showForm
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveProduct,
              tooltip: 'Guardar Producto',
              icon: _isSaving 
                  ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.save),
              label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR'),
            )
          : FloatingActionButton( // FAB para agregar si se está mostrando la lista
              onPressed: () {
                _resetForm(); // Asegurar que el form esté limpio para nuevo producto
                setState(() => _showForm = true);
              },
              tooltip: 'Agregar Producto',
              child: Icon(Icons.add),
            ),
      floatingActionButtonLocation: _showForm 
        ? FloatingActionButtonLocation.centerFloat 
        : FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_basket),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'El nombre es requerido' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Cantidad en Stock',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'La cantidad es requerida';
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
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El costo es requerido';
                final cost = double.tryParse(value!);
                if (cost == null) return 'Ingrese un valor monetario válido';
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
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El precio es requerido';
                final price = double.tryParse(value!);
                if (price == null) return 'Ingrese un valor monetario válido';
                if (price < 0) return 'El precio no puede ser negativo';
                
                final cost = double.tryParse(_unitCostController.text);
                if (cost != null && price < cost) {
                  return 'El precio de venta debe ser mayor o igual al costo';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            _buildDateTile(
              context,
              date: _restockDate,
              label: 'Fecha de Reabastecimiento',
              isRequired: false, // Depende de tu lógica de negocio
              dateType: DateType.restock,
            ),
            _buildDateTile(
              context,
              date: _expirationDate,
              label: 'Fecha de Caducidad',
              isRequired: false, // Opcional
              dateType: DateType.expiration,
            ),
            SizedBox(height: 70), // Espacio para el FAB
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required DateTime? date,
    required String label,
    required bool isRequired, // Puedes usar esto para validación si es necesario
    required DateType dateType,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(dateType == DateType.restock ? Icons.inventory_2_outlined : Icons.event_busy_outlined),
        title: Text(date == null ? label : '$label: ${_formatDate(date)}'),
        subtitle: date == null ? Text('Toca para seleccionar') : null,
        trailing: date != null 
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]), 
                onPressed: () {
                  setState(() {
                    if (dateType == DateType.restock) _restockDate = null;
                    else _expirationDate = null;
                  });
                },
                tooltip: 'Limpiar fecha',
              )
            : Icon(Icons.calendar_today_outlined, color: Theme.of(context).primaryColor),
        onTap: () => _selectDate(context, dateType),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  Widget _buildProductList() {
    if (_products.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No hay productos en el inventario.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Agregar Primer Producto'),
              onPressed: () {
                _resetForm();
                setState(() => _showForm = true);
              },
            )
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 80), // Espacio para el FAB de agregar
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final isLowStock = product.quantity < 10 && product.quantity > 0; // Ajusta el umbral
          final isOutOfStock = product.quantity <= 0;
          final isNearlyExpired = product.expirationDate != null &&
              product.expirationDate!.isAfter(DateTime.now()) &&
              product.expirationDate!.difference(DateTime.now()).inDays < 30; // Caduca en menos de 30 días
          final isExpired = product.expirationDate != null && 
              product.expirationDate!.isBefore(DateTime.now().subtract(Duration(days: 1))); // Ayer o antes

          Color cardColor = Theme.of(context).cardColor;
          if (isExpired) cardColor = Colors.red.shade100;
          else if (isOutOfStock) cardColor = Colors.orange.shade100;
          else if (isNearlyExpired) cardColor = Colors.yellow.shade100;
          else if (isLowStock) cardColor = Colors.amber.shade100;


          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
                  style: TextStyle(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.red.shade900 : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Stock: ${product.quantity}', style: TextStyle(fontWeight: isOutOfStock || isLowStock ? FontWeight.bold : FontWeight.normal)),
                  Text('Costo: ${_formatCurrency(product.unitCost)} | Precio Venta: ${_formatCurrency(product.salePrice)}'),
                  if (product.expirationDate != null)
                    Text(
                      'Caduca: ${_formatDate(product.expirationDate)}',
                      style: TextStyle(
                        color: isExpired ? Colors.red.shade900 : (isNearlyExpired ? Colors.orange.shade900 : null),
                        fontWeight: isExpired || isNearlyExpired ? FontWeight.bold : null,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(
                    icon: Icon(Icons.edit_note, color: Theme.of(context).primaryColorDark),
                    onPressed: () => _editProduct(product),
                    tooltip: 'Editar Producto',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                    onPressed: () => _deleteProduct(product.id!, product.name), // Asumimos que product.id no es null aquí
                    tooltip: 'Eliminar Producto',
                  ),
                ],
              )
            ),
          );
        },
      ),
    );
  }
}