import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Verificar estado de autenticación después de un breve delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasNavigated) {
        // Verificar el estado actual primero
        final currentState = context.read<AuthBloc>().state;
        _handleAuthState(currentState);
        
        // Si aún está en estado inicial o loading, disparar el evento
        if (currentState is AuthInitial || currentState is AuthLoading) {
          context.read<AuthBloc>().add(const CheckAuthStatusEvent());
        }
      }
    });
    
    // Timeout de seguridad: si después de 5 segundos no ha navegado, ir al login
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go(AppConfig.loginRoute);
      }
    });
  }

  void _handleAuthState(AuthState state) {
    if (_hasNavigated) return;
    
    if (state is AuthAuthenticated) {
      _hasNavigated = true;
      context.go(AppConfig.homeRoute);
    } else if (state is AuthUnauthenticated || state is AuthError) {
      _hasNavigated = true;
      context.go(AppConfig.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar el estado actual cuando se construye el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasNavigated) {
        final currentState = context.read<AuthBloc>().state;
        _handleAuthState(currentState);
      }
    });
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _handleAuthState(state);
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de reciclaje
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 70,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recicladora App',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestión inteligente de reciclaje',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

