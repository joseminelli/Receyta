import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:receyta/data/services/timer_notifications.dart';

/// Lembretes locais do app (G5): notificações agendadas, sem servidor. Cada
/// tipo tem um id fixo — reagendar um tipo substitui o anterior, e desligar
/// cancela. Fica atrás de uma interface pra os testes não falarem com o plugin.
abstract class ReminderNotifications {
  /// Pede a permissão de notificação. Só é chamada quando a pessoa liga o
  /// primeiro lembrete, nunca na abertura do app. `true` se concedida.
  Future<bool> requestPermission();

  /// Agenda "planejar a semana" toda [weekday] (1 = segunda … 7 = domingo) às
  /// [minutes] (desde a meia-noite, hora local), substituindo o anterior.
  Future<void> schedulePlanWeek({required int weekday, required int minutes});

  Future<void> cancelPlanWeek();
}

const _planWeekId = 900001;
const _channelId = 'reminders';

/// Próxima ocorrência de [weekday] às [minutes], hora local, depois de [now].
DateTime nextWeekly(DateTime now,
    {required int weekday, required int minutes}) {
  final local = now.toLocal();
  var day = DateTime(local.year, local.month, local.day);
  while (day.weekday != weekday) {
    day = day.add(const Duration(days: 1));
  }
  var at = day.add(Duration(minutes: minutes));
  if (!at.isAfter(local)) at = at.add(const Duration(days: 7));
  return at;
}

class PluginReminderNotifications implements ReminderNotifications {
  PluginReminderNotifications(this._timers,
      [FlutterLocalNotificationsPlugin? p])
      : _plugin = p ?? FlutterLocalNotificationsPlugin();

  final TimerNotifications _timers;
  final FlutterLocalNotificationsPlugin _plugin;
  bool _channelReady = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// O plugin é um só no app: quem o inicializa é o serviço dos timers (com
  /// os toques e botões dele). Aqui só garante isso e cria o canal próprio.
  Future<void> _ready() async {
    await _timers.init();
    if (_channelReady) return;
    await _android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'Lembretes',
      description: 'Lembretes que você liga nas configurações.',
      importance: Importance.defaultImportance,
    ));
    _channelReady = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _ready();
      return await _android?.requestNotificationsPermission() ?? true;
    } catch (e) {
      debugPrint('ReminderNotifications.requestPermission: $e');
      return false;
    }
  }

  @override
  Future<void> schedulePlanWeek({
    required int weekday,
    required int minutes,
  }) async {
    try {
      await _ready();
      final at = nextWeekly(DateTime.now(), weekday: weekday, minutes: minutes);
      await _plugin.zonedSchedule(
        _planWeekId,
        'Hora de planejar a semana',
        'Escolha o que cozinhar em cada dia.',
        tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.UTC,
          at.toUtc().millisecondsSinceEpoch,
        ),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Lembretes',
            channelDescription: 'Lembretes que você liga nas configurações.',
            icon: 'ic_stat_receyta',
            color: Color(0xFFD6F45A),
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder:planWeek',
      );
    } catch (e) {
      debugPrint('ReminderNotifications.schedulePlanWeek: $e');
    }
  }

  @override
  Future<void> cancelPlanWeek() async {
    try {
      await _plugin.cancel(_planWeekId);
    } catch (e) {
      debugPrint('ReminderNotifications.cancelPlanWeek: $e');
    }
  }
}

final reminderNotificationsProvider = Provider<ReminderNotifications>(
  (ref) => PluginReminderNotifications(ref.watch(timerNotificationsProvider)),
);
