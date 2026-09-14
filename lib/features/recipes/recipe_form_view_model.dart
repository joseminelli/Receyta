import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/models/ingredient.dart';

/// ViewModel do formulário de receita (§5, RF-01.2–01.5). Não conhece Flutter:
/// recebe o texto cru dos campos, descarta linhas vazias, converte números,
/// valida e cria ou atualiza via repositório. Ingredientes e passos viajam
/// como texto livre — o parsing (bloco C) preenche o resto.
class RecipeFormViewModel {
  RecipeFormViewModel(this._repo);

  final RecipeRepository _repo;

  Future<Result<Recipe>> submit({
    Recipe? original,
    required String name,
    String? about,
    String? prepText,
    String? cookText,
    String? servingsText,
    String? notes,
    List<String> ingredientLines = const [],
    List<String> stepLines = const [],
    List<String?> ingredientGroups = const [],
    List<String?> stepGroups = const [],
    List<String?> ingredientIds = const [],
    List<String> tagNames = const [],
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Future.value(const Err(ValidationFailure('Dê um nome à receita')));
    }

    final prep = _parseCount(prepText, 'O tempo de preparo');
    if (prep is Err<int?>) return Future.value(Err(prep.failure));
    final cook = _parseCount(cookText, 'O tempo de cozimento');
    if (cook is Err<int?>) return Future.value(Err(cook.failure));
    final servings = _parseCount(servingsText, 'O rendimento');
    if (servings is Err<int?>) return Future.value(Err(servings.failure));

    final (ingLines, ingGroups, ingIds) =
        _cleanGrouped(ingredientLines, ingredientGroups, ingredientIds);
    final (stepLinesClean, stepGroupsClean, _) =
        _cleanGrouped(stepLines, stepGroups, const []);

    return _repo.saveDetail(
      base: original,
      name: trimmedName,
      about: _blankToNull(about),
      prepMinutes: (prep as Ok<int?>).value,
      cookMinutes: (cook as Ok<int?>).value,
      servings: (servings as Ok<int?>).value,
      notes: _blankToNull(notes),
      ingredientLines: ingLines,
      stepLines: stepLinesClean,
      ingredientGroups: ingGroups,
      stepGroups: stepGroupsClean,
      ingredientIds: ingIds,
      tagNames: tagNames,
    );
  }

  /// Tira linhas vazias mantendo o rótulo de grupo alinhado com o que sobrou.
  (List<String>, List<String?>, List<String?>) _cleanGrouped(
    List<String> lines,
    List<String?> groups,
    List<String?> ids,
  ) {
    final outLines = <String>[];
    final outGroups = <String?>[];
    final outIds = <String?>[];
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i].trim();
      if (text.isEmpty) continue;
      outLines.add(text);
      final g = i < groups.length ? groups[i]?.trim() : null;
      outGroups.add((g == null || g.isEmpty) ? null : g);
      outIds.add(i < ids.length ? ids[i] : null);
    }
    return (outLines, outGroups, outIds);
  }

  Result<int?> _parseCount(String? raw, String field) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return const Ok(null);
    final value = int.tryParse(text);
    if (value == null || value <= 0) {
      return Err(
        ValidationFailure('$field precisa ser um número maior que zero'),
      );
    }
    return Ok(value);
  }

  String? _blankToNull(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

final recipeFormViewModelProvider = Provider<RecipeFormViewModel>(
  (ref) => RecipeFormViewModel(ref.watch(recipeRepositoryProvider)),
);

/// Carrega a receita (com listas) a editar — leitura única para o formulário.
/// `autoDispose`: some quando o form fecha, então reabrir a edição relê do
/// banco (senão o cache mostra a versão anterior, sem as tags recém-salvas).
/// Erro (não encontrada) sobe como `AsyncError`.
final recipeDetailFutureProvider =
    FutureProvider.autoDispose.family<RecipeDetail, String>((ref, id) async {
  final result = await ref.watch(recipeRepositoryProvider).getDetail(id);
  return result.when(ok: (d) => d, err: (f) => throw f);
});

/// Stream da receita para a tela de detalhe (B6) — reflete edições na hora.
final recipeDetailProvider =
    StreamProvider.family<RecipeDetail?, String>((ref, id) {
  return ref.watch(recipeRepositoryProvider).watchDetail(id);
});

/// Todas as tags já cadastradas — o campo de tags do formulário sugere daqui.
final allTagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchAll(),
);

/// Todos os ingredientes já cadastrados — o autocomplete do formulário
/// sugere daqui (C3).
final allIngredientsProvider = StreamProvider<List<Ingredient>>(
  (ref) => ref.watch(ingredientRepositoryProvider).watchAll(),
);
