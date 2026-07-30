// lib/main.dart
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/material.dart';

import 'pantalla_inicio.dart';
import 'pantalla_carga.dart';
import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AHORA SÍ CON EL NOMBRE CORRECTO DEL MOTOR LITE RT
  await FlutterGemma.initialize(
    inferenceEngines: [LiteRtLmEngine()],
  );
  
  bool onboardingCompleto = await DatabaseHelper.esOnboardingCompleto();
  runApp(FinanzasApp(onboardingCompleto: onboardingCompleto));
}

class FinanzasApp extends StatelessWidget {
  final bool onboardingCompleto;
  
  // Recibe el parámetro obligatoriamente en el constructor
  const FinanzasApp({super.key, required this.onboardingCompleto});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // --- SOPORTE DE REGIONES PARA EL CALENDARIO ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español de España (Semana inicia el Lunes)
        Locale('es', 'US'), // Español de EE.UU./Latam (Semana inicia el Domingo)
      ],
      // Si ya hizo el onboarding, va al Dashboard. Si es nuevo, va a descargar la IA.
      home: onboardingCompleto ? const PantallaInicio() : const PantallaCarga(),
    );
  }
}