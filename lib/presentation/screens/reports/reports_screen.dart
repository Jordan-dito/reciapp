import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/datasources/reports_remote_datasource.dart';
import '../../../data/models/sucursal_model.dart';
import '../../../data/models/categoria_porcentaje_model.dart';
import '../../../data/models/sucursal_gastos_compras_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedSucursal;

  // Lista de sucursales cargadas del servidor
  List<SucursalModel> _sucursales = [];
  List<CategoriaPorcentajeModel> _categorias = [];
  bool _isLoadingSucursales = true;
  bool _isLoadingCategorias = false;
  double _totalCantidad = 0.0;

  // Datos de gastos/compras por sucursal (para scatter)
  List<SucursalGastosComprasModel> _sucursalGastosCompras = [];
  bool _isLoadingGastosCompras = false;

  late ReportsRemoteDataSource _reportsDataSource;

  final List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_selectedYear, _selectedMonth);
    // Inicializar datasource
    final apiClient = context.read<ApiClient>();
    _reportsDataSource = ReportsRemoteDataSource(apiClient: apiClient);
    _loadSucursales();
    _loadReportsData();
    _loadGastosCompras();
  }

  Future<void> _loadSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
    });

    try {
      final sucursales = await _reportsDataSource.getSucursalesDisponibles();
      setState(() {
        _sucursales = sucursales;
        if (_sucursales.isNotEmpty && _selectedSucursal == null) {
          _selectedSucursal = _sucursales.first.id.toString();
        }
        _isLoadingSucursales = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSucursales = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sucursales: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGastosCompras() async {
    setState(() {
      _isLoadingGastosCompras = true;
    });

    try {
      final mes = _selectedMonth.toString().padLeft(2, '0');
      final anio = _selectedYear.toString();

      final items = await _reportsDataSource.getGastosComprasPorSucursal(
        mes: mes,
        anio: anio,
      );

      setState(() {
        _sucursalGastosCompras = items;
        _isLoadingGastosCompras = false;
      });
    } catch (e) {
      setState(() {
        _sucursalGastosCompras = [];
        _isLoadingGastosCompras = false;
      });
    }
  }

  Future<void> _selectMonth() async {
    final List<String> options = List.generate(12, (index) => _meses[index]);

    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => _FilterDialog(
        title: 'Seleccionar Mes',
        options: options,
        selectedIndex: _selectedMonth - 1,
      ),
    );

    if (selected != null) {
      final monthIndex = options.indexOf(selected);
      setState(() {
        _selectedMonth = monthIndex + 1;
        _selectedDate = DateTime(_selectedYear, _selectedMonth);
      });
      _loadReportsData();
    }
  }

  Future<void> _selectYear() async {
    final currentYear = DateTime.now().year;
    final List<String> years = List.generate(
      currentYear - 2019,
      (index) => (currentYear - index).toString(),
    );

    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => _FilterDialog(
        title: 'Seleccionar Año',
        options: years,
        selectedValue: _selectedYear.toString(),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedYear = int.parse(selected);
        _selectedDate = DateTime(_selectedYear, _selectedMonth);
      });
      _loadReportsData();
    }
  }

  Future<void> _selectSucursal() async {
    if (_sucursales.isEmpty) return;

    final List<String> options = _sucursales.map((s) => s.nombre).toList();

    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => _FilterDialog(
        title: 'Seleccionar Sucursal',
        options: options,
        selectedValue: _sucursales
            .firstWhere(
              (s) => s.id.toString() == _selectedSucursal,
              orElse: () => _sucursales.first,
            )
            .nombre,
      ),
    );

    if (selected != null) {
      final sucursal = _sucursales.firstWhere((s) => s.nombre == selected);
      setState(() {
        _selectedSucursal = sucursal.id.toString();
      });
      _loadReportsData();
    }
  }

  Future<void> _loadReportsData() async {
    if (_selectedSucursal == null) return;

    setState(() {
      _isLoadingCategorias = true;
    });

    try {
      final sucursalId = int.tryParse(_selectedSucursal!);

      final result = await _reportsDataSource.getPorcentajesCategorias(
        anio: _selectedYear,
        mes: _selectedMonth,
        sucursalId: sucursalId,
      );

      final categorias = result['categorias'] as List<CategoriaPorcentajeModel>;
      final totalCantidad = result['total_cantidad'] as double;

      // Limpiar categorías si todas son cero para mostrar estado vacío
      final allZero =
          categorias.every((cat) => cat.cantidad == 0 || cat.porcentaje == 0);
      if (allZero) categorias.clear();

      setState(() {
        _categorias = categorias;
        _totalCantidad = totalCantidad;
        _isLoadingCategorias = false;
      });

      _loadGastosCompras();
    } catch (e) {
      setState(() {
        _isLoadingCategorias = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Filtro profesional con mes, año y sucursal
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtros de Búsqueda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Fila de filtros
                Row(
                  children: [
                    // Selector de Mes
                    Expanded(
                      child: _FilterSelector(
                        label: 'Mes',
                        value: _meses[_selectedMonth - 1],
                        icon: Icons.calendar_month,
                        onTap: _selectMonth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Selector de Año
                    Expanded(
                      child: _FilterSelector(
                        label: 'Año',
                        value: _selectedYear.toString(),
                        icon: Icons.calendar_today,
                        onTap: _selectYear,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Selector de Sucursal
                    Expanded(
                      child: _FilterSelector(
                        label: 'Sucursal',
                        value: _isLoadingSucursales
                            ? 'Cargando...'
                            : _sucursales.isEmpty
                                ? 'Sin sucursales'
                                : _sucursales
                                    .firstWhere(
                                      (s) =>
                                          s.id.toString() == _selectedSucursal,
                                      orElse: () => _sucursales.first,
                                    )
                                    .nombre,
                        icon: Icons.store,
                        onTap: _isLoadingSucursales ? () {} : _selectSucursal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Etiquetas de valores seleccionados
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtros activos: ${_meses[_selectedMonth - 1]} $_selectedYear - ${_isLoadingSucursales || _sucursales.isEmpty ? "N/A" : _sucursales.firstWhere((s) => s.id.toString() == _selectedSucursal, orElse: () => _sucursales.first).nombre}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenido con scroll
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Resumen general mejorado
                  _ModernSummaryCard(
                    selectedDate: _selectedDate,
                    totalKg: _totalCantidad,
                    totalVentas: _sucursalGastosCompras.fold(
                        0.0, (sum, s) => sum + s.totalVenta),
                  ),
                  const SizedBox(height: 16),
                  // Gráfico de distribución de materiales (mejorado)
                  _DistributionChartCard(
                    categorias: _categorias,
                    isLoading: _isLoadingCategorias,
                  ),
                  const SizedBox(height: 16),
                  // Gráfico de barras mejorado
                  _MaterialsBarChartCard(
                    categorias: _categorias,
                    isLoading: _isLoadingCategorias,
                  ),
                  const SizedBox(height: 16),
                  // Gráfico de tendencia mejorado
                  _TrendLineChartCard(),
                  const SizedBox(height: 16),
                  // Gráfico de dispersión: Compra (X) vs Venta (Y), tamaño = Ganancia
                  _BranchScatterChartCard(
                    items: _sucursalGastosCompras,
                    isLoading: _isLoadingGastosCompras,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSummaryCard extends StatelessWidget {
  final DateTime selectedDate;
  final double totalKg;
  final double totalVentas;

  const _ModernSummaryCard({
    required this.selectedDate,
    required this.totalKg,
    required this.totalVentas,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.##', 'es');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.secondaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy', 'es').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.recycling,
                    value: numberFormat.format(totalKg),
                    unit: 'kg',
                    label: 'Total Reciclado',
                  ),
                ),
                Container(
                  width: 1,
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppTheme.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.attach_money,
                    value: numberFormat.format(totalVentas),
                    unit: '\$',
                    label: 'Ventas',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.white, size: 28),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _DistributionChartCard extends StatelessWidget {
  final List<CategoriaPorcentajeModel> categorias;
  final bool isLoading;

  const _DistributionChartCard({
    required this.categorias,
    required this.isLoading,
  });

  // Paleta de colores variada y atractiva para las categorías
  static final List<Color> _colors = [
    const Color(0xFF2E7D32), // Verde oscuro (Plásticos)
    const Color(0xFF1976D2), // Azul (Vidrio)
    const Color(0xFFFF9800), // Naranja (Papel)
    const Color(0xFF9C27B0), // Púrpura (Metal)
    const Color(0xFFE91E63), // Rosa (Orgánico)
    const Color(0xFF00BCD4), // Cyan (Electrónicos)
    const Color(0xFFFFC107), // Ámbar (Textiles)
    const Color(0xFF795548), // Marrón (Otros)
  ];

  Color _getColorForIndex(int index) {
    return _colors[index % _colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando o no hay datos, mostrar estado vacío
    if (isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Distribución de Materiales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cargando datos...',
                style: TextStyle(
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Verificar si no hay datos o todas las cantidades son cero
    final hasNoData = categorias.isEmpty ||
        categorias.every((cat) => cat.cantidad == 0 || cat.porcentaje == 0);

    if (hasNoData) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Distribución de Materiales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.pie_chart_outline,
                size: 60,
                color: AppTheme.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'No hay datos disponibles',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No se encontraron registros para los filtros seleccionados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.grey.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.lightGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Distribución de Materiales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Gráfico y leyenda en layout mejorado
            SizedBox(
              height: 280,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gráfico circular centrado
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 55,
                            sections: categorias.asMap().entries.map((entry) {
                              final index = entry.key;
                              final categoria = entry.value;
                              final color = _getColorForIndex(index);

                              return PieChartSectionData(
                                value: categoria.porcentaje,
                                title:
                                    '${categoria.porcentaje.toStringAsFixed(1)}%',
                                color: color,
                                radius: 70,
                                titleStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.white,
                                ),
                              );
                            }).toList(),
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                if (!event.isInterestedForInteractions) return;
                                if (pieTouchResponse?.touchedSection == null) return;

                                final touchedIndex = pieTouchResponse!
                                    .touchedSection!.touchedSectionIndex;

                                if (touchedIndex >= 0 &&
                                    touchedIndex < categorias.length) {
                                  final categoria = categorias[touchedIndex];
                                  final message =
                                      '${categoria.categoriaNombre}: ${categoria.porcentaje.toStringAsFixed(1)}% (${categoria.cantidad.toStringAsFixed(2)} kg)';

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          message,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 3),
                                        backgroundColor:
                                            _getColorForIndex(touchedIndex),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        action: SnackBarAction(
                                          label: 'OK',
                                          textColor: Colors.white,
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Leyenda mejorada
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: categorias.asMap().entries.map((entry) {
                          final index = entry.key;
                          final categoria = entry.value;
                          final color = _getColorForIndex(index);

                          return Column(
                            children: [
                              _ModernLegendItem(
                                color: color,
                                label: categoria.categoriaNombre,
                                percentage:
                                    '${categoria.porcentaje.toStringAsFixed(1)}%',
                              ),
                              if (index < categorias.length - 1)
                                const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String percentage;

  const _ModernLegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                percentage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialsBarChartCard extends StatelessWidget {
  final List<CategoriaPorcentajeModel> categorias;
  final bool isLoading;

  const _MaterialsBarChartCard({
    required this.categorias,
    required this.isLoading,
  });

  // Paleta de colores profesional para las barras
  static final List<Color> _barColors = [
    const Color(0xFF2E7D32), // Verde oscuro
    const Color(0xFF1976D2), // Azul
    const Color(0xFFFF9800), // Naranja
    const Color(0xFF9C27B0), // Púrpura
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFFC107), // Ámbar
    const Color(0xFF795548), // Marrón
  ];

  Color _getColorForIndex(int index) {
    return _barColors[index % _barColors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando, mostrar estado de carga
    if (isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Materiales Reciclados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cargando datos...',
                style: TextStyle(
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Verificar si no hay datos o todas las cantidades son cero
    final hasNoData = categorias.isEmpty ||
        categorias.every((cat) => cat.cantidad == 0 || cat.porcentaje == 0);

    if (hasNoData) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Materiales Reciclados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.bar_chart_outlined,
                size: 60,
                color: AppTheme.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'No hay datos disponibles',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No se encontraron registros para los filtros seleccionados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.grey.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.lightGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Materiales Reciclados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Gráfico de barras horizontal profesional con datos reales
            SizedBox(
              height: categorias.length * 70.0 + 40,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: () {
                    if (categorias.isEmpty) return 100.0;
                    final max = categorias
                        .map((c) => c.cantidad)
                        .reduce((a, b) => a > b ? a : b);
                    return max == 0 ? 100.0 : max * 1.2;
                  }(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= 0 && groupIndex < categorias.length) {
                          final categoria = categorias[groupIndex];
                          return BarTooltipItem(
                            '${categoria.categoriaNombre}\n${categoria.cantidad.toStringAsFixed(2)} kg\n${categoria.porcentaje.toStringAsFixed(1)}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return BarTooltipItem('', const TextStyle());
                      },
                    ),
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (barTouchResponse?.spot != null &&
                          event is FlTapUpEvent) {
                        final spot = barTouchResponse!.spot;
                        final groupIndex = spot?.touchedBarGroupIndex;
                        if (groupIndex != null &&
                            groupIndex >= 0 &&
                            groupIndex < categorias.length) {
                          final categoria = categorias[groupIndex];
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${categoria.categoriaNombre}: ${categoria.cantidad.toStringAsFixed(2)} kg (${categoria.porcentaje.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: _getColorForIndex(groupIndex),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < categorias.length) {
                            final categoria = categorias[value.toInt()];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  categoria.cantidad.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: AppTheme.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 120,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < categorias.length) {
                            final categoria = categorias[value.toInt()];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  categoria.categoriaNombre,
                                  style: const TextStyle(
                                    color: AppTheme.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: false,
                    verticalInterval: () {
                      if (categorias.isEmpty) return 20.0;
                      final max = categorias
                          .map((c) => c.cantidad)
                          .reduce((a, b) => a > b ? a : b);
                      final interval = (max * 1.2) / 5;
                      return interval == 0 ? 20.0 : interval;
                    }(),
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: AppTheme.lightGrey.withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.lightGrey.withOpacity(0.3),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: AppTheme.lightGrey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  barGroups: categorias.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoria = entry.value;
                    final color = _getColorForIndex(index);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: categoria.cantidad,
                          color: color,
                          width: 32,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: () {
                              final max = categorias
                                  .map((c) => c.cantidad)
                                  .reduce((a, b) => a > b ? a : b);
                              return max == 0 ? 100.0 : max * 1.2;
                            }(),
                            color: AppTheme.lightGrey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendLineChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.lightGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Tendencia de Ingresos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.lightGrey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Ene',
                            'Feb',
                            'Mar',
                            'Abr',
                            'May',
                            'Jun'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                months[value.toInt()],
                                style: const TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '\$${value.toInt()}',
                              style: const TextStyle(
                                color: AppTheme.grey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 2500),
                        FlSpot(1, 3200),
                        FlSpot(2, 2800),
                        FlSpot(3, 4100),
                        FlSpot(4, 3700),
                        FlSpot(5, 4800),
                      ],
                      isCurved: true,
                      color: AppTheme.primaryGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchScatterChartCard extends StatelessWidget {
  final List<SucursalGastosComprasModel> items;
  final bool isLoading;

  const _BranchScatterChartCard({
    required this.items,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: const [
              Text(
                'Gastos y Ventas por Sucursal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.black),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              SizedBox(height: 20),
              Text('Cargando datos...'),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Gastos y Ventas por Sucursal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.black),
              ),
              const SizedBox(height: 40),
              Icon(Icons.scatter_plot_outlined, size: 60, color: AppTheme.grey.withOpacity(0.5)),
              const SizedBox(height: 20),
              const Text('No hay datos disponibles'),
            ],
          ),
        ),
      );
    }

    // Mostrar Bubble chart (tamaño = ganancia)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.lightGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Gastos y Ventas por Sucursal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.black),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.scatter_plot,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: items.asMap().entries.map<ScatterSpot>((entry) {
                    final d = entry.value;
                    return ScatterSpot(
                      d.totalCompra,
                      d.totalVenta,
                    );
                  }).toList(),
                  minX: items.isEmpty ? 0 : (items.map((i) => i.totalCompra).reduce((a, b) => a < b ? a : b) * 0.9),
                  maxX: items.isEmpty ? 100 : (items.map((i) => i.totalCompra).reduce((a, b) => a > b ? a : b) * 1.1),
                  minY: items.isEmpty ? 0 : (items.map((i) => i.totalVenta).reduce((a, b) => a < b ? a : b) * 0.9),
                  maxY: items.isEmpty ? 100 : (items.map((i) => i.totalVenta).reduce((a, b) => a > b ? a : b) * 1.1),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.lightGrey.withOpacity(0.2)),
                    getDrawingVerticalLine: (value) => FlLine(color: AppTheme.lightGrey.withOpacity(0.2)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppTheme.lightGrey.withOpacity(0.3)),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Total Compra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text('Total Venta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      tooltipBgColor: AppTheme.primaryGreen,
                      getTooltipItems: (touchedSpot) {
                        final match = items.firstWhere(
                          (it) => (it.totalCompra - touchedSpot.x).abs() < 1.0 && (it.totalVenta - touchedSpot.y).abs() < 1.0,
                          orElse: () => items.isNotEmpty ? items.first : SucursalGastosComprasModel(
                            sucursalId: 0,
                            sucursalNombre: 'N/A',
                            totalGasto: 0,
                            totalCompra: 0,
                            totalVenta: 0,
                            ganancia: 0,
                          ),
                        );
                        return ScatterTooltipItem(
                          '${match.sucursalNombre}\nCompra: \$${match.totalCompra.toStringAsFixed(2)}\nVenta: \$${match.totalVenta.toStringAsFixed(2)}\nGanancia: \$${match.ganancia.toStringAsFixed(2)}',
                          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para selector de filtro individual
class _FilterSelector extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterSelector({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para diálogo de selección
class _FilterDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  final int? selectedIndex;
  final String? selectedValue;

  const _FilterDialog({
    required this.title,
    required this.options,
    this.selectedIndex,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppTheme.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedIndex != null
                      ? index == selectedIndex
                      : selectedValue != null && option == selectedValue;

                  return InkWell(
                    onTap: () => Navigator.of(context).pop(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : AppTheme.backgroundGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.black,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
