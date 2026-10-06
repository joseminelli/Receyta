import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/data/sync/sync_remote.dart';

/// O que mudou na casa, vindo do Realtime.
enum SharedChange {
  /// Alguém mexeu num item compartilhado: vale uma rodada de sync.
  docs,

  /// Entrou ou saiu alguém: vale reler quem faz parte da casa.
  members,
}

/// Os itens de uma casa na nuvem (`shared_docs`). Mesmo formato do
/// `SyncRemote` da conta, mas de uma casa em vez de uma pessoa. Injetável pra
/// o teste não usar rede.
abstract class SharedRemote {
  /// `null` = ninguém logado.
  String? get userId;

  Future<void> push(String spaceId, List<SyncDoc> docs);

  Future<List<SyncDoc>> pullSince(String spaceId, DateTime? since);

  /// Avisos em tempo real de que a casa mudou. Cancelar a escuta fecha o canal.
  Stream<SharedChange> changes(String spaceId);
}

class SupabaseSharedRemote implements SharedRemote {
  SupabaseSharedRemote(this._client);

  final sb.SupabaseClient _client;

  static const _table = 'shared_docs';
  static const _pageSize = 1000;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> push(String spaceId, List<SyncDoc> docs) async {
    if (userId == null || docs.isEmpty) return;
    await _client.from(_table).upsert(
      [
        for (final d in docs)
          {
            'space_id': spaceId,
            'kind': d.kind,
            'id': d.id,
            'data': d.deleted ? null : d.data,
            'deleted': d.deleted,
            'edited_at': d.editedAt.toUtc().toIso8601String(),
          },
      ],
      onConflict: 'space_id,kind,id',
    );
  }

  @override
  Future<List<SyncDoc>> pullSince(String spaceId, DateTime? since) async {
    final out = <SyncDoc>[];
    for (var offset = 0;; offset += _pageSize) {
      var query = _client
          .from(_table)
          .select('kind, id, data, deleted, edited_at, updated_at')
          .eq('space_id', spaceId);
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
  Stream<SharedChange> changes(String spaceId) {
    late final StreamController<SharedChange> controller;
    final channels = <sb.RealtimeChannel>[];

    sb.RealtimeChannel listen(String table, SharedChange change) {
      return _client
          .channel('$table-$spaceId')
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'space_id',
              value: spaceId,
            ),
            callback: (_) {
              if (!controller.isClosed) controller.add(change);
            },
          )
          .subscribe();
    }

    controller = StreamController<SharedChange>(
      onListen: () {
        channels
          ..add(listen(_table, SharedChange.docs))
          ..add(listen('space_members', SharedChange.members));
      },
      onCancel: () async {
        for (final c in channels) {
          await _client.removeChannel(c);
        }
        channels.clear();
      },
    );
    return controller.stream;
  }
}

/// Usado quando o Supabase não inicializou.
class NoSharedRemote implements SharedRemote {
  const NoSharedRemote();

  @override
  String? get userId => null;

  @override
  Future<void> push(String spaceId, List<SyncDoc> docs) async {}

  @override
  Future<List<SyncDoc>> pullSince(String spaceId, DateTime? since) async =>
      const [];

  @override
  Stream<SharedChange> changes(String spaceId) => const Stream.empty();
}

final sharedRemoteProvider = Provider<SharedRemote>((ref) {
  try {
    return SupabaseSharedRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoSharedRemote();
  }
});
