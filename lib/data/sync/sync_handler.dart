import 'package:receyta/data/sync/sync_remote.dart';

/// Um item pronto pra subir e o que fazer quando o servidor confirmar.
typedef PendingDoc = ({SyncDoc doc, Future<void> Function() onSent});

/// Quanto um tipo de item mexeu no banco ao aplicar o que veio da nuvem.
typedef ApplyResult = ({int applied, int removed});

/// Ensina o motor de sync a lidar com UM tipo de item (calendário, listas,
/// histórico…). O motor cuida do que é comum — cursor, transação, lotes,
/// avisos de exclusão, repetição — e cada tipo só diz: o que está pendente de
/// envio e como aplicar o que chegou.
abstract class SyncHandler {
  /// O `kind` do item na nuvem (ver `core/sync_kinds.dart`).
  String get kind;

  /// Há algo deste tipo pendente de envio? (barato — o coordenador pergunta a
  /// cada escrita no banco).
  Future<bool> hasPending();

  /// Os itens pendentes de envio.
  Future<List<PendingDoc>> pending();

  /// Aplica no banco os itens deste tipo que vieram da nuvem ([docs] só traz o
  /// [kind] deste tratador, vivos e apagados misturados). Roda DENTRO da
  /// transação do motor, com as chaves estrangeiras adiadas, depois de
  /// receitas e pastas.
  Future<ApplyResult> apply(List<SyncDoc> docs);
}

/// Decide, pra um item que chegou da nuvem, se ele deve sobrescrever o local.
///
/// - não existe aqui: aplica;
/// - existe e NÃO mudou desde a última sincronização: segue a nuvem (se for
///   exatamente a mesma versão, não há o que fazer);
/// - existe e MUDOU aqui (pendente de envio): vence a edição mais recente.
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
