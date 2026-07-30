import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pantalla_inicio.dart';
import 'database.dart';

class PantallaOnboarding extends StatefulWidget {
  const PantallaOnboarding({super.key});

  @override
  State<PantallaOnboarding> createState() => _PantallaOnboardingState();
}

class _PantallaOnboardingState extends State<PantallaOnboarding> {
  final PageController _pageController = PageController();
  final TextEditingController _salarioController = TextEditingController();
  
  final TextEditingController _fijoDescController = TextEditingController();
  final TextEditingController _fijoMontoController = TextEditingController();
  
  // <-- NUEVO: Los controles remotos del cursor
  final FocusNode _descFocus = FocusNode();
  final FocusNode _montoFocus = FocusNode();
  
  final List<Map<String, dynamic>> _fijosTemporales = [];

  // Función visual para ponerle puntos a la lista de fijos
  String _formatearVistaMoneda(double cantidad) {
    String numStr = cantidad.toStringAsFixed(0);
    return numStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _guardarPasoSalario(double salario) async {
    await DatabaseHelper.guardarSalario(salario);
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _agregarFijoTemporal() {
    double monto = double.tryParse(_fijoMontoController.text.replaceAll('.', '').trim()) ?? 0.0;
    
    // Aplicamos la lógica de capitalización directamente aquí
    String descLimpia = _fijoDescController.text.trim().split(' ').map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').join(' ');

    if (descLimpia.isNotEmpty && monto > 0) {
      setState(() {
        // Usamos descLimpia en lugar del texto crudo
        _fijosTemporales.add({'descripcion': descLimpia, 'monto': monto});
        _fijoDescController.clear();
        _fijoMontoController.clear();
      });
    }
  }

  void _finalizarOnboarding() async {
    for (var fijo in _fijosTemporales) {
      await DatabaseHelper.insertarFijo(fijo['descripcion'], fijo['monto']);
    }
    await DatabaseHelper.completarOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        // Al terminar los fijos, vamos directo al Dashboard
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
                // Botón para freelancers o personas sin ingreso fijo
                Center(
                  child: TextButton(
                    onPressed: () => _guardarPasoSalario(0.0), // Guarda 0 y avanza
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
                        focusNode: _descFocus, // <-- 1. Le asignamos su nodo
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next, // Botón "Siguiente" en teclado
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_montoFocus), // <-- 2. Salta al valor
                        decoration: const InputDecoration(hintText: 'Ej: Arriendo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fijoMontoController,
                        focusNode: _montoFocus, // <-- 3. Le asignamos su nodo
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done, // Botón "Confirmar/Listo"
                        inputFormatters: [FormatoMoneda()],
                        onSubmitted: (_) {
                          _agregarFijoTemporal(); // <-- 4. Guarda el gasto en la lista
                          FocusScope.of(context).requestFocus(_descFocus); // <-- 5. ¡Regresa el cursor al título!
                        },
                        decoration: const InputDecoration(hintText: 'Monto'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                      onPressed: () {
                        _agregarFijoTemporal();
                        // Si el usuario presiona el botón con el dedo, también le regresamos el cursor al título
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
                              key: UniqueKey(), // Usamos UniqueKey porque aún no tienen ID en BD
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
                                  // Agregamos el icono naranja para mantener la estética de los fijos
                                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.lock, color: Colors.white, size: 18)),
                                  title: Text(item['descripcion']),
                                  // Quitamos el botón de papelera original y dejamos solo el monto
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

// (Mantén la clase FormatoMoneda exactamente igual que la tenías abajo)
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