import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fijo_model.dart';
import '../repositories/fijo_repository.dart';

final fijoRepositoryProvider = Provider((ref) => FijoRepository());

final fijosProvider = StateNotifierProvider<FijosNotifier, AsyncValue<List<FijoModel>>>((ref) {
  return FijosNotifier(ref.read(fijoRepositoryProvider));
});

class FijosNotifier extends StateNotifier<AsyncValue<List<FijoModel>>> {
  FijosNotifier(this._repo) : super(const AsyncValue.loading()) {
    cargar();
  }

  final FijoRepository _repo;

  Future<void> cargar() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.obtenerTodos();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> agregar(FijoModel fijo) async {
    await _repo.insertar(fijo);
    await cargar();
  }

  Future<void> actualizar(FijoModel fijo) async {
    await _repo.actualizar(fijo);
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminar(id);
    await cargar();
  }
}