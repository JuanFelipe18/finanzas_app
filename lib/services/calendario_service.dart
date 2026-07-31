class CalendarioService {
  static int obtenerTotalSemanasDelMes(DateTime mes, String inicio, String modo) {
    if (modo == 'Fijo 5') return 5;
    DateTime ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    return obtenerSemanaDelMes(ultimoDia, inicio, modo);
  }

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
}