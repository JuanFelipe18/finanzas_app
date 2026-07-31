import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gasto_model.dart';
import '../repositories/gasto_repository.dart';

final gastoRepositoryProvider = Provider((ref) => GastoRepository());

final gastosProvider = FutureProvider.autoDispose<List<GastoModel>>((ref) async {
  final repo = ref.watch(gastoRepositoryProvider);
  return repo.obtenerTodos();
});

final gastosPorMesProvider = FutureProvider.autoDispose.family<List<GastoModel>, DateTime>((ref, mes) async {
  final repo = ref.watch(gastoRepositoryProvider);
  return repo.obtenerPorMes(mes);
});