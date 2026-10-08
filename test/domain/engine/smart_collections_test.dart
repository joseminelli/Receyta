import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/domain/models/recipe.dart';

final _now = DateTime.utc(2026, 10, 8);

Recipe _r(
  String id, {
  int? prep,
  int? cook,
  bool fav = false,
  DateTime? created,
  DateTime? opened,
}) =>
    Recipe(
      id: id,
      name: id,
      createdAt: created ?? _now.subtract(const Duration(days: 5)),
      updatedAt: created ?? _now.subtract(const Duration(days: 5)),
      prepMinutes: prep,
      cookMinutes: cook,
      isFavorite: fav,
      lastOpenedAt: opened,
    );

CookLog _log(String recipeId, int daysAgo) => CookLog(
      id: '$recipeId-$daysAgo',
      recipeId: recipeId,
      cookedAt: _now.subtract(Duration(days: daysAgo)),
    );

List<String> _ids(List<Recipe> l) => [for (final r in l) r.id];

void main() {
  List<Recipe> run(
    SmartCollection c,
    List<Recipe> recipes, [
    List<CookLog> logs = const [],
  ]) =>
      recipesIn(c, recipes, cookStatsOf(logs), _now);

  test(
      'rápidas: soma prep + cozimento, mais rápida primeiro; sem tempo fica de fora',
      () {
    final out = run(SmartCollection.quick, [
      _r('lenta', prep: 20, cook: 60),
      _r('meia', prep: 10, cook: 20),
      _r('curta', cook: 10),
      _r('semTempo'),
    ]);
    expect(_ids(out), ['curta', 'meia']);
  });

  test('nunca cozinhei: só quem não tem registro, a mais nova primeiro', () {
    final out = run(
      SmartCollection.neverCooked,
      [
        _r('velha', created: _now.subtract(const Duration(days: 30))),
        _r('feita'),
        _r('nova', created: _now.subtract(const Duration(days: 1))),
      ],
      [_log('feita', 3)],
    );
    expect(_ids(out), ['nova', 'velha']);
  });

  test('mais feitas: ao menos 2 vezes, a mais repetida primeiro', () {
    final out = run(
      SmartCollection.mostCooked,
      [_r('a'), _r('b'), _r('c')],
      [
        _log('a', 1),
        _log('a', 9),
        _log('b', 2),
        _log('b', 3),
        _log('b', 4),
        _log('c', 1)
      ],
    );
    expect(_ids(out), ['b', 'a']);
  });

  test('esquecidas: mais de 60 dias sem cozinhar, abrir ou criar', () {
    final out = run(
      SmartCollection.forgotten,
      [
        _r('antiga', created: _now.subtract(const Duration(days: 200))),
        _r('abertaHa10',
            created: _now.subtract(const Duration(days: 200)),
            opened: _now.subtract(const Duration(days: 10))),
        _r('feitaHa5', created: _now.subtract(const Duration(days: 200))),
        _r('maisAntiga', created: _now.subtract(const Duration(days: 400))),
        _r('nova'),
      ],
      [_log('feitaHa5', 5)],
    );
    expect(_ids(out), ['maisAntiga', 'antiga']);
  });

  test('favoritas: só as marcadas', () {
    expect(
      _ids(run(SmartCollection.favorites, [_r('a', fav: true), _r('b')])),
      ['a'],
    );
  });

  test('buildSmartCollections omite as vazias, na ordem do enum', () {
    final out = buildSmartCollections(
      [_r('a', cook: 10, fav: true)],
      const [],
      _now,
    );
    expect(out.keys.toList(), [
      SmartCollection.quick,
      SmartCollection.neverCooked,
      SmartCollection.favorites,
    ]);
  });

  test('fromName', () {
    expect(SmartCollection.fromName('quick'), SmartCollection.quick);
    expect(SmartCollection.fromName('nada'), isNull);
  });
}
