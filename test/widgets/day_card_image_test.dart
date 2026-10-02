import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/day_card_image.dart';

int _u32(Uint8List b, int i) =>
    (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('altura cresce com o número de refeições', () {
    expect(dayCardHeight(2) - dayCardHeight(1),
        dayCardHeight(3) - dayCardHeight(2));
    expect(dayCardHeight(3), greaterThan(dayCardHeight(1)));
  });

  testWidgets('gera um PNG na largura e na altura esperadas', (tester) async {
    final png = await tester.runAsync(
      () => renderDayCardPng(
        day: DateTime(2026, 10, 2),
        meals: const [
          DayCardMeal(
            recipeId: 'a',
            recipeName: 'Pão de Queijo de Frigideira',
            mealLabel: 'Café da manhã',
            tileColor: TileColor.coral,
            tileMotif: TileMotif.arco,
          ),
          DayCardMeal(
            recipeId: 'b',
            recipeName:
                'Pasta de Grão de Bico (homus) com um nome bem comprido',
            mealLabel: 'Almoço',
            done: true,
          ),
          DayCardMeal(recipeId: 'c', recipeName: 'Bolo', mealLabel: 'Lanche'),
        ],
      ),
    );

    expect(png, isNotNull);
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    // IHDR: largura e altura nos bytes 16–23.
    expect(_u32(png, 16), 1080);
    expect(_u32(png, 20), dayCardHeight(3).ceil());
  });

  testWidgets('um dia com uma refeição só também renderiza', (tester) async {
    final png = await tester.runAsync(
      () => renderDayCardPng(
        day: DateTime(2026, 12, 31),
        meals: const [
          DayCardMeal(recipeId: 'a', recipeName: 'Sopa', mealLabel: 'Jantar'),
        ],
      ),
    );

    expect(png, isNotNull);
    expect(_u32(png!, 20), dayCardHeight(1).ceil());
  });

  group('cartão da semana', () {
    WeekCardDay d(int day, List<DayCardMeal> meals) =>
        WeekCardDay(day: DateTime(2026, 9, day), meals: meals);

    const bolo = DayCardMeal(
      recipeId: 'a',
      recipeName: 'Bolo de cenoura',
      mealLabel: 'Lanche',
    );

    test('altura soma cada dia: vazio é mais baixo que com refeições', () {
      final vazio = weekCardHeight([d(28, const [])]);
      final cheio = weekCardHeight([
        d(28, const [bolo, bolo, bolo])
      ]);

      expect(cheio, greaterThan(vazio));
    });

    testWidgets('gera um PNG na altura calculada', (tester) async {
      final days = [
        d(28, const [bolo]),
        d(29, const []),
        d(30, const [bolo, bolo]),
        d(31, const []),
        d(1, const []),
        d(2, const [bolo]),
        d(3, const []),
      ];
      final png = await tester.runAsync(
        () => renderWeekCardPng(monday: DateTime(2026, 9, 28), days: days),
      );

      expect(png, isNotNull);
      expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(_u32(png, 16), 1080);
      expect(_u32(png, 20), weekCardHeight(days).ceil());
    });
  });
}
