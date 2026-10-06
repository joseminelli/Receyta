import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';

/// Quanto esperar depois da abertura pra rodar a manutenção em segundo plano
/// (deixa a home aparecer e o primeiro gesto passar antes de mexer no
/// banco). `null` = não agenda — os testes usam isso e chamam
/// [runAppMaintenance] direto.
final maintenanceDelayProvider = Provider<Duration?>(
  (ref) => const Duration(milliseconds: 1500),
);

/// Inicialização que a splash espera antes de liberar a home (§9.7): só o
/// que a home precisa pra desenhar — abrir o Drift, rodar as migrações e
/// conferir o seed. A faxina da lixeira e o reprocessamento de ingredientes
/// antigos saem do caminho da abertura e rodam depois ([runAppMaintenance]):
/// o usuário não precisa esperar por eles, e o custo deles cresce com o
/// volume de dados.
///
/// Cada passo marca um trecho na linha do tempo (DevTools → Performance →
/// Timeline: `bootstrap.*`) e, em debug, loga a duração — é como se mede a
/// abertura de verdade (em `--profile`, não em debug).
final appBootstrapProvider = FutureProvider<void>((ref) async {
  await _timed(
    'bootstrap.ensureReady',
    () => ref.watch(databaseProvider).ensureReady(),
  );

  final delay = ref.read(maintenanceDelayProvider);
  if (delay != null) {
    final recipes = ref.read(recipeRepositoryProvider);
    final images = ref.read(recipeImageServiceProvider);
    final imageSync = ref.read(recipeImageSyncProvider);
    unawaited(
      Future<void>.delayed(delay).then(
        (_) => runAppMaintenance(recipes, images: images, imageSync: imageSync),
      ),
    );
  }
});

/// Manutenção que não precisa bloquear a abertura: apaga da lixeira o que
/// passou de 30 dias (RF-01.6) e resolve ingredientes de receitas antigas
/// (C5). Nunca lança — falha aqui não pode derrubar o app, só vira log.
/// Com [imageSync], manda pra nuvem as fotos pendentes (só se logado). Com
/// [images], apaga também as fotos que nenhuma receita usa mais (receita
/// apagada de vez, foto trocada).
Future<void> runAppMaintenance(
  RecipeRepository recipes, {
  RecipeImageService? images,
  RecipeImageSync? imageSync,
}) async {
  try {
    await _timed('bootstrap.purgeExpired', recipes.purgeExpired);
    if (imageSync != null) {
      await _timed('bootstrap.imageSync', imageSync.syncPending);
    }
    if (images != null) {
      await _timed(
        'bootstrap.deleteOrphanImages',
        () async => images.deleteOrphans(await recipes.referencedImagePaths()),
      );
    }
    await _timed(
      'bootstrap.reprocessLegacyIngredients',
      recipes.reprocessLegacyIngredients,
    );
  } catch (e) {
    debugPrint('runAppMaintenance: $e');
  }
}

/// Mede [body] numa tarefa assíncrona da Timeline e, em debug, loga a
/// duração.
Future<T> _timed<T>(String name, Future<T> Function() body) async {
  final task = developer.TimelineTask()..start(name);
  final watch = Stopwatch()..start();
  try {
    return await body();
  } finally {
    watch.stop();
    task.finish();
    if (kDebugMode) debugPrint('[$name] ${watch.elapsedMilliseconds} ms');
  }
}
