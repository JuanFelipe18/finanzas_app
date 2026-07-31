import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import 'gemma_service.dart';

class PantallaCarga extends StatefulWidget {
  const PantallaCarga({super.key});

  @override
  State<PantallaCarga> createState() => _PantallaCargaState();
}

class _PantallaCargaState extends State<PantallaCarga> {
  int _progreso = 0;

  @override
  void initState() {
    super.initState();
    _iniciarIA();
  }

    Future<void> _iniciarIA() async {
    try {
      await GemmaService.init(
        onProgress: (progreso) {
          if (mounted) setState(() => _progreso = progreso);
        },
      );
    } catch (e) {
      debugPrint('⚠️ Gemma no pudo inicializarse: $e');
      // La app funciona perfectamente sin IA (usa el regex fallback)
    }

    // Siempre avanzamos al onboarding, haya IA o no
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaOnboarding()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¡Bienvenido a FinanApp! 👋',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 48),
              const Icon(Icons.smart_toy, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Descargando tu Asistente Privado...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Este proceso descarga la Inteligencia Artificial a tu celular (aprox 2.5GB). Solo se hace hoy y garantizará que tus finanzas sean 100% privadas y funcionen sin internet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              LinearProgressIndicator(
                value: _progreso / 100,
                backgroundColor: Colors.green.shade200,
                color: Colors.green,
                minHeight: 12,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 16),
              Text('$_progreso%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }
}