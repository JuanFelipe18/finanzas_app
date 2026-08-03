import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/categorias_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/gastos_provider.dart';
import 'package:flutter/material.dart';
import 'models/gasto_model.dart';

class PantallaConfirmacion extends ConsumerStatefulWidget {
  final List<GastoModel> gastos;
  const PantallaConfirmacion({super.key, required this.gastos});

  @override
  ConsumerState<PantallaConfirmacion> createState() => _PantallaConfirmacionState();
}

class _PantallaConfirmacionState extends ConsumerState<PantallaConfirmacion> {
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar gastos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: categoriasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categorias) {
          final nombresCategorias = categorias.map((c) => c.nombre).toList();
          if (nombresCategorias.isEmpty) {
            nombresCategorias.addAll(['Alimentación', 'Transporte', 'Salud', 'Entretenimiento', 'Hogar', 'Ropa', 'Educación', 'Otros']);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.gastos.length,
            itemBuilder: (context, i) {
              final gasto = widget.gastos[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gasto.descripcion,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('\$${gasto.monto.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, color: Colors.green)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: nombresCategorias.contains(gasto.categoria) ? gasto.categoria : nombresCategorias.last,
                        isExpanded: true,
                        items: nombresCategorias
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          setState(() => widget.gastos[i] = widget.gastos[i].copyWith(categoria: val));
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: ['Débito', 'Crédito'].contains(gasto.metodoPago) ? gasto.metodoPago : 'Débito',
                        isExpanded: true,
                        items: ['Débito', 'Crédito']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          setState(() => widget.gastos[i] = widget.gastos[i].copyWith(metodoPago: val));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Guardar gastos', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final repo = ref.read(gastoRepositoryProvider);

    for (final gasto in widget.gastos) {
      await repo.insertar(gasto);
    }

    // Invalidar providers para que todo se actualice al volver al home
    ref.invalidate(gastosProvider);
    ref.invalidate(categoriasProvider);
    ref.invalidate(dashboardProvider(DateTime.now()));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Gastos guardados')),
    );

    Navigator.popUntil(context, (r) => r.isFirst);
  }
}