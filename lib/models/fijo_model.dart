class FijoModel {
  final int? id;
  final String descripcion;
  final double monto;
  final String icono;

  FijoModel({
    this.id,
    required this.descripcion,
    required this.monto,
    this.icono = '🔒',
  });

  factory FijoModel.fromMap(Map<String, dynamic> map) {
    return FijoModel(
      id: map['id'] as int?,
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      icono: map['icono'] as String? ?? '🔒',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'icono': icono,
    };
  }

  FijoModel copyWith({
    int? id,
    String? descripcion,
    double? monto,
    String? icono,
  }) {
    return FijoModel(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      icono: icono ?? this.icono,
    );
  }
}