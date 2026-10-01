import 'dart:math' as math;

/// Similaridade entre receitas por ingredientes em comum, com peso IDF
/// (§8.3). Dart puro, sem banco: quem chama monta o catálogo
/// (`recipeId → ids de ingrediente`) e recebe sugestões prontas — a sugestão no
/// calendário (F5) e a de "tenho X, Y, Z" (G12) usam este mesmo motor.

/// Abaixo disto o IDF ainda não tem sinal (quase tudo é "raro"): cai pra peso
/// uniforme, que vira o Jaccard clássico.
const kMinRecipesForIdf = 20;

/// Quanto a nota cai pra uma receita agendada nos últimos [kRecentDays] dias
/// — pra não sugerir sempre a mesma coisa.
const kRecentPenalty = 0.4;
const kRecentDays = 14;

/// Pesos por ingrediente. `uniform` = base pequena demais, todo mundo pesa 1.
class IdfWeights {
  const IdfWeights._(
    this._weights,
    this._unknownWeight, {
    required this.uniform,
  });

  const IdfWeights.uniform() : this._(const {}, 1, uniform: true);

  final Map<String, double> _weights;
  final double _unknownWeight;
  final bool uniform;

  /// Ingrediente que nenhuma receita do catálogo usa (só pode vir do alvo)
  /// pesa como o mais raro possível: `ln(total)`.
  double weightOf(String ingredientId) =>
      uniform ? 1 : (_weights[ingredientId] ?? _unknownWeight);
}

/// Peso de cada ingrediente: `ln(total / (1 + receitas que usam))`, nunca
/// negativo — o que está em (quase) todas as receitas, como o sal, pesa 0 e
/// some do cálculo; o raro pesa muito. Com menos de [minRecipes] receitas, peso
/// uniforme.
IdfWeights computeIdf(
  List<Set<String>> recipes, {
  int minRecipes = kMinRecipesForIdf,
}) {
  if (recipes.length < minRecipes) return const IdfWeights.uniform();
  final counts = <String, int>{};
  for (final r in recipes) {
    for (final i in r) {
      counts.update(i, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final total = recipes.length;
  return IdfWeights._(
    {
      for (final e in counts.entries)
        e.key: math.max(0.0, math.log(total / (1 + e.value))),
    },
    math.log(total.toDouble()),
    uniform: false,
  );
}

/// `Σ peso(A∩B) / Σ peso(A∪B)` — 1 pra conjuntos iguais, 0 sem nada em
/// comum. Peso total zero (só ingredientes que estão em tudo) devolve 0.
double weightedJaccard(Set<String> a, Set<String> b, IdfWeights weights) {
  var inter = 0.0;
  var union = 0.0;
  for (final i in a) {
    final w = weights.weightOf(i);
    union += w;
    if (b.contains(i)) inter += w;
  }
  for (final i in b) {
    if (!a.contains(i)) union += weights.weightOf(i);
  }
  return union <= 0 ? 0 : inter / union;
}

/// Uma receita sugerida: a nota e *por que* — os ingredientes em comum com o
/// alvo, do mais informativo (raro) pro menos, sem os de peso zero.
class RecipeSuggestion {
  const RecipeSuggestion({
    required this.recipeId,
    required this.score,
    required this.sharedIngredientIds,
  });

  final String recipeId;
  final double score;
  final List<String> sharedIngredientIds;
}

/// Receitas do [catalog] ordenadas por quanto se parecem com o [target] (o
/// conjunto de ingredientes que você já vai comprar). Fora da lista:
/// [excludeRecipeIds] (já agendadas), as sem nada em comum e as de nota zero.
/// Agendada nos últimos [kRecentDays] dias (em [lastScheduled]) tem a nota
/// multiplicada por [kRecentPenalty]. Empate desempata pelo id, pra ordem ser
/// estável.
List<RecipeSuggestion> suggestRecipes({
  required Map<String, Set<String>> catalog,
  required Set<String> target,
  Set<String> excludeRecipeIds = const {},
  Map<String, DateTime> lastScheduled = const {},
  required DateTime now,
  int limit = 5,
}) {
  if (target.isEmpty) return const [];
  final weights = computeIdf(catalog.values.toList());
  final out = <RecipeSuggestion>[];

  for (final entry in catalog.entries) {
    if (excludeRecipeIds.contains(entry.key)) continue;
    var score = weightedJaccard(entry.value, target, weights);
    if (score <= 0) continue;

    final last = lastScheduled[entry.key];
    if (last != null && now.difference(last).inDays < kRecentDays) {
      score *= kRecentPenalty;
    }

    final shared = [
      for (final i in entry.value)
        if (target.contains(i) && weights.weightOf(i) > 0) i,
    ]..sort((a, b) {
        final byWeight = weights.weightOf(b).compareTo(weights.weightOf(a));
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });

    out.add(RecipeSuggestion(
      recipeId: entry.key,
      score: score,
      sharedIngredientIds: shared,
    ));
  }

  out.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.recipeId.compareTo(b.recipeId);
  });
  return out.take(limit).toList();
}
