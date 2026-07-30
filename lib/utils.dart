class AppUtils {
  // Centraliza la lógica de capitalización
  static String capitalizarTexto(String texto) {
    if (texto.isEmpty) return texto;

    return texto.trim().split(' ').map((palabra) {
      if (palabra.isEmpty) return '';
      return '${palabra[0].toUpperCase()}${palabra.substring(1).toLowerCase()}';
    }).join(' ');
  }

  // Centraliza el formato de moneda para que los separadores de miles sean consistentes en toda la app
  static String formatearMoneda(double cantidad) {
    return cantidad.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }
}