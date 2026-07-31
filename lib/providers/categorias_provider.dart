import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/categoria_model.dart';
import '../repositories/categoria_repository.dart';

final categoriaRepositoryProvider = Provider((ref) => CategoriaRepository());

// Este provider se invalida automáticamente cuando cambia el estado
final categoriasProvider = StateNotifierProvider<CategoriasNotifier, AsyncValue<List<CategoriaModel>>>((ref) {
  return CategoriasNotifier(ref.read(categoriaRepositoryProvider));
});

class CategoriasNotifier extends StateNotifier<AsyncValue<List<CategoriaModel>>> {
  CategoriasNotifier(this._repo) : super(const AsyncValue.loading()) {
    cargar();
  }

  final CategoriaRepository _repo;

  Future<void> cargar() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.obtenerTodos();
      list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())); // <-- NUEVO
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> agregar(CategoriaModel cat) async {
    await _repo.insertar(cat);
    await cargar();
  }

  Future<void> actualizar(CategoriaModel cat) async {
    await _repo.actualizar(cat);
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminar(id);
    await cargar();
  }
}