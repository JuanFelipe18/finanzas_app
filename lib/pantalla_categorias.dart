import 'package:flutter/material.dart';
import 'database.dart';
import 'onboarding_page.dart'; // Para FormatoMoneda()
import 'gemma_service.dart';

class PantallaCategorias extends StatefulWidget {
  const PantallaCategorias({super.key});

  @override
  State<PantallaCategorias> createState() => _PantallaCategoriasState();
}

class _PantallaCategoriasState extends State<PantallaCategorias> {
  List<Map<String, dynamic>> _categorias = [];
  bool _usarPresupuestos = false;
  // Catálogo hiperligero de emojis frecuentes para finanzas (ocupa 0kb de memoria)
  final List<String> _emojisSugeridos = [
    '🍔', '🍕', '🍎', '☕', '🛒', // Alimentación/Mercado
    '🚌', '🚗', '🚕', '✈️', '🚲', // Transporte
    '🏥', '💊', '⚕️', '🦷', '🩺', // Salud
    '🎬', '🎮', '🎫', '⚽', '🍻', // Entretenimiento
    '🏠', '💡', '💧', '🔥', '🛋️', // Hogar/Servicios
    '👕', '👗', '👟', '🕶️', '👜', // Ropa
    '📚', '🎓', '✏️', '💻', '🎒', // Educación/Trabajo
    '🐶', '🐱', '🐾', '🦴', '🐟', // Mascotas
    '💰', '💳', '📈', '🏦', '💸', // Finanzas
    '🎁', '💈', '💅', '🔧', '📁', // Otros/Varios
  ];

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
                    crossAxisCount: 6, // 6 emojis por fila
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _emojisSugeridos.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        controlador.text = _emojisSugeridos[index];
                        Navigator.pop(context); // Cierra el panel al seleccionar
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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final categorias = await DatabaseHelper.obtenerCategorias();
    String config = await DatabaseHelper.obtenerConfiguracion('presupuesto_categorias', 'false');
    setState(() {
      _categorias = categorias;
      _usarPresupuestos = config == 'true';
    });
  }

  String _formatear(double cantidad) {
    return cantidad.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _editarCategoria({Map<String, dynamic>? cat}) {
    final nombreController = TextEditingController(text: cat?['nombre'] ?? '');
    final presuController = TextEditingController(text: (cat != null && cat['presupuesto'] > 0) ? _formatear((cat['presupuesto'] as num).toDouble()) : '');
    final iconoController = TextEditingController(text: cat?['icono'] ?? '📁'); 
    final FocusNode presuFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cat == null ? 'Nueva Categoría' : 'Editar Categoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: iconoController,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28),
                      onTap: () => _mostrarSelectorEmoji(context, iconoController), // Abre nuestro panel
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
                      controller: nombreController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: _usarPresupuestos ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: (_) {
                        if (_usarPresupuestos) FocusScope.of(context).requestFocus(presuFocus);
                      },
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                  ),
                ],
              ),
              if (_usarPresupuestos) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: presuController,
                  focusNode: presuFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FormatoMoneda()],
                  decoration: const InputDecoration(labelText: 'Presupuesto Mensual', prefixText: '\$'),
                ),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              String nombreLimpio = nombreController.text.trim();
              String emoji = iconoController.text.isNotEmpty ? iconoController.text : '📁'; 
              double presupuesto = _usarPresupuestos ? (double.tryParse(presuController.text.replaceAll('.', '')) ?? 0.0) : 0.0;
              
              if (nombreLimpio.isNotEmpty) {
                if (cat == null) {
                  // Si es nueva, inserta
                  await DatabaseHelper.insertarCategoria(nombreLimpio, emoji, presupuesto);
                } else {
                  // Si existe, actualiza
                  await DatabaseHelper.actualizarCategoria(cat['id'], nombreLimpio, emoji, presupuesto);
                }
                
                await GemmaService.refrescarCacheCategorias(); // Refresca la IA
                
                if (!mounted) return;
                _cargarDatos();
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      // --- NUEVO: BOTÓN FLOTANTE PARA AGREGAR ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _editarCategoria(), // Lo llamamos sin parámetros para crear
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final cat = _categorias[index];
          double presupuesto = (cat['presupuesto'] as num).toDouble();

          // --- NUEVO: DESLIZAR PARA BORRAR ---
          return Dismissible(
            key: Key('cat_${cat['id']}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            // Confirmación opcional para evitar borrar por accidente
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirmar"),
                    content: const Text("¿Estás seguro de que deseas eliminar esta categoría?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCELAR")),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("BORRAR", style: TextStyle(color: Colors.red))),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) async {
              await DatabaseHelper.eliminarCategoria(cat['id']);
              await GemmaService.refrescarCacheCategorias(); // Que la IA lo olvide
              _cargarDatos();
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: Text(cat['icono'], style: const TextStyle(fontSize: 22))),
                title: Text(cat['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: _usarPresupuestos && presupuesto > 0
                    ? Text('Presupuesto: \$${_formatear(presupuesto)}', style: const TextStyle(color: Colors.green))
                    : const Text('Sin límite establecido', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.edit, color: Colors.grey),
                onTap: () => _editarCategoria(cat: cat), // Lo llamamos con la categoría para editar
              ),
            ),
          );
        },
      ),
    );
  }
}