import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/pantry_match.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/recipe.dart';

Recipe _r(String id) {
  final t = DateTime.utc(2026);
  return Recipe(id: id, name: id, createdAt: t, updatedAt: t);
}

void main() {
  group('matchPantry', () {
    final byRecipe = {
      'tudo': {'ovo', 'leite'},
      'falta1': {'ovo', 'leite', 'farinha'},
      'falta2': {'ovo', 'leite', 'farinha', 'acucar'},
      'falta3': {'ovo', 'leite', 'farinha', 'acucar', 'manteiga'},
      'nada': {'chocolate', 'creme'},
    };
    final pantry = {'ovo', 'leite'};

    test('guarda quem falta até o limite e tem algo na despensa', () {
      final m = matchPantry(byRecipe, pantry);

      expect(m.keys, containsAll(['tudo', 'falta1', 'falta2']));
      expect(m.containsKey('falta3'), isFalse);
      expect(m.containsKey('nada'), isFalse);
      expect(m['tudo']!.hasEverything, isTrue);
      expect(m['falta2']!.missingIds, ['acucar', 'farinha']);
      expect(m['falta1']!.have, 2);
    });

    test('despensa vazia não casa nada', () {
      expect(matchPantry(byRecipe, <String>{}), isEmpty);
    });

    test('receita sem ingrediente catalogado fica de fora', () {
      expect(matchPantry({'vazia': <String>{}}, pantry), isEmpty);
    });
  });

  test('coleção Dá pra fazer ordena por quem falta menos', () {
    final recipes = [_r('b'), _r('a'), _r('c'), _r('z')];
    final pantry = matchPantry(
      {
        'a': {'ovo', 'leite', 'farinha'},
        'b': {'ovo', 'leite'},
        'c': {'ovo', 'leite', 'farinha'},
        'z': {'chocolate'},
      },
      {'ovo', 'leite'},
    );

    final out = recipesIn(
      SmartCollection.canCook,
      recipes,
      const {},
      DateTime.utc(2026, 10, 8),
      pantry: pantry,
    );

    expect([for (final r in out) r.id], ['b', 'a', 'c']);
  });

  test('sem despensa a coleção some', () {
    final out = buildSmartCollections([_r('a')], const [], DateTime.utc(2026));
    expect(out.containsKey(SmartCollection.canCook), isFalse);
  });
}
