import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/datasources/reports_remote_datasource.dart';
import '../../../data/models/sucursal_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

/// Tipos de reporte según FLUTTER_REPORTES_API.md
const _tiposReporte = [
  ('inventarios', 'Reporte de Inventarios', true),
  ('compras', 'Reporte de Compras', true),
  ('ventas', 'Reporte de Ventas', true),
  ('productos', 'Reporte de Productos', false),
  ('materiales', 'Reporte de Materiales por Categoría', false),
  ('sucursales', 'Reporte de Sucursales', true),
  ('usuarios', 'Reporte de Usuarios por Rol', true),
];

class ReportesApiScreen extends StatefulWidget {
  const ReportesApiScreen({super.key});

  @override
  State<ReportesApiScreen> createState() => _ReportesApiScreenState();
}

class _ReportesApiScreenState extends State<ReportesApiScreen> {
  late ReportsRemoteDataSource _reportsDataSource;

  String _tipoSeleccionado = 'compras';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  SucursalModel? _sucursalSeleccionada;
  int? _rolId;
  String _material = '';

  List<SucursalModel> _sucursales = [];
  List<Map<String, dynamic>> _roles = [];
  List<dynamic> _datosReporte = [];
  bool _tieneDatos = false;
  bool _isLoadingSucursales = true;
  bool _isLoadingReporte = false;
  bool _isDownloadingPdf = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fechaDesde = DateTime(DateTime.now().year, 1, 1);
    _fechaHasta = DateTime.now();
    _reportsDataSource = ReportsRemoteDataSource(
      apiClient: context.read<ApiClient>(),
    );
    _loadSucursales();
  }

  bool get _tipoRequiereFechas {
    return _tiposReporte
        .firstWhere((t) => t.$1 == _tipoSeleccionado, orElse: () => ('', '', false))
        .$3;
  }

  Future<void> _loadSucursales() async {
    setState(() => _isLoadingSucursales = true);
    try {
      final sucursales = await _reportsDataSource.getSucursalesActivas();
      setState(() {
        _sucursales = sucursales;
        if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
          _sucursalSeleccionada = _sucursales.first;
        }
        _isLoadingSucursales = false;
      });
    } catch (_) {
      try {
        final sucursales = await _reportsDataSource.getSucursalesDisponibles();
        setState(() {
          _sucursales = sucursales;
          if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
            _sucursalSeleccionada = _sucursales.first;
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
              content: Text('Error al cargar sucursales: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _reportsDataSource.getRoles();
      setState(() => _roles = roles);
    } catch (_) {}
  }

  Future<void> _generarReporte() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipoRequiereFechas && (_fechaDesde == null || _fechaHasta == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las fechas son obligatorias para este tipo de reporte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingReporte = true;
      _error = null;
      _datosReporte = [];
      _tieneDatos = false;
    });

    try {
      final resultado = await _reportsDataSource.getReporteVistaPrevia(
        usuarioId: authState.user.id,
        tipo: _tipoSeleccionado,
        fechaDesde: _fechaDesde?.toIso8601String().split('T')[0],
        fechaHasta: _fechaHasta?.toIso8601String().split('T')[0],
        sucursalId: _sucursalSeleccionada?.id,
        rolId: _rolId,
        material: _material.isNotEmpty ? _material : null,
      );

      if (resultado['success'] == true) {
        setState(() {
          _datosReporte = resultado['datos'] as List<dynamic>? ?? [];
          _tieneDatos = resultado['tieneDatos'] == true;
          _isLoadingReporte = false;
        });
      } else {
        setState(() {
          _error = resultado['message'] as String? ?? 'Error desconocido';
          _isLoadingReporte = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingReporte = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _descargarPdf() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isDownloadingPdf = true);
    try {
      final path = await _reportsDataSource.downloadReportePdf(
        usuarioId: authState.user.id,
        tipo: _tipoSeleccionado,
        fechaDesde: _fechaDesde?.toIso8601String().split('T')[0],
        fechaHasta: _fechaHasta?.toIso8601String().split('T')[0],
        sucursalId: _sucursalSeleccionada?.id,
        rolId: _rolId,
        material: _material.isNotEmpty ? _material : null,
      );
      await OpenFile.open(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF descargado correctamente'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTipoDropdown(),
          const SizedBox(height: 16),
          if (_tipoRequiereFechas) ...[
            _buildFechasRow(),
            const SizedBox(height: 16),
          ],
          _buildSucursalDropdown(),
          if (_tipoSeleccionado == 'usuarios') ...[
            const SizedBox(height: 16),
            _buildRolDropdown(),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isLoadingReporte ? null : _generarReporte,
            icon: _isLoadingReporte
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isLoadingReporte ? 'Cargando...' : 'Generar reporte'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (_error != null) const SizedBox(height: 16),
          if (_datosReporte.isNotEmpty || _tieneDatos == false) ...[
            Text(
              'Resultado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildResultado(),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de reporte *'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _tipoSeleccionado,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: _tiposReporte
              .map((t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(t.$2),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _tipoSeleccionado = v;
                if (v == 'usuarios') _loadRoles();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFechasRow() {
    final format = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fecha desde *'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fechaDesde ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _fechaDesde = d);
                },
                child: Text(_fechaDesde != null
                    ? format.format(_fechaDesde!)
                    : 'Seleccionar'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fecha hasta *'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fechaHasta ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _fechaHasta = d);
                },
                child: Text(_fechaHasta != null
                    ? format.format(_fechaHasta!)
                    : 'Seleccionar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSucursalDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sucursal (opcional)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<SucursalModel>(
          value: _sucursalSeleccionada,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: const Text('Todas las sucursales'),
          items: [
            const DropdownMenuItem<SucursalModel>(
              value: null,
              child: Text('Todas las sucursales'),
            ),
            ..._sucursales.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.nombre),
                )),
          ],
          onChanged: _isLoadingSucursales
              ? null
              : (v) => setState(() => _sucursalSeleccionada = v),
        ),
      ],
    );
  }

  Widget _buildRolDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rol (opcional)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _rolId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: const Text('Todos los roles'),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Todos los roles'),
            ),
            ..._roles.map((r) => DropdownMenuItem(
                  value: r['id'] as int?,
                  child: Text(r['nombre'] as String? ?? ''),
                )),
          ],
          onChanged: (v) => setState(() => _rolId = v),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    if (_datosReporte.isEmpty && !_tieneDatos) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay datos disponibles para este reporte',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    final firstRow = _datosReporte.isNotEmpty && _datosReporte.first is Map
        ? (_datosReporte.first as Map).keys.toList()
        : <String>[];

    return Card(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: firstRow.map((k) => DataColumn(label: Text(k.toString()))).toList(),
              rows: _datosReporte.take(100).map((d) {
                final m = d is Map ? d as Map : <String, dynamic>{};
                return DataRow(
                  cells: firstRow
                      .map((k) => DataCell(Text('${m[k] ?? ''}'.toString())))
                      .toList(),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _isDownloadingPdf ? null : _descargarPdf,
                  icon: _isDownloadingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf, size: 20),
                  label: Text(_isDownloadingPdf ? 'Descargando...' : 'Exportar PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
