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
/// `skipped` só conta receitas em conflito que o usuário mandou pular (D4).
typedef ImportSummary = ({int recipes, int folders, int skipped});

/// O que fazer com uma receita cujo `id` de origem já existe localmente
/// (D4, RF-06.3) — decidido pelo usuário na tela de conflitos, nunca
/// escolhido sozinho pelo serviço.
enum ConflictResolution {
  /// Sobrescreve a receita existente (mesmo id) com o conteúdo do arquivo.
  replace,

  /// Cria uma receita nova, com id novo — a existente fica intocada.
  duplicate,

  /// Não faz nada com essa receita.
  skip,
}

/// Lê um `.receyta` e reconcilia contra a base local: ingrediente entra
/// pelo mesmo `getOrCreate` do C1/C2 (nunca por id — o catálogo de origem
/// não tem por que bater com o daqui), tag pelo mesmo `ensureTags`, pasta
/// pelo par nome+pai (D4). Receita reaproveita o `id` do arquivo de
/// origem quando não bate com nada local — é isso que permite detectar
/// conflito numa reimportação e não é escolha alocada em outro lugar: sem
/// conflito, a receita simplesmente nasce com aquele id.
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

  /// Abre o seletor de arquivo do sistema e já lê+parseia o conteúdo. `null`
  /// significa que o usuário cancelou a escolha — não é erro, não mostra
  /// mensagem nenhuma. Não importa nada ainda — quem chama decide (via
  /// [findConflicts] + [importParsedFile]) depois de ver se há conflito.
  ///
  /// Sem filtro de extensão de propósito: `.receyta` não é uma extensão
  /// registrada no `MimeTypeMap` do Android, e `FileType.custom` +
  /// `allowedExtensions` falha a validação do PRÓPRIO plugin antes de sequer
  /// abrir o seletor quando nenhuma extensão pedida resolve pra um mimetype
  /// conhecido — o erro nem chegava a aparecer (ninguém dava `await`/`catch`
  /// nesse ponto da cadeia). `FileType.any` sempre funciona; quem valida que
  /// o arquivo escolhido é um `.receyta` de verdade é o `parseReceytaFile`
  /// logo depois.
  Future<Result<ParsedReceytaFile>?> pickAndParseFile() async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(type: FileType.any);
    } catch (e) {
      return Err(
        ProcessingFailure('Falha ao abrir o seletor de arquivo', cause: e),
      );
    }
    final path = picked?.files.single.path;
    if (path == null) return null;
    return parseFileAtPath(path);
  }

  /// Lê e parseia um `.receyta` já em disco — usado tanto pelo seletor
  /// manual quanto pelo `.receyta` recebido de outro app (D5), cujo caminho
  /// o `receive_sharing_intent` já resolveu (copia o `content://` pra um
  /// arquivo de verdade antes de entregar pro Dart).
  Future<Result<ParsedReceytaFile>> parseFileAtPath(String path) async {
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
    if (parsed.recipes.isEmpty) {
      return const Err(
        ValidationFailure('Esse arquivo não tem nenhuma receita.'),
      );
    }
    return Ok(parsed);
  }

  /// Nomes das receitas do arquivo que já existem localmente (mesmo `id` de
  /// origem) — a UI só precisa perguntar o que fazer quando essa lista não
  /// vem vazia (D4). Leitura pura, não escreve nada.
  Future<List<String>> findConflicts(ParsedReceytaFile file) async {
    final names = <String>[];
    for (final recipe in file.recipes) {
      final sourceId = recipe.sourceId;
      if (sourceId == null) continue;
      if (await _recipeDao.findById(sourceId) != null) {
        names.add(recipe.name);
      }
    }
    return names;
  }

  /// A reconciliação em si, separada do seletor/parser pra ficar testável
  /// sem tocar em plugin nativo. [resolution] vale pra TODAS as receitas em
  /// conflito deste import — a tela de conflitos (D4) pergunta uma vez só
  /// pro lote inteiro, não receita por receita.
  Future<Result<ImportSummary>> importParsedFile(
    ParsedReceytaFile file, {
    ConflictResolution resolution = ConflictResolution.duplicate,
  }) async {
    try {
      return Ok(await _import(file, resolution));
    } catch (e) {
      return Err(DatabaseFailure('Falha ao importar', cause: e));
    }
  }

  Future<ImportSummary> _import(
    ParsedReceytaFile file,
    ConflictResolution resolution,
  ) async {
    final folderIds = await _importFolders(file.folders);
    var imported = 0;
    var skipped = 0;
    for (final recipe in file.recipes) {
      if (await _importRecipe(recipe, folderIds, resolution)) {
        imported++;
      } else {
        skipped++;
      }
    }
    return (recipes: imported, folders: folderIds.length, skipped: skipped);
  }

  /// Resolve cada pasta recursivamente (pai antes de filho, não importa a
  /// ordem no arquivo — o export lista por nome, não por hierarquia) e
  /// reconcilia pelo par nome+pai já resolvido (D4): reimportar o mesmo
  /// backup reaproveita a pasta existente em vez de duplicar a árvore
  /// inteira a cada vez.
  Future<Map<String, String>> _importFolders(
    List<ParsedFolderImport> folders,
  ) async {
    final bySourceId = {for (final f in folders) f.sourceId: f};
    final realIds = <String, String>{};

    Future<String> resolve(String sourceId) async {
      final cached = realIds[sourceId];
      if (cached != null) return cached;

      final folder = bySourceId[sourceId]!;
      final parentSourceId = folder.parentSourceId;
      final parentId = (parentSourceId != null &&
              bySourceId.containsKey(parentSourceId))
          ? await resolve(parentSourceId)
          : null;

      final existing =
          await _folderDao.findByNameAndParent(folder.name, parentId);
      final id = existing?.id ??
          (await _folderDao.create(name: folder.name, parentId: parentId)).id;
      realIds[sourceId] = id;
      return id;
    }

    for (final f in folders) {
      await resolve(f.sourceId);
    }
    return realIds;
  }

  /// `true` se a receita foi de fato criada/atualizada; `false` só quando o
  /// usuário escolheu pular um conflito.
  Future<bool> _importRecipe(
    ParsedRecipeImport recipe,
    Map<String, String> folderIds,
    ConflictResolution resolution,
  ) async {
    final sourceId = recipe.sourceId;
    final hasConflict =
        sourceId != null && await _recipeDao.findById(sourceId) != null;
    if (hasConflict && resolution == ConflictResolution.skip) {
      return false;
    }
    final recipeId = (hasConflict && resolution == ConflictResolution.duplicate)
        ? _uuid.v4()
        : (sourceId ?? _uuid.v4());

    final now = _clock().toUtc();

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
    return true;
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
