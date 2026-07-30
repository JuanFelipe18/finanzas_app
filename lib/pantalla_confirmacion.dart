// lib/pantalla_confirmacion.dart
import 'package:flutter/material.dart';
import 'database.dart';
import 'models/gasto.dart';

class PantallaConfirmacion extends StatefulWidget {
  final List<Gasto> gastos;
  const PantallaConfirmacion({super.key, required this.gastos});

  @override
  State<PantallaConfirmacion> createState() => _PantallaConfirmacionState();
}

class _PantallaConfirmacionState extends State<PantallaConfirmacion> {
  final List<String> _categorias = [
    'Alimentación', 'Transporte', 'Salud', 'Entretenimiento',
    'Hogar', 'Ropa', 'Educación', 'Otros'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar gastos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
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
                    value: gasto.categoria == 'Sin categoría' ? _categorias[7] : gasto.categoria,
                    isExpanded: true,
                    items: _categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => gasto.categoria = val!);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: ['Débito', 'Crédito'].contains(gasto.metodoPago) ? gasto.metodoPago : 'Débito',
                    isExpanded: true,
                    items: ['Débito', 'Crédito'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      setState(() => gasto.metodoPago = val!);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            for (final gasto in widget.gastos) {
              await DatabaseHelper.insertarGasto(gasto);
            }
            
            if (!mounted) return; // <-- Nueva regla de Flutter cumplida

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Gastos guardados')),
            );
            
            Navigator.popUntil(context, (r) => r.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Guardar gastos', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}