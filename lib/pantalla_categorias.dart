import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/categoria_model.dart';
import 'providers/categorias_provider.dart';
import 'gemma_service.dart';
import 'onboarding_page.dart';

class PantallaCategorias extends ConsumerWidget {
  const PantallaCategorias({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _mostrarDialogo(context, ref),
      ),
      body: categoriasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categorias) {
          if (categorias.isEmpty) {
            return const Center(child: Text('No hay categorías'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final cat = categorias[index];
              return _CategoriaTile(categoria: cat);
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogo(BuildContext context, WidgetRef ref, {CategoriaModel? categoria}) {
    showDialog(
      context: context,
      builder: (context) => _DialogoCategoria(categoria: categoria),
    );
  }
}

class _CategoriaTile extends ConsumerWidget {
  final CategoriaModel categoria;

  const _CategoriaTile({required this.categoria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('cat_${categoria.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirmar"),
          content: const Text("¿Eliminar esta categoría?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("BORRAR", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
      onDismissed: (_) async {
        await ref.read(categoriasProvider.notifier).eliminar(categoria.id!);
        await GemmaService.refrescarCacheCategorias();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade50,
            child: Text(categoria.icono, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(categoria.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.edit, color: Colors.grey),
          onTap: () => showDialog(
            context: context,
            builder: (_) => _DialogoCategoria(categoria: categoria),
          ),
        ),
      ),
    );
  }
}

class _DialogoCategoria extends ConsumerStatefulWidget {
  final CategoriaModel? categoria;
  const _DialogoCategoria({this.categoria});

  @override
  ConsumerState<_DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends ConsumerState<_DialogoCategoria> {
  late final TextEditingController _nombreController;
  late final TextEditingController _iconoController;
  late final TextEditingController _presuController;

  final List<String> _emojisSugeridos = [
    '🍔', '🍕', '🍎', '☕', '🛒',
    '🚌', '🚗', '🚕', '✈️', '🚲',
    '🏥', '💊', '⚕️', '🦷', '🩺',
    '🎬', '🎮', '🎫', '⚽', '🍻',
    '🏠', '💡', '💧', '🔥', '🛋️',
    '👕', '👗', '👟', '🕶️', '👜',
    '📚', '🎓', '✏️', '💻', '🎒',
    '🐶', '🐱', '🐾', '🦴', '🐟',
    '💰', '💳', '📈', '🏦', '💸',
    '🎁', '💈', '💅', '🔧', '📁',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre ?? '');
    _iconoController = TextEditingController(text: widget.categoria?.icono ?? '📁');
    _presuController = TextEditingController(
      text: (widget.categoria != null && widget.categoria!.presupuesto > 0)
          ? _formatear(widget.categoria!.presupuesto)
          : '',
    );
  }

  String _formatear(double cantidad) {
    return cantidad.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _mostrarSelectorEmoji() {
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
                itemCount: _emojisSugeridos.length,
                itemBuilder: (context, index) => InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() => _iconoController.text = _emojisSugeridos[index]);
                    Navigator.pop(context);
                  },
                  child: Center(child: Text(_emojisSugeridos[index], style: const TextStyle(fontSize: 28))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esNueva = widget.categoria == null;

    return AlertDialog(
      title: Text(esNueva ? 'Nueva Categoría' : 'Editar Categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _iconoController,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    onTap: _mostrarSelectorEmoji,
                    decoration: const InputDecoration(labelText: 'Emoji', counterText: ''),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _presuController,
              keyboardType: TextInputType.number,
              inputFormatters: [FormatoMoneda()],
              decoration: const InputDecoration(labelText: 'Presupuesto Mensual', prefixText: '\$'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final nombre = _nombreController.text.trim();
            final icono = _iconoController.text.isNotEmpty ? _iconoController.text : '📁';
            final presupuesto = double.tryParse(_presuController.text.replaceAll('.', '')) ?? 0.0;

            if (nombre.isEmpty) return;

            final notifier = ref.read(categoriasProvider.notifier);
            final cats = await ref.read(categoriaRepositoryProvider).obtenerTodos();

            // Validar duplicados
            final duplicado = cats.any((c) =>
                c.nombre.toLowerCase() == nombre.toLowerCase() &&
                c.id != widget.categoria?.id);

            if (duplicado) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ya existe una categoría con ese nombre')),
              );
              return;
            }

            if (esNueva) {
              await notifier.agregar(CategoriaModel(nombre: nombre, icono: icono, presupuesto: presupuesto));
            } else {
              await notifier.actualizar(widget.categoria!.copyWith(
                nombre: nombre,
                icono: icono,
                presupuesto: presupuesto,
              ));
            }

            await GemmaService.refrescarCacheCategorias();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}