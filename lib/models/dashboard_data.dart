class DashboardData {
  final String tipoPresupuesto;
  final double salario;
  final double totalFijos;
  final double totalDebito;
  final double totalCredito;
  final double ahorro;
  final int totalSemanasMes;
  final int semanaActualReal;
  final Map<int, double> presupuestosSemanales;
  final Map<int, double> restantesSemanales;
  final Map<int, List<Map<String, dynamic>>> gastosPorSemana;
  final List<Map<String, dynamic>> gastosRecientes;
  final List<Map<String, dynamic>> categoriasDisponibles;

  DashboardData({
    required this.tipoPresupuesto,
    required this.salario,
    required this.totalFijos,
    required this.totalDebito,
    required this.totalCredito,
    required this.ahorro,
    required this.totalSemanasMes,
    required this.semanaActualReal,
    required this.presupuestosSemanales,
    required this.restantesSemanales,
    required this.gastosPorSemana,
    required this.gastosRecientes,
    required this.categoriasDisponibles,
  });
}