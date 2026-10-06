import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/core/sync_kinds.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/domain/engine/sync_codec.dart' show kSyncSchemaVersion;

import '../../helpers/sync_harness.dart';

/// Pausa curta: os carimbos dos gatilhos têm precisão de milissegundo, e dois
/// aparelhos do teste editam "ao mesmo tempo".
Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 12));

void main() {
  late SyncServer server;
  late SyncDevice a;
  late SyncDevice b;
  late Directory root;

  setUp(() async {
    server = SyncServer();
    root = await Directory.systemTemp.createTemp('sync_h4_test');
    a = SyncDevice('A', server, imagesRoot: root);
    b = SyncDevice('B', server, imagesRoot: root);
    await a.db.ensureReady();
    await b.db.ensureReady();
  });

  tearDown(() async {
    await a.close();
    await b.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Uma receita que já existe nos dois aparelhos (o resto depende dela).
  Future<String> sharedRecipe() async {
    final id = await a.newRecipe('Bolo');
    await a.syncOk();
    await b.syncOk();
    return id;
  }

  group('histórico "cozinhei"', () {
    test('um registro feito numa ponta aparece na outra', () async {
      final recipe = await sharedRecipe();
      final logId = await a.db.cookLogDao.add(
        recipeId: recipe,
        cookedAt: DateTime.utc(2026, 2, 3, 19),
        note: 'ficou ótimo',
      );

      await a.syncOk();
      final report = await b.syncOk();

      expect(report.applied, 1);
      final log = (await b.db.cookLogDao.findById(logId))!;
      expect(log.recipeId, recipe);
      expect(log.cookedAt, DateTime.utc(2026, 2, 3, 19));
      expect(log.note, 'ficou ótimo');
      expect(await b.db.cookLogDao.dirtyForSync(), isEmpty);
    });

    test('editar a nota chega na outra', () async {
      final recipe = await sharedRecipe();
      final logId = await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      await a.syncOk();
      await b.syncOk();

      await tick();
      await (a.db.update(a.db.cookLogs)..where((l) => l.id.equals(logId)))
          .write(const CookLogsCompanion(note: Value('com mais sal')));
      await a.syncOk();
      await b.syncOk();

      expect((await b.db.cookLogDao.findById(logId))!.note, 'com mais sal');
    });

    test('apagar um registro propaga, sem eco', () async {
      final recipe = await sharedRecipe();
      final logId = await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      await a.syncOk();
      await b.syncOk();

      await a.db.cookLogDao.remove(logId);
      await a.syncOk();
      final report = await b.syncOk();

      expect(report.removed, 1);
      expect(await b.db.cookLogDao.findById(logId), isNull);
      expect(await b.db.select(b.db.syncTombstones).get(), isEmpty);
    });

    test(
        'marcar a refeição como feita leva o registro junto, e desmarcar o tira',
        () async {
      final recipe = await sharedRecipe();
      a.at(5);
      final entry = await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 5),
        mealType: 'dinner',
        at: a.clock,
      );
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.db.mealPlanDao.setDone(entry.id, true, a.clock);
      await a.syncOk();
      await b.syncOk();

      expect((await b.db.mealPlanDao.findById(entry.id))!.done, isTrue);
      expect(await b.db.select(b.db.cookLogs).get(), hasLength(1));

      a.at(20);
      await a.db.mealPlanDao.setDone(entry.id, false, a.clock);
      await a.syncOk();
      await b.syncOk();

      expect((await b.db.mealPlanDao.findById(entry.id))!.done, isFalse);
      expect(await b.db.select(b.db.cookLogs).get(), isEmpty);
    });

    test('registro de uma receita que este aparelho não tem é ignorado',
        () async {
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindCookLog,
          id: 'orfao',
          editedAt: DateTime.utc(2026, 2, 3),
          data: {
            'v': 1,
            'id': 'orfao',
            'recipeId': 'receita-que-nao-existe',
            'cookedAt': '2026-02-03T00:00:00.000Z',
            'updatedAt': '2026-02-03T00:00:00.000Z',
          },
        ),
      ]);

      final report = await b.syncOk();

      expect(report.applied, 0);
      expect(await b.db.select(b.db.cookLogs).get(), isEmpty);
    });

    test('receita apagada leva o histórico junto nas duas pontas', () async {
      final recipe = await sharedRecipe();
      await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      await a.syncOk();
      await b.syncOk();

      await a.repo.softDelete(recipe);
      await a.repo.deleteForever(recipe);
      await a.syncOk();
      await b.syncOk();

      expect(await b.db.select(b.db.cookLogs).get(), isEmpty);
    });
  });

  group('calendário', () {
    test('refeição planejada chega com todos os campos', () async {
      final recipe = await sharedRecipe();
      a.at(5);
      final entry = await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: a.clock,
        servingsOverride: 6,
        note: 'com visita',
      );
      await a.syncOk();

      await b.syncOk();

      final e = (await b.db.mealPlanDao.findById(entry.id))!;
      expect(e.recipeId, recipe);
      expect(e.date, DateTime.utc(2026, 2, 7));
      expect(e.mealType, 'lunch');
      expect(e.servingsOverride, 6);
      expect(e.note, 'com visita');
      expect(e.done, isFalse);
      expect(await b.db.mealPlanDao.dirtyForSync(), isEmpty);
    });

    test('mover pra outro dia e refeição chega na outra', () async {
      final recipe = await sharedRecipe();
      a.at(5);
      final entry = await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: a.clock,
      );
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.db.mealPlanDao.move(
        entry.id,
        date: DateTime.utc(2026, 2, 9),
        mealType: 'dinner',
        at: a.clock,
      );
      await a.syncOk();
      await b.syncOk();

      final e = (await b.db.mealPlanDao.findById(entry.id))!;
      expect(e.date, DateTime.utc(2026, 2, 9));
      expect(e.mealType, 'dinner');
    });

    test('tirar do plano propaga', () async {
      final recipe = await sharedRecipe();
      a.at(5);
      final entry = await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: a.clock,
      );
      await a.syncOk();
      await b.syncOk();

      await a.db.mealPlanDao.remove(entry.id);
      await a.syncOk();
      await b.syncOk();

      expect(await b.db.mealPlanDao.findById(entry.id), isNull);
    });

    test('as duas moveram: vale a mais recente', () async {
      final recipe = await sharedRecipe();
      a.at(5);
      final entry = await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: a.clock,
      );
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.db.mealPlanDao.move(entry.id,
          date: DateTime.utc(2026, 2, 8), mealType: 'lunch', at: a.clock);
      b.at(20);
      await b.db.mealPlanDao.move(entry.id,
          date: DateTime.utc(2026, 2, 9), mealType: 'dinner', at: b.clock);
      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      for (final d in [a, b]) {
        final e = (await d.db.mealPlanDao.findById(entry.id))!;
        expect(e.date, DateTime.utc(2026, 2, 9), reason: d.name);
        expect(e.mealType, 'dinner', reason: d.name);
      }
    });

    test('refeição de uma receita que este aparelho não tem é ignorada',
        () async {
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindMealPlan,
          id: 'orfa',
          editedAt: DateTime.utc(2026, 2, 3),
          data: {
            'v': 1,
            'id': 'orfa',
            'recipeId': 'receita-que-nao-existe',
            'date': '2026-02-07T00:00:00.000Z',
            'mealType': 'lunch',
            'updatedAt': '2026-02-03T00:00:00.000Z',
          },
        ),
      ]);

      final report = await b.syncOk();

      expect(report.applied, 0);
      expect(await b.db.select(b.db.mealPlanEntries).get(), isEmpty);
    });
  });

  group('listas de compras', () {
    Future<String> listWith(
        SyncDevice d, String name, List<String> items) async {
      final list =
          await d.db.shoppingListDao.createEmpty(name: name, at: d.clock);
      for (final item in items) {
        await d.db.shoppingListDao.addItem(listId: list.id, manualName: item);
      }
      return list.id;
    }

    Future<List<ShoppingListItemRow>> itemsOf(SyncDevice d, String listId) =>
        d.db.shoppingListDao.itemsOf(listId);

    test('a lista e os itens chegam, na ordem', () async {
      final id = await listWith(a, 'Feira', ['Leite', 'Pão', 'Ovos']);
      await a.syncOk();

      await b.syncOk();

      final list = await b.db.shoppingListDao.dirtyLists();
      expect(list, isEmpty);
      final items = await itemsOf(b, id);
      expect(items.map((i) => i.manualName), ['Leite', 'Pão', 'Ovos']);
      expect(items.every((i) => !i.checked), isTrue);
    });

    test('item do catálogo viaja por nome e as receitas de origem vêm junto',
        () async {
      final recipe = await sharedRecipe();
      final list =
          await a.db.shoppingListDao.createEmpty(name: 'Feira', at: a.clock);
      final ing = await a.db.ingredientDao.getOrCreate('Farinha de trigo');
      await a.db.shoppingListDao.addItem(
        listId: list.id,
        ingredientId: ing.id,
        quantity: 500,
        unitId: 'g',
      );
      final created = (await itemsOf(a, list.id)).single;
      await a.db.into(a.db.shoppingItemSources).insert(
            ShoppingItemSourcesCompanion.insert(
              itemId: created.id,
              recipeId: recipe,
              quantity: const Value(500),
              unitId: const Value('g'),
            ),
          );
      await a.syncOk();

      await b.syncOk();

      final items = await itemsOf(b, list.id);
      expect(items, hasLength(1));
      final bIng =
          (await b.db.ingredientDao.findByIds([items.single.ingredientId!]))
              .single;
      expect(bIng.displayName.toLowerCase(), contains('farinha'));
      expect(items.single.quantity, 500);
      expect(items.single.unitId, 'g');
      final sources = await b.db.select(b.db.shoppingItemSources).get();
      expect(sources.single.recipeId, recipe);
      expect(sources.single.quantity, 500);
    });

    test('marcar um item como comprado chega na outra ponta', () async {
      final id = await listWith(a, 'Feira', ['Leite', 'Pão']);
      await a.syncOk();
      await b.syncOk();
      final leite = (await itemsOf(b, id)).first;

      await tick();
      await b.db.shoppingListDao.setChecked(leite.id, true);
      await b.syncOk();
      await a.syncOk();

      final itemsA = await itemsOf(a, id);
      expect(itemsA.firstWhere((i) => i.id == leite.id).checked, isTrue);
      expect(itemsA.firstWhere((i) => i.id != leite.id).checked, isFalse);
    });

    test('cada um marca um item DIFERENTE ao mesmo tempo: os dois valem',
        () async {
      final id = await listWith(a, 'Feira', ['Leite', 'Pão']);
      await a.syncOk();
      await b.syncOk();
      final itemsA = await itemsOf(a, id);
      final itemsB = await itemsOf(b, id);

      await tick();
      await a.db.shoppingListDao.setChecked(itemsA[0].id, true);
      await b.db.shoppingListDao.setChecked(itemsB[1].id, true);
      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      for (final d in [a, b]) {
        final items = await itemsOf(d, id);
        expect(items.map((i) => i.checked), [true, true], reason: d.name);
      }
    });

    test('o mesmo item mexido nas duas pontas: vale a mais recente', () async {
      final id = await listWith(a, 'Feira', ['Leite']);
      await a.syncOk();
      await b.syncOk();
      final item = (await itemsOf(a, id)).single;

      await tick();
      await a.db.shoppingListDao.setChecked(item.id, true);
      await tick();
      await tick();
      await b.db.shoppingListDao.setChecked(item.id, false);
      await (b.db.update(b.db.shoppingListItems)
            ..where((i) => i.id.equals(item.id)))
          .write(const ShoppingListItemsCompanion(note: Value('integral')));
      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      for (final d in [a, b]) {
        final i = (await itemsOf(d, id)).single;
        expect(i.note, 'integral', reason: d.name);
        expect(i.checked, isFalse, reason: d.name);
      }
    });

    test('item novo adicionado numa ponta chega; item tirado some na outra',
        () async {
      final id = await listWith(a, 'Feira', ['Leite', 'Pão']);
      await a.syncOk();
      await b.syncOk();

      await tick();
      await b.db.shoppingListDao.addItem(listId: id, manualName: 'Café');
      final pao =
          (await itemsOf(b, id)).firstWhere((i) => i.manualName == 'Pão');
      await b.db.shoppingListDao.deleteItem(pao.id);
      await b.syncOk();
      await a.syncOk();

      final names = (await itemsOf(a, id)).map((i) => i.manualName).toSet();
      expect(names, {'Leite', 'Café'});
    });

    test('renomear a lista chega', () async {
      final id = await listWith(a, 'Feira', ['Leite']);
      await a.syncOk();
      await b.syncOk();

      await a.db.shoppingListDao.rename(id, 'Feira de sábado',
          DateTime.now().toUtc().add(const Duration(minutes: 1)));
      await a.syncOk();
      await b.syncOk();

      final row = await (b.db.select(b.db.shoppingLists)
            ..where((l) => l.id.equals(id)))
          .getSingle();
      expect(row.name, 'Feira de sábado');
    });

    test('apagar a lista apaga a lista e os itens na outra, sem eco', () async {
      final id = await listWith(a, 'Feira', ['Leite', 'Pão']);
      await a.syncOk();
      await b.syncOk();

      await a.db.shoppingListDao.deleteList(id);
      await a.syncOk();
      await b.syncOk();

      expect(await b.db.select(b.db.shoppingLists).get(), isEmpty);
      expect(await b.db.select(b.db.shoppingListItems).get(), isEmpty);
      expect(await b.db.select(b.db.syncTombstones).get(), isEmpty);
    });

    test('item de uma lista que este aparelho não tem é ignorado', () async {
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindShoppingItem,
          id: 'solto',
          editedAt: DateTime.utc(2026, 2, 3),
          data: {
            'v': 1,
            'id': 'solto',
            'listId': 'lista-que-nao-existe',
            'manualName': 'Leite',
            'updatedAt': '2026-02-03T00:00:00.000Z',
          },
        ),
      ]);

      final report = await b.syncOk();

      expect(report.applied, 0);
      expect(await b.db.select(b.db.shoppingListItems).get(), isEmpty);
    });

    test(
        'unidade desconhecida vira "sem unidade" e a receita de origem '
        'inexistente é descartada, sem erro', () async {
      final list =
          await a.db.shoppingListDao.createEmpty(name: 'Feira', at: a.clock);
      await a.syncOk();
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindShoppingItem,
          id: 'item1',
          editedAt: DateTime.utc(2030, 1, 1),
          data: {
            'v': 1,
            'id': 'item1',
            'listId': list.id,
            'manualName': 'Sal',
            'quantity': 2,
            'unit': 'bobina_inexistente',
            'sources': [
              {'recipeId': 'receita-que-nao-existe', 'quantity': 2},
            ],
            'updatedAt': '2030-01-01T00:00:00.000Z',
          },
        ),
      ]);

      await b.syncOk();

      final item = (await itemsOf(b, list.id)).single;
      expect(item.unitId, isNull);
      expect(item.quantity, 2);
      expect(await b.db.select(b.db.shoppingItemSources).get(), isEmpty);
    });
  });

  group('despensa', () {
    test('marcar "sempre tenho" numa ponta vale na outra', () async {
      final salA = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(salA.id, true);
      await a.syncOk();

      await b.syncOk();

      final salB = (await b.db.select(b.db.ingredients).get())
          .singleWhere((i) => i.normalizedKey == salA.normalizedKey);
      expect(salB.inPantry, isTrue);
      expect(await b.db.ingredientDao.dirtyPantry(), isEmpty);
    });

    test('desmarcar também chega', () async {
      final sal = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(sal.id, true);
      await a.syncOk();
      await b.syncOk();

      await tick();
      await a.db.ingredientDao.setInPantry(sal.id, false);
      await a.syncOk();
      await b.syncOk();

      final salB = (await b.db.select(b.db.ingredients).get())
          .singleWhere((i) => i.normalizedKey == sal.normalizedKey);
      expect(salB.inPantry, isFalse);
    });

    test(
        'ingrediente que o outro aparelho já tem (sem despensa) só recebe o marcador',
        () async {
      final salB = await b.db.ingredientDao.getOrCreate('Sal');
      final salA = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(salA.id, true);
      await a.syncOk();

      await b.syncOk();

      final all = await b.db.select(b.db.ingredients).get();
      expect(all.where((i) => i.normalizedKey == salB.normalizedKey),
          hasLength(1));
      expect(all.singleWhere((i) => i.id == salB.id).inPantry, isTrue);
    });

    test('as duas mexem na mesma: vale a mais recente', () async {
      final salA = await a.db.ingredientDao.getOrCreate('Sal');
      final salB = await b.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(salA.id, true);
      await a.syncOk();
      await b.syncOk();

      await tick();
      await a.db.ingredientDao.setInPantry(salA.id, false);
      await tick();
      await tick();
      await b.db.ingredientDao.setInPantry(salB.id, false);
      await b.db.ingredientDao.setInPantry(salB.id, true);
      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      for (final d in [a, b]) {
        final sal = (await d.db.select(d.db.ingredients).get())
            .singleWhere((i) => i.normalizedKey == salA.normalizedKey);
        expect(sal.inPantry, isTrue, reason: d.name);
      }
    });

    test('despensa que já existia antes do sync sobe na 1ª rodada', () async {
      final sal = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.customStatement(
          "UPDATE ingredients SET in_pantry = 1, pantry_updated_at = NULL "
          "WHERE id = '${sal.id}'");
      await a.db.ensureReady();

      await a.syncOk();
      await b.syncOk();

      final salB = (await b.db.select(b.db.ingredients).get())
          .singleWhere((i) => i.normalizedKey == sal.normalizedKey);
      expect(salB.inPantry, isTrue);
    });
  });

  group('junto, e robustez', () {
    test('uma rodada leva todos os tipos, e a segunda não reenvia nada',
        () async {
      final recipe = await sharedRecipe();
      final list =
          await a.db.shoppingListDao.createEmpty(name: 'Feira', at: a.clock);
      await a.db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      final sal = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(sal.id, true);
      a.at(5);
      await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: a.clock,
      );
      await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));

      final first = await a.syncOk();
      final again = await a.syncOk();

      expect(first.pushed, 5);
      expect(again.pushed, 0);
      expect(await a.engine.hasPending(), isFalse);
    });

    test('hasPending enxerga cada tipo', () async {
      expect(await a.engine.hasPending(), isFalse);
      final recipe = await sharedRecipe();
      expect(await a.engine.hasPending(), isFalse);

      await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      expect(await a.engine.hasPending(), isTrue);
      await a.syncOk();
      expect(await a.engine.hasPending(), isFalse);

      final list =
          await a.db.shoppingListDao.createEmpty(name: 'F', at: a.clock);
      expect(await a.engine.hasPending(), isTrue);
      await a.syncOk();

      await a.db.shoppingListDao.addItem(listId: list.id, manualName: 'L');
      expect(await a.engine.hasPending(), isTrue);
      await a.syncOk();

      final sal = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(sal.id, true);
      expect(await a.engine.hasPending(), isTrue);
      await a.syncOk();
      expect(await a.engine.hasPending(), isFalse);
    });

    test(
        'depois de limpar o aparelho tudo volta (receitas, listas, plano, '
        'histórico e despensa)', () async {
      final recipe = await sharedRecipe();
      final list =
          await a.db.shoppingListDao.createEmpty(name: 'Feira', at: a.clock);
      await a.db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      final sal = await a.db.ingredientDao.getOrCreate('Sal');
      await a.db.ingredientDao.setInPantry(sal.id, true);
      a.at(5);
      await a.db.mealPlanDao.add(
        recipeId: recipe,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: a.clock,
      );
      await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      await a.syncOk();

      await b.db.wipeUserData();
      b.prefs = {};
      await b.syncOk();

      expect(await b.db.select(b.db.recipes).get(), hasLength(1));
      expect(await b.db.select(b.db.shoppingLists).get(), hasLength(1));
      expect(await b.db.select(b.db.shoppingListItems).get(), hasLength(1));
      expect(await b.db.select(b.db.mealPlanEntries).get(), hasLength(1));
      expect(await b.db.select(b.db.cookLogs).get(), hasLength(1));
      expect(
        (await b.db.select(b.db.ingredients).get()).where((i) => i.inPantry),
        hasLength(1),
      );
    });

    test('depois de excluir a conta, tudo sobe de novo numa conta nova',
        () async {
      final recipe = await sharedRecipe();
      await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      await a.syncOk();
      final fresh = SyncServer();
      a.remote.server = fresh;

      await a.db.resetSyncState();
      final report = await a.syncOk();

      expect(report.pushed, 2);
      expect(fresh.rows.keys.map((k) => k.split('/').first).toSet(),
          {kSyncKindRecipe, kSyncKindCookLog});
    });

    test(
        'corpo de uma versão mais nova do formato é ignorado em todos os tipos',
        () async {
      final recipe = await sharedRecipe();
      final future = {'v': kSyncSchemaVersion + 1};
      await a.remote.push([
        SyncDoc(
            kind: kSyncKindCookLog,
            id: 'f1',
            editedAt: DateTime.utc(2026, 2, 3),
            data: {...future, 'id': 'f1', 'recipeId': recipe}),
        SyncDoc(
            kind: kSyncKindMealPlan,
            id: 'f2',
            editedAt: DateTime.utc(2026, 2, 3),
            data: {...future, 'id': 'f2', 'recipeId': recipe}),
        SyncDoc(
            kind: kSyncKindShoppingList,
            id: 'f3',
            editedAt: DateTime.utc(2026, 2, 3),
            data: {...future, 'id': 'f3', 'name': 'x'}),
        SyncDoc(
            kind: kSyncKindPantry,
            id: 'f4',
            editedAt: DateTime.utc(2026, 2, 3),
            data: {...future, 'key': 'f4', 'name': 'x'}),
      ]);

      final report = await b.syncOk();

      expect(report.applied, 0,
          reason: 'a receita já estava em dia; o resto é ignorado');
      expect(await b.db.select(b.db.cookLogs).get(), isEmpty);
      expect(await b.db.select(b.db.shoppingLists).get(), isEmpty);
    });

    test('falha de rede no envio deixa tudo pendente e a próxima rodada envia',
        () async {
      final recipe = await sharedRecipe();
      await a.db.cookLogDao
          .add(recipeId: recipe, cookedAt: DateTime.utc(2026, 2, 3));
      a.remote.failPush = true;

      expect(await a.sync(), isA<Err<dynamic>>());
      expect(await a.engine.hasPending(), isTrue);

      a.remote.failPush = false;
      await a.syncOk();
      expect(await a.engine.hasPending(), isFalse);
    });
  });
}
