import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_page.dart';
import 'dart:math';
import 'models/fijo_model.dart';
import 'providers/fijos_provider.dart';
import 'providers/config_provider.dart';
import 'utils.dart';

class PantallaAnalisis extends ConsumerWidget {
  const PantallaAnalisis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salarioAsync = ref.watch(salarioProvider);
    final ahorroAsync = ref.watch(metaAhorroProvider);
    final fijosAsync = ref.watch(fijosProvider);

    final isLoading = salarioAsync.isLoading || ahorroAsync.isLoading || fijosAsync.isLoading;
    final hasError = salarioAsync.hasError || ahorroAsync.hasError || fijosAsync.hasError;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Análisis Estratégico'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Análisis Estratégico'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Error al cargar datos')),
      );
    }

    final salario = salarioAsync.valueOrNull ?? 0.0;
    final ahorro = ahorroAsync.valueOrNull ?? 0.0;
    final fijos = fijosAsync.valueOrNull ?? [];
    final totalFijos = fijos.fold(0.0, (sum, item) => sum + item.monto);
    final disponibleLibre = max(0, salario - totalFijos - ahorro).toDouble();

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
                    painter: _GraficoCircularPainter(totalFijos, ahorro, disponibleLibre, salario),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LeyendaGrafico(color: Colors.orange, texto: 'Fijos', valor: totalFijos),
                    const SizedBox(height: 8),
                    _LeyendaGrafico(color: Colors.blue, texto: 'Ahorro', valor: ahorro),
                    const SizedBox(height: 8),
                    _LeyendaGrafico(color: Colors.green, texto: 'Disponible', valor: disponibleLibre),
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
                    '\$${AppUtils.formatearMoneda(salario)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.green),
                  onTap: () => _editarSalario(context, ref, salario),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Meta de Ahorro', style: TextStyle(color: Colors.grey)),
                  subtitle: Text(
                    '\$${AppUtils.formatearMoneda(ahorro)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.green),
                  onTap: () => _editarAhorro(context, ref, ahorro),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gastos Fijos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.orange, size: 28),
                      onPressed: () => _dialogoFijo(context, ref),
                    ),
                  ],
                ),
                ...fijos.map((f) => Dismissible(
                  key: Key('fijo_${f.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await ref.read(fijosProvider.notifier).eliminar(f.id!);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(f.icono, style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(f.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('\$${AppUtils.formatearMoneda(f.monto)}'),
                      onTap: () => _dialogoFijo(context, ref, fijoExistente: f),
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

  void _editarSalario(BuildContext context, WidgetRef ref, double valorActual) {
    final controller = TextEditingController(
      text: valorActual == 0 ? '' : AppUtils.formatearMoneda(valorActual),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Actualizar Salario'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FormatoMoneda()],
          decoration: const InputDecoration(prefixText: '\$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(controller.text.replaceAll('.', '')) ?? 0.0;
              await ref.read(configRepositoryProvider).guardarSalario(valor);
              ref.invalidate(salarioProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editarAhorro(BuildContext context, WidgetRef ref, double valorActual) {
    final controller = TextEditingController(
      text: valorActual == 0 ? '' : AppUtils.formatearMoneda(valorActual),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Meta de Ahorro'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FormatoMoneda()],
          decoration: const InputDecoration(prefixText: '\$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(controller.text.replaceAll('.', '')) ?? 0.0;
              await ref.read(configRepositoryProvider).guardar('meta_ahorro', valor.toString());
              ref.invalidate(metaAhorroProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _dialogoFijo(BuildContext context, WidgetRef ref, {FijoModel? fijoExistente}) {
    final descController = TextEditingController(text: fijoExistente?.descripcion ?? '');
    final montoController = TextEditingController(
      text: fijoExistente != null ? AppUtils.formatearMoneda(fijoExistente.monto) : '',
    );
    final iconoController = TextEditingController(text: fijoExistente?.icono ?? '🔒');

    final List<String> emojisSugeridos = [
      '🔒', '🏠', '💡', '💧', '🔥', '🛋️', '📱', '💻', '🚗', '🚌',
      '✈️', '🏥', '💊', '🎬', '🎮', '🍔', '🛒', '👕', '📚', '🐶',
      '🐱', '💰', '💳', '📈', '🏦', '💸', '🎁', '🔧', '📁', '☕',
    ];

    void mostrarSelectorEmoji() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
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
                  itemCount: emojisSugeridos.length,
                  itemBuilder: (context, index) => InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      iconoController.text = emojisSugeridos[index];
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(emojisSugeridos[index], style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fijoExistente == null ? 'Nuevo Gasto Fijo' : 'Editar Fijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    onTap: mostrarSelectorEmoji,
                    decoration: const InputDecoration(labelText: 'Emoji', counterText: ''),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: descController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FormatoMoneda()],
              decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$'),
            ),
          ],
        ),
        actions: [
          if (fijoExistente != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await ref.read(fijosProvider.notifier).eliminar(fijoExistente.id!);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoController.text.replaceAll('.', '')) ?? 0.0;
              final desc = AppUtils.capitalizarTexto(descController.text);
              final icono = iconoController.text.isNotEmpty ? iconoController.text : '🔒';

              if (desc.isNotEmpty && monto > 0) {
                final notifier = ref.read(fijosProvider.notifier);
                if (fijoExistente == null) {
                  await notifier.agregar(FijoModel(descripcion: desc, monto: monto, icono: icono));
                } else {
                  await notifier.actualizar(fijoExistente.copyWith(
                    descripcion: desc,
                    monto: monto,
                    icono: icono,
                  ));
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

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