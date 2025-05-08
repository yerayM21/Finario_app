import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Cambia la importación a community_charts_flutter
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;

// Importa tus modelos y servicios
// Ajusta estas rutas si tu estructura de carpetas es diferente.
import '../../models/transaction.dart' as app_transaction; 
import '../../services/DatabaseService.dart'; 

// Modelo simple para los datos de la gráfica
class ReportData {
  final String segment;
  final double amount;
  final charts.Color barColor; 

  ReportData(this.segment, this.amount, {required this.barColor});
}

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _dbService = DatabaseService();
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  bool _isLoading = false; 

  List<app_transaction.Transaction> _transactions = [];
  List<charts.Series<ReportData, String>>? _seriesData;

  double _totalSales = 0.0;
  double _totalOtherIncome = 0.0; 
  double _totalExpenses = 0.0;    
  double _netProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365 * 10)), 
      helpText: isStartDate ? 'SELECCIONAR FECHA INICIO' : 'SELECCIONAR FECHA FIN',
      locale: const Locale('es', 'MX'), 
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
      // Considerar llamar a _fetchReportData() aquí si quieres auto-actualización
    }
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; 
      _seriesData = null; 
      _transactions = []; 
      _totalSales = 0.0;
      _totalOtherIncome = 0.0;
      _totalExpenses = 0.0;
      _netProfit = 0.0;
    });

    try {
      final allTransactionsInRange = await _dbService.getTransactionsByDateRangeAndTypes(
        startDate: _startDate,
        endDate: _endDate,
        types: ['sale', 'generic_income', 'generic_expense', 'purchase'], 
      );

      if (!mounted) return;

      _transactions = allTransactionsInRange;
      _calculateTotalsAndPrepareChartData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); 
      }
    }
  }

  void _calculateTotalsAndPrepareChartData() {
    double currentSales = 0.0;
    double currentOtherIncome = 0.0;
    double currentPurchasesCost = 0.0; 
    double currentGenericExpensesCost = 0.0; 

    for (var t in _transactions) {
      switch (t.type) {
        case 'sale':
          currentSales += t.amount; 
          break;
        case 'generic_income':
          currentOtherIncome += t.amount; 
          break;
        case 'purchase':
          currentPurchasesCost += t.amount.abs();
          break;
        case 'generic_expense':
          currentGenericExpensesCost += t.amount.abs();
          break;
      }
    }

    _totalSales = currentSales;
    _totalOtherIncome = currentOtherIncome;
    _totalExpenses = currentPurchasesCost + currentGenericExpensesCost; 
    _netProfit = (_totalSales + _totalOtherIncome) - _totalExpenses;

    final List<ReportData> reportSummaryData = [
      ReportData('Ventas', _totalSales, barColor: charts.ColorUtil.fromDartColor(Colors.green.shade400)),
      ReportData('Otros Ingresos', _totalOtherIncome, barColor: charts.ColorUtil.fromDartColor(Colors.blue.shade400)),
      ReportData('Gastos Totales', _totalExpenses, barColor: charts.ColorUtil.fromDartColor(Colors.red.shade400)),
    ];

    _seriesData = [
      charts.Series<ReportData, String>(
        id: 'ResumenFinanciero',
        domainFn: (ReportData report, _) => report.segment,
        measureFn: (ReportData report, _) => report.amount,
        colorFn: (ReportData report, _) => report.barColor,
        data: reportSummaryData,
        // Define SÓLO el texto de la etiqueta
        labelAccessorFn: (ReportData report, _) {
           // Evitar mostrar etiqueta para valores muy pequeños o cero si se desea
           if (report.amount.abs() < 1) return ''; 
           return NumberFormat.compactCurrency(locale: 'es_MX', symbol: '\$', decimalDigits: 0).format(report.amount);
        },
        // --- labelStyleAccessorFn REMOVIDO ---
      )
    ];

    if (mounted) {
      setState(() {}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Financieros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchReportData,
            tooltip: 'Recargar Datos',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Seleccionar Rango de Fechas", 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha Inicio',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(formatter.format(_startDate)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                               decoration: InputDecoration(
                                labelText: 'Fecha Fin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(formatter.format(_endDate)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: _isLoading 
                            ? SizedBox(width:18, height:18, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2,)) 
                            : const Icon(Icons.bar_chart_rounded),
                      label: Text(_isLoading ? 'GENERANDO...' : 'GENERAR REPORTE'),
                      onPressed: _isLoading ? null : _fetchReportData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Sección de Resumen ---
            if (!_isLoading && _transactions.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resumen del Periodo", 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow("Ingresos por Ventas:", _totalSales, Colors.green.shade600),
                      _buildSummaryRow("Otros Ingresos:", _totalOtherIncome, Colors.blue.shade600),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top:4, bottom:4),
                        child: _buildSummaryRow(
                          "SUBTOTAL INGRESOS:", 
                          _totalSales + _totalOtherIncome, 
                          Colors.teal.shade700, isBold: true, fontSize: 17
                        ),
                      ),
                      const Divider(height: 24, thickness: 0.5, color: Colors.grey),
                      _buildSummaryRow("Gastos Totales:", _totalExpenses, Colors.red.shade600), 
                      const Divider(height: 28, thickness: 1.5),
                      _buildSummaryRow(
                        "RESULTADO NETO:",
                        _netProfit,
                        _netProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                        isBold: true,
                        fontSize: 19
                      ),
                    ],
                  ),
                ),
              ),
            
            // --- Indicador de Carga ---
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // --- Gráfica de Resumen ---
            if (!_isLoading && _seriesData != null && _transactions.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                         "Gráfica: Ingresos y Gastos", 
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)
                        ),
                       const SizedBox(height: 12),
                       Container(
                        height: 220, 
                        child: charts.BarChart(
                          _seriesData!,
                          animate: true,
                          animationDuration: const Duration(milliseconds: 500),
                          vertical: false, 
                          // --- Decorador solo para posición, sin estilo ---
                          barRendererDecorator: charts.BarLabelDecorator<String>(
                            labelPosition: charts.BarLabelPosition.auto, 
                          ),
                          // --- Fin sección decorador ---
                          domainAxis: charts.OrdinalAxisSpec(
                            renderSpec: charts.SmallTickRendererSpec(
                              labelStyle: charts.TextStyleSpec(
                                fontSize: 11, 
                                color: charts.ColorUtil.fromDartColor(Colors.grey.shade700), 
                                fontWeight: '500'
                              ),
                            ),
                          ),
                          primaryMeasureAxis: charts.NumericAxisSpec(
                            tickProviderSpec: const charts.BasicNumericTickProviderSpec(desiredTickCount: 4),
                            tickFormatterSpec: charts.BasicNumericTickFormatterSpec.fromNumberFormat(
                              NumberFormat.compactCurrency(locale: 'es_MX', symbol: '\$')
                            ),
                            renderSpec: charts.GridlineRendererSpec(
                              labelStyle: charts.TextStyleSpec(
                                  fontSize: 10, 
                                  color: charts.ColorUtil.fromDartColor(Colors.grey.shade500) 
                              ),
                              lineStyle: charts.LineStyleSpec(
                                  color: charts.ColorUtil.fromDartColor(Colors.grey.shade200) 
                              ),
                            ),
                          ),
                           behaviors: [
                              charts.SeriesLegend(
                                position: charts.BehaviorPosition.bottom,
                                horizontalFirst: false,
                                cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
                                showMeasures: false, 
                                entryTextStyle: charts.TextStyleSpec(
                                    color: charts.ColorUtil.fromDartColor(Colors.black), 
                                    fontSize: 10
                                ),
                              )
                            ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // --- Mensaje de "No hay transacciones" ---
            else if (!_isLoading && _transactions.isEmpty && 
                     !(_startDate.isAtSameMomentAs(DateTime.now().subtract(Duration(days:30))) && 
                       _endDate.isAtSameMomentAs(DateTime.now()) && 
                       _transactions.isEmpty) )
                 Center(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                            'No hay transacciones en el periodo seleccionado.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                        ),
                        ],
                    ),
                    ),
                ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color valueColor, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3, 
            child: Text(
              label, 
              style: TextStyle(
                fontSize: fontSize, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
                color: Colors.grey.shade800
              ),
              overflow: TextOverflow.ellipsis,
            )
          ),
          const SizedBox(width: 8),
          Expanded( 
            flex: 2,
            child: Text(
              NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(value),
              style: TextStyle(
                fontSize: fontSize, 
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: valueColor
              ),
              textAlign: TextAlign.end, 
            ),
          ),
        ],
      ),
    );
  }
}