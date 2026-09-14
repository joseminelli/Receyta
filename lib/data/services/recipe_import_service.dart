import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:receyta/core/result.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

/// Busca uma URL e extrai a receita via JSON-LD (C7). Timeout curto e
/// User-Agent de navegador — vários sites de receita bloqueiam requisições
/// sem um UA reconhecível.
class RecipeImportService {
  RecipeImportService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Result<ImportedRecipe>> importFromUrl(String rawUrl) async {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const Err(ValidationFailure('Esse link não parece válido.'));
    }

    try {
      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (compatible; ReceytaApp/1.0; +https://receyta.app)',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return Err(NetworkFailure(
          'O site respondeu com erro (${response.statusCode}).',
        ));
      }

      // `response.body` usa o charset do `Content-Type`; quando o site não
      // declara um (comum), cai pro padrão antigo `latin1` mesmo a página
      // sendo UTF-8 de verdade — decodifica sempre como UTF-8 explicitamente.
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final recipe = extractRecipeFromHtml(html, sourceUrl: url);
      if (recipe == null) {
        return const Err(ValidationFailure(
          'Não encontrei os dados da receita nessa página.',
        ));
      }
      return Ok(recipe);
    } on TimeoutException {
      return const Err(NetworkFailure('O site demorou demais para responder.'));
    } catch (e) {
      return Err(NetworkFailure('Falha ao acessar o link', cause: e));
    }
  }
}

final recipeImportServiceProvider =
    Provider<RecipeImportService>((ref) => RecipeImportService());
