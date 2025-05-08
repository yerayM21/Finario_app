import 'package:flutter/material.dart';
import '../../models/supplier.dart';
import '../../models/product.dart';
import '../../models/supplier_product_info.dart';
import '../../services/DatabaseService.dart';
import 'supplier_product_form_dialog.dart'; // Crearemos este a continuación
import 'package:intl/intl.dart';


class ManageSupplierProductsScreen extends StatefulWidget {
  final Supplier supplier;
  final List<Product> allProducts; // Lista de todos los productos para seleccionar

  ManageSupplierProductsScreen({
    Key? key,
    required this.supplier,
    required this.allProducts,
  }) : super(key: key);

  @override
  _ManageSupplierProductsScreenState createState() => _ManageSupplierProductsScreenState();
}

class _ManageSupplierProductsScreenState extends State<ManageSupplierProductsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<SupplierProductInfo> _supplierProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplierProducts();
  }

  Future<void> _loadSupplierProducts({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);
    try {
      // Asumiendo que getSupplierProductInfoForSupplier devuelve List<SupplierProductInfo>
      // y que el modelo SupplierProductInfo puede tener un campo 'productName' si se hace join.
      _supplierProducts = await _dbService.getSupplierProductInfoForSupplier(widget.supplier.id!);
    } catch (e) {
      _showError('Error al cargar productos del proveedor: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
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


  void _openSupplierProductForm({SupplierProductInfo? existingSpi}) async {
    final bool? resultRefreshed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SupplierProductFormDialog(
          supplierId: widget.supplier.id!,
          existingSpi: existingSpi,
          allProducts: widget.allProducts,
          // Pasar el nombre del producto si estamos editando y lo tenemos
          productName: existingSpi?.productName ?? 
                       (existingSpi != null 
                           ? widget.allProducts.firstWhere((p) => p.id == existingSpi.productId, orElse: () => Product(id:'', name:'Desconocido', unitCost:0, salePrice:0)).name 
                           : null),
        );
      },
    );

    if (resultRefreshed == true && mounted) {
      _loadSupplierProducts(showLoading: false); // Recargar sin mostrar el loader principal
      // Notificar a ManagementScreen que podría haber cambios
      // Navigator.of(context).maybePop(true); // Esto depende de cómo se maneje la pila de navegación
    }
  }

  Future<void> _deleteSupplierProductLink(String spiId) async {
    // Confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desvincular Producto'),
        content: Text('¿Estás seguro de que quieres desvincular este producto del proveedor?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Desvincular', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteSupplierProductInfo(spiId);
        _showSuccess('Producto desvinculado del proveedor.');
        _loadSupplierProducts(showLoading: false);
      } catch (e) {
        _showError('Error al desvincular producto: ${e.toString()}');
      }
    }
  }
  
  String _formatCurrency(double? value) {
    if (value == null) return 'N/A';
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(value);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de ${widget.supplier.name}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _supplierProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Este proveedor no tiene productos vinculados.', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add_link),
                        label: Text('Vincular Primer Producto'),
                        onPressed: () => _openSupplierProductForm(),
                      )
                    ],
                  )
                )
              : RefreshIndicator(
                  onRefresh: () => _loadSupplierProducts(showLoading: false),
                  child: ListView.builder(
                    itemCount: _supplierProducts.length,
                    itemBuilder: (context, index) {
                      final spi = _supplierProducts[index];
                      // Asumiendo que spi.productName se llena con un join en el servicio
                      // o lo buscamos en _allProducts.
                      final productName = spi.productName ?? 
                                          widget.allProducts.firstWhere(
                                            (p) => p.id == spi.productId, 
                                            orElse: () => Product(id: '', name: 'Producto Desconocido', unitCost: 0, salePrice: 0)
                                          ).name;

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Costo Suministro: ${_formatCurrency(spi.supplyCost)}'),
                              if (spi.deliveryLeadTimeDays != null)
                                Text('Tiempo Entrega: ${spi.deliveryLeadTimeDays} días'),
                              if (spi.supplierProductCode != null && spi.supplierProductCode!.isNotEmpty)
                                Text('Cód. Proveedor: ${spi.supplierProductCode}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                tooltip: 'Editar Vínculo',
                                onPressed: () => _openSupplierProductForm(existingSpi: spi),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Desvincular Producto',
                                onPressed: () => _deleteSupplierProductLink(spi.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSupplierProductForm(),
        label: Text('Vincular Producto'),
        icon: Icon(Icons.add_link),
        tooltip: 'Vincular Nuevo Producto al Proveedor',
      ),
    );
  }
}