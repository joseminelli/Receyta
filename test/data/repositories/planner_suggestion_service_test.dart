import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/planner_suggestion_service.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/planner_suggestion.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipeRepo;
  late MealPlanRepository planRepo;
  late PlannerSuggestionService service;

  // Terça-feira de uma semana qualquer.
  final tuesday = DateTime.utc(2026, 9, 29);

  Future<Recipe> recipe(String name, List<String> lines) async =>
      (await recipeRepo.saveDetail(name: name, ingredientLines: lines)
              as Ok<Recipe>)
          .value;

  Future<List<PlannerSuggestion>> suggest({DateTime? day}) async {
    final d = day ?? tuesday;
    final window = await planRepo
        .watchRange(addDays(d, -14), addDays(d, 15))
        .first;
    return service.suggestionsFor(d, window);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recipeRepo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    planRepo = MealPlanRepository(db.mealPlanDao);
    service = PlannerSuggestionService(db.recipeDao, db.ingredientDao);
  });

  tearDown(() => db.close());

  test('sugere quem divide ingrediente com a semana, com o motivo', () async {
    final planned = await recipe(
      'Frango com gengibre',
      ['500g de frango', '1 colher de gengibre'],
    );
    await recipe(
      'Strogonoff',
      ['400g de frango', '1 cebola', '200ml de creme de leite'],
    );
    await recipe('Bolo', ['2 ovos', '300g de farinha de trigo']);
    await planRepo.add(planned.id, tuesday, MealType.dinner);

    final result = await suggest();

    expect(result.map((s) => s.recipe.name), ['Strogonoff']);
    expect(result.single.sharedIngredientNames, ['Frango']);
    expect(result.single.reason, 'usa frango, que você já vai comprar');
  });

  test('não sugere a que já está na semana, nem sem nada pendente', () async {
    final a = await recipe('Frango com gengibre', ['500g de frango']);
    final b = await recipe('Strogonoff', ['400g de frango', '1 cebola']);
    final aId = (await planRepo.add(a.id, tuesday, MealType.dinner)
            as Ok<String>)
        .value;
    await planRepo.add(b.id, addDays(tuesday, 2), MealType.lunch);

    // Strogonoff já está na semana: nada pra sugerir.
    expect(await suggest(), isEmpty);

    // Tudo feito = nada que "você já vai comprar".
    await planRepo.setDone(aId, true);
    final bEntry = (await planRepo
            .watchRange(tuesday, addDays(tuesday, 7))
            .first)
        .firstWhere((e) => e.recipeId == b.id);
    await planRepo.setDone(bEntry.id, true);
    await recipe('Sopa', ['400g de frango']);
    expect(await suggest(), isEmpty);
  });

  test('semana vazia não sugere nada', () async {
    await recipe('Strogonoff', ['400g de frango']);
    expect(await suggest(), isEmpty);
  });

  test('a agendada há poucos dias fica atrás da que não foi agendada',
      () async {
    final planned = await recipe('Frango com gengibre', ['500g de frango']);
    final recent = await recipe('Strogonoff', ['400g de frango', '1 cebola']);
    await recipe('Frango assado', ['400g de frango', '1 cebola']);
    await planRepo.add(planned.id, tuesday, MealType.dinner);
    // Semana passada: fora da semana (pode ser sugerida), mas recente.
    await planRepo.add(recent.id, addDays(tuesday, -5), MealType.lunch);

    final result = await suggest();

    expect(result.map((s) => s.recipe.name), ['Frango assado', 'Strogonoff']);
    expect(result.first.score, greaterThan(result.last.score));
  });

  test('receita na lixeira não é sugerida', () async {
    final planned = await recipe('Frango com gengibre', ['500g de frango']);
    final trashed = await recipe('Strogonoff', ['400g de frango']);
    await planRepo.add(planned.id, tuesday, MealType.dinner);
    await recipeRepo.softDelete(trashed.id);

    expect(await suggest(), isEmpty);
  });

  group('PlannerSuggestion.reason', () {
    PlannerSuggestion with_(List<String> names) => PlannerSuggestion(
          recipe: Recipe(
            id: 'r',
            name: 'R',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          score: 1,
          sharedIngredientNames: names,
        );

    test('um, dois, três nomes (e só os três primeiros)', () {
      expect(with_(['Frango']).reason, 'usa frango, que você já vai comprar');
      expect(
        with_(['Frango', 'Gengibre']).reason,
        'usa frango e gengibre, que você já vai comprar',
      );
      expect(
        with_(['Frango', 'Gengibre', 'Cebola', 'Alho']).reason,
        'usa frango, gengibre e cebola, que você já vai comprar',
      );
      expect(with_(const []).reason, 'combina com o que você já vai comprar');
    });
  });

  group('defaultMealFor', () {
    MealPlanEntry e(MealType m) => MealPlanEntry(
          id: m.code,
          recipe: Recipe(
            id: m.code,
            name: m.code,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          date: tuesday,
          mealType: m,
        );

    test('primeira refeição vazia: almoço, jantar, café, lanche', () {
      expect(defaultMealFor(const []), MealType.lunch);
      expect(defaultMealFor([e(MealType.lunch)]), MealType.dinner);
      expect(
        defaultMealFor([e(MealType.lunch), e(MealType.dinner)]),
        MealType.breakfast,
      );
      expect(
        defaultMealFor([for (final m in MealType.values) e(m)]),
        MealType.lunch,
      );
    });
  });
}
