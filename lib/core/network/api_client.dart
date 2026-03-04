import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/api_exceptions.dart';

/// Cliente HTTP base para todas las llamadas a la API
/// Estructurado para ser fácilmente extensible con más endpoints
class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient({
    required this.baseUrl,
    Map<String, String>? headers,
  }) : defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        };

  /// Realiza una petición GET
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      
      // Añadir query parameters si existen
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }

      final response = await http.get(
        uri,
        headers: {...defaultHeaders, ...?headers},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La petición tardó demasiado. Verifica tu conexión.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      // Convertir errores de conexión en excepciones específicas
      if (e is TimeoutException) {
        return ApiResponse.error('El servidor tardó demasiado en responder. Verifica tu conexión.');
      }
      if (e is http.ClientException || 
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup')) {
        final connectionError = ConnectionException.fromError(e);
        return ApiResponse.error(connectionError.message);
      }
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Realiza una petición POST
  /// 
  /// [useFormData] - Si es true, envía los datos como form-urlencoded en lugar de JSON
  /// Útil para backends PHP que esperan datos de formulario
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Object? bodyJson,
    bool useFormData = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      Map<String, String> requestHeaders = {...defaultHeaders, ...?headers};
      Object? requestBody;
      
      if (bodyJson != null) {
        requestBody = bodyJson;
      } else if (body != null) {
        if (useFormData) {
          // Enviar como form-urlencoded para backends PHP
          // Convertir a String con formato application/x-www-form-urlencoded
          final formDataPairs = body.entries.map((e) => 
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}'
          ).join('&');
          requestBody = formDataPairs;
          requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
        } else {
          // Enviar como JSON
          requestBody = jsonEncode(body);
        }
      }
      
      print('📤 Enviando POST a: $uri');
      print('📦 Headers: $requestHeaders');
      print('📦 Body: $requestBody');
      
      final response = await http.post(
        uri,
        headers: requestHeaders,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Timeout después de 30 segundos');
          throw TimeoutException('La petición tardó demasiado. Verifica tu conexión.');
        },
      );
      
      print('📥 Respuesta recibida - Status: ${response.statusCode}, Body length: ${response.body.length}');

      return _handleResponse(response);
    } catch (e) {
      // Convertir errores de conexión en excepciones específicas
      if (e is TimeoutException) {
        return ApiResponse.error('El servidor tardó demasiado en responder. Verifica tu conexión.');
      }
      if (e is http.ClientException || 
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup')) {
        final connectionError = ConnectionException.fromError(e);
        return ApiResponse.error(connectionError.message);
      }
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Realiza una petición PUT
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Object? bodyJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.put(
        uri,
        headers: {...defaultHeaders, ...?headers},
        body: bodyJson ?? (body != null ? jsonEncode(body) : null),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La petición tardó demasiado. Verifica tu conexión.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      // Convertir errores de conexión en excepciones específicas
      if (e is TimeoutException) {
        return ApiResponse.error('El servidor tardó demasiado en responder. Verifica tu conexión.');
      }
      if (e is http.ClientException || 
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup')) {
        final connectionError = ConnectionException.fromError(e);
        return ApiResponse.error(connectionError.message);
      }
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Realiza una petición DELETE
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.delete(
        uri,
        headers: {...defaultHeaders, ...?headers},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La petición tardó demasiado. Verifica tu conexión.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      // Convertir errores de conexión en excepciones específicas
      if (e is TimeoutException) {
        return ApiResponse.error('El servidor tardó demasiado en responder. Verifica tu conexión.');
      }
      if (e is http.ClientException || 
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('failed host lookup')) {
        final connectionError = ConnectionException.fromError(e);
        return ApiResponse.error(connectionError.message);
      }
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  /// Maneja la respuesta HTTP y la convierte en ApiResponse
  ApiResponse _handleResponse(http.Response response) {
    print('📋 _handleResponse - Status: ${response.statusCode}, Body: ${response.body}');
    
    // Si el status code indica error, manejar según el código
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('❌ Status code de error: ${response.statusCode}');
      try {
        // Intentar parsear como JSON para obtener el mensaje de error
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final message = data['message'] as String? ?? 
                         data['error'] as String? ??
                         'Error ${response.statusCode}: ${response.reasonPhrase}';
        return ApiResponse.error(message, statusCode: response.statusCode);
      } catch (e) {
        // Si no es JSON válido, usar el mensaje del status code
        final apiError = ApiErrorException.fromStatusCode(
          response.statusCode,
          response.reasonPhrase,
        );
        return ApiResponse.error(apiError.message, statusCode: response.statusCode);
      }
    }
    
    // Status code exitoso (200-299)
    print('✅ Status code exitoso, parseando JSON...');
    try {
      // Intentar parsear como JSON
      if (response.body.isEmpty) {
        print('⚠️ Body vacío');
        return ApiResponse.success({}, statusCode: response.statusCode);
      }
      
      print('📄 Parseando body: ${response.body}');
      final data = jsonDecode(response.body);
      print('✅ JSON parseado: $data');
      
      // Si es un Map, devolverlo directamente
      if (data is Map<String, dynamic>) {
        print('✅ Es un Map, retornando success');
        return ApiResponse.success(data, statusCode: response.statusCode);
      }
      
      // Si es otro tipo, envolverlo en un Map
      print('⚠️ No es Map, envolviendo en data');
      return ApiResponse.success({'data': data}, statusCode: response.statusCode);
    } catch (e) {
      print('❌ Error parseando JSON: $e');
      // Si no es JSON válido pero el status es exitoso, devolver el body como texto
      return ApiResponse.success({'data': response.body}, statusCode: response.statusCode);
    }
  }

  /// Añade un token de autenticación a los headers por defecto
  void setAuthToken(String token) {
    defaultHeaders['Authorization'] = 'Bearer $token';
  }

  /// Elimina el token de autenticación
  void removeAuthToken() {
    defaultHeaders.remove('Authorization');
  }
}

/// Clase para manejar las respuestas de la API de forma consistente
class ApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(Map<String, dynamic> data, {int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  /// Obtiene un mensaje de la respuesta (útil para mostrar al usuario)
  String get message {
    if (success && data != null) {
      return data!['message'] as String? ?? '';
    }
    return error ?? 'Error desconocido';
  }
}

