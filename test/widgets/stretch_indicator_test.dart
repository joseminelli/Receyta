import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/stretch_indicator.dart';
import 'package:receyta/widgets/underline_tabs.dart';
import 'package:receyta/widgets/period_strip.dart';

void main() {
  group('stretchRect', () {
    const a = Rect.fromLTWH(0, 0, 100, 40);
    const b = Rect.fromLTWH(200, 0, 100, 40);

    test('começa e termina nas opções', () {
      expect(stretchRect(a, b, 0), a);
      expect(stretchRect(a, b, 1), b);
    });

    test('indo pra direita estica: a frente chega antes da traseira sair', () {
      final mid = stretchRect(a, b, 0.35);
      // A borda esquerda ainda perto da origem, a direita já bem adiante.
      expect(mid.left, lessThan(60));
      expect(mid.right, greaterThan(180));
      // Mais larga que a opção: está esticado.
      expect(mid.width, greaterThan(a.width));
    });

    test('indo pra esquerda a frente é a borda esquerda', () {
      final mid = stretchRect(b, a, 0.35);
      expect(mid.right, greaterThan(240));
      expect(mid.left, lessThan(120));
      expect(mid.width, greaterThan(b.width));
    });

    test('volta ao tamanho original no fim', () {
      expect(stretchRect(a, b, 1).width, a.width);
      expect(stretchRect(a, b, 0.99).width, closeTo(a.width, 5));
    });
  });

  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
      );

  testWidgets('SlidingSegmented estica no meio e assenta no destino',
      (tester) async {
    var selected = 0;
    late StateSetter set;
    await tester.pumpWidget(host(StatefulBuilder(builder: (context, setState) {
      set = setState;
      return SlidingSegmented(
        labels: const ['Semana', 'Mês'],
        selected: selected,
        onChanged: (_) {},
      );
    })));
    final indicator = find.descendant(
      of: find.byType(StretchIndicator),
      matching: find.byType(DecoratedBox),
    );
    final start = tester.getRect(indicator.first);

    set(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = tester.getRect(indicator.first);
    expect(mid.width, greaterThan(start.width), reason: 'está esticado');

    await tester.pumpAndSettle();
    final end = tester.getRect(indicator.first);
    expect(end.width, closeTo(start.width, 0.5));
    expect(end.left, greaterThan(start.left + 100));
  });

  testWidgets('UnderlineTabs usa o mesmo efeito', (tester) async {
    var selected = 0;
    late StateSetter set;
    await tester.pumpWidget(host(StatefulBuilder(builder: (context, setState) {
      set = setState;
      return UnderlineTabs(
        tabs: const [
          UnderlineTab(label: 'A', icon: Icons.add),
          UnderlineTab(label: 'B', icon: Icons.remove),
        ],
        selected: selected,
        onChanged: (_) {},
      );
    })));
    final bar = find.descendant(
      of: find.byType(StretchIndicator),
      matching: find.byType(DecoratedBox),
    );
    final start = tester.getRect(bar.first);

    set(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getRect(bar.first).width, greaterThan(start.width));

    await tester.pumpAndSettle();
    expect(tester.getRect(bar.first).width, closeTo(start.width, 0.5));
  });
}
