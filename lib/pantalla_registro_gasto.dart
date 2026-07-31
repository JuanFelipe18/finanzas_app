// lib/pantalla_registro_gasto.dart
import 'package:flutter/material.dart';
import 'dart:convert';

import 'gemma_service.dart';
import 'models/gasto_antiguo.dart'; // Aquí vive ahora tu clase Gasto y tu parsearGastos (Regex)
import 'pantalla_confirmacion.dart';

class PantallaRegistroGasto extends StatefulWidget {
  const PantallaRegistroGasto({super.key});

  @override
  State<PantallaRegistroGasto> createState() => _PantallaRegistroGastoState();
}

class _PantallaRegistroGastoState extends State<PantallaRegistroGasto> {
  final TextEditingController _controller = TextEditingController();
  bool _analizando = false;

  void _analizar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() => _analizando = true);
    
    debugPrint('\n====================================');
    debugPrint('🔵 INICIANDO ANÁLISIS DE GASTO');
    debugPrint('🔵 Texto del usuario: "$texto"');
    
    try {
      final jsonStr = await GemmaService.parsearGasto(texto);
      debugPrint('🔵 Resultado devuelto a main: $jsonStr');
      
      final lista = jsonDecode(jsonStr) as List;
      debugPrint('🔵 JSON decodificado exitosamente. Items: ${lista.length}');
      
      final gastos = lista.map((g) {
        return Gasto(
          descripcion: g['d']?.toString() ?? '',
          monto: double.tryParse(g['m'].toString()) ?? 0.0, 
          categoria: g['c']?.toString() ?? 'Otros',
          metodoPago: (g['me'] == 'C') ? 'Crédito' : 'Débito', 
          tipoMovimiento: (g['t'] == 'I') ? 'Ingreso' : 'Gasto', // <-- Leemos 'I' o 'G'
          cuotas: int.tryParse(g['cu'].toString()) ?? 1,         // <-- Leemos las cuotas
        );
      }).toList();
      
      if (gastos.isEmpty) throw Exception('Sin gastos detectados en el JSON');

      if (!mounted) return; // <-- Corrección de linter

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PantallaConfirmacion(gastos: gastos)),
      );
      
    } catch (e, stacktrace) {
      // Este bloque atrapa cualquier fallo de la IA o de decodificación JSON
      debugPrint('🔴🔴🔴 ERROR DETECTADO, SALTANDO A PLAN B (REGEX) 🔴🔴🔴');
      debugPrint('🔴 Motivo exacto del fallo: $e');
      debugPrint('🔴 Ruta del error (Stacktrace): \n$stacktrace'); 
      
      // Fallback al parser regex tradicional (ahora importado desde models/gasto.dart)
      final gastos = parsearGastos(texto);
      
      if (!mounted) return; // <-- Corrección de linter

      if (gastos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No detecté gastos. Intenta: "almuerzo 15k"')),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PantallaConfirmacion(gastos: gastos)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _analizando = false);
      }
      debugPrint('====================================\n');
    }
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