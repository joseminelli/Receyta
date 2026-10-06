import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/sync/shared_remote.dart';
import 'package:receyta/data/sync/sync_engine.dart' show SyncReport;
import 'package:receyta/data/sync/sync_error.dart';
import 'package:receyta/data/sync/sync_handler.dart';
import 'package:receyta/data/sync/sync_handlers.dart';
import 'package:receyta/data/sync/sync_remote.dart' show SyncDoc;

/// Sincroniza com a CASA (itens compartilhados) o que o [SyncEngine] não
/// sincroniza com a conta: as listas de compras (e, depois, o calendário) que
/// têm `space_id`. Mesma ideia do motor da conta — puxa, aplica numa
/// transação, empurra em lotes —, mais enxuto: não há receitas, pastas nem
/// fotos aqui.
///
/// Quem manda é a edição mais recente, item a item (`remoteWins`), então duas
/// pessoas marcando itens diferentes da mesma lista não se atropelam.
class SharedSyncEngine {
  SharedSyncEngine({
    required this.remote,
    required this.db,
    required this.spaceId,
    List<SyncHandler>? handlers,
    this.overlap = const Duration(minutes: 2),
  }) : handlers = handlers ?? sharedSyncHandlers(db, spaceId);

  final SharedRemote remote;
  final AppDatabase db;
  final String spaceId;

  /// Na ordem em que aplicam: a lista antes dos itens.
  final List<SyncHandler> handlers;

  /// Quanto recuar o ponto de leitura (ver `SyncEngine.overlap`).
  final Duration overlap;

  static const cursorPrefix = 'shared_cursor_';
  static const _batchSize = 50;

  String get _cursorKey => '$cursorPrefix$spaceId';

  /// Sobrou algo pendente de envio pra esta casa?
  Future<bool> hasPending() async {
    if ((await db.recipeDao.pendingTombstones(spaceId: spaceId)).isNotEmpty) {
      return true;
    }
    for (final h in handlers) {
      if (await h.hasPending()) return true;
    }
    return false;
  }

  Future<Result<SyncReport>> sync() async {
    if (remote.userId == null) {
      return const Err(
          ValidationFailure('Entre na sua conta para sincronizar.'));
    }
    try {
      final pull = await _pull();
      final pushed = await _push();
      return Ok((
        pulled: pull.pulled,
        applied: pull.applied,
        removed: pull.removed,
        pushed: pushed,
        merged: 0,
      ));
    } catch (e) {
      debugPrint('SharedSyncEngine: $e');
      return Err(classifySyncError(e));
    }
  }

  Future<({int pulled, int applied, int removed})> _pull() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = DateTime.tryParse(prefs.getString(_cursorKey) ?? '');
    final docs = await remote.pullSince(spaceId, saved?.subtract(overlap));
    if (docs.isEmpty) return (pulled: 0, applied: 0, removed: 0);

    var applied = 0;
    var removed = 0;
    await db.transaction(() async {
      await db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final h in handlers) {
        final mine = [
          for (final d in docs)
            if (d.kind == h.kind) d
        ];
        if (mine.isEmpty) continue;
        final result = await h.apply(mine);
        applied += result.applied;
        removed += result.removed;
      }
    });

    final newest = docs
        .map((d) => d.updatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (best, t) => best == null || t.isAfter(best) ? t : best);
    if (newest != null) {
      await prefs.setString(_cursorKey, newest.toUtc().toIso8601String());
    }
    return (pulled: docs.length, applied: applied, removed: removed);
  }

  Future<int> _push() async {
    final items = <PendingDoc>[];
    for (final h in handlers) {
      items.addAll(await h.pending());
    }
    for (final t in await db.recipeDao.pendingTombstones(spaceId: spaceId)) {
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
    if (items.isEmpty) return 0;

    var pushed = 0;
    for (var i = 0; i < items.length; i += _batchSize) {
      final end = i + _batchSize > items.length ? items.length : i + _batchSize;
      final batch = items.sublist(i, end);
      await remote.push(spaceId, [for (final it in batch) it.doc]);
      for (final it in batch) {
        await it.onSent();
      }
      pushed += batch.length;
    }
    return pushed;
  }
}
