import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

/// Onde o tour aponta. Cada um vira uma `GlobalKey` que o widget real
/// carrega; o overlay lê a posição dela pra recortar o destaque. Os três
/// últimos ficam nas outras abas (Agenda, Compras, Conta).
enum TutorialTarget {
  create,
  search,
  firstRecipe,
  navBar,
  agenda,
  shoppingCreate,
  accountSettings,
}

class TutorialStep {
  const TutorialStep({
    this.target,
    this.tab = 0,
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Nulo = cartão no meio da tela, sem destaque.
  final TutorialTarget? target;

  /// Aba da casca que precisa estar aberta no passo (0 Receitas, 1 Agenda,
  /// 2 Compras, 3 Conta).
  final int tab;
  final IconData icon;
  final String title;
  final String body;
}

/// O tour é curto de propósito: um recado por cartão, pulável em qualquer
/// um. Os últimos passos levam a pessoa às outras abas em vez de só falar
/// delas.
const kTutorialSteps = [
  TutorialStep(
    icon: Icons.explore_outlined,
    title: 'Um tour rápido',
    body: 'Criei uma receita de exemplo pra você explorar. Ela some sozinha '
        'quando o tour acabar, ou se você pular.',
  ),
  TutorialStep(
    target: TutorialTarget.create,
    icon: Icons.add,
    title: 'Adicionar receitas',
    body: 'Digite, importe de um link, de uma foto ou de um arquivo, ou crie '
        'uma pasta.',
  ),
  TutorialStep(
    target: TutorialTarget.search,
    icon: Icons.search,
    title: 'Buscar',
    body: 'Procure por nome, notas ou tag, e filtre por favoritas ou tempo.',
  ),
  TutorialStep(
    target: TutorialTarget.firstRecipe,
    icon: Icons.restaurant_menu_outlined,
    title: 'Sua receita',
    body: 'Toque pra ver ingredientes e passos. O "Modo cozinha" tem timers e '
        'ajusta as porções.',
  ),
  TutorialStep(
    target: TutorialTarget.agenda,
    tab: 1,
    icon: Icons.calendar_month_outlined,
    title: 'Agenda',
    body: 'Planeje o que cozinhar em cada dia. Deslize para trocar de mês e '
        'toque num dia para escolher as refeições.',
  ),
  TutorialStep(
    target: TutorialTarget.shoppingCreate,
    tab: 2,
    icon: Icons.shopping_cart_outlined,
    title: 'Compras',
    body: 'Crie uma lista a partir das receitas: as quantidades já saem '
        'somadas.',
  ),
  TutorialStep(
    target: TutorialTarget.accountSettings,
    tab: 3,
    icon: Icons.backup_outlined,
    title: 'Guarde uma cópia',
    body: 'O app já faz uma cópia por dia. Nas configurações, em Suas '
        'cópias, você envia uma para fora do aparelho.',
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

/// Aba que o tour pede à casca do app. A casca troca de aba quando muda.
final tutorialTabRequestProvider = StateProvider<int?>((ref) => null);

final tutorialControllerProvider =
    Provider<TutorialController>(TutorialController.new);

/// Conduz o tour: cria a receita de exemplo ao começar e a apaga ao terminar
/// ou pular. O id fica guardado no aparelho: se o app morrer no meio do tour,
/// a receita é apagada na próxima abertura.
class TutorialController {
  TutorialController(this._ref);

  final Ref _ref;

  /// Pede à casca do app a aba [tab]; passa por nulo antes pra repetir o
  /// mesmo pedido ainda mexer (a pessoa pode ter trocado de aba sozinha).
  void _requestTab(int tab) {
    final notifier = _ref.read(tutorialTabRequestProvider.notifier);
    notifier.state = null;
    notifier.state = tab;
  }

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
      _requestTab(0);
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
      final nextStep = step + 1;
      _requestTab(kTutorialSteps[nextStep].tab);
      _ref.read(tutorialStepProvider.notifier).state = nextStep;
    }
  }

  /// Pular e concluir fazem a mesma coisa: fecha o tour e some com o exemplo.
  Future<void> finish() async {
    _ref.read(tutorialStepProvider.notifier).state = null;
    _requestTab(0);
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
