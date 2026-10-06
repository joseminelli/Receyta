import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;

import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/domain/engine/sync_codec.dart';
import 'package:receyta/domain/engine/text_normalize.dart';

/// Une duplicatas que nascem quando o MESMO conteúdo foi criado separado em
/// dois aparelhos antes de a conta existir (receitas e pastas com ids
/// diferentes e conteúdo igual).
///
/// Regra de segurança: só some a cópia **local que nunca foi sincronizada**
/// (`synced_at` nulo) e que é IDÊNTICA a um item que acabou de chegar da
/// nuvem, um pra um. Nunca toca em item já sincronizado — duas cópias que a
/// pessoa fez de propósito e que já estão na conta continuam duas. Quem fica é
/// o item da nuvem; o que apontava pra cópia (refeições planejadas, histórico,
/// origens de itens de compras, receitas dentro da pasta) passa a apontar pra
/// ele e é marcado como mudado, pra a correção chegar aos outros aparelhos.
///
/// Os dois aparelhos chegam ao mesmo resultado: o primeiro a sincronizar vira
/// a "cópia da nuvem" e o outro descarta a sua.
class SyncDeduper {
  SyncDeduper(this.db, {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase db;
  final DateTime Function() _clock;

  /// Chave de comparação de nome: sem acento, minúsculas, espaços colapsados.
  static String nameKey(String name) =>
      stripAccents(name.trim().toLowerCase()).replaceAll(RegExp(r'\s+'), ' ');

  // -------------------------------------------------------------------------
  // Pastas
  // -------------------------------------------------------------------------

  /// [fresh] são as pastas que chegaram da nuvem e eram novas aqui. Devolve
  /// quantas cópias locais foram unidas.
  Future<int> mergeFolders(List<SyncFolder> fresh) async {
    if (fresh.isEmpty) return 0;
    var merged = 0;

    // Pais antes dos filhos: unir o pai re-aponta os filhos locais pra pasta da
    // nuvem, e só então eles podem casar com os filhos dela.
    final byId = {for (final f in fresh) f.id: f};
    int depth(SyncFolder f) {
      var d = 0;
      var p = f.parentId;
      while (p != null && byId.containsKey(p) && d < 50) {
        d++;
        p = byId[p]!.parentId;
      }
      return d;
    }

    final ordered = [...fresh]..sort((a, b) => depth(a).compareTo(depth(b)));
    final claimed = <String>{};

    for (final remote in ordered) {
      final candidates = await (db.select(db.folders)
            ..where((f) => f.syncedAt.isNull() & f.id.isNotValue(remote.id)))
          .get();
      FolderRow? match;
      for (final c in candidates) {
        if (claimed.contains(c.id)) continue;
        if (nameKey(c.name) != nameKey(remote.name)) continue;
        if (c.parentId != remote.parentId) continue;
        match = c;
        break;
      }
      if (match == null) continue;
      claimed.add(match.id);
      await _moveFolderContents(from: match.id, to: remote.id);
      await (db.delete(db.folders)..where((f) => f.id.equals(match!.id))).go();
      merged++;
    }
    return merged;
  }

  Future<void> _moveFolderContents({
    required String from,
    required String to,
  }) async {
    final now = _clock();
    await (db.update(db.folders)..where((f) => f.parentId.equals(from))).write(
      FoldersCompanion(parentId: Value(to), updatedAt: Value(now)),
    );
    await (db.update(db.recipes)..where((r) => r.folderId.equals(from))).write(
      RecipesCompanion(folderId: Value(to), updatedAt: Value(now)),
    );
  }

  // -------------------------------------------------------------------------
  // Receitas
  // -------------------------------------------------------------------------

  /// [fresh] são as receitas que chegaram da nuvem e eram novas aqui.
  /// [onImageFreed] recebe o nome da foto de cada cópia descartada (pra o
  /// motor apagar o arquivo se ninguém mais o usa). Devolve quantas cópias
  /// locais foram unidas.
  Future<int> mergeRecipes(
    List<SyncRecipe> fresh, {
    void Function(String imageName)? onImageFreed,
  }) async {
    if (fresh.isEmpty) return 0;

    // Candidatas: receitas locais ativas que nunca subiram, por nome.
    final pending = await (db.select(db.recipes)
          ..where((r) => r.syncedAt.isNull() & r.deletedAt.isNull()))
        .get();
    if (pending.isEmpty) return 0;
    final byName = <String, List<RecipeRow>>{};
    for (final r in pending) {
      byName.putIfAbsent(nameKey(r.name), () => []).add(r);
    }

    var merged = 0;
    final claimed = <String>{};
    for (final remote in fresh) {
      if (remote.deletedAt != null) continue;
      final candidates = byName[nameKey(remote.name)] ?? const [];
      final remotePrint = _fingerprint(
        remote.ingredients.map((i) => i.rawText),
        remote.steps.map((s) => s.text),
      );
      RecipeRow? match;
      for (final c in candidates) {
        if (c.id == remote.id || claimed.contains(c.id)) continue;
        final print = _fingerprint(
          (await db.recipeDao.ingredientsOf(c.id)).map((i) => i.rawText),
          (await db.recipeDao.stepsOf(c.id)).map((s) => s.instruction),
        );
        if (print == remotePrint) {
          match = c;
          break;
        }
      }
      if (match == null) continue;
      claimed.add(match.id);
      await _repointReferences(from: match.id, to: remote.id);
      await db.recipeDao.deleteWithoutTombstone(match.id);
      if (match.imagePath != null) onImageFreed?.call(match.imagePath!);
      merged++;
    }
    return merged;
  }

  /// Ingredientes e passos, em ordem, sem acento e sem diferença de caixa ou
  /// espaço — o que torna duas receitas "a mesma".
  String _fingerprint(Iterable<String> ingredients, Iterable<String> steps) {
    String norm(String s) => nameKey(s);
    return '${ingredients.map(norm).join('|')}\n${steps.map(norm).join('|')}';
  }

  /// Tudo que apontava pra receita descartada passa a apontar pra da nuvem, e
  /// é marcado como mudado (`updated_at`) pra o ajuste sincronizar.
  Future<void> _repointReferences({
    required String from,
    required String to,
  }) async {
    final now = _clock();

    await (db.update(db.mealPlanEntries)..where((e) => e.recipeId.equals(from)))
        .write(MealPlanEntriesCompanion(
      recipeId: Value(to),
      updatedAt: Value(now),
    ));

    await (db.update(db.cookLogs)..where((l) => l.recipeId.equals(from))).write(
      CookLogsCompanion(recipeId: Value(to), updatedAt: Value(now)),
    );

    // Origens de itens de compras: a chave é (item, receita); se o item já
    // tem a receita da nuvem como origem, a da cópia só sai.
    final sources = await (db.select(db.shoppingItemSources)
          ..where((s) => s.recipeId.equals(from)))
        .get();
    for (final s in sources) {
      final alreadyThere = await (db.select(db.shoppingItemSources)
            ..where((x) => x.itemId.equals(s.itemId) & x.recipeId.equals(to)))
          .getSingleOrNull();
      if (alreadyThere == null) {
        await db.into(db.shoppingItemSources).insert(
              ShoppingItemSourceRow(
                itemId: s.itemId,
                recipeId: to,
                quantity: s.quantity,
                unitId: s.unitId,
              ),
            );
      }
      await (db.update(db.shoppingListItems)
            ..where((i) => i.id.equals(s.itemId)))
          .write(ShoppingListItemsCompanion(updatedAt: Value(now)));
    }
    await (db.delete(db.shoppingItemSources)
          ..where((s) => s.recipeId.equals(from)))
        .go();
  }
}
