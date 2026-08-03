import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'pantalla_confirmacion.dart';
import 'models/gasto_antiguo.dart';
import 'models/gasto_model.dart';
import 'gemma_service.dart';
import 'dart:convert';


class PantallaRegistroGasto extends ConsumerStatefulWidget {
  const PantallaRegistroGasto({super.key});

  @override
  ConsumerState<PantallaRegistroGasto> createState() => _PantallaRegistroGastoState();
}

class _PantallaRegistroGastoState extends ConsumerState<PantallaRegistroGasto> {
  final TextEditingController _controller = TextEditingController();
  bool _analizando = false;

  void _analizar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() => _analizando = true);

    debugPrint('\n====================================');
    debugPrint('🔵 INICIANDO ANÁLISIS DE GASTO');
    debugPrint('🔵 Texto del usuario: "$texto"');

    List<GastoModel> gastos = [];

    try {
      final jsonStr = await GemmaService.parsearGasto(texto);
      debugPrint('🔵 Resultado devuelto a main: $jsonStr');

      final lista = jsonDecode(jsonStr) as List;
      debugPrint('🔵 JSON decodificado exitosamente. Items: ${lista.length}');

      gastos = lista.map((g) => GastoModel(
        descripcion: g['d']?.toString() ?? '',
        monto: double.tryParse(g['m'].toString()) ?? 0.0,
        categoria: g['c']?.toString() ?? 'Otros',
        metodoPago: (g['me'] == 'C') ? 'Crédito' : 'Débito',
        tipoMovimiento: (g['t'] == 'I') ? 'Ingreso' : 'Gasto',
        cuotas: int.tryParse(g['cu'].toString()) ?? 1,
      )).toList();

      if (gastos.isEmpty) throw Exception('Sin gastos detectados en el JSON');

    } catch (e) {
      debugPrint('🔴🔴🔴 ERROR DETECTADO, SALTANDO A PLAN B (REGEX) 🔴🔴🔴');
      debugPrint('🔴 Motivo exacto del fallo: $e');

      final gastosViejos = parsearGastos(texto);
      gastos = gastosViejos.map((g) => GastoModel(
        descripcion: g.descripcion,
        monto: g.monto,
        categoria: g.categoria,
        metodoPago: g.metodoPago,
        tipoMovimiento: g.tipoMovimiento,
        cuotas: g.cuotas,
      )).toList();
    }

    if (!mounted) {
      setState(() => _analizando = false);
      return;
    }

    setState(() => _analizando = false);
    debugPrint('====================================\n');

    if (gastos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No detecté gastos. Intenta: "almuerzo 15k"')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PantallaConfirmacion(gastos: gastos)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo gasto'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe tu gasto:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: almuerzo 15k, taxi 8k',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _analizando ? null : _analizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _analizando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Analizar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}