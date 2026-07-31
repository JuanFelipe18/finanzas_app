import '../database.dart';
import '../models/gasto_model.dart';

class GastoRepository {
  Future<List<GastoModel>> obtenerTodos() async {
    final raw = await DatabaseHelper.obtenerGastos();
    return raw.map((m) => GastoModel.fromMap(m)).toList();
  }

  Future<List<GastoModel>> obtenerPorMes(DateTime mes) async {
    final raw = await DatabaseHelper.obtenerGastosPorMes(mes);
    return raw.map((m) => GastoModel.fromMap(m)).toList();
  }

  Future<void> insertar(GastoModel gasto) async {
    final database = await DatabaseHelper.db;
    await database.insert('gastos', {
      'descripcion': gasto.descripcion,
      'monto': gasto.monto,
      'categoria': gasto.categoria,
      'metodo_pago': gasto.metodoPago,
      'tipo': gasto.tipoMovimiento,
      'cuotas': gasto.cuotas,
      'fecha': gasto.fecha.toIso8601String(),
    });
  }

  Future<void> actualizar(GastoModel gasto) async {
    if (gasto.id == null) throw ArgumentError('Gasto sin ID no se puede actualizar');
    final database = await DatabaseHelper.db;
    await database.update(
      'gastos',
      {
        'descripcion': gasto.descripcion,
        'monto': gasto.monto,
        'categoria': gasto.categoria,
        'metodo_pago': gasto.metodoPago,
        'fecha': gasto.fecha.toIso8601String(),
        'tipo': gasto.tipoMovimiento,
        'cuotas': gasto.cuotas,
      },
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<void> eliminar(int id) async {
    await DatabaseHelper.eliminarGasto(id);
  }
}