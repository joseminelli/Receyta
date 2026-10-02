import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/features/recipes/screens/history_page.dart';
import 'package:receyta/theme/app_theme.dart';

class _FakeRepo implements CookLogRepository {
  final removed = <String>[];

  @override
  Future<Result<String>> add(
    String recipeId, {
    DateTime? cookedAt,
    String? note,
  }) async =>
      const Ok('novo');

  @override
  Future<Result<void>> remove(String id) async {
    removed.add(id);
    return const Ok(null);
  }

  @override
  Stream<List<CookLog>> watchForRecipe(String recipeId) => const Stream.empty();

  @override
  Stream<List<CookLog>> watchAll() => const Stream.empty();
}

CookLog _log(String id, String recipeId, String name, DateTime at,
        {String? note}) =>
    CookLog(
      id: id,
      recipeId: recipeId,
      recipeName: name,
      cookedAt: at,
      note: note,
    );

Widget _host(List<CookLog> logs, {_FakeRepo? repo}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HistoryPage()),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => Text('ROTA ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      allCookLogsProvider.overrideWith((ref) => Stream.value(logs)),
      if (repo != null) cookLogRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  final recent = DateTime.now();
  final lastYear = DateTime(recent.year - 1, 3, 10, 12);

  testWidgets('sem registros, convida a cozinhar', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text('Nada cozinhado ainda'), findsOneWidget);
  });

  testWidgets('cabeçalho com totais, grupos por mês e nota', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host([
        _log('3', 'a', 'Bolo', recent, note: 'ficou ótimo'),
        _log('2', 'b', 'Sopa', lastYear),
        _log('1', 'a', 'Bolo', lastYear),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('O que você cozinhou'), findsOneWidget);
    expect(find.text('3 VEZES · 2 RECEITAS'), findsOneWidget);
    expect(find.text('Março ${lastYear.year}'), findsOneWidget);
    expect(find.text('ficou ótimo'), findsOneWidget);
  });

  testWidgets('buscar filtra por receita, sem ligar pra acento',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host([
        _log('1', 'a', 'Pão de queijo', recent),
        _log('2', 'b', 'Sopa de abóbora', recent),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abobora');
    await tester.pumpAndSettle();

    expect(find.text('Sopa de abóbora'), findsOneWidget);
    expect(find.text('Pão de queijo'), findsNothing);
  });

  testWidgets('filtro "Com nota" e mensagem quando nada combina',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host([
        _log('1', 'a', 'Bolo', recent, note: 'faltou sal'),
        _log('2', 'b', 'Sopa', recent),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Com nota'));
    await tester.pumpAndSettle();
    expect(find.text('Bolo'), findsOneWidget);
    expect(find.text('Sopa'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Nada com esse filtro.'), findsOneWidget);
  });

  testWidgets('tocar numa linha abre a receita', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([_log('1', 'abc', 'Bolo', recent)]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bolo'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA abc'), findsOneWidget);
  });

  testWidgets('apagar tira o registro do histórico', (tester) async {
    _usePhoneSize(tester);
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _host([_log('x1', 'a', 'Bolo', recent)], repo: repo),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Apagar do histórico'));
    await tester.pumpAndSettle();

    expect(repo.removed, ['x1']);
  });
}
