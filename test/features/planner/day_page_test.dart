import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/day_export_service.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/planner_suggestion.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/planner/screens/day_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

MealPlanEntry _entry(
  String name,
  MealType meal, {
  bool done = false,
  String? recipeId,
}) =>
    MealPlanEntry(
      id: '$name-${meal.code}',
      recipe: Recipe(
        id: recipeId ?? name,
        name: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      date: today(),
      mealType: meal,
      done: done,
    );

class _FakeExport extends DayExportService {
  final shared = <({DateTime day, int meals})>[];

  @override
  Future<Result<void>> shareDay(
    DateTime day,
    List<MealPlanEntry> entries,
  ) async {
    shared.add((day: day, meals: entries.length));
    return const Ok(null);
  }
}

Widget _host(
  List<MealPlanEntry> entries, {
  DateTime? day,
  List<PlannerSuggestion> suggestions = const [],
  DayExportService? export,
}) =>
    ProviderScope(
      overrides: [
        if (export != null) dayExportServiceProvider.overrideWithValue(export),
        // Sem isto a tela cairia no banco de verdade.
        daySuggestionsProvider.overrideWith((ref, d) async => suggestions),
        dayEntriesProvider.overrideWith(
          (ref, d) => Stream.value(isSameDay(d, today()) ? entries : const []),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: DayPage(initialDay: day ?? today()),
      ),
    );

/// Tela de celular (390×844): o cabeçalho colorido ocupa bem mais que a
/// superfície padrão do teste (800×600) deixa sobrar pras refeições.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('mostra o dia com as quatro refeições e as receitas agendadas',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([
      _entry('Bolo de Fubá', MealType.breakfast),
      _entry('Sopa', MealType.dinner, done: true),
    ]));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(weekdayLong(today()).toUpperCase()),
      findsOneWidget,
    );
    expect(find.textContaining('HOJE'), findsOneWidget);
    expect(find.text('2 refeições'), findsOneWidget);
    expect(find.text('Bolo de Fubá'), findsOneWidget);
    expect(find.text('Sopa'), findsOneWidget);
    for (final m in MealType.values) {
      expect(find.text(m.label.toUpperCase()), findsOneWidget);
    }
    expect(find.text('Nada planejado'), findsNWidgets(2));
  });

  testWidgets('setas andam de dia em dia', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Próximo dia'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(weekdayLong(addDays(today(), 1)).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Bolo'), findsNothing);
    expect(find.text('Nada planejado'), findsNWidgets(4));

    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Bolo'), findsOneWidget);
  });

  testWidgets('nome sobre o azulejo; só um card por receita leva o Hero',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([
      _entry('Bolo de Fubá', MealType.lunch, recipeId: 'bolo'),
      _entry('Bolo de Fubá', MealType.dinner, recipeId: 'bolo'),
      _entry('Sopa', MealType.dinner),
    ]));
    await tester.pumpAndSettle();

    // 3 cards + o cabeçalho violeta.
    expect(find.byType(TilePattern), findsNWidgets(4));
    expect(find.byType(Hero), findsNWidgets(2));
    final tags = tester.widgetList<Hero>(find.byType(Hero)).map((h) => h.tag);
    expect(tags, {recipeTileHeroTag('bolo'), recipeTileHeroTag('Sopa')});
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrastar o dia com o dedo passa pro dia seguinte',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Nada planejado').first, const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(weekdayLong(addDays(today(), 1)).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Bolo'), findsNothing);
  });

  testWidgets('"Hoje" só liga fora de hoje e traz de volta', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    bool enabled() =>
        tester
            .widget<InkWell>(find.byKey(const ValueKey('stepper-today')))
            .onTap !=
        null;
    expect(enabled(), isFalse);

    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(enabled(), isTrue);

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    expect(enabled(), isFalse);
    expect(find.text('Bolo'), findsOneWidget);
  });

  testWidgets('arrastar pelo cabeçalho roxo também passa de dia',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    await tester.drag(
      find.textContaining(weekdayLong(today()).toUpperCase()),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(weekdayLong(addDays(today(), 1)).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Bolo'), findsNothing);

    await tester.drag(
      find.textContaining(weekdayLong(addDays(today(), 1)).toUpperCase()),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bolo'), findsOneWidget);
  });

  testWidgets('mostra as sugestões do dia com o motivo escrito',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(
      [_entry('Frango com gengibre', MealType.dinner)],
      suggestions: [
        PlannerSuggestion(
          recipe: Recipe(
            id: 'stroganoff',
            name: 'Strogonoff',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          score: 0.5,
          sharedIngredientNames: const ['Frango', 'Gengibre'],
        ),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('SUGESTÕES'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('SUGESTÕES'), findsOneWidget);
    expect(find.text('Strogonoff'), findsOneWidget);
    expect(
      find.text('usa frango e gengibre, que você já vai comprar'),
      findsOneWidget,
    );
    expect(find.byTooltip('Agendar Strogonoff'), findsOneWidget);
  });

  testWidgets('sem sugestões o bloco não aparece', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();
    expect(find.text('SUGESTÕES'), findsNothing);
  });

  testWidgets('o botão de compartilhar manda o dia com as refeições',
      (tester) async {
    _usePhoneSize(tester);
    final export = _FakeExport();
    await tester.pumpWidget(
      _host([
        _entry('Bolo', MealType.breakfast),
        _entry('Sopa', MealType.dinner),
      ], export: export),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Compartilhar o dia como imagem'));
    await tester.pumpAndSettle();

    expect(export.shared, hasLength(1));
    expect(export.shared.single.meals, 2);
    expect(isSameDay(export.shared.single.day, today()), isTrue);
  });

  testWidgets('sem refeições no dia, não há botão de compartilhar',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Compartilhar o dia como imagem'), findsNothing);
  });
}
