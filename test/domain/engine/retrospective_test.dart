import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/domain/models/cook_log.dart';

final _oct = RetroPeriod.monthOf(DateTime(2026, 10, 15));

CookLog _log(String recipeId, int month, int day, {int year = 2026}) => CookLog(
      id: '$recipeId-$year-$month-$day',
      recipeId: recipeId,
      recipeName: recipeId,
      cookedAt: DateTime(year, month, day, 19),
    );

RetroRecipe _recipe(
  String id, {
  int minutes = 0,
  List<String> tags = const [],
  DateTime? created,
}) =>
    RetroRecipe(
      id: id,
      name: 'Receita $id',
      createdAt: created ?? DateTime(2025),
      minutes: minutes,
      tags: tags,
    );

void main() {
  group('RetroPeriod', () {
    test('mês: limites, rótulo e navegação', () {
      expect(_oct.start, DateTime(2026, 10));
      expect(_oct.end, DateTime(2026, 11));
      expect(_oct.label, 'Outubro 2026');
      expect(_oct.inSentence, 'outubro');
      expect(_oct.contains(DateTime(2026, 10, 31, 23, 59)), isTrue);
      expect(_oct.contains(DateTime(2026, 11)), isFalse);
      expect(_oct.shift(-10).start, DateTime(2025, 12));
      expect(_oct.shift(3).start, DateTime(2027, 1));
    });

    test('ano', () {
      final y = RetroPeriod.yearOf(DateTime(2026, 6, 1));
      expect(y.label, '2026');
      expect(y.contains(DateTime(2026, 12, 31)), isTrue);
      expect(y.contains(DateTime(2027)), isFalse);
      expect(y.shift(-1).start, DateTime(2025));
      expect(y.containing(DateTime(2030, 3, 3)).start, DateTime(2030));
    });

    test('igualdade por valor', () {
      expect(RetroPeriod.monthOf(DateTime(2026, 10, 1)), _oct);
      expect(
          _oct.hashCode, RetroPeriod.monthOf(DateTime(2026, 10, 30)).hashCode);
    });
  });

  group('buildRetrospective', () {
    test('sem histórico no período fica vazia, mas conta receitas novas', () {
      final r = buildRetrospective(
        period: _oct,
        logs: [_log('a', 9, 30)],
        recipes: {'a': _recipe('a', created: DateTime(2026, 10, 3))},
      );
      expect(r.isEmpty, isTrue);
      expect(r.topRecipe, isNull);
      expect(r.newRecipes, 1);
    });

    test('totais, receita e tag mais frequentes, tempo no fogão', () {
      final r = buildRetrospective(
        period: _oct,
        logs: [
          _log('a', 10, 1),
          _log('a', 10, 8),
          _log('a', 10, 15),
          _log('b', 10, 9),
          _log('b', 11, 2), // fora do período
        ],
        recipes: {
          'a': _recipe('a', minutes: 40, tags: ['Massas', 'Jantar']),
          'b': _recipe('b', minutes: 20, tags: ['Jantar']),
        },
      );
      expect(r.cookCount, 4);
      expect(r.distinctRecipes, 2);
      expect(r.totalMinutes, 3 * 40 + 20);
      expect(r.topRecipe?.id, 'a');
      expect(r.topRecipe?.times, 3);
      expect(r.topTag?.name, 'Jantar');
      expect(r.topTag?.times, 4);
    });

    test('empate na receita mais feita vai pra mais recente', () {
      final r = buildRetrospective(
        period: _oct,
        logs: [_log('a', 10, 1), _log('b', 10, 20)],
        recipes: {'a': _recipe('a'), 'b': _recipe('b')},
      );
      expect(r.topRecipe?.id, 'b');
    });

    test('dia da semana mais cozinhado e maior sequência', () {
      // 5, 6, 7 de out/2026 = seg, ter, qua; 12 = seg; 19 = seg.
      final r = buildRetrospective(
        period: _oct,
        logs: [
          _log('a', 10, 5),
          _log('a', 10, 6),
          _log('b', 10, 7),
          _log('a', 10, 12),
          _log('b', 10, 19),
        ],
        recipes: {'a': _recipe('a'), 'b': _recipe('b')},
      );
      expect(r.busiestWeekday, DateTime.monday);
      expect(r.bestStreak, 3);
    });

    test('duas vezes no mesmo dia contam um dia só na sequência', () {
      final r = buildRetrospective(
        period: _oct,
        logs: [_log('a', 10, 5), _log('b', 10, 5), _log('a', 10, 6)],
        recipes: {'a': _recipe('a'), 'b': _recipe('b')},
      );
      expect(r.cookCount, 3);
      expect(r.bestStreak, 2);
    });

    test('receita apagada ainda conta, sem tempo nem tag', () {
      final r = buildRetrospective(
        period: _oct,
        logs: [_log('sumiu', 10, 5)],
        recipes: const {},
      );
      expect(r.cookCount, 1);
      expect(r.totalMinutes, 0);
      expect(r.topRecipe?.name, 'sumiu');
      expect(r.topTag, isNull);
    });
  });

  test('formatCookingTime', () {
    expect(formatCookingTime(0), '0 min');
    expect(formatCookingTime(45), '45 min');
    expect(formatCookingTime(120), '2 h');
    expect(formatCookingTime(870), '14 h 30 min');
  });

  test('retroWeekdayName', () {
    expect(retroWeekdayName(1), 'Segunda');
    expect(retroWeekdayName(7), 'Domingo');
  });
}
