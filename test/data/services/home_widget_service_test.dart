import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/services/home_widget_service.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

MealPlanEntry _e(String name, DateTime date, MealType meal,
        {bool done = false}) =>
    MealPlanEntry(
      id: name,
      recipe: Recipe(
        id: name,
        name: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      date: date,
      mealType: meal,
      done: done,
    );

ShoppingListSummary _l(String name, int total, int checked) => (
      list: ShoppingList(
        id: name,
        name: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      total: total,
      checked: checked,
    );

void main() {
  test('ordena por dia e refeição e carrega o estado de feita', () {
    final p = buildWidgetPayload(
      entries: [
        _e('Jantar A', DateTime.utc(2026, 9, 29), MealType.dinner),
        _e('Almoço A', DateTime.utc(2026, 9, 29), MealType.lunch, done: true),
        _e('Ontem', DateTime.utc(2026, 9, 28), MealType.dinner),
      ],
      lists: const [],
    );
    final meals = p['meals']! as List;
    expect(meals.map((m) => (m as Map)['name']),
        ['Ontem', 'Almoço A', 'Jantar A']);
    expect((meals[1] as Map)['date'], '2026-09-29');
    expect((meals[1] as Map)['done'], isTrue);
  });

  test('resume só as compras com itens pendentes', () {
    final p = buildWidgetPayload(
      entries: const [],
      lists: [_l('Feira', 5, 2), _l('Pronta', 3, 3), _l('Mercado', 4, 0)],
    );
    expect(p['shoppingPending'], 7);
    expect(p['shoppingLists'], 2);
    expect(p['shoppingList'], 'Feira');
  });

  test('leva só os itens que faltam da primeira lista em aberto', () {
    ShoppingListItem item(String name, {bool checked = false}) =>
        ShoppingListItem(
          id: name,
          listId: 'Feira',
          displayName: name,
          checked: checked,
        );
    final p = buildWidgetPayload(
      entries: const [],
      lists: [_l('Feira', 3, 1)],
      items: [item('Arroz'), item('Leite', checked: true), item('Ovos')],
    );
    expect(p['shoppingItems'], ['Arroz', 'Ovos']);
    expect(p['shoppingTotal'], 3);
    expect(p['shoppingChecked'], 1);
  });

  test('sem lista em aberto, o widget de compras fica vazio', () {
    final p = buildWidgetPayload(
      entries: const [],
      lists: [_l('Pronta', 2, 2)],
    );
    expect(p['shoppingItems'], isEmpty);
    expect(p['shoppingTotal'], 0);
  });
}
