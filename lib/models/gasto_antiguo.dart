class Gasto {
  String descripcion;
  double monto;
  String categoria;
  String metodoPago; 
  String tipoMovimiento; 
  int cuotas;

  Gasto({
    required this.descripcion,
    required this.monto,
    this.categoria = 'Otros',
    this.metodoPago = 'Débito',
    this.tipoMovimiento = 'Gasto',
    this.cuotas = 1,
  });
}

// Parser simple con regex
List<Gasto> parsearGastos(String texto) {
  final List<Gasto> gastos = [];
  final regex = RegExp(r'([a-záéíóúñ\s]+?)\s+(\d+(?:[.,]\d+)?)\s*k?', caseSensitive: false);
  
  final matches = regex.allMatches(texto.toLowerCase());
  for (final match in matches) {
    String desc = match.group(1)!.trim();
    String montoStr = match.group(2)!.replaceAll(',', '.');
    double monto = double.parse(montoStr);
    
    if (texto.toLowerCase().contains('${match.group(2)}k')) {
      monto *= 1000;
    }
    
    // El Regex siempre asume Gasto y 1 cuota
    gastos.add(Gasto(descripcion: desc, monto: monto));
  }
  return gastos;
}