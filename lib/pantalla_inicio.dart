import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'models/dashboard_data.dart';
import 'services/dashboard_service.dart';
import 'providers/dashboard_provider.dart';
import 'pantalla_registro_gasto.dart';
import 'pantalla_analisis.dart';
import 'pantalla_categorias.dart';
import 'pantalla_configuracion.dart';
import 'onboarding_page.dart';

class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  final List<String> _nombresMeses = const [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesSeleccionado = ref.watch(mesSeleccionadoProvider);
    final dashboardAsync = ref.watch(dashboardProvider(mesSeleccionado));

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinanApp', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context, ref),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) => _buildBody(context, ref, data, mesSeleccionado),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PantallaRegistroGasto()),
        ),
        label: const Text('Registrar gasto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DashboardData data, DateTime mes) {
    double disponible = data.salario - data.totalFijos - data.ahorro - data.totalDebito - data.totalCredito;

    return Column(
      children: [
        Container(
          color: Colors.green.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _cambiarMes(ref, mes, -1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_nombresMeses[mes.month - 1]} ${mes.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.read(mesSeleccionadoProvider.notifier).state = DateTime.now(),
                icon: const Icon(Icons.today, size: 18, color: Colors.green),
                label: const Text('Hoy', style: TextStyle(color: Colors.green)),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _cambiarMes(ref, mes, 1),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.green.shade50,
          width: double.infinity,
          child: Column(
            children: [
              Text(
                data.tipoPresupuesto == 'Mensual'
                    ? 'PRESUPUESTO MENSUAL'
                    : 'SEMANA ${data.semanaActualReal}',
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                data.tipoPresupuesto == 'Mensual'
                    ? '\$${DashboardService.formatearVistaMoneda(disponible)}'
                    : '\$${DashboardService.formatearVistaMoneda(data.restantesSemanales[data.semanaActualReal] ?? 0.0)}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: (data.tipoPresupuesto == 'Mensual'
                          ? disponible
                          : (data.restantesSemanales[data.semanaActualReal] ?? 0.0)) >= 0
                      ? Colors.green.shade800
                      : Colors.red,
                ),
              ),
              if (data.tipoPresupuesto == 'Semanal') ...[
                const SizedBox(height: 6),
                Text(
                  'Queda del salario total: \$${DashboardService.formatearVistaMoneda(disponible)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Deuda Tarjeta a separar: \$${DashboardService.formatearVistaMoneda(data.totalCredito)}',
                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: data.gastosRecientes.isEmpty
              ? const Center(child: Text('Sin gastos en este mes 👋', style: TextStyle(fontSize: 18)))
              : data.tipoPresupuesto == 'Mensual'
                  ? ListView.builder(
                      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 88),
                      itemCount: data.gastosRecientes.length,
                      itemBuilder: (context, i) => _construirTarjetaGasto(context, ref, data, data.gastosRecientes[i]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 88),
                      itemCount: data.totalSemanasMes,
                      itemBuilder: (context, index) {
                        int semanaActual = index + 1;
                        List<Map<String, dynamic>> gastosDeEstaSemana = data.gastosPorSemana[semanaActual] ?? [];

                        double presupuestoSemana = data.presupuestosSemanales[semanaActual] ?? 0.0;
                        double restanteSemana = data.restantesSemanales[semanaActual] ?? 0.0;
                        bool esNegativo = restanteSemana < 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            initiallyExpanded: data.gastosRecientes.isNotEmpty &&
                                semanaActual == DashboardService.obtenerSemanaDelMes(
                                  DateTime.now(),
                                  'Lunes',
                                  'Dinámico',
                                ),
                            backgroundColor: esNegativo ? Colors.red.shade50 : Colors.green.shade50,
                            title: Text(
                              'Semana $semanaActual',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: esNegativo ? Colors.red.shade800 : Colors.green.shade800,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Asignado: \$${DashboardService.formatearVistaMoneda(presupuestoSemana)} | Disponible: \$${DashboardService.formatearVistaMoneda(restanteSemana)}',
                                style: TextStyle(
                                  color: esNegativo ? Colors.red.shade700 : Colors.grey.shade700,
                                  fontWeight: esNegativo ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            children: gastosDeEstaSemana.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        'Sin movimientos registrados en este periodo 🎉',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ),
                                  ]
                                : gastosDeEstaSemana
                                    .map((gasto) => _construirTarjetaGasto(context, ref, data, gasto))
                                    .toList(),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _cambiarMes(WidgetRef ref, DateTime mesActual, int delta) {
    ref.read(mesSeleccionadoProvider.notifier).state =
        DateTime(mesActual.year, mesActual.month + delta, 1);
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text('FinanApp', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart, color: Colors.blue),
            title: const Text('Análisis y Estrategia', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaAnalisis()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.purple),
            title: const Text('Categorías', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCategorias()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Configuración', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaConfiguracion()));
            },
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaGasto(BuildContext context, WidgetRef ref, DashboardData data, Map<String, dynamic> g) {
    String fechaVisual = DashboardService.formatearFecha(g['fecha']);
    bool esCredito = g['metodo_pago'] == 'Crédito';
    bool esFantasma = g['es_fantasma'] == true;

    double montoMostrar = (g['monto_calculado'] ?? g['monto'] as num).toDouble();
    String descMostrar = g['desc_visual'] ?? g['descripcion'];

    Widget tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: esFantasma
            ? Colors.grey.shade200
            : (esCredito ? Colors.purple.shade100 : Colors.green.shade100),
        child: Icon(
          esCredito ? Icons.credit_card : Icons.account_balance_wallet,
          color: esFantasma
              ? Colors.grey
              : (esCredito ? Colors.purple : Colors.green),
        ),
      ),
      title: Text(
        descMostrar,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: esFantasma ? Colors.grey : Colors.black,
        ),
      ),
      subtitle: Text('${g['categoria']} • ${g['metodo_pago'] ?? 'Débito'} • $fechaVisual'),
      trailing: Text(
        '-\$${DashboardService.formatearVistaMoneda(montoMostrar)}',
        style: TextStyle(
          color: esFantasma
              ? Colors.grey
              : (esCredito ? Colors.purple : Colors.red),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: esFantasma
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Esta es una cuota dividida. Edita o borra el gasto original en la semana que lo registraste.')),
              )
          : () => _mostrarDialogoEdicion(context, ref, data, g),
    );

    if (esFantasma) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.grey.shade50,
        child: tile,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key(g['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) async {
          await DatabaseHelper.eliminarGasto(g['id']);
          ref.invalidate(dashboardProvider(ref.read(mesSeleccionadoProvider)));
        },
        child: tile,
      ),
    );
  }

  void _mostrarDialogoEdicion(BuildContext context, WidgetRef ref, DashboardData data, Map<String, dynamic> gasto) {
    final descController = TextEditingController(text: gasto['descripcion']);
    final montoController = TextEditingController(
      text: DashboardService.formatearVistaMoneda((gasto['monto'] as num).toDouble()),
    );
    String categoriaSeleccionada = gasto['categoria'];
    String metodoSeleccionado = gasto['metodo_pago'] ?? 'Débito';
    String fechaSeleccionada = gasto['fecha'] ?? DateTime.now().toIso8601String();

    final categorias = data.categoriasDisponibles.isNotEmpty
        ? data.categoriasDisponibles.map((c) => c['nombre'] as String).toList()
        : ['Alimentación', 'Transporte', 'Salud', 'Entretenimiento', 'Hogar', 'Ropa', 'Educación', 'Otros'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar Gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FormatoMoneda()],
                    decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categorias.contains(categoriaSeleccionada) ? categoriaSeleccionada : 'Otros',
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setStateDialog(() => categoriaSeleccionada = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: ['Débito', 'Crédito'].contains(metodoSeleccionado) ? metodoSeleccionado : 'Débito',
                    decoration: const InputDecoration(labelText: 'Método de pago'),
                    items: ['Débito', 'Crédito'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setStateDialog(() => metodoSeleccionado = val!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    subtitle: Text(
                      DashboardService.formatearFecha(fechaSeleccionada),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.green),
                    onTap: () async {
                      DateTime initDate;
                      try {
                        initDate = DateTime.parse(fechaSeleccionada);
                      } catch (e) {
                        initDate = DateTime.now();
                      }

                      DateTime? fecha = await showDatePicker(
                        context: dialogContext,
                        initialDate: initDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );

                      if (fecha != null) {
                        setStateDialog(() => fechaSeleccionada = fecha.toIso8601String());
                      }
                    },
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DatabaseHelper.eliminarGasto(gasto['id']);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ref.invalidate(dashboardProvider(ref.read(mesSeleccionadoProvider)));
                          }
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            double monto = double.tryParse(montoController.text.replaceAll('.', '')) ?? 0.0;
                            if (descController.text.isNotEmpty && monto > 0) {
                              String tipoExistente = gasto['tipo'] ?? 'Gasto';
                              int cuotasExistentes = gasto['cuotas'] ?? 1;

                              await DatabaseHelper.actualizarGasto(
                                gasto['id'],
                                descController.text,
                                monto,
                                categoriaSeleccionada,
                                metodoSeleccionado,
                                fechaSeleccionada,
                                tipoExistente,
                                cuotasExistentes,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(dashboardProvider(ref.read(mesSeleccionadoProvider)));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}