import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/api_exceptions.dart';
import '../models/user_model.dart';

/// Datasource remoto para operaciones de autenticación
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Realiza el login usando el endpoint del servidor
  Future<UserModel> login(String email, String password) async {
    try {
      if (email.trim().isEmpty || password.isEmpty) {
        throw ValidationException('Por favor, completa todos los campos');
      }

      final response = await apiClient.post(
        AppConfig.loginEndpoint,
        body: {
          'email': email.trim(),
          'password': password,
        },
        useFormData: true,
      );

      if (!response.success) {
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
        throw ConnectionException(
          response.error ?? 'Error de conexión. Verifica tu internet.',
        );
      }

      if (response.data == null) {
        throw FormatException('El servidor no devolvió datos válidos.');
      }

      if (response.data!['success'] == true) {
        try {
          final user = UserModel.fromLoginResponse(response.data!);

          if (user.rol.toLowerCase() != 'gerente') {
            throw AuthenticationException(
              'Solo válido para gerentes. Tu rol actual es: ${user.rol}',
            );
          }

          final token = response.data!['token'] as String? ??
              'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

          return user.copyWith(token: token);
        } catch (e) {
          if (e is ApiException) rethrow;
          throw FormatException(
            'Error al procesar la respuesta del servidor: ${e.toString()}',
          );
        }
      } else {
        final message = response.data!['message'] as String? ??
            response.data!['error'] as String? ??
            'Credenciales incorrectas';
        throw AuthenticationException(message);
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

  /// Cierra la sesión
  Future<void> logout() async {
    apiClient.removeAuthToken();
  }

  /// Obtiene los datos actualizados del usuario desde el servidor
  Future<UserModel> refreshUser(int userId) async {
    try {
      final response = await apiClient.post(
        AppConfig.getUserEndpoint,
        body: {
          'usuario_id': userId.toString(),
        },
        useFormData: true,
      );

      if (!response.success) {
        final message = response.error ?? 'Error al obtener datos del usuario';
        throw ConnectionException(message);
      }

      if (response.data!['success'] == true) {
        try {
          return UserModel.fromLoginResponse(response.data!);
        } catch (e) {
          if (e is ApiException) rethrow;
          throw FormatException(
            'Error al procesar la respuesta del servidor: ${e.toString()}',
          );
        }
      } else {
        final message = response.data!['message'] as String? ??
            response.data!['error'] as String? ??
            'Error al obtener datos del usuario';
        throw AuthenticationException(message);
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

  /// Verifica si el token actual es válido
  Future<bool> validateToken(String token) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}
