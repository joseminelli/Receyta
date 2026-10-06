import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/sync_codec.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';

void main() {
  final created = DateTime.utc(2026, 1, 1, 10);
  final updated = DateTime.utc(2026, 2, 3, 11, 30, 15);

  RecipeDetail detail({
    Recipe? recipe,
    List<RecipeIngredient>? ingredients,
  }) {
    return RecipeDetail(
      recipe: recipe ??
          Recipe(
            id: 'r1',
            name: 'Frango ao curry',
            createdAt: created,
            updatedAt: updated,
            folderId: 'f1',
            about: 'Rápido',
            prepMinutes: 15,
            cookMinutes: 25,
            servings: 4,
            imagePath: 'abc.jpg',
            sourceUrl: 'https://x.com/frango',
            notes: 'Melhor no dia seguinte',
            tileColor: TileColor.mar,
            tileMotif: TileMotif.onda,
            isFavorite: true,
            deletedAt: DateTime.utc(2026, 3, 1),
          ),
      ingredients: ingredients ??
          const [
            RecipeIngredient(
              id: 'i1',
              recipeId: 'r1',
              rawText: '500g de peito de frango em cubos',
              position: 0,
              groupLabel: 'Base',
              ingredientId: 'ing1',
              quantity: 500,
              unitId: 'g',
              qualifier: 'em cubos',
            ),
          ],
      steps: const [
        RecipeStep(
          id: 's1',
          recipeId: 'r1',
          text: 'Tempere.',
          position: 0,
          groupLabel: 'Preparo',
        ),
      ],
      tags: const [
        Tag(id: 't1', name: 'Frango'),
        Tag(id: 't2', name: 'Rápido'),
      ],
    );
  }

  Map<String, dynamic> viaJson(Map<String, dynamic> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  group('receita', () {
    test('ida e volta pelo JSON preserva tudo que o aparelho guarda', () {
      final json = viaJson(
        recipeToSyncJson(detail(),
            ingredientNames: {'ing1': 'Peito de frango'}),
      );

      final r = parseRecipeSync(json)!;

      expect(r.id, 'r1');
      expect(r.name, 'Frango ao curry');
      expect(r.folderId, 'f1');
      expect(r.about, 'Rápido');
      expect(r.prepMinutes, 15);
      expect(r.cookMinutes, 25);
      expect(r.servings, 4);
      expect(r.imageName, 'abc.jpg');
      expect(r.sourceUrl, 'https://x.com/frango');
      expect(r.notes, 'Melhor no dia seguinte');
      expect(r.tileColor, TileColor.mar);
      expect(r.tileMotif, TileMotif.onda);
      expect(r.isFavorite, isTrue);
      expect(r.deletedAt, DateTime.utc(2026, 3, 1));
      expect(r.createdAt, created);
      expect(r.updatedAt, updated);
      expect(r.tags, ['Frango', 'Rápido']);

      final i = r.ingredients.single;
      expect(i.name, 'Peito de frango');
      expect(i.rawText, '500g de peito de frango em cubos');
      expect(i.quantity, 500);
      expect(i.unit, 'g');
      expect(i.qualifier, 'em cubos');
      expect(i.groupLabel, 'Base');

      final s = r.steps.single;
      expect(s.text, 'Tempere.');
      expect(s.groupLabel, 'Preparo');
    });

    test('ingrediente sem catálogo vai pelo texto digitado, nunca vazio', () {
      final json = recipeToSyncJson(
        detail(
          ingredients: const [
            RecipeIngredient(
              id: 'i1',
              recipeId: 'r1',
              rawText: 'sal a gosto',
              position: 0,
            ),
          ],
        ),
        ingredientNames: const {},
      );

      expect((json['ingredients'] as List).single['name'], 'sal a gosto');
    });

    test('receita simples (sem azulejo, sem foto, ativa) volta sem inventar',
        () {
      final plain = Recipe(
        id: 'r2',
        name: 'Sopa',
        createdAt: created,
        updatedAt: updated,
      );

      final r = parseRecipeSync(viaJson(
        recipeToSyncJson(detail(recipe: plain, ingredients: const []),
            ingredientNames: const {}),
      ))!;

      expect(r.tileColor, isNull);
      expect(r.tileMotif, isNull);
      expect(r.imageName, isNull);
      expect(r.deletedAt, isNull);
      expect(r.isFavorite, isFalse);
      expect(r.folderId, isNull);
    });

    test('as datas viajam em UTC', () {
      final local = Recipe(
        id: 'r3',
        name: 'X',
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 2, 9),
      );

      final json =
          recipeToSyncJson(detail(recipe: local), ingredientNames: const {});

      expect(json['createdAt'], endsWith('Z'));
      expect(json['updatedAt'], endsWith('Z'));
    });

    test('corpo de uma versão mais nova que a minha é ignorado', () {
      final json = viaJson(
          recipeToSyncJson(detail(), ingredientNames: {'ing1': 'Frango'}));
      json['v'] = kSyncSchemaVersion + 1;

      expect(parseRecipeSync(json), isNull);
    });

    test('corpo sem versão é lido como a versão 1', () {
      final json = viaJson(
          recipeToSyncJson(detail(), ingredientNames: {'ing1': 'Frango'}));
      json.remove('v');

      expect(parseRecipeSync(json), isNotNull);
    });

    test('lixo não lança: vira null, ou campo ignorado', () {
      expect(parseRecipeSync(null), isNull);
      expect(parseRecipeSync('texto'), isNull);
      expect(parseRecipeSync(<String, dynamic>{}), isNull);
      expect(
        parseRecipeSync({'id': 'a', 'name': '  ', 'createdAt': 'x'}),
        isNull,
      );
      expect(
        parseRecipeSync({
          'id': 'a',
          'name': 'ok',
          'createdAt': 'não é data',
          'updatedAt': 'idem',
        }),
        isNull,
      );

      final r = parseRecipeSync({
        'id': 'a',
        'name': 'ok',
        'createdAt': created.toIso8601String(),
        'updatedAt': updated.toIso8601String(),
        'prepMinutes': 'dez',
        'servings': 4.0,
        'tileColor': 'cor_que_nao_existe',
        'tags': ['A', 5, '', null],
        'ingredients': [
          'não é mapa',
          {'rawText': ''},
          {'rawText': '2 ovos', 'quantity': 'dois'},
        ],
        'steps': [
          {'text': ''},
          {'text': 'Misture'},
          42,
        ],
      })!;

      expect(r.prepMinutes, isNull);
      expect(r.servings, 4);
      expect(r.tileColor, isNull);
      expect(r.tags, ['A']);
      expect(r.ingredients.single.rawText, '2 ovos');
      expect(r.ingredients.single.quantity, isNull);
      expect(r.ingredients.single.name, '2 ovos');
      expect(r.steps.single.text, 'Misture');
    });

    test('todas as cores e texturas sobrevivem à ida e volta', () {
      for (final c in TileColor.values) {
        for (final m in TileMotif.values) {
          final json = viaJson(recipeToSyncJson(
            detail(
              recipe: Recipe(
                id: 'r',
                name: 'X',
                createdAt: created,
                updatedAt: updated,
                tileColor: c,
                tileMotif: m,
              ),
            ),
            ingredientNames: const {},
          ));

          final r = parseRecipeSync(json)!;
          expect(r.tileColor, c);
          expect(r.tileMotif, m);
        }
      }
    });
  });

  group('pasta', () {
    test('ida e volta pelo JSON', () {
      final json = viaJson(folderToSyncJson(
        id: 'f1',
        name: 'Massas',
        parentId: 'f0',
        position: 3,
        tileColor: TileColor.floresta,
        tileMotif: TileMotif.xadrez,
        createdAt: created,
        updatedAt: updated,
      ));

      final f = parseFolderSync(json)!;

      expect(f.id, 'f1');
      expect(f.name, 'Massas');
      expect(f.parentId, 'f0');
      expect(f.position, 3);
      expect(f.tileColor, TileColor.floresta);
      expect(f.tileMotif, TileMotif.xadrez);
      expect(f.createdAt, created);
      expect(f.updatedAt, updated);
    });

    test('pasta de raiz não tem pai', () {
      final f = parseFolderSync(viaJson(folderToSyncJson(
        id: 'f1',
        name: 'Raiz',
        createdAt: created,
        updatedAt: updated,
      )))!;

      expect(f.parentId, isNull);
      expect(f.tileColor, isNull);
    });

    test('versão mais nova, lixo ou sem nome: null', () {
      final ok = folderToSyncJson(
        id: 'f1',
        name: 'A',
        createdAt: created,
        updatedAt: updated,
      );

      expect(parseFolderSync({...ok, 'v': kSyncSchemaVersion + 1}), isNull);
      expect(parseFolderSync({...ok, 'name': ''}), isNull);
      expect(parseFolderSync({...ok, 'id': null}), isNull);
      expect(parseFolderSync(42), isNull);
    });
  });
}
