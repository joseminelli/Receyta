import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/daos/ingredient_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/recipe_export.dart';
import 'package:receyta/domain/engine/recipe_pdf.dart';
import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

/// Exporta receitas como arquivo `.receyta` e abre o share sheet do sistema
/// (§7, bloco D) — o caminho mais curto pra "você manda uma receita pelo
/// WhatsApp" (D1) ou "faz um backup manual antes de trocar de celular" (D2).
/// O arquivo fica na pasta temporária do app; quem decide o destino final
/// (anexo do WhatsApp, "Salvar em Arquivos" etc.) é o próprio share sheet.
class RecipeExportService {
  RecipeExportService(
    this._recipeRepository,
    this._folderRepository,
    this._ingredientDao,
  );

  final RecipeRepository _recipeRepository;
  final FolderRepository _folderRepository;
  final IngredientDao _ingredientDao;

  /// Monta o payload de export de uma receita (D1, §7) resolvendo os nomes
  /// de ingrediente contra o catálogo — separado de [shareRecipe] pra ficar
  /// testável sem tocar em arquivo/share, que dependem de plugin nativo.
  Future<Result<Map<String, dynamic>>> buildPayload(String recipeId) async {
    final detailResult = await _recipeRepository.getDetail(recipeId);
    if (detailResult is Err<RecipeDetail>) return Err(detailResult.failure);
    final detail = (detailResult as Ok<RecipeDetail>).value;

    final names = await _namesFor([detail]);
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

    return _writeAndShare(payload, fileName: _fileName(recipeName), text: recipeName);
  }

  /// PDF de uma receita (D6, RF-06.6) — layout próprio via `buildRecipePdf`,
  /// não uma captura de tela do app; `Printing.sharePdf` abre o mesmo share
  /// sheet do sistema (imprimir aparece como opção nele, quando suportado).
  Future<Result<void>> sharePdf(String recipeId) async {
    final detailResult = await _recipeRepository.getDetail(recipeId);
    if (detailResult is Err<RecipeDetail>) return Err(detailResult.failure);
    final detail = (detailResult as Ok<RecipeDetail>).value;

    try {
      final bytes = await buildRecipePdf(detail);
      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName(detail.recipe.name),
      );
      return const Ok(null);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao gerar o PDF', cause: e));
    }
  }

  /// Monta o payload do backup completo (D2, §7): todas as pastas e receitas
  /// ativas (a lixeira não entra), com as listas de cada receita já
  /// resolvidas. Separado de [shareFullBackup] pelo mesmo motivo do
  /// [buildPayload].
  Future<Result<Map<String, dynamic>>> buildFullBackupPayload() async {
    final folders = await _folderRepository.watchAll().first;
    final recipes = await _recipeRepository.watchAll().first;

    final details = <RecipeDetail>[];
    for (final recipe in recipes) {
      final detailResult = await _recipeRepository.getDetail(recipe.id);
      if (detailResult is Err<RecipeDetail>) return Err(detailResult.failure);
      details.add((detailResult as Ok<RecipeDetail>).value);
    }

    final names = await _namesFor(details);
    return Ok(buildFullExportJson(
      folders: folders,
      recipes: details,
      ingredientNames: names,
    ));
  }

  Future<Result<void>> shareFullBackup() async {
    final payloadResult = await buildFullBackupPayload();
    if (payloadResult is Err<Map<String, dynamic>>) {
      return Err(payloadResult.failure);
    }
    final payload = (payloadResult as Ok<Map<String, dynamic>>).value;

    return _writeAndShare(
      payload,
      fileName: _backupFileName(),
      text: 'Backup do Receyta',
    );
  }

  Future<Map<String, String>> _namesFor(List<RecipeDetail> details) async {
    final ingredientIds = {
      for (final d in details)
        for (final i in d.ingredients)
          if (i.ingredientId != null) i.ingredientId!,
    }.toList();
    final rows = await _ingredientDao.findByIds(ingredientIds);
    return {for (final row in rows) row.id: row.displayName};
  }

  Future<Result<void>> _writeAndShare(
    Map<String, dynamic> payload, {
    required String fileName,
    required String text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonEncode(payload));
      await Share.shareXFiles([XFile(file.path)], text: text);
      return const Ok(null);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao exportar a receita', cause: e));
    }
  }
}

/// Slug seguro em qualquer SO — sem acento (reaproveita o mesmo mapa do
/// parser/normalizador, C1/C2) e sem nada além de letra/número/hífen.
String _slug(String recipeName) {
  final slug = stripAccents(recipeName.trim().toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'receita' : slug;
}

String _fileName(String recipeName) => '${_slug(recipeName)}.receyta';

String _pdfFileName(String recipeName) => '${_slug(recipeName)}.pdf';

/// `receyta-backup-<data>.receyta` — a data ajuda quem faz mais de um backup
/// manual a distinguir os arquivos sem precisar abrir cada um.
String _backupFileName({DateTime Function() clock = DateTime.now}) {
  final now = clock().toUtc();
  String pad(int n) => n.toString().padLeft(2, '0');
  return 'receyta-backup-${now.year}${pad(now.month)}${pad(now.day)}.receyta';
}

final recipeExportServiceProvider = Provider<RecipeExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return RecipeExportService(
    ref.watch(recipeRepositoryProvider),
    ref.watch(folderRepositoryProvider),
    db.ingredientDao,
  );
});
