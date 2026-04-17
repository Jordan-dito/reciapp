import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Cargar variables de entorno desde el asset .env (obligatorio en release)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e, st) {
    try {
      final raw = await rootBundle.loadString('.env');
      dotenv.testLoad(fileInput: raw);
    } catch (_) {
      debugPrint('Error cargando .env: $e\n$st');
      rethrow;
    }
  }

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
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  GoRouter? _router;
  bool _splashRemoved = false;
  bool _routerInitialized = false;
  bool _startupFlowScheduled = false;

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
      _router = AppRouter.createRouter(
        context,
        navigatorKey: _rootNavigatorKey,
      );
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
          builder: (scopedContext) {
            _initializeRouter(scopedContext);

            if (!_startupFlowScheduled) {
              _startupFlowScheduled = true;
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _runStartupFlow(scopedContext);
              });
            }

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

  Future<void> _runStartupFlow(BuildContext scopedContext) async {
    if (!mounted || _splashRemoved) return;

    final connectivityService = ConnectivityService();
    final hasConnection = await connectivityService.hasInternetConnection();

    if (!mounted || !scopedContext.mounted) return;

    if (!hasConnection) {
      FlutterNativeSplash.remove();
      _splashRemoved = true;

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || !scopedContext.mounted) return;

      final dialogContext = _rootNavigatorKey.currentContext;
      if (dialogContext == null) return;

      showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
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
                Navigator.of(dialogContext).pop();
                scopedContext.read<AuthBloc>().add(const CheckAuthStatusEvent());
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!mounted || !scopedContext.mounted) return;
                  final authState = scopedContext.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    _router?.go(AppConfig.homeRoute);
                  } else {
                    _router?.go(AppConfig.loginRoute);
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

    scopedContext.read<AuthBloc>().add(const CheckAuthStatusEvent());

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || !scopedContext.mounted) return;

    FlutterNativeSplash.remove();
    _splashRemoved = true;

    final authState = scopedContext.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _router?.go(AppConfig.homeRoute);
    } else {
      _router?.go(AppConfig.loginRoute);
    }
  }
}
