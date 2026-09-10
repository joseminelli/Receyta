import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables.dart';

part 'tag_dao.g.dart';

/// Catálogo de tags livres (§RF-01.10). O vínculo receita↔tag em `recipe_tags`
/// é escrito pela [RecipeDao] junto do resto do agregado; aqui ficam só o
/// getOrCreate por nome e as leituras que a home e o formulário consomem.
@DriftAccessor(tables: [Tags, RecipeTags, Recipes])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  /// Todas as tags em ordem alfabética — alimenta o autocomplete do formulário.
  Stream<List<TagRow>> watchAll() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Todas as tags com a contagem de receitas (ativas ou não) — a tela de
  /// gerenciar tags mostra até as que não estão em nenhuma receita.
  Stream<List<({TagRow tag, int count})>> watchAllWithCounts() {
    final count = recipeTags.recipeId.count();
    final query = select(tags).join([
      leftOuterJoin(recipeTags, recipeTags.tagId.equalsExp(tags.id)),
    ])
      ..addColumns([count])
      ..groupBy([tags.id])
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              (tag: row.readTable(tags), count: row.read(count) ?? 0),
          ],
        );
  }

  /// Só as tags presas a pelo menos uma receita ativa — é o que o filtro
  /// horizontal da home mostra (tag sem receita não filtra nada).
  Stream<List<TagRow>> watchInUse() {
    final query = select(tags).join([
      innerJoin(recipeTags, recipeTags.tagId.equalsExp(tags.id)),
      innerJoin(recipes, recipes.id.equalsExp(recipeTags.recipeId)),
    ])
      ..where(recipes.deletedAt.isNull())
      ..groupBy([tags.id])
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.map((row) => row.readTable(tags)).watch();
  }

  /// Quantas receitas carregam a tag — pra confirmar a remoção.
  Future<int> usageCount(String tagId) async {
    final rows =
        await (select(recipeTags)..where((t) => t.tagId.equals(tagId))).get();
    return rows.length;
  }

  /// Apaga a tag do catálogo; o cascade tira o vínculo de todas as receitas.
  Future<int> deleteTag(String tagId) {
    return (delete(tags)..where((t) => t.id.equals(tagId))).go();
  }

  /// Resolve nomes em linhas de `tags`, criando o que faltar. Devolve na mesma
  /// ordem dos nomes recebidos. Espera nomes já normalizados (minúsculas, sem
  /// espaço nas pontas, sem repetição).
  Future<List<TagRow>> ensureTags(List<String> names) async {
    if (names.isEmpty) return const [];
    return transaction(() async {
      final existing = await (select(tags)..where((t) => t.name.isIn(names)))
          .get();
      final byName = {for (final t in existing) t.name: t};
      final missing = names.where((n) => !byName.containsKey(n)).toList();
      if (missing.isNotEmpty) {
        final created = [
          for (final n in missing) TagRow(id: _uuid.v4(), name: n),
        ];
        await batch((b) => b.insertAll(tags, created));
        for (final t in created) {
          byName[t.name] = t;
        }
      }
      return [for (final n in names) byName[n]!];
    });
  }
}
