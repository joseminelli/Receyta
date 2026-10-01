import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receyta_timer_card/receyta_timer_card.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:receyta/data/services/timer_notification_actions.dart';
import 'package:receyta/data/services/timers_store.dart';
import 'package:receyta/domain/models/cooking_timer.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/widgets/timer_card_image.dart';

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

  /// Desenha o card (cor e textura da receita, nome, rótulo) que a
  /// notificação do timer mostra expandida. Precisa do app vivo (usa o motor
  /// de desenho do Flutter); os botões, depois, só reaproveitam o arquivo.
  /// Sem o card a notificação funciona igual, só sem a imagem.
  Future<void> prepareCard(CookingTimer timer);

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

/// O `payload` leva a receita (pro toque) e o timer (pros botões).
String _payload(String recipeId, int timerId) => '$recipeId|$timerId';

({String recipeId, int timerId})? _parsePayload(String? payload) {
  if (payload == null) return null;
  final i = payload.lastIndexOf('|');
  if (i <= 0) return null;
  final timerId = int.tryParse(payload.substring(i + 1));
  if (timerId == null) return null;
  return (recipeId: payload.substring(0, i), timerId: timerId);
}

/// Um botão da notificação foi tocado: pausar/retomar/+1 min/parar/repetir,
/// sobre os timers guardados. Roda no isolate principal (app vivo em segundo
/// plano) ou no de segundo plano ([timerNotificationBackgroundHandler]).
Future<void> _runAction(NotificationResponse response) async {
  final actionId = response.actionId;
  final ref = _parsePayload(response.payload);
  if (actionId == null || actionId.isEmpty || ref == null) return;
  final notifications = PluginTimerNotifications();
  await notifications.init();
  await TimerNotificationActions(
    store: PrefsTimersStore(),
    notifications: notifications,
    alertFlags: () async {
      final s = await loadCookingAlertSettings();
      return (vibrate: s.vibrate, sound: s.sound);
    },
  ).handle(actionId: actionId, timerId: ref.timerId);
}

/// Ponto de entrada do isolate de segundo plano pros botões da notificação
/// (o app minimizado ou até fechado). Função de topo, de propósito: o Android
/// a chama pelo nome.
@pragma('vm:entry-point')
Future<void> timerNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  await _runAction(response);
}

class PluginTimerNotifications implements TimerNotifications {
  PluginTimerNotifications([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;
  void Function(String recipeId)? _onTap;

  static const _runningChannel = 'timer_running';

  /// Plugin nativo (`packages/receyta_timer_card`): o card da notificação.
  static const _cardChannel = MethodChannel(timerCardChannelName);

  /// Ícone da barra de status: silhueta própria (`res/drawable-*/ic_stat_receyta.png`, gerado de assets/brand/logoIcon.png por tool/gen_notification_icon.dart)
  /// — o ícone do app não serve, o Android o pinta como um bloco branco.
  static const _statusIcon = 'ic_stat_receyta';

  /// Cor de destaque da notificação (o `lime` da marca): tinge o ícone e o
  /// nome do app na gaveta.
  static const _accentArgb = 0xFFD6F45A;
  static const _accent = Color(_accentArgb);

  /// Imagem à esquerda da notificação: o cloche do Receyta em branco sobre o
  /// laranja da marca com a textura de arcos
  /// (`res/drawable-nodpi/ic_notification_large.png`, gerado por
  /// `tool/gen_notification_icon.dart`).
  static const _largeIcon =
      DrawableResourceAndroidBitmap('ic_notification_large');

  /// Botões. Os de ação não abrem o app (`showsUserInterface: false`): rodam
  /// em segundo plano sobre os timers guardados.
  static const _pauseAction = AndroidNotificationAction(
    kTimerActionPause,
    'Pausar',
    showsUserInterface: false,
    cancelNotification: false,
  );
  static const _resumeAction = AndroidNotificationAction(
    kTimerActionResume,
    'Retomar',
    showsUserInterface: false,
    cancelNotification: false,
  );
  static const _plusMinuteAction = AndroidNotificationAction(
    kTimerActionPlusMinute,
    '+1 min',
    showsUserInterface: false,
    cancelNotification: false,
  );
  static const _stopAction = AndroidNotificationAction(
    kTimerActionStop,
    'Parar',
    showsUserInterface: false,
    cancelNotification: true,
  );
  static const _restartAction = AndroidNotificationAction(
    kTimerActionRestart,
    'Repetir',
    showsUserInterface: false,
    cancelNotification: true,
  );

  static String _hhmm(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

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
          android: AndroidInitializationSettings(_statusIcon),
        ),
        onDidReceiveNotificationResponse: (response) {
          // Botão: mexe nos timers guardados. Toque no corpo: abre a receita.
          if (response.actionId != null && response.actionId!.isNotEmpty) {
            _runAction(response);
            return;
          }
          final ref = _parsePayload(response.payload);
          if (ref != null) _onTap?.call(ref.recipeId);
        },
        onDidReceiveBackgroundNotificationResponse:
            timerNotificationBackgroundHandler,
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
      // atualizando a cada segundo com o app em segundo plano. Primeiro o
      // card nativo; sem ele, a notificação comum.
      final native = await _showCard(
        timerId: timerId,
        recipeId: recipeId,
        title: title,
        running: true,
        remaining: remaining,
        actions: const [_pauseAction, _plusMinuteAction, _stopAction],
      );
      if (!native) {
        await _plugin.show(
          _ongoingId(timerId),
          title,
          'Termina às ${_hhmm(endsAt)}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _runningChannel,
              'Timers em andamento',
              channelDescription:
                  'O relógio regressivo dos timers do modo cozinha.',
              icon: _statusIcon,
              largeIcon: _largeIcon,
              color: _accent,
              actions: const [_pauseAction, _plusMinuteAction, _stopAction],
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
          payload: _payload(recipeId, timerId),
        );
      }

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
            icon: _statusIcon,
            largeIcon: _largeIcon,
            color: _accent,
            actions: const [_restartAction, _stopAction],
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
        payload: _payload(recipeId, timerId),
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
      final native = await _showCard(
        timerId: timerId,
        recipeId: recipeId,
        title: title,
        running: false,
        remaining: remaining,
        actions: const [_resumeAction, _plusMinuteAction, _stopAction],
      );
      if (native) return;
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
            icon: _statusIcon,
            largeIcon: _largeIcon,
            color: _accent,
            actions: [_resumeAction, _plusMinuteAction, _stopAction],
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: _payload(recipeId, timerId),
      );
    } catch (e) {
      debugPrint('TimerNotifications.showPaused: $e');
    }
  }

  @override
  Future<void> prepareCard(CookingTimer timer) async {
    try {
      final name = timer.recipeName.isEmpty ? timer.label : timer.recipeName;
      final collapsed = await renderCollapsedTimerBlock(
        recipeId: timer.recipeId,
        name: name,
        tileColor: timer.tileColor,
        tileMotif: timer.tileMotif,
      );
      final expanded = await renderExpandedTimerBlock(
        recipeId: timer.recipeId,
        name: name,
        tileColor: timer.tileColor,
        tileMotif: timer.tileMotif,
      );
      final dir = await _cardDir();
      await dir.create(recursive: true);
      if (collapsed != null) {
        await File(_cardPath(dir, timer.id, 'c'))
            .writeAsBytes(collapsed, flush: true);
      }
      if (expanded != null) {
        await File(_cardPath(dir, timer.id, 'e'))
            .writeAsBytes(expanded, flush: true);
      }
    } catch (e) {
      debugPrint('TimerNotifications.prepareCard: $e');
    }
  }

  Future<Directory> _cardDir() async =>
      Directory('${(await getTemporaryDirectory()).path}/timer_cards');

  String _cardPath(Directory dir, int timerId, String kind) =>
      '${dir.path}/${timerId}_$kind.png';

  /// "Frango · Passo 2" -> "Passo 2" (o painel do card mostra só o rótulo; o
  /// nome da receita já está no bloco colorido).
  static String _labelOf(String title) => title.split(' · ').last;

  /// Mostra a notificação com o layout nativo (relógio regressivo de verdade
  /// e botões). Devolve `false` se o plugin nativo não responder — aí quem
  /// chamou cai na notificação comum.
  Future<bool> _showCard({
    required int timerId,
    required String recipeId,
    required String title,
    required bool running,
    required Duration remaining,
    required List<AndroidNotificationAction> actions,
  }) async {
    try {
      final dir = await _cardDir();
      final collapsed = File(_cardPath(dir, timerId, 'c'));
      final expanded = File(_cardPath(dir, timerId, 'e'));
      await _cardChannel.invokeMethod<void>('show', {
        'id': _ongoingId(timerId),
        'channelId': _runningChannel,
        'payload': _payload(recipeId, timerId),
        'title': title,
        'label': _labelOf(title),
        'running': running,
        'remainingMs': remaining.inMilliseconds,
        'timeoutMs': running ? remaining.inMilliseconds : 0,
        'accent': _accentArgb,
        'smallIcon': _statusIcon,
        'collapsedImage': await collapsed.exists() ? collapsed.path : null,
        'expandedImage': await expanded.exists() ? expanded.path : null,
        'actions': [
          for (final a in actions)
            {
              'id': a.id,
              'title': a.title,
              'cancel': a.cancelNotification,
            },
        ],
      });
      return true;
    } catch (e) {
      debugPrint('TimerNotifications._showCard: $e');
      return false;
    }
  }

  @override
  Future<void> cancel(int timerId) async {
    try {
      await _plugin.cancel(_ongoingId(timerId));
      await _plugin.cancel(_alarmId(timerId));
      final dir = await _cardDir();
      for (final kind in ['c', 'e']) {
        final file = File(_cardPath(dir, timerId, kind));
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('TimerNotifications.cancel: $e');
    }
  }
}

/// O serviço de verdade; os testes trocam por um falso.
final timerNotificationsProvider =
    Provider<TimerNotifications>((ref) => PluginTimerNotifications());
