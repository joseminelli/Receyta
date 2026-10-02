import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/domain/models/cook_log.dart';

/// Histórico "cozinhei" de uma receita, do mais recente ao mais antigo.
final cookLogsProvider =
    StreamProvider.autoDispose.family<List<CookLog>, String>(
  (ref, recipeId) =>
      ref.watch(cookLogRepositoryProvider).watchForRecipe(recipeId),
);
