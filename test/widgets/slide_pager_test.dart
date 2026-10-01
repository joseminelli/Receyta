import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/widgets/slide_pager.dart';

class _Host extends StatefulWidget {
  const _Host({required this.changes});

  final List<int> changes;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 5;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () => setState(() => index++),
              child: const Text('próximo'),
            ),
            SizedBox(
              width: 300,
              height: 200,
              child: SlidePager(
                index: index,
                onChanged: (i) {
                  widget.changes.add(i);
                  setState(() => index = i);
                },
                builder: (i) => SizedBox(
                  width: 300,
                  height: 200,
                  child: Text('página $i'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('a página segue o dedo e a vizinha entra do lado',
      (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(changes: changes));
    final home = tester.getTopLeft(find.text('página 5')).dx;

    final gesture = await tester.startGesture(const Offset(150, 150));
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();

    expect(tester.getTopLeft(find.text('página 5')).dx, closeTo(home - 80, 2));
    expect(find.text('página 6'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('página 6')).dx,
      closeTo(home + 300 - 80, 2),
    );
    expect(find.text('página 4'), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(tester.getTopLeft(find.text('página 5')).dx, home);
    expect(find.text('página 6'), findsNothing);
  });

  testWidgets('arrasto longo passa de página sem animar de novo',
      (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(changes: changes));
    final home = tester.getTopLeft(find.text('página 5')).dx;

    final gesture = await tester.startGesture(const Offset(150, 150));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changes, [6]);
    expect(find.text('página 5'), findsNothing);
    expect(tester.getTopLeft(find.text('página 6')).dx, home);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('arrastar pra direita volta uma página', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(changes: changes));

    final gesture = await tester.startGesture(const Offset(150, 150));
    await gesture.moveBy(const Offset(130, 0));
    await tester.pump();
    expect(find.text('página 4'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changes, [4]);
    expect(find.text('página 4'), findsOneWidget);
  });

  testWidgets('botão ainda usa o deslize automático', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(changes: changes));
    final home = tester.getTopLeft(find.text('página 5')).dx;

    await tester.tap(find.text('próximo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('página 5'), findsOneWidget);
    expect(find.text('página 6'), findsOneWidget);
    expect(tester.getTopLeft(find.text('página 5')).dx, lessThan(home));
    expect(tester.getTopLeft(find.text('página 6')).dx, greaterThan(home));
    expect(changes, isEmpty);

    await tester.pumpAndSettle();
    expect(find.text('página 5'), findsNothing);
  });
}
