import 'package:flutter/foundation.dart';

import 'package:receyta/domain/models/recipe.dart';

/// Uma vez que a receita foi feita (G7): quando e, se a pessoa quis, uma nota
/// ("faltou sal", "ficou ótimo com menos açúcar"). [recipeName] só vem
/// preenchido nas listas que misturam receitas.
@immutable
class CookLog {
  const CookLog({
    required this.id,
    required this.recipeId,
    required this.cookedAt,
    this.recipeName = '',
    this.note,
    this.rating,
    this.recipe,
  });

  final String id;
  final String recipeId;
  final String recipeName;
  final DateTime cookedAt;
  final String? note;

  /// Estrelas de 1 a 5, ou nulo quando não avaliou.
  final int? rating;

  /// A receita, nas listas que mostram a capa dela (o histórico).
  final Recipe? recipe;

  bool get hasNote => (note ?? '').trim().isNotEmpty;
}
