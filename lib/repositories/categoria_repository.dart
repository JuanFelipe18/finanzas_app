import '../database.dart';
import '../models/categoria_model.dart';

class CategoriaRepository {
  Future<List<CategoriaModel>> obtenerTodos() async {
    await DatabaseHelper.inicializarCategorias();
    final raw = await DatabaseHelper.obtenerCategorias();
    return raw.map((m) => CategoriaModel.fromMap(m)).toList();
  }

  Future<void> insertar(CategoriaModel cat) async {
    await DatabaseHelper.insertarCategoria(cat.nombre, cat.icono, cat.presupuesto);
  }

  Future<void> actualizar(CategoriaModel cat) async {
    if (cat.id == null) throw ArgumentError('Categoría sin ID no se puede actualizar');
    await DatabaseHelper.actualizarCategoria(cat.id!, cat.nombre, cat.icono, cat.presupuesto);
  }

  Future<void> eliminar(int id) async {
    await DatabaseHelper.eliminarCategoria(id);
  }
}