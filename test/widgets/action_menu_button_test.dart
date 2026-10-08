import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/action_menu_button.dart';

void main() {
  Widget host(Alignment alignment) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ActionMenuButton(
                items: [
                  ActionMenuItem(
                    icon: Icons.edit,
                    label: 'Primeira',
                    onTap: () {},
                  ),
                  ActionMenuItem(
                    icon: Icons.call_merge,
                    label: 'Segunda',
                    onTap: () {},
                  ),
                  ActionMenuItem(
                    icon: Icons.delete_outline,
                    label: 'Terceira',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('no alto da tela o cartão abre embaixo do botão', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host(Alignment.topRight));
    final button = tester.getRect(find.byTooltip('Mais ações').first);

    await tester.tap(find.byType(ActionMenuButton));
    await tester.pumpAndSettle();

    final first = tester.getRect(find.text('Primeira'));
    expect(first.top, greaterThan(button.bottom));
  });

  testWidgets('no fim da tela o cartão abre em cima e não sai da tela',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host(Alignment.bottomRight));
    final button = tester.getRect(find.byType(ActionMenuButton));

    await tester.tap(find.byType(ActionMenuButton));
    await tester.pumpAndSettle();

    final first = tester.getRect(find.text('Primeira'));
    final last = tester.getRect(find.text('Terceira'));
    expect(last.bottom, lessThanOrEqualTo(button.top));
    expect(first.top, greaterThanOrEqualTo(0));
    expect(last.bottom, lessThanOrEqualTo(700));
  });

  testWidgets('escolher uma opção ainda chama a ação', (tester) async {
    usePhone(tester);
    var picked = '';
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomRight,
          child: ActionMenuButton(
            items: [
              ActionMenuItem(
                icon: Icons.edit,
                label: 'Editar',
                onTap: () => picked = 'editar',
              ),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(ActionMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(picked, 'editar');
  });
}
