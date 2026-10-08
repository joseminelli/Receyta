import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/features/recipes/screens/tags_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/tile_pattern.dart';

void main() {
  late AppDatabase db;
  late StreamController<List<({Tag tag, int count})>> tags;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tags = StreamController<List<({Tag tag, int count})>>.broadcast();
  });
  tearDown(() async {
    await tags.close();
    await db.close();
  });

  Widget host() {
    final router = GoRouter(
      initialLocation: '/tags',
      routes: [GoRoute(path: '/tags', builder: (_, __) => const TagsPage())],
    );
    return ProviderScope(
      overrides: [
        tagRepositoryProvider.overrideWithValue(TagRepository(db.tagDao)),
        tagsWithCountsProvider.overrideWith((ref) => tags.stream),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  testWidgets('lista tags usadas e não usadas com a contagem', (tester) async {
    await tester.pumpWidget(host());
    tags.add(const [
      (tag: Tag(id: 't1', name: 'Rápido'), count: 3),
      (tag: Tag(id: 't2', name: 'Órfã'), count: 0),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Rápido'), findsOneWidget);
    expect(find.text('3 receitas'), findsOneWidget);
    expect(find.text('Órfã'), findsOneWidget);
    expect(find.text('Não usada'), findsOneWidget);
  });

  testWidgets('o azulejo traz o número grande e a barra compara o uso',
      (tester) async {
    await tester.pumpWidget(host());
    tags.add(const [
      (tag: Tag(id: 't1', name: 'Rápido'), count: 8),
      (tag: Tag(id: 't2', name: 'Doce'), count: 2),
      (tag: Tag(id: 't3', name: 'Órfã'), count: 0),
    ]);
    await tester.pumpAndSettle();

    // O número de receitas aparece grande no azulejo.
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Barra do mais usado = 100%; a do Doce = 25% do mais usado.
    final bars = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((b) => b.widthFactor)
        .toList();
    expect(bars, [1.0, 0.25]);
  });

  testWidgets('a mesma tag sempre tem a mesma cor de azulejo', (tester) async {
    await tester.pumpWidget(host());
    tags.add(const [(tag: Tag(id: 't1', name: 'Rápido'), count: 1)]);
    await tester.pumpAndSettle();
    final first = tester.getRect(find.byType(TilePattern).first);

    tags.add(const [(tag: Tag(id: 't1', name: 'Rápido'), count: 5)]);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TilePattern).first), first);
  });

  testWidgets('apagar pede confirmação e chama o repositório', (tester) async {
    final row = (await db.tagDao.ensureTags(['órfã'])).single;

    await tester.pumpWidget(host());
    tags.add([(tag: Tag(id: row.id, name: 'órfã'), count: 0)]);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    final count = await tester.runAsync(() async =>
        (await db.customSelect('SELECT COUNT(*) c FROM tags').getSingle())
            .read<int>('c'));
    expect(count, 0);
  });
}
