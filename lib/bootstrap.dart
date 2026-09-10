import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';

/// Inicialização que a splash espera antes de liberar a home (§9.7): abre o
/// Drift, roda as migrações e confere o seed, e faz a faxina da lixeira de 30
/// dias (RF-01.6). A splash segura a última frame da animação até isto
/// resolver, sem estourar o orçamento de `SplashTimings`.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(databaseProvider).ensureReady();
  await ref.read(recipeRepositoryProvider).purgeExpired();
});
