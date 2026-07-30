// lib/pantalla_inicio.dart
import 'package:flutter/material.dart';
import 'database.dart';
import 'services/presupuesto_service.dart';
import 'pantalla_registro_gasto.dart';
import 'pantalla_analisis.dart';
import 'pantalla_categorias.dart';
import 'pantalla_configuracion.dart';
import 'onboarding_page.dart'; // Para FormatoMoneda
import 'gemma_service.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});
  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  String _tipoPresupuesto = 'Mensual';
  double _salario = 0.0;
  double _totalFijos = 0.0;
  double _totalDebito = 0.0;
  double _totalCredito = 0.0;
  double _ahorro = 0.0;
  int _totalSemanasMes = 5;
  int _semanaActualReal = 1;
  Map<int, double> _presupuestosSemanales = {};
  Map<int, double> _restantesSemanales = {};
  Map<int, List<Map<String, dynamic>>> _gastosPorSemana = {};
  List<Map<String, dynamic>> _gastosRecientes = [];
  
  // Control del mes actual
  DateTime _mesSeleccionado = DateTime.now();
  final List<String> _nombresMeses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + delta, 1);
    });
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    await DatabaseHelper.inicializarCategorias();
    await GemmaService.refrescarCacheCategorias();

    String tipo = await DatabaseHelper.obtenerTipoPresupuesto();
    String inicio = await DatabaseHelper.obtenerConfiguracion('inicio_semana', 'Lunes'); 
    String modo = await DatabaseHelper.obtenerConfiguracion('modo_semanas', 'Dinámico'); 
    
    double salario = await DatabaseHelper.obtenerSalario();
    String ahorroStr = await DatabaseHelper.obtenerConfiguracion('meta_ahorro', '0'); 
    double ahorroFijo = double.tryParse(ahorroStr) ?? 0.0;

    final fijos = await DatabaseHelper.obtenerFijos();
    double fijosSum = fijos.fold(0, (sum, item) => sum + (item['monto'] as num).toDouble());

    final variables = await DatabaseHelper.obtenerGastosPorMes(_mesSeleccionado);
    
    double debitoSum = 0;
    double creditoSum = 0;
    Map<int, List<Map<String, dynamic>>> gruposSemanas = {};

    // 1. Clasificación inicial de gastos de la base de datos
    for (var g in variables) {
      double m = (g['monto'] as num).toDouble();
      if (g['metodo_pago'] == 'Crédito') {
        creditoSum += m;
      } else {
        debitoSum += m;
      }

      DateTime fechaGasto;
      try { fechaGasto = DateTime.parse(g['fecha']); } catch(e) { fechaGasto = DateTime.now(); }
      
      int numeroSemana = _obtenerSemanaDelMes(fechaGasto, inicio, modo);
      
      if (!gruposSemanas.containsKey(numeroSemana)) {
        gruposSemanas[numeroSemana] = [];
      }
      gruposSemanas[numeroSemana]!.add(g);
    }

    // 2. CÁLCULO DE CASCADA Y AMORTIZACIÓN
    int totalSemanas = _obtenerTotalSemanasDelMes(_mesSeleccionado, inicio, modo);
    double disponibleParaSemanas = salario - fijosSum - ahorroFijo; 
    double presupuestoBasePorSemana = totalSemanas > 0 ? disponibleParaSemanas / totalSemanas : 0;
    
    // --- MAGIA: CREACIÓN DE CUOTAS FANTASMA EXTRAÍDA AL SERVICIO ---
    final gruposSemanasProcesados = PresupuestoService.calcularCuotasFantasma(
      gruposSemanas: gruposSemanas,
      totalSemanas: totalSemanas,
      presupuestoBasePorSemana: presupuestoBasePorSemana,
    );

    // --- AHORA SÍ, LA CASCADA USANDO LOS GASTOS PROCESADOS ---
    Map<int, double> presupuestosCalculados = {};
    Map<int, double> restantesCalculados = {};
    double deficitParaSiguienteSemana = 0;

    for (int w = 1; w <= totalSemanas; w++) {
      double presupuestoAsignadoW = presupuestoBasePorSemana - deficitParaSiguienteSemana;
      presupuestosCalculados[w] = presupuestoAsignadoW;

      List<Map<String, dynamic>> gastosDeEstaSemana = gruposSemanasProcesados[w] ?? []; 
      
      double totalGastosW = gastosDeEstaSemana.fold(0, (sum, item) => sum + (item['monto_calculado'] as num).toDouble());
      double restanteW = presupuestoAsignadoW - totalGastosW;
      restantesCalculados[w] = restanteW;

      if (restanteW < 0) {
        deficitParaSiguienteSemana = restanteW.abs();
      } else {
        deficitParaSiguienteSemana = 0; 
      }
    }

    int semanaActualReal = 1;
    if (_mesSeleccionado.month == DateTime.now().month && _mesSeleccionado.year == DateTime.now().year) {
      semanaActualReal = _obtenerSemanaDelMes(DateTime.now(), inicio, modo);
    }

    if (!mounted) return; // Evita warnings al actualizar el estado

    setState(() {
      _tipoPresupuesto = tipo;
      _salario = salario;
      _ahorro = ahorroFijo;
      _totalFijos = fijosSum;
      _totalDebito = debitoSum;
      _totalCredito = creditoSum;
      _gastosRecientes = variables;
      _gastosPorSemana = gruposSemanasProcesados;
      _totalSemanasMes = totalSemanas;
      _presupuestosSemanales = presupuestosCalculados;
      _restantesSemanales = restantesCalculados;
      _semanaActualReal = semanaActualReal; 
    });
  }

  String _formatearVistaMoneda(double cantidad) {
    bool esNegativo = cantidad < 0;
    String numStr = cantidad.abs().toStringAsFixed(0);
    String formateado = numStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return esNegativo ? '-$formateado' : formateado;
  }

  int _obtenerTotalSemanasDelMes(DateTime mes, String inicio, String modo) {
    if (modo == 'Fijo 5') return 5;
    DateTime ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    return _obtenerSemanaDelMes(ultimoDia, inicio, modo);
  }

  String _formatearFecha(String? fechaIso) {
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

  int _obtenerSemanaDelMes(DateTime fecha, String inicioSemana, String modoSemanas) {
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

  void _mostrarDialogoEdicion(Map<String, dynamic> gasto) {
    final descController = TextEditingController(text: gasto['descripcion']);
    final montoController = TextEditingController(text: _formatearVistaMoneda((gasto['monto'] as num).toDouble()));
    String categoriaSeleccionada = gasto['categoria'];
    String metodoSeleccionado = gasto['metodo_pago'] ?? 'Débito';
    String fechaSeleccionada = gasto['fecha'] ?? DateTime.now().toIso8601String();
    final categorias = ['Alimentación', 'Transporte', 'Salud', 'Entretenimiento', 'Hogar', 'Ropa', 'Educación', 'Otros'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder( // Cambio de context a dialogContext
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar Gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
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
                    subtitle: Text(_formatearFecha(fechaSeleccionada), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.green),
                    onTap: () async {
                      DateTime initDate;
                      try { initDate = DateTime.parse(fechaSeleccionada); } catch (e) { initDate = DateTime.now(); }
                      String inicio = await DatabaseHelper.obtenerConfiguracion('inicio_semana', 'Lunes');
                      
                      if (!dialogContext.mounted) return;
                      DateTime? fecha = await showDatePicker(
                        context: dialogContext, 
                        initialDate: initDate, 
                        firstDate: DateTime(2020), 
                        lastDate: DateTime.now(), 
                        builder: (context, child) {
                          return Localizations.override(
                            context: context,
                            locale: inicio == 'Lunes' ? const Locale('es', 'ES') : const Locale('es', 'US'),
                            child: child!,
                          );
                        },
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
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _cargarDashboard();
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext), 
                          child: const Text('Cancelar')
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            double monto = double.tryParse(montoController.text.replaceAll('.', '')) ?? 0.0;
                            if (descController.text.isNotEmpty && monto > 0) {
                              
                              // 1. Rescatamos el tipo y las cuotas originales para no perderlos
                              String tipoExistente = gasto['tipo'] ?? 'Gasto';
                              int cuotasExistentes = gasto['cuotas'] ?? 1;

                              // 2. Ahora sí enviamos los 8 parámetros exactos que espera la base de datos
                              await DatabaseHelper.actualizarGasto(
                                gasto['id'], 
                                descController.text, 
                                monto, 
                                categoriaSeleccionada, 
                                metodoSeleccionado, 
                                fechaSeleccionada,
                                tipoExistente,     // <-- Parámetro 7 añadido
                                cuotasExistentes   // <-- Parámetro 8 añadido
                              );
                              
                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                              _cargarDashboard(); 
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double disponible = _salario - _totalFijos - _ahorro - _totalDebito - _totalCredito;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinanApp', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
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
              onTap: () async {
                Navigator.pop(context); 
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaAnalisis()));
                _cargarDashboard();
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
              onTap: () async {
                Navigator.pop(context); 
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaConfiguracion()));
                _cargarDashboard();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _cambiarMes(-1)),
                Text(
                  '${_nombresMeses[_mesSeleccionado.month - 1]} ${_mesSeleccionado.year}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                ),
                IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _cambiarMes(1)),
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
                  _tipoPresupuesto == 'Mensual' 
                      ? 'PRESUPUESTO MENSUAL' 
                      : 'SEMANA $_semanaActualReal', 
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Text(
                  _tipoPresupuesto == 'Mensual'
                      ? '\$${_formatearVistaMoneda(disponible)}'
                      : '\$${_formatearVistaMoneda(_restantesSemanales[_semanaActualReal] ?? 0.0)}', 
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold, 
                    color: (_tipoPresupuesto == 'Mensual' ? disponible : (_restantesSemanales[_semanaActualReal] ?? 0.0)) >= 0 
                        ? Colors.green.shade800 
                        : Colors.red
                  )
                ),
                if (_tipoPresupuesto == 'Semanal') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Queda del salario total: \$${_formatearVistaMoneda(disponible)}',
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
                      Text('Deuda Tarjeta a separar: \$${_formatearVistaMoneda(_totalCredito)}', 
                        style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _gastosRecientes.isEmpty
                ? const Center(child: Text('Sin gastos en este mes 👋', style: TextStyle(fontSize: 18)))
                : _tipoPresupuesto == 'Mensual'
                    ? ListView.builder(
                        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 88),
                        itemCount: _gastosRecientes.length,
                        itemBuilder: (context, i) => _construirTarjetaGasto(_gastosRecientes[i]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 88),
                        itemCount: _totalSemanasMes,
                        itemBuilder: (context, index) {
                          int semanaActual = index + 1;
                          List<Map<String, dynamic>> gastosDeEstaSemana = _gastosPorSemana[semanaActual] ?? [];
                          
                          double presupuestoSemana = _presupuestosSemanales[semanaActual] ?? 0.0;
                          double restanteSemana = _restantesSemanales[semanaActual] ?? 0.0;
                          bool esNegativo = restanteSemana < 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              initiallyExpanded: _gastosRecientes.isNotEmpty && 
                                  semanaActual == _obtenerSemanaDelMes(DateTime.now(), 
                                      _presupuestosSemanales.containsKey(semanaActual) ? 'Lunes' : 'Lunes', 'Dinámico'), 
                              backgroundColor: esNegativo ? Colors.red.shade50 : Colors.green.shade50,
                              title: Text(
                                'Semana $semanaActual', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: esNegativo ? Colors.red.shade800 : Colors.green.shade800)
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Asignado: \$${_formatearVistaMoneda(presupuestoSemana)}  |  Disponible: \$${_formatearVistaMoneda(restanteSemana)}', 
                                  style: TextStyle(
                                    color: esNegativo ? Colors.red.shade700 : Colors.grey.shade700,
                                    fontWeight: esNegativo ? FontWeight.bold : FontWeight.normal
                                  )
                                ),
                              ),
                              children: gastosDeEstaSemana.isEmpty
                                  ? [
                                      const Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Text('Sin movimientos registrados en este periodo 🎉', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                      )
                                    ]
                                  : gastosDeEstaSemana.map((gasto) => _construirTarjetaGasto(gasto)).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRegistroGasto()));
          _cargarDashboard();
        },
        label: const Text('Registrar gasto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _construirTarjetaGasto(Map<String, dynamic> g) {
    String fechaVisual = _formatearFecha(g['fecha']);
    bool esCredito = g['metodo_pago'] == 'Crédito';
    bool esFantasma = g['es_fantasma'] == true;
    
    double montoMostrar = (g['monto_calculado'] ?? g['monto'] as num).toDouble();
    String descMostrar = g['desc_visual'] ?? g['descripcion'];

    Widget tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: esFantasma ? Colors.grey.shade200 : (esCredito ? Colors.purple.shade100 : Colors.green.shade100),
        child: Icon(esCredito ? Icons.credit_card : Icons.account_balance_wallet, 
                    color: esFantasma ? Colors.grey : (esCredito ? Colors.purple : Colors.green)),
      ),
      title: Text(descMostrar, style: TextStyle(fontWeight: FontWeight.bold, color: esFantasma ? Colors.grey : Colors.black)),
      subtitle: Text('${g['categoria']} • ${g['metodo_pago'] ?? 'Débito'} • $fechaVisual'), 
      trailing: Text(
        '-\$${_formatearVistaMoneda(montoMostrar)}',
        style: TextStyle(color: esFantasma ? Colors.grey : (esCredito ? Colors.purple : Colors.red), fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onTap: esFantasma 
          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta es una cuota dividida. Edita o borra el gasto original en la semana que lo registraste.')))
          : () => _mostrarDialogoEdicion(g),
    );

    if (esFantasma) {
      return Card(margin: const EdgeInsets.only(bottom: 8), elevation: 0, color: Colors.grey.shade50, child: tile);
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
        onDismissed: (direction) async {
          await DatabaseHelper.eliminarGasto(g['id']);
          _cargarDashboard();
        },
        child: tile,
      ),
    );
  }
}