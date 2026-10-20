// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_log_dao.dart';

// ignore_for_file: type=lint
mixin _$CookLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $CookLogsTable get cookLogs => attachedDatabase.cookLogs;
  CookLogDaoManager get managers => CookLogDaoManager(this);
}

class CookLogDaoManager {
  final _$CookLogDaoMixin _db;
  CookLogDaoManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$CookLogsTableTableManager get cookLogs =>
      $$CookLogsTableTableManager(_db.attachedDatabase, _db.cookLogs);
}
