/// Formato de export de receita (§7, bloco D). Serializa `RecipeDetail` para
/// o payload portátil `.receyta` — JSON puro por dentro, sem tocar em
/// arquivo/rede (isso é o `RecipeExportService`). Ingredientes viajam como
/// **nome legível**, não por id: ao importar, a base de destino reconcilia
/// via `getOrCreate` (§8.2) contra o próprio catálogo, então nunca depende
/// dos ids da origem baterem com os do destino.
library;

import 'package:receyta/domain/engine/ingredient_parser.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

const kRecipeExportSchemaVersion = 1;

/// Monta o corpo de export de uma única receita (D1) — `kind: "recipes"`,
/// sem pastas nem planejamento (export completo com pastas é o [buildFullExportJson], D2).
/// [ingredientNames] resolve `ingredientId` → nome legível (§8.2, catálogo);
/// entra pronto porque este arquivo não toca em banco.
Map<String, dynamic> buildRecipeExportJson(
  RecipeDetail detail, {
  required Map<String, String> ingredientNames,
  DateTime Function() clock = DateTime.now,
}) {
  return _envelope(
    kind: 'recipes',
    recipes: [detail],
    ingredientNames: ingredientNames,
    clock: clock,
  );
}

/// Backup completo (D2) — `kind: "full"`, com [folders] junto pra a árvore
/// sobreviver ao roundtrip. `recipeCount`/planejamento (calendário, lista de
/// compras) ainda não existem no app, então não tem o que incluir aqui além
/// de pasta + receita.
Map<String, dynamic> buildFullExportJson({
  required List<Folder> folders,
  required List<RecipeDetail> recipes,
  required Map<String, String> ingredientNames,
  DateTime Function() clock = DateTime.now,
}) {
  return _envelope(
    kind: 'full',
    folders: folders,
    recipes: recipes,
    ingredientNames: ingredientNames,
    clock: clock,
  );
}

Map<String, dynamic> _envelope({
  required String kind,
  required List<RecipeDetail> recipes,
  required Map<String, String> ingredientNames,
  required DateTime Function() clock,
  List<Folder>? folders,
}) {
  return {
    'schemaVersion': kRecipeExportSchemaVersion,
    'exportedAt': clock().toUtc().toIso8601String(),
    'app': 'receyta',
    'kind': kind,
    if (folders != null) 'folders': [for (final f in folders) _folderToJson(f)],
    'recipes': [for (final r in recipes) _recipeToJson(r, ingredientNames)],
  };
}

Map<String, dynamic> _folderToJson(Folder f) => {
      'id': f.id,
      'parentId': f.parentId,
      'name': f.name,
      'position': f.position,
    };

Map<String, dynamic> _recipeToJson(
  RecipeDetail detail,
  Map<String, String> ingredientNames,
) {
  final r = detail.recipe;
  return {
    'id': r.id,
    'folderId': r.folderId,
    'name': r.name,
    'about': r.about,
    'prepMinutes': r.prepMinutes,
    'cookMinutes': r.cookMinutes,
    'servings': r.servings,
    'sourceUrl': r.sourceUrl,
    'notes': r.notes,
    'tags': [for (final t in detail.tags) t.name],
    'ingredients': [
      for (final i in detail.ingredients) _ingredientToJson(i, ingredientNames)
    ],
    'steps': [
      for (final s in detail.steps)
        {'position': s.position, 'groupLabel': s.groupLabel, 'text': s.text},
    ],
    'createdAt': r.createdAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> _ingredientToJson(
  RecipeIngredient i,
  Map<String, String> ingredientNames,
) {
  return {
    'position': i.position,
    'groupLabel': i.groupLabel,
    'rawText': i.rawText,
    'quantity': i.quantity,
    'unit': i.unitId,
    'name': _ingredientName(i, ingredientNames),
    'qualifier': i.qualifier,
  };
}

/// Nome legível pro ingrediente: o do catálogo quando resolvido; se a linha
/// nunca chegou a resolver (`ingredientId` nulo — raro, só quando o parser
/// não extraiu nada de aproveitável), tenta o nome que o parser (C1) já
/// separa do `rawText`; na pior hipótese, o `rawText` cru mesmo, pra nunca
/// exportar uma linha vazia.
String _ingredientName(RecipeIngredient i, Map<String, String> names) {
  final id = i.ingredientId;
  final fromCatalog = id == null ? null : names[id];
  if (fromCatalog != null) return fromCatalog;
  final parsedName = parseIngredientLine(i.rawText).name;
  return parsedName.isNotEmpty ? parsedName : i.rawText;
}
