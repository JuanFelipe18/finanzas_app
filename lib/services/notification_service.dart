import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/fijo_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Pedir permiso en Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> programarRecordatorioFijo(FijoModel fijo) async {
    if (!fijo.tieneRecordatorio || fijo.id == null) return;

    final id = fijo.id!;

    // Cancelar notificación anterior si existe
    await _plugin.cancel(id);

    final fechaNotificacion = _calcularProximaFecha(
      fijo.fechaPago!,
      fijo.recordatorioDias,
    );

    if (fechaNotificacion == null) return;

    await _plugin.zonedSchedule(
      id,
      '💳 Recordatorio de pago',
      '${fijo.descripcion}: \$${fijo.monto.toStringAsFixed(0)} vence el día ${fijo.fechaPago}',
      fechaNotificacion,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios_fijos',
          'Recordatorios de gastos fijos',
          channelDescription: 'Notificaciones para recordar pagos de suscripciones y servicios',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static Future<void> cancelarRecordatorio(int fijoId) async {
    await _plugin.cancel(fijoId);
  }

  static Future<void> reprogramarTodos(List<FijoModel> fijos) async {
    for (final f in fijos) {
      if (f.tieneRecordatorio) {
        await programarRecordatorioFijo(f);
      }
    }
  }

  static tz.TZDateTime? _calcularProximaFecha(int diaDelMes, int diasAntes) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime fechaPago = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      diaDelMes,
      9, // 9:00 AM
      0,
    );

    // Si ya pasó este mes, ir al siguiente
    if (fechaPago.isBefore(now)) {
      fechaPago = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        diaDelMes,
        9,
        0,
      );
    }

    // Restar los días de anticipación
    final fechaNotificacion = fechaPago.subtract(Duration(days: diasAntes));

    // Si la fecha de notificación ya pasó, saltar al siguiente mes
    if (fechaNotificacion.isBefore(now)) {
      final siguienteMes = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        diaDelMes,
        9,
        0,
      );
      return siguienteMes.subtract(Duration(days: diasAntes));
    }

    return fechaNotificacion;
  }
}