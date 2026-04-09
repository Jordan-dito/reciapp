import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Recicladora App';
  static const String appVersion = '1.0.0';

  /// Obtiene la URL base del servidor según el entorno configurado en .env
  /// Lee ENVIRONMENT, BASE_URL_DEV y BASE_URL_PROD del archivo .env
  /// Solo usa el dominio configurado en .env, sin valores por defecto
  static String get baseUrl {
    final environment = dotenv.env['ENVIRONMENT'] ?? 'development';

    if (environment == 'production') {
      final url = dotenv.env['BASE_URL_PROD'];
      if (url == null || url.isEmpty) {
        throw Exception('BASE_URL_PROD no está configurado en el archivo .env. '
            'Por favor, configura tu dominio de producción.');
      }
      return url;
    } else {
      // Desarrollo
      final url = dotenv.env['BASE_URL_DEV'];
      if (url == null || url.isEmpty) {
        throw Exception('BASE_URL_DEV no está configurado en el archivo .env. '
            'Por favor, configura tu dominio de desarrollo.');
      }
      return url;
    }
  }

  /// Verifica si estamos en modo producción
  static bool get isProduction {
    final environment = dotenv.env['ENVIRONMENT'] ?? 'development';
    return environment == 'production';
  }

  // Endpoints de la API
  static const String loginEndpoint = '/config/login.php';
  static const String getUserEndpoint = '/config/get_user.php'; // Endpoint para obtener datos actualizados del usuario
  static const String sucursalesEndpoint = '/sucursales/api.php'; // Endpoint para obtener sucursales disponibles
  static const String porcentajesCategoriasEndpoint = '/config/porcentajes_categorias.php'; // Endpoint para obtener porcentajes de categorías
  static const String graficosEndpoint = '/reportes/api_graficos.php'; // Endpoint para gráficos por sucursal (action=gastos_compras_por_sucursal)
  static const String reportesApiEndpoint = '/reportes/api.php'; // Endpoint para reportes (vista previa y PDF)
  static const String rolesEndpoint = '/roles/api.php'; // Endpoint para obtener roles

  // Rutas de la app
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String reportsRoute = '/reports';

  // SharedPreferences keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String isLoggedInKey = 'is_logged_in';

  /// Normaliza una URL de imagen reemplazando localhost con el dominio real
  /// Si la URL contiene localhost, lo reemplaza con el baseUrl configurado
  /// Si la URL es relativa (empieza con /), la convierte en absoluta usando baseUrl
  static String? normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final trimmedUrl = url.trim();
    
    // Si es una URL relativa (empieza con /), construir URL completa
    if (trimmedUrl.startsWith('/')) {
      // Remover la barra inicial si baseUrl ya termina con /
      final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      return '$base$trimmedUrl';
    }

    // Si contiene localhost o 127.0.0.1, reemplazar con el dominio real
    if (trimmedUrl.contains('localhost') || trimmedUrl.contains('127.0.0.1')) {
      try {
        final originalUri = Uri.parse(trimmedUrl);
        final baseUri = Uri.parse(baseUrl);
        
        // Construir nueva URL con el dominio real (usar el mismo protocolo y puerto del baseUrl)
        final normalizedUri = Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: originalUri.path,
          query: originalUri.query.isNotEmpty ? originalUri.query : null,
          fragment: originalUri.fragment.isNotEmpty ? originalUri.fragment : null,
        );
        
        return normalizedUri.toString();
      } catch (e) {
        // Si falla el parseo, intentar reemplazo simple de strings
        try {
          final baseUri = Uri.parse(baseUrl);
          final host = baseUri.host.isNotEmpty ? baseUri.host : baseUrl;
          
          return trimmedUrl
              .replaceAll('http://localhost', baseUrl)
              .replaceAll('https://localhost', baseUrl)
              .replaceAll('localhost', host)
              .replaceAll('127.0.0.1', host);
        } catch (e2) {
          // Si todo falla, retornar la URL original
          return trimmedUrl;
        }
      }
    }

    // Si ya es una URL completa válida (sin localhost), retornarla tal cual
    return trimmedUrl;
  }
}
