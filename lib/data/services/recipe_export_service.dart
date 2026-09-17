import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/daos/ingredient_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/recipe_export.dart';
import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

/// Exporta uma receita como arquivo `.receyta` e abre o share sheet do
/// sistema (D1, §7) — o caminho mais curto pra "você manda uma receita pelo
/// WhatsApp". O arquivo fica na pasta temporária do app; quem decide o
/// destino final (anexo do WhatsApp, "Salvar em Arquivos" etc.) é o próprio
/// share sheet.
class RecipeExportService {
  RecipeExportService(this._recipeRepository, this._ingredientDao);

  final RecipeRepository _recipeRepository;
  final IngredientDao _ingredientDao;

  /// Monta o payload de export (§7) resolvendo os nomes de ingrediente
  /// contra o catálogo — separado de [shareRecipe] pra ficar testável sem
  /// tocar em arquivo/share, que dependem de plugin nativo.
  Future<Result<Map<String, dynamic>>> buildPayload(String recipeId) async {
    final detailResult = await _recipeRepository.getDetail(recipeId);
    if (detailResult is Err<RecipeDetail>) return Err(detailResult.failure);
    final detail = (detailResult as Ok<RecipeDetail>).value;

    final ingredientIds = {
      for (final i in detail.ingredients)
        if (i.ingredientId != null) i.ingredientId!,
    }.toList();
    final rows = await _ingredientDao.findByIds(ingredientIds);
    final names = {for (final row in rows) row.id: row.displayName};

    return Ok(buildRecipeExportJson(detail, ingredientNames: names));
  }

  Future<Result<void>> shareRecipe(String recipeId) async {
    final payloadResult = await buildPayload(recipeId);
    if (payloadResult is Err<Map<String, dynamic>>) {
      return Err(payloadResult.failure);
    }
    final payload = (payloadResult as Ok<Map<String, dynamic>>).value;
    final recipeName =
        (payload['recipes'] as List)[0]['name'] as String? ?? 'receita';

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_fileName(recipeName)}');
      await file.writeAsString(jsonEncode(payload));
      await Share.shareXFiles([XFile(file.path)], text: recipeName);
      return const Ok(null);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao exportar a receita', cause: e));
    }
  }
}

/// `<nome-da-receita>.receyta`, achatado pra ser um nome de arquivo seguro em
/// qualquer SO — sem acento (reaproveita o mesmo mapa do parser/normalizador,
/// C1/C2) e sem nada além de letra/número/hífen.
String _fileName(String recipeName) {
  final slug = stripAccents(recipeName.trim().toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'receita' : slug}.receyta';
}

final recipeExportServiceProvider = Provider<RecipeExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return RecipeExportService(
    ref.watch(recipeRepositoryProvider),
    db.ingredientDao,
  );
});
