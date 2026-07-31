import 'package:flutter/material.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pantalla_inicio.dart';
import 'pantalla_carga.dart';
import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterGemma.initialize(
    inferenceEngines: [LiteRtLmEngine()],
  );

  bool onboardingCompleto = await DatabaseHelper.esOnboardingCompleto();

  runApp(
    ProviderScope( // <-- NUEVO: Envuelve toda la app
      child: FinanzasApp(onboardingCompleto: onboardingCompleto),
    ),
  );
}

class FinanzasApp extends StatelessWidget {
  final bool onboardingCompleto;

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('es', 'US'),
      ],
      home: onboardingCompleto ? const PantallaInicio() : const PantallaCarga(),
    );
  }
}