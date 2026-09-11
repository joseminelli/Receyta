import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/folder_dao.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/models/folder.dart';

/// Fonte de verdade das pastas (§RF-02). Converte linha do Drift ↔ model de
/// domínio, cuida das contagens que os tiles mostram e barra movimentos que
/// criariam ciclo. Timestamps são sempre UTC.
class FolderRepository {
  FolderRepository(
    this._dao,
    this._recipeDao, {
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final FolderDao _dao;
  final RecipeDao _recipeDao;
  final DateTime Function() _clock;

  Stream<List<Folder>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList());

  Stream<Folder?> watchFolder(String id) =>
      _dao.watchById(id).map((row) => row == null ? null : _toDomain(row));

  /// Pastas de um nível (filhas de [parentId], ou as de raiz se nulo) já com as
  /// contagens de receitas diretas e de subpastas.
  Stream<List<FolderWithCounts>> watchChildrenWithCounts(String? parentId) {
    return _dao.watchChildrenWithCounts(parentId).map(
          (rows) => [
            for (final row in rows)
              (
                folder: _toDomain(row.folder),
                recipeCount: row.recipeCount,
                subfolders: row.subfolders,
              ),
          ],
        );
  }

  Future<Result<Folder>> create({
    required String name,
    String? parentId,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return const Err(ValidationFailure('Dê um nome pra pasta.'));
    }
    try {
      final row = await _dao.create(name: clean, parentId: parentId);
      return Ok(_toDomain(row));
    } catch (e) {
      return Err(DatabaseFailure('Falha ao criar a pasta', cause: e));
    }
  }

  Future<Result<void>> rename(String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return const Err(ValidationFailure('Dê um nome pra pasta.'));
    }
    try {
      await _dao.rename(id, clean, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao renomear a pasta', cause: e));
    }
  }

  /// Troca a cor e/ou o módulo do azulejo (§9.4). Nulo em qualquer um volta ao
  /// padrão daquele eixo.
  Future<Result<void>> setAppearance(
    String id, {
    TileColor? color,
    TileMotif? motif,
  }) async {
    try {
      await _dao.setAppearance(
        id,
        color: color?.name,
        motif: motif?.name,
        at: _clock().toUtc(),
      );
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao mudar a aparência', cause: e));
    }
  }

  /// Move [id] pra dentro de [newParentId] (nulo = raiz). Recusa se o destino
  /// for a própria pasta ou uma descendente dela — isso quebraria a árvore.
  Future<Result<void>> move(String id, String? newParentId) async {
    if (id == newParentId) {
      return const Err(ValidationFailure('Uma pasta não cabe dentro de si.'));
    }
    try {
      if (newParentId != null && await _isDescendant(newParentId, of: id)) {
        return const Err(
          ValidationFailure('Não dá pra mover pra dentro de uma subpasta.'),
        );
      }
      await _dao.move(id, newParentId, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao mover a pasta', cause: e));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _dao.deleteFolder(id, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao excluir a pasta', cause: e));
    }
  }

  /// Põe a receita numa pasta (nulo = tira da pasta, volta pra raiz).
  Future<Result<void>> moveRecipe(String recipeId, String? folderId) async {
    try {
      await _recipeDao.setFolder(recipeId, folderId, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao mover a receita', cause: e));
    }
  }

  Future<bool> _isDescendant(String candidate, {required String of}) async {
    var cursor = candidate;
    for (var i = 0; i < 64; i++) {
      final row = await _dao.findById(cursor);
      final parent = row?.parentId;
      if (parent == null) return false;
      if (parent == of) return true;
      cursor = parent;
    }
    return true;
  }

  Folder _toDomain(FolderRow r) => Folder(
        id: r.id,
        name: r.name,
        parentId: r.parentId,
        tileColor: tileColorFromName(r.tileColor),
        tileMotif: tileMotifFromName(r.tileMotif),
        position: r.position,
      );
}

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FolderRepository(db.folderDao, db.recipeDao);
});
