// lib/screens/management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Importaciones de Modelos ---
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/supplier_invoice.dart'; // Asegúrate que el enum InvoiceStatus esté aquí o importado
import '../models/customer_receivable.dart';
import '../models/product.dart';
import '../models/supplier_product_info.dart'; 
import '../models/transaction.dart'; // Necesario para CustomerReceivableDetailsScreen

// --- Importación del Servicio ---
import '../services/DatabaseService.dart';

// --- Importaciones de Pantallas y Diálogos ---
import 'suppliers/supplier_form_screen.dart';
import 'suppliers/manage_supplier_products_screen.dart';
import 'customers/customer_form_screen.dart';
import 'finances/supplier_invoice_form_screen.dart';
import 'finances/record_payment_dialog.dart';
import 'finances/customer_receivable_details_screen.dart'; // <-- Pantalla de detalles

// --- Gestión Principal ---
class ManagementScreen extends StatefulWidget {
  @override
  _ManagementScreenState createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();

  // Listas de datos
  List<Supplier> _suppliers = [];
  List<Customer> _customers = [];
  List<SupplierInvoice> _supplierInvoices = [];
  List<CustomerReceivable> _customerReceivables = [];
  List<Product> _allProducts = [];

  // Estados de carga
  bool _isLoadingSuppliers = true;
  bool _isLoadingCustomers = true;
  bool _isLoadingSupplierInvoices = true;
  bool _isLoadingCustomerReceivables = true;
  bool _isLoadingAllProducts = true; 

  // Títulos y estado del TabBar
  final Map<int, String> _tabTitles = {
    0: "Proveedores",
    1: "Clientes",
    2: "Cuentas por Pagar",
    3: "Cuentas por Cobrar",
  };
  String _currentAppBarTitle = "Proveedores";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _currentAppBarTitle = _tabTitles[_tabController.index]!;
    _fetchAllInitialData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // --- Manejo de Tabs y Carga de Datos ---
  void _handleTabSelection() {
    if (_tabController.indexIsChanging || !_tabController.animation!.isCompleted) return;
    if (mounted) {
      setState(() {
        _currentAppBarTitle = _tabTitles[_tabController.index]!;
      });
      _loadDataForCurrentTab(isRefresh: false);
    }
  }

  Future<void> _fetchAllInitialData() async {
    await _loadAllProducts(); 
    await Future.wait([
      _loadSuppliers(isRefresh: true),
      _loadCustomers(isRefresh: true),
      _loadSupplierInvoices(isRefresh: true),
      _loadCustomerReceivables(isRefresh: true),
    ]);
  }
  
  Future<void> _loadDataForCurrentTab({bool isRefresh = false}) async {
    switch (_tabController.index) {
      case 0: if (isRefresh || _suppliers.isEmpty) await _loadSuppliers(isRefresh: isRefresh); break;
      case 1: if (isRefresh || _customers.isEmpty) await _loadCustomers(isRefresh: isRefresh); break;
      case 2: if (isRefresh || _supplierInvoices.isEmpty) await _loadSupplierInvoices(isRefresh: isRefresh); break;
      case 3: if (isRefresh || _customerReceivables.isEmpty) await _loadCustomerReceivables(isRefresh: isRefresh); break;
    }
  }

  Future<void> _loadAllProducts() async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoadingAllProducts = true);
    try {
      _allProducts = await _dbService.getProducts();
    } catch (e) { _showError('Error cargando productos: ${e.toString()}'); } 
    finally { setStateIfMounted(() => _isLoadingAllProducts = false); }
  }

  Future<void> _loadSuppliers({bool isRefresh = false}) async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoadingSuppliers = true);
    try {
      _suppliers = await _dbService.getSuppliers();
    } catch (e) { _showError('Error cargando proveedores: ${e.toString()}'); } 
    finally { setStateIfMounted(() => _isLoadingSuppliers = false); }
  }

  Future<void> _loadCustomers({bool isRefresh = false}) async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoadingCustomers = true);
    try {
      _customers = await _dbService.getCustomers();
    } catch (e) { _showError('Error cargando clientes: ${e.toString()}'); } 
    finally { setStateIfMounted(() => _isLoadingCustomers = false); }
  }

  Future<void> _loadSupplierInvoices({bool isRefresh = false}) async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoadingSupplierInvoices = true);
    try {
      _supplierInvoices = await _dbService.getSupplierInvoices();
      _supplierInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Ordenar
    } catch (e) { _showError('Error cargando facturas de proveedores: ${e.toString()}'); } 
    finally { setStateIfMounted(() => _isLoadingSupplierInvoices = false); }
  }

  Future<void> _loadCustomerReceivables({bool isRefresh = false}) async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoadingCustomerReceivables = true);
    try {
      _customerReceivables = await _dbService.getCustomerReceivables();
       _customerReceivables.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Ordenar
    } catch (e) { _showError('Error cargando cuentas por cobrar: ${e.toString()}'); } 
    finally { setStateIfMounted(() => _isLoadingCustomerReceivables = false); }
  }
  
  // Helper para setState seguro
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // --- Helpers de UI y Navegación ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
    );
  }
  
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatCurrency(double? value) {
    if (value == null) return 'N/A';
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(value);
  }

  String _formatDate(DateTime? date, {String format = 'dd/MM/yyyy'}) {
    if (date == null) return 'N/A';
    return DateFormat(format).format(date);
  }

  void _navigateToAddEditSupplierScreen({Supplier? supplier}) async {
    final bool? resultRefreshed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => SupplierFormScreen(supplier: supplier)));
    if (resultRefreshed == true) _loadSuppliers(isRefresh: true);
  }

  void _manageSupplierProducts(Supplier supplier) async {
    if (_isLoadingAllProducts) { _showError("Cargando lista de productos..."); return; }
    final bool? resultRefreshed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => ManageSupplierProductsScreen(supplier: supplier, allProducts: _allProducts)));
    if (resultRefreshed == true) _loadSuppliers(isRefresh: true);
  }

  void _navigateToAddEditCustomerScreen({Customer? customer}) async {
    final bool? resultRefreshed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => CustomerFormScreen(customer: customer)));
    if (resultRefreshed == true) _loadCustomers(isRefresh: true);
  }

  void _navigateToAddEditSupplierInvoiceScreen({SupplierInvoice? invoice}) async {
    if (_isLoadingSuppliers || (_suppliers.isEmpty && invoice == null)) {
       _showError("Cargando proveedores o no hay. Agregue uno primero.");
       if(_suppliers.isEmpty) await _loadSuppliers(isRefresh: true);
       if(_suppliers.isEmpty) return; 
    }
    final bool? resultRefreshed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => SupplierInvoiceFormScreen(invoice: invoice, availableSuppliers: _suppliers)));
    if (resultRefreshed == true) _loadSupplierInvoices(isRefresh: true);
  }

  void _recordSupplierInvoicePayment(SupplierInvoice invoice) async {
    final double? amountPaid = await showDialog<double>(
        context: context, builder: (context) => RecordPaymentDialog(title: 'Registrar Pago a Factura #${invoice.invoiceNumber ?? invoice.id!.substring(0,8)}', totalAmount: invoice.totalAmount, currentPaidAmount: invoice.amountPaid));

    if (amountPaid != null && amountPaid > 0) {
        setStateIfMounted(() => _isLoadingSupplierInvoices = true);
        try {
            SupplierInvoice updatedInvoice = SupplierInvoice.fromMap(invoice.toMapForUpdate());
            updatedInvoice.id = invoice.id; // Restaurar ID que no está en toMapForUpdate
            updatedInvoice.amountPaid += amountPaid;
            if (updatedInvoice.amountPaid >= updatedInvoice.totalAmount) updatedInvoice.status = InvoiceStatus.paid;
            else if (updatedInvoice.amountPaid > 0) updatedInvoice.status = InvoiceStatus.partially_paid;
            else updatedInvoice.status = InvoiceStatus.pending;
            
            await _dbService.updateSupplierInvoice(updatedInvoice);
            _showSuccess('Pago registrado para factura ${invoice.invoiceNumber ?? invoice.id!.substring(0,8)}');
            _loadSupplierInvoices(isRefresh: true);
        } catch (e) { _showError('Error al registrar pago: ${e.toString()}'); setStateIfMounted(() => _isLoadingSupplierInvoices = false); }
    }
  }

  void _recordCustomerReceivablePayment(CustomerReceivable receivable) async {
     final double? amountReceived = await showDialog<double>(
        context: context, builder: (context) => RecordPaymentDialog(title: 'Registrar Cobro a Cliente ${receivable.customerName ?? receivable.customerId.substring(0,8)}', totalAmount: receivable.totalDue, currentPaidAmount: receivable.amountPaid));
    
    if (amountReceived != null && amountReceived > 0) {
        setStateIfMounted(() => _isLoadingCustomerReceivables = true);
        try {
            CustomerReceivable updatedReceivable = CustomerReceivable.fromMap(receivable.toMapForUpdate());
             updatedReceivable.id = receivable.id; // Restaurar ID
            updatedReceivable.amountPaid += amountReceived;
            if (updatedReceivable.amountPaid >= updatedReceivable.totalDue) updatedReceivable.status = InvoiceStatus.paid;
            else if (updatedReceivable.amountPaid > 0) updatedReceivable.status = InvoiceStatus.partially_paid;
            else updatedReceivable.status = InvoiceStatus.pending;

            await _dbService.updateCustomerReceivable(updatedReceivable);
            _showSuccess('Cobro registrado para ${receivable.customerName ?? receivable.customerId.substring(0,8)}');
            _loadCustomerReceivables(isRefresh: true);
        } catch (e) { _showError('Error al registrar cobro: ${e.toString()}'); setStateIfMounted(() => _isLoadingCustomerReceivables = false); }
    }
  }

  // Navega a la pantalla de detalles de la cuenta por cobrar
  void _navigateToReceivableDetails(CustomerReceivable receivable) async {
     final bool? refreshNeeded = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerReceivableDetailsScreen(receivable: receivable),
        ),
      );
      // Si la pantalla de detalles indica que algo cambió (ej. se registró un pago o se editó)
      if (refreshNeeded == true && mounted) {
        _loadCustomerReceivables(isRefresh: true);
      }
  }

  // --- Widgets para cada Pestaña ---
  Widget _buildListShell({
    required bool isLoading, required bool isEmpty, required String emptyListMessage,
    required RefreshCallback onRefresh, required Widget listBuilderWidget,
    String? emptyListActionText, VoidCallback? onEmptyListActionPressed,
  }) {
    // ... (código del _buildListShell como en la respuesta anterior, sin cambios) ...
     if (isLoading) return Center(child: CircularProgressIndicator());
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 60, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(emptyListMessage, style: TextStyle(fontSize: 16, color: Colors.grey[700]), textAlign: TextAlign.center),
              if(emptyListActionText != null && onEmptyListActionPressed != null) ...[
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text(emptyListActionText),
                      onPressed: onEmptyListActionPressed,
                  )
              ]
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(onRefresh: onRefresh, child: listBuilderWidget);
  }

  Widget _buildSuppliersTab() {
    return _buildListShell(
      isLoading: _isLoadingSuppliers, isEmpty: _suppliers.isEmpty,
      emptyListMessage: 'No hay proveedores registrados.\n¡Comienza agregando uno!',
      onRefresh: () => _loadSuppliers(isRefresh: true),
      emptyListActionText: "Agregar Proveedor",
      onEmptyListActionPressed: () => _navigateToAddEditSupplierScreen(),
      listBuilderWidget: ListView.builder(
        padding: EdgeInsets.all(8), itemCount: _suppliers.length,
        itemBuilder: (context, index) {
          final supplier = _suppliers[index];
          return Card( /* ... ListTile como antes ... */ 
             margin: EdgeInsets.symmetric(vertical: 6), elevation: 2,
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
              title: Text(supplier.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(supplier.contactDetails?['phone'] ?? supplier.contactDetails?['email'] ?? 'Sin contacto principal'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.inventory_2_outlined, color: Theme.of(context).primaryColor), tooltip: 'Gestionar Productos', onPressed: () => _manageSupplierProducts(supplier)),
                IconButton(icon: Icon(Icons.edit_note_outlined, color: Colors.orange.shade700), tooltip: 'Editar Proveedor', onPressed: () => _navigateToAddEditSupplierScreen(supplier: supplier)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomersTab() {
     return _buildListShell(
      isLoading: _isLoadingCustomers, isEmpty: _customers.isEmpty,
      emptyListMessage: 'No hay clientes registrados.\n¡Agrega tu primer cliente!',
      onRefresh: () => _loadCustomers(isRefresh: true),
      emptyListActionText: "Agregar Cliente",
      onEmptyListActionPressed: () => _navigateToAddEditCustomerScreen(),
      listBuilderWidget: ListView.builder(
        padding: EdgeInsets.all(8), itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          return Card( /* ... ListTile como antes ... */ 
             margin: EdgeInsets.symmetric(vertical: 6), elevation: 2,
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(customer.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Tipo: ${customer.customerType.name}\n${customer.contactDetails?['phone'] ?? customer.contactDetails?['email'] ?? 'Sin contacto'}'),
              isThreeLine: (customer.contactDetails?['phone'] != null || customer.contactDetails?['email'] != null) && (customer.contactDetails?['phone'] != null && customer.contactDetails?['email'] != null),
              trailing: IconButton(
                icon: Icon(Icons.edit_note_outlined, color: Colors.orange.shade700), tooltip: 'Editar Cliente', onPressed: () => _navigateToAddEditCustomerScreen(customer: customer),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierInvoicesTab() {
     return _buildListShell(
      isLoading: _isLoadingSupplierInvoices, isEmpty: _supplierInvoices.isEmpty,
      emptyListMessage: 'No hay facturas de proveedores registradas.',
      onRefresh: () => _loadSupplierInvoices(isRefresh: true),
      emptyListActionText: "Agregar Factura Proveedor",
      onEmptyListActionPressed: () => _navigateToAddEditSupplierInvoiceScreen(),
      listBuilderWidget: ListView.builder(
         padding: EdgeInsets.all(8), itemCount: _supplierInvoices.length,
        itemBuilder: (context, index) {
          final invoice = _supplierInvoices[index];
          // ... (lógica de isOverdue, statusColor, statusIcon como antes) ...
           bool isOverdue = invoice.status != InvoiceStatus.paid && invoice.dueDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
          Color statusColor; IconData statusIcon;
          switch(invoice.status) { /* ... como antes ... */ 
             case InvoiceStatus.paid: statusColor = Colors.green; statusIcon = Icons.check_circle_outline; break;
             case InvoiceStatus.pending: statusColor = isOverdue ? Colors.red.shade700 : Colors.orange.shade700; statusIcon = isOverdue ? Icons.error_outline : Icons.hourglass_empty_outlined; break;
             case InvoiceStatus.partially_paid: statusColor = isOverdue ? Colors.red.shade700 : Colors.blue.shade700; statusIcon = isOverdue ? Icons.error_outline : Icons.incomplete_circle_outlined; break;
             case InvoiceStatus.overdue: statusColor = Colors.red.shade700; statusIcon = Icons.error_outline; break;
             default: statusColor = Colors.grey; statusIcon = Icons.help_outline;
          }

          return Card( /* ... ListTile como antes ... */
            margin: EdgeInsets.symmetric(vertical: 6), elevation: 2,
            child: ListTile(
              leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.15), child: Icon(statusIcon, color: statusColor)),
              title: Text('Factura: ${invoice.invoiceNumber ?? "S/N"}', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Proveedor: ${invoice.supplierName ?? invoice.supplierId.substring(0,8)}...'),
                Text('Total: ${_formatCurrency(invoice.totalAmount)} / Pagado: ${_formatCurrency(invoice.amountPaid)}'),
                Text('Vence: ${_formatDate(invoice.dueDate)}', style: TextStyle(color: isOverdue && invoice.status != InvoiceStatus.paid ? Colors.red.shade900 : null, fontWeight: isOverdue && invoice.status != InvoiceStatus.paid ? FontWeight.bold : FontWeight.normal)),
                Text('Estado: ${invoice.status.name.replaceAll('_', ' ').toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_outlined),
                onSelected: (value) { /* ... como antes ... */
                  if (value == 'edit') _navigateToAddEditSupplierInvoiceScreen(invoice: invoice);
                  else if (value == 'pay' && invoice.status != InvoiceStatus.paid) _recordSupplierInvoicePayment(invoice);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[ /* ... como antes ... */
                   const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar Factura'))),
                   if (invoice.status != InvoiceStatus.paid) const PopupMenuItem<String>(value: 'pay', child: ListTile(leading: Icon(Icons.payment_outlined), title: Text('Registrar Pago'))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerReceivablesTab() {
     return _buildListShell(
      isLoading: _isLoadingCustomerReceivables, isEmpty: _customerReceivables.isEmpty,
      emptyListMessage: 'No hay cuentas por cobrar activas.',
      onRefresh: () => _loadCustomerReceivables(isRefresh: true),
      listBuilderWidget: ListView.builder(
         padding: EdgeInsets.all(8), itemCount: _customerReceivables.length,
        itemBuilder: (context, index) {
          final receivable = _customerReceivables[index];
          // ... (lógica de isOverdue, statusColor, statusIcon como antes) ...
          bool isOverdue = receivable.status != InvoiceStatus.paid && receivable.dueDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
          Color statusColor; IconData statusIcon;
           switch(receivable.status) { /* ... como antes ... */
               case InvoiceStatus.paid: statusColor = Colors.green; statusIcon = Icons.check_circle_outline; break;
               case InvoiceStatus.pending: statusColor = isOverdue ? Colors.red.shade700 : Colors.orange.shade700; statusIcon = isOverdue ? Icons.error_outline : Icons.hourglass_empty_outlined; break;
               case InvoiceStatus.partially_paid: statusColor = isOverdue ? Colors.red.shade700 : Colors.blue.shade700; statusIcon = isOverdue ? Icons.error_outline : Icons.incomplete_circle_outlined; break;
               case InvoiceStatus.overdue: statusColor = Colors.red.shade700; statusIcon = Icons.error_outline; break;
               default: statusColor = Colors.grey; statusIcon = Icons.help_outline;
           }

          return Card(
            margin: EdgeInsets.symmetric(vertical: 6), elevation: 2,
            child: ListTile(
              // --- NAVEGACIÓN A DETALLES ---
              onTap: () => _navigateToReceivableDetails(receivable),
              // -----------------------------
              leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.15), child: Icon(statusIcon, color: statusColor)),
              title: Text('Cliente: ${receivable.customerName ?? receivable.customerId.substring(0,8)}...', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                 if (receivable.transactionDescription != null && receivable.transactionDescription!.isNotEmpty)
                    Text('Ref Venta: ${receivable.transactionDescription}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                 Text('Total: ${_formatCurrency(receivable.totalDue)} / Recibido: ${_formatCurrency(receivable.amountPaid)}'),
                 Text('Vence: ${_formatDate(receivable.dueDate)}', style: TextStyle(color: isOverdue && receivable.status != InvoiceStatus.paid ? Colors.red.shade900 : null, fontWeight: isOverdue && receivable.status != InvoiceStatus.paid ? FontWeight.bold : null)),
                 Text('Estado: ${receivable.status.name.replaceAll('_', ' ').toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              isThreeLine: true,
              trailing: receivable.status != InvoiceStatus.paid 
                ? IconButton( // Botón directo para la acción principal
                    icon: Icon(Icons.price_check_outlined, color: Theme.of(context).primaryColor),
                    tooltip: 'Registrar Cobro',
                    onPressed: () => _recordCustomerReceivablePayment(receivable),
                  )
                : Icon(Icons.check_circle, color: Colors.green, semanticLabel: "Pagado"),
            ),
          );
        },
      ),
    );
  }

  // --- Widget Build Principal ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAppBarTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Proveedores'),
            Tab(icon: Icon(Icons.people_outline), text: 'Clientes'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Por Pagar'),
            Tab(icon: Icon(Icons.request_quote_outlined), text: 'Por Cobrar'), // Icono cambiado
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refrescar Datos Actuales',
            onPressed: () => _loadDataForCurrentTab(isRefresh: true),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuppliersTab(),
          _buildCustomersTab(),
          _buildSupplierInvoicesTab(),
          _buildCustomerReceivablesTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // FAB dinámico
  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: return FloatingActionButton.extended(onPressed: () => _navigateToAddEditSupplierScreen(), label: Text('Proveedor'), icon: Icon(Icons.add), tooltip: 'Agregar Proveedor');
      case 1: return FloatingActionButton.extended(onPressed: () => _navigateToAddEditCustomerScreen(), label: Text('Cliente'), icon: Icon(Icons.person_add_alt_1_outlined), tooltip: 'Agregar Cliente');
      case 2: return FloatingActionButton.extended(onPressed: () => _navigateToAddEditSupplierInvoiceScreen(), label: Text('Factura Prov.'), icon: Icon(Icons.post_add_outlined), tooltip: 'Agregar Factura Proveedor');
      case 3: return null; // No hay FAB para agregar CxC aquí
      default: return null;
    }
  }
}