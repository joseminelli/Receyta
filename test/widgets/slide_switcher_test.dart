import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/widgets/slide_switcher.dart';

Widget _host(int index) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: SlideSwitcher(
              index: index,
              child: SizedBox(
                width: 300,
                height: 40,
                child: Text('item $index'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('avançar: o atual sai pra esquerda e o novo entra pela direita',
      (tester) async {
    await tester.pumpWidget(_host(1));
    final home = tester.getTopLeft(find.text('item 1')).dx;

    await tester.pumpWidget(_host(2));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(tester.getTopLeft(find.text('item 1')).dx, lessThan(home));
    expect(tester.getTopLeft(find.text('item 2')).dx, greaterThan(home));

    await tester.pumpAndSettle();
    expect(find.text('item 1'), findsNothing);
    expect(tester.getTopLeft(find.text('item 2')).dx, home);
  });

  testWidgets('voltar: o atual sai pra direita e o novo entra pela esquerda',
      (tester) async {
    await tester.pumpWidget(_host(5));
    final home = tester.getTopLeft(find.text('item 5')).dx;

    await tester.pumpWidget(_host(4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getTopLeft(find.text('item 5')).dx, greaterThan(home));
    expect(tester.getTopLeft(find.text('item 4')).dx, lessThan(home));

    await tester.pumpAndSettle();
    expect(find.text('item 5'), findsNothing);
  });

  testWidgets('mesmo índice só reconstrói o filho, sem animar', (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpWidget(_host(3));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('item 3'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
