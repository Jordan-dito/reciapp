import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/api_exceptions.dart';
import '../models/user_model.dart';

/// Datasource remoto para operaciones de autenticación
/// Maneja todas las llamadas HTTP relacionadas con autenticación
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Realiza el login usando el endpoint del servidor
  /// 
  /// [email] - Email del usuario
  /// [password] - Contraseña del usuario
  /// 
  /// Retorna un [UserModel] si el login es exitoso
  /// Lanza una [Exception] si hay un error
  Future<UserModel> login(String email, String password) async {
    try {
      // Validar que los campos no estén vacíos antes de enviar
      if (email.trim().isEmpty || password.isEmpty) {
        throw ValidationException('Por favor, completa todos los campos');
      }
      
      print('🔐 Intentando login con email: $email');
      print('🌐 URL: ${apiClient.baseUrl}${AppConfig.loginEndpoint}');
      
      // Enviar como form-data para compatibilidad con backends PHP
      final response = await apiClient.post(
        AppConfig.loginEndpoint,
        body: {
          'email': email.trim(),
          'password': password,
        },
        useFormData: true, // Usar form-urlencoded para PHP
      );
      
      print('📡 Respuesta recibida - success: ${response.success}, statusCode: ${response.statusCode}');

      // Si hay un error en la respuesta HTTP
      if (!response.success) {
        // Si es un error de status code (401, 404, 500, etc.)
        if (response.statusCode != null) {
          if (response.statusCode == 401) {
            throw AuthenticationException(
              response.error ?? 'Credenciales incorrectas. Verifica tu email y contraseña.',
            );
          }
          throw ApiErrorException.fromStatusCode(
            response.statusCode!,
            response.error,
          );
        }
        // Si es un error de conexión
        throw ConnectionException(
          response.error ?? 'Error de conexión. Verifica tu internet.',
        );
      }

      // Si la respuesta es exitosa pero no tiene data
      if (response.data == null) {
        print('❌ Error: response.data es null');
        throw FormatException('El servidor no devolvió datos válidos.');
      }

      print('✅ response.data: ${response.data}');

      // Verificar que la respuesta tenga success: true
      if (response.data!['success'] == true) {
        print('✅ success es true, procesando usuario...');
        try {
          // Crear el usuario desde la respuesta
          final user = UserModel.fromLoginResponse(response.data!);
          print('✅ Usuario creado: ${user.nombre}, Rol: ${user.rol}');
          
          // Validar que solo los gerentes puedan acceder
          if (user.rol.toLowerCase() != 'gerente') {
            print('❌ Rol no es gerente: ${user.rol}');
            throw AuthenticationException(
              'Solo válido para gerentes. Tu rol actual es: ${user.rol}',
            );
          }
          
          print('✅ Rol válido (gerente)');
          
          // Si el servidor devuelve un token, usarlo; si no, generar uno local
          final token = response.data!['token'] as String? ??
                       'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
          
          final userWithToken = user.copyWith(token: token);
          print('✅ Usuario con token creado, retornando...');
          
          return userWithToken;
        } catch (e) {
          // Si ya es una ApiException, re-lanzarla
          if (e is ApiException) {
            rethrow;
          }
          throw FormatException(
            'Error al procesar la respuesta del servidor: ${e.toString()}',
          );
        }
      } else {
        // El servidor devolvió success: false
        final message = response.data!['message'] as String? ?? 
                       response.data!['error'] as String? ??
                       'Credenciales incorrectas';
        throw AuthenticationException(message);
      }
    } on ApiException {
      // Re-lanzar excepciones de API sin modificar
      rethrow;
    } catch (e) {
      // Convertir otros errores en ConnectionException
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

  /// Cierra la sesión en el servidor (si es necesario)
  /// Por ahora solo limpia el token local
  Future<void> logout() async {
    // Si tu backend tiene un endpoint de logout, puedes llamarlo aquí:
    // await apiClient.post('/config/logout.php');
    
    // Por ahora solo removemos el token del cliente
    apiClient.removeAuthToken();
  }

  /// Obtiene los datos actualizados del usuario desde el servidor
  /// Usa el endpoint /config/get_user.php para obtener datos frescos
  Future<UserModel> refreshUser(int userId) async {
    try {
      print('🔄 Refrescando datos del usuario ID: $userId');
      print('🌐 URL: ${apiClient.baseUrl}${AppConfig.getUserEndpoint}');
      
      // Hacer petición POST con el ID del usuario
      final response = await apiClient.post(
        AppConfig.getUserEndpoint,
        body: {
          'usuario_id': userId.toString(),
        },
        useFormData: true, // Usar form-urlencoded para PHP
      );
      
      print('📡 Respuesta recibida - success: ${response.success}, statusCode: ${response.statusCode}');

      // Si hay un error en la respuesta HTTP
      if (!response.success) {
        final message = response.error ?? 'Error al obtener datos del usuario';
        throw ConnectionException(message);
      }

      // Verificar que la respuesta tenga success: true
      if (response.data!['success'] == true) {
        print('✅ success es true, procesando usuario...');
        try {
          // Crear el usuario desde la respuesta
          final user = UserModel.fromLoginResponse(response.data!);
          print('✅ Usuario refrescado: ${user.nombre}, Foto: ${user.fotoPerfil}');
          
          return user;
        } catch (e) {
          // Si ya es una ApiException, re-lanzarla
          if (e is ApiException) {
            rethrow;
          }
          throw FormatException(
            'Error al procesar la respuesta del servidor: ${e.toString()}',
          );
        }
      } else {
        // El servidor devolvió success: false
        final message = response.data!['message'] as String? ?? 
                       response.data!['error'] as String? ??
                       'Error al obtener datos del usuario';
        throw AuthenticationException(message);
      }
    } on ApiException {
      // Re-lanzar excepciones de API sin modificar
      rethrow;
    } catch (e) {
      // Convertir otros errores en ConnectionException
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

  /// Verifica si el token actual es válido
  /// Útil para mantener la sesión activa
  Future<bool> validateToken(String token) async {
    try {
      // Si tu backend tiene un endpoint de validación, puedes usarlo aquí:
      // final response = await apiClient.get('/config/validate_token.php');
      // return response.success;
      
      // Por ahora retornamos true (implementar según tu backend)
      return true;
    } catch (e) {
      return false;
    }
  }
}

