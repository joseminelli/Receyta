import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/features/recipes/screens/cook_log_sheet.dart';
import 'package:receyta/theme/app_theme.dart';

class _FakeRepo implements CookLogRepository {
  final added = <({String recipeId, String? note, DateTime? cookedAt})>[];
  final removed = <String>[];

  @override
  Future<Result<String>> add(
    String recipeId, {
    DateTime? cookedAt,
    String? note,
  }) async {
    added.add((recipeId: recipeId, note: note, cookedAt: cookedAt));
    return Ok('log-${added.length}');
  }

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

Widget _host(
  Widget child, {
  List<CookLog> logs = const [],
  _FakeRepo? repo,
}) {
  return ProviderScope(
    overrides: [
      cookLogsProvider.overrideWith((ref, id) => Stream.value(logs)),
      if (repo != null) cookLogRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)),
  );
}

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CookLog _log(String id, DateTime at, {String? note}) =>
    CookLog(id: id, recipeId: 'r1', cookedAt: at, note: note);

void main() {
  group('CookedCard', () {
    testWidgets('sem histórico convida a registrar', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host(const CookedCard(recipeId: 'r1')));
      await tester.pumpAndSettle();

      expect(find.text('Nunca cozinhada'), findsOneWidget);
      expect(find.text('Toque pra registrar quando fizer'), findsOneWidget);
    });

    testWidgets('com histórico mostra quantas vezes e a última',
        (tester) async {
      _usePhoneSize(tester);
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          const CookedCard(recipeId: 'r1'),
          logs: [
            _log('2', now),
            _log('1', now.subtract(const Duration(days: 9))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cozinhada 2 vezes'), findsOneWidget);
      expect(find.text('Última vez: hoje'), findsOneWidget);
    });
  });

  group('folha do histórico', () {
    testWidgets('registrar manda a nota e limpa o campo', (tester) async {
      _usePhoneSize(tester);
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _host(const CookedCard(recipeId: 'r1'), repo: repo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nunca cozinhada'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'faltou sal');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(repo.added, hasLength(1));
      expect(repo.added.single.recipeId, 'r1');
      expect(repo.added.single.note, 'faltou sal');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
    });

    testWidgets('lista o histórico e apaga um registro', (tester) async {
      _usePhoneSize(tester);
      final repo = _FakeRepo();
      final now = DateTime.now();
      await tester.pumpWidget(
        _host(
          const CookedCard(recipeId: 'r1'),
          repo: repo,
          logs: [_log('a', now, note: 'ficou ótimo')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cozinhada 1 vez'));
      await tester.pumpAndSettle();

      expect(find.text('HISTÓRICO'), findsOneWidget);
      expect(find.text('ficou ótimo'), findsOneWidget);

      await tester.tap(find.byTooltip('Apagar registro'));
      await tester.pumpAndSettle();

      expect(repo.removed, ['a']);
    });
  });
}
