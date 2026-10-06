import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Um item sincronizado como ele viaja pela nuvem (uma linha de `sync_docs`).
class SyncDoc {
  const SyncDoc({
    required this.kind,
    required this.id,
    required this.editedAt,
    this.data,
    this.deleted = false,
    this.updatedAt,
  });

  /// `recipe` ou `folder` (ver `sync_codec.dart`).
  final String kind;
  final String id;

  /// Corpo do item; nulo quando [deleted].
  final Map<String, dynamic>? data;
  final bool deleted;

  /// Quando foi editado de verdade (relógio do aparelho que editou).
  final DateTime editedAt;

  /// Relógio do servidor na gravação — só vem nas leituras; é o cursor.
  final DateTime? updatedAt;
}

/// O que o sync precisa da nuvem. Injetável pra o teste não usar rede.
abstract class SyncRemote {
  /// `null` = ninguém logado: o sync não faz nada.
  String? get userId;

  /// Grava (cria ou atualiza) os itens. O servidor descarta, por conta
  /// própria, o que for mais velho que o já gravado.
  Future<void> push(List<SyncDoc> docs);

  /// Todos os itens com `updated_at` a partir de [since] (todos, se nulo), em
  /// ordem de `updated_at`.
  Future<List<SyncDoc>> pullSince(DateTime? since);

  /// Avisos em tempo real de que a conta mudou (outro aparelho gravou). Cancelar
  /// a escuta fecha o canal.
  Stream<void> changes();
}

class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final sb.SupabaseClient _client;

  static const _table = 'sync_docs';
  static const _pageSize = 1000;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> push(List<SyncDoc> docs) async {
    final uid = userId;
    if (uid == null || docs.isEmpty) return;
    await _client.from(_table).upsert(
      [
        for (final d in docs)
          {
            'user_id': uid,
            'kind': d.kind,
            'id': d.id,
            'data': d.deleted ? null : d.data,
            'deleted': d.deleted,
            'edited_at': d.editedAt.toUtc().toIso8601String(),
          },
      ],
      onConflict: 'user_id,kind,id',
    );
  }

  @override
  Future<List<SyncDoc>> pullSince(DateTime? since) async {
    final out = <SyncDoc>[];
    for (var offset = 0;; offset += _pageSize) {
      var query = _client
          .from(_table)
          .select('kind, id, data, deleted, edited_at, updated_at');
      if (since != null) {
        query = query.gte('updated_at', since.toUtc().toIso8601String());
      }
      final rows = await query
          .order('updated_at', ascending: true)
          .order('kind', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + _pageSize - 1);
      for (final row in rows) {
        final edited = DateTime.tryParse('${row['edited_at']}');
        if (edited == null) continue;
        out.add(SyncDoc(
          kind: '${row['kind']}',
          id: '${row['id']}',
          data: row['data'] is Map
              ? Map<String, dynamic>.from(row['data'] as Map)
              : null,
          deleted: row['deleted'] == true,
          editedAt: edited.toUtc(),
          updatedAt: DateTime.tryParse('${row['updated_at']}')?.toUtc(),
        ));
      }
      if (rows.length < _pageSize) return out;
    }
  }

  @override
  Stream<void> changes() {
    final uid = userId;
    if (uid == null) return const Stream.empty();
    late final StreamController<void> controller;
    sb.RealtimeChannel? channel;
    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('sync-$uid')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: _table,
              filter: sb.PostgresChangeFilter(
                type: sb.PostgresChangeFilterType.eq,
                column: 'user_id',
                value: uid,
              ),
              callback: (_) {
                if (!controller.isClosed) controller.add(null);
              },
            )
            .subscribe((status, error) {
          debugPrint('Realtime sync_docs: $status ${error ?? ''}');
        });
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _client.removeChannel(c);
      },
    );
    return controller.stream;
  }
}

/// Usado quando o Supabase não inicializou.
class NoSyncRemote implements SyncRemote {
  const NoSyncRemote();

  @override
  String? get userId => null;

  @override
  Future<void> push(List<SyncDoc> docs) async {}

  @override
  Future<List<SyncDoc>> pullSince(DateTime? since) async => const [];

  @override
  Stream<void> changes() => const Stream.empty();
}

final syncRemoteProvider = Provider<SyncRemote>((ref) {
  try {
    return SupabaseSyncRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoSyncRemote();
  }
});
