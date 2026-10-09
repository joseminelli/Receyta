import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

/// Onde o tour aponta na home. Cada um vira uma `GlobalKey` que o widget
/// real carrega; o overlay lê a posição dela pra recortar o destaque.
enum TutorialTarget { create, search, firstRecipe, navBar }

class TutorialStep {
  const TutorialStep({this.target, required this.title, required this.body});

  /// Nulo = cartão no meio da tela, sem destaque.
  final TutorialTarget? target;
  final String title;
  final String body;
}

/// O tour é curto de propósito: seis cartões, pulável em qualquer um.
const kTutorialSteps = [
  TutorialStep(
    title: 'Um tour rápido',
    body: 'Criei uma receita de exemplo pra você explorar. Ela some sozinha '
        'quando o tour acabar — ou se você pular.',
  ),
  TutorialStep(
    target: TutorialTarget.create,
    title: 'Adicionar receitas',
    body: 'Toque no + pra digitar uma receita, importar de um link, de uma '
        'foto ou de um arquivo .receyta, ou criar uma pasta.',
  ),
  TutorialStep(
    target: TutorialTarget.search,
    title: 'Buscar',
    body: 'Procure por nome, notas ou tag.',
  ),
  TutorialStep(
    target: TutorialTarget.firstRecipe,
    title: 'Sua receita',
    body: 'Toque pra ver ingredientes e passos. No ⋯ você muda a cor, move '
        'de pasta e compartilha; o coração favorita e o "Modo cozinha" tem '
        'timers e ajusta as porções.',
  ),
  TutorialStep(
    target: TutorialTarget.navBar,
    title: 'Agenda, Compras e Conta',
    body: 'A Agenda planeja o que cozinhar, Compras gera a lista a partir das '
        'receitas e Conta guarda os ajustes.',
  ),
  TutorialStep(
    target: TutorialTarget.navBar,
    title: 'Faça backup',
    body: 'Em Conta, toque na engrenagem e escolha Backup. Seus dados ficam '
        'só neste aparelho — guarde uma cópia de vez em quando.',
  ),
];

const _pendingKey = 'tutorial_pending_v1';
const _exampleKey = 'tutorial_example_recipe_id';

/// A introdução terminou: o tour começa assim que a home abrir.
Future<void> markTutorialPending() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingKey, true);
  } catch (e) {
    debugPrint('markTutorialPending: $e');
  }
}

/// Uma `GlobalKey` por alvo, estável durante a vida do app.
final tutorialTargetsProvider = Provider<Map<TutorialTarget, GlobalKey>>(
  (ref) => {
    for (final t in TutorialTarget.values) t: GlobalKey(debugLabel: t.name),
  },
);

/// Passo atual do tour; `null` = tour desligado.
final tutorialStepProvider = StateProvider<int?>((ref) => null);

final tutorialControllerProvider =
    Provider<TutorialController>(TutorialController.new);

/// Conduz o tour: cria a receita de exemplo ao começar e a apaga ao terminar
/// ou pular. O id fica guardado no aparelho: se o app morrer no meio do tour,
/// a receita é apagada na próxima abertura.
class TutorialController {
  TutorialController(this._ref);

  final Ref _ref;

  Future<void> startIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getBool(_pendingKey) ?? false;
      final stale = prefs.getString(_exampleKey);

      if (stale != null && !pending) {
        await _deleteExample(stale);
        await prefs.remove(_exampleKey);
        return;
      }
      if (!pending) return;

      await prefs.remove(_pendingKey);
      final id = await _createExample();
      if (id != null) await prefs.setString(_exampleKey, id);
      _ref.read(tutorialStepProvider.notifier).state = 0;
    } catch (e) {
      debugPrint('Tutorial.startIfNeeded: $e');
    }
  }

  void next() {
    final step = _ref.read(tutorialStepProvider);
    if (step == null) return;
    if (step >= kTutorialSteps.length - 1) {
      finish();
    } else {
      _ref.read(tutorialStepProvider.notifier).state = step + 1;
    }
  }

  /// Pular e concluir fazem a mesma coisa: fecha o tour e some com o exemplo.
  Future<void> finish() async {
    _ref.read(tutorialStepProvider.notifier).state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_exampleKey);
      if (id != null) await _deleteExample(id);
      await prefs.remove(_exampleKey);
    } catch (e) {
      debugPrint('Tutorial.finish: $e');
    }
  }

  Future<String?> _createExample() async {
    final result = await _ref.read(recipeRepositoryProvider).saveDetail(
      name: 'Omelete (receita de exemplo)',
      about: 'Esta receita some quando o tour acabar. Toque nela e '
          'experimente o modo cozinha.',
      prepMinutes: 5,
      cookMinutes: 5,
      servings: 2,
      ingredientLines: const [
        '3 ovos',
        '1 colher de sopa de leite',
        '1 pitada de sal',
        '1 colher de sopa de manteiga',
      ],
      stepLines: const [
        'Bata os ovos com o leite e o sal.',
        'Derreta a manteiga em fogo médio.',
        'Despeje os ovos e deixe firmar por 2 minutos.',
        'Dobre ao meio e sirva.',
      ],
    );
    return result is Ok<Recipe> ? result.value.id : null;
  }

  /// Apaga a receita de vez (não vai pra lixeira) e os ingredientes que ela
  /// criou no catálogo e que ninguém mais usa.
  Future<void> _deleteExample(String id) async {
    final recipes = _ref.read(recipeRepositoryProvider);
    final ingredients = _ref.read(ingredientRepositoryProvider);
    final detail = await recipes.getDetail(id);
    final ingredientIds = detail is Ok<RecipeDetail>
        ? [
            for (final i in detail.value.ingredients)
              if (i.ingredientId != null) i.ingredientId!,
          ]
        : const <String>[];
    await recipes.deleteForever(id);
    for (final ingredientId in ingredientIds.toSet()) {
      await ingredients.delete(ingredientId);
    }
  }
}
