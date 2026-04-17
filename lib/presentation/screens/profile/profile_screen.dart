import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Funcionalidad de cambiar foto pendiente
  // final ProfileImageService _profileImageService = ProfileImageService();

  // TODO: Al implementar cambio de foto, solicitar permisos primero:
  // await PermissionService.requestMediaPermissions() antes de ImagePicker.pickImage
  // Ver: lib/core/services/permission_service.dart

  @override
  void initState() {
    super.initState();
    // Refrescar los datos del usuario cuando se muestra la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const RefreshUserEvent());
      // Cerrar cualquier SnackBar que pueda estar abierto de otras pantallas
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {},
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Avatar con foto desde el endpoint
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: user.fotoPerfil == null
                            ? AppTheme.primaryGreen
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: user.fotoPerfil != null &&
                              user.fotoPerfil!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user.fotoPerfil!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                // Agregar cache buster para forzar actualización
                                cacheWidth: 120,
                                cacheHeight: 120,
                                // Forzar recarga de la imagen usando el ID del usuario y la URL
                                key: ValueKey(
                                    'profile_${user.id}_${user.fotoPerfil}'),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.primaryGreen,
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.white,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.white,
                            ),
                    ),
                    const SizedBox(height: 24),
                    // Nombre
                    Text(
                      user.nombre,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.rol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Información del usuario
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: user.email,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
