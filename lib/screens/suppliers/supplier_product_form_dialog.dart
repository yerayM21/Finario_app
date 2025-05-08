// lib/screens/suppliers/supplier_product_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/supplier_product_info.dart';
import '../../services/DatabaseService.dart';

class SupplierProductFormDialog extends StatefulWidget {
  final String supplierId;
  final SupplierProductInfo? existingSpi; // Null para agregar nuevo
  final List<Product> allProducts;
  final String? productName; // Nombre del producto si se está editando

  SupplierProductFormDialog({
    Key? key,
    required this.supplierId,
    this.existingSpi,
    required this.allProducts,
    this.productName,
  }) : super(key: key);

  @override
  _SupplierProductFormDialogState createState() => _SupplierProductFormDialogState();
}

class _SupplierProductFormDialogState extends State<SupplierProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  String? _selectedProductId;
  late TextEditingController _supplyCostController;
  late TextEditingController _deliveryLeadTimeController;
  late TextEditingController _supplierProductCodeController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  bool get _isEditing => widget.existingSpi != null;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.existingSpi?.productId;
    _supplyCostController = TextEditingController(text: widget.existingSpi?.supplyCost.toStringAsFixed(2) ?? '');
    _deliveryLeadTimeController = TextEditingController(text: widget.existingSpi?.deliveryLeadTimeDays?.toString() ?? '');
    _supplierProductCodeController = TextEditingController(text: widget.existingSpi?.supplierProductCode ?? '');
    _notesController = TextEditingController(text: widget.existingSpi?.notes ?? '');
  }

  @override
  void dispose() {
    _supplyCostController.dispose();
    _deliveryLeadTimeController.dispose();
    _supplierProductCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplierProductInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null && !_isEditing) {
      // Debería ser prevenido por el validador del dropdown
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Seleccione un producto."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    final spiToSave = SupplierProductInfo(
      id: widget.existingSpi?.id, // null si es nuevo
      supplierId: widget.supplierId,
      productId: _selectedProductId!, // Validador o lógica asegura que no sea null
      supplyCost: double.tryParse(_supplyCostController.text) ?? 0.0,
      deliveryLeadTimeDays: int.tryParse(_deliveryLeadTimeController.text),
      supplierProductCode: _supplierProductCodeController.text.trim().isNotEmpty ? _supplierProductCodeController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: widget.existingSpi?.createdAt, // Mantener si se edita
    );

    try {
      if (_isEditing) {
        await _dbService.updateSupplierProductInfo(spiToSave);
      } else {
        await _dbService.addSupplierProductInfo(spiToSave);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Información de producto guardada."), backgroundColor: Colors.green));
      Navigator.of(context).pop(true); // Indicar que se guardó algo
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Producto del Proveedor' : 'Vincular Producto al Proveedor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!_isEditing) // Dropdown para seleccionar producto solo si es nuevo
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  hint: Text('Seleccionar Producto'),
                  isExpanded: true,
                  items: widget.allProducts.map((Product product) {
                    return DropdownMenuItem<String>(
                      value: product.id,
                      child: Text(product.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProductId = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Seleccione un producto' : null,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
              if (_isEditing && widget.productName != null) // Mostrar nombre si se edita
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text("Producto: ${widget.productName}", style: Theme.of(context).textTheme.titleMedium),
                ),
              SizedBox(height: 16),
              TextFormField(
                controller: _supplyCostController,
                decoration: InputDecoration(labelText: 'Costo de Suministro', prefixText: '\$ ', border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Costo requerido';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  if (double.parse(value) < 0) return 'Costo no puede ser negativo';
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _deliveryLeadTimeController,
                decoration: InputDecoration(labelText: 'Tiempo de Entrega (días)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                 validator: (value) {
                    if (value != null && value.isNotEmpty) {
                       if (int.tryParse(value) == null) return 'Número inválido';
                       if (int.parse(value) < 0) return 'No puede ser negativo';
                    }
                    return null;
                 }
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _supplierProductCodeController,
                decoration: InputDecoration(labelText: 'Código del Producto (Proveedor)', border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notas Adicionales', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        ),
        ElevatedButton.icon(
          icon: _isSaving 
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
              : Icon(Icons.save),
          label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR'),
          onPressed: _isSaving ? null : _saveSupplierProductInfo,
        ),
      ],
    );
  }
}