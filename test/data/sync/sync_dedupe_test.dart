import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/core/sync_kinds.dart';
import 'package:receyta/data/sync/sync_dedupe.dart';
import 'package:receyta/data/sync/sync_remote.dart';

import '../../helpers/sync_harness.dart';

void main() {
  late SyncServer server;
  late SyncDevice a;
  late SyncDevice b;
  late Directory root;

  setUp(() async {
    server = SyncServer();
    root = await Directory.systemTemp.createTemp('sync_dedupe_test');
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

  Future<Set<String>> recipeIds(SyncDevice d) async =>
      {for (final r in await d.allRecipes()) r.id};

  Future<Set<String>> folderIds(SyncDevice d) async =>
      {for (final f in await d.db.select(d.db.folders).get()) f.id};

  group('receitas', () {
    test('a mesma receita criada nos dois aparelhos vira uma só', () async {
      final idA = await a.newRecipe('Bolo de fubá',
          ingredients: ['2 ovos', '1 xícara de fubá']);
      final idB = await b.newRecipe('Bolo de fubá',
          ingredients: ['2 ovos', '1 xícara de fubá']);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.merged, 1);
      expect(await recipeIds(b), {idA});
      expect(await b.row(idB), isNull);
    });

    test('os dois aparelhos terminam com a MESMA receita', () async {
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await a.syncOk();
      await b.syncOk();
      await a.syncOk();
      await b.syncOk();

      expect(await recipeIds(a), {idA});
      expect(await recipeIds(b), {idA});
    });

    test(
        'o que apontava pra cópia descartada passa a apontar pra da nuvem e '
        'chega na outra ponta', () async {
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      final idB = await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      b.at(5);
      final entry = await b.db.mealPlanDao.add(
        recipeId: idB,
        date: DateTime.utc(2026, 2, 7),
        mealType: 'lunch',
        at: b.clock,
      );
      final logId = await b.db.cookLogDao
          .add(recipeId: idB, cookedAt: DateTime.utc(2026, 2, 3));
      await a.syncOk();

      await b.syncOk();
      await a.syncOk();

      expect((await b.db.mealPlanDao.findById(entry.id))!.recipeId, idA);
      expect((await b.db.cookLogDao.findById(logId))!.recipeId, idA);
      expect((await a.db.mealPlanDao.findById(entry.id))!.recipeId, idA);
      expect((await a.db.cookLogDao.findById(logId))!.recipeId, idA);
    });

    test('origem de item de compras também é re-apontada', () async {
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      final idB = await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      final list =
          await b.db.shoppingListDao.createEmpty(name: 'Feira', at: b.clock);
      await b.db.shoppingListDao.addItem(listId: list.id, manualName: 'Ovos');
      final item = (await b.db.select(b.db.shoppingListItems).get()).single;
      await b.db.into(b.db.shoppingItemSources).insert(
            ShoppingItemSourceRow(itemId: item.id, recipeId: idB, quantity: 2),
          );
      await a.syncOk();

      await b.syncOk();

      final sources = await b.db.select(b.db.shoppingItemSources).get();
      expect(sources.single.recipeId, idA);
      expect(sources.single.itemId, item.id);
    });

    test('conteúdo diferente (um ingrediente a mais) NÃO é unido', () async {
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      final idB = await b
          .newRecipe('Bolo', ingredients: ['2 ovos', '1 xícara de açúcar']);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.merged, 0);
      expect(await recipeIds(b), {idA, idB});
    });

    test('nome com acento, caixa ou espaço diferente conta como o mesmo',
        () async {
      final idA = await a.newRecipe('Bolo de Fubá', ingredients: ['2 Ovos']);
      await b.newRecipe('  bolo  de fuba ', ingredients: ['2 ovos']);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.merged, 1);
      expect(await recipeIds(b), {idA});
    });

    test('só une cópia que NUNCA foi sincronizada: a já sincronizada fica',
        () async {
      final idB = await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.syncOk();
      // Uma cópia idêntica que chega depois, vinda de quem nunca viu a de B.
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindRecipe,
          id: 'copia-da-nuvem',
          editedAt: DateTime.utc(2030, 1, 1),
          data: {
            'v': 1,
            'id': 'copia-da-nuvem',
            'name': 'Bolo',
            'createdAt': '2030-01-01T00:00:00.000Z',
            'updatedAt': '2030-01-01T00:00:00.000Z',
            'ingredients': [
              {'position': 0, 'rawText': '2 ovos', 'name': 'Ovos'},
            ],
            'steps': [
              {'position': 0, 'text': 'Misture'},
            ],
          },
        ),
      ]);

      final report = await b.syncOk();

      expect(report.merged, 0);
      expect(await recipeIds(b), {idB, 'copia-da-nuvem'});
    });

    test('um pra um: duas cópias locais iguais, só uma é unida à da nuvem',
        () async {
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.merged, 1);
      expect(await recipeIds(b), hasLength(2));
      expect(await recipeIds(b), contains(idA));
    });

    test('cópia na lixeira não é unida', () async {
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      final idB = await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.repo.softDelete(idB);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.merged, 0);
      expect(await recipeIds(b), {idA, idB});
    });

    test('a foto da cópia descartada sai do aparelho se ninguém mais a usa',
        () async {
      final src = File(p.join(root.path, 'src.jpg'))
        ..writeAsBytesSync([1, 2, 3]);
      final photo = await b.images!.store(src);
      final idA = await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      final idB = await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.repo.setImage(idB, photo);
      expect(await (await b.images!.fileFor(photo)).exists(), isTrue);
      await a.syncOk();

      await b.syncOk();

      expect(await recipeIds(b), {idA});
      expect(await (await b.images!.fileFor(photo)).exists(), isFalse);
    });

    test('a foto fica se outra receita ainda a usa', () async {
      final src = File(p.join(root.path, 'src.jpg'))
        ..writeAsBytesSync([1, 2, 3]);
      final photo = await b.images!.store(src);
      await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      final idB = await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      final other = await b.newRecipe('Outra', ingredients: ['1 maçã']);
      await b.repo.setImage(idB, photo);
      await b.repo.setImage(other, photo);
      await a.syncOk();

      await b.syncOk();

      expect(await (await b.images!.fileFor(photo)).exists(), isTrue);
    });

    test('a união é estável: repetir a sincronização não muda mais nada',
        () async {
      await a.newRecipe('Bolo', ingredients: ['2 ovos']);
      await b.newRecipe('Bolo', ingredients: ['2 ovos']);
      await a.syncOk();
      await b.syncOk();
      await a.syncOk();
      await b.syncOk();

      final again = await b.syncOk();

      expect(again.merged, 0);
      expect(again.pushed, 0);
      expect(await b.db.recipeDao.dirtyForSync(), isEmpty);
    });
  });

  group('pastas', () {
    test(
        'a mesma pasta criada nos dois aparelhos vira uma só e leva as '
        'receitas', () async {
      final fa = await a.db.folderDao.create(name: 'Massas');
      final fb = await b.db.folderDao.create(name: 'Massas');
      final idB = await b.newRecipe('Lasanha', ingredients: ['massa']);
      await b.db.recipeDao.setFolder(idB, fb.id, b.clock);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.merged, greaterThanOrEqualTo(1));
      expect(await folderIds(b), {fa.id});
      expect((await b.row(idB))!.folderId, fa.id);
    });

    test('a receita que estava na cópia chega na pasta certa na outra ponta',
        () async {
      final fa = await a.db.folderDao.create(name: 'Massas');
      final fb = await b.db.folderDao.create(name: 'Massas');
      final idB = await b.newRecipe('Lasanha', ingredients: ['massa']);
      await b.db.recipeDao.setFolder(idB, fb.id, b.clock);
      await a.syncOk();
      await b.syncOk();

      await a.syncOk();

      expect((await a.row(idB))!.folderId, fa.id);
    });

    test('subpastas: pai e filho se unem, o pai primeiro', () async {
      final parentA = await a.db.folderDao.create(name: 'Massas');
      final childA =
          await a.db.folderDao.create(name: 'Molhos', parentId: parentA.id);
      final parentB = await b.db.folderDao.create(name: 'Massas');
      await b.db.folderDao.create(name: 'Molhos', parentId: parentB.id);
      await a.syncOk();

      await b.syncOk();

      expect(await folderIds(b), {parentA.id, childA.id});
      final child = (await b.db.folderDao.findAny(childA.id))!;
      expect(child.parentId, parentA.id);
    });

    test('mesmo nome em outro lugar (outro pai) NÃO é unido', () async {
      final fa = await a.db.folderDao.create(name: 'Massas');
      final outer = await b.db.folderDao.create(name: 'Receitas');
      final fb =
          await b.db.folderDao.create(name: 'Massas', parentId: outer.id);
      await a.syncOk();

      await b.syncOk();

      expect(await folderIds(b), {fa.id, outer.id, fb.id});
    });

    test('pasta já sincronizada nunca é unida', () async {
      final fb = await b.db.folderDao.create(name: 'Massas');
      await b.syncOk();
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindFolder,
          id: 'pasta-da-nuvem',
          editedAt: DateTime.utc(2030, 1, 1),
          data: {
            'v': 1,
            'id': 'pasta-da-nuvem',
            'name': 'Massas',
            'createdAt': '2030-01-01T00:00:00.000Z',
            'updatedAt': '2030-01-01T00:00:00.000Z',
          },
        ),
      ]);

      final report = await b.syncOk();

      expect(report.merged, 0);
      expect(await folderIds(b), {fb.id, 'pasta-da-nuvem'});
    });

    test('nome com caixa e acento diferentes conta como o mesmo', () async {
      final fa = await a.db.folderDao.create(name: 'Sobremesas Frias');
      await b.db.folderDao.create(name: 'sobremesas  frias');
      await a.syncOk();

      await b.syncOk();

      expect(await folderIds(b), {fa.id});
    });
  });

  group('chave de nome', () {
    test('ignora acento, caixa e espaços repetidos', () {
      expect(SyncDeduper.nameKey('  Bolo  de   Fubá '), 'bolo de fuba');
      expect(SyncDeduper.nameKey('AÇAÍ'), 'acai');
    });

    test('nomes diferentes continuam diferentes', () {
      expect(SyncDeduper.nameKey('Bolo de fubá'),
          isNot(SyncDeduper.nameKey('Bolo de milho')));
    });
  });
}
