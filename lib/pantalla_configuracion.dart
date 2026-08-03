import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/config_repository.dart';
import 'providers/categorias_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/gastos_provider.dart';
import 'providers/config_provider.dart';
import 'providers/fijos_provider.dart';
import 'package:flutter/material.dart';
import 'database.dart';

class PantallaConfiguracion extends ConsumerWidget {
  const PantallaConfiguracion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipoAsync = ref.watch(tipoPresupuestoProvider);
    final presupCatAsync = ref.watch(presupuestoCategoriasProvider);
    final configRepo = ref.read(configRepositoryProvider);

    void invalidateDashboard() {
      final mes = ref.read(mesSeleccionadoProvider);
      ref.invalidate(dashboardProvider(mes));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Preferencias de la App',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),

          // Tipo de Presupuesto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipo de Presupuesto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Mensual o Semanal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  tipoAsync.when(
                    loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, _) => const Text('Error'),
                    data: (tipo) => DropdownButton<String>(
                      value: tipo,
                      items: ['Mensual', 'Semanal']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (String? nuevoValor) async {
                        if (nuevoValor != null) {
                          await configRepo.guardar('tipo_presupuesto', nuevoValor);
                          ref.invalidate(tipoPresupuestoProvider);
                          invalidateDashboard(); // <-- FIX: recarga el home
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Presupuesto por Categorías
          presupCatAsync.when(
            loading: () => const Card(child: ListTile(title: Text('Cargando...'))),
            error: (_, _) => const Card(child: ListTile(title: Text('Error'))),
            data: (presupCat) => Card(
              child: SwitchListTile(
                title: const Text('Presupuesto por Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Asignar límites a cada tipo de gasto'),
                activeThumbColor: Colors.green,
                value: presupCat,
                onChanged: (bool valor) async {
                  await configRepo.guardar('presupuesto_categorias', valor.toString());
                  ref.invalidate(presupuestoCategoriasProvider);
                  ref.invalidate(categoriasProvider); // <-- FIX: recarga categorías
                },
              ),
            ),
          ),

          // Configuraciones semanales
          tipoAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (tipo) {
              if (tipo != 'Semanal') return const SizedBox.shrink();
              return _ConfigSemanal(
                configRepo: configRepo,
                onChanged: invalidateDashboard, // <-- FIX: recarga al cambiar semana
              );
            },
          ),

          // --- BOTÓN DE DATOS DE PRUEBA ---
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.science, color: Colors.orange),
              title: const Text(
                'Cargar datos de prueba',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              subtitle: const Text('Inserta salario, fijos y gastos de ejemplo'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
              onTap: () => _cargarDatosPrueba(context, ref),
            ),
          ),
        ],
      ),
    );
  }

    Future<void> _cargarDatosPrueba(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Cargar datos de prueba'),
        content: const Text(
          'Esto insertará:\n'
          '• Salario: \$2.869.895\n'
          '• Meta ahorro: \$1.400.000\n'
          '• 8 gastos fijos\n'
          '• 12 gastos del mes actual\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cargar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await DatabaseHelper.cargarDatosPrueba();

    // FIX: Invalidar todos los providers para que se vean inmediatamente
    ref.invalidate(salarioProvider);
    ref.invalidate(metaAhorroProvider);
    ref.invalidate(fijosProvider);
    ref.invalidate(gastosProvider);
    ref.invalidate(categoriasProvider);
    ref.invalidate(dashboardProvider(DateTime.now()));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Datos cargados. Ve a Inicio o Análisis.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _ConfigSemanal extends StatefulWidget {
  final ConfigRepository configRepo;
  final VoidCallback onChanged; // <-- NUEVO

  const _ConfigSemanal({
    required this.configRepo,
    required this.onChanged, // <-- NUEVO
  });

  @override
  State<_ConfigSemanal> createState() => _ConfigSemanalState();
}

class _ConfigSemanalState extends State<_ConfigSemanal> {
  String _modoSemanas = 'Dinámico';
  String _inicioSemana = 'Lunes';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final modo = await widget.configRepo.obtener('modo_semanas', 'Dinámico');
    final inicio = await widget.configRepo.obtener('inicio_semana', 'Lunes');
    if (mounted) {
      setState(() {
        _modoSemanas = modo;
        _inicioSemana = inicio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Ajustes Semanales',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Distribución del Mes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('¿Cómo dividir el presupuesto base?', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _modoSemanas,
                  items: const [
                    DropdownMenuItem(value: 'Dinámico', child: Text('Dinámico (Semanas reales del mes)')),
                    DropdownMenuItem(value: 'Fijo 5', child: Text('Fijo (Siempre dividir en 5 semanas)')),
                  ],
                  onChanged: (String? val) async {
                    if (val != null) {
                      setState(() => _modoSemanas = val);
                      await widget.configRepo.guardar('modo_semanas', val);
                      widget.onChanged(); // <-- FIX: recarga dashboard
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inicio de la semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Día de corte', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                DropdownButton<String>(
                  value: _inicioSemana,
                  items: ['Lunes', 'Domingo']
                      .map((dia) => DropdownMenuItem(value: dia, child: Text(dia)))
                      .toList(),
                  onChanged: (String? val) async {
                    if (val != null) {
                      setState(() => _inicioSemana = val);
                      await widget.configRepo.guardar('inicio_semana', val);
                      widget.onChanged(); // <-- FIX: recarga dashboard
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}