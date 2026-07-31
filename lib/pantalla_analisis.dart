import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import 'database.dart';
import 'utils.dart';
import 'dart:math';

class PantallaAnalisis extends StatefulWidget {
  const PantallaAnalisis({super.key});

  @override
  State<PantallaAnalisis> createState() => _PantallaAnalisisState();
}

class _PantallaAnalisisState extends State<PantallaAnalisis> {
  double _salario = 0.0;
  double _ahorro = 0.0;
  List<Map<String, dynamic>> _fijos = [];

  // FIX 5: Misma lógica de emojis que categorías
  final List<String> _emojisSugeridos = [
    '🔒', '🏠', '💡', '💧', '🔥', '🛋️', '📱', '💻', '🚗', '🚌',
    '✈️', '🏥', '💊', '🎬', '🎮', '🍔', '🛒', '👕', '📚', '🐶',
    '🐱', '💰', '💳', '📈', '🏦', '💸', '🎁', '🔧', '📁', '☕',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    double salario = await DatabaseHelper.obtenerSalario();
    String ahorroStr = await DatabaseHelper.obtenerConfiguracion('meta_ahorro', '0');
    final fijos = await DatabaseHelper.obtenerFijos();

    if (!mounted) return;

    setState(() {
      _salario = salario;
      _ahorro = double.tryParse(ahorroStr) ?? 0.0;
      _fijos = fijos;
    });
  }

  double get _totalFijos => _fijos.fold(0, (sum, item) => sum + (item['monto'] as num).toDouble());
  double get _disponibleLibre => max(0, _salario - _totalFijos - _ahorro);

  void _editarSalarioOAhorro(bool esSalario) {
    double valorActual = esSalario ? _salario : _ahorro;
    final controller = TextEditingController(
      text: valorActual == 0 ? '' : AppUtils.formatearMoneda(valorActual),
    );

    void procesarYGuardar() async {
      double valor = double.tryParse(controller.text.replaceAll('.', '')) ?? 0.0;

      if (esSalario) {
        await DatabaseHelper.guardarSalario(valor);
      } else {
        await DatabaseHelper.guardarConfiguracion('meta_ahorro', valor.toString());
      }

      if (!mounted) return;
      Navigator.pop(context);
      _cargarDatos();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(esSalario ? 'Actualizar Salario' : 'Meta de Ahorro'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FormatoMoneda()],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => procesarYGuardar(),
          decoration: const InputDecoration(prefixText: '\$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: procesarYGuardar,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // FIX 5: Selector de emojis para fijos
  void _mostrarSelectorEmoji(BuildContext context, TextEditingController controlador) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            children: [
              const Text('Selecciona un icono', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _emojisSugeridos.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        controlador.text = _emojisSugeridos[index];
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text(_emojisSugeridos[index], style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _dialogoFijo({Map? fijoExistente}) {
    final descController = TextEditingController(text: fijoExistente?['descripcion'] ?? '');
    final montoController = TextEditingController(
      text: fijoExistente != null ? AppUtils.formatearMoneda((fijoExistente['monto'] as num).toDouble()) : '',
    );
    final iconoController = TextEditingController(text: fijoExistente?['icono'] ?? '🔒');
    final FocusNode montoFocusNode = FocusNode();

    void procesarYGuardarFijo() async {
      double monto = double.tryParse(montoController.text.replaceAll('.', '')) ?? 0.0;
      String descLimpia = AppUtils.capitalizarTexto(descController.text);
      String emoji = iconoController.text.isNotEmpty ? iconoController.text : '🔒';

      if (descLimpia.isNotEmpty && monto > 0) {
        if (fijoExistente == null) {
          await DatabaseHelper.insertarFijo(descLimpia, monto, icono: emoji);
        } else {
          await DatabaseHelper.actualizarFijo(fijoExistente['id'], descLimpia, monto, icono: emoji);
        }

        if (!mounted) return;
        Navigator.pop(context);
        _cargarDatos();
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fijoExistente == null ? 'Nuevo Gasto Fijo' : 'Editar Fijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX 5: Emoji + Descripción alineados
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: iconoController,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    onTap: () => _mostrarSelectorEmoji(dialogContext, iconoController),
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: descController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(montoFocusNode),
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montoController,
              focusNode: montoFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FormatoMoneda()],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => procesarYGuardarFijo(),
              decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$'),
            ),
          ],
        ),
        actions: [
          if (fijoExistente != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DatabaseHelper.eliminarFijo(fijoExistente['id']);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _cargarDatos();
              },
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: procesarYGuardarFijo,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Estratégico'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _GraficoCircularPainter(_totalFijos, _ahorro, _disponibleLibre, _salario),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LeyendaGrafico(color: Colors.orange, texto: 'Fijos', valor: _totalFijos),
                    const SizedBox(height: 8),
                    _LeyendaGrafico(color: Colors.blue, texto: 'Ahorro', valor: _ahorro),
                    const SizedBox(height: 8),
                    _LeyendaGrafico(color: Colors.green, texto: 'Disponible', valor: _disponibleLibre),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: const Text('Salario Base', style: TextStyle(color: Colors.grey)),
                  subtitle: Text(
                    '\$${AppUtils.formatearMoneda(_salario)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.green),
                  onTap: () => _editarSalarioOAhorro(true),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Meta de Ahorro', style: TextStyle(color: Colors.grey)),
                  subtitle: Text(
                    '\$${AppUtils.formatearMoneda(_ahorro)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.green),
                  onTap: () => _editarSalarioOAhorro(false),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gastos Fijos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.orange, size: 28),
                      onPressed: () => _dialogoFijo(),
                    ),
                  ],
                ),
                ..._fijos.map((f) => Dismissible(
                  key: Key('fijo_${f['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await DatabaseHelper.eliminarFijo(f['id']);
                    _cargarDatos();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      // FIX 5: Emoji personalizado en fijos
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(f['icono'] ?? '🔒', style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(f['descripcion'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('\$${AppUtils.formatearMoneda((f['monto'] as num).toDouble())}'),
                      onTap: () => _dialogoFijo(fijoExistente: f),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS AUXILIARES PARA EL GRÁFICO ---
class _LeyendaGrafico extends StatelessWidget {
  final Color color;
  final String texto;
  final double valor;
  const _LeyendaGrafico({required this.color, required this.texto, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$texto: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('\$${AppUtils.formatearMoneda(valor)}'),
      ],
    );
  }
}

class _GraficoCircularPainter extends CustomPainter {
  final double fijos, ahorro, disponible, salario;
  _GraficoCircularPainter(this.fijos, this.ahorro, this.disponible, this.salario);

  @override
  void paint(Canvas canvas, Size size) {
    if (salario <= 0) return;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double inicio = -pi / 2;

    void dibujarPorcion(double valor, Color color) {
      if (valor <= 0) return;
      double barrido = (valor / salario) * 2 * pi;
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawArc(rect, inicio, barrido, true, paint);
      inicio += barrido;
    }

    dibujarPorcion(fijos, Colors.orange);
    dibujarPorcion(ahorro, Colors.blue);
    dibujarPorcion(disponible, Colors.green);
  }

  @override
  bool shouldRepaint(covariant _GraficoCircularPainter oldDelegate) {
    return oldDelegate.fijos != fijos ||
        oldDelegate.ahorro != ahorro ||
        oldDelegate.disponible != disponible ||
        oldDelegate.salario != salario;
  }
}