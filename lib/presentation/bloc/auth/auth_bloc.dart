import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/errors/api_exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
    on<LogoutEvent>(_onLogoutEvent);
    on<CheckAuthStatusEvent>(_onCheckAuthStatusEvent);
    on<RefreshUserEvent>(_onRefreshUserEvent);
  }

  Future<void> _onLoginEvent(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      // Usar el mensaje de la excepción directamente (ya está formateado)
      emit(AuthError(e.message));
    } on TimeoutException {
      emit(AuthError('El servidor tardó demasiado en responder. Verifica tu conexión.'));
    } catch (e) {
      // Para otros errores, limpiar el mensaje
      final errorMessage = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('Error: ', '')
          .replaceAll('TimeoutException: ', '');
      
      // Si el mensaje está vacío o es muy genérico, usar uno más amigable
      if (errorMessage.isEmpty || errorMessage == e.toString()) {
        emit(AuthError('Error al iniciar sesión. Verifica tu conexión e intenta nuevamente.'));
      } else {
        emit(AuthError(errorMessage));
      }
    }
  }

  Future<void> _onLogoutEvent(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatusEvent(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Emitir loading para indicar que se está verificando
    emit(const AuthLoading());
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      // Si hay un error al verificar el estado, asumir que no está autenticado
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onRefreshUserEvent(
    RefreshUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Obtener el usuario actualizado
      final user = await authRepository.refreshUser();
      emit(AuthAuthenticated(user));
    } catch (e) {
      // Si falla el refresh, mantener el estado actual
      // No emitir error para no interrumpir la experiencia del usuario
      print('⚠️ Error al refrescar usuario: $e');
    }
  }
}

