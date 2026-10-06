import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:receyta/core/sync_kinds.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/sync/sync_handler.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/domain/engine/shared_meal_codec.dart';

/// Resumo da receita [recipeId] pra viajar com a refeição; nulo se ela não
/// existe mais (a refeição então não sobe).
typedef MealRecipeSnapshot = Future<SharedMealRecipe?> Function(
  String recipeId,
);

/// O calendário da casa. Cada refeição é um item `meal_plan` da casa, com o
/// resumo da receita dentro.
///
/// - As refeições da própria pessoa ficam em `meal_plan_entries` (com
///   `space_id`) e sobem com o resumo da receita.
/// - As dos outros chegam em `shared_meals`: quem recebe pode não ter a receita.
///   Mexer numa delas (marcar feita, mover, apagar) sobe a mudança de volta, e
///   o dono a aplica na refeição real dele.
/// - Uma refeição minha que chega de outro aparelho MEU vira refeição real aqui
///   (se a receita existe), em vez de linha de "outra pessoa".
class SharedMealSync implements SyncHandler {
  SharedMealSync(
    this.db, {
    required this.spaceId,
    required this.myId,
    required this.myName,
    required this.snapshotOf,
  });

  final AppDatabase db;
  final String spaceId;
  final String myId;
  final Future<String> Function() myName;
  final MealRecipeSnapshot snapshotOf;

  @override
  String get kind => kSyncKindMealPlan;

  @override
  Future<bool> hasPending() async =>
      (await db.mealPlanDao.dirtyForSync(spaceId: spaceId)).isNotEmpty ||
      (await db.mealPlanDao.dirtySharedMeals(spaceId)).isNotEmpty;

  @override
  Future<List<PendingDoc>> pending() async {
    final out = <PendingDoc>[];
    final name = await myName();

    for (final e in await db.mealPlanDao.dirtyForSync(spaceId: spaceId)) {
      final recipe = await snapshotOf(e.recipeId);
      if (recipe == null) continue;
      out.add((
        doc: SyncDoc(
          kind: kind,
          id: e.id,
          editedAt: e.updatedAt,
          data: sharedMealToJson(SharedMealDoc(
            id: e.id,
            recipe: recipe,
            date: e.date,
            mealType: e.mealType,
            servingsOverride: e.servingsOverride,
            note: e.note,
            done: e.done,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            byId: myId,
            byName: name,
          )),
        ),
        onSent: () => db.mealPlanDao.markSynced(e.id, e.updatedAt),
      ));
    }

    for (final m in await db.mealPlanDao.dirtySharedMeals(spaceId)) {
      final recipe = SharedMealRecipe.parse(_decode(m.recipeJson));
      if (recipe == null) continue;
      out.add((
        doc: SyncDoc(
          kind: kind,
          id: m.id,
          editedAt: m.updatedAt,
          data: sharedMealToJson(SharedMealDoc(
            id: m.id,
            recipe: recipe,
            date: m.date,
            mealType: m.mealType,
            servingsOverride: m.servingsOverride,
            note: m.note,
            done: m.done,
            createdAt: m.createdAt,
            updatedAt: m.updatedAt,
            byId: m.authorId,
            byName: m.authorName,
          )),
        ),
        onSent: () => db.mealPlanDao.markSharedSynced(m.id, m.updatedAt),
      ));
    }
    return out;
  }

  @override
  Future<ApplyResult> apply(List<SyncDoc> docs) async {
    var applied = 0;
    var removed = 0;
    for (final d in docs) {
      final mine = await db.mealPlanDao.findById(d.id);
      final other = await db.mealPlanDao.findShared(d.id);

      if (d.deleted) {
        if (mine != null &&
            mine.spaceId == spaceId &&
            remoteWins(
              exists: true,
              remoteEditedAt: d.editedAt,
              localUpdatedAt: mine.updatedAt,
              localSyncedAt: mine.syncedAt,
            )) {
          await (db.delete(db.mealPlanEntries)..where((e) => e.id.equals(d.id)))
              .go();
          removed++;
        } else if (other != null &&
            remoteWins(
              exists: true,
              remoteEditedAt: d.editedAt,
              localUpdatedAt: other.updatedAt,
              localSyncedAt: other.syncedAt,
            )) {
          await db.mealPlanDao.deleteSharedRaw(d.id);
          removed++;
        }
        continue;
      }

      final doc = parseSharedMeal(d.data);
      if (doc == null || doc.id != d.id) continue;

      if (mine != null) {
        if (mine.spaceId != spaceId) continue;
        if (!remoteWins(
          exists: true,
          remoteEditedAt: doc.updatedAt,
          localUpdatedAt: mine.updatedAt,
          localSyncedAt: mine.syncedAt,
        )) {
          continue;
        }
        await (db.update(db.mealPlanEntries)..where((e) => e.id.equals(d.id)))
            .write(MealPlanEntriesCompanion(
          date: Value(doc.date),
          mealType: Value(doc.mealType),
          servingsOverride: Value(doc.servingsOverride),
          note: Value(doc.note),
          done: Value(doc.done),
          updatedAt: Value(doc.updatedAt),
          syncedAt: Value(doc.updatedAt),
        ));
        applied++;
        continue;
      }

      if (doc.byId == myId) {
        final recipeExists = await (db.select(db.recipes)
              ..where((r) => r.id.equals(doc.recipe.id)))
            .getSingleOrNull();
        if (recipeExists == null) continue;
        await db.into(db.mealPlanEntries).insert(MealPlanEntryRow(
              id: doc.id,
              recipeId: doc.recipe.id,
              date: doc.date,
              mealType: doc.mealType,
              servingsOverride: doc.servingsOverride,
              note: doc.note,
              done: doc.done,
              createdAt: doc.createdAt,
              updatedAt: doc.updatedAt,
              syncedAt: doc.updatedAt,
              spaceId: spaceId,
            ));
        applied++;
        continue;
      }

      if (!remoteWins(
        exists: other != null,
        remoteEditedAt: doc.updatedAt,
        localUpdatedAt: other?.updatedAt,
        localSyncedAt: other?.syncedAt,
      )) {
        continue;
      }
      await db.mealPlanDao.putShared(SharedMealRow(
        id: doc.id,
        spaceId: spaceId,
        date: doc.date,
        mealType: doc.mealType,
        servingsOverride: doc.servingsOverride,
        note: doc.note,
        done: doc.done,
        recipeJson: jsonEncode(doc.recipe.toJson()),
        authorId: doc.byId,
        authorName: doc.byName,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
        syncedAt: doc.updatedAt,
      ));
      applied++;
    }
    return (applied: applied, removed: removed);
  }

  Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }
}

/// Monta o resumo da receita [recipeId] a partir do banco; nulo se não existe
/// (ou está na lixeira).
Future<SharedMealRecipe?> mealRecipeSnapshot(
  AppDatabase db,
  RecipeRepository recipes,
  String recipeId,
) async {
  final row = await db.recipeDao.findById(recipeId);
  if (row == null) return null;
  final detail = await recipes.detailOfRow(row);
  final r = detail.recipe;
  return SharedMealRecipe(
    id: r.id,
    name: r.name,
    about: r.about,
    prepMinutes: r.prepMinutes,
    cookMinutes: r.cookMinutes,
    servings: r.servings,
    tileColor: r.tileColor,
    tileMotif: r.tileMotif,
    ingredients: [for (final i in detail.ingredients) i.rawText],
    steps: [for (final s in detail.steps) s.text],
  );
}
