import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/domain/models/cook_log.dart';

/// Todo o histórico "cozinhei", com o nome da receita, do mais recente ao
/// mais antigo (receitas na lixeira ficam de fora).
final allCookLogsProvider = StreamProvider.autoDispose<List<CookLog>>(
  (ref) => ref.watch(cookLogRepositoryProvider).watchAll(),
);

/// Histórico "cozinhei" de uma receita, do mais recente ao mais antigo.
final cookLogsProvider =
    StreamProvider.autoDispose.family<List<CookLog>, String>(
  (ref, recipeId) =>
      ref.watch(cookLogRepositoryProvider).watchForRecipe(recipeId),
);
