import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/planner_suggestion_service.dart';
import 'package:receyta/domain/models/planner_suggestion.dart';

/// Receitas suas parecidas com a aberta no detalhe, por ingredientes em
/// comum. Lida uma vez por abertura: não precisa reagir a cada edição.
final similarRecipesProvider = FutureProvider.autoDispose
    .family<List<PlannerSuggestion>, String>((ref, recipeId) {
  return ref.watch(plannerSuggestionServiceProvider).similarTo(recipeId);
});
