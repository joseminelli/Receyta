import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/domain/models/cooking_timer.dart';

/// `TimerNotifications` de teste: sem plugin, só anota o que foi pedido.
/// `calls` guarda `init`, `permissions`, `running:<id>`, `paused:<id>` e
/// `cancel:<id>`; `lastRunning` guarda os detalhes do último `showRunning`.
class FakeTimerNotifications implements TimerNotifications {
  final calls = <String>[];
  final runningDetails = <int, FakeRunning>{};
  final pausedDetails = <int, FakePaused>{};
  void Function(String recipeId)? tapCallback;

  @override
  Future<void> init() async => calls.add('init');

  @override
  void onTapRecipe(void Function(String recipeId) callback) =>
      tapCallback = callback;

  @override
  Future<void> requestPermissions() async => calls.add('permissions');

  @override
  Future<void> prepareCard(CookingTimer timer) async =>
      calls.add('card:${timer.id}');

  @override
  Future<void> showRunning({
    required int timerId,
    required String recipeId,
    required String title,
    required DateTime endsAt,
    required bool vibrate,
    required bool sound,
  }) async {
    calls.add('running:$timerId');
    runningDetails[timerId] = FakeRunning(
      recipeId: recipeId,
      title: title,
      endsAt: endsAt,
      vibrate: vibrate,
      sound: sound,
    );
  }

  @override
  Future<void> showPaused({
    required int timerId,
    required String recipeId,
    required String title,
    required Duration remaining,
  }) async {
    calls.add('paused:$timerId');
    pausedDetails[timerId] = FakePaused(
      recipeId: recipeId,
      title: title,
      remaining: remaining,
    );
  }

  @override
  Future<void> cancel(int timerId) async => calls.add('cancel:$timerId');
}

class FakeRunning {
  const FakeRunning({
    required this.recipeId,
    required this.title,
    required this.endsAt,
    required this.vibrate,
    required this.sound,
  });

  final String recipeId;
  final String title;
  final DateTime endsAt;
  final bool vibrate;
  final bool sound;
}

class FakePaused {
  const FakePaused({
    required this.recipeId,
    required this.title,
    required this.remaining,
  });

  final String recipeId;
  final String title;
  final Duration remaining;
}
