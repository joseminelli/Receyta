// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_dao.dart';

// ignore_for_file: type=lint
mixin _$RecipeDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $CategoriesTable get categories => attachedDatabase.categories;
  $IngredientsTable get ingredients => attachedDatabase.ingredients;
  $UnitsTable get units => attachedDatabase.units;
  $RecipeIngredientsTable get recipeIngredients =>
      attachedDatabase.recipeIngredients;
  $RecipeStepsTable get recipeSteps => attachedDatabase.recipeSteps;
  $TagsTable get tags => attachedDatabase.tags;
  $RecipeTagsTable get recipeTags => attachedDatabase.recipeTags;
  $SyncTombstonesTable get syncTombstones => attachedDatabase.syncTombstones;
  RecipeDaoManager get managers => RecipeDaoManager(this);
}

class RecipeDaoManager {
  final _$RecipeDaoMixin _db;
  RecipeDaoManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db.attachedDatabase, _db.ingredients);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db.attachedDatabase, _db.units);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(
          _db.attachedDatabase, _db.recipeIngredients);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db.attachedDatabase, _db.recipeSteps);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db.attachedDatabase, _db.recipeTags);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(
          _db.attachedDatabase, _db.syncTombstones);
}
