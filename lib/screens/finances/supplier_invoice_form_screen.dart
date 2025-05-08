// lib/screens/finances/supplier_invoice_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplier.dart';
import '../../models/supplier_invoice.dart';
import '../../services/DatabaseService.dart';

class SupplierInvoiceFormScreen extends StatefulWidget {
  final SupplierInvoice? invoice;
  final List<Supplier> availableSuppliers;

  SupplierInvoiceFormScreen({
    Key? key,
    this.invoice,
    required this.availableSuppliers,
  }) : super(key: key);

  @override
  _SupplierInvoiceFormScreenState createState() => _SupplierInvoiceFormScreenState();
}

class _SupplierInvoiceFormScreenState extends State<SupplierInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  String? _selectedSupplierId;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _totalAmountController;
  late TextEditingController _amountPaidController; // Para edición inicial, no para pagos posteriores
  late TextEditingController _notesController;

  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(Duration(days: 30)); // Default a 30 días
  InvoiceStatus _selectedStatus = InvoiceStatus.pending;

  bool _isSaving = false;
  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.invoice?.supplierId;
    _invoiceNumberController = TextEditingController(text: widget.invoice?.invoiceNumber ?? '');
    _totalAmountController = TextEditingController(text: widget.invoice?.totalAmount.toStringAsFixed(2) ?? '');
    _amountPaidController = TextEditingController(text: widget.invoice?.amountPaid.toStringAsFixed(2) ?? '0.00');
    _notesController = TextEditingController(text: widget.invoice?.notes ?? '');
    _invoiceDate = widget.invoice?.invoiceDate ?? DateTime.now();
    _dueDate = widget.invoice?.dueDate ?? DateTime.now().add(Duration(days: 30));
    _selectedStatus = widget.invoice?.status ?? InvoiceStatus.pending;

    // Si es nuevo y hay un solo proveedor, preseleccionarlo
    if (!_isEditing && widget.availableSuppliers.length == 1) {
      _selectedSupplierId = widget.availableSuppliers.first.id;
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _totalAmountController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _invoiceDate : _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
          // Opcional: si se cambia la fecha de factura, ajustar automáticamente la fecha de vencimiento
          // _dueDate = _invoiceDate.add(Duration(days: 30)); 
        } else {
          _dueDate = picked;
        }
      });
    }
  }


  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
     if (_selectedSupplierId == null) {
      _showFeedback("Debe seleccionar un proveedor.", true);
      return;
    }
    setState(() => _isSaving = true);

    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

    // Determinar el estado basado en los montos, especialmente para nuevas facturas
    InvoiceStatus statusToSave = _selectedStatus;
    if (!_isEditing) { // Para nuevas facturas, calcular estado inicial
        if (amountPaid >= totalAmount && totalAmount > 0) {
            statusToSave = InvoiceStatus.paid;
        } else if (amountPaid > 0 && amountPaid < totalAmount) {
            statusToSave = InvoiceStatus.partially_paid;
        } else {
            statusToSave = InvoiceStatus.pending;
        }
    } else { // Para edición, mantener el estado a menos que se pague por completo
        if (amountPaid >= totalAmount && totalAmount > 0) {
            statusToSave = InvoiceStatus.paid;
        } else if (amountPaid > 0 && amountPaid < totalAmount && _selectedStatus != InvoiceStatus.paid) {
            statusToSave = InvoiceStatus.partially_paid;
        } // Si ya estaba pagada y se editan montos, podría necesitar re-evaluación más compleja
    }


    try {
      SupplierInvoice invoiceToSave;
      if (!_isEditing) {
        invoiceToSave = SupplierInvoice(
          supplierId: _selectedSupplierId!,
          invoiceNumber: _invoiceNumberController.text.trim().isNotEmpty ? _invoiceNumberController.text.trim() : null,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          totalAmount: totalAmount,
          amountPaid: amountPaid,
          status: statusToSave, // Usar el estado calculado/seleccionado
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        await _dbService.addSupplierInvoice(invoiceToSave);
        _showFeedback('Factura agregada exitosamente.', false);
      } else {
        invoiceToSave = SupplierInvoice(
          id: widget.invoice!.id,
          supplierId: _selectedSupplierId!,
          invoiceNumber: _invoiceNumberController.text.trim().isNotEmpty ? _invoiceNumberController.text.trim() : null,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          totalAmount: totalAmount,
          amountPaid: amountPaid, // El campo amountPaid se edita aquí
          status: statusToSave, // Usar el estado calculado/seleccionado
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          createdAt: widget.invoice!.createdAt,
        );
        await _dbService.updateSupplierInvoice(invoiceToSave);
        _showFeedback('Factura actualizada exitosamente.', false);
      }
      if(mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if(mounted) _showFeedback('Error al guardar factura: ${e.toString()}', true);
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
        title: Text(_isEditing ? 'Editar Factura Proveedor' : 'Agregar Factura Proveedor'),
         actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveInvoice,
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
              DropdownButtonFormField<String>(
                value: _selectedSupplierId,
                hint: Text('Seleccionar Proveedor'),
                isExpanded: true,
                items: widget.availableSuppliers.map((Supplier supplier) {
                  return DropdownMenuItem<String>(
                    value: supplier.id,
                    child: Text(supplier.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedSupplierId = newValue);
                },
                validator: (value) => value == null ? 'Seleccione un proveedor' : null,
                decoration: InputDecoration(labelText: 'Proveedor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_shipping)),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(labelText: 'Número de Factura (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.receipt)),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Fecha de Factura: ${DateFormat('dd/MM/yyyy').format(_invoiceDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey)),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Fecha de Vencimiento: ${DateFormat('dd/MM/yyyy').format(_dueDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey)),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _totalAmountController,
                decoration: InputDecoration(labelText: 'Monto Total', prefixText: '\$ ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Monto total requerido';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  if (double.parse(value) <= 0) return 'Monto debe ser positivo';
                  return null;
                },
              ),
              SizedBox(height: 16),
               // El campo 'Monto Pagado' aquí es para el pago inicial al crear/editar la factura.
               // Los pagos subsecuentes se registran con el RecordPaymentDialog.
              TextFormField(
                controller: _amountPaidController,
                decoration: InputDecoration(labelText: 'Monto Pagado Inicialmente', prefixText: '\$ ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payment)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Monto pagado requerido (puede ser 0)';
                  final paid = double.tryParse(value);
                  if (paid == null) return 'Número inválido';
                  if (paid < 0) return 'No puede ser negativo';
                  final total = double.tryParse(_totalAmountController.text);
                  if (total != null && paid > total) return 'Pago no puede exceder el total';
                  return null;
                },
              ),
              SizedBox(height: 16),
               if (_isEditing) // Solo mostrar/editar estado si se está editando
                 DropdownButtonFormField<InvoiceStatus>(
                  value: _selectedStatus,
                  decoration: InputDecoration(labelText: 'Estado de la Factura', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag_outlined)),
                  items: InvoiceStatus.values.map((InvoiceStatus status) {
                    return DropdownMenuItem<InvoiceStatus>(
                      value: status,
                      child: Text(status.name.replaceAll('_', ' ').toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (InvoiceStatus? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedStatus = newValue);
                    }
                  },
                ),
              if (_isEditing) SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notas (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving 
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.save),
                label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR FACTURA'),
                onPressed: _isSaving ? null : _saveInvoice,
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