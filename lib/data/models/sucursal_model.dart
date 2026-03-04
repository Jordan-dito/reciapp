class SucursalModel {
  final int id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String estado;

  SucursalModel({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.email,
    required this.estado,
  });

  factory SucursalModel.fromJson(Map<String, dynamic> json) {
    return SucursalModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      estado: json['estado'] as String? ?? 'activa',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'estado': estado,
    };
  }
}

