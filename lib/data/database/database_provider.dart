import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Instância única do banco para todo o app. Fechada quando o `ProviderScope`
/// é descartado. Repositórios (bloco B em diante) leem daqui.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
