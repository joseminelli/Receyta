import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipes;
  late CookLogRepository logs;
  late MealPlanRepository plan;
  late DateTime clock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = DateTime.utc(2026, 10, 1, 12);
    recipes = RecipeRepository(
      db.recipeDao,
      db.tagDao,
      db.ingredientDao,
      clock: () => clock,
    );
    logs = CookLogRepository(db.cookLogDao, clock: () => clock);
    plan = MealPlanRepository(db.mealPlanDao, clock: () => clock);
  });

  tearDown(() => db.close());

  Future<Recipe> newRecipe(String name) async =>
      (await recipes.saveDetail(name: name) as Ok<Recipe>).value;

  test('registra, lista do mais recente ao mais antigo e apaga', () async {
    final r = await newRecipe('Bolo');

    await logs.add(r.id, cookedAt: DateTime.utc(2026, 9, 1, 12));
    final second =
        await logs.add(r.id, cookedAt: DateTime.utc(2026, 9, 20, 12));
    await logs.add(r.id, note: '  ficou ótimo  ');

    var list = await logs.watchForRecipe(r.id).first;
    expect(list, hasLength(3));
    expect(list.first.note, 'ficou ótimo');
    expect(list.map((l) => l.cookedAt.isBefore(DateTime.utc(2026, 9, 21))),
        [false, true, true]);

    await logs.remove((second as Ok<String>).value);
    list = await logs.watchForRecipe(r.id).first;
    expect(list, hasLength(2));
  });

  test('nota em branco não é gravada', () async {
    final r = await newRecipe('Bolo');

    await logs.add(r.id, note: '   ');

    final list = await logs.watchForRecipe(r.id).first;
    expect(list.single.note, isNull);
    expect(list.single.hasNote, isFalse);
  });

  test('apagar a receita de vez leva o histórico junto', () async {
    final r = await newRecipe('Bolo');
    await logs.add(r.id);

    await recipes.deleteForever(r.id);

    expect(await logs.watchForRecipe(r.id).first, isEmpty);
  });

  test(
      'receita na lixeira some das listas gerais mas o histórico volta com ela',
      () async {
    final r = await newRecipe('Bolo');
    await logs.add(r.id);

    await recipes.softDelete(r.id);
    expect(await logs.watchAll().first, isEmpty);

    await recipes.restore(r.id);
    final all = await logs.watchAll().first;
    expect(all.single.recipeName, 'Bolo');
  });

  group('refeição planejada marcada como feita', () {
    test('entra no histórico uma vez só e sai ao desmarcar', () async {
      final r = await newRecipe('Bolo');
      final entryId = (await plan.add(
        r.id,
        DateTime(2026, 10, 1),
        MealType.lunch,
      ) as Ok<String>)
          .value;

      await plan.setDone(entryId, true);
      await plan.setDone(entryId, true);
      expect(await logs.watchForRecipe(r.id).first, hasLength(1));

      await plan.setDone(entryId, false);
      expect(await logs.watchForRecipe(r.id).first, isEmpty);
    });

    test('não mexe nos registros feitos à mão', () async {
      final r = await newRecipe('Bolo');
      await logs.add(r.id, note: 'à mão');
      final entryId = (await plan.add(
        r.id,
        DateTime(2026, 10, 1),
        MealType.lunch,
      ) as Ok<String>)
          .value;

      await plan.setDone(entryId, true);
      await plan.setDone(entryId, false);

      final list = await logs.watchForRecipe(r.id).first;
      expect(list.single.note, 'à mão');
    });
  });

  group('cozinhei no modo cozinha com a receita na agenda de hoje', () {
    Future<String> schedule(Recipe r, DateTime day, MealType type) async =>
        (await plan.add(r.id, day, type) as Ok<String>).value;

    Future<List<MealPlanEntry>> entriesOfToday() =>
        plan.watchRange(DateTime(2026, 10, 1), DateTime(2026, 10, 2)).first;

    test('marca a refeição de hoje como feita e grava um registro só',
        () async {
      final r = await newRecipe('Bolo');
      final id = await schedule(r, DateTime(2026, 10, 1), MealType.lunch);

      final result = await plan.markCookedToday(r.id);

      expect((result as Ok<String?>).value, id);
      expect((await entriesOfToday()).single.done, isTrue);
      expect(await logs.watchForRecipe(r.id).first, hasLength(1));
    });

    test('sem agendamento hoje, não faz nada e devolve nulo', () async {
      final r = await newRecipe('Bolo');
      await schedule(r, DateTime(2026, 10, 2), MealType.lunch);

      final result = await plan.markCookedToday(r.id);

      expect((result as Ok<String?>).value, isNull);
      expect(await logs.watchForRecipe(r.id).first, isEmpty);
    });

    test('refeição já feita hoje não é marcada de novo', () async {
      final r = await newRecipe('Bolo');
      final id = await schedule(r, DateTime(2026, 10, 1), MealType.lunch);
      await plan.setDone(id, true);

      final result = await plan.markCookedToday(r.id);

      expect((result as Ok<String?>).value, isNull);
      expect(await logs.watchForRecipe(r.id).first, hasLength(1));
    });

    test('agendada duas vezes hoje: marca só a mais antiga', () async {
      final r = await newRecipe('Bolo');
      clock = DateTime.utc(2026, 10, 1, 9);
      final first = await schedule(r, DateTime(2026, 10, 1), MealType.lunch);
      clock = DateTime.utc(2026, 10, 1, 10);
      await schedule(r, DateTime(2026, 10, 1), MealType.dinner);
      clock = DateTime.utc(2026, 10, 1, 12);

      final result = await plan.markCookedToday(r.id);

      expect((result as Ok<String?>).value, first);
      final today = await entriesOfToday();
      expect(today.where((e) => e.done), hasLength(1));
    });

    test('só olha a receita pedida', () async {
      final bolo = await newRecipe('Bolo');
      final sopa = await newRecipe('Sopa');
      await schedule(sopa, DateTime(2026, 10, 1), MealType.dinner);

      final result = await plan.markCookedToday(bolo.id);

      expect((result as Ok<String?>).value, isNull);
      expect((await entriesOfToday()).single.done, isFalse);
    });

    test('desfazer (desmarcar) tira o registro do histórico', () async {
      final r = await newRecipe('Bolo');
      await schedule(r, DateTime(2026, 10, 1), MealType.lunch);
      final id = ((await plan.markCookedToday(r.id)) as Ok<String?>).value!;

      await plan.setDone(id, false);

      expect(await logs.watchForRecipe(r.id).first, isEmpty);
      expect((await entriesOfToday()).single.done, isFalse);
    });
  });

  test('limpar dados apaga o histórico', () async {
    final r = await newRecipe('Bolo');
    await logs.add(r.id);

    await db.wipeUserData();

    expect(await logs.watchAll().first, isEmpty);
  });
}
