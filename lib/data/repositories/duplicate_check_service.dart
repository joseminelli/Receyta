import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/engine/duplicate_detector.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

/// Junta o rascunho de um import com as receitas ativas e roda o detector.
/// Qualquer falha de leitura vira "sem duplicata": o aviso nunca pode
/// atrapalhar o import.
class DuplicateCheckService {
  DuplicateCheckService(this._recipeDao);

  final RecipeDao _recipeDao;

  Future<DuplicateMatch?> check(ImportedRecipe draft) async {
    try {
      final identities = await _recipeDao.activeIdentities();
      final keys = await _recipeDao.activeIngredientKeySets();
      return findDuplicate(
        name: draft.name,
        sourceUrl: draft.sourceUrl,
        ingredientKeys: ingredientKeysOf(draft.ingredientLines),
        existing: [
          for (final r in identities)
            ExistingRecipe(
              id: r.id,
              name: r.name,
              sourceUrl: r.sourceUrl,
              ingredientKeys: keys[r.id] ?? const {},
            ),
        ],
      );
    } catch (e) {
      debugPrint('DuplicateCheckService.check: $e');
      return null;
    }
  }
}

final duplicateCheckServiceProvider = Provider<DuplicateCheckService>(
  (ref) => DuplicateCheckService(ref.watch(databaseProvider).recipeDao),
);
