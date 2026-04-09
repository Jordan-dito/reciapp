import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Tests de integración contra el servidor de producción real.
/// Objetivo: detectar qué endpoints existen (200/401/403/500)
/// vs cuáles no existen (404).
///
/// Ejecutar con:
///   flutter test test/endpoint_integration_test.dart -v

const String _baseUrl = 'https://hermanosyanez.alwaysdata.net';

const _headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/// Retorna true si el endpoint existe (cualquier respuesta que no sea 404)
bool _existe(int statusCode) => statusCode != 404;

void _log(String endpoint, int status, String body) {
  final preview = body.length > 200 ? '${body.substring(0, 200)}...' : body;
  final icono = _existe(status) ? '✅' : '❌';
  // ignore: avoid_print
  print('\n$icono  $endpoint');
  // ignore: avoid_print
  print('   Status: $status');
  // ignore: avoid_print
  print('   Body:   $preview');
}

void main() {
  group('Endpoints - Existencia en servidor de producción', () {
    test('GET /sucursales/api.php?action=disponibles', () async {
      final uri = Uri.parse('$_baseUrl/sucursales/api.php')
          .replace(queryParameters: {'action': 'disponibles'});

      final res = await http.get(uri, headers: _headers);
      _log('/sucursales/api.php?action=disponibles', res.statusCode, res.body);

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });

    test('GET /sucursales/api.php?action=activas', () async {
      final uri = Uri.parse('$_baseUrl/sucursales/api.php')
          .replace(queryParameters: {'action': 'activas'});

      final res = await http.get(uri, headers: _headers);
      _log('/sucursales/api.php?action=activas', res.statusCode, res.body);

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });

    test('POST /config/porcentajes_categorias.php', () async {
      final uri = Uri.parse('$_baseUrl/config/porcentajes_categorias.php');
      final body = jsonEncode({'anio': 2025, 'mes': 1});

      final res = await http.post(uri, headers: _headers, body: body);
      _log('/config/porcentajes_categorias.php', res.statusCode, res.body);

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });

    test('GET /roles/api.php', () async {
      final uri = Uri.parse('$_baseUrl/roles/api.php');

      final res = await http.get(uri, headers: _headers);
      _log('/roles/api.php', res.statusCode, res.body);

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });

    test('GET /reportes/api_graficos.php?action=gastos_compras_por_sucursal',
        () async {
      final uri = Uri.parse('$_baseUrl/reportes/api_graficos.php').replace(
        queryParameters: {'action': 'gastos_compras_por_sucursal'},
      );

      final res = await http.get(uri, headers: _headers);
      _log(
        '/reportes/api_graficos.php?action=gastos_compras_por_sucursal',
        res.statusCode,
        res.body,
      );

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });

    test('POST /reportes/api.php (vista_previa)', () async {
      final uri = Uri.parse('$_baseUrl/reportes/api.php');
      final body = jsonEncode({
        'action': 'vista_previa',
        'usuario_id': 1,
        'tipo': 'compras',
      });

      final res = await http.post(uri, headers: _headers, body: body);
      _log('/reportes/api.php', res.statusCode, res.body);

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });

    test('POST /config/login.php', () async {
      final uri = Uri.parse('$_baseUrl/config/login.php');
      // Enviamos credenciales vacías: esperamos 200 con error de validación,
      // o 400/401 — cualquier cosa menos 404.
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'usuario=test&contrasena=test',
      );
      _log('/config/login.php', res.statusCode, res.body);

      expect(
        _existe(res.statusCode),
        isTrue,
        reason: 'Endpoint devolvió 404 — no existe en el servidor',
      );
    });
  });
}
