class DashboardService {
  static int obtenerSemanaDelMes(DateTime fecha, String inicioSemana, String modoSemanas) {
    DateTime primerDiaMes = DateTime(fecha.year, fecha.month, 1);
    int offset = 0;
    if (inicioSemana == 'Lunes') {
      offset = primerDiaMes.weekday - 1;
    } else {
      int diaDart = primerDiaMes.weekday == 7 ? 0 : primerDiaMes.weekday;
      offset = diaDart;
    }

    int diasTranscurridos = fecha.day + offset - 1;
    int semanaMatematica = (diasTranscurridos ~/ 7) + 1;

    if (modoSemanas == 'Fijo 5' && semanaMatematica > 5) {
      return 5;
    }
    return semanaMatematica;
  }

  static int obtenerTotalSemanasDelMes(DateTime mes, String inicio, String modo) {
    if (modo == 'Fijo 5') return 5;
    DateTime ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    return obtenerSemanaDelMes(ultimoDia, inicio, modo);
  }

  static String formatearFecha(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) fechaIso = DateTime.now().toIso8601String();
    try {
      DateTime date = DateTime.parse(fechaIso);
      String dia = date.day.toString().padLeft(2, '0');
      String mes = date.month.toString().padLeft(2, '0');
      return '$dia/$mes';
    } catch (e) {
      return fechaIso.split('T')[0];
    }
  }

  static String formatearVistaMoneda(double cantidad) {
    bool esNegativo = cantidad < 0;
    String numStr = cantidad.abs().toStringAsFixed(0);
    String formateado = numStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return esNegativo ? '-$formateado' : formateado;
  }
}