import 'package:receyta/domain/models/recipe.dart';

/// Uma receita sugerida pro dia (RF-04.4) e o motivo: os ingredientes que ela
/// divide com o que você já vai comprar na semana (nomes de exibição, do mais
/// raro pro mais comum — ver `suggestRecipes`).
class PlannerSuggestion {
  const PlannerSuggestion({
    required this.recipe,
    required this.score,
    required this.sharedIngredientNames,
  });

  final Recipe recipe;
  final double score;
  final List<String> sharedIngredientNames;

  /// "usa frango e gengibre, que você já vai comprar" — até três nomes, em
  /// minúsculas. Sem nenhum nome (não deveria acontecer), só a frase base.
  String get reason {
    final names = [
      for (final n in sharedIngredientNames.take(3)) n.toLowerCase(),
    ];
    const tail = 'que você já vai comprar';
    return switch (names.length) {
      0 => 'combina com o que você já vai comprar',
      1 => 'usa ${names[0]}, $tail',
      2 => 'usa ${names[0]} e ${names[1]}, $tail',
      _ => 'usa ${names[0]}, ${names[1]} e ${names[2]}, $tail',
    };
  }
}
