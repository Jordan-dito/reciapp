import 'dart:io';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/api_exceptions.dart';
import '../models/sucursal_model.dart';
import '../models/categoria_porcentaje_model.dart';
import '../models/sucursal_gastos_compras_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource({required this.apiClient});

  /// Obtiene la lista de sucursales disponibles
  /// NOTA: Según la documentación, este endpoint NO requiere autenticación
  Future<List<SucursalModel>> getSucursalesDisponibles() async {
    try {
      print('📡 [ReportsDataSource] Obteniendo sucursales disponibles...');
      print(
          '🌐 URL: ${apiClient.baseUrl}${AppConfig.sucursalesEndpoint}?action=disponibles');
      print(
          'ℹ️ [ReportsDataSource] Este endpoint NO requiere autenticación según documentación');

      // Hacer la petición sin token de autenticación (según documentación)
      final response = await apiClient.get(
        AppConfig.sucursalesEndpoint,
        queryParams: {'action': 'disponibles'},
      );

      print('📥 [ReportsDataSource] Respuesta recibida:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Data: ${response.data}');

      if (!response.success) {
        final message = response.error ?? 'Error al obtener sucursales';
        print('❌ [ReportsDataSource] Error en respuesta: $message');
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        final List<dynamic> sucursalesJson = response.data!['data'] ?? [];
        print(
            '✅ [ReportsDataSource] Sucursales encontradas: ${sucursalesJson.length}');

        final sucursales =
            sucursalesJson.map((json) => SucursalModel.fromJson(json)).toList();

        // Log detallado de cada sucursal
        for (var i = 0; i < sucursales.length; i++) {
          final s = sucursales[i];
          print(
              '   ${i + 1}. ID: ${s.id}, Nombre: ${s.nombre}, Estado: ${s.estado}');
        }

        return sucursales;
      } else {
        final message = response.data!['message'] as String? ??
            'Error al obtener sucursales';
        print('❌ [ReportsDataSource] Error en data: $message');
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
      print('📡 [ReportsDataSource] Obteniendo porcentajes de categorías...');
      print(
          '🌐 URL: ${apiClient.baseUrl}${AppConfig.porcentajesCategoriasEndpoint}');
      print('📋 Parámetros:');
      print('   - Año: $anio');
      print('   - Mes: $mes');
      print('   - Sucursal ID: ${sucursalId ?? "Todas"}');

      // Según MENSAJE_FLUTTER.md, el body debe ser JSON con números (int), no strings
      final body = <String, dynamic>{
        'anio': anio, // Enviar como int, no como string
        'mes': mes, // Enviar como int, no como string
      };

      if (sucursalId != null) {
        body['sucursal_id'] = sucursalId; // Enviar como int, no como string
      }

      print('📦 Body enviado (JSON con números): $body');
      print(
          'ℹ️ [ReportsDataSource] Este endpoint NO requiere autenticación según MENSAJE_FLUTTER.md');

      // Según MENSAJE_FLUTTER.md:
      // - NO requiere autenticación
      // - Debe enviarse como JSON (Content-Type: application/json)
      // - Los valores deben ser números (int), no strings
      final response = await apiClient.post(
        AppConfig.porcentajesCategoriasEndpoint,
        body: body,
        useFormData: false, // Enviar como JSON según documentación
      );

      print('📥 [ReportsDataSource] Respuesta recibida:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Data completo: ${response.data}');

      if (!response.success) {
        final message =
            response.error ?? 'Error al obtener porcentajes de categorías';
        print('❌ [ReportsDataSource] Error en respuesta: $message');
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        final List<dynamic> categoriasJson = response.data!['categorias'] ?? [];
        print(
            '✅ [ReportsDataSource] Categorías encontradas: ${categoriasJson.length}');

        final totalCantidad =
            (response.data!['total_cantidad'] as num?)?.toDouble() ?? 0.0;
        print('📊 [ReportsDataSource] Total cantidad: $totalCantidad kg');

        final categorias = categoriasJson
            .map((json) => CategoriaPorcentajeModel.fromJson(json))
            .toList();

        // Log detallado de cada categoría
        print('📋 [ReportsDataSource] Detalle de categorías:');
        for (var i = 0; i < categorias.length; i++) {
          final cat = categorias[i];
          print('   ${i + 1}. ${cat.categoriaNombre}:');
          print('      - ID: ${cat.categoriaId}');
          print('      - Cantidad: ${cat.cantidad} kg');
          print('      - Porcentaje: ${cat.porcentaje}%');
        }

        final filtros = response.data!['filtros'] ?? {};
        print('🔍 [ReportsDataSource] Filtros aplicados: $filtros');

        return {
          'categorias': categorias,
          'total_cantidad': totalCantidad,
          'filtros': filtros,
        };
      } else {
        final message = response.data!['message'] as String? ??
            'Error al obtener porcentajes de categorías';
        print('❌ [ReportsDataSource] Error en data: $message');
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

  /// Obtiene gastos, compras, ventas y ganancias por sucursal
  /// Si no se especifica sucursal, devuelve todas las sucursales para el mes/año opcional
  Future<List<SucursalGastosComprasModel>> getGastosComprasPorSucursal({
    String? mes,
    String? anio,
    int? sucursalId,
  }) async {
    try {
      print('📡 [ReportsDataSource] Obteniendo gastos/compras por sucursal...');

      final queryParams = <String, dynamic>{'action': 'gastos_compras_por_sucursal'};
      if (mes != null && mes.isNotEmpty) queryParams['mes'] = mes;
      if (anio != null && anio.isNotEmpty) queryParams['anio'] = anio;
      if (sucursalId != null) queryParams['sucursal_id'] = sucursalId;

      final response = await apiClient.get(
        AppConfig.graficosEndpoint,
        queryParams: queryParams,
      );

      print('📥 [ReportsDataSource] Respuesta recibida: success=${response.success}, status=${response.statusCode}');

      if (!response.success) {
        final message = response.error ?? 'Error al obtener datos de graficos por sucursal';
        print('❌ [ReportsDataSource] Error en respuesta: $message');
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        final List<dynamic> list = response.data!['data'] ?? [];
        print('✅ [ReportsDataSource] Items encontrados: ${list.length}');

        final items = list
            .map((json) => SucursalGastosComprasModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return items;
      } else {
        final message = response.data!['message'] as String? ?? 'Error al obtener datos de graficos por sucursal';
        print('❌ [ReportsDataSource] Error en data: $message');
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

  /// Obtiene sucursales activas (para filtro de reportes)
  Future<List<SucursalModel>> getSucursalesActivas() async {
    final response = await apiClient.get(
      AppConfig.sucursalesEndpoint,
      queryParams: {'action': 'activas'},
    );
    if (!response.success) {
      throw ConnectionException(response.error ?? 'Error al obtener sucursales');
    }
    if (response.data!['success'] != true) {
      throw ConnectionException(
        response.data!['message'] as String? ?? 'Error al obtener sucursales',
      );
    }
    final list = response.data!['data'] as List<dynamic>? ?? [];
    return list.map((j) => SucursalModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Obtiene vista previa del reporte según FLUTTER_REPORTES_API.md
  Future<Map<String, dynamic>> getReporteVistaPrevia({
    required int usuarioId,
    required String tipo,
    String? fechaDesde,
    String? fechaHasta,
    int? sucursalId,
    int? rolId,
    String? material,
  }) async {
    final params = <String, String>{
      'action': 'vista_previa',
      'tipo': tipo,
      'usuario_id': usuarioId.toString(),
    };
    if (fechaDesde != null && fechaDesde.isNotEmpty) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) params['fecha_hasta'] = fechaHasta;
    if (sucursalId != null) params['sucursal_id'] = sucursalId.toString();
    if (rolId != null) params['rol_id'] = rolId.toString();
    if (material != null && material.isNotEmpty) params['material'] = material;

    final response = await apiClient.get(
      AppConfig.reportesApiEndpoint,
      queryParams: params,
    );

    if (!response.success) {
      throw ConnectionException(response.error ?? 'Error al obtener reporte');
    }
    if (response.data == null) {
      throw ConnectionException('Respuesta inválida del servidor');
    }
    return response.data!;
  }

  /// Obtiene lista de roles (para reporte de usuarios)
  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await apiClient.get(AppConfig.rolesEndpoint);
    if (!response.success) {
      return [];
    }
    if (response.data!['success'] != true) {
      return [];
    }
    final list = response.data!['data'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Descarga el reporte en PDF y devuelve la ruta al archivo
  Future<String> downloadReportePdf({
    required int usuarioId,
    required String tipo,
    String? fechaDesde,
    String? fechaHasta,
    int? sucursalId,
    int? rolId,
    String? material,
  }) async {
    final params = <String, String>{
      'tipo': tipo,
      'usuario_id': usuarioId.toString(),
    };
    if (fechaDesde != null && fechaDesde.isNotEmpty) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) params['fecha_hasta'] = fechaHasta;
    if (sucursalId != null) params['sucursal_id'] = sucursalId.toString();
    if (rolId != null) params['rol_id'] = rolId.toString();
    if (material != null && material.isNotEmpty) params['material'] = material;

    final uri = Uri.parse('${apiClient.baseUrl}${AppConfig.reportesPdfEndpoint}')
        .replace(queryParameters: params);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw ConnectionException(
        'Error al descargar PDF: ${response.statusCode}',
      );
    }
    final dir = await getTemporaryDirectory();
    final fileName = 'reporte_${tipo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
