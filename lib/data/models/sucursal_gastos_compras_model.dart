class SucursalGastosComprasModel {
  final int sucursalId;
  final String sucursalNombre;
  final double totalGasto;
  final double totalCompra;
  final double totalVenta;
  final double ganancia;

  SucursalGastosComprasModel({
    required this.sucursalId,
    required this.sucursalNombre,
    required this.totalGasto,
    required this.totalCompra,
    required this.totalVenta,
    required this.ganancia,
  });

  factory SucursalGastosComprasModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return SucursalGastosComprasModel(
      sucursalId: (json['sucursal_id'] as num?)?.toInt() ??
          int.tryParse(json['sucursal_id']?.toString() ?? '') ??
          0,
      sucursalNombre: json['sucursal_nombre']?.toString() ?? '',
      totalGasto: _toDouble(json['total_gasto']),
      totalCompra: _toDouble(json['total_compra']),
      totalVenta: _toDouble(json['total_venta']),
      ganancia: _toDouble(json['ganancia']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sucursal_id': sucursalId,
      'sucursal_nombre': sucursalNombre,
      'total_gasto': totalGasto,
      'total_compra': totalCompra,
      'total_venta': totalVenta,
      'ganancia': ganancia,
    };
  }
}
