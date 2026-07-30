class PresupuestoService {
  /// Recibe los gastos agrupados y devuelve el mapa procesado con las "cuotas fantasma"
  static Map<int, List<Map<String, dynamic>>> calcularCuotasFantasma({
    required Map<int, List<Map<String, dynamic>>> gruposSemanas,
    required int totalSemanas,
    required double presupuestoBasePorSemana,
  }) {
    double umbralGranGasto = presupuestoBasePorSemana * 0.40;
    Map<int, List<Map<String, dynamic>>> gruposSemanasProcesados = {};
    
    // Inicializar mapa
    for(int w = 1; w <= totalSemanas; w++) {
      gruposSemanasProcesados[w] = [];
    }

    for (int w = 1; w <= totalSemanas; w++) {
      List<Map<String, dynamic>> gastosOriginales = gruposSemanas[w] ?? [];
      
      for(var g in gastosOriginales) {
        double m = (g['monto'] as num).toDouble();
        
        // Si superó el 40% y NO estamos en la última semana del mes
        if (m >= umbralGranGasto && w < totalSemanas) {
          int semanasRestantes = totalSemanas - w + 1;
          double cuota = m / semanasRestantes;
          
          // Re-escribimos el gasto original para mostrar solo su cuota
          Map<String, dynamic> gastoPrincipal = Map.from(g);
          gastoPrincipal['monto_calculado'] = cuota;
          gastoPrincipal['desc_visual'] = '${g['descripcion']} (1/$semanasRestantes)';
          gruposSemanasProcesados[w]!.add(gastoPrincipal);
          
          // Clonamos "fantasmas" hacia el futuro
          for(int futura = w + 1; futura <= totalSemanas; futura++) {
            Map<String, dynamic> fantasma = Map.from(g);
            fantasma['monto_calculado'] = cuota;
            int numCuota = futura - w + 1;
            fantasma['desc_visual'] = '${g['descripcion']} ($numCuota/$semanasRestantes)';
            fantasma['es_fantasma'] = true; // Etiqueta secreta
            gruposSemanasProcesados[futura]!.add(fantasma);
          }
        } else {
          // Si es un gasto normal
          Map<String, dynamic> normal = Map.from(g);
          normal['monto_calculado'] = m;
          normal['desc_visual'] = g['descripcion'];
          gruposSemanasProcesados[w]!.add(normal);
        }
      }
    }
    
    return gruposSemanasProcesados;
  }
}