// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_dao.dart';

// ignore_for_file: type=lint
mixin _$IngredientDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $IngredientsTable get ingredients => attachedDatabase.ingredients;
  $IngredientAliasesTable get ingredientAliases =>
      attachedDatabase.ingredientAliases;
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $UnitsTable get units => attachedDatabase.units;
  $RecipeIngredientsTable get recipeIngredients =>
      attachedDatabase.recipeIngredients;
  $ShoppingListsTable get shoppingLists => attachedDatabase.shoppingLists;
  $ShoppingListItemsTable get shoppingListItems =>
      attachedDatabase.shoppingListItems;
  IngredientDaoManager get managers => IngredientDaoManager(this);
}

class IngredientDaoManager {
  final _$IngredientDaoMixin _db;
  IngredientDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db.attachedDatabase, _db.ingredients);
  $$IngredientAliasesTableTableManager get ingredientAliases =>
      $$IngredientAliasesTableTableManager(
          _db.attachedDatabase, _db.ingredientAliases);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db.attachedDatabase, _db.units);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(
          _db.attachedDatabase, _db.recipeIngredients);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db.attachedDatabase, _db.shoppingLists);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(
          _db.attachedDatabase, _db.shoppingListItems);
}
