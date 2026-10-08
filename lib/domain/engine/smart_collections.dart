/// Coleções inteligentes: listas de receitas definidas por regra, calculadas na
/// hora a partir do que já existe (nada é gravado, nada fica desatualizado).
/// Dart puro.
library;

import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/domain/models/recipe.dart';

/// Até aqui (prep + cozimento, em minutos) a receita é "rápida".
const kQuickMinutes = 30;

/// Sem cozinhar nem abrir há tanto tempo, a receita vira "esquecida".
const kForgottenDays = 60;

/// "Mais feitas" pede ao menos isto de vezes cozinhada.
const kMostCookedMin = 2;

enum SmartCollection {
  quick('Rápidas', 'Até $kQuickMinutes minutos no total'),
  neverCooked('Nunca cozinhei', 'Salvas, mas ainda não feitas'),
  mostCooked('Mais feitas', 'As que você mais repete'),
  forgotten('Esquecidas', 'Sem abrir há mais de $kForgottenDays dias'),
  favorites('Favoritas', 'As que você marcou com o coração');

  const SmartCollection(this.title, this.description);

  final String title;
  final String description;

  static SmartCollection? fromName(String? name) {
    for (final c in values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// Quantas vezes e quando foi a última vez que a receita foi cozinhada.
class CookStats {
  const CookStats({required this.count, required this.lastCookedAt});

  final int count;
  final DateTime lastCookedAt;
}

Map<String, CookStats> cookStatsOf(Iterable<CookLog> logs) {
  final out = <String, CookStats>{};
  for (final l in logs) {
    final prev = out[l.recipeId];
    out[l.recipeId] = CookStats(
      count: (prev?.count ?? 0) + 1,
      lastCookedAt: prev == null || l.cookedAt.isAfter(prev.lastCookedAt)
          ? l.cookedAt
          : prev.lastCookedAt,
    );
  }
  return out;
}

int? _totalMinutes(Recipe r) {
  final total = (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0);
  return total == 0 ? null : total;
}

/// Última vez que a receita foi cozinhada, aberta ou, na falta de ambos,
/// criada.
DateTime _lastTouched(Recipe r, CookStats? stats) {
  var last = r.createdAt;
  final opened = r.lastOpenedAt;
  if (opened != null && opened.isAfter(last)) last = opened;
  final cooked = stats?.lastCookedAt;
  if (cooked != null && cooked.isAfter(last)) last = cooked;
  return last;
}

/// As receitas de [collection], já na ordem em que fazem sentido (a mais
/// rápida primeiro, a mais repetida primeiro...).
List<Recipe> recipesIn(
  SmartCollection collection,
  List<Recipe> recipes,
  Map<String, CookStats> stats,
  DateTime now,
) {
  switch (collection) {
    case SmartCollection.quick:
      final out = [
        for (final r in recipes)
          if ((_totalMinutes(r) ?? kQuickMinutes + 1) <= kQuickMinutes) r,
      ];
      out.sort((a, b) => _totalMinutes(a)!.compareTo(_totalMinutes(b)!));
      return out;

    case SmartCollection.neverCooked:
      return [
        for (final r in recipes)
          if (!stats.containsKey(r.id)) r,
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    case SmartCollection.mostCooked:
      final out = [
        for (final r in recipes)
          if ((stats[r.id]?.count ?? 0) >= kMostCookedMin) r,
      ];
      out.sort((a, b) {
        final byCount = stats[b.id]!.count.compareTo(stats[a.id]!.count);
        return byCount != 0
            ? byCount
            : stats[b.id]!.lastCookedAt.compareTo(stats[a.id]!.lastCookedAt);
      });
      return out;

    case SmartCollection.forgotten:
      final cutoff = now.subtract(const Duration(days: kForgottenDays));
      return [
        for (final r in recipes)
          if (_lastTouched(r, stats[r.id]).isBefore(cutoff)) r,
      ]..sort((a, b) =>
          _lastTouched(a, stats[a.id]).compareTo(_lastTouched(b, stats[b.id])));

    case SmartCollection.favorites:
      return [
        for (final r in recipes)
          if (r.isFavorite) r,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}

/// Todas as coleções que têm pelo menos uma receita, na ordem do enum.
Map<SmartCollection, List<Recipe>> buildSmartCollections(
  List<Recipe> recipes,
  Iterable<CookLog> logs,
  DateTime now,
) {
  final stats = cookStatsOf(logs);
  final out = <SmartCollection, List<Recipe>>{};
  for (final c in SmartCollection.values) {
    final list = recipesIn(c, recipes, stats, now);
    if (list.isNotEmpty) out[c] = list;
  }
  return out;
}
