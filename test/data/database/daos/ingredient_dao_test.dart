import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('getOrCreate cria na primeira vez e reusa depois', () async {
    final first = await db.ingredientDao.getOrCreate('Tomate');
    final second = await db.ingredientDao.getOrCreate('tomates');

    expect(second.id, first.id);
    expect(first.displayName, 'Tomate');
    expect(first.normalizedKey, 'tomate');
  });

  test('bate por alias sem criar duplicata', () async {
    final tomato = await db.ingredientDao.getOrCreate('Tomate');
    await db.into(db.ingredientAliases).insert(
          IngredientAliasRow(
            id: 'alias-1',
            ingredientId: tomato.id,
            normalizedAlias: 'jitomate',
          ),
        );

    final byAlias = await db.ingredientDao.getOrCreate('jitomate');
    expect(byAlias.id, tomato.id);

    final all = await db.select(db.ingredients).get();
    expect(all.length, 1);
  });

  test('nomes diferentes viram ingredientes diferentes', () async {
    final a = await db.ingredientDao.getOrCreate('Cebola');
    final b = await db.ingredientDao.getOrCreate('Alho');
    expect(a.id, isNot(b.id));
  });
}
