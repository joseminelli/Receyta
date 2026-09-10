import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables.dart';

part 'folder_dao.g.dart';

/// Acesso bruto às pastas (§RF-02). Aninhamento por `parentId`; as receitas
/// apontam pra pasta por `folderId`. Excluir uma pasta sobe o conteúdo
/// (subpastas e receitas) pro pai — nada é apagado junto. Só linhas ativas: o
/// soft delete fica escondido aqui, como na [RecipeDao].
@DriftAccessor(tables: [Folders, Recipes])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  Stream<List<FolderRow>> watchAll() {
    return (select(folders)
          ..where((f) => f.deletedAt.isNull())
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .watch();
  }

  /// Pastas de um nível: filhas diretas de [parentId], ou as de raiz se nulo.
  Stream<List<FolderRow>> watchChildren(String? parentId) {
    return (select(folders)
          ..where((f) =>
              f.deletedAt.isNull() &
              (parentId == null
                  ? f.parentId.isNull()
                  : f.parentId.equals(parentId)))
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .watch();
  }

  Stream<FolderRow?> watchById(String id) {
    return (select(folders)
          ..where((f) => f.id.equals(id) & f.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<FolderRow?> findById(String id) {
    return (select(folders)
          ..where((f) => f.id.equals(id) & f.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Pastas de um nível já com a contagem de receitas diretas (não conta as de
  /// subpastas) e de subpastas diretas. Uma query só, stream vivo.
  Stream<List<({FolderRow folder, int recipeCount, int subfolders})>>
      watchChildrenWithCounts(String? parentId) {
    return customSelect(
      'SELECT f.*, '
      '  (SELECT COUNT(*) FROM recipes r '
      '   WHERE r.folder_id = f.id AND r.deleted_at IS NULL) AS recipe_count, '
      '  (SELECT COUNT(*) FROM folders c '
      '   WHERE c.parent_id = f.id AND c.deleted_at IS NULL) AS subfolder_count '
      'FROM folders f '
      'WHERE f.deleted_at IS NULL AND '
      '  ((?1 IS NULL AND f.parent_id IS NULL) OR f.parent_id = ?1) '
      'ORDER BY f.name COLLATE NOCASE',
      variables: [Variable<String>(parentId)],
      readsFrom: {folders, recipes},
    ).watch().map(
          (rows) => [
            for (final row in rows)
              (
                folder: folders.map(row.data),
                recipeCount: row.read<int>('recipe_count'),
                subfolders: row.read<int>('subfolder_count'),
              ),
          ],
        );
  }

  Future<FolderRow> create({required String name, String? parentId}) async {
    final now = DateTime.now().toUtc();
    final row = FolderRow(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      position: 0,
      createdAt: now,
      updatedAt: now,
    );
    await into(folders).insert(row);
    return row;
  }

  Future<int> rename(String id, String name, DateTime at) {
    return (update(folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(name: Value(name), updatedAt: Value(at)),
    );
  }

  Future<int> move(String id, String? newParentId, DateTime at) {
    return (update(folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(parentId: Value(newParentId), updatedAt: Value(at)),
    );
  }

  /// Sobe subpastas e receitas pro pai da pasta e apaga a linha, numa transação.
  /// O `onDelete: setNull` da FK de receita jogaria elas na raiz — aqui levamos
  /// explícito pro pai, que é o que o usuário espera.
  Future<void> deleteFolder(String id, DateTime at) {
    return transaction(() async {
      final row = await findById(id);
      final parent = row?.parentId;
      await (update(folders)..where((f) => f.parentId.equals(id))).write(
        FoldersCompanion(parentId: Value(parent), updatedAt: Value(at)),
      );
      await (update(recipes)..where((r) => r.folderId.equals(id))).write(
        RecipesCompanion(folderId: Value(parent), updatedAt: Value(at)),
      );
      await (delete(folders)..where((f) => f.id.equals(id))).go();
    });
  }
}
