import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/datasources/reports_remote_datasource.dart';
import '../../../data/models/sucursal_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SucursalModel> _sucursales = [];
  bool _isLoading = true;
  late ReportsRemoteDataSource _reportsDataSource;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _reportsDataSource = ReportsRemoteDataSource(apiClient: apiClient);
    _loadSucursales();
  }

  Future<void> _loadSucursales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sucursales = await _reportsDataSource.getSucursalesDisponibles();
      setState(() {
        _sucursales = sucursales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de bienvenida
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.secondaryGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.recycling,
                          color: AppTheme.white,
                          size: 40,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Bienvenido',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestión inteligente de reciclaje',
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sucursales
            const Text(
              'Sucursales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              )
            else if (_sucursales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No hay sucursales disponibles',
                    style: TextStyle(
                      color: AppTheme.grey,
                    ),
                  ),
                ),
              )
            else
              ..._buildSucursalesCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSucursalesCards() {
    final cards = <Widget>[];
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.secondaryGreen,
      AppTheme.accentGreen,
      AppTheme.primaryLightGreen,
    ];
    final icons = [
      Icons.store,
      Icons.business,
      Icons.location_city,
      Icons.store_mall_directory,
    ];

    // Mostrar hasta 4 sucursales
    final sucursalesToShow = _sucursales.take(4).toList();

    for (int i = 0; i < sucursalesToShow.length; i += 2) {
      final row = <Widget>[];

      // Primera tarjeta de la fila
      if (i < sucursalesToShow.length) {
        row.add(
          Expanded(
            child: _StatCard(
              icon: icons[i % icons.length],
              title: 'Sucursal',
              value: sucursalesToShow[i].nombre,
              color: colors[i % colors.length],
            ),
          ),
        );
      }

      // Segunda tarjeta de la fila (si existe)
      if (i + 1 < sucursalesToShow.length) {
        row.add(const SizedBox(width: 12));
        row.add(
          Expanded(
            child: _StatCard(
              icon: icons[(i + 1) % icons.length],
              title: 'Sucursal',
              value: sucursalesToShow[i + 1].nombre,
              color: colors[(i + 1) % colors.length],
            ),
          ),
        );
      }

      cards.add(Row(children: row));
      if (i + 2 < sucursalesToShow.length) {
        cards.add(const SizedBox(height: 12));
      }
    }

    return cards;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
