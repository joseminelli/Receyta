import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recipe_dao.g.dart';

/// Acesso bruto à tabela `recipes` (§5: "Service"). Só linhas ativas — o soft
/// delete do §RF-01.6 é escondido aqui, não no repositório.
@DriftAccessor(tables: [Recipes])
class RecipeDao extends DatabaseAccessor<AppDatabase> with _$RecipeDaoMixin {
  RecipeDao(super.db);

  Stream<List<RecipeRow>> watchActive() {
    return (select(recipes)
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  Future<RecipeRow?> findById(String id) {
    return (select(recipes)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<void> upsert(RecipeRow row) =>
      into(recipes).insertOnConflictUpdate(row);

  Future<int> softDelete(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  }
}
