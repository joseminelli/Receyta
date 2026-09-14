import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/models/ingredient.dart';

/// Catálogo inteiro com contagem de uso — a tela de gerenciar ingredientes
/// (C6) lista daqui.
final ingredientsWithCountsProvider =
    StreamProvider<List<IngredientWithCount>>(
  (ref) => ref.watch(ingredientRepositoryProvider).watchAllWithCounts(),
);
