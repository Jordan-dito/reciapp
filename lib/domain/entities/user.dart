import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? token;
  final String? cedula;
  final String? telefono;
  final int rolId;
  final String? fotoPerfil; // URL completa de la foto de perfil

  const User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.rolId,
    this.token,
    this.cedula,
    this.telefono,
    this.fotoPerfil,
  });

  @override
  List<Object?> get props => [id, nombre, email, rol, rolId, token, cedula, telefono, fotoPerfil];
}

