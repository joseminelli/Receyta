import 'dart:io';
import 'dart:typed_data';

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

  Future<File> source(String name, [List<int> bytes = const [1, 2, 3]]) async {
    final f = File(p.join(root.path, name));
    await f.writeAsBytes(bytes);
    return f;
  }

  Future<List<String>> storedFiles() async => [
        for (final e in await (await service.directory()).list().toList())
          if (e is File) p.basename(e.path),
      ]..sort();

  final hashName = RegExp(r'^[0-9a-f]{40}\.jpg$');

  test('store dá à foto um nome derivado do conteúdo', () async {
    final name = await service.store(await source('a.jpg'));

    expect(name, matches(hashName));
    expect(await (await service.fileFor(name)).exists(), isTrue);
  });

  test('a mesma foto escolhida duas vezes é UM arquivo só', () async {
    final a = await service.store(await source('a.jpg', [9, 9, 9]));
    final b = await service.store(await source('copia.jpg', [9, 9, 9]));

    expect(a, b);
    expect(await storedFiles(), [a]);
  });

  test('fotos diferentes ganham arquivos diferentes', () async {
    final a = await service.store(await source('a.jpg', [1, 1]));
    final b = await service.store(await source('b.jpg', [2, 2]));

    expect(a, isNot(b));
    expect(await storedFiles(), hasLength(2));
  });

  test('não sobra arquivo temporário depois de guardar', () async {
    await service.store(await source('a.jpg'));
    await service.store(await source('a.jpg'));

    expect((await storedFiles()).where((n) => n.startsWith('.tmp')), isEmpty);
  });

  test('store falha quando a compressão não gera arquivo', () async {
    final failing = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (_, __, {required maxSide, required quality}) async => null,
    );

    expect(
      () => failing.store(File('x.jpg')),
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
        await File(dst).writeAsBytes(List.filled(bytes, 7));
        return File(dst);
      },
    );

    final name = await shrinking.store(await source('a.jpg'));

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

    final name = await stubborn.store(await source('a.jpg'));

    expect(await (await stubborn.fileFor(name)).exists(), isTrue);
    expect(calls, lessThan(30));
  });

  group('storeBytes', () {
    test('com nome válido e sem comprimir, mantém o nome', () async {
      final name = await service.storeBytes(
        Uint8List.fromList([4, 5, 6]),
        name: 'minha_foto-1.jpg',
        compress: false,
      );

      expect(name, 'minha_foto-1.jpg');
      expect(await (await service.fileFor(name)).readAsBytes(), [4, 5, 6]);
    });

    test('se o arquivo com esse nome já existe, não regrava', () async {
      await service.storeBytes(Uint8List.fromList([1]),
          name: 'x.jpg', compress: false);

      await service.storeBytes(Uint8List.fromList([2]),
          name: 'x.jpg', compress: false);

      expect(await (await service.fileFor('x.jpg')).readAsBytes(), [1]);
    });

    test('nome inseguro (caminho, extensão errada) é ignorado: vira hash',
        () async {
      for (final bad in ['../fora.jpg', 'a/b.jpg', r'a\b.jpg', 'x.png', '']) {
        final name = await service.storeBytes(
          Uint8List.fromList([7, 7]),
          name: bad,
          compress: false,
        );

        expect(name, matches(hashName), reason: bad);
      }
      expect(await File(p.join(root.path, 'fora.jpg')).exists(), isFalse);
    });

    test('sem nome e sem comprimir, também vira hash e dedupa', () async {
      final a =
          await service.storeBytes(Uint8List.fromList([3, 3]), compress: false);
      final b =
          await service.storeBytes(Uint8List.fromList([3, 3]), compress: false);

      expect(a, matches(hashName));
      expect(a, b);
    });

    test('comprimindo, a foto passa pela compressão e é nomeada pelo hash',
        () async {
      final name = await service.storeBytes(Uint8List.fromList([8, 8, 8]));

      expect(name, matches(hashName));
    });
  });

  test('isValidRecipeImageName aceita nomes antigos e hash, recusa o resto',
      () {
    expect(isValidRecipeImageName('3f2a_1759000000000.jpg'), isTrue);
    expect(
      isValidRecipeImageName('b3a1c1d2-0000-4000-8000-123456789abc_17.jpg'),
      isTrue,
    );
    expect(isValidRecipeImageName('nova_17.jpg'), isTrue);
    expect(isValidRecipeImageName('../x.jpg'), isFalse);
    expect(isValidRecipeImageName('x.jpeg'), isFalse);
    expect(isValidRecipeImageName(null), isFalse);
    expect(isValidRecipeImageName('a' * 90 + '.jpg'), isFalse);
  });

  test('delete apaga o arquivo e aceita nulo ou nome inexistente', () async {
    final name = await service.store(await source('a.jpg'));

    await service.delete(name);
    await service.delete(null);
    await service.delete('nao_existe.jpg');

    expect(await (await service.fileFor(name)).exists(), isFalse);
  });

  test('deleteIfUnused só apaga quando ninguém usa', () async {
    final name = await service.store(await source('a.jpg'));

    await service.deleteIfUnused(name, (_) async => true);
    expect(await (await service.fileFor(name)).exists(), isTrue);

    await service.deleteIfUnused(name, (_) async => false);
    expect(await (await service.fileFor(name)).exists(), isFalse);

    await service.deleteIfUnused(null, (_) async => false);
  });

  test('deleteOrphans apaga só o que nenhuma receita referencia', () async {
    final keep = await service.store(await source('a.jpg', [1]));
    final drop = await service.store(await source('b.jpg', [2]));

    final removed = await service.deleteOrphans({keep});

    expect(removed, 1);
    expect(await (await service.fileFor(keep)).exists(), isTrue);
    expect(await (await service.fileFor(drop)).exists(), isFalse);
  });
}
