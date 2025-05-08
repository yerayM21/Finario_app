import 'package:flutter/material.dart';
import '../../models/supplier.dart';
import '../../services/DatabaseService.dart';
// Podrías tener un widget reutilizable para campos de texto
// import '../../widgets/custom_text_form_field.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier; // Null para agregar, con datos para editar

  SupplierFormScreen({Key? key, this.supplier}) : super(key: key);

  @override
  _SupplierFormScreenState createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  // Puedes agregar más controladores para otros contactDetails

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    // Inicializar contactDetails (ejemplo simple)
    final contactDetails = widget.supplier?.contactDetails;
    _phoneController = TextEditingController(text: contactDetails?['phone'] as String? ?? '');
    _emailController = TextEditingController(text: contactDetails?['email'] as String? ?? '');
    _addressController = TextEditingController(text: contactDetails?['address'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = true);

    // Construir el mapa de contactDetails
    Map<String, dynamic> contactDetailsMap = {};
    if (_phoneController.text.isNotEmpty) contactDetailsMap['phone'] = _phoneController.text.trim();
    if (_emailController.text.isNotEmpty) contactDetailsMap['email'] = _emailController.text.trim();
    if (_addressController.text.isNotEmpty) contactDetailsMap['address'] = _addressController.text.trim();
    // Agrega más campos si es necesario

    try {
      Supplier supplierToSave;
      if (widget.supplier == null) { // Agregando nuevo proveedor
        supplierToSave = Supplier(
          // id será generado por la BD o puedes generarlo aquí si tu modelo/servicio lo espera
          name: _nameController.text.trim(),
          contactDetails: contactDetailsMap.isNotEmpty ? contactDetailsMap : null,
        );
        await _dbService.addSupplier(supplierToSave);
         _showFeedback('Proveedor "${supplierToSave.name}" agregado exitosamente.', false);
      } else { // Editando proveedor existente
        supplierToSave = Supplier(
          id: widget.supplier!.id, // Usar el ID existente
          name: _nameController.text.trim(),
          contactDetails: contactDetailsMap.isNotEmpty ? contactDetailsMap : null,
          createdAt: widget.supplier!.createdAt, // Mantener fecha de creación original
        );
        await _dbService.updateSupplier(supplierToSave);
        _showFeedback('Proveedor "${supplierToSave.name}" actualizado exitosamente.', false);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Devuelve true para indicar que hubo cambios
      }

    } catch (e) {
      if (mounted) {
         _showFeedback('Error al guardar proveedor: ${e.toString().replaceFirst("Exception: ", "")}', true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  void _showFeedback(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Agregar Proveedor' : 'Editar Proveedor'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSupplier,
            tooltip: 'Guardar Proveedor',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Proveedor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Detalles de Contacto (Opcional)', style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$').hasMatch(value)) {
                      return 'Ingrese un correo electrónico válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
              ),
              // Puedes agregar más campos para contactDetails aquí
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving 
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.save),
                label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR PROVEEDOR'),
                onPressed: _isSaving ? null : _saveSupplier,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 16)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}