import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/pill_nav_bar.dart';

const _labels = ['Receitas', 'Agenda', 'Compras', 'Conta'];

class _Host extends StatefulWidget {
  const _Host({required this.picked});

  final List<int> picked;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: PillNavBar(
          currentIndex: _index,
          onSelected: (i) {
            widget.picked.add(i);
            setState(() => _index = i);
          },
          items: [
            for (final label in _labels)
              PillNavItem(
                icon: Icons.circle,
                label: label,
                color: colors.coral,
                motif: TileMotif.arco,
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late List<int> picked;
  late List<MethodCall> haptics;

  setUp(() {
    picked = [];
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: _Host(picked: picked)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('arrastar o dedo da esquerda pra direita passa por todas as abas',
      (tester) async {
    await pump(tester);
    final bar = tester.getRect(find.byType(PillNavBar));
    final y = bar.center.dy;

    final gesture = await tester.startGesture(Offset(bar.left + 30, y));
    for (var x = bar.left + 30; x < bar.right - 20; x += 12) {
      await gesture.moveTo(Offset(x, y));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(picked, [1, 2, 3]);
  });

  testWidgets('arrastar de volta pra esquerda desce as abas e para onde soltar',
      (tester) async {
    await pump(tester);
    final bar = tester.getRect(find.byType(PillNavBar));
    final y = bar.center.dy;

    final gesture = await tester.startGesture(Offset(bar.right - 30, y));
    for (var x = bar.right - 30; x > bar.left + 20; x -= 12) {
      await gesture.moveTo(Offset(x, y));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Volta um pouco e solta: fica na aba da zona onde o dedo parou.
    await gesture.moveTo(Offset(bar.left + bar.width * 0.4, y));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(picked.last, 1);
  });

  testWidgets('cada troca no arrasto vibra uma vez; ficar na mesma zona não',
      (tester) async {
    await pump(tester);
    final bar = tester.getRect(find.byType(PillNavBar));
    final y = bar.center.dy;

    final gesture = await tester.startGesture(Offset(bar.left + 20, y));
    await gesture.moveTo(Offset(bar.left + 25, y));
    await gesture.moveTo(Offset(bar.left + 30, y));
    await tester.pump(const Duration(milliseconds: 16));
    expect(haptics, isEmpty);

    await gesture.moveTo(Offset(bar.left + bar.width * 0.4, y));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(Offset(bar.left + bar.width * 0.42, y));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(picked, [1]);
    expect(haptics, hasLength(1));
  });

  testWidgets('arrastar além das pontas não passa do primeiro nem do último',
      (tester) async {
    await pump(tester);
    final bar = tester.getRect(find.byType(PillNavBar));
    final y = bar.center.dy;

    final gesture = await tester.startGesture(Offset(bar.left + 30, y));
    await gesture.moveTo(Offset(bar.right + 200, y));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(Offset(bar.left - 200, y));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(picked, everyElement(inInclusiveRange(0, 3)));
    expect(picked.last, 0);
  });

  testWidgets('tocar numa aba continua funcionando', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('Conta')).first);
    await tester.pumpAndSettle();

    expect(picked, [3]);
  });
}
