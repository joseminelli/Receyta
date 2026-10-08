/// Retrospectiva: o resumo do que você cozinhou num mês ou num ano, calculado
/// só a partir do histórico "Cozinhei!" e das receitas. Dart puro; nada é
/// gravado.
library;

import 'package:flutter/foundation.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/cook_log.dart';

enum RetroKind { month, year }

/// Um mês ou um ano de calendário, em hora local.
@immutable
class RetroPeriod {
  const RetroPeriod(this.kind, this.start);

  factory RetroPeriod.monthOf(DateTime d) =>
      RetroPeriod(RetroKind.month, DateTime(d.year, d.month));

  factory RetroPeriod.yearOf(DateTime d) =>
      RetroPeriod(RetroKind.year, DateTime(d.year));

  final RetroKind kind;

  /// Primeiro instante do período (meia-noite local).
  final DateTime start;

  /// Primeiro instante depois do período.
  DateTime get end => kind == RetroKind.month
      ? DateTime(start.year, start.month + 1)
      : DateTime(start.year + 1);

  bool contains(DateTime moment) {
    final local = moment.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  /// [n] períodos pra frente (negativo volta).
  RetroPeriod shift(int n) => kind == RetroKind.month
      ? RetroPeriod(kind, DateTime(start.year, start.month + n))
      : RetroPeriod(kind, DateTime(start.year + n));

  /// O mesmo tipo de período que contém [moment].
  RetroPeriod containing(DateTime moment) => kind == RetroKind.month
      ? RetroPeriod.monthOf(moment)
      : RetroPeriod.yearOf(moment);

  /// "Outubro 2026" ou "2026".
  String get label => kind == RetroKind.month
      ? '${monthLong(start)} ${start.year}'
      : '${start.year}';

  /// "outubro" ou "2026": como entra numa frase ("em outubro").
  String get inSentence => kind == RetroKind.month
      ? monthLong(start).toLowerCase()
      : '${start.year}';

  @override
  bool operator ==(Object other) =>
      other is RetroPeriod && other.kind == kind && other.start == start;

  @override
  int get hashCode => Object.hash(kind, start);
}

/// O que a retrospectiva precisa saber de uma receita.
@immutable
class RetroRecipe {
  const RetroRecipe({
    required this.id,
    required this.name,
    required this.createdAt,
    this.minutes = 0,
    this.tags = const [],
    this.tileColor,
    this.tileMotif,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// Preparo + cozimento, em minutos (0 = a receita não diz).
  final int minutes;
  final List<String> tags;
  final TileColor? tileColor;
  final TileMotif? tileMotif;
}

class RetroTopRecipe {
  const RetroTopRecipe({
    required this.id,
    required this.name,
    required this.times,
    this.tileColor,
    this.tileMotif,
  });

  final String id;
  final String name;
  final int times;
  final TileColor? tileColor;
  final TileMotif? tileMotif;
}

class RetroTopTag {
  const RetroTopTag({required this.name, required this.times});

  final String name;
  final int times;
}

class Retrospective {
  const Retrospective({
    required this.period,
    required this.cookCount,
    required this.distinctRecipes,
    required this.totalMinutes,
    required this.bestStreak,
    required this.newRecipes,
    this.topRecipe,
    this.topTag,
    this.busiestWeekday,
  });

  final RetroPeriod period;

  /// Quantos "Cozinhei!" caem no período.
  final int cookCount;
  final int distinctRecipes;

  /// Soma de preparo + cozimento de cada vez que cozinhou.
  final int totalMinutes;

  /// Mais dias seguidos cozinhando.
  final int bestStreak;

  /// Receitas salvas dentro do período.
  final int newRecipes;
  final RetroTopRecipe? topRecipe;
  final RetroTopTag? topTag;

  /// 1 = segunda ... 7 = domingo.
  final int? busiestWeekday;

  bool get isEmpty => cookCount == 0;
}

/// Monta a retrospectiva de [period]. Receita que sumiu de [recipes] (apagada)
/// ainda conta como vez cozinhada, só sem tempo nem tag.
Retrospective buildRetrospective({
  required RetroPeriod period,
  required Iterable<CookLog> logs,
  required Map<String, RetroRecipe> recipes,
}) {
  final inPeriod = [
    for (final l in logs)
      if (period.contains(l.cookedAt)) l,
  ];
  final newRecipes = recipes.values.where((r) => period.contains(r.createdAt));

  if (inPeriod.isEmpty) {
    return Retrospective(
      period: period,
      cookCount: 0,
      distinctRecipes: 0,
      totalMinutes: 0,
      bestStreak: 0,
      newRecipes: newRecipes.length,
    );
  }

  final timesByRecipe = <String, int>{};
  final lastByRecipe = <String, DateTime>{};
  var minutes = 0;
  final weekdayCount = <int, int>{};
  final tagCount = <String, int>{};
  final days = <int>{};

  for (final l in inPeriod) {
    timesByRecipe.update(l.recipeId, (n) => n + 1, ifAbsent: () => 1);
    final last = lastByRecipe[l.recipeId];
    if (last == null || l.cookedAt.isAfter(last)) {
      lastByRecipe[l.recipeId] = l.cookedAt;
    }

    final recipe = recipes[l.recipeId];
    minutes += recipe?.minutes ?? 0;
    for (final tag in recipe?.tags ?? const <String>[]) {
      tagCount.update(tag, (n) => n + 1, ifAbsent: () => 1);
    }

    final local = l.cookedAt.toLocal();
    weekdayCount.update(local.weekday, (n) => n + 1, ifAbsent: () => 1);
    days.add(dayIndex(DateTime.utc(local.year, local.month, local.day)));
  }

  final topId = (timesByRecipe.keys.toList()
        ..sort((a, b) {
          final byTimes = timesByRecipe[b]!.compareTo(timesByRecipe[a]!);
          return byTimes != 0
              ? byTimes
              : lastByRecipe[b]!.compareTo(lastByRecipe[a]!);
        }))
      .first;
  final topRecipeInfo = recipes[topId];
  final topName = topRecipeInfo?.name ??
      inPeriod.firstWhere((l) => l.recipeId == topId).recipeName;

  RetroTopTag? topTag;
  if (tagCount.isNotEmpty) {
    final names = tagCount.keys.toList()
      ..sort((a, b) {
        final byCount = tagCount[b]!.compareTo(tagCount[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    topTag = RetroTopTag(name: names.first, times: tagCount[names.first]!);
  }

  final weekdays = weekdayCount.keys.toList()
    ..sort((a, b) {
      final byCount = weekdayCount[b]!.compareTo(weekdayCount[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });

  return Retrospective(
    period: period,
    cookCount: inPeriod.length,
    distinctRecipes: timesByRecipe.length,
    totalMinutes: minutes,
    bestStreak: _longestRun(days),
    newRecipes: newRecipes.length,
    topRecipe: RetroTopRecipe(
      id: topId,
      name: topName,
      times: timesByRecipe[topId]!,
      tileColor: topRecipeInfo?.tileColor,
      tileMotif: topRecipeInfo?.tileMotif,
    ),
    topTag: topTag,
    busiestWeekday: weekdays.first,
  );
}

int _longestRun(Set<int> dayIndexes) {
  final sorted = dayIndexes.toList()..sort();
  var best = 0;
  var run = 0;
  int? prev;
  for (final d in sorted) {
    run = (prev != null && d == prev + 1) ? run + 1 : 1;
    if (run > best) best = run;
    prev = d;
  }
  return best;
}

/// "45 min", "2 h", "14 h 30 min".
String formatCookingTime(int minutes) {
  if (minutes <= 0) return '0 min';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

const _weekdayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// "Domingo" pra 7.
String retroWeekdayName(int weekday) => _weekdayNames[weekday - 1];
