import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/config_repository.dart';

final configRepositoryProvider = Provider((ref) => ConfigRepository());

final salarioProvider = FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(configRepositoryProvider);
  return repo.obtenerSalario();
});

final tipoPresupuestoProvider = FutureProvider.autoDispose<String>((ref) async {
  final repo = ref.watch(configRepositoryProvider);
  return repo.obtener('tipo_presupuesto', 'Mensual');
});

final onboardingCompletoProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(configRepositoryProvider);
  return repo.esOnboardingCompleto();
});

final presupuestoCategoriasProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(configRepositoryProvider);
  final val = await repo.obtener('presupuesto_categorias', 'false');
  return val == 'true';
});