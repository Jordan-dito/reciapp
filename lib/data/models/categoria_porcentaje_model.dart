class CategoriaPorcentajeModel {
  final int categoriaId;
  final String categoriaNombre;
  final double cantidad;
  final double porcentaje;

  CategoriaPorcentajeModel({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.cantidad,
    required this.porcentaje,
  });

  factory CategoriaPorcentajeModel.fromJson(Map<String, dynamic> json) {
    return CategoriaPorcentajeModel(
      categoriaId: json['categoria_id'] is int
          ? json['categoria_id']
          : int.parse(json['categoria_id'].toString()),
      categoriaNombre: json['categoria_nombre'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      porcentaje: (json['porcentaje'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria_id': categoriaId,
      'categoria_nombre': categoriaNombre,
      'cantidad': cantidad,
      'porcentaje': porcentaje,
    };
  }
}

