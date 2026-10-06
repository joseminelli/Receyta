import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/sync_codec.dart' show kSyncSchemaVersion;
import 'package:receyta/domain/engine/sync_codec_h4.dart';

void main() {
  final created = DateTime.utc(2026, 1, 1, 10);
  final updated = DateTime.utc(2026, 2, 3, 11, 30, 15);

  Map<String, dynamic> viaJson(Map<String, dynamic> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  group('histórico', () {
    final log = SyncCookLog(
      id: 'c1',
      recipeId: 'r1',
      cookedAt: DateTime.utc(2026, 2, 2, 19),
      note: 'ficou ótimo',
      mealPlanEntryId: 'm1',
      createdAt: created,
      updatedAt: updated,
    );

    test('ida e volta pelo JSON', () {
      final r = parseCookLogSync(viaJson(cookLogToSyncJson(log)))!;

      expect(r.id, 'c1');
      expect(r.recipeId, 'r1');
      expect(r.cookedAt, DateTime.utc(2026, 2, 2, 19));
      expect(r.note, 'ficou ótimo');
      expect(r.mealPlanEntryId, 'm1');
      expect(r.createdAt, created);
      expect(r.updatedAt, updated);
    });

    test('sem nota nem refeição de origem volta nulo', () {
      final json = viaJson(cookLogToSyncJson(SyncCookLog(
        id: 'c2',
        recipeId: 'r1',
        cookedAt: created,
        createdAt: created,
        updatedAt: updated,
      )));

      final r = parseCookLogSync(json)!;

      expect(r.note, isNull);
      expect(r.mealPlanEntryId, isNull);
    });

    test('createdAt ausente cai na data de cozinhar', () {
      final json = viaJson(cookLogToSyncJson(log))..remove('createdAt');

      expect(parseCookLogSync(json)!.createdAt, log.cookedAt);
    });

    test('lixo, versão nova e campos obrigatórios faltando: null', () {
      final ok = viaJson(cookLogToSyncJson(log));

      expect(parseCookLogSync(null), isNull);
      expect(parseCookLogSync('x'), isNull);
      expect(parseCookLogSync({...ok, 'v': kSyncSchemaVersion + 1}), isNull);
      expect(parseCookLogSync({...ok, 'id': ''}), isNull);
      expect(parseCookLogSync({...ok, 'recipeId': null}), isNull);
      expect(parseCookLogSync({...ok, 'cookedAt': 'não é data'}), isNull);
      expect(parseCookLogSync({...ok}..remove('updatedAt')), isNull);
    });
  });

  group('refeição planejada', () {
    final entry = SyncMealPlan(
      id: 'm1',
      recipeId: 'r1',
      date: DateTime.utc(2026, 2, 7),
      mealType: 'dinner',
      servingsOverride: 6,
      note: 'com visita',
      done: true,
      createdAt: created,
      updatedAt: updated,
    );

    test('ida e volta pelo JSON', () {
      final r = parseMealPlanSync(viaJson(mealPlanToSyncJson(entry)))!;

      expect(r.recipeId, 'r1');
      expect(r.date, DateTime.utc(2026, 2, 7));
      expect(r.mealType, 'dinner');
      expect(r.servingsOverride, 6);
      expect(r.note, 'com visita');
      expect(r.done, isTrue);
      expect(r.updatedAt, updated);
    });

    test('o dia viaja em UTC mesmo se vier de um fuso local', () {
      final local = SyncMealPlan(
        id: 'm2',
        recipeId: 'r1',
        date: DateTime(2026, 2, 7),
        mealType: 'lunch',
        createdAt: created,
        updatedAt: updated,
      );

      expect(mealPlanToSyncJson(local)['date'], endsWith('Z'));
    });

    test('sem refeição, dia ou receita: null', () {
      final ok = viaJson(mealPlanToSyncJson(entry));

      expect(parseMealPlanSync({...ok, 'mealType': ''}), isNull);
      expect(parseMealPlanSync({...ok, 'date': null}), isNull);
      expect(parseMealPlanSync({...ok, 'recipeId': ''}), isNull);
      expect(parseMealPlanSync({...ok, 'v': kSyncSchemaVersion + 1}), isNull);
    });

    test('não feita e sem porções é o padrão', () {
      final json = viaJson(mealPlanToSyncJson(SyncMealPlan(
        id: 'm3',
        recipeId: 'r1',
        date: DateTime.utc(2026, 2, 8),
        mealType: 'lunch',
        createdAt: created,
        updatedAt: updated,
      )));

      final r = parseMealPlanSync(json)!;

      expect(r.done, isFalse);
      expect(r.servingsOverride, isNull);
      expect(r.note, isNull);
    });
  });

  group('lista de compras', () {
    test('ida e volta', () {
      final r = parseShoppingListSync(viaJson(shoppingListToSyncJson(
        SyncShoppingList(
          id: 'l1',
          name: 'Feira',
          status: 'done',
          createdAt: created,
          updatedAt: updated,
        ),
      )))!;

      expect(r.name, 'Feira');
      expect(r.status, 'done');
      expect(r.createdAt, created);
      expect(r.updatedAt, updated);
    });

    test('status ausente vira ativa; sem nome ou versão nova: null', () {
      final ok = viaJson(shoppingListToSyncJson(SyncShoppingList(
        id: 'l1',
        name: 'Feira',
        createdAt: created,
        updatedAt: updated,
      )));

      expect(
          parseShoppingListSync({...ok}..remove('status'))!.status, 'active');
      expect(parseShoppingListSync({...ok, 'name': '  '}), isNull);
      expect(
          parseShoppingListSync({...ok, 'v': kSyncSchemaVersion + 1}), isNull);
    });
  });

  group('item de compras', () {
    final item = SyncShoppingItem(
      id: 'i1',
      listId: 'l1',
      ingredientName: 'Farinha de trigo',
      quantity: 500,
      unit: 'g',
      checked: true,
      note: 'integral',
      position: 3,
      sources: const [
        SyncItemSource(recipeId: 'r1', quantity: 300, unit: 'g'),
        SyncItemSource(recipeId: 'r2', quantity: 200, unit: 'g'),
      ],
      updatedAt: updated,
    );

    test('ida e volta com as receitas de origem', () {
      final r = parseShoppingItemSync(viaJson(shoppingItemToSyncJson(item)))!;

      expect(r.listId, 'l1');
      expect(r.ingredientName, 'Farinha de trigo');
      expect(r.manualName, isNull);
      expect(r.quantity, 500);
      expect(r.unit, 'g');
      expect(r.checked, isTrue);
      expect(r.note, 'integral');
      expect(r.position, 3);
      expect(r.sources.map((s) => (s.recipeId, s.quantity, s.unit)),
          [('r1', 300.0, 'g'), ('r2', 200.0, 'g')]);
      expect(r.updatedAt, updated);
    });

    test('item avulso só com o nome digitado', () {
      final r = parseShoppingItemSync(viaJson(shoppingItemToSyncJson(
        SyncShoppingItem(
          id: 'i2',
          listId: 'l1',
          manualName: 'Pilha AA',
          updatedAt: updated,
        ),
      )))!;

      expect(r.manualName, 'Pilha AA');
      expect(r.ingredientName, isNull);
      expect(r.sources, isEmpty);
      expect(r.checked, isFalse);
    });

    test('sem nome nenhum, sem lista ou de versão nova: null', () {
      final ok = viaJson(shoppingItemToSyncJson(item));

      expect(
        parseShoppingItemSync(
            {...ok, 'ingredientName': null, 'manualName': ' '}),
        isNull,
      );
      expect(parseShoppingItemSync({...ok, 'listId': ''}), isNull);
      expect(
          parseShoppingItemSync({...ok, 'v': kSyncSchemaVersion + 1}), isNull);
    });

    test('origem quebrada é descartada sem derrubar o item', () {
      final json = viaJson(shoppingItemToSyncJson(item));
      json['sources'] = [
        'lixo',
        {'quantity': 3},
        {'recipeId': 'r9', 'quantity': 'muito'},
      ];

      final r = parseShoppingItemSync(json)!;

      expect(r.sources, hasLength(1));
      expect(r.sources.single.recipeId, 'r9');
      expect(r.sources.single.quantity, isNull);
    });
  });

  group('despensa', () {
    test('ida e volta, marcada e desmarcada', () {
      for (final on in [true, false]) {
        final r = parsePantrySync(viaJson(pantryToSyncJson(SyncPantry(
          key: 'sal',
          name: 'Sal',
          inPantry: on,
          updatedAt: updated,
        ))))!;

        expect(r.key, 'sal');
        expect(r.name, 'Sal');
        expect(r.inPantry, on);
        expect(r.updatedAt, updated);
      }
    });

    test('sem chave, sem nome ou de versão nova: null', () {
      final ok = viaJson(pantryToSyncJson(SyncPantry(
        key: 'sal',
        name: 'Sal',
        inPantry: true,
        updatedAt: updated,
      )));

      expect(parsePantrySync({...ok, 'key': ''}), isNull);
      expect(parsePantrySync({...ok, 'name': null}), isNull);
      expect(parsePantrySync({...ok, 'v': kSyncSchemaVersion + 1}), isNull);
      expect(parsePantrySync(42), isNull);
    });

    test('valor que não é booleano conta como desmarcado', () {
      final json = viaJson(pantryToSyncJson(SyncPantry(
        key: 'sal',
        name: 'Sal',
        inPantry: true,
        updatedAt: updated,
      )))
        ..['inPantry'] = 'sim';

      expect(parsePantrySync(json)!.inPantry, isFalse);
    });
  });
}
