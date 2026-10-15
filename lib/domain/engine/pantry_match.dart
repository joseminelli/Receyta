/// Cruza o que cada receita pede com o que a pessoa diz que sempre tem (a
/// despensa), pra saber o que dá pra fazer agora. Dart puro.
library;

/// Até quantos ingredientes podem faltar pra receita ainda entrar em "Dá pra
/// fazer".
const kMaxMissingIngredients = 2;

/// Quanto da receita a despensa cobre: [total] ingredientes catalogados, dos
/// quais [missingIds] não estão na despensa.
class PantryMatch {
  const PantryMatch({required this.total, required this.missingIds});

  final int total;
  final List<String> missingIds;

  int get missing => missingIds.length;
  int get have => total - missing;
  bool get hasEverything => missingIds.isEmpty;
}

/// Receitas que a despensa quase cobre: faltam no máximo [maxMissing]
/// ingredientes e pelo menos um está na despensa. [ingredientsByRecipe] é
/// `recipeId` → ids dos ingredientes do catálogo (linhas ainda sem vínculo
/// não entram na conta). Despensa vazia não casa nada.
Map<String, PantryMatch> matchPantry(
  Map<String, Set<String>> ingredientsByRecipe,
  Set<String> pantry, {
  int maxMissing = kMaxMissingIngredients,
}) {
  if (pantry.isEmpty) return const {};
  final out = <String, PantryMatch>{};
  for (final e in ingredientsByRecipe.entries) {
    final missing = [
      for (final id in e.value)
        if (!pantry.contains(id)) id,
    ]..sort();
    final have = e.value.length - missing.length;
    if (have < 1 || missing.length > maxMissing) continue;
    out[e.key] = PantryMatch(total: e.value.length, missingIds: missing);
  }
  return out;
}
