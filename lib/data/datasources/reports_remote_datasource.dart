import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/api_exceptions.dart';
import '../models/sucursal_model.dart';
import '../models/categoria_porcentaje_model.dart';
import '../models/sucursal_gastos_compras_model.dart';

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource({required this.apiClient});

  /// Obtiene la lista de sucursales disponibles
  /// NOTA: Según la documentación, este endpoint NO requiere autenticación
  Future<List<SucursalModel>> getSucursalesDisponibles() async {
    try {
      final response = await apiClient.get(
        AppConfig.sucursalesEndpoint,
        queryParams: {'action': 'disponibles'},
      );

      if (!response.success) {
        final message = response.error ?? 'Error al obtener sucursales';
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        final List<dynamic> sucursalesJson = response.data!['data'] ?? [];
        return sucursalesJson.map((json) => SucursalModel.fromJson(json)).toList();
      } else {
        final message = response.data!['message'] as String? ?? 'Error al obtener sucursales';
        throw ConnectionException(message);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException(
        'Error inesperado: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Obtiene los porcentajes de categorías por sucursal, mes y año
  Future<Map<String, dynamic>> getPorcentajesCategorias({
    required int anio,
    required int mes,
    int? sucursalId,
  }) async {
    try {
      final body = <String, dynamic>{
        'anio': anio,
        'mes': mes,
      };

      if (sucursalId != null) {
        body['sucursal_id'] = sucursalId;
      }

      final response = await apiClient.post(
        AppConfig.porcentajesCategoriasEndpoint,
        body: body,
        useFormData: false,
      );

      if (!response.success) {
        final message = response.error ?? 'Error al obtener porcentajes de categorías';
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        final List<dynamic> categoriasJson = response.data!['categorias'] ?? [];
        final totalCantidad =
            (response.data!['total_cantidad'] as num?)?.toDouble() ?? 0.0;
        final categorias = categoriasJson
            .map((json) => CategoriaPorcentajeModel.fromJson(json))
            .toList();
        final filtros = response.data!['filtros'] ?? {};

        return {
          'categorias': categorias,
          'total_cantidad': totalCantidad,
          'filtros': filtros,
        };
      } else {
        final message = response.data!['message'] as String? ??
            'Error al obtener porcentajes de categorías';
        throw ConnectionException(message);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException(
        'Error inesperado: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Obtiene sucursales activas (alias de getSucursalesDisponibles con action=activas)
  Future<List<SucursalModel>> getSucursalesActivas() async {
    try {
      final response = await apiClient.get(
        AppConfig.sucursalesEndpoint,
        queryParams: {'action': 'activas'},
      );
      if (!response.success) {
        throw ConnectionException(response.error ?? 'Error al obtener sucursales activas');
      }
      if (response.data!['success'] == true) {
        final List<dynamic> list = response.data!['data'] ?? [];
        return list.map((json) => SucursalModel.fromJson(json)).toList();
      }
      throw ConnectionException(
        response.data!['message'] as String? ?? 'Error al obtener sucursales activas',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException('Error inesperado: ${e.toString()}', originalError: e);
    }
  }

  /// Obtiene los roles disponibles
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await apiClient.get(AppConfig.rolesEndpoint);
      if (!response.success) {
        throw ConnectionException(response.error ?? 'Error al obtener roles');
      }
      if (response.data!['success'] == true) {
        final List<dynamic> list = response.data!['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw ConnectionException(
        response.data!['message'] as String? ?? 'Error al obtener roles',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException('Error inesperado: ${e.toString()}', originalError: e);
    }
  }

  /// Obtiene vista previa del reporte (datos tabulares)
  Future<Map<String, dynamic>> getReporteVistaPrevia({
    required int usuarioId,
    required String tipo,
    String? fechaDesde,
    String? fechaHasta,
    int? sucursalId,
    int? rolId,
    String? material,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'vista_previa',
        'usuario_id': usuarioId,
        'tipo': tipo,
      };
      if (fechaDesde != null) body['fecha_desde'] = fechaDesde;
      if (fechaHasta != null) body['fecha_hasta'] = fechaHasta;
      if (sucursalId != null) body['sucursal_id'] = sucursalId;
      if (rolId != null) body['rol_id'] = rolId;
      if (material != null) body['material'] = material;

      final response = await apiClient.post(
        AppConfig.reportesApiEndpoint,
        body: body,
        useFormData: false,
      );

      if (!response.success) {
        throw ConnectionException(response.error ?? 'Error al obtener vista previa');
      }
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException('Error inesperado: ${e.toString()}', originalError: e);
    }
  }

  /// Descarga el reporte en PDF y lo guarda en un archivo temporal
  Future<File> downloadReportePdf({
    required int usuarioId,
    required String tipo,
    String? fechaDesde,
    String? fechaHasta,
    int? sucursalId,
    int? rolId,
    String? material,
  }) async {
    try {
      final uri = Uri.parse('${apiClient.baseUrl}${AppConfig.reportesApiEndpoint}');
      final body = <String, dynamic>{
        'action': 'descargar_pdf',
        'usuario_id': usuarioId.toString(),
        'tipo': tipo,
      };
      if (fechaDesde != null) body['fecha_desde'] = fechaDesde;
      if (fechaHasta != null) body['fecha_hasta'] = fechaHasta;
      if (sucursalId != null) body['sucursal_id'] = sucursalId.toString();
      if (rolId != null) body['rol_id'] = rolId.toString();
      if (material != null) body['material'] = material;

      final formData = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final headers = Map<String, String>.from(apiClient.defaultHeaders);
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      final response = await http.post(
        uri,
        headers: headers,
        body: formData,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ConnectionException('Error al descargar PDF: ${response.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_$tipo.pdf');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException('Error inesperado: ${e.toString()}', originalError: e);
    }
  }

  /// Obtiene gastos, compras, ventas y ganancias por sucursal
  Future<List<SucursalGastosComprasModel>> getGastosComprasPorSucursal({
    String? mes,
    String? anio,
    int? sucursalId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'action': 'gastos_compras_por_sucursal'};
      if (mes != null && mes.isNotEmpty) queryParams['mes'] = mes;
      if (anio != null && anio.isNotEmpty) queryParams['anio'] = anio;
      if (sucursalId != null) queryParams['sucursal_id'] = sucursalId;

      final response = await apiClient.get(
        AppConfig.graficosEndpoint,
        queryParams: queryParams,
      );

      if (!response.success) {
        final message = response.error ?? 'Error al obtener datos de graficos por sucursal';
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        final List<dynamic> list = response.data!['data'] ?? [];
        return list
            .map((json) => SucursalGastosComprasModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final message = response.data!['message'] as String? ?? 'Error al obtener datos de graficos por sucursal';
        throw ConnectionException(message);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup') ||
          e.toString().toLowerCase().contains('timeout')) {
        throw ConnectionException.fromError(e);
      }
      throw ConnectionException(
        'Error inesperado: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
