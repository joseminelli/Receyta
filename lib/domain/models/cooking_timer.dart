import 'package:flutter/foundation.dart';

enum TimerPhase { running, paused, finished }

/// Um timer do modo cozinha. `key` identifica de onde veio ("cook" pro tempo
/// de cozimento da receita, "step-2-0" pro primeiro tempo do passo 3) — assim
/// o mesmo botão sabe se o timer dele já existe. `endsAt` só vale rodando;
/// parado, o que sobra está em `remaining`.
///
/// As transições (pausar, retomar, +tempo, repetir) vivem aqui, puras, porque
/// dois lugares precisam delas: a tela (via `CookingTimersNotifier`) e os
/// botões da notificação, que rodam com o app fechado, sem Riverpod.
@immutable
class CookingTimer {
  const CookingTimer({
    required this.id,
    required this.recipeId,
    this.recipeName = '',
    required this.label,
    required this.total,
    required this.remaining,
    required this.phase,
    this.key,
    this.endsAt,
    this.finishedAt,
  });

  final int id;
  final String recipeId;

  /// Nome da receita, pra faixa global dizer de qual é ("Frango · Passo 2").
  final String recipeName;
  final String? key;
  final String label;
  final Duration total;
  final Duration remaining;
  final TimerPhase phase;
  final DateTime? endsAt;
  final DateTime? finishedAt;

  bool get isRunning => phase == TimerPhase.running;
  bool get isFinished => phase == TimerPhase.finished;
  bool get isPaused => phase == TimerPhase.paused;

  /// "Frango ao curry · Passo 2" (ou só o rótulo, sem nome de receita).
  String get title =>
      [if (recipeName.isNotEmpty) recipeName, label].join(' · ');

  CookingTimer copyWith({
    Duration? remaining,
    TimerPhase? phase,
    DateTime? endsAt,
    bool clearEndsAt = false,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
  }) =>
      CookingTimer(
        id: id,
        recipeId: recipeId,
        recipeName: recipeName,
        key: key,
        label: label,
        total: total,
        remaining: remaining ?? this.remaining,
        phase: phase ?? this.phase,
        endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
        finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      );

  /// Rodando -> pausado, guardando o que falta. Os outros estados não mudam.
  CookingTimer paused(DateTime now) {
    if (!isRunning) return this;
    final left = endsAt!.difference(now);
    return copyWith(
      remaining: left.isNegative ? Duration.zero : left,
      phase: TimerPhase.paused,
      clearEndsAt: true,
    );
  }

  /// Pausado -> rodando, contando do que sobrava.
  CookingTimer resumed(DateTime now) {
    if (!isPaused) return this;
    return copyWith(phase: TimerPhase.running, endsAt: now.add(remaining));
  }

  /// Soma [by] ao que falta (rodando ou pausado). Pronto não muda: pra isso
  /// existe [restarted].
  CookingTimer extended(Duration by) {
    if (isRunning) {
      return copyWith(remaining: remaining + by, endsAt: endsAt!.add(by));
    }
    if (isPaused) return copyWith(remaining: remaining + by);
    return this;
  }

  /// Volta ao tempo inicial e roda de novo (também serve pra "mais uma vez"
  /// num timer que acabou).
  CookingTimer restarted(DateTime now) => copyWith(
        remaining: total,
        phase: TimerPhase.running,
        endsAt: now.add(total),
        clearFinishedAt: true,
      );

  /// Pra guardar no aparelho: o timer sobrevive ao app ser fechado ou morto
  /// em segundo plano (o horário de fim é o que manda).
  Map<String, Object?> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'key': key,
        'label': label,
        'total': total.inMilliseconds,
        'remaining': remaining.inMilliseconds,
        'phase': phase.name,
        'endsAt': endsAt?.millisecondsSinceEpoch,
        'finishedAt': finishedAt?.millisecondsSinceEpoch,
      };

  static CookingTimer? fromJson(Map<String, Object?> json) {
    try {
      DateTime? at(Object? ms) => ms == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true);
      return CookingTimer(
        id: json['id']! as int,
        recipeId: json['recipeId']! as String,
        recipeName: (json['recipeName'] as String?) ?? '',
        key: json['key'] as String?,
        label: json['label']! as String,
        total: Duration(milliseconds: json['total']! as int),
        remaining: Duration(milliseconds: json['remaining']! as int),
        phase: TimerPhase.values.byName(json['phase']! as String),
        endsAt: at(json['endsAt']),
        finishedAt: at(json['finishedAt']),
      );
    } catch (_) {
      return null; // registro estragado: ignora, não derruba o app
    }
  }
}
