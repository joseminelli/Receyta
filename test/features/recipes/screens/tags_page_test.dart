import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/features/recipes/tags_page.dart';
import 'package:receyta/theme/app_theme.dart';

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
        tagRepositoryProvider
            .overrideWithValue(TagRepository(db.tagDao)),
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

  testWidgets('apagar pede confirmação e chama o repositório', (tester) async {
    final row = (await db.tagDao.ensureTags(['órfã'])).single;

    await tester.pumpWidget(host());
    tags.add([(tag: Tag(id: row.id, name: 'órfã'), count: 0)]);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    final count = await tester.runAsync(() async => (await db
            .customSelect('SELECT COUNT(*) c FROM tags')
            .getSingle())
        .read<int>('c'));
    expect(count, 0);
  });
}
