import 'package:flutter/foundation.dart';

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
  });

  final String id;
  final String recipeId;
  final String recipeName;
  final DateTime cookedAt;
  final String? note;

  bool get hasNote => (note ?? '').trim().isNotEmpty;
}
