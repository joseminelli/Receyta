import 'package:flutter_test/flutter_test.dart';

import 'package:receyta/domain/engine/ingredient_category.dart';
import 'package:receyta/domain/engine/shopping_text.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

ShoppingListItem _item(
  String name, {
  double? qty,
  String? unit,
  int position = 0,
  bool checked = false,
  List<String> recipes = const [],
}) =>
    ShoppingListItem(
      id: name,
      listId: 'l',
      displayName: name,
      quantity: qty,
      unitId: unit,
      position: position,
      checked: checked,
      categorySlug: categorySlugFor(name),
      sources: [
        for (final r in recipes) ShoppingItemSource(recipeId: r, recipeName: r),
      ],
    );

void main() {
  group('categorySlugFor', () {
    test('casa por palavra inteira, com ou sem acento e no plural', () {
      expect(categorySlugFor('Tomate'), 'hortifruti');
      expect(categorySlugFor('Tomates'), 'hortifruti');
      expect(categorySlugFor('Limão'), 'hortifruti');
      expect(categorySlugFor('Leite'), 'frios_laticinios');
      expect(categorySlugFor('Farinha de Trigo'), 'mercearia');
    });

    test('o mais específico vence: molho de tomate não é hortifruti', () {
      expect(categorySlugFor('Molho de Tomate'), 'massas_molhos');
    });

    test('"sal" não pega salsinha nem salmão', () {
      expect(categorySlugFor('Sal'), 'temperos_condimentos');
      expect(categorySlugFor('Salsinha'), 'hortifruti');
      expect(categorySlugFor('Salmão'), 'peixaria');
    });

    test('desconhecido cai em outros', () {
      expect(categorySlugFor('Xyzzy'), 'outros');
    });
  });

  group('groupShoppingItems', () {
    test('seções na ordem do mercado, itens na ordem de position', () {
      final groups = groupShoppingItems([
        _item('Farinha de Trigo', position: 0),
        _item('Leite', position: 1),
        _item('Cebola', position: 2),
        _item('Tomate', position: 3),
      ]);
      expect(
        groups.map((g) => g.slug),
        ['hortifruti', 'frios_laticinios', 'mercearia'],
      );
      expect(
          groups.first.items.map((i) => i.displayName), ['Cebola', 'Tomate']);
    });
  });

  group('groupShoppingItems com sinkChecked', () {
    test('marcados vão pro fim da seção; seção toda marcada pro fim da lista',
        () {
      final groups = groupShoppingItems(
        [
          _item('Cebola', position: 0, checked: true),
          _item('Tomate', position: 1),
          _item('Leite', position: 2, checked: true),
          _item('Farinha de Trigo', position: 3),
        ],
        sinkChecked: true,
      );
      expect(
        groups.map((g) => g.slug),
        ['hortifruti', 'mercearia', 'frios_laticinios'],
      );
      expect(
          groups.first.items.map((i) => i.displayName), ['Tomate', 'Cebola']);
    });
  });

  group('buildShoppingListText', () {
    test('título, seções, marcação e origem', () {
      final text = buildShoppingListText('Lista de 29/09', [
        _item('Farinha de Trigo',
            qty: 1300, unit: 'g', recipes: ['Bolo', 'Pão'], position: 0),
        _item('Cebola', qty: 2, unit: 'unidade', checked: true, position: 1),
        _item('Leite', position: 2),
      ]);
      expect(text, startsWith('Lista de 29/09\n\nHORTIFRÚTI\n[x] 2 '));
      expect(text, contains('\n\nFRIOS E LATICÍNIOS\n[ ] Leite'));
      expect(text, contains('Farinha de Trigo (Bolo, Pão)'));
      expect(text.indexOf('HORTIFRÚTI'), lessThan(text.indexOf('MERCEARIA')));
    });
  });
}
