import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/sync_codec.dart' show kSyncSchemaVersion;

/// Resumo da receita que viaja junto de uma refeição compartilhada: o
/// suficiente pra outra pessoa da casa ver o que vai ser feito, abrir os
/// ingredientes e o preparo e, se quiser, guardar na própria biblioteca. Não
/// leva foto, pasta nem tags.
class SharedMealRecipe {
  const SharedMealRecipe({
    required this.id,
    required this.name,
    this.about,
    this.prepMinutes,
    this.cookMinutes,
    this.servings,
    this.tileColor,
    this.tileMotif,
    this.ingredients = const [],
    this.steps = const [],
  });

  final String id;
  final String name;
  final String? about;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? servings;
  final TileColor? tileColor;
  final TileMotif? tileMotif;
  final List<String> ingredients;
  final List<String> steps;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'about': about,
        'prepMinutes': prepMinutes,
        'cookMinutes': cookMinutes,
        'servings': servings,
        'tileColor': tileColor?.name,
        'tileMotif': tileMotif?.name,
        'ingredients': ingredients,
        'steps': steps,
      };

  static SharedMealRecipe? parse(Object? raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    final name = _str(raw['name']);
    if (id == null || id.isEmpty || name == null || name.trim().isEmpty) {
      return null;
    }
    return SharedMealRecipe(
      id: id,
      name: name,
      about: _str(raw['about']),
      prepMinutes: _int(raw['prepMinutes']),
      cookMinutes: _int(raw['cookMinutes']),
      servings: _int(raw['servings']),
      tileColor: tileColorFromName(_str(raw['tileColor'])),
      tileMotif: tileMotifFromName(_str(raw['tileMotif'])),
      ingredients: _strings(raw['ingredients']),
      steps: _strings(raw['steps']),
    );
  }
}

/// Uma refeição planejada como ela viaja pela casa: os campos de sempre, o
/// resumo da receita e quem a planejou.
class SharedMealDoc {
  const SharedMealDoc({
    required this.id,
    required this.recipe,
    required this.date,
    required this.mealType,
    required this.createdAt,
    required this.updatedAt,
    required this.byId,
    required this.byName,
    this.servingsOverride,
    this.note,
    this.done = false,
  });

  final String id;
  final SharedMealRecipe recipe;
  final DateTime date;
  final String mealType;
  final int? servingsOverride;
  final String? note;
  final bool done;
  final DateTime createdAt;

  /// Também é o `edited_at` do item na casa.
  final DateTime updatedAt;

  /// Quem planejou (id da conta e nome de exibição na hora).
  final String byId;
  final String byName;
}

Map<String, dynamic> sharedMealToJson(SharedMealDoc m) => {
      'v': kSyncSchemaVersion,
      'id': m.id,
      'recipe': m.recipe.toJson(),
      'date': m.date.toUtc().toIso8601String(),
      'mealType': m.mealType,
      'servingsOverride': m.servingsOverride,
      'note': m.note,
      'done': m.done,
      'createdAt': m.createdAt.toUtc().toIso8601String(),
      'updatedAt': m.updatedAt.toUtc().toIso8601String(),
      'byId': m.byId,
      'byName': m.byName,
    };

/// `null` se o corpo não serve (sem id, receita, data ou refeição, ou de uma
/// versão mais nova que este aparelho entende).
SharedMealDoc? parseSharedMeal(Object? raw) {
  if (raw is! Map || (_int(raw['v']) ?? 1) > kSyncSchemaVersion) return null;
  final id = _str(raw['id']);
  final recipe = SharedMealRecipe.parse(raw['recipe']);
  final date = _date(raw['date']);
  final mealType = _str(raw['mealType']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || recipe == null) return null;
  if (date == null || mealType == null || mealType.isEmpty) return null;
  if (updatedAt == null) return null;
  return SharedMealDoc(
    id: id,
    recipe: recipe,
    date: date,
    mealType: mealType,
    servingsOverride: _int(raw['servingsOverride']),
    note: _str(raw['note']),
    done: raw['done'] == true,
    createdAt: _date(raw['createdAt']) ?? updatedAt,
    updatedAt: updatedAt,
    byId: _str(raw['byId']) ?? '',
    byName: _str(raw['byName']) ?? '',
  );
}

String? _str(Object? v) => v is String ? v : null;

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;

List<String> _strings(Object? v) => [
      if (v is List)
        for (final e in v)
          if (e is String && e.trim().isNotEmpty) e,
    ];
