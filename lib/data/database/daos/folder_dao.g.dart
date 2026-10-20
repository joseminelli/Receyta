// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_dao.dart';

// ignore_for_file: type=lint
mixin _$FolderDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $SyncTombstonesTable get syncTombstones => attachedDatabase.syncTombstones;
  FolderDaoManager get managers => FolderDaoManager(this);
}

class FolderDaoManager {
  final _$FolderDaoMixin _db;
  FolderDaoManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db.attachedDatabase, _db.recipes);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(
          _db.attachedDatabase, _db.syncTombstones);
}
