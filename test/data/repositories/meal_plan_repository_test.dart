import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipeRepo;
  late MealPlanRepository planRepo;
  late ShoppingListRepository shoppingRepo;
  late Recipe bolo;
  late Recipe sopa;

  final monday = DateTime.utc(2026, 9, 28);
  final sunday = DateTime.utc(2026, 10, 4);

  Future<List<MealPlanEntry>> week() =>
      planRepo.watchRange(monday, addDays(monday, 7)).first;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recipeRepo =
        RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    planRepo = MealPlanRepository(db.mealPlanDao);
    shoppingRepo = ShoppingListRepository(
      db.shoppingListDao,
      db.recipeDao,
      db.ingredientDao,
    );
    bolo = (await recipeRepo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['500g de farinha de trigo', '2 ovos'],
    ) as Ok<Recipe>)
        .value;
    sopa = (await recipeRepo.saveDetail(
      name: 'Sopa',
      ingredientLines: ['300g de farinha de trigo', '1 cebola'],
    ) as Ok<Recipe>)
        .value;
  });

  tearDown(() => db.close());

  test('agenda, lê só a semana pedida e normaliza a data', () async {
    await planRepo.add(bolo.id, DateTime(2026, 9, 30, 18, 45), MealType.dinner);
    await planRepo.add(sopa.id, sunday, MealType.lunch);
    await planRepo.add(sopa.id, DateTime.utc(2026, 10, 5), MealType.lunch);
    await planRepo.add(sopa.id, DateTime.utc(2026, 9, 27), MealType.lunch);

    final entries = await week();
    expect(entries.map((e) => e.recipeName), ['Bolo', 'Sopa']);
    expect(entries.first.date, DateTime.utc(2026, 9, 30));
    expect(entries.first.mealType, MealType.dinner);
    expect(entries.last.date, sunday);
  });

  test('mover troca dia e refeição; duplicar copia sem marcar como feita',
      () async {
    final id = (await planRepo.add(bolo.id, monday, MealType.lunch) as Ok<String>)
        .value;
    await planRepo.setDone(id, true);

    await planRepo.move(id, addDays(monday, 2), MealType.dinner);
    var entries = await week();
    expect(entries.single.date, addDays(monday, 2));
    expect(entries.single.mealType, MealType.dinner);
    expect(entries.single.done, isTrue);

    final copyId = (await planRepo.duplicate(id, addDays(monday, 3), MealType.lunch)
            as Ok<String>)
        .value;
    entries = await week();
    expect(entries, hasLength(2));
    final copy = entries.firstWhere((e) => e.id == copyId);
    expect((copy.date, copy.mealType, copy.done),
        (addDays(monday, 3), MealType.lunch, false));

    expect(await planRepo.duplicate('x', monday, MealType.lunch),
        isA<Err<String>>());
  });

  test('remover e desfazer (restore)', () async {
    final id = (await planRepo.add(bolo.id, monday, MealType.snack) as Ok<String>)
        .value;
    final entry = (await week()).single;

    await planRepo.remove(id);
    expect(await week(), isEmpty);

    await planRepo.restore(entry);
    final back = (await week()).single;
    expect((back.recipeId, back.date, back.mealType),
        (bolo.id, monday, MealType.snack));
  });

  test('receita na lixeira some do plano; apagar a receita leva as entradas',
      () async {
    await planRepo.add(bolo.id, monday, MealType.lunch);
    await planRepo.add(sopa.id, monday, MealType.dinner);

    await recipeRepo.softDelete(sopa.id);
    expect((await week()).map((e) => e.recipeName), ['Bolo']);

    await recipeRepo.restore(sopa.id);
    expect(await week(), hasLength(2));

    await recipeRepo.deleteForever(bolo.id);
    expect((await week()).map((e) => e.recipeName), ['Sopa']);
  });

  test('upcoming: pendentes dos próximos 14 dias, em ordem, no máximo 5',
      () async {
    final from = DateTime.utc(2026, 9, 29);
    final doneId = (await planRepo.add(bolo.id, from, MealType.breakfast)
            as Ok<String>)
        .value;
    await planRepo.setDone(doneId, true);
    await planRepo.add(sopa.id, addDays(from, 2), MealType.lunch);
    await planRepo.add(bolo.id, from, MealType.dinner);
    await planRepo.add(sopa.id, from, MealType.lunch);
    await planRepo.add(bolo.id, addDays(from, 1), MealType.snack);
    await planRepo.add(sopa.id, addDays(from, 3), MealType.dinner);
    await planRepo.add(bolo.id, addDays(from, 13), MealType.lunch);
    await planRepo.add(bolo.id, addDays(from, 14), MealType.lunch);
    await planRepo.add(bolo.id, addDays(from, -1), MealType.lunch);

    final container = ProviderContainer(
      overrides: [mealPlanRepositoryProvider.overrideWithValue(planRepo)],
    );
    addTearDown(container.dispose);
    final upcoming = await container.read(upcomingEntriesProvider(from).future);

    expect(upcoming, hasLength(5));
    expect(
      upcoming.map((e) => (e.date, e.mealType)),
      [
        (from, MealType.lunch),
        (from, MealType.dinner),
        (addDays(from, 1), MealType.snack),
        (addDays(from, 2), MealType.lunch),
        (addDays(from, 3), MealType.dinner),
      ],
    );
    expect(upcoming.any((e) => e.done), isFalse);
  });

  test('pendingRecipeCounts conta repetições e ignora feitas e passadas', () {
    MealPlanEntry e(String recipe, DateTime d, {bool done = false}) =>
        MealPlanEntry(
          id: '$recipe$d',
          recipe: Recipe(
            id: recipe,
            name: recipe,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          date: d,
          mealType: MealType.lunch,
          done: done,
        );
    final counts = pendingRecipeCounts(
      [
        e('a', DateTime.utc(2026, 9, 28)),
        e('a', DateTime.utc(2026, 9, 30)),
        e('a', DateTime.utc(2026, 10, 1)),
        e('b', DateTime.utc(2026, 9, 30), done: true),
        e('c', DateTime.utc(2026, 10, 2)),
      ],
      DateTime.utc(2026, 9, 29),
    );
    expect(counts, {'a': 2, 'c': 1});
  });

  test('lista da semana: receita 2× pede ingredientes em dobro', () async {
    final list = (await shoppingRepo.generateFromRecipes(
      [bolo.id, sopa.id],
      name: 'Semana',
      counts: {bolo.id: 2, sopa.id: 1},
    ) as Ok<ShoppingList>)
        .value;

    final items = await shoppingRepo.itemsOf(list.id);
    final farinha = items.firstWhere((i) => i.displayName == 'Farinha de Trigo');
    expect((farinha.quantity, farinha.unitId), (1.3, 'kg'));
    final ovos = items.firstWhere((i) => i.displayName == 'Ovos');
    expect(ovos.quantity, 4);
    final fromBolo = farinha.sources.firstWhere((s) => s.recipeName == 'Bolo');
    expect((fromBolo.quantity, fromBolo.unitId), (1000, 'g'));
  });

  test('addRecipesToList pula receita que já está e soma o resto', () async {
    final list = (await shoppingRepo.generateFromRecipes([bolo.id]) as Ok<ShoppingList>)
        .value;

    final result = await shoppingRepo
        .addRecipesToList(list.id, {bolo.id: 1, sopa.id: 2});
    expect(result, isA<Ok<void>>());

    final items = await shoppingRepo.itemsOf(list.id);
    final farinha = items.firstWhere((i) => i.displayName == 'Farinha de Trigo');
    expect((farinha.quantity, farinha.unitId), (1.1, 'kg'));
    expect(items.firstWhere((i) => i.displayName == 'Cebola').quantity, 2);

    expect(await shoppingRepo.addRecipesToList(list.id, {bolo.id: 1, sopa.id: 1}),
        isA<Err<void>>());
  });
}
