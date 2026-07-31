import '../database.dart';

class ConfigRepository {
  Future<double> obtenerSalario() => DatabaseHelper.obtenerSalario();
  Future<void> guardarSalario(double monto) => DatabaseHelper.guardarSalario(monto);

  Future<String> obtener(String clave, String defecto) =>
      DatabaseHelper.obtenerConfiguracion(clave, defecto);

  Future<void> guardar(String clave, String valor) =>
      DatabaseHelper.guardarConfiguracion(clave, valor);

  Future<bool> esOnboardingCompleto() => DatabaseHelper.esOnboardingCompleto();
  Future<void> completarOnboarding() => DatabaseHelper.completarOnboarding();
}