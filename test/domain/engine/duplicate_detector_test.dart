import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/duplicate_detector.dart';

const _bolo = ExistingRecipe(
  id: 'r1',
  name: 'Bolo de cenoura',
  sourceUrl: 'https://www.exemplo.com.br/receitas/bolo-de-cenoura/',
  ingredientKeys: {'cenoura', 'ovo', 'farinha trigo', 'acucar', 'oleo'},
);

const _frango = ExistingRecipe(
  id: 'r2',
  name: 'Frango ao curry',
  ingredientKeys: {'frango', 'curry', 'leite coco'},
);

void main() {
  group('canonicalUrl', () {
    test('ignora esquema, www, parâmetros, âncora e barra final', () {
      expect(
        canonicalUrl('HTTPS://www.Exemplo.com.br/a/b/?utm=1#topo'),
        'exemplo.com.br/a/b',
      );
      expect(canonicalUrl('  '), isNull);
      expect(canonicalUrl(null), isNull);
    });
  });

  group('findDuplicate', () {
    test('mesmo link, mesmo escrito de outro jeito', () {
      final m = findDuplicate(
        name: 'Qualquer nome',
        sourceUrl: 'http://exemplo.com.br/receitas/bolo-de-cenoura?ref=x',
        existing: [_frango, _bolo],
      );
      expect(m?.recipeId, 'r1');
      expect(m?.reason, DuplicateReason.sameLink);
    });

    test('nome igual ou quase igual', () {
      expect(
        findDuplicate(name: 'bolo de cenouras', existing: [_frango, _bolo])
            ?.reason,
        DuplicateReason.sameName,
      );
      expect(
        findDuplicate(name: 'Bolo cenoura', existing: [_bolo])?.recipeId,
        'r1',
      );
    });

    test('nome diferente, mas ingredientes quase iguais', () {
      final m = findDuplicate(
        name: 'Bolinho alaranjado',
        ingredientKeys: {'cenoura', 'ovo', 'farinha trigo', 'acucar', 'oleo'},
        existing: [_frango, _bolo],
      );
      expect(m?.reason, DuplicateReason.sameIngredients);
      expect(m?.recipeId, 'r1');
    });

    test('poucos ingredientes em comum não é duplicata', () {
      expect(
        findDuplicate(
          name: 'Salada',
          ingredientKeys: {'ovo', 'acucar', 'alface'},
          existing: [_bolo],
        ),
        isNull,
      );
    });

    test('receita diferente não casa', () {
      expect(
        findDuplicate(
          name: 'Lasanha',
          sourceUrl: 'https://outro.com/lasanha',
          ingredientKeys: {'massa', 'queijo', 'molho tomate'},
          existing: [_bolo, _frango],
        ),
        isNull,
      );
    });
  });

  test('ingredientKeysOf usa o nome já limpo pelo parser e normalizador', () {
    expect(
      ingredientKeysOf(['2 xícaras de farinha de trigo', '3 ovos', '']),
      {'farinha trigo', 'ovo'},
    );
  });
}
