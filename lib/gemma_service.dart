import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/foundation.dart';
import 'database.dart';

class GemmaService {
  static const _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  static InferenceModel? _model;

  static String categoriasEnRAM = "Alimentación, Transporte, Salud, Entretenimiento, Hogar, Ropa, Educación, Otros";

  // Mensaje de prueba: cubre gasto compartido, jerga de montos ("lucas", "k",
  // separador de miles con punto), crédito implícito vs explícito, monto
  // ambiguo, recarga, e ingreso por reembolso. Útil para validar el parser
  // end-to-end sin depender de que el usuario escriba algo complejo primero.
  static const String textoDePrueba =
      "ayer fui a almorzar con mi hermano y pagué yo, fueron como 45 lucas "
      "pero yo puse 30 y él me debe el resto, ahí pagué con la tarjeta de "
      "crédito del bbva. después en la tarde compré unas onces, un pan y un "
      "café, como 8mil, eso sí fue en efectivo. en la noche pedí una "
      "hamburguesa por rappi que salió en 62.500. hoy en la mañana recargué "
      "la tarjeta del transmilenio con 25000 desde la app, y ahora al "
      "mediodía tomé un uber a la oficina que costó 12300 y otro de vuelta "
      "que no me acuerdo bien si fueron 11 o 13 mil, pagué con la de "
      "débito. ah y se me olvidaba, el viernes había comprado unos tenis "
      "pero los devolví y me reembolsaron 180.000 a la tarjeta";

  static Future<void> refrescarCacheCategorias() async {
    final lista = await DatabaseHelper.obtenerCategorias();

    if (lista.isNotEmpty) {
      categoriasEnRAM = lista.map((c) => c['nombre']).join(', ');
    }
  }

  // Agregamos el parámetro onProgress
  static Future<void> init({Function(int)? onProgress}) async {
    if (_model != null) return;

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,       // <-- CAMBIO 1: Arquitectura exacta
        fileType: ModelFileType.litertlm,  // <-- CAMBIO 2: Etiqueta para el motor de C++
      )
          .fromNetwork(
            'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
            token: _hfToken,
          )
          .withProgress((progress) {
            debugPrint('Descargando: $progress%');
            if (onProgress != null) onProgress(progress);
          })
          .install();

      _model = await FlutterGemma.getActiveModel(maxTokens: 2048);
      debugPrint('✅ Gemma listo');
    } catch (e) {
      debugPrint('❌ Error Gemma: $e');
    }
  }

  static Future<String> parsearGasto(String texto) async {
    if (_model == null) {
      await init();

      if (_model == null) throw Exception('Modelo no cargado.');
    }

    final session = await _model!.createSession(
      maxOutputTokens: 256,
      temperature: 0.1,
    );

    try {
      final promptOptimizado = '''Extrae movimientos financieros del texto en JSON. Sin movimientos: [].
      Reglas:
      -Un objeto por movimiento, nunca combines.
      -d: palabra clave del texto, max 2 palabras.
      -m: entero. "mil"/"lucas"/"k"=x1000. Punto en miles no es decimal (62.500=62500). Monto incierto: usa el mayor.
      -t: "G" gasto, "I" ingreso (reembolso/devolución/pago recibido).
      -c: una de [$categoriasEnRAM] o "Otros".
      -me: "C" si dice "crédito"/"tarjeta crédito" o nombra banco sin especificar débito. "D" si dice débito/efectivo/transferencia o no se menciona.
      -cu: Si me="C" y menciona meses/cuotas, pon el número. Si no, 1.
      -Compartido: usa solo la parte del usuario.
      -Recarga: gasto normal en su categoría.
      -FUTURO: ignora cosas que no han pasado ("voy a comprar", "tengo que pagar"). Solo extrae pagos reales ya hechos.

      Ej: "cine 30k, luz 40mil credito a 2 cuotas, devolvieron 20mil tenis, mañana pago 50k arriendo" -> [{"d":"cine","m":30000,"t":"G","c":"Entretenimiento","me":"D","cu":1},{"d":"luz","m":40000,"t":"G","c":"Hogar","me":"C","cu":2},{"d":"tenis","m":20000,"t":"I","c":"Otros","me":"D","cu":1}]

      Texto: "$texto"''';

      await session.addQueryChunk(Message(
        text: promptOptimizado,
        isUser: true,
      ));

      final DateTime inicio = DateTime.now();
      String response = await session.getResponse();
      final DateTime fin = DateTime.now();

      final duracionMs = fin.difference(inicio).inMilliseconds;
      debugPrint("GEMMA_TIMING|inicio=${inicio.toIso8601String()}|fin=${fin.toIso8601String()}|duracion_ms=$duracionMs|input_len=${promptOptimizado.length}|output_len=${response.length}");

      // Buscamos un Array [ ] o un Objeto individual { }
      final regexJson = RegExp(r'\[.*\]|\{.*\}', dotAll: true);
      final match = regexJson.firstMatch(response);

      if (match != null) {
        String jsonLimpio = match.group(0)!;

        // Si la IA nos devolvió un solo gasto sin la lista, nosotros le ponemos los corchetes
        if (jsonLimpio.startsWith('{')) {
          jsonLimpio = '[$jsonLimpio]';
        }

        return jsonLimpio;
      } else {
        throw Exception('Gemma no respondió con JSON.');
      }
    } catch (e) {
      rethrow;
    } finally {
      await session.close();
    }
  }

  // Atajo para probar el parser con el mensaje de prueba sin tener que
  // escribirlo a mano en la UI cada vez.
  static Future<String> parsearGastoDePrueba() => parsearGasto(textoDePrueba);
}