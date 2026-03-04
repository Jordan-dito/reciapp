/// Excepciones personalizadas para manejar diferentes tipos de errores de API
library;

/// Excepción base para errores de API
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

/// Error de conexión (sin internet, servidor no disponible, timeout)
class ConnectionException extends ApiException {
  ConnectionException(super.message, {super.originalError});

  factory ConnectionException.fromError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return ConnectionException(
        'No hay conexión a internet. Verifica tu conexión e intenta nuevamente.',
        originalError: error,
      );
    }
    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return ConnectionException(
        'El servidor tardó demasiado en responder. Intenta nuevamente.',
        originalError: error,
      );
    }
    
    if (errorString.contains('connection refused') ||
        errorString.contains('connection reset')) {
      return ConnectionException(
        'No se pudo conectar con el servidor. Verifica que el servidor esté disponible.',
        originalError: error,
      );
    }
    
    return ConnectionException(
      'Error de conexión: ${error.toString()}',
      originalError: error,
    );
  }
}

/// Error de API (404, 500, etc.)
class ApiErrorException extends ApiException {
  ApiErrorException(super.message, {super.statusCode, super.originalError});

  factory ApiErrorException.fromStatusCode(int statusCode, String? message) {
    switch (statusCode) {
      case 400:
        return ApiErrorException(
          message ?? 'Solicitud incorrecta. Verifica los datos enviados.',
          statusCode: statusCode,
        );
      case 401:
        return ApiErrorException(
          message ?? 'No autorizado. Verifica tus credenciales.',
          statusCode: statusCode,
        );
      case 403:
        return ApiErrorException(
          message ?? 'Acceso denegado. No tienes permisos para esta acción.',
          statusCode: statusCode,
        );
      case 404:
        return ApiErrorException(
          message ?? 'Recurso no encontrado. El endpoint no existe.',
          statusCode: statusCode,
        );
      case 500:
        return ApiErrorException(
          message ?? 'Error interno del servidor. Intenta más tarde.',
          statusCode: statusCode,
        );
      case 502:
        return ApiErrorException(
          message ?? 'Servidor no disponible temporalmente.',
          statusCode: statusCode,
        );
      case 503:
        return ApiErrorException(
          message ?? 'Servicio no disponible. El servidor está en mantenimiento.',
          statusCode: statusCode,
        );
      default:
        return ApiErrorException(
          message ?? 'Error del servidor ($statusCode).',
          statusCode: statusCode,
        );
    }
  }
}

/// Error de autenticación (credenciales incorrectas)
class AuthenticationException extends ApiException {
  AuthenticationException(super.message, {super.originalError});
}

/// Error de formato (JSON inválido, datos mal formateados)
class FormatException extends ApiException {
  FormatException(super.message, {super.originalError});
}

/// Error de validación (datos inválidos)
class ValidationException extends ApiException {
  ValidationException(super.message, {super.originalError});
}

