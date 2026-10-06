import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/recipe_import_service.dart';

void main() {
  test('link inválido nem chega a fazer requisição', () async {
    final service = RecipeImportService(
      client: MockClient((_) async => http.Response('', 404)),
    );
    final result = await service.importFromUrl('não é uma url');
    expect(result, isA<Err<Object?>>());
    expect((result as Err).failure, isA<ValidationFailure>());
  });

  test('extrai a receita de uma resposta 200 com JSON-LD', () async {
    final service = RecipeImportService(
      client: MockClient((request) async {
        return http.Response('''
<script type="application/ld+json">
{"@type": "Recipe", "name": "Sopa", "recipeIngredient": ["Água"]}
</script>
''', 200);
      }),
    );
    final result = await service.importFromUrl('https://exemplo.com/sopa');
    final recipe = (result as Ok).value;
    expect(recipe.name, 'Sopa');
    expect(recipe.sourceUrl, 'https://exemplo.com/sopa');
  });

  test('acentuação decodifica certo mesmo sem charset no Content-Type',
      () async {
    const bodyText = '''
<script type="application/ld+json">
{"@type": "Recipe", "name": "Técnica de sushi", "recipeIngredient": ["1/2 xícara de açúcar"]}
</script>
''';
    final service = RecipeImportService(
      client: MockClient(
        (_) async => http.Response.bytes(utf8.encode(bodyText), 200),
      ),
    );
    final result = await service.importFromUrl('https://exemplo.com/sushi');
    final recipe = (result as Ok).value;
    expect(recipe.name, 'Técnica de sushi');
    expect(recipe.ingredientLines, ['1/2 xícara de açúcar']);
  });

  test('status diferente de 200 vira NetworkFailure', () async {
    final service = RecipeImportService(
      client: MockClient((_) async => http.Response('erro', 500)),
    );
    final result = await service.importFromUrl('https://exemplo.com/x');
    expect((result as Err).failure, isA<NetworkFailure>());
  });

  test('página sem JSON-LD de receita vira ValidationFailure', () async {
    final service = RecipeImportService(
      client: MockClient((_) async => http.Response('<html></html>', 200)),
    );
    final result = await service.importFromUrl('https://exemplo.com/x');
    expect((result as Err).failure, isA<ValidationFailure>());
  });

  group('downloadImage', () {
    http.Response png(int status,
            {String type = 'image/jpeg', int size = 10}) =>
        http.Response.bytes(
          List.filled(size, 1),
          status,
          headers: {'content-type': type},
        );

    RecipeImportService with_(http.Response Function() reply) =>
        RecipeImportService(client: MockClient((_) async => reply()));

    test('devolve os bytes de uma imagem 200', () async {
      final bytes =
          await with_(() => png(200)).downloadImage('https://x.com/a.jpg');
      expect(bytes, hasLength(10));
    });

    test('status de erro, não-imagem e vazio viram null', () async {
      expect(await with_(() => png(404)).downloadImage('https://x.com/a.jpg'),
          isNull);
      expect(
        await with_(() => png(200, type: 'text/html'))
            .downloadImage('https://x.com/a.jpg'),
        isNull,
      );
      expect(
        await with_(() => png(200, size: 0))
            .downloadImage('https://x.com/a.jpg'),
        isNull,
      );
    });

    test('maior que 8 MB é recusada', () async {
      final big = png(200, size: 8 * 1024 * 1024 + 1);
      expect(
          await with_(() => big).downloadImage('https://x.com/a.jpg'), isNull);
    });

    test('erro de rede e endereço inválido viram null, sem lançar', () async {
      final failing = RecipeImportService(
        client: MockClient((_) async => throw Exception('sem rede')),
      );
      expect(await failing.downloadImage('https://x.com/a.jpg'), isNull);
      expect(await failing.downloadImage('não é url'), isNull);
    });
  });
}
