// lib/screens/finances/customer_receivable_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importaciones de Modelos y Servicios
import '../../models/customer_receivable.dart';
import '../../models/supplier_invoice.dart'; // Para el enum InvoiceStatus (o define uno específico)
import '../../models/transaction.dart';
import '../../services/DatabaseService.dart';

// Importaciones de otras pantallas/diálogos necesarios
import 'record_payment_dialog.dart';
import 'customer_receivable_form_screen.dart'; // Asegúrate de crear este archivo

class CustomerReceivableDetailsScreen extends StatefulWidget {
  // El objeto inicial, podría actualizarse si se registran pagos en esta pantalla
  final CustomerReceivable initialReceivable; 

  CustomerReceivableDetailsScreen({Key? key, required CustomerReceivable receivable}) 
    : initialReceivable = receivable, // Guarda el original
      super(key: key);

  @override
  _CustomerReceivableDetailsScreenState createState() => _CustomerReceivableDetailsScreenState();
}

class _CustomerReceivableDetailsScreenState extends State<CustomerReceivableDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  // Estado local para reflejar cambios hechos en esta pantalla (ej. después de registrar pago)
  late CustomerReceivable _currentReceivable; 
  
  Transaction? _saleTransaction; // Detalles de la venta asociada
  bool _isLoadingTransaction = true;
  bool _isProcessingPayment = false; // Estado para deshabilitar botón mientras se procesa pago

  @override
  void initState() {
    super.initState();
    // Inicializa el estado local con el objeto pasado al widget
    _currentReceivable = widget.initialReceivable; 
    _loadSaleTransactionDetails();
  }

  // Carga los detalles de la transacción de venta original
  Future<void> _loadSaleTransactionDetails() async {
    if (_currentReceivable.saleTransactionId.isEmpty || !_dbService.isValidUuid(_currentReceivable.saleTransactionId)) {
      if (mounted) setState(() => _isLoadingTransaction = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoadingTransaction = true);
    try {
      // Usamos el getTransactionById que ya deberías tener en DatabaseService
      final transaction = await _dbService.getTransactionById(_currentReceivable.saleTransactionId);
      if (mounted) {
        setState(() {
          _saleTransaction = transaction;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Error cargando detalles de transacción: $e");
        // Opcional: mostrar un mensaje discreto al usuario
        _showFeedback("No se pudieron cargar los detalles de la venta asociada.", true);
      }
    } finally {
        if (mounted) {
            setState(() => _isLoadingTransaction = false);
        }
    }
  }
  
  // --- Helpers ---
  String _formatCurrency(double? value) {
    if (value == null) return 'N/A';
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(value);
  }

  String _formatDate(DateTime? date, {String format = 'dd/MM/yyyy'}) {
    if (date == null) return 'N/A';
    return DateFormat(format).format(date);
  }

  void _showFeedback(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst("Exception: ", "")),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  // --- Acciones ---

  // Muestra el diálogo para registrar un pago/cobro
  Future<void> _triggerRecordPayment() async {
    if (_isProcessingPayment) return; // Evitar doble tap

    final double? amountReceived = await showDialog<double>(
      context: context,
      barrierDismissible: !_isProcessingPayment, // No permitir cerrar mientras procesa
      builder: (context) => RecordPaymentDialog(
        title: 'Registrar Cobro a Cliente',
        totalAmount: _currentReceivable.totalDue,
        currentPaidAmount: _currentReceivable.amountPaid,
      ),
    );

    if (amountReceived != null && amountReceived > 0 && mounted) {
      setState(() => _isProcessingPayment = true);
      
      // Mostrar un loader DENTRO del botón o en la UI es mejor que un diálogo modal
      // Pero por simplicidad, podemos seguir con el diálogo modal si prefieres:
      // showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator()));

      try {
        // Clonar el objeto actual para modificarlo
        CustomerReceivable updatedReceivable = CustomerReceivable.fromMap(_currentReceivable.toMapForUpdate());
        updatedReceivable.id = _currentReceivable.id; // Asegurarse que el ID se mantiene
        
        // Actualizar monto pagado
        updatedReceivable.amountPaid = (updatedReceivable.amountPaid) + amountReceived;
        
        // Actualizar estado basado en el nuevo monto pagado
        if (updatedReceivable.amountPaid >= updatedReceivable.totalDue) {
          updatedReceivable.status = InvoiceStatus.paid;
        } else if (updatedReceivable.amountPaid > 0) {
          updatedReceivable.status = InvoiceStatus.partially_paid;
        } else {
           // Esto no debería pasar si amountReceived es > 0, pero por si acaso
          updatedReceivable.status = InvoiceStatus.pending;
        }
        
        // Guardar en la base de datos
        final savedReceivable = await _dbService.updateCustomerReceivable(updatedReceivable);
        
        // Actualizar el estado local para reflejar el cambio inmediatamente en esta pantalla
        if (mounted) {
          setState(() {
            _currentReceivable = savedReceivable;
          });
          _showFeedback('Cobro registrado exitosamente.', false);
        }

      } catch (e) {
        _showFeedback('Error al registrar cobro: ${e.toString()}', true);
      } finally {
        if (mounted) {
          // Navigator.of(context).pop(); // Cerrar loader si usaste diálogo modal
          setState(() => _isProcessingPayment = false);
        }
      }
    }
  }
  
  // Navega a la pantalla para editar campos seleccionados
  void _navigateToEditReceivableScreen() async {
    // Asumiendo que CustomerReceivableFormScreen existe y puede manejar la edición
    final bool? resultRefreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerReceivableFormScreen(receivable: _currentReceivable),
      ),
    );

    if (resultRefreshed == true && mounted) {
      // Si el formulario de edición indica que hubo cambios, recargamos los datos
      // Esencial si queremos ver los cambios reflejados inmediatamente aquí.
      try {
         // Necesitas este método en DatabaseService:
         final refreshedReceivable = await _dbService.getCustomerReceivableById(_currentReceivable.id!); 
         if (refreshedReceivable != null && mounted) {
           setState(() {
             _currentReceivable = refreshedReceivable;
             // Si la edición pudiera afectar la transacción asociada (muy poco probable)
             // podrías llamar a _loadSaleTransactionDetails() aquí también.
           });
            _showFeedback('Detalles actualizados.', false);
         }
      } catch (e) {
         _showFeedback("Error al recargar detalles tras edición: ${e.toString()}", true);
      }
    }
  }

  // --- Construcción de UI ---
  @override
  Widget build(BuildContext context) {
    // Determinar estado visual (como antes)
    bool isOverdue = _currentReceivable.status != InvoiceStatus.paid && 
                     _currentReceivable.dueDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
    Color statusColor;
    IconData statusIcon;
    switch(_currentReceivable.status) {
        case InvoiceStatus.paid: statusColor = Colors.green; statusIcon = Icons.check_circle; break;
        case InvoiceStatus.pending: statusColor = isOverdue ? Colors.red.shade700 : Colors.orange.shade700; statusIcon = isOverdue ? Icons.error : Icons.hourglass_empty; break;
        case InvoiceStatus.partially_paid: statusColor = isOverdue ? Colors.red.shade700 : Colors.blue.shade700; statusIcon = isOverdue ? Icons.error : Icons.incomplete_circle; break;
        case InvoiceStatus.overdue: statusColor = Colors.red.shade700; statusIcon = Icons.error; break; // Ya manejado por isOverdue + pending
        default: statusColor = Colors.grey; statusIcon = Icons.help;
    }
     double remainingAmount = _currentReceivable.totalDue - _currentReceivable.amountPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Cuenta por Cobrar'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_outlined),
            tooltip: 'Editar Notas / Términos / Vencimiento',
            onPressed: _navigateToEditReceivableScreen, // Llama a la función de navegación
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async { 
            // El refresh aquí debería recargar tanto el receivable como la transacción
            await _loadSaleTransactionDetails();
            // Para recargar el receivable, necesitaríamos su ID y un método en el servicio
            if(_currentReceivable.id != null) {
                try {
                     final refreshed = await _dbService.getCustomerReceivableById(_currentReceivable.id!);
                     if(refreshed != null && mounted) {
                         setState(() => _currentReceivable = refreshed);
                     }
                } catch(e) { /* manejo de error */ }
            }
        },
        child: ListView( // Usar ListView en lugar de SingleChildScrollView para que RefreshIndicator funcione bien
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            // --- Tarjeta Principal de Detalles ---
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente: ${_currentReceivable.customerName ?? _currentReceivable.customerId.substring(0,8)}...', 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 12),
                    Row( // Fila para Estado visual
                      children: [
                        Icon(statusIcon, color: statusColor, size: 22),
                        SizedBox(width: 8),
                        Text(
                          _currentReceivable.status.name.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Divider(height: 24, thickness: 1),
                    _buildDetailRow('Monto Total Adeudado:', _formatCurrency(_currentReceivable.totalDue)),
                    _buildDetailRow('Monto Recibido:', _formatCurrency(_currentReceivable.amountPaid)),
                    _buildDetailRow(
                      'Monto Pendiente:', 
                      _formatCurrency(remainingAmount),
                      valueStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: remainingAmount > 0 ? statusColor : Colors.green) // Color del estado si pendiente > 0
                    ),
                    Divider(height: 24, thickness: 1),
                    _buildDetailRow('Fecha de Emisión:', _formatDate(_currentReceivable.issueDate)),
                    _buildDetailRow(
                      'Fecha de Vencimiento:', 
                      _formatDate(_currentReceivable.dueDate),
                      valueStyle: TextStyle(color: isOverdue && _currentReceivable.status != InvoiceStatus.paid ? Colors.red.shade900 : null, fontWeight: isOverdue && _currentReceivable.status != InvoiceStatus.paid ? FontWeight.bold : null)
                    ),
                    if (_currentReceivable.paymentTerms != null && _currentReceivable.paymentTerms!.isNotEmpty)
                      _buildDetailRow('Términos de Pago:', _currentReceivable.paymentTerms!),
                    
                     if (_currentReceivable.notes != null && _currentReceivable.notes!.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Text('Notas Adicionales:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade700)),
                        SizedBox(height: 4),
                        Text(_currentReceivable.notes!, style: TextStyle(fontSize: 14)),
                     ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // --- Tarjeta de Detalles de la Venta Asociada ---
            if (_isLoadingTransaction)
              Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator()))
            else if (_saleTransaction != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Venta Asociada', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                      Divider(height: 20, thickness: 1),
                      _buildDetailRow('ID Transacción:', _saleTransaction!.id!.substring(0,8) + "..."),
                      _buildDetailRow('Descripción Venta:', _saleTransaction!.description),
                      _buildDetailRow('Fecha Venta:', _formatDate(_saleTransaction!.date, format: 'dd/MM/yyyy hh:mm a')),
                      _buildDetailRow('Monto Venta:', _formatCurrency(_saleTransaction!.amount)),
                       if (_saleTransaction!.productName != null)
                        _buildDetailRow(
                          'Producto Vendido:', 
                          '${_saleTransaction!.productName}${_saleTransaction!.quantity != null ? " (x${_saleTransaction!.quantity})" : ""}'
                          ),
                    ],
                  ),
                ),
              )
            else if (_currentReceivable.saleTransactionId.isNotEmpty) // Si había ID pero no se encontró
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 16.0),
                 child: Text('No se encontraron detalles para la transacción de venta asociada (${_currentReceivable.saleTransactionId.substring(0,8)}...).', style: TextStyle(color: Colors.grey[600])),
               ),
            
          ],
        ),
      ),
      // FAB solo si no está pagado y no se está procesando un pago
      floatingActionButton: _currentReceivable.status != InvoiceStatus.paid
          ? FloatingActionButton.extended(
              onPressed: _isProcessingPayment ? null : _triggerRecordPayment, // Deshabilitar si está procesando
              label: Text('Registrar Cobro'),
              icon: _isProcessingPayment 
                    ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Icon(Icons.payment),
              tooltip: 'Registrar un nuevo cobro para esta cuenta',
            )
          : null, // No mostrar FAB si ya está pagado
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper para construir filas de detalle consistentes
  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2, 
              child: Text(
                label, 
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)
              )
          ),
          SizedBox(width: 8),
          Expanded(
              flex: 3, 
              child: Text(
                  value.isEmpty ? '-' : value, 
                  style: valueStyle ?? TextStyle(fontSize: 15)
              )
          ),
        ],
      ),
    );
  }
}

