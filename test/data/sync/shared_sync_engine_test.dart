import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/sync/shared_meal_sync.dart';
import 'package:receyta/data/sync/shared_remote.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/data/sync/sync_engine.dart';
import 'package:receyta/data/sync/sync_handlers.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/sync_harness.dart';

const _space = 'casa-1';

/// O servidor da casa: mesma regra do trigger do SQL (o `edited_at` mais velho
/// é descartado), indexado por (casa, tipo, id).
class _SharedServer {
  final rows = <String, SyncDoc>{};
  var _tick = DateTime.utc(2026, 1, 1);
  DateTime next() => _tick = _tick.add(const Duration(seconds: 1));
}

class _SharedRemote implements SharedRemote {
  _SharedRemote(this.server, this.userId);

  final _SharedServer server;

  @override
  String? userId;

  @override
  Future<void> push(String spaceId, List<SyncDoc> docs) async {
    final stamp = server.next();
    for (final d in docs) {
      final key = '$spaceId/${d.kind}/${d.id}';
      final old = server.rows[key];
      if (old != null && d.editedAt.isBefore(old.editedAt)) continue;
      server.rows[key] = SyncDoc(
        kind: d.kind,
        id: d.id,
        editedAt: d.editedAt,
        data: d.deleted ? null : d.data,
        deleted: d.deleted,
        updatedAt: stamp,
      );
    }
  }

  @override
  Future<List<SyncDoc>> pullSince(String spaceId, DateTime? since) async {
    return [
      for (final e in server.rows.entries)
        if (e.key.startsWith('$spaceId/') &&
            (since == null || !e.value.updatedAt!.isBefore(since)))
          e.value,
    ]..sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));
  }

  @override
  Stream<SharedChange> changes(String spaceId) => const Stream.empty();
}

/// Um aparelho de uma pessoa: banco próprio, o motor da conta e o da casa.
class _Phone {
  _Phone(this.name, _SharedServer shared, SyncServer personal, String user) {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final remote = ServerRemote(personal)..userId = user;
    recipes = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    personalEngine = SyncEngine(remote: remote, db: db, recipes: recipes);
    sharedEngine = SharedSyncEngine(
      remote: _SharedRemote(shared, user),
      db: db,
      spaceId: _space,
      handlers: sharedSyncHandlers(
        db,
        _space,
        meals: SharedMealSync(
          db,
          spaceId: _space,
          myId: user,
          myName: () async => name,
          snapshotOf: (id) => mealRecipeSnapshot(db, recipes, id),
        ),
      ),
    );
  }

  final String name;
  late final AppDatabase db;
  late final RecipeRepository recipes;
  late final SyncEngine personalEngine;
  late final SharedSyncEngine sharedEngine;
  Map<String, Object> prefs = {};

  Future<T> _withPrefs<T>(Future<T> Function() run) async {
    SharedPreferences.setMockInitialValues(Map.of(prefs));
    final out = await run();
    final saved = await SharedPreferences.getInstance();
    prefs = {for (final k in saved.getKeys()) k: saved.get(k)!};
    return out;
  }

  Future<SyncReport> personal() async {
    final r = await _withPrefs(personalEngine.sync);
    expect(r.isOk, isTrue, reason: '$name conta: ${r is Err ? r : ''}');
    return r.valueOrNull!;
  }

  Future<SyncReport> shared() async {
    final r = await _withPrefs(sharedEngine.sync);
    expect(r.isOk, isTrue, reason: '$name casa: ${r is Err ? r : ''}');
    return r.valueOrNull!;
  }

  Future<String> newList(String listName, List<String> items) async {
    final list = await db.shoppingListDao
        .create(name: listName, items: const [], at: DateTime.utc(2026, 2, 1));
    for (final i in items) {
      await db.shoppingListDao.addItem(listId: list.id, manualName: i);
    }
    return list.id;
  }

  Future<ShoppingListRow?> list(String id) =>
      (db.select(db.shoppingLists)..where((l) => l.id.equals(id)))
          .getSingleOrNull();

  Future<List<ShoppingListItemRow>> items(String id) =>
      db.shoppingListDao.itemsOf(id);

  Future<void> share(String id) =>
      db.shoppingListDao.setSpace(id, _space, DateTime.now().toUtc());

  Future<void> unshare(String id) =>
      db.shoppingListDao.setSpace(id, null, DateTime.now().toUtc());

  Future<String> newRecipe(String recipeName) async {
    final saved = await recipes.saveDetail(
      name: recipeName,
      ingredientLines: const ['2 ovos', '1 xícara de farinha'],
      stepLines: const ['Misture', 'Asse'],
    );
    return saved.valueOrNull!.id;
  }

  Future<String> planMeal(String recipeId, {String? spaceId = _space}) async {
    final row = await db.mealPlanDao.add(
      recipeId: recipeId,
      date: DateTime.utc(2026, 3, 10),
      mealType: 'lunch',
      at: DateTime.utc(2026, 3, 1),
      spaceId: spaceId,
    );
    return row.id;
  }

  Future<List<SharedMealRow>> others() => db.select(db.sharedMeals).get();

  Future<void> close() => db.close();
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 12));

void main() {
  late _SharedServer shared;
  late SyncServer ana;
  late SyncServer beto;
  late _Phone anaPhone;
  late _Phone betoPhone;

  setUp(() async {
    shared = _SharedServer();
    ana = SyncServer();
    beto = SyncServer();
    anaPhone = _Phone('Ana', shared, ana, 'ana');
    betoPhone = _Phone('Beto', shared, beto, 'beto');
    await anaPhone.db.ensureReady();
    await betoPhone.db.ensureReady();
  });

  tearDown(() async {
    await anaPhone.close();
    await betoPhone.close();
  });

  test('a lista compartilhada chega à outra pessoa, com os itens', () async {
    final id = await anaPhone.newList('Feira', ['Leite', 'Ovos']);
    await anaPhone.share(id);

    await anaPhone.shared();
    final report = await betoPhone.shared();

    expect(report.applied, 3);
    expect((await betoPhone.list(id))!.spaceId, _space);
    expect((await betoPhone.items(id)).map((i) => i.manualName),
        unorderedEquals(['Leite', 'Ovos']));
  });

  test('lista compartilhada não vai pra conta, e a conta não a leva embora',
      () async {
    final id = await anaPhone.newList('Feira', ['Leite']);
    await anaPhone.share(id);

    await anaPhone.personal();
    expect(
      ana.rows.keys.where((k) => k.startsWith('shopping')),
      isEmpty,
      reason: 'só a casa guarda a lista compartilhada',
    );
    expect(await anaPhone.sharedEngine.hasPending(), isTrue);
  });

  test('marcar um item numa ponta aparece na outra', () async {
    final id = await anaPhone.newList('Feira', ['Leite', 'Ovos']);
    await anaPhone.share(id);
    await anaPhone.shared();
    await betoPhone.shared();

    await tick();
    final leite =
        (await betoPhone.items(id)).firstWhere((i) => i.manualName == 'Leite');
    await (betoPhone.db.update(betoPhone.db.shoppingListItems)
          ..where((i) => i.id.equals(leite.id)))
        .write(const ShoppingListItemsCompanion(checked: Value(true)));
    await betoPhone.shared();
    await anaPhone.shared();

    final mine = await anaPhone.items(id);
    expect(mine.firstWhere((i) => i.manualName == 'Leite').checked, isTrue);
    expect(mine.firstWhere((i) => i.manualName == 'Ovos').checked, isFalse);
  });

  test('duas pessoas marcando itens diferentes não se atropelam', () async {
    final id = await anaPhone.newList('Feira', ['Leite', 'Ovos']);
    await anaPhone.share(id);
    await anaPhone.shared();
    await betoPhone.shared();

    Future<void> check(_Phone p, String name) async {
      final item = (await p.items(id)).firstWhere((i) => i.manualName == name);
      await (p.db.update(p.db.shoppingListItems)
            ..where((i) => i.id.equals(item.id)))
          .write(const ShoppingListItemsCompanion(checked: Value(true)));
    }

    await tick();
    await check(anaPhone, 'Leite');
    await check(betoPhone, 'Ovos');
    await anaPhone.shared();
    await betoPhone.shared();
    await anaPhone.shared();

    for (final phone in [anaPhone, betoPhone]) {
      expect((await phone.items(id)).every((i) => i.checked), isTrue,
          reason: phone.name);
    }
  });

  test('apagar a lista compartilhada apaga na outra ponta', () async {
    final id = await anaPhone.newList('Feira', ['Leite']);
    await anaPhone.share(id);
    await anaPhone.shared();
    await betoPhone.shared();
    expect(await betoPhone.list(id), isNotNull);

    await anaPhone.db.shoppingListDao.deleteList(id);
    await anaPhone.shared();
    final report = await betoPhone.shared();

    expect(report.removed, greaterThan(0));
    expect(await betoPhone.list(id), isNull);
    expect(await betoPhone.items(id), isEmpty);
  });

  test('deixar de compartilhar tira a lista da casa e leva pra conta',
      () async {
    final id = await anaPhone.newList('Feira', ['Leite']);
    await anaPhone.share(id);
    await anaPhone.shared();
    await betoPhone.shared();

    await anaPhone.unshare(id);
    await anaPhone.shared();
    await betoPhone.shared();
    await anaPhone.personal();

    expect(await betoPhone.list(id), isNull);
    expect((await anaPhone.list(id))!.spaceId, isNull);
    expect(ana.rows.keys, contains('shopping_list/$id'));
  });

  test('o outro aparelho da mesma pessoa recebe a lista já compartilhada',
      () async {
    final other = _Phone('Ana2', shared, ana, 'ana');
    addTearDown(other.close);
    await other.db.ensureReady();

    final id = await anaPhone.newList('Feira', ['Leite']);
    await anaPhone.personal();
    await other.personal();
    expect((await other.list(id))!.spaceId, isNull);

    await anaPhone.share(id);
    await anaPhone.personal();
    await anaPhone.shared();

    await other.personal();
    await other.shared();

    expect((await other.list(id))!.spaceId, _space);
    expect(await other.items(id), hasLength(1));
  });

  test('o aviso de exclusão da conta não apaga a cópia compartilhada',
      () async {
    final id = await anaPhone.newList('Feira', ['Leite']);
    await anaPhone.personal();
    await anaPhone.share(id);
    await anaPhone.personal();
    await anaPhone.shared();

    final other = _Phone('Ana2', shared, ana, 'ana');
    addTearDown(other.close);
    await other.db.ensureReady();
    await other.shared();
    await other.personal();

    expect((await other.list(id))!.spaceId, _space);
  });

  group('calendário da casa', () {
    test('a refeição chega a quem não tem a receita, com o resumo dela',
        () async {
      final recipe = await anaPhone.newRecipe('Bolo de cenoura');
      final meal = await anaPhone.planMeal(recipe);

      await anaPhone.shared();
      final report = await betoPhone.shared();

      expect(report.applied, 1);
      final row = (await betoPhone.others()).single;
      expect(row.id, meal);
      expect(row.authorName, 'Ana');
      expect(row.recipeJson, contains('Bolo de cenoura'));
      expect(row.recipeJson, contains('2 ovos'));
      expect(await betoPhone.db.select(betoPhone.db.recipes).get(), isEmpty,
          reason: 'a receita em si não vai pra biblioteca de quem recebe');
    });

    test('a refeição da casa não sobe pra conta', () async {
      final recipe = await anaPhone.newRecipe('Bolo');
      await anaPhone.planMeal(recipe);

      await anaPhone.personal();

      expect(ana.rows.keys.where((k) => k.startsWith('meal_plan')), isEmpty);
    });

    test('marcar como feita a refeição de outra pessoa chega ao dono',
        () async {
      final recipe = await anaPhone.newRecipe('Bolo');
      final meal = await anaPhone.planMeal(recipe);
      await anaPhone.shared();
      await betoPhone.shared();

      await tick();
      await MealPlanRepository(betoPhone.db.mealPlanDao,
          clock: () => DateTime.now()).setDone(meal, true);
      await betoPhone.shared();
      await anaPhone.shared();

      expect((await anaPhone.db.mealPlanDao.findById(meal))!.done, isTrue);
      expect(await anaPhone.db.select(anaPhone.db.cookLogs).get(), isEmpty,
          reason: 'quem só viu a refeição não grava histórico pra o dono');
    });

    test('apagar a própria refeição apaga na casa toda', () async {
      final recipe = await anaPhone.newRecipe('Bolo');
      final meal = await anaPhone.planMeal(recipe);
      await anaPhone.shared();
      await betoPhone.shared();
      expect(await betoPhone.others(), hasLength(1));

      await anaPhone.db.mealPlanDao.remove(meal);
      await anaPhone.shared();
      await betoPhone.shared();

      expect(await betoPhone.others(), isEmpty);
    });

    test('tirar a refeição de outra pessoa do plano tira do dono também',
        () async {
      final recipe = await anaPhone.newRecipe('Bolo');
      final meal = await anaPhone.planMeal(recipe);
      await anaPhone.shared();
      await betoPhone.shared();

      await MealPlanRepository(betoPhone.db.mealPlanDao).remove(meal);
      await betoPhone.shared();
      await anaPhone.shared();

      expect(await anaPhone.db.mealPlanDao.findById(meal), isNull);
    });

    test('o outro aparelho da própria pessoa recebe a refeição como dela',
        () async {
      final other = _Phone('Ana', shared, ana, 'ana');
      addTearDown(other.close);
      await other.db.ensureReady();

      final recipe = await anaPhone.newRecipe('Bolo');
      await anaPhone.personal();
      await other.personal();
      final meal = await anaPhone.planMeal(recipe);
      await anaPhone.shared();

      await other.shared();

      expect(await other.others(), isEmpty);
      final entry = (await other.db.mealPlanDao.findById(meal))!;
      expect(entry.spaceId, _space);
      expect(entry.recipeId, recipe);
    });

    test('quem planeja de novo no dia vê as duas refeições juntas', () async {
      final bolo = await anaPhone.newRecipe('Bolo');
      final sopa = await betoPhone.newRecipe('Sopa');
      await anaPhone.planMeal(bolo);
      await betoPhone.planMeal(sopa);
      await anaPhone.shared();
      await betoPhone.shared();
      await anaPhone.shared();

      final repo = MealPlanRepository(anaPhone.db.mealPlanDao);
      final week = await repo
          .watchRange(DateTime.utc(2026, 3, 9), DateTime.utc(2026, 3, 16))
          .first;

      expect(week.map((e) => e.recipeName), unorderedEquals(['Bolo', 'Sopa']));
      expect(week.firstWhere((e) => e.recipeName == 'Sopa').sharedBy, 'Beto');
      expect(week.firstWhere((e) => e.recipeName == 'Bolo').sharedBy, isNull);
    });

    test(
        'deixar de compartilhar o calendário limpa as dos outros e '
        'devolve as minhas pra conta', () async {
      final recipe = await anaPhone.newRecipe('Bolo');
      final meal = await anaPhone.planMeal(recipe);
      await anaPhone.shared();
      await betoPhone.shared();

      await betoPhone.db.mealPlanDao.unshare(_space);
      await anaPhone.db.mealPlanDao.unshare(_space);
      await anaPhone.shared();
      await anaPhone.personal();

      expect(await betoPhone.others(), isEmpty);
      expect((await anaPhone.db.mealPlanDao.findById(meal))!.spaceId, isNull);
      expect(ana.rows.keys, contains('meal_plan/$meal'));
    });

    test('compartilhar a partir de hoje não leva o passado', () async {
      final recipe = await anaPhone.newRecipe('Bolo');
      final past = await anaPhone.planMeal(recipe, spaceId: null);
      await anaPhone.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 4, 1),
        mealType: 'dinner',
        at: DateTime.utc(2026, 3, 1),
      );

      final count = await anaPhone.db.mealPlanDao
          .shareFrom(_space, DateTime.utc(2026, 3, 20));

      expect(count, 1);
      expect((await anaPhone.db.mealPlanDao.findById(past))!.spaceId, isNull);
    });
  });
}
