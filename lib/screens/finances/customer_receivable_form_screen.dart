// lib/screens/finances/customer_receivable_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_receivable.dart';
import '../../services/DatabaseService.dart';

class CustomerReceivableFormScreen extends StatefulWidget {
  final CustomerReceivable receivable; // Siempre se edita una existente

  CustomerReceivableFormScreen({Key? key, required this.receivable}) : super(key: key);

  @override
  _CustomerReceivableFormScreenState createState() => _CustomerReceivableFormScreenState();
}

class _CustomerReceivableFormScreenState extends State<CustomerReceivableFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  late TextEditingController _notesController;
  late TextEditingController _paymentTermsController;
  late DateTime _dueDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.receivable.notes ?? '');
    _paymentTermsController = TextEditingController(text: widget.receivable.paymentTerms ?? '');
    _dueDate = widget.receivable.dueDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: widget.receivable.issueDate, // No antes de la fecha de emisión
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate && mounted) {
      setState(() {
        _dueDate = picked;
      });
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


  Future<void> _saveReceivableChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // Crear una copia del receivable original para modificar solo los campos permitidos
      CustomerReceivable updatedReceivable = CustomerReceivable.fromMap(widget.receivable.toMapForUpdate());
      
      updatedReceivable.dueDate = _dueDate;
      updatedReceivable.paymentTerms = _paymentTermsController.text.trim().isNotEmpty ? _paymentTermsController.text.trim() : null;
      updatedReceivable.notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
      
      // Los campos como totalDue, amountPaid, status, customerId, saleTransactionId no se editan aquí.
      // Esos se mantienen del objeto original. El status se actualiza con los pagos.

      await _dbService.updateCustomerReceivable(updatedReceivable);
      _showFeedback('Cambios en la cuenta por cobrar guardados.', false);
      if (mounted) Navigator.of(context).pop(true); // Indicar que hubo cambios

    } catch (e) {
      _showFeedback('Error al guardar cambios: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Cuenta por Cobrar'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Guardar Cambios',
            onPressed: _isSaving ? null : _saveReceivableChanges,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Cliente: ${widget.receivable.customerName ?? widget.receivable.customerId}', style: Theme.of(context).textTheme.titleMedium),
              Text('Monto Total: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(widget.receivable.totalDue)}'),
              Text('Monto Pagado: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(widget.receivable.amountPaid)}'),
              Divider(height: 24),

              ListTile(
                title: Text('Fecha de Vencimiento: ${DateFormat('dd/MM/yyyy').format(_dueDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDueDate(context),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey)),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _paymentTermsController,
                decoration: InputDecoration(
                  labelText: 'Términos de Pago (Ej: Neto 30 días)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined)
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas Adicionales',
                  border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.notes_outlined)
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving 
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.save_alt_outlined),
                label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS'),
                onPressed: _isSaving ? null : _saveReceivableChanges,
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