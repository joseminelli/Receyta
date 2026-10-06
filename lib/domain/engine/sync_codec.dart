/// Formato dos itens sincronizados com a conta (H3): como uma receita e uma
/// pasta viram o JSON da coluna `data` de `sync_docs` e voltam. Dart puro —
/// sem banco, sem rede.
///
/// Diferente do `.receyta` (feito pra compartilhar), aqui tem TUDO que o
/// aparelho guarda da receita: cor e textura do azulejo, favorita, lixeira,
/// pasta, datas. Ingredientes viajam por **nome**, não por id: o catálogo é
/// de cada aparelho e é reconciliado por `getOrCreate` ao aplicar. A foto
/// viaja só pelo NOME do arquivo — o arquivo em si fica no Storage.
library;

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

export 'package:receyta/core/sync_kinds.dart';

/// Versão do corpo. Um aparelho que lê um item de versão MAIOR ignora o item
/// (não entende) em vez de aplicar pela metade.
const kSyncSchemaVersion = 1;

class SyncIngredient {
  const SyncIngredient({
    required this.position,
    required this.rawText,
    required this.name,
    this.groupLabel,
    this.quantity,
    this.unit,
    this.qualifier,
  });

  final int position;
  final String rawText;
  final String name;
  final String? groupLabel;
  final double? quantity;
  final String? unit;
  final String? qualifier;
}

class SyncStep {
  const SyncStep({
    required this.position,
    required this.text,
    this.groupLabel,
  });

  final int position;
  final String text;
  final String? groupLabel;
}

class SyncRecipe {
  const SyncRecipe({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.about,
    this.prepMinutes,
    this.cookMinutes,
    this.servings,
    this.notes,
    this.sourceUrl,
    this.imageName,
    this.tileColor,
    this.tileMotif,
    this.isFavorite = false,
    this.deletedAt,
    this.tags = const [],
    this.ingredients = const [],
    this.steps = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// Também é o `edited_at` do item na nuvem.
  final DateTime updatedAt;
  final String? folderId;
  final String? about;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? servings;
  final String? notes;
  final String? sourceUrl;

  /// Nome do arquivo da foto (a foto fica no Storage).
  final String? imageName;
  final TileColor? tileColor;
  final TileMotif? tileMotif;
  final bool isFavorite;

  /// Preenchido = a receita está na lixeira.
  final DateTime? deletedAt;
  final List<String> tags;
  final List<SyncIngredient> ingredients;
  final List<SyncStep> steps;
}

class SyncFolder {
  const SyncFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.position = 0,
    this.tileColor,
    this.tileMotif,
  });

  final String id;
  final String name;
  final String? parentId;
  final int position;
  final TileColor? tileColor;
  final TileMotif? tileMotif;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// ---------------------------------------------------------------------------
// Receita
// ---------------------------------------------------------------------------

/// [ingredientNames] resolve `ingredientId` → nome legível do catálogo.
Map<String, dynamic> recipeToSyncJson(
  RecipeDetail detail, {
  required Map<String, String> ingredientNames,
}) {
  final r = detail.recipe;
  return {
    'v': kSyncSchemaVersion,
    'id': r.id,
    'name': r.name,
    'about': r.about,
    'prepMinutes': r.prepMinutes,
    'cookMinutes': r.cookMinutes,
    'servings': r.servings,
    'notes': r.notes,
    'sourceUrl': r.sourceUrl,
    'folderId': r.folderId,
    'imageName': r.imagePath,
    'tileColor': r.tileColor?.name,
    'tileMotif': r.tileMotif?.name,
    'isFavorite': r.isFavorite,
    'deletedAt': r.deletedAt?.toUtc().toIso8601String(),
    'createdAt': r.createdAt.toUtc().toIso8601String(),
    'updatedAt': r.updatedAt.toUtc().toIso8601String(),
    'tags': [for (final t in detail.tags) t.name],
    'ingredients': [
      for (final i in detail.ingredients)
        {
          'position': i.position,
          'groupLabel': i.groupLabel,
          'rawText': i.rawText,
          'quantity': i.quantity,
          'unit': i.unitId,
          'name': _ingredientName(i.ingredientId, i.rawText, ingredientNames),
          'qualifier': i.qualifier,
        },
    ],
    'steps': [
      for (final s in detail.steps)
        {'position': s.position, 'groupLabel': s.groupLabel, 'text': s.text},
    ],
  };
}

/// Nome do catálogo; se a linha nunca resolveu, o próprio texto digitado —
/// nunca vai um nome vazio.
String _ingredientName(
  String? ingredientId,
  String rawText,
  Map<String, String> names,
) {
  final fromCatalog = ingredientId == null ? null : names[ingredientId];
  return (fromCatalog != null && fromCatalog.isNotEmpty)
      ? fromCatalog
      : rawText;
}

/// `null` se o corpo não serve: sem id/nome/datas, ou de uma versão mais nova
/// que a que este aparelho entende. Tolerante com o resto: campo ausente ou do
/// tipo errado vira nulo/padrão, nunca exceção.
SyncRecipe? parseRecipeSync(Object? raw) {
  if (raw is! Map) return null;
  final version = _int(raw['v']) ?? 1;
  if (version > kSyncSchemaVersion) return null;

  final id = _string(raw['id']);
  final name = _string(raw['name']);
  final createdAt = _date(raw['createdAt']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || name == null || name.trim().isEmpty) {
    return null;
  }
  if (createdAt == null || updatedAt == null) return null;

  return SyncRecipe(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    folderId: _string(raw['folderId']),
    about: _string(raw['about']),
    prepMinutes: _int(raw['prepMinutes']),
    cookMinutes: _int(raw['cookMinutes']),
    servings: _int(raw['servings']),
    notes: _string(raw['notes']),
    sourceUrl: _string(raw['sourceUrl']),
    imageName: _string(raw['imageName']),
    tileColor: tileColorFromName(_string(raw['tileColor'])),
    tileMotif: tileMotifFromName(_string(raw['tileMotif'])),
    isFavorite: raw['isFavorite'] == true,
    deletedAt: _date(raw['deletedAt']),
    tags: [
      for (final t in _list(raw['tags']))
        if (t is String && t.trim().isNotEmpty) t,
    ],
    ingredients: [
      for (final i in _list(raw['ingredients']))
        if (_parseIngredient(i) case final parsed?) parsed,
    ],
    steps: [
      for (final s in _list(raw['steps']))
        if (_parseStep(s) case final parsed?) parsed,
    ],
  );
}

SyncIngredient? _parseIngredient(Object? raw) {
  if (raw is! Map) return null;
  final rawText = _string(raw['rawText']);
  if (rawText == null || rawText.trim().isEmpty) return null;
  final name = _string(raw['name']);
  return SyncIngredient(
    position: _int(raw['position']) ?? 0,
    rawText: rawText,
    name: (name == null || name.trim().isEmpty) ? rawText : name,
    groupLabel: _string(raw['groupLabel']),
    quantity: _double(raw['quantity']),
    unit: _string(raw['unit']),
    qualifier: _string(raw['qualifier']),
  );
}

SyncStep? _parseStep(Object? raw) {
  if (raw is! Map) return null;
  final text = _string(raw['text']);
  if (text == null || text.trim().isEmpty) return null;
  return SyncStep(
    position: _int(raw['position']) ?? 0,
    text: text,
    groupLabel: _string(raw['groupLabel']),
  );
}

// ---------------------------------------------------------------------------
// Pasta
// ---------------------------------------------------------------------------

Map<String, dynamic> folderToSyncJson({
  required String id,
  required String name,
  required DateTime createdAt,
  required DateTime updatedAt,
  String? parentId,
  int position = 0,
  TileColor? tileColor,
  TileMotif? tileMotif,
}) {
  return {
    'v': kSyncSchemaVersion,
    'id': id,
    'name': name,
    'parentId': parentId,
    'position': position,
    'tileColor': tileColor?.name,
    'tileMotif': tileMotif?.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

SyncFolder? parseFolderSync(Object? raw) {
  if (raw is! Map) return null;
  final version = _int(raw['v']) ?? 1;
  if (version > kSyncSchemaVersion) return null;

  final id = _string(raw['id']);
  final name = _string(raw['name']);
  final createdAt = _date(raw['createdAt']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || name == null || name.trim().isEmpty) {
    return null;
  }
  if (createdAt == null || updatedAt == null) return null;

  return SyncFolder(
    id: id,
    name: name,
    parentId: _string(raw['parentId']),
    position: _int(raw['position']) ?? 0,
    tileColor: tileColorFromName(_string(raw['tileColor'])),
    tileMotif: tileMotifFromName(_string(raw['tileMotif'])),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ---------------------------------------------------------------------------
// Leitura tolerante
// ---------------------------------------------------------------------------

String? _string(Object? v) => v is String ? v : null;

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

double? _double(Object? v) => v is num ? v.toDouble() : null;

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;

List<Object?> _list(Object? v) => v is List ? v : const [];
