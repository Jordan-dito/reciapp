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
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email y contraseña son requeridos');
    }

    if (!email.contains('@')) {
      throw Exception('Por favor ingresa un email válido');
    }

    try {
      final user = await remoteDataSource.login(email, password);
      await localDataSource.saveUser(user);

      if (user.token != null) {
        remoteDataSource.apiClient.setAuthToken(user.token!);
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Continuar con el logout local incluso si falla el remoto
    } finally {
      remoteDataSource.apiClient.removeAuthToken();
      await localDataSource.clearUser();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final user = await localDataSource.getUser();

    if (user != null && user.token != null) {
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
      final currentUser = await localDataSource.getUser();
      if (currentUser == null) {
        throw Exception('Usuario no encontrado. Por favor, inicia sesión nuevamente.');
      }

      final updatedUser = await remoteDataSource.refreshUser(currentUser.id);
      await localDataSource.saveUser(updatedUser);

      if (updatedUser.token != null) {
        remoteDataSource.apiClient.setAuthToken(updatedUser.token!);
      }

      return updatedUser;
    } catch (e) {
      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        return localUser;
      }
      rethrow;
    }
  }
}
