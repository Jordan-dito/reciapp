import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

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
  final String _material = '';

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
      final platform = Theme.of(context).platform;

      final result = await _reportsDataSource.downloadReportePdf(
        usuarioId: authState.user.id,
        tipo: _tipoSeleccionado,
        fechaDesde: _fechaDesde?.toIso8601String().split('T')[0],
        fechaHasta: _fechaHasta?.toIso8601String().split('T')[0],
        sucursalId: _sucursalSeleccionada?.id,
        rolId: _rolId,
        material: _material.isNotEmpty ? _material : null,
      );

      final isMobile = platform == TargetPlatform.android ||
          platform == TargetPlatform.iOS;
      if (isMobile) {
        // En móvil: usar share_plus para que el usuario guarde/comparta donde quiera
        // (Evita problemas de OpenFile con archivos en directorios de la app)
        // Usar XFile con path (no fromData) por compatibilidad en Android
        final xFile = XFile(
          result.path,
          mimeType: 'application/pdf',
          name: 'reporte_$_tipoSeleccionado.pdf',
        );
        await Share.shareXFiles(
          [xFile],
          text: 'Reporte $_tipoSeleccionado',
        );
      } else {
        await OpenFile.open(result.path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMobile
                  ? 'Abre el menú y elige "Guardar" o "Guardar en archivos" para conservar el PDF'
                  : 'PDF descargado correctamente',
            ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFiltrosCard(context),
          const SizedBox(height: 20),
          _buildGenerarButton(context),
          const SizedBox(height: 20),
          if (_error != null) _buildErrorCard(),
          if (_error != null) const SizedBox(height: 16),
          if (_datosReporte.isNotEmpty || _tieneDatos == false) ...[
            _buildResultadoSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltrosCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filtros del reporte',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  Widget _buildGenerarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isLoadingReporte ? null : _generarReporte,
        icon: _isLoadingReporte
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.white,
                ),
              )
            : const Icon(Icons.analytics_rounded, size: 22),
        label: Text(
          _isLoadingReporte ? 'Cargando...' : 'Generar reporte',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultado',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.black,
              ),
        ),
        const SizedBox(height: 16),
        _buildResultado(context),
      ],
    );
  }

  Widget _buildTipoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de reporte *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _tipoSeleccionado,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
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
              Text(
                'Fecha desde *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fechaDesde ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _fechaDesde = d);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: AppTheme.primaryGreen),
                      const SizedBox(width: 12),
                      Text(
                        _fechaDesde != null
                            ? format.format(_fechaDesde!)
                            : 'Seleccionar',
                        style: TextStyle(
                          fontSize: 14,
                          color: _fechaDesde != null
                              ? AppTheme.black
                              : AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha hasta *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fechaHasta ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _fechaHasta = d);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: AppTheme.primaryGreen),
                      const SizedBox(width: 12),
                      Text(
                        _fechaHasta != null
                            ? format.format(_fechaHasta!)
                            : 'Seleccionar',
                        style: TextStyle(
                          fontSize: 14,
                          color: _fechaHasta != null
                              ? AppTheme.black
                              : AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
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
        Text(
          'Sucursal (opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SucursalModel>(
          value: _sucursalSeleccionada,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
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
        Text(
          'Rol (opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _rolId,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
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

  Widget _buildResultado(BuildContext context) {
    if (_datosReporte.isEmpty && !_tieneDatos) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: AppTheme.lightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles para este reporte',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final firstRow = _datosReporte.isNotEmpty && _datosReporte.first is Map
        ? (_datosReporte.first as Map).keys.toList()
        : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTheme.backgroundGreen.withOpacity(0.8),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryDarkGreen,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.black,
              ),
              columnSpacing: 24,
              horizontalMargin: 20,
              columns: firstRow
                  .map((k) => DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            k.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkGreen,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
              rows: _datosReporte.take(100).map((d) {
                final m = d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
                return DataRow(
                  cells: firstRow
                      .map((k) => DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('${m[k] ?? ''}'.toString()),
                            ),
                          ))
                      .toList(),
                );
              }).toList(),
            ),
          ),
          _buildExportPdfSection(context),
        ],
      ),
    );
  }

  /// Sección destacada para exportar a PDF
  Widget _buildExportPdfSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryDarkGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Exportar reporte',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Descarga el reporte en formato PDF para compartir o archivar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _isDownloadingPdf ? null : _descargarPdf,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isDownloadingPdf)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    else
                      Icon(Icons.download_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _isDownloadingPdf ? 'Descargando...' : 'Descargar PDF',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
