import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';

Future<void> main() async {
  // Mantener el splash nativo visible hasta que Flutter esté completamente listo
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  // Cargar variables de entorno desde el archivo .env
  await dotenv.load(fileName: '.env');

  // Inicializar formato de fecha para español
  await initializeDateFormatting('es', null);

  runApp(const RecicladoraApp());
}

class RecicladoraApp extends StatefulWidget {
  const RecicladoraApp({super.key});

  @override
  State<RecicladoraApp> createState() => _RecicladoraAppState();
}

class _RecicladoraAppState extends State<RecicladoraApp> {
  GoRouter? _router;
  bool _splashRemoved = false;
  bool _routerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Timeout de seguridad: remover el splash después de 3 segundos si no se ha removido
    Future.delayed(const Duration(seconds: 3), () {
      if (!_splashRemoved && mounted) {
        FlutterNativeSplash.remove();
        _splashRemoved = true;
      }
    });
  }

  void _initializeRouter(BuildContext context) {
    if (!_routerInitialized) {
      _router = AppRouter.createRouter(context);
      AppRouter.setRouter(_router!);
      _routerInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Cliente HTTP base - reutilizable para todos los endpoints
        RepositoryProvider<ApiClient>(
          create: (_) => ApiClient(baseUrl: AppConfig.baseUrl),
        ),
        // Datasource local para almacenamiento
        RepositoryProvider<AuthLocalDataSource>(
          create: (_) => AuthLocalDataSource(),
        ),
        // Datasource remoto para llamadas HTTP
        RepositoryProvider<AuthRemoteDataSource>(
          create: (context) => AuthRemoteDataSource(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        // Repositorio de autenticación
        RepositoryProvider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(
            localDataSource: context.read<AuthLocalDataSource>(),
            remoteDataSource: context.read<AuthRemoteDataSource>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            // Inicializar el router solo una vez
            _initializeRouter(context);

            // Verificar si hay una sesión guardada al iniciar la app
            Future.microtask(() async {
              if (mounted && !_splashRemoved) {
                // Verificar conectividad a internet
                final connectivityService = ConnectivityService();
                final hasConnection =
                    await connectivityService.hasInternetConnection();

                if (!hasConnection && mounted) {
                  // Mostrar diálogo de advertencia si no hay conexión
                  FlutterNativeSplash.remove();
                  _splashRemoved = true;

                  // Esperar a que el contexto esté disponible para mostrar el diálogo
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.wifi_off, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Sin conexión a internet'),
                          ],
                        ),
                        content: const Text(
                          'No se detectó conexión a internet. Algunas funciones de la aplicación pueden no estar disponibles.\n\n'
                          'Por favor, verifica tu conexión Wi-Fi o datos móviles.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Verificar el estado de autenticación guardado
                              context
                                  .read<AuthBloc>()
                                  .add(const CheckAuthStatusEvent());
                              // Navegar según el estado
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                if (mounted) {
                                  final authState =
                                      context.read<AuthBloc>().state;
                                  if (authState is AuthAuthenticated) {
                                    _router?.go(AppConfig.homeRoute);
                                  } else {
                                    _router?.go(AppConfig.loginRoute);
                                  }
                                }
                              });
                            },
                            child: const Text('Continuar'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                }

                // Verificar el estado de autenticación guardado
                context.read<AuthBloc>().add(const CheckAuthStatusEvent());

                // Esperar un momento para que se complete la verificación
                await Future.delayed(const Duration(milliseconds: 500));

                if (mounted) {
                  FlutterNativeSplash.remove();
                  _splashRemoved = true;

                  // El router redirigirá automáticamente según el estado de autenticación
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    _router?.go(AppConfig.homeRoute);
                  } else {
                    _router?.go(AppConfig.loginRoute);
                  }
                }
              }
            });

            // El redirect del router manejará la navegación automáticamente
            // Asegurarse de que el router esté inicializado
            if (_router == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: _router!,
            );
          },
        ),
      ),
    );
  }
}
