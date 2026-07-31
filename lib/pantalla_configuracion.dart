import 'package:flutter/material.dart';
import 'database.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  bool _presupuestoCategorias = false;
  String _tipoPresupuesto = 'Mensual';
  String _modoSemanas = 'Dinámico';
  String _inicioSemana = 'Lunes';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    String tipo = await DatabaseHelper.obtenerTipoPresupuesto();
    String modo = await DatabaseHelper.obtenerConfiguracion('modo_semanas', 'Dinámico');
    String inicio = await DatabaseHelper.obtenerConfiguracion('inicio_semana', 'Lunes');
    String presupCat = await DatabaseHelper.obtenerConfiguracion('presupuesto_categorias', 'false');

    setState(() {
      _tipoPresupuesto = tipo;
      _modoSemanas = modo;
      _inicioSemana = inicio;
      _presupuestoCategorias = presupCat == 'true';
    });
  }

  Future<void> _cargarDatosPrueba() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Cargar datos de prueba'),
        content: const Text(
          'Esto insertará:\n'
          '• Salario: \$4.000.000\n'
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

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Datos de prueba cargados. Reinicia la app para ver todo.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  DropdownButton<String>(
                    value: _tipoPresupuesto,
                    items: ['Mensual', 'Semanal']
                        .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                        .toList(),
                    onChanged: (String? nuevoValor) async {
                      if (nuevoValor != null) {
                        setState(() => _tipoPresupuesto = nuevoValor);
                        await DatabaseHelper.guardarTipoPresupuesto(nuevoValor);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Presupuesto por Categorías
          Card(
            child: SwitchListTile(
              title: const Text('Presupuesto por Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Asignar límites a cada tipo de gasto'),
              activeThumbColor: Colors.green,
              value: _presupuestoCategorias,
              onChanged: (bool valor) async {
                setState(() => _presupuestoCategorias = valor);
                await DatabaseHelper.guardarConfiguracion('presupuesto_categorias', valor.toString());
              },
            ),
          ),

          // Configuraciones semanales
          if (_tipoPresupuesto == 'Semanal') ...[
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
                          await DatabaseHelper.guardarConfiguracion('modo_semanas', val);
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
                          await DatabaseHelper.guardarConfiguracion('inicio_semana', val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

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
              onTap: _cargarDatosPrueba,
            ),
          ),
        ],
      ),
    );
  }
}