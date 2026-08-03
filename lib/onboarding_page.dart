import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/config_provider.dart';
import 'providers/fijos_provider.dart';
import 'models/fijo_model.dart';
import 'pantalla_inicio.dart';

class PantallaOnboarding extends ConsumerStatefulWidget {
  const PantallaOnboarding({super.key});

  @override
  ConsumerState<PantallaOnboarding> createState() => _PantallaOnboardingState();
}

class _PantallaOnboardingState extends ConsumerState<PantallaOnboarding> {
  final PageController _pageController = PageController();
  final TextEditingController _salarioController = TextEditingController();
  final TextEditingController _fijoDescController = TextEditingController();
  final TextEditingController _fijoMontoController = TextEditingController();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _montoFocus = FocusNode();
  final List<Map<String, dynamic>> _fijosTemporales = [];

  void _guardarPasoSalario(double salario) async {
    await ref.read(configRepositoryProvider).guardarSalario(salario);
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _agregarFijoTemporal() {
    double monto = double.tryParse(_fijoMontoController.text.replaceAll('.', '').trim()) ?? 0.0;
    String descLimpia = _fijoDescController.text.trim().split(' ').map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').join(' ');

    if (descLimpia.isNotEmpty && monto > 0) {
      setState(() {
        _fijosTemporales.add({
          'descripcion': descLimpia,
          'monto': monto,
          'fechaPago': null,
          'recordatorioDias': 0,
          'recordatorioActivo': 0,
        });
        _fijoDescController.clear();
        _fijoMontoController.clear();
      });
    }
  }

  void _actualizarFijoTemporal(int index, {
    int? fechaPago,
    int? recordatorioDias,
    int? recordatorioActivo,
  }) {
    setState(() {
      if (fechaPago != null) _fijosTemporales[index]['fechaPago'] = fechaPago;
      if (recordatorioDias != null) _fijosTemporales[index]['recordatorioDias'] = recordatorioDias;
      if (recordatorioActivo != null) _fijosTemporales[index]['recordatorioActivo'] = recordatorioActivo;
    });
  }

  void _finalizarOnboarding() async {
    try {
      final notifier = ref.read(fijosProvider.notifier);
      for (var fijo in _fijosTemporales) {
        await notifier.agregar(FijoModel(
          descripcion: fijo['descripcion'],
          monto: fijo['monto'],
          fechaPago: fijo['fechaPago'],
          recordatorioDias: fijo['recordatorioDias'],
          recordatorioActivo: fijo['recordatorioActivo'],
        ));
      }
      await ref.read(configRepositoryProvider).completarOnboarding();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaInicio()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // PASO 1: Salario
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tus Ingresos 💰', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('¿Cuál es tu salario neto o ingreso fijo mensual?', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _salarioController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FormatoMoneda()],
                  decoration: InputDecoration(
                    labelText: 'Ingreso Neto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      double salario = double.tryParse(_salarioController.text.replaceAll('.', '').trim()) ?? 0.0;
                      if (salario <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor ingresa un salario válido')));
                        return;
                      }
                      _guardarPasoSalario(salario);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Continuar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => _guardarPasoSalario(0.0),
                    child: const Text('No tengo ingresos fijos', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                  ),
                )
              ],
            ),
          ),

          // PASO 2: Gastos Fijos
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const Text('Gastos Fijos 📌', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Registra arriendo, servicios, suscripciones, etc.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _fijoDescController,
                        focusNode: _descFocus,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_montoFocus),
                        decoration: const InputDecoration(hintText: 'Ej: Arriendo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fijoMontoController,
                        focusNode: _montoFocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FormatoMoneda()],
                        onSubmitted: (_) {
                          _agregarFijoTemporal();
                          FocusScope.of(context).requestFocus(_descFocus);
                        },
                        decoration: const InputDecoration(hintText: 'Monto'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                      onPressed: () {
                        _agregarFijoTemporal();
                        FocusScope.of(context).requestFocus(_descFocus);
                      },
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _fijosTemporales.isEmpty
                      ? const Center(child: Text('No has agregado gastos fijos todavía.'))
                      : ListView.builder(
                          itemCount: _fijosTemporales.length,
                          itemBuilder: (context, i) {
                            final item = _fijosTemporales[i];
                            return _FijoTemporalTile(
                              index: i,
                              item: item,
                              onUpdate: _actualizarFijoTemporal,
                              onDelete: () => setState(() => _fijosTemporales.removeAt(i)),
                            );
                          },
                        ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finalizarOnboarding,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Terminar Configuración', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _FijoTemporalTile extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final Function(int, {int? fechaPago, int? recordatorioDias, int? recordatorioActivo}) onUpdate;
  final VoidCallback onDelete;

  const _FijoTemporalTile({
    required this.index,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_FijoTemporalTile> createState() => _FijoTemporalTileState();
}

class _FijoTemporalTileState extends State<_FijoTemporalTile> {
  bool _tieneFecha = false;

  @override
  void initState() {
    super.initState();
    _tieneFecha = widget.item['fechaPago'] != null;
  }

    @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.lock, color: Colors.white, size: 18),
            ),
            title: Text(item['descripcion']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\$${item['monto'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('¿Tiene fecha de pago?', style: TextStyle(fontSize: 13)),
                  value: _tieneFecha,
                  onChanged: (val) {
                    setState(() => _tieneFecha = val);
                    if (!val) widget.onUpdate(widget.index, fechaPago: null);
                  },
                ),
                if (_tieneFecha) ...[
                  Row(
                    children: [
                      const Text('Día: '),
                      DropdownButton<int>(
                        value: item['fechaPago'],
                        hint: const Text('Elegir'),
                        items: List.generate(31, (i) => i + 1)
                            .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {});
                          widget.onUpdate(widget.index, fechaPago: val);
                        },
                      ),
                      const Spacer(),
                      const Text('Recordar: '),
                      DropdownButton<int>(
                        value: item['recordatorioDias'],
                        items: List.generate(15, (i) => i)
                            .map((d) => DropdownMenuItem(value: d, child: Text('$d ${d == 1 ? 'día' : 'días'}')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {});
                          widget.onUpdate(widget.index, recordatorioDias: val, recordatorioActivo: val != null && val > 0 ? 1 : 0);
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FormatoMoneda extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String soloNumeros = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloNumeros.isEmpty) return newValue;

    String formateado = '';
    int contador = 0;
    for (int i = soloNumeros.length - 1; i >= 0; i--) {
      if (contador != 0 && contador % 3 == 0) {
        formateado = '.$formateado';
      }
      formateado = soloNumeros[i] + formateado;
      contador++;
    }

    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}