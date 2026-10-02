import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/header_scaffold.dart';

Widget _host(Widget page) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/page'),
            child: const Text('abrir'),
          ),
        ),
      ),
      GoRoute(path: '/page', builder: (_, __) => page),
    ],
  );
  return MaterialApp.router(theme: AppTheme.light(), routerConfig: router);
}

void main() {
  testWidgets('mostra título, subtítulo em maiúsculas, ação e o corpo',
      (tester) async {
    await tester.pumpWidget(
      _host(
        HeaderScaffold(
          title: 'Tags',
          subtitle: '5 tags',
          color: TileColor.coral,
          trailing: const Text('AÇÃO'),
          body: const Center(child: Text('CORPO')),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('5 TAGS'), findsOneWidget);
    expect(find.text('AÇÃO'), findsOneWidget);
    expect(find.text('CORPO'), findsOneWidget);
  });

  testWidgets('sem subtítulo nem ação, só o título', (tester) async {
    await tester.pumpWidget(
      _host(
        const HeaderScaffold(
          title: 'Lixeira',
          color: TileColor.ink,
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Lixeira'), findsOneWidget);
  });

  testWidgets('o botão de voltar fecha a tela', (tester) async {
    await tester.pumpWidget(
      _host(
        const HeaderScaffold(
          title: 'Pastas',
          color: TileColor.violet,
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);
  });
}
