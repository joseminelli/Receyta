// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_dao.dart';

// ignore_for_file: type=lint
mixin _$MealPlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $MealPlanEntriesTable get mealPlanEntries => attachedDatabase.mealPlanEntries;
  $SharedMealsTable get sharedMeals => attachedDatabase.sharedMeals;
  $CookLogsTable get cookLogs => attachedDatabase.cookLogs;
  MealPlanDaoManager get managers => MealPlanDaoManager(this);
}

class MealPlanDaoManager {
  final _$MealPlanDaoMixin _db;
  MealPlanDaoManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$MealPlanEntriesTableTableManager get mealPlanEntries =>
      $$MealPlanEntriesTableTableManager(
          _db.attachedDatabase, _db.mealPlanEntries);
  $$SharedMealsTableTableManager get sharedMeals =>
      $$SharedMealsTableTableManager(_db.attachedDatabase, _db.sharedMeals);
  $$CookLogsTableTableManager get cookLogs =>
      $$CookLogsTableTableManager(_db.attachedDatabase, _db.cookLogs);
}
