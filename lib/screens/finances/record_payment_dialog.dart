// lib/screens/finances/record_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecordPaymentDialog extends StatefulWidget {
  final String title;
  final double totalAmount;
  final double currentPaidAmount;

  RecordPaymentDialog({
    Key? key,
    required this.title,
    required this.totalAmount,
    required this.currentPaidAmount,
  }) : super(key: key);

  @override
  _RecordPaymentDialogState createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paymentAmountController = TextEditingController();
  // Opcional: podrías añadir un selector de fecha de pago aquí
  // DateTime _paymentDate = DateTime.now();

  double get _remainingAmount => widget.totalAmount - widget.currentPaidAmount;

  @override
  void dispose() {
    _paymentAmountController.dispose();
    super.dispose();
  }
  
  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      final double paymentAmount = double.tryParse(_paymentAmountController.text) ?? 0.0;
      Navigator.of(context).pop(paymentAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Monto Total: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(widget.totalAmount)}'),
              Text('Monto Pagado Previamente: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(widget.currentPaidAmount)}'),
              Text(
                'Monto Pendiente: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(_remainingAmount)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: _remainingAmount > 0 ? Colors.orange.shade800 : Colors.green),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _paymentAmountController,
                decoration: InputDecoration(
                  labelText: 'Monto del Nuevo Pago/Cobro',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un monto';
                  }
                  final payment = double.tryParse(value);
                  if (payment == null) {
                    return 'Monto inválido';
                  }
                  if (payment <= 0) {
                    return 'El monto debe ser positivo';
                  }
                  if (payment > _remainingAmount && _remainingAmount > 0) { // Permite pagar más si el remanente es 0 o negativo (sobrepago)
                    return 'El pago no puede exceder el monto pendiente (\$${_remainingAmount.toStringAsFixed(2)})';
                  }
                  return null;
                },
              ),
              // Opcional: Campo para fecha de pago si es diferente a hoy
              // SizedBox(height: 12),
              // ListTile(title: Text('Fecha Pago: ${DateFormat('dd/MM/yyyy').format(_paymentDate)}'), trailing: Icon(Icons.calendar_today), onTap: _selectPaymentDate),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(null), // Devolver null si se cancela
        ),
        ElevatedButton(
          child: Text('Registrar'),
          onPressed: _submitPayment,
        ),
      ],
    );
  }

  // Opcional: _selectPaymentDate si quieres un selector de fecha
  // Future<void> _selectPaymentDate() async { ... }
}