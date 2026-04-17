import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_state.dart';
import '../config/app_config.dart';

class AppRouter {
  static GoRouter createRouter(
    BuildContext context, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    // Crear un StreamNotifier para escuchar cambios del AuthBloc
    final authStreamNotifier = _AuthStreamNotifier(context);

    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppConfig.loginRoute,
      refreshListenable: authStreamNotifier,
      routes: [
        GoRoute(
          path: AppConfig.loginRoute,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConfig.homeRoute,
          name: 'home',
          builder: (context, state) => const MainScreen(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        try {
          // Obtener el estado de autenticación del Bloc
          final authState = context.read<AuthBloc>().state;
          final isLoginRoute = state.matchedLocation == AppConfig.loginRoute;
          final isHomeRoute = state.matchedLocation == AppConfig.homeRoute;

          // Si está autenticado y está en login, redirigir a home
          if (authState is AuthAuthenticated && isLoginRoute) {
            return AppConfig.homeRoute;
          }

          // Si no está autenticado (o hay error) y está en home, redirigir a login
          if ((authState is AuthUnauthenticated ||
                  authState is AuthError ||
                  authState is AuthInitial) &&
              isHomeRoute) {
            return AppConfig.loginRoute;
          }

          // Si está en loading, no redirigir (dejar que termine)
          if (authState is AuthLoading) {
            return null;
          }

          return null;
        } catch (e) {
          // Si hay un error al leer el estado, ir al login
          return AppConfig.loginRoute;
        }
      },
    );
  }

  // Mantener una referencia estática para compatibilidad
  static GoRouter? _router;

  static GoRouter get router {
    if (_router == null) {
      throw StateError(
          'Router no inicializado. Usa AppRouter.createRouter(context) primero.');
    }
    return _router!;
  }

  static void setRouter(GoRouter router) {
    _router = router;
  }
}

/// StreamNotifier que escucha los cambios del AuthBloc y notifica al router
class _AuthStreamNotifier extends ChangeNotifier {
  final BuildContext context;
  StreamSubscription? _subscription;

  _AuthStreamNotifier(this.context) {
    // Escuchar los cambios del AuthBloc
    final authBloc = context.read<AuthBloc>();
    _subscription = authBloc.stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
