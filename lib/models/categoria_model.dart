class CategoriaModel {
  final int? id;
  final String nombre;
  final String icono;
  final double presupuesto;

  CategoriaModel({
    this.id,
    required this.nombre,
    this.icono = '📁',
    this.presupuesto = 0.0,
  });

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? 'Sin nombre',
      icono: map['icono'] as String? ?? '📁',
      presupuesto: (map['presupuesto'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'presupuesto': presupuesto,
    };
  }

  CategoriaModel copyWith({
    int? id,
    String? nombre,
    String? icono,
    double? presupuesto,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      presupuesto: presupuesto ?? this.presupuesto,
    );
  }
}