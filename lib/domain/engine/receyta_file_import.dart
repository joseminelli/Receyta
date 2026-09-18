/// Leitura do payload `.receyta` (§7, bloco D) — inverso de
/// `recipe_export.dart`. Dart puro: só valida forma/tipo dos campos, nunca
/// lança exceção — `null` pra qualquer coisa que não seja um `.receyta`
/// reconhecível. A reconciliação de verdade (getOrCreate, criação de pasta)
/// fica pro `ReceytaImportService`, que já tem acesso ao banco.
library;

import 'dart:convert';

import 'package:receyta/core/tag_name.dart';

const kSupportedReceytaSchemaVersions = {1};

class ParsedIngredientImport {
  const ParsedIngredientImport({
    required this.position,
    this.groupLabel,
    required this.rawText,
    this.quantity,
    this.unit,
    required this.name,
    this.qualifier,
  });

  final int position;
  final String? groupLabel;
  final String rawText;
  final double? quantity;
  final String? unit;
  final String name;
  final String? qualifier;
}

class ParsedStepImport {
  const ParsedStepImport({
    required this.position,
    this.groupLabel,
    required this.text,
  });

  final int position;
  final String? groupLabel;
  final String text;
}

class ParsedRecipeImport {
  const ParsedRecipeImport({
    this.sourceId,
    this.folderSourceId,
    required this.name,
    this.about,
    this.prepMinutes,
    this.cookMinutes,
    this.servings,
    this.sourceUrl,
    this.notes,
    this.tags = const [],
    this.ingredients = const [],
    this.steps = const [],
  });

  /// Id da receita no arquivo de origem (D4, RF-06.3): reaproveitado como id
  /// local no primeiro import — é o que permite detectar "essa receita já
  /// existe" numa reimportação do mesmo arquivo, sem precisar comparar
  /// conteúdo. `null` (arquivo sem o campo) sempre vira receita nova.
  final String? sourceId;
  final String? folderSourceId;
  final String name;
  final String? about;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? servings;
  final String? sourceUrl;
  final String? notes;
  final List<String> tags;
  final List<ParsedIngredientImport> ingredients;
  final List<ParsedStepImport> steps;
}

/// `sourceId` é o id do arquivo de origem — nunca reaproveitado como id de
/// verdade na importação (evita colidir com dado já existente aqui ou
/// depender de que o id não bateu com nada por acaso); serve só pra ligar
/// pasta-filha à pasta-mãe dentro do próprio arquivo.
class ParsedFolderImport {
  const ParsedFolderImport({
    required this.sourceId,
    this.parentSourceId,
    required this.name,
    this.position = 0,
  });

  final String sourceId;
  final String? parentSourceId;
  final String name;
  final int position;
}

class ParsedReceytaFile {
  const ParsedReceytaFile({
    required this.schemaVersion,
    required this.kind,
    this.folders = const [],
    this.recipes = const [],
  });

  final int schemaVersion;
  final String kind;
  final List<ParsedFolderImport> folders;
  final List<ParsedRecipeImport> recipes;
}

/// `null` = arquivo não reconhecível como `.receyta`: JSON inválido, faltando
/// campo obrigatório, ou `schemaVersion` que este app ainda não sabe ler
/// (RF-06.4 — migração de import entra quando existir uma v2 de verdade).
ParsedReceytaFile? parseReceytaFile(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;

  final schemaVersion = decoded['schemaVersion'];
  if (schemaVersion is! int ||
      !kSupportedReceytaSchemaVersions.contains(schemaVersion)) {
    return null;
  }
  final kind = decoded['kind'];
  if (kind is! String) return null;

  final rawRecipes = decoded['recipes'];
  if (rawRecipes is! List) return null;
  final recipes = [
    for (final r in rawRecipes)
      if (_parseRecipe(r) case final parsed?) parsed,
  ];

  final rawFolders = decoded['folders'];
  final folders = rawFolders is List
      ? [
          for (final f in rawFolders)
            if (_parseFolder(f) case final parsed?) parsed,
        ]
      : const <ParsedFolderImport>[];

  return ParsedReceytaFile(
    schemaVersion: schemaVersion,
    kind: kind,
    folders: folders,
    recipes: recipes,
  );
}

ParsedFolderImport? _parseFolder(Object? raw) {
  if (raw is! Map) return null;
  final id = raw['id'];
  final name = raw['name'];
  if (id is! String || name is! String || name.trim().isEmpty) return null;
  return ParsedFolderImport(
    sourceId: id,
    parentSourceId: raw['parentId'] as String?,
    name: name,
    position: (raw['position'] as num?)?.toInt() ?? 0,
  );
}

ParsedRecipeImport? _parseRecipe(Object? raw) {
  if (raw is! Map) return null;
  final name = raw['name'];
  if (name is! String || name.trim().isEmpty) return null;

  final rawIngredients = raw['ingredients'];
  final ingredients = <ParsedIngredientImport>[];
  if (rawIngredients is List) {
    for (var i = 0; i < rawIngredients.length; i++) {
      final parsed = _parseIngredient(rawIngredients[i], fallbackPosition: i);
      if (parsed != null) ingredients.add(parsed);
    }
  }

  final rawSteps = raw['steps'];
  final steps = <ParsedStepImport>[];
  if (rawSteps is List) {
    for (var i = 0; i < rawSteps.length; i++) {
      final parsed = _parseStep(rawSteps[i], fallbackPosition: i);
      if (parsed != null) steps.add(parsed);
    }
  }

  final rawTags = raw['tags'];
  final tags = rawTags is List
      ? [
          for (final t in rawTags)
            if (t is String && t.trim().isNotEmpty) t,
        ]
      : const <String>[];

  return ParsedRecipeImport(
    sourceId: raw['id'] as String?,
    folderSourceId: raw['folderId'] as String?,
    name: fixShoutyCase(name.trim()),
    about: raw['about'] as String?,
    prepMinutes: (raw['prepMinutes'] as num?)?.toInt(),
    cookMinutes: (raw['cookMinutes'] as num?)?.toInt(),
    servings: (raw['servings'] as num?)?.toInt(),
    sourceUrl: raw['sourceUrl'] as String?,
    notes: raw['notes'] as String?,
    tags: tags,
    ingredients: ingredients,
    steps: steps,
  );
}

ParsedIngredientImport? _parseIngredient(
  Object? raw, {
  required int fallbackPosition,
}) {
  if (raw is! Map) return null;
  final rawText = raw['rawText'];
  final name = raw['name'];
  if (rawText is! String || name is! String) return null;
  return ParsedIngredientImport(
    position: (raw['position'] as num?)?.toInt() ?? fallbackPosition,
    groupLabel: raw['groupLabel'] as String?,
    rawText: rawText,
    quantity: (raw['quantity'] as num?)?.toDouble(),
    unit: raw['unit'] as String?,
    name: name,
    qualifier: raw['qualifier'] as String?,
  );
}

ParsedStepImport? _parseStep(Object? raw, {required int fallbackPosition}) {
  if (raw is! Map) return null;
  final text = raw['text'];
  if (text is! String || text.trim().isEmpty) return null;
  return ParsedStepImport(
    position: (raw['position'] as num?)?.toInt() ?? fallbackPosition,
    groupLabel: raw['groupLabel'] as String?,
    text: text,
  );
}
