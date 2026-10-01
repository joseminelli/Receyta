import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/recipe_similarity.dart';

/// Base de [n] receitas de enchimento, todas com "sal" e cada uma com um
/// ingrediente só dela — dá o sinal de IDF (sal em tudo, o resto raríssimo).
Map<String, Set<String>> _filler(int n) => {
      for (var i = 0; i < n; i++) 'filler$i': {'sal', 'unico$i'},
    };

void main() {
  group('computeIdf', () {
    test('com poucas receitas o peso é uniforme (sem sinal de IDF)', () {
      final w = computeIdf([
        {'frango', 'sal'},
        {'sal'},
        {'sal', 'arroz'},
      ]);
      expect(w.uniform, isTrue);
      expect(w.weightOf('frango'), 1);
      expect(w.weightOf('sal'), 1);
      expect(w.weightOf('desconhecido'), 1);
    });

    test('a partir de 20 receitas o raro pesa mais que o comum', () {
      final catalog = {
        ..._filler(23),
        'a': {'sal', 'frango', 'gengibre'},
        'b': {'sal', 'frango'},
      };
      final w = computeIdf(catalog.values.toList());
      expect(w.uniform, isFalse);
      expect(w.weightOf('gengibre'), greaterThan(w.weightOf('frango')));
      expect(w.weightOf('frango'), greaterThan(w.weightOf('sal')));
    });

    test('ingrediente em todas as receitas não pesa nada (nunca negativo)', () {
      final w = computeIdf(_filler(25).values.toList());
      expect(w.weightOf('sal'), 0);
      expect(w.weightOf('unico3'), greaterThan(0));
    });

    test('fórmula: ln(total / (1 + receitas que usam))', () {
      final catalog = {
        ..._filler(18),
        'a': {'frango'},
        'b': {'frango'},
      };
      final w = computeIdf(catalog.values.toList());
      // 20 receitas, frango em 2: ln(20 / 3).
      expect(w.weightOf('frango'), closeTo(1.8971, 0.001));
    });
  });

  group('weightedJaccard', () {
    final uniform = computeIdf(const []);

    test('conjuntos iguais = 1; sem nada em comum = 0', () {
      expect(weightedJaccard({'a', 'b'}, {'a', 'b'}, uniform), 1);
      expect(weightedJaccard({'a'}, {'b'}, uniform), 0);
    });

    test('peso uniforme é o Jaccard clássico', () {
      expect(weightedJaccard({'a', 'b'}, {'b', 'c'}, uniform), closeTo(1 / 3, 1e-9));
    });

    test('conjunto vazio ou peso total zero devolve 0, nunca NaN', () {
      expect(weightedJaccard(<String>{}, {'a'}, uniform), 0);
      expect(weightedJaccard(<String>{}, <String>{}, uniform), 0);
      final zero = computeIdf(_filler(25).values.toList());
      expect(weightedJaccard({'sal'}, {'sal'}, zero), 0);
    });

    test('ingrediente raro em comum vale mais que o comum', () {
      final catalog = {
        ..._filler(23),
        'frangos': {'frango', 'gengibre'},
        'sopas': {'sopa', 'cebola'},
      };
      final w = computeIdf(catalog.values.toList());
      final viaRaro = weightedJaccard({'frango', 'x'}, {'frango', 'y'}, w);
      final viaSal = weightedJaccard({'sal', 'x'}, {'sal', 'y'}, w);
      expect(viaRaro, greaterThan(viaSal));
    });
  });

  group('suggestRecipes', () {
    final now = DateTime.utc(2026, 10, 1);

    // 22 receitas de enchimento + as candidatas de cada teste.
    Map<String, Set<String>> catalogWith(Map<String, Set<String>> extra) =>
        {..._filler(22), ...extra};

    test('"frango puxa mais que sal": mesmo número em comum, ranking pelo raro',
        () {
      final catalog = catalogWith({
        'so-sal': {'sal', 'x1', 'x2'},
        'com-frango': {'frango', 'x3', 'x4'},
        'agendada': {'frango', 'sal'},
      });
      final result = suggestRecipes(
        catalog: catalog,
        target: {'frango', 'sal'},
        excludeRecipeIds: {'agendada'},
        now: now,
      );
      expect(result.first.recipeId, 'com-frango');
      expect(result.map((s) => s.recipeId), isNot(contains('so-sal')));
    });

    test('não sugere receita já agendada nem a sem nada em comum', () {
      final catalog = catalogWith({
        'a': {'frango', 'gengibre'},
        'b': {'frango'},
        'c': {'chocolate'},
      });
      final result = suggestRecipes(
        catalog: catalog,
        target: {'frango'},
        excludeRecipeIds: {'a'},
        now: now,
      );
      expect(result.map((s) => s.recipeId), ['b']);
    });

    test('o motivo: ingredientes em comum, do mais ao menos informativo', () {
      final catalog = catalogWith({
        'alvo': {'frango', 'gengibre', 'sal'},
        'cand': {'frango', 'gengibre', 'sal', 'arroz'},
        // frango aparece em 3 receitas, gengibre em 2: gengibre é mais raro.
        'meio': {'frango'},
      });
      final result = suggestRecipes(
        catalog: catalog,
        target: {'frango', 'gengibre', 'sal'},
        excludeRecipeIds: {'alvo'},
        now: now,
      );
      final cand = result.firstWhere((s) => s.recipeId == 'cand');
      // gengibre é mais raro que frango; o sal está em tudo, pesa 0 e some.
      expect(cand.sharedIngredientIds.take(2), ['gengibre', 'frango']);
      expect(cand.sharedIngredientIds, isNot(contains('sal')));
    });

    test('receita agendada nos últimos 14 dias é penalizada', () {
      final catalog = catalogWith({
        'recente': {'frango', 'gengibre'},
        'antiga': {'frango', 'gengibre'},
      });
      final result = suggestRecipes(
        catalog: catalog,
        target: {'frango', 'gengibre'},
        lastScheduled: {
          'recente': now.subtract(const Duration(days: 3)),
          'antiga': now.subtract(const Duration(days: 20)),
        },
        now: now,
      );
      expect(result.map((s) => s.recipeId), ['antiga', 'recente']);
      expect(result.last.score, lessThan(result.first.score));
      expect(result.last.score, greaterThan(0));
    });

    test('limite, ordem estável no empate e alvo vazio', () {
      final catalog = catalogWith({
        'b': {'frango'},
        'a': {'frango'},
        'c': {'frango'},
      });
      final result = suggestRecipes(
        catalog: catalog,
        target: {'frango'},
        limit: 2,
        now: now,
      );
      expect(result.map((s) => s.recipeId), ['a', 'b']);

      expect(
        suggestRecipes(catalog: catalog, target: <String>{}, now: now),
        isEmpty,
      );
    });

    test('base pequena (< 20): peso uniforme, ainda sugere por Jaccard', () {
      final result = suggestRecipes(
        catalog: {
          'a': {'frango', 'arroz'},
          'b': {'frango', 'arroz', 'feijao', 'couve'},
          'c': {'peixe'},
        },
        target: {'frango', 'arroz'},
        excludeRecipeIds: {'a'},
        now: now,
      );
      expect(result.map((s) => s.recipeId), ['b']);
      expect(result.single.score, closeTo(0.5, 1e-9));
    });
  });
}
