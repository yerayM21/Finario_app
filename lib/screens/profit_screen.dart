import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/DatabaseService.dart';
import '../models/transaction.dart';
import '../models/supplier_invoice.dart';
import '../models/customer_receivable.dart';

class ProfitScreen extends StatefulWidget {
  @override
  _ProfitScreenState createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _transactions = [];
  List<SupplierInvoice> _supplierInvoices = [];
  List<CustomerReceivable> _customerReceivables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _transactions = await _dbService.getTransactions();
      _supplierInvoices = await _dbService.getSupplierInvoices(status: InvoiceStatus.pending.name);
      _customerReceivables = await _dbService.getCustomerReceivables(status: InvoiceStatus.pending.name);

      // Depuración: Imprimir información básica
      print("\n--- INICIO DE DEPURACIÓN DE PROFITSCREEN ---");
      print("Total de transacciones: ${_transactions.length}");
      print("Total de facturas: ${_supplierInvoices.length}");
      print("Total de cuentas por cobrar: ${_customerReceivables.length}");

      // Depuración: Imprimir tipos de transacción
      print("\nTipos de Transacción:");
      _transactions.forEach((tx) => print("  - ${tx.type}: ${tx.amount}"));

      // Depuración: Imprimir detalles de facturas
      print("\nDetalles de Facturas (Pendientes):");
      _supplierInvoices.forEach((invoice) => print("  - ${invoice.invoiceNumber ?? invoice.id}: Total=${invoice.totalAmount}, Paid=${invoice.amountPaid}, Due=${invoice.totalAmount - invoice.amountPaid}"));

      // Depuración: Imprimir detalles de cuentas por cobrar
      print("\nDetalles de Cuentas por Cobrar (Pendientes):");
      _customerReceivables.forEach((receivable) => print("  - ${receivable.id}: Total=${receivable.totalDue}, Paid=${receivable.amountPaid}, Due=${receivable.totalDue - receivable.amountPaid}"));

    } catch (e) {
      _showError('Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double _calculateTotalIncome() {
    double income = _transactions
        .where((tx) => tx.type == 'generic_income' || tx.type == 'sale')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    print("\nTotal Ingresos: $income");
    return income;
  }

  double _calculateTotalExpenses() {
    double expenses = _transactions
        .where((tx) => tx.type == 'generic_expense' || tx.type == 'purchase')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    print("Total Gastos: $expenses");
    return expenses;
  }

  double _calculateTotalPayables() {
    double payables = _supplierInvoices
        .fold(0.0, (sum, invoice) => sum + (invoice.totalAmount - invoice.amountPaid));
    print("Total Por Pagar: $payables");
    return payables;
  }

  double _calculateTotalReceivables() {
    double receivables = _customerReceivables
        .fold(0.0, (sum, receivable) => sum + (receivable.totalDue - receivable.amountPaid));
    print("Total Por Cobrar: $receivables");
    return receivables;
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _calculateTotalIncome();
    final totalExpenses = _calculateTotalExpenses().abs();
    final totalPayables = _calculateTotalPayables();
    final totalReceivables = _calculateTotalReceivables();

    final total = totalIncome + totalExpenses + totalPayables + totalReceivables;

    final incomePercentage = total == 0 ? 0 : totalIncome / total * 100;
    final expensePercentage = total == 0 ? 0 : totalExpenses / total * 100;
    final payablesPercentage = total == 0 ? 0 : totalPayables / total * 100;
    final receivablesPercentage = total == 0 ? 0 : totalReceivables / total * 100;

    print("\n--- Cálculos Finales ---");
    print("Total: $total");
    print("Porcentaje Ingresos: $incomePercentage");
    print("Porcentaje Gastos: $expensePercentage");
    print("Porcentaje Por Pagar: $payablesPercentage");
    print("Porcentaje Por Cobrar: $receivablesPercentage");

    return Scaffold(
      appBar: AppBar(
        title: Text('Análisis de Ganancias'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfitCard(totalIncome - totalExpenses - totalPayables),
                  SizedBox(height: 20),
                  Text(
                    'Resumen Financiero',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _buildPieChart(),
                  ),
                  SizedBox(height: 20),
                  _buildLegend(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfitCard(double netProfit) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ganancia Neta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(netProfit),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: netProfit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final totalIncome = _calculateTotalIncome();
    final totalExpenses = _calculateTotalExpenses().abs();
    final totalPayables = _calculateTotalPayables();
    final totalReceivables = _calculateTotalReceivables();

    final total = totalIncome + totalExpenses + totalPayables + totalReceivables;

    final incomePercentage = total == 0 ? 0 : totalIncome / total * 100;
    final expensePercentage = total == 0 ? 0 : totalExpenses / total * 100;
    final payablesPercentage = total == 0 ? 0 : totalPayables / total * 100;
    final receivablesPercentage = total == 0 ? 0 : totalReceivables / total * 100;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: totalIncome,
            title: '${incomePercentage.toStringAsFixed(1)}%\n${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(totalIncome)}',
            color: Colors.green,
            radius: 100,
            titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: totalExpenses,
            title: '${expensePercentage.toStringAsFixed(1)}%\n${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(totalExpenses)}',
            color: Colors.red,
            radius: 100,
            titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: totalPayables,
            title: '${payablesPercentage.toStringAsFixed(1)}%\n${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(totalPayables)}',
            color: Colors.orange,
            radius: 100,
            titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: totalReceivables,
            title: '${receivablesPercentage.toStringAsFixed(1)}%\n${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(totalReceivables)}',
            color: Colors.blue,
            radius: 100,
            titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        borderData: FlBorderData(show: false),
        centerSpaceRadius: 80,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leyenda', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            _buildLegendItem(Colors.green, 'Ingresos'),
            SizedBox(height: 8),
            _buildLegendItem(Colors.red, 'Gastos'),
            SizedBox(height: 8),
            _buildLegendItem(Colors.orange, 'Por Pagar'),
            SizedBox(height: 8),
            _buildLegendItem(Colors.blue, 'Por Cobrar'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          color: color,
          margin: EdgeInsets.only(right: 8),
        ),
        Text(text),
      ],
    );
  }
}