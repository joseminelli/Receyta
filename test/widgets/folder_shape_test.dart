import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/folder_shape.dart';

void main() {
  group('FolderBorder', () {
    const rect = Rect.fromLTWH(0, 0, 200, 140);
    final path = const FolderBorder().getOuterPath(rect);

    test('a orelha ocupa só o canto superior esquerdo', () {
      expect(path.contains(const Offset(20, 4)), isTrue);
      expect(path.contains(const Offset(170, 4)), isFalse);
      expect(path.contains(const Offset(170, kFolderTabHeight + 4)), isTrue);
    });

    test('o corpo cobre o resto e os cantos são arredondados', () {
      expect(path.contains(const Offset(100, 70)), isTrue);
      expect(path.contains(const Offset(1, 139)), isFalse);
      expect(path.contains(const Offset(199, 139)), isFalse);
    });
  });

  testWidgets('FolderShapeCard mostra nome e contagem', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 148,
            height: 123,
            child: FolderShapeCard(
              folder: Folder(id: 'f', name: 'Massas'),
              recipes: 3,
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Massas'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('receitas'), findsOneWidget);
  });

  testWidgets('FolderShapeCard: 1 receita, só subpastas e vazia',
      (tester) async {
    Future<void> show(int recipes, int subfolders) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: SizedBox(
                width: 148,
                height: 123,
                child: FolderShapeCard(
                  folder: const Folder(id: 'f', name: 'Massas'),
                  recipes: recipes,
                  subfolders: subfolders,
                ),
              ),
            ),
          ),
        );

    await show(1, 0);
    expect(find.text('receita'), findsOneWidget);
    await show(0, 2);
    expect(find.text('pastas'), findsOneWidget);
    await show(0, 0);
    expect(find.text('Vazia'), findsOneWidget);
  });
}
