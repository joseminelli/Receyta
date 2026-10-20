// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_dao.dart';

// ignore_for_file: type=lint
mixin _$TagDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $RecipeTagsTable get recipeTags => attachedDatabase.recipeTags;
  TagDaoManager get managers => TagDaoManager(this);
}

class TagDaoManager {
  final _$TagDaoMixin _db;
  TagDaoManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db.attachedDatabase, _db.recipeTags);
}
