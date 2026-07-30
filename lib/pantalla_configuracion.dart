import 'package:flutter/material.dart';
import 'database.dart'; // Asegúrate de que esta ruta sea correcta según dónde tengas tu archivo

// BLOQUE 1: El Widget (Inmutable)
class PantallaConfiguracion extends StatefulWidget {
  // Esto soluciona el error del "key"
  const PantallaConfiguracion({super.key});

  // Esto soluciona el error de "createState" missing
  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

// BLOQUE 2: El Estado (Mutable, aquí van tus variables)
// Esto soluciona el error de "@immutable"
class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  bool _presupuestoCategorias = false;
  String _tipoPresupuesto = 'Mensual';
  String _modoSemanas = 'Dinámico'; // 'Dinámico' o 'Fijo 5'
  String _inicioSemana = 'Lunes'; // 'Lunes' o 'Domingo'

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
    // En tu setState:
    _presupuestoCategorias = presupCat == 'true';
    
    setState(() {
      _tipoPresupuesto = tipo;
      _modoSemanas = modo;
      _inicioSemana = inicio;
    });
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
          const Text('Preferencias de la App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 16),
          
          // TARJETA 1: Tipo de Presupuesto
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
                    items: ['Mensual', 'Semanal'].map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
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

          // Mostramos las configuraciones semanales SOLO si eligió Semanal
          if (_tipoPresupuesto == 'Semanal') ...[
            const SizedBox(height: 24),
            const Text('Ajustes Semanales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),

            // TARJETA 2: Distribución de Semanas
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

            // TARJETA 3: Inicio de Semana
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
                      items: ['Lunes', 'Domingo'].map((dia) => DropdownMenuItem(value: dia, child: Text(dia))).toList(),
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
          ]
        ],
      ),
    );
  }
}