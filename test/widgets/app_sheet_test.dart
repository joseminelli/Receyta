import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_sheet.dart';

Widget _host(Widget Function(BuildContext) onOpen) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => onOpen(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('folha mostra título, subtítulo e as opções, e devolve a escolha',
      (tester) async {
    String? picked;
    await tester.pumpWidget(_host((context) {
      showModalBottomSheet<String>(
        context: context,
        builder: (sheet) => AppSheetFrame(
          title: 'Foto da receita',
          subtitle: 'Escolha de onde vem',
          child: AppSheetOptions(
            children: [
              AppSheetOption(
                icon: Icons.photo_camera_outlined,
                title: 'Tirar foto',
                subtitle: 'Abre a câmera',
                onTap: () => Navigator.of(sheet).pop('camera'),
              ),
              AppSheetOption(
                icon: Icons.hide_image_outlined,
                title: 'Remover foto',
                danger: true,
                onTap: () => Navigator.of(sheet).pop('remover'),
              ),
            ],
          ),
        ),
      ).then((v) => picked = v);
      return const SizedBox();
    }));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Foto da receita'), findsOneWidget);
    expect(find.text('Escolha de onde vem'), findsOneWidget);
    expect(find.text('Abre a câmera'), findsOneWidget);

    await tester.tap(find.text('Remover foto'));
    await tester.pumpAndSettle();

    expect(picked, 'remover');
    expect(find.text('Foto da receita'), findsNothing);
  });

  testWidgets('opção marcada mostra o check; as outras, a seta',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: AppSheetOptions(
          children: [
            AppSheetOption(
              icon: Icons.event_outlined,
              title: 'Domingo',
              selected: true,
              onTap: () {},
            ),
            AppSheetOption(
              icon: Icons.event_outlined,
              title: 'Segunda',
              onTap: () {},
            ),
          ],
        ),
      ),
    ));

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('o tema dá à folha o fundo paper e o canto arredondado',
      (tester) async {
    await tester.pumpWidget(_host((context) {
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => const AppSheetFrame(title: 'X', child: SizedBox()),
      );
      return const SizedBox();
    }));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final theme = AppTheme.light().bottomSheetTheme;
    expect(theme.surfaceTintColor, Colors.transparent);
    expect(theme.showDragHandle, isTrue);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, theme.backgroundColor);
  });
}
