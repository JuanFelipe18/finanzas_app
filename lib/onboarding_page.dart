import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _formatearVistaMoneda(double cantidad) {
    String numStr = cantidad.toStringAsFixed(0);
    return numStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _guardarPasoSalario(double salario) async {
    await ref.read(configRepositoryProvider).guardarSalario(salario);
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _agregarFijoTemporal() {
    double monto = double.tryParse(_fijoMontoController.text.replaceAll('.', '').trim()) ?? 0.0;
    String descLimpia = _fijoDescController.text.trim().split(' ').map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').join(' ');

    if (descLimpia.isNotEmpty && monto > 0) {
      setState(() {
        _fijosTemporales.add({'descripcion': descLimpia, 'monto': monto});
        _fijoDescController.clear();
        _fijoMontoController.clear();
      });
    }
  }

  void _finalizarOnboarding() async {
    final fijoRepo = ref.read(fijoRepositoryProvider);
    for (var fijo in _fijosTemporales) {
      await fijoRepo.insertar(FijoModel(
        descripcion: fijo['descripcion'],
        monto: fijo['monto'],
      ));
    }
    await ref.read(configRepositoryProvider).completarOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaInicio()),
      );
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
                const Text('¿Cuál es tu salario neto o ingreso fijo mensual? (Lo que realmente llega a tu cuenta)', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                setState(() {
                                  _fijosTemporales.removeAt(i);
                                });
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.lock, color: Colors.white, size: 18)),
                                  title: Text(item['descripcion']),
                                  trailing: Text('\$${_formatearVistaMoneda(item['monto'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
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