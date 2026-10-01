import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Timers do modo cozinha como notificação do sistema: ficam à vista com o app
/// minimizado (relógio regressivo na própria notificação) e, na hora certa,
/// um aviso toca/vibra mesmo com o app em segundo plano ou fechado.
///
/// Interface pra o resto do app (e os testes) não falarem com o plugin. Os ids
/// são do timer; cada timer usa dois: o "em andamento" e o aviso final.
abstract class TimerNotifications {
  /// Prepara o plugin e os canais. Seguro chamar mais de uma vez.
  Future<void> init();

  /// Quando o usuário toca numa notificação com o app aberto/minimizado,
  /// recebe o id da receita (o `payload`).
  void onTapRecipe(void Function(String recipeId) callback);

  /// Pede (uma vez) a permissão de notificação e de alarme exato. Não bloqueia
  /// nem derruba nada se negada — só degrada o aviso.
  Future<void> requestPermissions();

  /// Timer rodando: mostra a notificação "em andamento" com o tempo
  /// regressivo e agenda o aviso final pra [endsAt].
  Future<void> showRunning({
    required int timerId,
    required String recipeId,
    required String title,
    required DateTime endsAt,
    required bool vibrate,
    required bool sound,
  });

  /// Timer pausado: notificação fixa com o que falta (sem aviso final).
  Future<void> showPaused({
    required int timerId,
    required String recipeId,
    required String title,
    required Duration remaining,
  });

  /// Tira as notificações do timer (a em andamento e o aviso agendado).
  Future<void> cancel(int timerId);
}

int _ongoingId(int timerId) => timerId * 2;
int _alarmId(int timerId) => timerId * 2 + 1;

class PluginTimerNotifications implements TimerNotifications {
  PluginTimerNotifications([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;
  void Function(String recipeId)? _onTap;

  static const _runningChannel = 'timer_running';

  /// Android fixa som e vibração no CANAL (não na notificação): um canal pra
  /// cada combinação das chaves de vibrar/som da faixa de timers.
  static String _alarmChannel({required bool vibrate, required bool sound}) =>
      'timer_alarm_${vibrate ? 'v' : ''}${sound ? 's' : ''}${!vibrate && !sound ? 'q' : ''}';

  static final _vibrationPattern =
      Int64List.fromList([0, 700, 300, 700, 300, 700]);

  @override
  Future<void> init() => _initializing ??= _doInit();

  Future<void> _doInit() async {
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id != null && id.isNotEmpty) _onTap?.call(id);
        },
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _runningChannel,
        'Timers em andamento',
        description: 'O relógio regressivo dos timers do modo cozinha.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ));
      for (final vibrate in [true, false]) {
        for (final sound in [true, false]) {
          await android?.createNotificationChannel(AndroidNotificationChannel(
            _alarmChannel(vibrate: vibrate, sound: sound),
            _alarmChannelName(vibrate: vibrate, sound: sound),
            description: 'Aviso de que um timer do modo cozinha acabou.',
            importance: Importance.max,
            playSound: sound,
            // O som do canal é que vale no Android 8+: no volume de ALARME,
            // como o alarme de dentro do app, não no de notificação.
            audioAttributesUsage: AudioAttributesUsage.alarm,
            enableVibration: vibrate,
            vibrationPattern: vibrate ? _vibrationPattern : null,
          ));
        }
      }
    } catch (e) {
      debugPrint('TimerNotifications.init: $e');
    }
  }

  static String _alarmChannelName(
      {required bool vibrate, required bool sound}) {
    if (vibrate && sound) return 'Timer acabou (vibra e toca)';
    if (vibrate) return 'Timer acabou (só vibra)';
    if (sound) return 'Timer acabou (só toca)';
    return 'Timer acabou (silencioso)';
  }

  @override
  void onTapRecipe(void Function(String recipeId) callback) =>
      _onTap = callback;

  @override
  Future<void> requestPermissions() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      if (await android?.canScheduleExactNotifications() == false) {
        await android?.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('TimerNotifications.requestPermissions: $e');
    }
  }

  @override
  Future<void> showRunning({
    required int timerId,
    required String recipeId,
    required String title,
    required DateTime endsAt,
    required bool vibrate,
    required bool sound,
  }) async {
    try {
      await init();
      final remaining = endsAt.difference(DateTime.now());
      if (remaining <= Duration.zero) return;

      // Em andamento: o próprio Android desconta o relógio (cronômetro
      // regressivo) e some sozinho no fim (`timeoutAfter`) — nada de ficar
      // atualizando a cada segundo com o app em segundo plano.
      await _plugin.show(
        _ongoingId(timerId),
        title,
        'Timer em andamento',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _runningChannel,
            'Timers em andamento',
            channelDescription:
                'O relógio regressivo dos timers do modo cozinha.',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            when: endsAt.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            timeoutAfter: remaining.inMilliseconds,
            category: AndroidNotificationCategory.progress,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: recipeId,
      );

      // Aviso final, na hora certa. Alarme exato se o usuário permitiu;
      // senão aproximado (pode atrasar em economia de energia).
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      await _plugin.zonedSchedule(
        _alarmId(timerId),
        'Pronto! $title',
        'O timer acabou — toque pra voltar à receita.',
        tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.UTC,
          endsAt.millisecondsSinceEpoch,
        ),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _alarmChannel(vibrate: vibrate, sound: sound),
            _alarmChannelName(vibrate: vibrate, sound: sound),
            channelDescription: 'Aviso de que um timer do modo cozinha acabou.',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            playSound: sound,
            enableVibration: vibrate,
            vibrationPattern: vibrate ? _vibrationPattern : null,
            autoCancel: true,
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: recipeId,
      );
    } catch (e) {
      debugPrint('TimerNotifications.showRunning: $e');
    }
  }

  @override
  Future<void> showPaused({
    required int timerId,
    required String recipeId,
    required String title,
    required Duration remaining,
  }) async {
    try {
      await init();
      // Pausado não avisa: tira o aviso agendado que houver.
      await _plugin.cancel(_alarmId(timerId));
      final total = remaining.inSeconds;
      final mm = (total ~/ 60).toString().padLeft(2, '0');
      final ss = (total % 60).toString().padLeft(2, '0');
      await _plugin.show(
        _ongoingId(timerId),
        title,
        'Pausado · faltam $mm:$ss',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _runningChannel,
            'Timers em andamento',
            channelDescription:
                'O relógio regressivo dos timers do modo cozinha.',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: recipeId,
      );
    } catch (e) {
      debugPrint('TimerNotifications.showPaused: $e');
    }
  }

  @override
  Future<void> cancel(int timerId) async {
    try {
      await _plugin.cancel(_ongoingId(timerId));
      await _plugin.cancel(_alarmId(timerId));
    } catch (e) {
      debugPrint('TimerNotifications.cancel: $e');
    }
  }
}

/// O serviço de verdade; os testes trocam por um falso.
final timerNotificationsProvider =
    Provider<TimerNotifications>((ref) => PluginTimerNotifications());
