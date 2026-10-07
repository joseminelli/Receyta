/// Formato dos itens sincronizados que vieram depois de receitas e pastas (H4):
/// histórico "cozinhei", refeições planejadas, listas de compras e seus itens,
/// e despensa. Dart puro. Mesmas regras do `sync_codec.dart`: datas em UTC,
/// leitura tolerante (campo ausente ou do tipo errado vira nulo/padrão, nunca
/// exceção), e corpo de versão MAIOR que a entendida é ignorado.
library;

import 'package:receyta/domain/engine/sync_codec.dart' show kSyncSchemaVersion;

// ---------------------------------------------------------------------------
// Histórico "cozinhei"
// ---------------------------------------------------------------------------

class SyncCookLog {
  const SyncCookLog({
    required this.id,
    required this.recipeId,
    required this.cookedAt,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.mealPlanEntryId,
  });

  final String id;
  final String recipeId;
  final DateTime cookedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;
  final String? mealPlanEntryId;
}

Map<String, dynamic> cookLogToSyncJson(SyncCookLog l) => {
      'v': kSyncSchemaVersion,
      'id': l.id,
      'recipeId': l.recipeId,
      'cookedAt': l.cookedAt.toUtc().toIso8601String(),
      'note': l.note,
      'mealPlanEntryId': l.mealPlanEntryId,
      'createdAt': l.createdAt.toUtc().toIso8601String(),
      'updatedAt': l.updatedAt.toUtc().toIso8601String(),
    };

SyncCookLog? parseCookLogSync(Object? raw) {
  if (raw is! Map || (_int(raw['v']) ?? 1) > kSyncSchemaVersion) return null;
  final id = _str(raw['id']);
  final recipeId = _str(raw['recipeId']);
  final cookedAt = _date(raw['cookedAt']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || recipeId == null || recipeId.isEmpty) {
    return null;
  }
  if (cookedAt == null || updatedAt == null) return null;
  return SyncCookLog(
    id: id,
    recipeId: recipeId,
    cookedAt: cookedAt,
    createdAt: _date(raw['createdAt']) ?? cookedAt,
    updatedAt: updatedAt,
    note: _str(raw['note']),
    mealPlanEntryId: _str(raw['mealPlanEntryId']),
  );
}

// ---------------------------------------------------------------------------
// Refeição planejada
// ---------------------------------------------------------------------------

class SyncMealPlan {
  const SyncMealPlan({
    required this.id,
    required this.recipeId,
    required this.date,
    required this.mealType,
    required this.createdAt,
    required this.updatedAt,
    this.servingsOverride,
    this.note,
    this.done = false,
  });

  final String id;
  final String recipeId;
  final DateTime date;
  final String mealType;
  final int? servingsOverride;
  final String? note;
  final bool done;
  final DateTime createdAt;
  final DateTime updatedAt;
}

Map<String, dynamic> mealPlanToSyncJson(SyncMealPlan e) => {
      'v': kSyncSchemaVersion,
      'id': e.id,
      'recipeId': e.recipeId,
      'date': e.date.toUtc().toIso8601String(),
      'mealType': e.mealType,
      'servingsOverride': e.servingsOverride,
      'note': e.note,
      'done': e.done,
      'createdAt': e.createdAt.toUtc().toIso8601String(),
      'updatedAt': e.updatedAt.toUtc().toIso8601String(),
    };

SyncMealPlan? parseMealPlanSync(Object? raw) {
  if (raw is! Map || (_int(raw['v']) ?? 1) > kSyncSchemaVersion) return null;
  final id = _str(raw['id']);
  final recipeId = _str(raw['recipeId']);
  final date = _date(raw['date']);
  final mealType = _str(raw['mealType']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || recipeId == null || recipeId.isEmpty) {
    return null;
  }
  if (date == null || mealType == null || mealType.isEmpty) return null;
  if (updatedAt == null) return null;
  return SyncMealPlan(
    id: id,
    recipeId: recipeId,
    date: date,
    mealType: mealType,
    servingsOverride: _int(raw['servingsOverride']),
    note: _str(raw['note']),
    done: raw['done'] == true,
    createdAt: _date(raw['createdAt']) ?? updatedAt,
    updatedAt: updatedAt,
  );
}

// ---------------------------------------------------------------------------
// Lista de compras e seus itens
// ---------------------------------------------------------------------------

class SyncShoppingList {
  const SyncShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

Map<String, dynamic> shoppingListToSyncJson(SyncShoppingList l) => {
      'v': kSyncSchemaVersion,
      'id': l.id,
      'name': l.name,
      'status': l.status,
      'createdAt': l.createdAt.toUtc().toIso8601String(),
      'updatedAt': l.updatedAt.toUtc().toIso8601String(),
    };

SyncShoppingList? parseShoppingListSync(Object? raw) {
  if (raw is! Map || (_int(raw['v']) ?? 1) > kSyncSchemaVersion) return null;
  final id = _str(raw['id']);
  final name = _str(raw['name']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || name == null || name.trim().isEmpty) {
    return null;
  }
  if (updatedAt == null) return null;
  return SyncShoppingList(
    id: id,
    name: name,
    status: _str(raw['status']) ?? 'active',
    createdAt: _date(raw['createdAt']) ?? updatedAt,
    updatedAt: updatedAt,
  );
}

class SyncItemSource {
  const SyncItemSource({required this.recipeId, this.quantity, this.unit});

  final String recipeId;
  final double? quantity;
  final String? unit;
}

/// Item avulso (`manualName`) ou ligado a um ingrediente do catálogo — que
/// viaja por NOME ([ingredientName]), como nas receitas.
class SyncShoppingItem {
  const SyncShoppingItem({
    required this.id,
    required this.listId,
    required this.updatedAt,
    this.ingredientName,
    this.manualName,
    this.quantity,
    this.unit,
    this.checked = false,
    this.note,
    this.position = 0,
    this.sources = const [],
    this.addedBy,
    this.checkedBy,
  });

  final String id;
  final String listId;

  /// Quem adicionou e quem marcou (id da conta); só nas listas da casa.
  final String? addedBy;
  final String? checkedBy;
  final String? ingredientName;
  final String? manualName;
  final double? quantity;
  final String? unit;
  final bool checked;
  final String? note;
  final int position;
  final List<SyncItemSource> sources;
  final DateTime updatedAt;
}

Map<String, dynamic> shoppingItemToSyncJson(SyncShoppingItem i) => {
      'v': kSyncSchemaVersion,
      'id': i.id,
      'listId': i.listId,
      'ingredientName': i.ingredientName,
      'manualName': i.manualName,
      'quantity': i.quantity,
      'unit': i.unit,
      'checked': i.checked,
      'note': i.note,
      'position': i.position,
      'addedBy': i.addedBy,
      'checkedBy': i.checkedBy,
      'sources': [
        for (final s in i.sources)
          {'recipeId': s.recipeId, 'quantity': s.quantity, 'unit': s.unit},
      ],
      'updatedAt': i.updatedAt.toUtc().toIso8601String(),
    };

SyncShoppingItem? parseShoppingItemSync(Object? raw) {
  if (raw is! Map || (_int(raw['v']) ?? 1) > kSyncSchemaVersion) return null;
  final id = _str(raw['id']);
  final listId = _str(raw['listId']);
  final updatedAt = _date(raw['updatedAt']);
  if (id == null || id.isEmpty || listId == null || listId.isEmpty) return null;
  if (updatedAt == null) return null;
  final ingredientName = _str(raw['ingredientName']);
  final manualName = _str(raw['manualName']);
  // Sem de onde tirar o nome, o item não serve.
  final hasIngredient =
      ingredientName != null && ingredientName.trim().isNotEmpty;
  final hasManual = manualName != null && manualName.trim().isNotEmpty;
  if (!hasIngredient && !hasManual) return null;
  return SyncShoppingItem(
    id: id,
    listId: listId,
    ingredientName: ingredientName,
    manualName: manualName,
    quantity: _double(raw['quantity']),
    unit: _str(raw['unit']),
    checked: raw['checked'] == true,
    note: _str(raw['note']),
    position: _int(raw['position']) ?? 0,
    addedBy: _str(raw['addedBy']),
    checkedBy: _str(raw['checkedBy']),
    sources: [
      for (final s in _list(raw['sources']))
        if (s is Map && _str(s['recipeId']) != null)
          SyncItemSource(
            recipeId: _str(s['recipeId'])!,
            quantity: _double(s['quantity']),
            unit: _str(s['unit']),
          ),
    ],
    updatedAt: updatedAt,
  );
}

// ---------------------------------------------------------------------------
// Despensa
// ---------------------------------------------------------------------------

/// "Sempre tenho": um item por ingrediente. O id na nuvem é a CHAVE
/// normalizada do ingrediente ([key]) — o catálogo é de cada aparelho, mas
/// "Sal" vira a mesma chave em todos.
class SyncPantry {
  const SyncPantry({
    required this.key,
    required this.name,
    required this.inPantry,
    required this.updatedAt,
  });

  final String key;
  final String name;
  final bool inPantry;
  final DateTime updatedAt;
}

Map<String, dynamic> pantryToSyncJson(SyncPantry p) => {
      'v': kSyncSchemaVersion,
      'key': p.key,
      'name': p.name,
      'inPantry': p.inPantry,
      'updatedAt': p.updatedAt.toUtc().toIso8601String(),
    };

SyncPantry? parsePantrySync(Object? raw) {
  if (raw is! Map || (_int(raw['v']) ?? 1) > kSyncSchemaVersion) return null;
  final key = _str(raw['key']);
  final name = _str(raw['name']);
  final updatedAt = _date(raw['updatedAt']);
  if (key == null || key.isEmpty || name == null || name.trim().isEmpty) {
    return null;
  }
  if (updatedAt == null) return null;
  return SyncPantry(
    key: key,
    name: name,
    inPantry: raw['inPantry'] == true,
    updatedAt: updatedAt,
  );
}

// ---------------------------------------------------------------------------
// Leitura tolerante
// ---------------------------------------------------------------------------

String? _str(Object? v) => v is String ? v : null;

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

double? _double(Object? v) => v is num ? v.toDouble() : null;

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;

List<Object?> _list(Object? v) => v is List ? v : const [];
