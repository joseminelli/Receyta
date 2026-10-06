import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tag_name.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/data_reset_service.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/domain/engine/sync_codec.dart';

/// O que uma rodada de sincronização fez.
typedef SyncReport = ({int pulled, int applied, int removed, int pushed});

/// Decide, pra um item que chegou da nuvem, se ele deve sobrescrever o local.
///
/// - não existe aqui: aplica;
/// - existe e NÃO mudou desde a última sincronização: segue a nuvem (se for
///   exatamente a mesma versão, não há o que fazer);
/// - existe e MUDOU aqui (pendente de envio): vence a edição mais recente.
@visibleForTesting
bool remoteWins({
  required bool exists,
  required DateTime remoteEditedAt,
  DateTime? localUpdatedAt,
  DateTime? localSyncedAt,
}) {
  if (!exists) return true;
  final local = localUpdatedAt!;
  final dirty = localSyncedAt == null || local.isAfter(localSyncedAt);
  if (!dirty) return remoteEditedAt != local;
  return remoteEditedAt.isAfter(local);
}

/// Sincroniza receitas e pastas com a conta (H3). Local primeiro: o banco do
/// aparelho é a fonte da verdade, e a rodada é sempre "puxar o que mudou na
/// nuvem, aplicar com 'a edição mais recente vence' e só então enviar o que
/// mudou aqui". Idempotente — repetir não faz mal, e uma falha no meio só
/// deixa o resto pra próxima rodada.
class SyncEngine {
  SyncEngine({
    required this.remote,
    required this.db,
    required this.recipes,
    this.imageSync,
    this.images,
    this.overlap = const Duration(minutes: 2),
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid;

  final SyncRemote remote;
  final AppDatabase db;
  final RecipeRepository recipes;
  final RecipeImageSync? imageSync;
  final RecipeImageService? images;

  /// Quanto recuar o ponto de leitura. O `updated_at` do servidor vem de
  /// `now()` (início da transação), então uma gravação mais lenta pode
  /// aparecer DEPOIS de uma mais nova; reler uma janelinha pega esses
  /// atrasados, e reaplicar um item igual é barato (`remoteWins` pula).
  final Duration overlap;
  final Uuid _uuid;

  static const _batchSize = 50;

  Future<Result<SyncReport>> sync() async {
    final uid = remote.userId;
    if (uid == null) {
      return const Err(
          ValidationFailure('Entre na sua conta para sincronizar.'));
    }
    try {
      // Fotos primeiro: quando a receita chegar ao outro aparelho, o arquivo
      // já está no Storage.
      await imageSync?.syncPending();

      final pull = await _pull(uid);
      final pushed = await _push();
      return Ok((
        pulled: pull.pulled,
        applied: pull.applied,
        removed: pull.removed,
        pushed: pushed,
      ));
    } catch (e) {
      debugPrint('SyncEngine: $e');
      return Err(NetworkFailure(
        'Não foi possível sincronizar agora.',
        cause: e,
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Puxar
  // -------------------------------------------------------------------------

  Future<({int pulled, int applied, int removed})> _pull(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${DataResetService.syncCursorPrefix}$uid';
    final saved = DateTime.tryParse(prefs.getString(key) ?? '');
    final docs = await remote.pullSince(saved?.subtract(overlap));
    if (docs.isEmpty) return (pulled: 0, applied: 0, removed: 0);

    final result = await _apply(docs);

    // Só depois de aplicar tudo o ponto de leitura avança.
    final newest = docs
        .map((d) => d.updatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (best, t) => best == null || t.isAfter(best) ? t : best);
    if (newest != null) {
      await prefs.setString(key, newest.toUtc().toIso8601String());
    }
    return (
      pulled: docs.length,
      applied: result.applied,
      removed: result.removed,
    );
  }

  Future<({int applied, int removed})> _apply(List<SyncDoc> docs) async {
    final liveFolders = <SyncFolder>[];
    final goneFolders = <SyncDoc>[];
    final liveRecipes = <SyncRecipe>[];
    final goneRecipes = <SyncDoc>[];

    for (final d in docs) {
      if (d.kind == kSyncKindFolder) {
        if (d.deleted) {
          goneFolders.add(d);
        } else if (parseFolderSync(d.data) case final f? when f.id == d.id) {
          liveFolders.add(f);
        }
      } else if (d.kind == kSyncKindRecipe) {
        if (d.deleted) {
          goneRecipes.add(d);
        } else if (parseRecipeSync(d.data) case final r? when r.id == d.id) {
          liveRecipes.add(r);
        }
      }
    }

    var applied = 0;
    var removed = 0;
    final imagesToCheck = <String>{};

    await db.transaction(() async {
      // Pais e filhos chegam em qualquer ordem; as chaves estrangeiras são
      // conferidas só no fim da transação.
      await db.customStatement('PRAGMA defer_foreign_keys = ON');

      // 1) pastas apagadas (antes das vivas, pra um filho que já aponta pro
      // avô não achar o pai velho)
      for (final d in goneFolders) {
        final local = await db.folderDao.findAny(d.id);
        if (local == null) continue;
        if (!remoteWins(
          exists: true,
          remoteEditedAt: d.editedAt,
          localUpdatedAt: local.updatedAt,
          localSyncedAt: local.syncedAt,
        )) {
          continue;
        }
        await db.folderDao.deleteRaw(d.id);
        removed++;
      }

      // 2) pastas vivas
      final folderIds = {
        ...await db.folderDao.allIds(),
        for (final f in liveFolders) f.id,
      };
      for (final f in liveFolders) {
        final local = await db.folderDao.findAny(f.id);
        if (!remoteWins(
          exists: local != null,
          remoteEditedAt: f.updatedAt,
          localUpdatedAt: local?.updatedAt,
          localSyncedAt: local?.syncedAt,
        )) {
          continue;
        }
        final parent = (f.parentId != null &&
                f.parentId != f.id &&
                folderIds.contains(f.parentId))
            ? f.parentId
            : null;
        await db.folderDao.upsertRaw(FolderRow(
          id: f.id,
          parentId: parent,
          name: f.name,
          tileColor: f.tileColor?.name,
          tileMotif: f.tileMotif?.name,
          position: f.position,
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
          deletedAt: null,
          lastOpenedAt: local?.lastOpenedAt ?? f.updatedAt,
          syncedAt: f.updatedAt,
        ));
        applied++;
      }

      // 3) receitas apagadas
      for (final d in goneRecipes) {
        final local = await db.recipeDao.findIncludingTrashed(d.id);
        if (local == null) continue;
        if (!remoteWins(
          exists: true,
          remoteEditedAt: d.editedAt,
          localUpdatedAt: local.updatedAt,
          localSyncedAt: local.syncedAt,
        )) {
          continue;
        }
        await db.recipeDao.deleteWithoutTombstone(d.id);
        if (local.imagePath != null) imagesToCheck.add(local.imagePath!);
        removed++;
      }

      // 4) receitas vivas
      final knownFolders = await db.folderDao.allIds();
      final knownUnits = {
        for (final u in await db.select(db.units).get()) u.id,
      };
      for (final r in liveRecipes) {
        final local = await db.recipeDao.findIncludingTrashed(r.id);
        if (!remoteWins(
          exists: local != null,
          remoteEditedAt: r.updatedAt,
          localUpdatedAt: local?.updatedAt,
          localSyncedAt: local?.syncedAt,
        )) {
          continue;
        }
        await _applyRecipe(r, local, knownFolders, knownUnits);
        if (local?.imagePath != null && local!.imagePath != r.imageName) {
          imagesToCheck.add(local.imagePath!);
        }
        applied++;
      }
    });

    // Arquivos de foto que deixaram de ter dono (receita apagada ou foto
    // trocada pela nuvem) saem daqui — se nenhuma outra receita os usa.
    final service = images;
    if (service != null) {
      for (final name in imagesToCheck) {
        await service.deleteIfUnused(name, db.recipeDao.isImagePathUsed);
      }
    }
    return (applied: applied, removed: removed);
  }

  Future<void> _applyRecipe(
    SyncRecipe r,
    RecipeRow? local,
    Set<String> knownFolders,
    Set<String> knownUnits,
  ) async {
    final ingredients = <RecipeIngredientRow>[];
    for (final i in r.ingredients) {
      final catalog = await db.ingredientDao.getOrCreate(i.name);
      ingredients.add(RecipeIngredientRow(
        id: _uuid.v4(),
        recipeId: r.id,
        rawText: i.rawText,
        groupLabel: i.groupLabel,
        position: i.position,
        ingredientId: catalog.id,
        quantity: i.quantity,
        // Unidade que este aparelho não conhece (app mais novo no outro
        // lado) não pode quebrar a chave estrangeira.
        unitId: (i.unit != null && knownUnits.contains(i.unit)) ? i.unit : null,
        qualifier: i.qualifier,
      ));
    }
    final steps = [
      for (final s in r.steps)
        RecipeStepRow(
          id: _uuid.v4(),
          recipeId: r.id,
          instruction: s.text,
          groupLabel: s.groupLabel,
          position: s.position,
        ),
    ];

    final seen = <String>{};
    final tagNames = [
      for (final raw in r.tags) canonicalTagName(raw),
    ].where((n) => n.isNotEmpty && seen.add(n)).toList();
    final tagRows = await db.tagDao.ensureTags(tagNames);

    await db.recipeDao.saveWithChildren(
      recipe: RecipeRow(
        id: r.id,
        folderId: (r.folderId != null && knownFolders.contains(r.folderId))
            ? r.folderId
            : null,
        name: r.name,
        about: r.about,
        prepMinutes: r.prepMinutes,
        cookMinutes: r.cookMinutes,
        servings: r.servings,
        // A foto está no Storage (quem enviou a receita enviou a foto antes):
        // vale como "já enviada" e o arquivo local é baixado quando preciso.
        imagePath: r.imageName,
        imageSyncedPath: r.imageName,
        sourceUrl: r.sourceUrl,
        notes: r.notes,
        tileColor: r.tileColor?.name,
        tileMotif: r.tileMotif?.name,
        isFavorite: r.isFavorite,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
        lastOpenedAt: local?.lastOpenedAt ?? r.updatedAt,
        syncedAt: r.updatedAt,
      ),
      ingredients: ingredients,
      steps: steps,
      tagIds: [for (final t in tagRows) t.id],
      keepImageSyncedPath: false,
    );
  }

  // -------------------------------------------------------------------------
  // Enviar
  // -------------------------------------------------------------------------

  Future<int> _push() async {
    final dirtyFolders = await db.folderDao.dirtyForSync();
    final dirtyRecipes = await db.recipeDao.dirtyForSync();
    final tombstones = await db.recipeDao.pendingTombstones();
    if (dirtyFolders.isEmpty && dirtyRecipes.isEmpty && tombstones.isEmpty) {
      return 0;
    }

    // Cada item leva junto "o que fazer quando o servidor confirmar".
    final items = <({SyncDoc doc, Future<void> Function() onSent})>[];

    for (final f in dirtyFolders) {
      items.add((
        doc: SyncDoc(
          kind: kSyncKindFolder,
          id: f.id,
          editedAt: f.updatedAt,
          data: folderToSyncJson(
            id: f.id,
            name: f.name,
            parentId: f.parentId,
            position: f.position,
            tileColor: tileColorFromName(f.tileColor),
            tileMotif: tileMotifFromName(f.tileMotif),
            createdAt: f.createdAt,
            updatedAt: f.updatedAt,
          ),
        ),
        // Marca a versão que foi LIDA: edição feita durante o envio continua
        // pendente.
        onSent: () => db.folderDao.markSynced(f.id, f.updatedAt),
      ));
    }

    final names = <String, String>{};
    for (final r in dirtyRecipes) {
      final detail = await recipes.detailOfRow(r);
      final ids = [
        for (final i in detail.ingredients)
          if (i.ingredientId != null) i.ingredientId!,
      ];
      if (ids.isNotEmpty) {
        for (final row in await db.ingredientDao.findByIds(ids)) {
          names[row.id] = row.displayName;
        }
      }
      items.add((
        doc: SyncDoc(
          kind: kSyncKindRecipe,
          id: r.id,
          editedAt: r.updatedAt,
          data: recipeToSyncJson(detail, ingredientNames: names),
        ),
        onSent: () => db.recipeDao.markSynced(r.id, r.updatedAt),
      ));
    }

    for (final t in tombstones) {
      items.add((
        doc: SyncDoc(
          kind: t.kind,
          id: t.id,
          editedAt: t.deletedAt,
          deleted: true,
        ),
        onSent: () => db.recipeDao.clearTombstone(t.kind, t.id),
      ));
    }

    var pushed = 0;
    for (var i = 0; i < items.length; i += _batchSize) {
      final batch = items.sublist(
        i,
        i + _batchSize > items.length ? items.length : i + _batchSize,
      );
      await remote.push([for (final it in batch) it.doc]);
      for (final it in batch) {
        await it.onSent();
      }
      pushed += batch.length;
    }
    return pushed;
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    remote: ref.watch(syncRemoteProvider),
    db: ref.watch(databaseProvider),
    recipes: ref.watch(recipeRepositoryProvider),
    imageSync: ref.watch(recipeImageSyncProvider),
    images: ref.watch(recipeImageServiceProvider),
  );
});
