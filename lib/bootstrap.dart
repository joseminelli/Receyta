import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inicialização do app que a splash espera antes de liberar a home (§9.7).
///
/// Hoje não faz nada — resolve na hora. No bloco A7 é aqui que o Drift abre,
/// roda as migrações e confere o seed; a splash já está escrita para segurar
/// a última frame da animação enquanto isto não resolve, sem nunca travar
/// além do orçamento de [SplashTimings].
final appBootstrapProvider = FutureProvider<void>((ref) async {
  // TODO(A7): abrir o Drift, rodar migrações versionadas e semear unidades,
  // qualificadores e categorias.
});
