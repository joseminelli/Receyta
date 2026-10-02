import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Porções escolhidas no modo cozinha (RF-01.12), por receita. `null` = o
/// rendimento da receita. Vale só enquanto o modo cozinha está aberto; a
/// receita salva e a tela de detalhe não mudam.
final selectedServingsProvider =
    StateProvider.autoDispose.family<int?, String>((ref, recipeId) => null);
