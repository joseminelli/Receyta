/// Texto curto de "quando foi a última sincronização" — Dart puro.
library;

/// "agora há pouco", "há 5 min", "há 3 h", "ontem", "há 4 dias" ou a data.
/// [last] e [now] em qualquer fuso; só a diferença importa. Futuro (relógio
/// do aparelho voltou) conta como "agora há pouco".
String formatSyncAgo(DateTime last, DateTime now) {
  final diff = now.difference(last);
  if (diff.inMinutes < 1) return 'agora há pouco';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 7) return 'há ${diff.inDays} dias';
  final d = last.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'em ${two(d.day)}/${two(d.month)}/${d.year}';
}
