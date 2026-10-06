import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recipe_dao.g.dart';

/// Acesso bruto ao agregado receita (§5: "Service"): a linha em `recipes` e
/// suas listas em `recipe_ingredients` / `recipe_steps` / `recipe_tags`. Só
/// linhas ativas — o soft delete do §RF-01.6 é escondido aqui, não no
/// repositório. O catálogo de tags (getOrCreate por nome) fica na [TagDao].
@DriftAccessor(tables: [
  Recipes,
  RecipeIngredients,
  RecipeSteps,
  Tags,
  RecipeTags,
  SyncTombstones,
])
class RecipeDao extends DatabaseAccessor<AppDatabase> with _$RecipeDaoMixin {
  RecipeDao(super.db);

  Stream<List<RecipeRow>> watchActive({
    Set<String> anyOfTagIds = const {},
    bool favoritesOnly = false,
    bool rootOnly = false,
  }) {
    final query = select(recipes)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
    if (rootOnly) {
      query.where((r) => r.folderId.isNull());
    }
    if (favoritesOnly) {
      query.where((r) => r.isFavorite.equals(true));
    }
    if (anyOfTagIds.isNotEmpty) {
      query.where(
        (r) => existsQuery(
          select(recipeTags)
            ..where(
              (rt) => rt.recipeId.equalsExp(r.id) & rt.tagId.isIn(anyOfTagIds),
            ),
        ),
      );
    }
    return query.watch();
  }

  /// Busca por nome, sobre e notas (FTS5) e por nome de tag (§RF-01.9). Cada
  /// termo vira prefixo (`curry` acha "curry ao forno"). Query vazia → nada.
  Stream<List<RecipeRow>> search(String query) {
    final trimmed = query.trim();
    final terms = trimmed
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll('"', '').trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return Stream.value(const []);

    final match = terms.map((t) => '"$t"*').join(' ');
    final like = '%${trimmed.replaceAll(RegExp(r'[%_\\]'), r'\$0')}%';

    return customSelect(
      'SELECT r.* FROM recipes r '
      'WHERE r.deleted_at IS NULL AND ('
      '  r.rowid IN (SELECT rowid FROM recipes_fts WHERE recipes_fts MATCH ?1)'
      '  OR r.id IN ('
      '    SELECT rt.recipe_id FROM recipe_tags rt '
      '    JOIN tags t ON t.id = rt.tag_id '
      "    WHERE t.name LIKE ?2 ESCAPE '\\'"
      '  )'
      ') ORDER BY r.updated_at DESC',
      variables: [Variable<String>(match), Variable<String>(like)],
      readsFrom: {recipes, recipeTags, tags},
    ).map((row) => recipes.map(row.data)).watch();
  }

  Future<List<TagRow>> tagsOf(String recipeId) {
    final query = select(tags).join([
      innerJoin(recipeTags, recipeTags.tagId.equalsExp(tags.id)),
    ])
      ..where(recipeTags.recipeId.equals(recipeId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.map((row) => row.readTable(tags)).get();
  }

  Stream<RecipeRow?> watchById(String id) {
    return (select(recipes)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<RecipeRow?> findById(String id) {
    return (select(recipes)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Como [findById], mas enxerga também a receita que está na lixeira — é
  /// onde ela está quando é apagada de vez.
  Future<RecipeRow?> findIncludingTrashed(String id) {
    return (select(recipes)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Lote de receitas por id — gerar lista de compras (E2) resolve o nome
  /// de cada receita de origem de uma vez só, não um `SELECT` por linha.
  Future<List<RecipeRow>> findByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return (select(recipes)..where((r) => r.id.isIn(ids))).get();
  }

  /// Pra cada receita ativa, o conjunto de ingredientes do catálogo que ela
  /// usa (linhas ainda sem vínculo ficam de fora) — a entrada do motor de
  /// similaridade (F4). Receita sem nenhum ingrediente resolvido não aparece.
  Future<Map<String, Set<String>>> activeIngredientSets() async {
    final rows = await customSelect(
      'SELECT ri.recipe_id AS rid, ri.ingredient_id AS iid '
      'FROM recipe_ingredients ri '
      'JOIN recipes r ON r.id = ri.recipe_id '
      'WHERE r.deleted_at IS NULL AND ri.ingredient_id IS NOT NULL',
      readsFrom: {recipeIngredients, recipes},
    ).get();
    final out = <String, Set<String>>{};
    for (final row in rows) {
      out
          .putIfAbsent(row.read<String>('rid'), () => <String>{})
          .add(row.read<String>('iid'));
    }
    return out;
  }

  Future<List<RecipeIngredientRow>> ingredientsOf(String recipeId) {
    return (select(recipeIngredients)
          ..where((i) => i.recipeId.equals(recipeId))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
  }

  /// Ingredientes de várias receitas numa query só — gerar lista de compras
  /// (E2) a partir de receitas selecionadas não busca uma por vez.
  Future<List<RecipeIngredientRow>> ingredientsForRecipes(
    List<String> recipeIds,
  ) {
    if (recipeIds.isEmpty) return Future.value(const []);
    return (select(recipeIngredients)
          ..where((i) => i.recipeId.isIn(recipeIds))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
  }

  /// Linhas nunca resolvidas contra o catálogo — `raw_text` do bloco B, de
  /// antes do parser (C1) existir, ou qualquer linha que por algum motivo
  /// ficou sem `ingredient_id`. É o que o C5 reprocessa.
  Future<List<RecipeIngredientRow>> findUnresolvedIngredients() {
    return (select(recipeIngredients)..where((i) => i.ingredientId.isNull()))
        .get();
  }

  /// Grava o resultado do parser (C1) + `getOrCreate` (C2) numa linha
  /// existente, sem tocar em `raw_text`/`group_label`/`position`.
  Future<void> resolveIngredient(
    String id, {
    required String? ingredientId,
    required double? quantity,
    required String? unitId,
    required String? qualifier,
  }) {
    return (update(recipeIngredients)..where((i) => i.id.equals(id))).write(
      RecipeIngredientsCompanion(
        ingredientId: Value(ingredientId),
        quantity: Value(quantity),
        unitId: Value(unitId),
        qualifier: Value(qualifier),
      ),
    );
  }

  Future<List<RecipeStepRow>> stepsOf(String recipeId) {
    return (select(recipeSteps)
          ..where((s) => s.recipeId.equals(recipeId))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  Future<void> upsert(RecipeRow row) =>
      into(recipes).insertOnConflictUpdate(row);

  /// Grava a receita e substitui suas listas numa transação — a UI edita
  /// ingredientes, passos e tags por reposição total, não por diff. As linhas
  /// de `tags` já têm que existir (a [TagRepository] resolve os nomes antes).
  ///
  /// [keepImageSyncedPath] (padrão) preserva o registro de envio da foto que
  /// está no banco. O sync, ao aplicar uma receita vinda da nuvem, passa
  /// `false`: aí o valor que ele traz é que vale.
  Future<void> saveWithChildren({
    required RecipeRow recipe,
    required List<RecipeIngredientRow> ingredients,
    required List<RecipeStepRow> steps,
    List<String> tagIds = const [],
    bool keepImageSyncedPath = true,
  }) {
    return transaction(() async {
      // O registro de envio da foto pertence ao sync, não a quem edita: o
      // objeto que chega aqui pode ser de antes de um envio terminar, e
      // gravá-lo como está faria a foto subir de novo.
      final current = await (select(recipes)
            ..where((r) => r.id.equals(recipe.id)))
          .getSingleOrNull();
      final next = keepImageSyncedPath
          ? recipe.copyWith(imageSyncedPath: Value(current?.imageSyncedPath))
          : recipe;
      if (current == null) {
        await into(recipes).insert(next);
      } else {
        // `insertOnConflictUpdate` NÃO limpa uma coluna quando o valor novo é
        // nulo (ele ignora os nulos): apagar o "Sobre", o tempo ou as notas
        // numa edição faria o valor antigo voltar. Escrever o companion
        // completo (`toCompanion(false)`) grava os nulos de verdade.
        await (update(recipes)..where((r) => r.id.equals(recipe.id)))
            .write(next.toCompanion(false));
      }
      await (delete(recipeIngredients)
            ..where((i) => i.recipeId.equals(recipe.id)))
          .go();
      await (delete(recipeSteps)..where((s) => s.recipeId.equals(recipe.id)))
          .go();
      await (delete(recipeTags)..where((t) => t.recipeId.equals(recipe.id)))
          .go();
      await batch((b) {
        b.insertAll(recipeIngredients, ingredients);
        b.insertAll(recipeSteps, steps);
        b.insertAll(recipeTags, [
          for (final tagId in tagIds)
            RecipeTagRow(recipeId: recipe.id, tagId: tagId),
        ]);
      });
    });
  }

  /// Receitas ativas de uma pasta (por `folderId`); nulo = as soltas na raiz.
  Stream<List<RecipeRow>> watchInFolder(String? folderId) {
    return (select(recipes)
          ..where((r) =>
              r.deletedAt.isNull() &
              (folderId == null
                  ? r.folderId.isNull()
                  : r.folderId.equals(folderId)))
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  Future<int> setFolder(String id, String? folderId, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(folderId: Value(folderId), updatedAt: Value(at)),
    );
  }

  Future<int> setFavorite(String id, bool value, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(isFavorite: Value(value), updatedAt: Value(at)),
    );
  }

  /// `color`/`motif` são o `.name` do enum, ou nulo pra voltar ao automático.
  Future<int> setAppearance(
    String id, {
    required String? color,
    required String? motif,
    required DateTime at,
  }) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        tileColor: Value(color),
        tileMotif: Value(motif),
        updatedAt: Value(at),
      ),
    );
  }

  /// Nome do arquivo da foto (ou nulo pra tirar a foto).
  Future<int> setImagePath(String id, String? imagePath, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(imagePath: Value(imagePath), updatedAt: Value(at)),
    );
  }

  /// Receitas cuja foto não bate com a última enviada ao Storage: foto nova
  /// ou trocada (enviar) e foto trocada ou removida (apagar a antiga lá).
  Future<List<RecipeRow>> pendingImageSync() {
    return (select(recipes)
          ..where((r) => const CustomExpression<bool>(
              'image_path IS NOT image_synced_path')))
        .get();
  }

  /// Marca qual foto está na nuvem. Não mexe em `updated_at`: é bookkeeping,
  /// não edição da receita.
  Future<int> setImageSynced(String id, String? name) {
    return (update(recipes)..where((r) => r.id.equals(id)))
        .write(RecipesCompanion(imageSyncedPath: Value(name)));
  }

  /// Alguma receita (que não seja [exceptRecipeId]) tem [name] como foto?
  /// Decide se o ARQUIVO LOCAL ainda é necessário.
  Future<bool> isImagePathUsed(String name, {String? exceptRecipeId}) async {
    final query = select(recipes)
      ..where((r) {
        final used = r.imagePath.equals(name);
        return exceptRecipeId == null
            ? used
            : used & r.id.isNotValue(exceptRecipeId);
      })
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// Como [isImagePathUsed], mas também conta quem ainda tem [name] como foto
  /// já enviada. Decide se a cópia NA NUVEM ainda é necessária.
  Future<bool> isRemoteImageUsed(String name, {String? exceptRecipeId}) async {
    final query = select(recipes)
      ..where((r) {
        final used = r.imagePath.equals(name) | r.imageSyncedPath.equals(name);
        return exceptRecipeId == null
            ? used
            : used & r.id.isNotValue(exceptRecipeId);
      })
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// Toda foto que alguma receita (inclusive na lixeira) ainda referencia,
  /// local ou já enviada — o que sobrar na nuvem fora disso é lixo.
  Future<Set<String>> referencedImageNames() async {
    final rows = await (select(recipes)
          ..where(
              (r) => r.imagePath.isNotNull() | r.imageSyncedPath.isNotNull()))
        .get();
    return {
      for (final r in rows) ...[
        if (r.imagePath != null) r.imagePath!,
        if (r.imageSyncedPath != null) r.imageSyncedPath!,
      ],
    };
  }

  /// Nomes de foto que constam como já enviadas ao Storage.
  Future<Set<String>> syncedImageNames() async {
    final rows = await (select(recipes)
          ..where((r) => r.imageSyncedPath.isNotNull()))
        .get();
    return {for (final r in rows) r.imageSyncedPath!};
  }

  /// Nomes de foto ainda em uso (inclui a lixeira — a receita pode voltar).
  Future<Set<String>> referencedImagePaths() async {
    final rows =
        await (select(recipes)..where((r) => r.imagePath.isNotNull())).get();
    return {for (final r in rows) r.imagePath!};
  }

  Future<int> setLastOpenedAt(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id)))
        .write(RecipesCompanion(lastOpenedAt: Value(at)));
  }

  /// As 7 mais recentes (criação ou abertura), só as soltas na raiz — as de
  /// dentro de pasta são acessadas por lá, não pela prateleira da home.
  Stream<List<RecipeRow>> watchRecent({int limit = 7}) {
    return (select(recipes)
          ..where((r) => r.deletedAt.isNull() & r.folderId.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.lastOpenedAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> softDelete(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  }

  /// Linhas na lixeira (RF-01.6), da mais recente pra mais antiga.
  Stream<List<RecipeRow>> watchTrashed() {
    return (select(recipes)
          ..where((r) => r.deletedAt.isNotNull())
          ..orderBy([(r) => OrderingTerm.desc(r.deletedAt)]))
        .watch();
  }

  Future<int> restore(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: const Value(null), updatedAt: Value(at)),
    );
  }

  /// Apaga de verdade — o cascade leva ingredientes, passos e vínculos de tag.
  /// Se a receita já tinha sido sincronizada, deixa um aviso de exclusão pra
  /// nuvem (H3).
  Future<int> hardDelete(String id) {
    return transaction(() async {
      final row = await findIncludingTrashed(id);
      final count = await (delete(recipes)..where((r) => r.id.equals(id))).go();
      if (row?.syncedAt != null) {
        await _tombstone(id);
      }
      return count;
    });
  }

  Future<void> _tombstone(String id) {
    return into(syncTombstones).insertOnConflictUpdate(
      SyncTombstonesCompanion.insert(
        kind: 'recipe',
        id: id,
        deletedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Linhas da lixeira que já passaram do prazo — lidas antes do
  /// [purgeExpired] pra saber quais fotos ficam sem dono.
  Future<List<RecipeRow>> expiredInTrash(DateTime cutoff) {
    return (select(recipes)
          ..where((r) =>
              r.deletedAt.isNotNull() & r.deletedAt.isSmallerThanValue(cutoff)))
        .get();
  }

  /// Esvazia da lixeira tudo que passou do prazo. Roda no boot.
  Future<int> purgeExpired(DateTime cutoff) {
    return transaction(() async {
      final expired = await expiredInTrash(cutoff);
      final count = await (delete(recipes)
            ..where((r) =>
                r.deletedAt.isNotNull() &
                r.deletedAt.isSmallerThanValue(cutoff)))
          .go();
      for (final r in expired) {
        if (r.syncedAt != null) await _tombstone(r.id);
      }
      return count;
    });
  }

  /// Apaga a receita SEM deixar aviso de exclusão: é o sync aplicando uma
  /// exclusão que veio da nuvem — avisar de volta só faria eco.
  Future<int> deleteWithoutTombstone(String id) {
    return (delete(recipes)..where((r) => r.id.equals(id))).go();
  }

  /// Avisos de exclusão que a nuvem ainda não recebeu: os da conta
  /// ([spaceId] nulo) ou os de uma casa.
  Future<List<SyncTombstoneRow>> pendingTombstones({String? spaceId}) {
    return (select(syncTombstones)
          ..where((t) =>
              spaceId == null ? t.spaceId.isNull() : t.spaceId.equals(spaceId)))
        .get();
  }

  Future<int> clearTombstone(String kind, String id) {
    return (delete(syncTombstones)
          ..where((t) => t.kind.equals(kind) & t.id.equals(id)))
        .go();
  }

  /// Receitas (inclusive as da lixeira) que mudaram desde a última
  /// sincronização ou nunca subiram.
  Future<List<RecipeRow>> dirtyForSync() {
    return (select(recipes)
          ..where((r) =>
              r.syncedAt.isNull() | r.updatedAt.isBiggerThan(r.syncedAt)))
        .get();
  }

  /// Marca como sincronizada a versão [updatedAt]. Se a receita foi editada
  /// no meio do caminho (`updated_at` maior), continua pendente.
  Future<int> markSynced(String id, DateTime updatedAt) {
    return (update(recipes)..where((r) => r.id.equals(id)))
        .write(RecipesCompanion(syncedAt: Value(updatedAt)));
  }
}
