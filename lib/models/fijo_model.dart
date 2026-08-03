class FijoModel {
  final int? id;
  final String descripcion;
  final double monto;
  final String icono;
  final int? fechaPago;        // Día del mes (1-31) o null
  final int recordatorioDias;  // Cuántos días antes avisar
  final int recordatorioActivo; // 0 = no, 1 = sí

  FijoModel({
    this.id,
    required this.descripcion,
    required this.monto,
    this.icono = '🔒',
    this.fechaPago,
    this.recordatorioDias = 0,
    this.recordatorioActivo = 0,
  });

  factory FijoModel.fromMap(Map<String, dynamic> map) {
    return FijoModel(
      id: map['id'] as int?,
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      icono: map['icono'] as String? ?? '🔒',
      fechaPago: map['fecha_pago'] as int?,
      recordatorioDias: map['recordatorio_dias'] as int? ?? 0,
      recordatorioActivo: map['recordatorio_activo'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'icono': icono,
      'fecha_pago': fechaPago,
      'recordatorio_dias': recordatorioDias,
      'recordatorio_activo': recordatorioActivo,
    };
  }

  FijoModel copyWith({
    int? id,
    String? descripcion,
    double? monto,
    String? icono,
    int? fechaPago,
    int? recordatorioDias,
    int? recordatorioActivo,
  }) {
    return FijoModel(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      icono: icono ?? this.icono,
      fechaPago: fechaPago ?? this.fechaPago,
      recordatorioDias: recordatorioDias ?? this.recordatorioDias,
      recordatorioActivo: recordatorioActivo ?? this.recordatorioActivo,
    );
  }

  bool get tieneRecordatorio => recordatorioActivo == 1 && fechaPago != null;
}