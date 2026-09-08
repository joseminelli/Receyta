import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/database_provider.dart';

/// Inicialização do app que a splash espera antes de liberar a home (§9.7).
///
/// Abre o Drift, roda as migrações versionadas e confere o seed (unidades,
/// qualificadores e categorias). A splash já está escrita para segurar a última
/// frame da animação enquanto isto não resolve, sem nunca travar além do
/// orçamento de [SplashTimings] — o banco normalmente responde bem antes.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(databaseProvider).ensureReady();
});
