import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_data.dart';
import '../services/presupuesto_service.dart';
import '../services/dashboard_service.dart';
import 'config_provider.dart';
import 'gastos_provider.dart';
import 'fijos_provider.dart';
import 'categorias_provider.dart';

final mesSeleccionadoProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dashboardProvider = FutureProvider.autoDispose.family<DashboardData, DateTime>((ref, mes) async {
  final configRepo = ref.read(configRepositoryProvider);
  final gastoRepo = ref.read(gastoRepositoryProvider);
  final fijoRepo = ref.read(fijoRepositoryProvider);
  final catRepo = ref.read(categoriaRepositoryProvider);

  final tipo = await configRepo.obtener('tipo_presupuesto', 'Mensual');
  final inicio = await configRepo.obtener('inicio_semana', 'Lunes');
  final modo = await configRepo.obtener('modo_semanas', 'Dinámico');
  final salario = await configRepo.obtenerSalario();
  final ahorroStr = await configRepo.obtener('meta_ahorro', '0');
  final ahorro = double.tryParse(ahorroStr) ?? 0.0;

  final fijos = await fijoRepo.obtenerTodos();
  final fijosSum = fijos.fold(0.0, (sum, item) => sum + item.monto);

  final variables = await gastoRepo.obtenerPorMes(mes);
  final categorias = await catRepo.obtenerTodos();

  double debitoSum = 0;
  double creditoSum = 0;
  Map<int, List<Map<String, dynamic>>> gruposSemanas = {};

  for (var g in variables) {
    double m = g.monto;
    if (g.metodoPago == 'Crédito') {
      creditoSum += m;
    } else {
      debitoSum += m;
    }

    int numeroSemana = DashboardService.obtenerSemanaDelMes(g.fecha, inicio, modo);
    gruposSemanas.putIfAbsent(numeroSemana, () => []);
    gruposSemanas[numeroSemana]!.add(g.toMap());
  }

  int totalSemanas = DashboardService.obtenerTotalSemanasDelMes(mes, inicio, modo);
  double disponibleParaSemanas = salario - fijosSum - ahorro;
  double presupuestoBasePorSemana = totalSemanas > 0 ? disponibleParaSemanas / totalSemanas : 0;

  final gruposSemanasProcesados = PresupuestoService.calcularCuotasFantasma(
    gruposSemanas: gruposSemanas,
    totalSemanas: totalSemanas,
    presupuestoBasePorSemana: presupuestoBasePorSemana,
  );

  Map<int, double> presupuestosCalculados = {};
  Map<int, double> restantesCalculados = {};
  double deficitParaSiguienteSemana = 0;

  for (int w = 1; w <= totalSemanas; w++) {
    double presupuestoAsignadoW = presupuestoBasePorSemana - deficitParaSiguienteSemana;
    presupuestosCalculados[w] = presupuestoAsignadoW;

    List<Map<String, dynamic>> gastosDeEstaSemana = gruposSemanasProcesados[w] ?? [];
    double totalGastosW = gastosDeEstaSemana.fold(0.0, (sum, item) => sum + (item['monto_calculado'] as num).toDouble());
    double restanteW = presupuestoAsignadoW - totalGastosW;
    restantesCalculados[w] = restanteW;

    if (restanteW < 0) {
      deficitParaSiguienteSemana = restanteW.abs();
    } else {
      deficitParaSiguienteSemana = 0;
    }
  }

  int semanaActualReal = 1;
  final ahora = DateTime.now();
  if (mes.month == ahora.month && mes.year == ahora.year) {
    semanaActualReal = DashboardService.obtenerSemanaDelMes(ahora, inicio, modo);
  }

  return DashboardData(
    tipoPresupuesto: tipo,
    salario: salario,
    totalFijos: fijosSum,
    totalDebito: debitoSum,
    totalCredito: creditoSum,
    ahorro: ahorro,
    totalSemanasMes: totalSemanas,
    semanaActualReal: semanaActualReal,
    presupuestosSemanales: presupuestosCalculados,
    restantesSemanales: restantesCalculados,
    gastosPorSemana: gruposSemanasProcesados,
    gastosRecientes: variables.map((g) => g.toMap()).toList(),
    categoriasDisponibles: categorias.map((c) => c.toMap()).toList(),
  );
});