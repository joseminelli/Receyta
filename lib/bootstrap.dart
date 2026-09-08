import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/database_provider.dart';

/// Inicialização que a splash espera antes de liberar a home (§9.7): abre o
/// Drift, roda as migrações e confere o seed. A splash segura a última frame
/// da animação até isto resolver, sem estourar o orçamento de `SplashTimings`.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(databaseProvider).ensureReady();
});
