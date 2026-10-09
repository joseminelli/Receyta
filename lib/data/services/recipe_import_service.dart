import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:receyta/core/result.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

/// Busca uma URL e extrai a receita via JSON-LD (C7). Timeout curto e
/// User-Agent de navegador — vários sites de receita bloqueiam requisições
/// sem um UA reconhecível.
class RecipeImportService {
  RecipeImportService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<Result<ImportedRecipe>> importFromUrl(String rawUrl) async {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const Err(ValidationFailure('Esse link não parece válido.'));
    }

    try {
      final response = await _client
          .get(uri, headers: _pageHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return Err(NetworkFailure(
          'O site respondeu com erro (${response.statusCode}).',
        ));
      }

      final html = _decodeHtml(response.bodyBytes);
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

  /// Baixa a foto da receita. `null` em qualquer problema (rede, status,
  /// não é imagem, grande demais) — a foto é um extra, nunca impede o
  /// import. Limite de 8 MB: depois a compressão deixa em ~400 KB.
  Future<Uint8List?> downloadImage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    try {
      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (compatible; ReceytaApp/1.0; +https://receyta.app)',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final type = response.headers['content-type'] ?? '';
      if (!type.startsWith('image/')) return null;
      final bytes = response.bodyBytes;
      if (bytes.isEmpty || bytes.length > _maxImageBytes) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

const _maxImageBytes = 8 * 1024 * 1024;

/// Cabeçalhos de navegador de verdade: sites atrás de Cloudflare e afins
/// recusam User-Agent que se anuncia como robô.
const _pageHeaders = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
};

/// UTF-8 estrito primeiro; se a página não for UTF-8 de verdade (sites
/// antigos em ISO-8859-1), cai pra `latin1` em vez de trocar os acentos por
/// lixo. `response.body` não serve: sem charset declarado ele assume latin1
/// mesmo em página UTF-8.
String _decodeHtml(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

final recipeImportServiceProvider =
    Provider<RecipeImportService>((ref) => RecipeImportService());
