import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => DateTime.utc(2026));
  });
  tearDown(() => db.close());

  Future<String> create({
    required String name,
    String? about,
    String? notes,
    List<String> tags = const [],
  }) async {
    final r = await repo.saveDetail(
      name: name,
      about: about,
      notes: notes,
      tagNames: tags,
    ) as Ok<Recipe>;
    return r.value.id;
  }

  Future<List<String>> search(String q) async =>
      (await repo.search(q).first).map((r) => r.name).toList();

  test('acha por nome (prefixo), sobre e notas', () async {
    await create(name: 'Frango ao curry', about: 'rápido para a semana');
    await create(name: 'Bolo de fubá', notes: 'melhor no dia seguinte');
    await create(name: 'Sopa de abóbora');

    expect(await search('fran'), ['Frango ao curry']); // prefixo no nome
    expect(await search('semana'), ['Frango ao curry']); // sobre
    expect(await search('seguinte'), ['Bolo de fubá']); // notas
    expect((await search('de')).toSet(), {'Bolo de fubá', 'Sopa de abóbora'});
  });

  test('acha por tag', () async {
    await create(name: 'Curry', tags: ['rápido']);
    await create(name: 'Lasanha', tags: ['forno']);

    expect(await search('rápido'), ['Curry']);
    expect(await search('forn'), ['Lasanha']); // LIKE parcial na tag
  });

  test('query vazia ou só espaço devolve vazio', () async {
    await create(name: 'Curry');
    expect(await search(''), isEmpty);
    expect(await search('   '), isEmpty);
  });

  test('não traz receita da lixeira', () async {
    final id = await create(name: 'Curry secreto');
    expect(await search('secreto'), ['Curry secreto']);

    await repo.softDelete(id);
    expect(await search('secreto'), isEmpty);
  });

  test('acompanha edição do nome', () async {
    final id = await create(name: 'Frango');
    expect(await search('frango'), ['Frango']);

    final base = (await repo.getById(id) as Ok<Recipe>).value;
    await repo.saveDetail(base: base, name: 'Peixe assado');
    expect(await search('frango'), isEmpty);
    expect(await search('peixe'), ['Peixe assado']);
  });
}
