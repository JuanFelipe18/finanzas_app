class GastoModel {
  final int? id;
  final String descripcion;
  final double monto;
  final String categoria;
  final String metodoPago;
  final String tipoMovimiento;
  final int cuotas;
  final DateTime fecha;

  GastoModel({
    this.id,
    required this.descripcion,
    required this.monto,
    this.categoria = 'Otros',
    this.metodoPago = 'Débito',
    this.tipoMovimiento = 'Gasto',
    this.cuotas = 1,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  factory GastoModel.fromMap(Map<String, dynamic> map) {
    return GastoModel(
      id: map['id'] as int?,
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      categoria: map['categoria'] as String? ?? 'Otros',
      metodoPago: map['metodo_pago'] as String? ?? 'Débito',
      tipoMovimiento: map['tipo'] as String? ?? 'Gasto',
      cuotas: map['cuotas'] as int? ?? 1,
      fecha: map['fecha'] != null
          ? DateTime.tryParse(map['fecha'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'categoria': categoria,
      'metodo_pago': metodoPago,
      'tipo': tipoMovimiento,
      'cuotas': cuotas,
      'fecha': fecha.toIso8601String(),
    };
  }

  GastoModel copyWith({
    int? id,
    String? descripcion,
    double? monto,
    String? categoria,
    String? metodoPago,
    String? tipoMovimiento,
    int? cuotas,
    DateTime? fecha,
  }) {
    return GastoModel(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      metodoPago: metodoPago ?? this.metodoPago,
      tipoMovimiento: tipoMovimiento ?? this.tipoMovimiento,
      cuotas: cuotas ?? this.cuotas,
      fecha: fecha ?? this.fecha,
    );
  }
}