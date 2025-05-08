// lib/screens/customers/customer_form_screen.dart
import 'package:flutter/material.dart';
import '../../models/customer.dart'; // Asegúrate que el enum CustomerType esté aquí o importado
import '../../services/DatabaseService.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  CustomerFormScreen({Key? key, this.customer}) : super(key: key);

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  CustomerType _selectedCustomerType = CustomerType.regular;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    final contactDetails = widget.customer?.contactDetails;
    _phoneController = TextEditingController(text: contactDetails?['phone'] as String? ?? '');
    _emailController = TextEditingController(text: contactDetails?['email'] as String? ?? '');
    _addressController = TextEditingController(text: contactDetails?['address'] as String? ?? '');
    _notesController = TextEditingController(text: widget.customer?.notes ?? '');
    _selectedCustomerType = widget.customer?.customerType ?? CustomerType.regular;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    Map<String, dynamic> contactDetailsMap = {};
    if (_phoneController.text.isNotEmpty) contactDetailsMap['phone'] = _phoneController.text.trim();
    if (_emailController.text.isNotEmpty) contactDetailsMap['email'] = _emailController.text.trim();
    if (_addressController.text.isNotEmpty) contactDetailsMap['address'] = _addressController.text.trim();

    try {
      Customer customerToSave;
      if (widget.customer == null) {
        customerToSave = Customer(
          name: _nameController.text.trim(),
          contactDetails: contactDetailsMap.isNotEmpty ? contactDetailsMap : null,
          customerType: _selectedCustomerType,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        await _dbService.addCustomer(customerToSave);
        _showFeedback('Cliente "${customerToSave.name}" agregado exitosamente.', false);
      } else {
        customerToSave = Customer(
          id: widget.customer!.id,
          name: _nameController.text.trim(),
          contactDetails: contactDetailsMap.isNotEmpty ? contactDetailsMap : null,
          customerType: _selectedCustomerType,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          createdAt: widget.customer!.createdAt,
        );
        await _dbService.updateCustomer(customerToSave);
         _showFeedback('Cliente "${customerToSave.name}" actualizado exitosamente.', false);
      }
      if(mounted) Navigator.of(context).pop(true); // Indicar que hubo cambios
    } catch (e) {
      if(mounted) _showFeedback('Error al guardar cliente: ${e.toString()}', true);
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  void _showFeedback(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst("Exception: ", "")),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Agregar Cliente' : 'Editar Cliente'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveCustomer,
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
                decoration: InputDecoration(labelText: 'Nombre del Cliente', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es requerido.' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<CustomerType>(
                value: _selectedCustomerType,
                decoration: InputDecoration(labelText: 'Tipo de Cliente', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                items: CustomerType.values.map((CustomerType type) {
                  return DropdownMenuItem<CustomerType>(
                    value: type,
                    child: Text(type.name[0].toUpperCase() + type.name.substring(1)), // Capitalize
                  );
                }).toList(),
                onChanged: (CustomerType? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCustomerType = newValue);
                  }
                },
              ),
              SizedBox(height: 16),
              Text('Detalles de Contacto (Opcional)', style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
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
                decoration: InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                keyboardType: TextInputType.streetAddress,
                maxLines:2,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notas Adicionales', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving 
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.save),
                label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR CLIENTE'),
                onPressed: _isSaving ? null : _saveCustomer,
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