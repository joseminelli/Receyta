import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/data/services/recipe_image_service.dart';

void main() {
  late Directory root;
  late RecipeImageService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('recipe_images_test');
    service = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (src, dst, {required maxSide, required quality}) =>
          File(src).copy(dst),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<File> source(String name) async {
    final f = File(p.join(root.path, name));
    await f.writeAsBytes([1, 2, 3]);
    return f;
  }

  test('store guarda na pasta e devolve só o nome do arquivo', () async {
    final name = await service.store(await source('a.jpg'), recipeId: 'r1');

    expect(name, startsWith('r1_'));
    expect(name, endsWith('.jpg'));
    expect(p.basename(name), name);
    expect(await (await service.fileFor(name)).exists(), isTrue);
  });

  test('duas fotos da mesma receita ganham nomes diferentes', () async {
    final a = await service.store(await source('a.jpg'), recipeId: 'r1');
    await Future<void>.delayed(const Duration(milliseconds: 3));
    final b = await service.store(await source('b.jpg'), recipeId: 'r1');

    expect(a, isNot(b));
  });

  test('store falha quando a compressão não gera arquivo', () async {
    final failing = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (_, __, {required maxSide, required quality}) async => null,
    );

    expect(
      () => failing.store(File('x.jpg'), recipeId: 'r1'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('foto acima do teto é recomprimida até caber', () async {
    final calls = <({int side, int quality})>[];
    final shrinking = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (src, dst, {required maxSide, required quality}) async {
        calls.add((side: maxSide, quality: quality));
        final bytes = quality > 60 ? kRecipeImageMaxBytes + 1 : 1000;
        return File(dst)
            .writeAsBytes(List.filled(bytes, 7))
            .then((_) => File(dst));
      },
    );

    final name = await shrinking.store(await source('a.jpg'), recipeId: 'r1');

    expect(calls.length, greaterThan(1));
    expect(calls.first.quality, kRecipeImageQuality);
    expect(calls.last.quality, lessThanOrEqualTo(60));
    expect(
      await (await shrinking.fileFor(name)).length(),
      lessThanOrEqualTo(kRecipeImageMaxBytes),
    );
  });

  test('se nem no piso couber, para e guarda o que tem (sem loop infinito)',
      () async {
    var calls = 0;
    final stubborn = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (src, dst, {required maxSide, required quality}) async {
        calls++;
        await File(dst).writeAsBytes(List.filled(kRecipeImageMaxBytes + 1, 7));
        return File(dst);
      },
    );

    final name = await stubborn.store(await source('a.jpg'), recipeId: 'r1');

    expect(await (await stubborn.fileFor(name)).exists(), isTrue);
    expect(calls, lessThan(30));
  });

  test('delete apaga o arquivo e aceita nulo ou nome inexistente', () async {
    final name = await service.store(await source('a.jpg'), recipeId: 'r1');

    await service.delete(name);
    await service.delete(null);
    await service.delete('nao_existe.jpg');

    expect(await (await service.fileFor(name)).exists(), isFalse);
  });

  test('deleteOrphans apaga só o que nenhuma receita usa', () async {
    final keep = await service.store(await source('a.jpg'), recipeId: 'r1');
    await Future<void>.delayed(const Duration(milliseconds: 3));
    final drop = await service.store(await source('b.jpg'), recipeId: 'r2');

    final removed = await service.deleteOrphans({keep});

    expect(removed, 1);
    expect(await (await service.fileFor(keep)).exists(), isTrue);
    expect(await (await service.fileFor(drop)).exists(), isFalse);
  });
}
