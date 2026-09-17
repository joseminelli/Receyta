import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tag_name.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/folder_dao.dart';
import 'package:receyta/data/database/daos/ingredient_dao.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/daos/tag_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/engine/receyta_file_import.dart';

/// Quantas pastas/receitas entraram — o que a UI mostra depois de importar.
typedef ImportSummary = ({int recipes, int folders});

/// Lê um `.receyta` escolhido pelo usuário (D3, §7/RF-06.3) e reconcilia
/// contra a base local: ingrediente entra pelo mesmo `getOrCreate` do
/// C1/C2 (nunca por id — o catálogo de origem não tem por que bater com o
/// daqui), tag pelo mesmo `ensureTags`. Sempre cria linhas NOVAS (pasta,
/// receita, vínculo); detectar duplicata de uma reimportação e deixar
/// escolher substituir/duplicar/pular é o D4, ainda não existe.
class ReceytaImportService {
  ReceytaImportService(
    this._recipeDao,
    this._folderDao,
    this._ingredientDao,
    this._tagDao, {
    Uuid uuid = const Uuid(),
    DateTime Function() clock = DateTime.now,
  })  : _uuid = uuid,
        _clock = clock;

  final RecipeDao _recipeDao;
  final FolderDao _folderDao;
  final IngredientDao _ingredientDao;
  final TagDao _tagDao;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Abre o seletor de arquivo do sistema. `null` significa que o usuário
  /// cancelou a escolha — não é erro, não mostra mensagem nenhuma.
  ///
  /// Sem filtro de extensão de propósito: `.receyta` não é uma extensão
  /// registrada no `MimeTypeMap` do Android, e `FileType.custom` +
  /// `allowedExtensions` falha a validação do PRÓPRIO plugin antes de sequer
  /// abrir o seletor quando nenhuma extensão pedida resolve pra um mimetype
  /// conhecido — o erro nem chegava a aparecer (ninguém dava `await`/`catch`
  /// nesse ponto da cadeia). `FileType.any` sempre funciona; quem valida que
  /// o arquivo escolhido é um `.receyta` de verdade é o `parseReceytaFile`
  /// logo depois.
  Future<Result<ImportSummary>?> importFromPickedFile() async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(type: FileType.any);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao abrir o seletor de arquivo', cause: e));
    }
    final path = picked?.files.single.path;
    if (path == null) return null;
    return importFromFilePath(path);
  }

  /// Lê e importa um `.receyta` já em disco — usado tanto pelo seletor
  /// manual quanto pelo `.receyta` recebido de outro app (D5), cujo caminho
  /// o `receive_sharing_intent` já resolveu (copia o `content://` pra um
  /// arquivo de verdade antes de entregar pro Dart).
  Future<Result<ImportSummary>> importFromFilePath(String path) async {
    final String source;
    try {
      source = await File(path).readAsString();
    } catch (e) {
      return Err(ProcessingFailure('Falha ao ler o arquivo', cause: e));
    }

    final parsed = parseReceytaFile(source);
    if (parsed == null) {
      return const Err(
        ValidationFailure('Esse arquivo não é um .receyta válido.'),
      );
    }
    return importParsedFile(parsed);
  }

  /// A reconciliação em si, separada de [importFromPickedFile] pra ficar
  /// testável sem tocar no seletor de arquivo nativo.
  Future<Result<ImportSummary>> importParsedFile(
    ParsedReceytaFile file,
  ) async {
    if (file.recipes.isEmpty) {
      return const Err(
        ValidationFailure('Esse arquivo não tem nenhuma receita.'),
      );
    }
    try {
      return Ok(await _import(file));
    } catch (e) {
      return Err(DatabaseFailure('Falha ao importar', cause: e));
    }
  }

  Future<ImportSummary> _import(ParsedReceytaFile file) async {
    final folderIds = await _importFolders(file.folders);
    for (final recipe in file.recipes) {
      await _importRecipe(recipe, folderIds);
    }
    return (recipes: file.recipes.length, folders: folderIds.length);
  }

  /// Duas passadas: cria toda pasta na raiz primeiro (id novo, sem
  /// hierarquia) pra só depois resolver `parentId` com o mapa completo em
  /// mãos — a ordem das pastas no arquivo não garante pai antes de filho (o
  /// export lista em ordem alfabética, não hierárquica).
  Future<Map<String, String>> _importFolders(
    List<ParsedFolderImport> folders,
  ) async {
    final realIds = <String, String>{};
    for (final f in folders) {
      final row = await _folderDao.create(name: f.name);
      realIds[f.sourceId] = row.id;
    }
    final now = _clock().toUtc();
    for (final f in folders) {
      final realParentId =
          f.parentSourceId == null ? null : realIds[f.parentSourceId];
      if (realParentId == null) continue;
      await _folderDao.move(realIds[f.sourceId]!, realParentId, now);
    }
    return realIds;
  }

  Future<void> _importRecipe(
    ParsedRecipeImport recipe,
    Map<String, String> folderIds,
  ) async {
    final now = _clock().toUtc();
    final recipeId = _uuid.v4();

    final ingredients = <RecipeIngredientRow>[];
    for (final i in recipe.ingredients) {
      final ingredientRow = await _ingredientDao.getOrCreate(i.name);
      ingredients.add(RecipeIngredientRow(
        id: _uuid.v4(),
        recipeId: recipeId,
        rawText: i.rawText,
        groupLabel: i.groupLabel,
        position: i.position,
        ingredientId: ingredientRow.id,
        quantity: i.quantity,
        unitId: i.unit,
        qualifier: i.qualifier,
      ));
    }

    final steps = [
      for (final s in recipe.steps)
        RecipeStepRow(
          id: _uuid.v4(),
          recipeId: recipeId,
          instruction: s.text,
          groupLabel: s.groupLabel,
          position: s.position,
        ),
    ];

    final seen = <String>{};
    final canonicalTags = recipe.tags
        .map(canonicalTagName)
        .where((n) => n.isNotEmpty && seen.add(n))
        .toList();
    final tagRows = await _tagDao.ensureTags(canonicalTags);

    final folderId =
        recipe.folderSourceId == null ? null : folderIds[recipe.folderSourceId];

    await _recipeDao.saveWithChildren(
      recipe: RecipeRow(
        id: recipeId,
        folderId: folderId,
        name: recipe.name,
        about: recipe.about,
        prepMinutes: recipe.prepMinutes,
        cookMinutes: recipe.cookMinutes,
        servings: recipe.servings,
        imagePath: null,
        sourceUrl: recipe.sourceUrl,
        notes: recipe.notes,
        tileColor: null,
        tileMotif: null,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        lastOpenedAt: now,
      ),
      ingredients: ingredients,
      steps: steps,
      tagIds: [for (final t in tagRows) t.id],
    );
  }
}

final receytaImportServiceProvider = Provider<ReceytaImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReceytaImportService(
    db.recipeDao,
    db.folderDao,
    db.ingredientDao,
    db.tagDao,
  );
});
