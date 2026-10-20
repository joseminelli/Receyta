// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_dao.dart';

// ignore_for_file: type=lint
mixin _$ShoppingListDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShoppingListsTable get shoppingLists => attachedDatabase.shoppingLists;
  $CategoriesTable get categories => attachedDatabase.categories;
  $IngredientsTable get ingredients => attachedDatabase.ingredients;
  $UnitsTable get units => attachedDatabase.units;
  $ShoppingListItemsTable get shoppingListItems =>
      attachedDatabase.shoppingListItems;
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $ShoppingItemSourcesTable get shoppingItemSources =>
      attachedDatabase.shoppingItemSources;
  ShoppingListDaoManager get managers => ShoppingListDaoManager(this);
}

class ShoppingListDaoManager {
  final _$ShoppingListDaoMixin _db;
  ShoppingListDaoManager(this._db);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db.attachedDatabase, _db.shoppingLists);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db.attachedDatabase, _db.ingredients);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db.attachedDatabase, _db.units);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(
          _db.attachedDatabase, _db.shoppingListItems);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$ShoppingItemSourcesTableTableManager get shoppingItemSources =>
      $$ShoppingItemSourcesTableTableManager(
          _db.attachedDatabase, _db.shoppingItemSources);
}
