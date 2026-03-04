import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<User> login(String email, String password) async {
    // Validación básica
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email y contraseña son requeridos');
    }

    // Validar formato de email básico
    if (!email.contains('@')) {
      throw Exception('Por favor ingresa un email válido');
    }

    try {
      // Llamar al endpoint de login
      final user = await remoteDataSource.login(email, password);

      // Guardar el usuario localmente
      await localDataSource.saveUser(user);

      // Configurar el token en el cliente API para futuras peticiones
      if (user.token != null) {
        print('🔑 [AuthRepository] Configurando token en ApiClient');
        remoteDataSource.apiClient.setAuthToken(user.token!);
        print('✅ [AuthRepository] Token configurado exitosamente');
      } else {
        print('⚠️ [AuthRepository] Usuario no tiene token');
      }

      return user;
    } catch (e) {
      // Re-lanzar la excepción para que el BLoC la maneje
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Cerrar sesión en el servidor
      await remoteDataSource.logout();
    } catch (e) {
      // Continuar con el logout local incluso si falla el remoto
      // Esto asegura que el usuario pueda cerrar sesión localmente
      print('⚠️ [AuthRepository] Error al cerrar sesión en servidor: $e');
    } finally {
      // Remover el token del ApiClient
      print('🔑 [AuthRepository] Removiendo token del ApiClient');
      remoteDataSource.apiClient.removeAuthToken();
      
      // Limpiar datos locales
      await localDataSource.clearUser();
      print('✅ [AuthRepository] Logout completado');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final user = await localDataSource.getUser();
    
    // Si hay un usuario guardado, configurar el token en el ApiClient
    if (user != null && user.token != null) {
      print('🔑 [AuthRepository] Configurando token desde usuario guardado');
      remoteDataSource.apiClient.setAuthToken(user.token!);
    }
    
    return user;
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  @override
  Future<User> refreshUser() async {
    try {
      // Obtener el usuario actual para tener su ID
      final currentUser = await localDataSource.getUser();
      if (currentUser == null) {
        throw Exception('Usuario no encontrado. Por favor, inicia sesión nuevamente.');
      }

      // Obtener datos actualizados desde el servidor
      final updatedUser = await remoteDataSource.refreshUser(currentUser.id);

      // Guardar el usuario actualizado localmente
      await localDataSource.saveUser(updatedUser);

      // Configurar el token si existe
      if (updatedUser.token != null) {
        print('🔑 [AuthRepository] Configurando token después de refresh');
        remoteDataSource.apiClient.setAuthToken(updatedUser.token!);
      }

      return updatedUser;
    } catch (e) {
      // Si falla la actualización desde el servidor, retornar el usuario local
      // Esto asegura que la app siga funcionando aunque no haya conexión
      print('⚠️ Error al refrescar desde servidor: $e');
      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        return localUser;
      }
      rethrow;
    }
  }
}

