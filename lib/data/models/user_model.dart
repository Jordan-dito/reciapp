import '../../domain/entities/user.dart';
import '../../core/config/app_config.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nombre,
    required super.email,
    required super.rol,
    required super.rolId,
    super.token,
    super.cedula,
    super.telefono,
    super.fotoPerfil,
  });

  /// Crea un UserModel desde el JSON de respuesta del endpoint de login
  /// El endpoint devuelve: { "success": true, "usuario": { "id": 1, "nombre": "...", "email": "...", "rol": "...", "foto_perfil": "..." } }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Manejar rol_id de forma segura (puede no venir en respuestas antiguas)
    int parseRolId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    // Manejar foto_perfil - puede ser null o string vacío
    // Normaliza la URL reemplazando localhost con el dominio real
    String? parseFotoPerfil(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      if (str.isEmpty) return null;
      
      // Si la URL ya es completa y no contiene localhost, retornarla tal cual
      if (str.startsWith('http://') || str.startsWith('https://')) {
        if (!str.contains('localhost') && !str.contains('127.0.0.1')) {
          print('✅ URL de foto ya es completa: $str');
          return str;
        }
      }
      
      // Normalizar la URL para usar el dominio real en lugar de localhost
      final normalized = AppConfig.normalizeImageUrl(str);
      print('🔄 URL normalizada: $str -> $normalized');
      return normalized;
    }

    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      rolId: parseRolId(json['rol_id']),
      token: json['token'] as String?,
      cedula: json['cedula'] as String?,
      telefono: json['telefono'] as String?,
      fotoPerfil: parseFotoPerfil(json['foto_perfil']),
    );
  }

  /// Crea un UserModel desde la respuesta completa del endpoint de login
  /// Útil cuando recibes: { "success": true, "usuario": { ... } }
  factory UserModel.fromLoginResponse(Map<String, dynamic> response) {
    if (response['usuario'] != null) {
      return UserModel.fromJson(response['usuario'] as Map<String, dynamic>);
    }
    throw Exception('Usuario no encontrado en la respuesta');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'rol_id': rolId,
      if (token != null) 'token': token,
      if (cedula != null) 'cedula': cedula,
      if (telefono != null) 'telefono': telefono,
      if (fotoPerfil != null) 'foto_perfil': fotoPerfil,
    };
  }

  UserModel copyWith({
    int? id,
    String? nombre,
    String? email,
    String? rol,
    int? rolId,
    String? token,
    String? cedula,
    String? telefono,
    String? fotoPerfil,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      rolId: rolId ?? this.rolId,
      token: token ?? this.token,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }
}

