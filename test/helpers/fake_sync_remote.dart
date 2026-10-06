import 'package:receyta/data/sync/sync_remote.dart';

/// Servidor de sync em memória, sem a regra de "o mais novo vence" — pra
/// testes que só querem ver se o sync foi chamado e o que foi enviado.
class FakeSyncRemote implements SyncRemote {
  FakeSyncRemote({this.userId = 'u1'});

  @override
  String? userId;

  final docs = <String, SyncDoc>{};
  int pullCalls = 0;
  int pushCalls = 0;
  bool failPull = false;
  var _clock = DateTime.utc(2026, 1, 1);

  @override
  Future<void> push(List<SyncDoc> incoming) async {
    pushCalls++;
    _clock = _clock.add(const Duration(seconds: 1));
    for (final d in incoming) {
      docs['${d.kind}/${d.id}'] = SyncDoc(
        kind: d.kind,
        id: d.id,
        editedAt: d.editedAt,
        data: d.deleted ? null : d.data,
        deleted: d.deleted,
        updatedAt: _clock,
      );
    }
  }

  @override
  Future<List<SyncDoc>> pullSince(DateTime? since) async {
    pullCalls++;
    if (failPull) throw Exception('sem rede');
    return [
      for (final d in docs.values)
        if (since == null || !d.updatedAt!.isBefore(since)) d,
    ];
  }
}
