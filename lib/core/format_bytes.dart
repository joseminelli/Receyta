/// "850 KB", "2,4 MB", "30 MB" — tamanho em português, com vírgula decimal.
/// Abaixo de 10 MB mostra uma casa; acima, número inteiro.
String formatBytes(int bytes) {
  if (bytes < 0) bytes = 0;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = bytes / (1024 * 1024);
  if (mb >= 10) return '${mb.round()} MB';
  return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
}
