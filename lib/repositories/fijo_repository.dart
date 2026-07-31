import '../database.dart';
import '../models/fijo_model.dart';

class FijoRepository {
  Future<List<FijoModel>> obtenerTodos() async {
    final raw = await DatabaseHelper.obtenerFijos();
    return raw.map((m) => FijoModel.fromMap(m)).toList();
  }

  Future<void> insertar(FijoModel fijo) async {
    await DatabaseHelper.insertarFijo(
      fijo.descripcion,
      fijo.monto,
      icono: fijo.icono,
    );
  }

  Future<void> actualizar(FijoModel fijo) async {
    if (fijo.id == null) throw ArgumentError('Fijo sin ID no se puede actualizar');
    await DatabaseHelper.actualizarFijo(
      fijo.id!,
      fijo.descripcion,
      fijo.monto,
      icono: fijo.icono,
    );
  }

  Future<void> eliminar(int id) async {
    await DatabaseHelper.eliminarFijo(id);
  }
}