// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, FolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL REFERENCES folders (id)');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tileColorMeta =
      const VerificationMeta('tileColor');
  @override
  late final GeneratedColumn<String> tileColor = GeneratedColumn<String>(
      'tile_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tileMotifMeta =
      const VerificationMeta('tileMotif');
  @override
  late final GeneratedColumn<String> tileMotif = GeneratedColumn<String>(
      'tile_motif', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parentId,
        name,
        tileColor,
        tileMotif,
        position,
        createdAt,
        updatedAt,
        deletedAt,
        lastOpenedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(Insertable<FolderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tile_color')) {
      context.handle(_tileColorMeta,
          tileColor.isAcceptableOrUnknown(data['tile_color']!, _tileColorMeta));
    }
    if (data.containsKey('tile_motif')) {
      context.handle(_tileMotifMeta,
          tileMotif.isAcceptableOrUnknown(data['tile_motif']!, _tileMotifMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      tileColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tile_color']),
      tileMotif: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tile_motif']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      lastOpenedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_opened_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class FolderRow extends DataClass implements Insertable<FolderRow> {
  final String id;
  final String? parentId;
  final String name;

  /// Cor e módulo do azulejo escolhidos (§9.4). Nulo = aparência padrão
  /// (violet/meia-lua). Guardados como o `.name` do enum.
  final String? tileColor;
  final String? tileMotif;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Último acesso — criação ou abertura (§ "recentes" da home). Preenchida
  /// pela aplicação, nunca fica nula na prática; nullable só porque
  /// `addColumn` de migração não backfilla por linha sozinho (v3→v4 faz isso
  /// com um `UPDATE`, ver `app_database.dart`).
  final DateTime? lastOpenedAt;

  /// O `updated_at` que a pasta tinha quando foi sincronizada com a conta (H3).
  /// Nulo ou menor que `updated_at` = mudou desde então e precisa subir.
  final DateTime? syncedAt;
  const FolderRow(
      {required this.id,
      this.parentId,
      required this.name,
      this.tileColor,
      this.tileMotif,
      required this.position,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.lastOpenedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || tileColor != null) {
      map['tile_color'] = Variable<String>(tileColor);
    }
    if (!nullToAbsent || tileMotif != null) {
      map['tile_motif'] = Variable<String>(tileMotif);
    }
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      tileColor: tileColor == null && nullToAbsent
          ? const Value.absent()
          : Value(tileColor),
      tileMotif: tileMotif == null && nullToAbsent
          ? const Value.absent()
          : Value(tileMotif),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory FolderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      tileColor: serializer.fromJson<String?>(json['tileColor']),
      tileMotif: serializer.fromJson<String?>(json['tileMotif']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'tileColor': serializer.toJson<String?>(tileColor),
      'tileMotif': serializer.toJson<String?>(tileMotif),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  FolderRow copyWith(
          {String? id,
          Value<String?> parentId = const Value.absent(),
          String? name,
          Value<String?> tileColor = const Value.absent(),
          Value<String?> tileMotif = const Value.absent(),
          int? position,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<DateTime?> lastOpenedAt = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      FolderRow(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        tileColor: tileColor.present ? tileColor.value : this.tileColor,
        tileMotif: tileMotif.present ? tileMotif.value : this.tileMotif,
        position: position ?? this.position,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  FolderRow copyWithCompanion(FoldersCompanion data) {
    return FolderRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      tileColor: data.tileColor.present ? data.tileColor.value : this.tileColor,
      tileMotif: data.tileMotif.present ? data.tileMotif.value : this.tileMotif,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('tileColor: $tileColor, ')
          ..write('tileMotif: $tileMotif, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, name, tileColor, tileMotif,
      position, createdAt, updatedAt, deletedAt, lastOpenedAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.tileColor == this.tileColor &&
          other.tileMotif == this.tileMotif &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.syncedAt == this.syncedAt);
}

class FoldersCompanion extends UpdateCompanion<FolderRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String?> tileColor;
  final Value<String?> tileMotif;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.tileColor = const Value.absent(),
    this.tileMotif = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    this.tileColor = const Value.absent(),
    this.tileMotif = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<FolderRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? tileColor,
    Expression<String>? tileMotif,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (tileColor != null) 'tile_color': tileColor,
      if (tileMotif != null) 'tile_motif': tileMotif,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parentId,
      Value<String>? name,
      Value<String?>? tileColor,
      Value<String?>? tileMotif,
      Value<int>? position,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<DateTime?>? lastOpenedAt,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return FoldersCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      tileColor: tileColor ?? this.tileColor,
      tileMotif: tileMotif ?? this.tileMotif,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tileColor.present) {
      map['tile_color'] = Variable<String>(tileColor.value);
    }
    if (tileMotif.present) {
      map['tile_motif'] = Variable<String>(tileMotif.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('tileColor: $tileColor, ')
          ..write('tileMotif: $tileMotif, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES folders (id) ON DELETE SET NULL'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aboutMeta = const VerificationMeta('about');
  @override
  late final GeneratedColumn<String> about = GeneratedColumn<String>(
      'about', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _prepMinutesMeta =
      const VerificationMeta('prepMinutes');
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
      'prep_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cookMinutesMeta =
      const VerificationMeta('cookMinutes');
  @override
  late final GeneratedColumn<int> cookMinutes = GeneratedColumn<int>(
      'cook_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _servingsMeta =
      const VerificationMeta('servings');
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
      'servings', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageSyncedPathMeta =
      const VerificationMeta('imageSyncedPath');
  @override
  late final GeneratedColumn<String> imageSyncedPath = GeneratedColumn<String>(
      'image_synced_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceUrlMeta =
      const VerificationMeta('sourceUrl');
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
      'source_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tileColorMeta =
      const VerificationMeta('tileColor');
  @override
  late final GeneratedColumn<String> tileColor = GeneratedColumn<String>(
      'tile_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tileMotifMeta =
      const VerificationMeta('tileMotif');
  @override
  late final GeneratedColumn<String> tileMotif = GeneratedColumn<String>(
      'tile_motif', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        folderId,
        name,
        about,
        prepMinutes,
        cookMinutes,
        servings,
        imagePath,
        imageSyncedPath,
        sourceUrl,
        notes,
        tileColor,
        tileMotif,
        isFavorite,
        createdAt,
        updatedAt,
        deletedAt,
        lastOpenedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('about')) {
      context.handle(
          _aboutMeta, about.isAcceptableOrUnknown(data['about']!, _aboutMeta));
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
          _prepMinutesMeta,
          prepMinutes.isAcceptableOrUnknown(
              data['prep_minutes']!, _prepMinutesMeta));
    }
    if (data.containsKey('cook_minutes')) {
      context.handle(
          _cookMinutesMeta,
          cookMinutes.isAcceptableOrUnknown(
              data['cook_minutes']!, _cookMinutesMeta));
    }
    if (data.containsKey('servings')) {
      context.handle(_servingsMeta,
          servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('image_synced_path')) {
      context.handle(
          _imageSyncedPathMeta,
          imageSyncedPath.isAcceptableOrUnknown(
              data['image_synced_path']!, _imageSyncedPathMeta));
    }
    if (data.containsKey('source_url')) {
      context.handle(_sourceUrlMeta,
          sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('tile_color')) {
      context.handle(_tileColorMeta,
          tileColor.isAcceptableOrUnknown(data['tile_color']!, _tileColorMeta));
    }
    if (data.containsKey('tile_motif')) {
      context.handle(_tileMotifMeta,
          tileMotif.isAcceptableOrUnknown(data['tile_motif']!, _tileMotifMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      about: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}about']),
      prepMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prep_minutes']),
      cookMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cook_minutes']),
      servings: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}servings']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      imageSyncedPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_synced_path']),
      sourceUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_url']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      tileColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tile_color']),
      tileMotif: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tile_motif']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      lastOpenedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_opened_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class RecipeRow extends DataClass implements Insertable<RecipeRow> {
  final String id;
  final String? folderId;
  final String name;
  final String? about;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? servings;
  final String? imagePath;

  /// Nome da foto que já foi enviada pro Storage. Diferente de `imagePath` =
  /// há o que enviar (foto nova/trocada) ou o que apagar na nuvem (trocada
  /// ou removida). Nulo = nada enviado.
  final String? imageSyncedPath;
  final String? sourceUrl;
  final String? notes;

  /// Cor e módulo do azulejo escolhidos (§9.4). Nulo = deriva do id, como
  /// sempre. Guardados como o `.name` do enum.
  final String? tileColor;
  final String? tileMotif;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Último acesso — criação ou abertura (§ "recentes" da home). Ver o
  /// comentário equivalente em `Folders`.
  final DateTime? lastOpenedAt;

  /// O `updated_at` que a receita tinha quando foi sincronizada com a conta
  /// (H3). Nulo ou menor que `updated_at` = mudou desde então e precisa subir.
  /// Abrir a receita (`last_opened_at`) e marcar a foto como enviada não mexem
  /// em `updated_at`, então não contam como mudança.
  final DateTime? syncedAt;
  const RecipeRow(
      {required this.id,
      this.folderId,
      required this.name,
      this.about,
      this.prepMinutes,
      this.cookMinutes,
      this.servings,
      this.imagePath,
      this.imageSyncedPath,
      this.sourceUrl,
      this.notes,
      this.tileColor,
      this.tileMotif,
      required this.isFavorite,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      this.lastOpenedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || about != null) {
      map['about'] = Variable<String>(about);
    }
    if (!nullToAbsent || prepMinutes != null) {
      map['prep_minutes'] = Variable<int>(prepMinutes);
    }
    if (!nullToAbsent || cookMinutes != null) {
      map['cook_minutes'] = Variable<int>(cookMinutes);
    }
    if (!nullToAbsent || servings != null) {
      map['servings'] = Variable<int>(servings);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || imageSyncedPath != null) {
      map['image_synced_path'] = Variable<String>(imageSyncedPath);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || tileColor != null) {
      map['tile_color'] = Variable<String>(tileColor);
    }
    if (!nullToAbsent || tileMotif != null) {
      map['tile_motif'] = Variable<String>(tileMotif);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      name: Value(name),
      about:
          about == null && nullToAbsent ? const Value.absent() : Value(about),
      prepMinutes: prepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(prepMinutes),
      cookMinutes: cookMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(cookMinutes),
      servings: servings == null && nullToAbsent
          ? const Value.absent()
          : Value(servings),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      imageSyncedPath: imageSyncedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageSyncedPath),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      tileColor: tileColor == null && nullToAbsent
          ? const Value.absent()
          : Value(tileColor),
      tileMotif: tileMotif == null && nullToAbsent
          ? const Value.absent()
          : Value(tileMotif),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory RecipeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeRow(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      name: serializer.fromJson<String>(json['name']),
      about: serializer.fromJson<String?>(json['about']),
      prepMinutes: serializer.fromJson<int?>(json['prepMinutes']),
      cookMinutes: serializer.fromJson<int?>(json['cookMinutes']),
      servings: serializer.fromJson<int?>(json['servings']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      imageSyncedPath: serializer.fromJson<String?>(json['imageSyncedPath']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      notes: serializer.fromJson<String?>(json['notes']),
      tileColor: serializer.fromJson<String?>(json['tileColor']),
      tileMotif: serializer.fromJson<String?>(json['tileMotif']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String?>(folderId),
      'name': serializer.toJson<String>(name),
      'about': serializer.toJson<String?>(about),
      'prepMinutes': serializer.toJson<int?>(prepMinutes),
      'cookMinutes': serializer.toJson<int?>(cookMinutes),
      'servings': serializer.toJson<int?>(servings),
      'imagePath': serializer.toJson<String?>(imagePath),
      'imageSyncedPath': serializer.toJson<String?>(imageSyncedPath),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'notes': serializer.toJson<String?>(notes),
      'tileColor': serializer.toJson<String?>(tileColor),
      'tileMotif': serializer.toJson<String?>(tileMotif),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  RecipeRow copyWith(
          {String? id,
          Value<String?> folderId = const Value.absent(),
          String? name,
          Value<String?> about = const Value.absent(),
          Value<int?> prepMinutes = const Value.absent(),
          Value<int?> cookMinutes = const Value.absent(),
          Value<int?> servings = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          Value<String?> imageSyncedPath = const Value.absent(),
          Value<String?> sourceUrl = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> tileColor = const Value.absent(),
          Value<String?> tileMotif = const Value.absent(),
          bool? isFavorite,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<DateTime?> lastOpenedAt = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      RecipeRow(
        id: id ?? this.id,
        folderId: folderId.present ? folderId.value : this.folderId,
        name: name ?? this.name,
        about: about.present ? about.value : this.about,
        prepMinutes: prepMinutes.present ? prepMinutes.value : this.prepMinutes,
        cookMinutes: cookMinutes.present ? cookMinutes.value : this.cookMinutes,
        servings: servings.present ? servings.value : this.servings,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        imageSyncedPath: imageSyncedPath.present
            ? imageSyncedPath.value
            : this.imageSyncedPath,
        sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
        notes: notes.present ? notes.value : this.notes,
        tileColor: tileColor.present ? tileColor.value : this.tileColor,
        tileMotif: tileMotif.present ? tileMotif.value : this.tileMotif,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  RecipeRow copyWithCompanion(RecipesCompanion data) {
    return RecipeRow(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      name: data.name.present ? data.name.value : this.name,
      about: data.about.present ? data.about.value : this.about,
      prepMinutes:
          data.prepMinutes.present ? data.prepMinutes.value : this.prepMinutes,
      cookMinutes:
          data.cookMinutes.present ? data.cookMinutes.value : this.cookMinutes,
      servings: data.servings.present ? data.servings.value : this.servings,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imageSyncedPath: data.imageSyncedPath.present
          ? data.imageSyncedPath.value
          : this.imageSyncedPath,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      notes: data.notes.present ? data.notes.value : this.notes,
      tileColor: data.tileColor.present ? data.tileColor.value : this.tileColor,
      tileMotif: data.tileMotif.present ? data.tileMotif.value : this.tileMotif,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeRow(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('name: $name, ')
          ..write('about: $about, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('servings: $servings, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageSyncedPath: $imageSyncedPath, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('notes: $notes, ')
          ..write('tileColor: $tileColor, ')
          ..write('tileMotif: $tileMotif, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      folderId,
      name,
      about,
      prepMinutes,
      cookMinutes,
      servings,
      imagePath,
      imageSyncedPath,
      sourceUrl,
      notes,
      tileColor,
      tileMotif,
      isFavorite,
      createdAt,
      updatedAt,
      deletedAt,
      lastOpenedAt,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeRow &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.name == this.name &&
          other.about == this.about &&
          other.prepMinutes == this.prepMinutes &&
          other.cookMinutes == this.cookMinutes &&
          other.servings == this.servings &&
          other.imagePath == this.imagePath &&
          other.imageSyncedPath == this.imageSyncedPath &&
          other.sourceUrl == this.sourceUrl &&
          other.notes == this.notes &&
          other.tileColor == this.tileColor &&
          other.tileMotif == this.tileMotif &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.syncedAt == this.syncedAt);
}

class RecipesCompanion extends UpdateCompanion<RecipeRow> {
  final Value<String> id;
  final Value<String?> folderId;
  final Value<String> name;
  final Value<String?> about;
  final Value<int?> prepMinutes;
  final Value<int?> cookMinutes;
  final Value<int?> servings;
  final Value<String?> imagePath;
  final Value<String?> imageSyncedPath;
  final Value<String?> sourceUrl;
  final Value<String?> notes;
  final Value<String?> tileColor;
  final Value<String?> tileMotif;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.name = const Value.absent(),
    this.about = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.servings = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageSyncedPath = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.tileColor = const Value.absent(),
    this.tileMotif = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    this.folderId = const Value.absent(),
    required String name,
    this.about = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.servings = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageSyncedPath = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.tileColor = const Value.absent(),
    this.tileMotif = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<RecipeRow> custom({
    Expression<String>? id,
    Expression<String>? folderId,
    Expression<String>? name,
    Expression<String>? about,
    Expression<int>? prepMinutes,
    Expression<int>? cookMinutes,
    Expression<int>? servings,
    Expression<String>? imagePath,
    Expression<String>? imageSyncedPath,
    Expression<String>? sourceUrl,
    Expression<String>? notes,
    Expression<String>? tileColor,
    Expression<String>? tileMotif,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (name != null) 'name': name,
      if (about != null) 'about': about,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (cookMinutes != null) 'cook_minutes': cookMinutes,
      if (servings != null) 'servings': servings,
      if (imagePath != null) 'image_path': imagePath,
      if (imageSyncedPath != null) 'image_synced_path': imageSyncedPath,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (notes != null) 'notes': notes,
      if (tileColor != null) 'tile_color': tileColor,
      if (tileMotif != null) 'tile_motif': tileMotif,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? folderId,
      Value<String>? name,
      Value<String?>? about,
      Value<int?>? prepMinutes,
      Value<int?>? cookMinutes,
      Value<int?>? servings,
      Value<String?>? imagePath,
      Value<String?>? imageSyncedPath,
      Value<String?>? sourceUrl,
      Value<String?>? notes,
      Value<String?>? tileColor,
      Value<String?>? tileMotif,
      Value<bool>? isFavorite,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<DateTime?>? lastOpenedAt,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return RecipesCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      about: about ?? this.about,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      servings: servings ?? this.servings,
      imagePath: imagePath ?? this.imagePath,
      imageSyncedPath: imageSyncedPath ?? this.imageSyncedPath,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      notes: notes ?? this.notes,
      tileColor: tileColor ?? this.tileColor,
      tileMotif: tileMotif ?? this.tileMotif,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (about.present) {
      map['about'] = Variable<String>(about.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (cookMinutes.present) {
      map['cook_minutes'] = Variable<int>(cookMinutes.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imageSyncedPath.present) {
      map['image_synced_path'] = Variable<String>(imageSyncedPath.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tileColor.present) {
      map['tile_color'] = Variable<String>(tileColor.value);
    }
    if (tileMotif.present) {
      map['tile_motif'] = Variable<String>(tileMotif.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('name: $name, ')
          ..write('about: $about, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('servings: $servings, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageSyncedPath: $imageSyncedPath, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('notes: $notes, ')
          ..write('tileColor: $tileColor, ')
          ..write('tileMotif: $tileMotif, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final int sortOrder;
  const CategoryRow(
      {required this.id, required this.name, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryRow copyWith({String? id, String? name, int? sortOrder}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required int sortOrder,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        sortOrder = Value(sortOrder);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, IngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedKeyMeta =
      const VerificationMeta('normalizedKey');
  @override
  late final GeneratedColumn<String> normalizedKey = GeneratedColumn<String>(
      'normalized_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _usageCountMeta =
      const VerificationMeta('usageCount');
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
      'usage_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _inPantryMeta =
      const VerificationMeta('inPantry');
  @override
  late final GeneratedColumn<bool> inPantry = GeneratedColumn<bool>(
      'in_pantry', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("in_pantry" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pantryUpdatedAtMeta =
      const VerificationMeta('pantryUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> pantryUpdatedAt =
      GeneratedColumn<DateTime>('pantry_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pantrySyncedAtMeta =
      const VerificationMeta('pantrySyncedAt');
  @override
  late final GeneratedColumn<DateTime> pantrySyncedAt =
      GeneratedColumn<DateTime>('pantry_synced_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _priceCentsMeta =
      const VerificationMeta('priceCents');
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
      'price_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _priceBasisMeta =
      const VerificationMeta('priceBasis');
  @override
  late final GeneratedColumn<String> priceBasis = GeneratedColumn<String>(
      'price_basis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceQtyMeta =
      const VerificationMeta('priceQty');
  @override
  late final GeneratedColumn<double> priceQty = GeneratedColumn<double>(
      'price_qty', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        displayName,
        normalizedKey,
        categoryId,
        usageCount,
        inPantry,
        pantryUpdatedAt,
        pantrySyncedAt,
        priceCents,
        priceBasis,
        priceQty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('normalized_key')) {
      context.handle(
          _normalizedKeyMeta,
          normalizedKey.isAcceptableOrUnknown(
              data['normalized_key']!, _normalizedKeyMeta));
    } else if (isInserting) {
      context.missing(_normalizedKeyMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('usage_count')) {
      context.handle(
          _usageCountMeta,
          usageCount.isAcceptableOrUnknown(
              data['usage_count']!, _usageCountMeta));
    }
    if (data.containsKey('in_pantry')) {
      context.handle(_inPantryMeta,
          inPantry.isAcceptableOrUnknown(data['in_pantry']!, _inPantryMeta));
    }
    if (data.containsKey('pantry_updated_at')) {
      context.handle(
          _pantryUpdatedAtMeta,
          pantryUpdatedAt.isAcceptableOrUnknown(
              data['pantry_updated_at']!, _pantryUpdatedAtMeta));
    }
    if (data.containsKey('pantry_synced_at')) {
      context.handle(
          _pantrySyncedAtMeta,
          pantrySyncedAt.isAcceptableOrUnknown(
              data['pantry_synced_at']!, _pantrySyncedAtMeta));
    }
    if (data.containsKey('price_cents')) {
      context.handle(
          _priceCentsMeta,
          priceCents.isAcceptableOrUnknown(
              data['price_cents']!, _priceCentsMeta));
    }
    if (data.containsKey('price_basis')) {
      context.handle(
          _priceBasisMeta,
          priceBasis.isAcceptableOrUnknown(
              data['price_basis']!, _priceBasisMeta));
    }
    if (data.containsKey('price_qty')) {
      context.handle(_priceQtyMeta,
          priceQty.isAcceptableOrUnknown(data['price_qty']!, _priceQtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      normalizedKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}normalized_key'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      usageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usage_count'])!,
      inPantry: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}in_pantry'])!,
      pantryUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}pantry_updated_at']),
      pantrySyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}pantry_synced_at']),
      priceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_cents']),
      priceBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_basis']),
      priceQty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_qty']),
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class IngredientRow extends DataClass implements Insertable<IngredientRow> {
  final String id;
  final String displayName;
  final String normalizedKey;
  final String? categoryId;
  final int usageCount;

  /// "Sempre tenho" (G11): ingrediente da despensa, que não entra nas listas
  /// de compras geradas.
  final bool inPantry;

  /// Quando `in_pantry` mudou pela última vez (um gatilho do banco preenche) e
  /// o valor que já foi sincronizado com a conta (H4). Nulo = a despensa nunca
  /// foi mexida neste ingrediente, não há o que sincronizar.
  final DateTime? pantryUpdatedAt;
  final DateTime? pantrySyncedAt;

  /// Preço informado pela pessoa: [priceCents] centavos por [priceQty] da
  /// unidade [priceBasis] (código de `units`: `kg`, `g`, `l`, `ml`, `unidade`,
  /// `dente`, `maco`...). "R$ 4,50 por 500 g" = 450 / 500 / `g`. Nulo = não
  /// informado; [priceQty] nulo vale 1. Só local: não sincroniza.
  final int? priceCents;
  final String? priceBasis;
  final double? priceQty;
  const IngredientRow(
      {required this.id,
      required this.displayName,
      required this.normalizedKey,
      this.categoryId,
      required this.usageCount,
      required this.inPantry,
      this.pantryUpdatedAt,
      this.pantrySyncedAt,
      this.priceCents,
      this.priceBasis,
      this.priceQty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['normalized_key'] = Variable<String>(normalizedKey);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['usage_count'] = Variable<int>(usageCount);
    map['in_pantry'] = Variable<bool>(inPantry);
    if (!nullToAbsent || pantryUpdatedAt != null) {
      map['pantry_updated_at'] = Variable<DateTime>(pantryUpdatedAt);
    }
    if (!nullToAbsent || pantrySyncedAt != null) {
      map['pantry_synced_at'] = Variable<DateTime>(pantrySyncedAt);
    }
    if (!nullToAbsent || priceCents != null) {
      map['price_cents'] = Variable<int>(priceCents);
    }
    if (!nullToAbsent || priceBasis != null) {
      map['price_basis'] = Variable<String>(priceBasis);
    }
    if (!nullToAbsent || priceQty != null) {
      map['price_qty'] = Variable<double>(priceQty);
    }
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      normalizedKey: Value(normalizedKey),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      usageCount: Value(usageCount),
      inPantry: Value(inPantry),
      pantryUpdatedAt: pantryUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pantryUpdatedAt),
      pantrySyncedAt: pantrySyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pantrySyncedAt),
      priceCents: priceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCents),
      priceBasis: priceBasis == null && nullToAbsent
          ? const Value.absent()
          : Value(priceBasis),
      priceQty: priceQty == null && nullToAbsent
          ? const Value.absent()
          : Value(priceQty),
    );
  }

  factory IngredientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      normalizedKey: serializer.fromJson<String>(json['normalizedKey']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      inPantry: serializer.fromJson<bool>(json['inPantry']),
      pantryUpdatedAt: serializer.fromJson<DateTime?>(json['pantryUpdatedAt']),
      pantrySyncedAt: serializer.fromJson<DateTime?>(json['pantrySyncedAt']),
      priceCents: serializer.fromJson<int?>(json['priceCents']),
      priceBasis: serializer.fromJson<String?>(json['priceBasis']),
      priceQty: serializer.fromJson<double?>(json['priceQty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'normalizedKey': serializer.toJson<String>(normalizedKey),
      'categoryId': serializer.toJson<String?>(categoryId),
      'usageCount': serializer.toJson<int>(usageCount),
      'inPantry': serializer.toJson<bool>(inPantry),
      'pantryUpdatedAt': serializer.toJson<DateTime?>(pantryUpdatedAt),
      'pantrySyncedAt': serializer.toJson<DateTime?>(pantrySyncedAt),
      'priceCents': serializer.toJson<int?>(priceCents),
      'priceBasis': serializer.toJson<String?>(priceBasis),
      'priceQty': serializer.toJson<double?>(priceQty),
    };
  }

  IngredientRow copyWith(
          {String? id,
          String? displayName,
          String? normalizedKey,
          Value<String?> categoryId = const Value.absent(),
          int? usageCount,
          bool? inPantry,
          Value<DateTime?> pantryUpdatedAt = const Value.absent(),
          Value<DateTime?> pantrySyncedAt = const Value.absent(),
          Value<int?> priceCents = const Value.absent(),
          Value<String?> priceBasis = const Value.absent(),
          Value<double?> priceQty = const Value.absent()}) =>
      IngredientRow(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        normalizedKey: normalizedKey ?? this.normalizedKey,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        usageCount: usageCount ?? this.usageCount,
        inPantry: inPantry ?? this.inPantry,
        pantryUpdatedAt: pantryUpdatedAt.present
            ? pantryUpdatedAt.value
            : this.pantryUpdatedAt,
        pantrySyncedAt:
            pantrySyncedAt.present ? pantrySyncedAt.value : this.pantrySyncedAt,
        priceCents: priceCents.present ? priceCents.value : this.priceCents,
        priceBasis: priceBasis.present ? priceBasis.value : this.priceBasis,
        priceQty: priceQty.present ? priceQty.value : this.priceQty,
      );
  IngredientRow copyWithCompanion(IngredientsCompanion data) {
    return IngredientRow(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      normalizedKey: data.normalizedKey.present
          ? data.normalizedKey.value
          : this.normalizedKey,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      usageCount:
          data.usageCount.present ? data.usageCount.value : this.usageCount,
      inPantry: data.inPantry.present ? data.inPantry.value : this.inPantry,
      pantryUpdatedAt: data.pantryUpdatedAt.present
          ? data.pantryUpdatedAt.value
          : this.pantryUpdatedAt,
      pantrySyncedAt: data.pantrySyncedAt.present
          ? data.pantrySyncedAt.value
          : this.pantrySyncedAt,
      priceCents:
          data.priceCents.present ? data.priceCents.value : this.priceCents,
      priceBasis:
          data.priceBasis.present ? data.priceBasis.value : this.priceBasis,
      priceQty: data.priceQty.present ? data.priceQty.value : this.priceQty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('normalizedKey: $normalizedKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('usageCount: $usageCount, ')
          ..write('inPantry: $inPantry, ')
          ..write('pantryUpdatedAt: $pantryUpdatedAt, ')
          ..write('pantrySyncedAt: $pantrySyncedAt, ')
          ..write('priceCents: $priceCents, ')
          ..write('priceBasis: $priceBasis, ')
          ..write('priceQty: $priceQty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      displayName,
      normalizedKey,
      categoryId,
      usageCount,
      inPantry,
      pantryUpdatedAt,
      pantrySyncedAt,
      priceCents,
      priceBasis,
      priceQty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.normalizedKey == this.normalizedKey &&
          other.categoryId == this.categoryId &&
          other.usageCount == this.usageCount &&
          other.inPantry == this.inPantry &&
          other.pantryUpdatedAt == this.pantryUpdatedAt &&
          other.pantrySyncedAt == this.pantrySyncedAt &&
          other.priceCents == this.priceCents &&
          other.priceBasis == this.priceBasis &&
          other.priceQty == this.priceQty);
}

class IngredientsCompanion extends UpdateCompanion<IngredientRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> normalizedKey;
  final Value<String?> categoryId;
  final Value<int> usageCount;
  final Value<bool> inPantry;
  final Value<DateTime?> pantryUpdatedAt;
  final Value<DateTime?> pantrySyncedAt;
  final Value<int?> priceCents;
  final Value<String?> priceBasis;
  final Value<double?> priceQty;
  final Value<int> rowid;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.normalizedKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.inPantry = const Value.absent(),
    this.pantryUpdatedAt = const Value.absent(),
    this.pantrySyncedAt = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.priceBasis = const Value.absent(),
    this.priceQty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsCompanion.insert({
    required String id,
    required String displayName,
    required String normalizedKey,
    this.categoryId = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.inPantry = const Value.absent(),
    this.pantryUpdatedAt = const Value.absent(),
    this.pantrySyncedAt = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.priceBasis = const Value.absent(),
    this.priceQty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        displayName = Value(displayName),
        normalizedKey = Value(normalizedKey);
  static Insertable<IngredientRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? normalizedKey,
    Expression<String>? categoryId,
    Expression<int>? usageCount,
    Expression<bool>? inPantry,
    Expression<DateTime>? pantryUpdatedAt,
    Expression<DateTime>? pantrySyncedAt,
    Expression<int>? priceCents,
    Expression<String>? priceBasis,
    Expression<double>? priceQty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (normalizedKey != null) 'normalized_key': normalizedKey,
      if (categoryId != null) 'category_id': categoryId,
      if (usageCount != null) 'usage_count': usageCount,
      if (inPantry != null) 'in_pantry': inPantry,
      if (pantryUpdatedAt != null) 'pantry_updated_at': pantryUpdatedAt,
      if (pantrySyncedAt != null) 'pantry_synced_at': pantrySyncedAt,
      if (priceCents != null) 'price_cents': priceCents,
      if (priceBasis != null) 'price_basis': priceBasis,
      if (priceQty != null) 'price_qty': priceQty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? displayName,
      Value<String>? normalizedKey,
      Value<String?>? categoryId,
      Value<int>? usageCount,
      Value<bool>? inPantry,
      Value<DateTime?>? pantryUpdatedAt,
      Value<DateTime?>? pantrySyncedAt,
      Value<int?>? priceCents,
      Value<String?>? priceBasis,
      Value<double?>? priceQty,
      Value<int>? rowid}) {
    return IngredientsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      normalizedKey: normalizedKey ?? this.normalizedKey,
      categoryId: categoryId ?? this.categoryId,
      usageCount: usageCount ?? this.usageCount,
      inPantry: inPantry ?? this.inPantry,
      pantryUpdatedAt: pantryUpdatedAt ?? this.pantryUpdatedAt,
      pantrySyncedAt: pantrySyncedAt ?? this.pantrySyncedAt,
      priceCents: priceCents ?? this.priceCents,
      priceBasis: priceBasis ?? this.priceBasis,
      priceQty: priceQty ?? this.priceQty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (normalizedKey.present) {
      map['normalized_key'] = Variable<String>(normalizedKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (inPantry.present) {
      map['in_pantry'] = Variable<bool>(inPantry.value);
    }
    if (pantryUpdatedAt.present) {
      map['pantry_updated_at'] = Variable<DateTime>(pantryUpdatedAt.value);
    }
    if (pantrySyncedAt.present) {
      map['pantry_synced_at'] = Variable<DateTime>(pantrySyncedAt.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (priceBasis.present) {
      map['price_basis'] = Variable<String>(priceBasis.value);
    }
    if (priceQty.present) {
      map['price_qty'] = Variable<double>(priceQty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('normalizedKey: $normalizedKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('usageCount: $usageCount, ')
          ..write('inPantry: $inPantry, ')
          ..write('pantryUpdatedAt: $pantryUpdatedAt, ')
          ..write('pantrySyncedAt: $pantrySyncedAt, ')
          ..write('priceCents: $priceCents, ')
          ..write('priceBasis: $priceBasis, ')
          ..write('priceQty: $priceQty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientAliasesTable extends IngredientAliases
    with TableInfo<$IngredientAliasesTable, IngredientAliasRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ingredients (id) ON DELETE CASCADE'));
  static const VerificationMeta _normalizedAliasMeta =
      const VerificationMeta('normalizedAlias');
  @override
  late final GeneratedColumn<String> normalizedAlias = GeneratedColumn<String>(
      'normalized_alias', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, ingredientId, normalizedAlias];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_aliases';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientAliasRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('normalized_alias')) {
      context.handle(
          _normalizedAliasMeta,
          normalizedAlias.isAcceptableOrUnknown(
              data['normalized_alias']!, _normalizedAliasMeta));
    } else if (isInserting) {
      context.missing(_normalizedAliasMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientAliasRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientAliasRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredient_id'])!,
      normalizedAlias: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_alias'])!,
    );
  }

  @override
  $IngredientAliasesTable createAlias(String alias) {
    return $IngredientAliasesTable(attachedDatabase, alias);
  }
}

class IngredientAliasRow extends DataClass
    implements Insertable<IngredientAliasRow> {
  final String id;
  final String ingredientId;
  final String normalizedAlias;
  const IngredientAliasRow(
      {required this.id,
      required this.ingredientId,
      required this.normalizedAlias});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['normalized_alias'] = Variable<String>(normalizedAlias);
    return map;
  }

  IngredientAliasesCompanion toCompanion(bool nullToAbsent) {
    return IngredientAliasesCompanion(
      id: Value(id),
      ingredientId: Value(ingredientId),
      normalizedAlias: Value(normalizedAlias),
    );
  }

  factory IngredientAliasRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientAliasRow(
      id: serializer.fromJson<String>(json['id']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      normalizedAlias: serializer.fromJson<String>(json['normalizedAlias']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'normalizedAlias': serializer.toJson<String>(normalizedAlias),
    };
  }

  IngredientAliasRow copyWith(
          {String? id, String? ingredientId, String? normalizedAlias}) =>
      IngredientAliasRow(
        id: id ?? this.id,
        ingredientId: ingredientId ?? this.ingredientId,
        normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      );
  IngredientAliasRow copyWithCompanion(IngredientAliasesCompanion data) {
    return IngredientAliasRow(
      id: data.id.present ? data.id.value : this.id,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      normalizedAlias: data.normalizedAlias.present
          ? data.normalizedAlias.value
          : this.normalizedAlias,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientAliasRow(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('normalizedAlias: $normalizedAlias')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ingredientId, normalizedAlias);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientAliasRow &&
          other.id == this.id &&
          other.ingredientId == this.ingredientId &&
          other.normalizedAlias == this.normalizedAlias);
}

class IngredientAliasesCompanion extends UpdateCompanion<IngredientAliasRow> {
  final Value<String> id;
  final Value<String> ingredientId;
  final Value<String> normalizedAlias;
  final Value<int> rowid;
  const IngredientAliasesCompanion({
    this.id = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.normalizedAlias = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientAliasesCompanion.insert({
    required String id,
    required String ingredientId,
    required String normalizedAlias,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ingredientId = Value(ingredientId),
        normalizedAlias = Value(normalizedAlias);
  static Insertable<IngredientAliasRow> custom({
    Expression<String>? id,
    Expression<String>? ingredientId,
    Expression<String>? normalizedAlias,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (normalizedAlias != null) 'normalized_alias': normalizedAlias,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientAliasesCompanion copyWith(
      {Value<String>? id,
      Value<String>? ingredientId,
      Value<String>? normalizedAlias,
      Value<int>? rowid}) {
    return IngredientAliasesCompanion(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (normalizedAlias.present) {
      map['normalized_alias'] = Variable<String>(normalizedAlias.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientAliasesCompanion(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, UnitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pluralMeta = const VerificationMeta('plural');
  @override
  late final GeneratedColumn<String> plural = GeneratedColumn<String>(
      'plural', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUnitIdMeta =
      const VerificationMeta('baseUnitId');
  @override
  late final GeneratedColumn<String> baseUnitId = GeneratedColumn<String>(
      'base_unit_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL REFERENCES units (id)');
  static const VerificationMeta _factorToBaseMeta =
      const VerificationMeta('factorToBase');
  @override
  late final GeneratedColumn<double> factorToBase = GeneratedColumn<double>(
      'factor_to_base', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, displayName, plural, kind, baseUnitId, factorToBase];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<UnitRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('plural')) {
      context.handle(_pluralMeta,
          plural.isAcceptableOrUnknown(data['plural']!, _pluralMeta));
    } else if (isInserting) {
      context.missing(_pluralMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('base_unit_id')) {
      context.handle(
          _baseUnitIdMeta,
          baseUnitId.isAcceptableOrUnknown(
              data['base_unit_id']!, _baseUnitIdMeta));
    }
    if (data.containsKey('factor_to_base')) {
      context.handle(
          _factorToBaseMeta,
          factorToBase.isAcceptableOrUnknown(
              data['factor_to_base']!, _factorToBaseMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      plural: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plural'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      baseUnitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_unit_id']),
      factorToBase: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}factor_to_base']),
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class UnitRow extends DataClass implements Insertable<UnitRow> {
  final String id;
  final String code;
  final String displayName;
  final String plural;
  final String kind;
  final String? baseUnitId;
  final double? factorToBase;
  const UnitRow(
      {required this.id,
      required this.code,
      required this.displayName,
      required this.plural,
      required this.kind,
      this.baseUnitId,
      this.factorToBase});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['display_name'] = Variable<String>(displayName);
    map['plural'] = Variable<String>(plural);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || baseUnitId != null) {
      map['base_unit_id'] = Variable<String>(baseUnitId);
    }
    if (!nullToAbsent || factorToBase != null) {
      map['factor_to_base'] = Variable<double>(factorToBase);
    }
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      code: Value(code),
      displayName: Value(displayName),
      plural: Value(plural),
      kind: Value(kind),
      baseUnitId: baseUnitId == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUnitId),
      factorToBase: factorToBase == null && nullToAbsent
          ? const Value.absent()
          : Value(factorToBase),
    );
  }

  factory UnitRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      displayName: serializer.fromJson<String>(json['displayName']),
      plural: serializer.fromJson<String>(json['plural']),
      kind: serializer.fromJson<String>(json['kind']),
      baseUnitId: serializer.fromJson<String?>(json['baseUnitId']),
      factorToBase: serializer.fromJson<double?>(json['factorToBase']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'displayName': serializer.toJson<String>(displayName),
      'plural': serializer.toJson<String>(plural),
      'kind': serializer.toJson<String>(kind),
      'baseUnitId': serializer.toJson<String?>(baseUnitId),
      'factorToBase': serializer.toJson<double?>(factorToBase),
    };
  }

  UnitRow copyWith(
          {String? id,
          String? code,
          String? displayName,
          String? plural,
          String? kind,
          Value<String?> baseUnitId = const Value.absent(),
          Value<double?> factorToBase = const Value.absent()}) =>
      UnitRow(
        id: id ?? this.id,
        code: code ?? this.code,
        displayName: displayName ?? this.displayName,
        plural: plural ?? this.plural,
        kind: kind ?? this.kind,
        baseUnitId: baseUnitId.present ? baseUnitId.value : this.baseUnitId,
        factorToBase:
            factorToBase.present ? factorToBase.value : this.factorToBase,
      );
  UnitRow copyWithCompanion(UnitsCompanion data) {
    return UnitRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      plural: data.plural.present ? data.plural.value : this.plural,
      kind: data.kind.present ? data.kind.value : this.kind,
      baseUnitId:
          data.baseUnitId.present ? data.baseUnitId.value : this.baseUnitId,
      factorToBase: data.factorToBase.present
          ? data.factorToBase.value
          : this.factorToBase,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('displayName: $displayName, ')
          ..write('plural: $plural, ')
          ..write('kind: $kind, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('factorToBase: $factorToBase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, code, displayName, plural, kind, baseUnitId, factorToBase);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.displayName == this.displayName &&
          other.plural == this.plural &&
          other.kind == this.kind &&
          other.baseUnitId == this.baseUnitId &&
          other.factorToBase == this.factorToBase);
}

class UnitsCompanion extends UpdateCompanion<UnitRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> displayName;
  final Value<String> plural;
  final Value<String> kind;
  final Value<String?> baseUnitId;
  final Value<double?> factorToBase;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.displayName = const Value.absent(),
    this.plural = const Value.absent(),
    this.kind = const Value.absent(),
    this.baseUnitId = const Value.absent(),
    this.factorToBase = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String code,
    required String displayName,
    required String plural,
    required String kind,
    this.baseUnitId = const Value.absent(),
    this.factorToBase = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        displayName = Value(displayName),
        plural = Value(plural),
        kind = Value(kind);
  static Insertable<UnitRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? displayName,
    Expression<String>? plural,
    Expression<String>? kind,
    Expression<String>? baseUnitId,
    Expression<double>? factorToBase,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (displayName != null) 'display_name': displayName,
      if (plural != null) 'plural': plural,
      if (kind != null) 'kind': kind,
      if (baseUnitId != null) 'base_unit_id': baseUnitId,
      if (factorToBase != null) 'factor_to_base': factorToBase,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? displayName,
      Value<String>? plural,
      Value<String>? kind,
      Value<String?>? baseUnitId,
      Value<double?>? factorToBase,
      Value<int>? rowid}) {
    return UnitsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      displayName: displayName ?? this.displayName,
      plural: plural ?? this.plural,
      kind: kind ?? this.kind,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      factorToBase: factorToBase ?? this.factorToBase,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (plural.present) {
      map['plural'] = Variable<String>(plural.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (baseUnitId.present) {
      map['base_unit_id'] = Variable<String>(baseUnitId.value);
    }
    if (factorToBase.present) {
      map['factor_to_base'] = Variable<double>(factorToBase.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('displayName: $displayName, ')
          ..write('plural: $plural, ')
          ..write('kind: $kind, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('factorToBase: $factorToBase, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeIngredientsTable extends RecipeIngredients
    with TableInfo<$RecipeIngredientsTable, RecipeIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
      'ingredient_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ingredients (id) ON DELETE RESTRICT'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES units (id) ON DELETE SET NULL'));
  static const VerificationMeta _qualifierMeta =
      const VerificationMeta('qualifier');
  @override
  late final GeneratedColumn<String> qualifier = GeneratedColumn<String>(
      'qualifier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawTextMeta =
      const VerificationMeta('rawText');
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
      'raw_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupLabelMeta =
      const VerificationMeta('groupLabel');
  @override
  late final GeneratedColumn<String> groupLabel = GeneratedColumn<String>(
      'group_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recipeId,
        ingredientId,
        quantity,
        unitId,
        qualifier,
        rawText,
        groupLabel,
        position
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecipeIngredientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('qualifier')) {
      context.handle(_qualifierMeta,
          qualifier.isAcceptableOrUnknown(data['qualifier']!, _qualifierMeta));
    }
    if (data.containsKey('raw_text')) {
      context.handle(_rawTextMeta,
          rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta));
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('group_label')) {
      context.handle(
          _groupLabelMeta,
          groupLabel.isAcceptableOrUnknown(
              data['group_label']!, _groupLabelMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredientRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredient_id']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id']),
      qualifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}qualifier']),
      rawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_text'])!,
      groupLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_label']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $RecipeIngredientsTable createAlias(String alias) {
    return $RecipeIngredientsTable(attachedDatabase, alias);
  }
}

class RecipeIngredientRow extends DataClass
    implements Insertable<RecipeIngredientRow> {
  final String id;
  final String recipeId;
  final String? ingredientId;
  final double? quantity;
  final String? unitId;
  final String? qualifier;
  final String rawText;
  final String? groupLabel;
  final int position;
  const RecipeIngredientRow(
      {required this.id,
      required this.recipeId,
      this.ingredientId,
      this.quantity,
      this.unitId,
      this.qualifier,
      required this.rawText,
      this.groupLabel,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    if (!nullToAbsent || ingredientId != null) {
      map['ingredient_id'] = Variable<String>(ingredientId);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || qualifier != null) {
      map['qualifier'] = Variable<String>(qualifier);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || groupLabel != null) {
      map['group_label'] = Variable<String>(groupLabel);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      ingredientId: ingredientId == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredientId),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      qualifier: qualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(qualifier),
      rawText: Value(rawText),
      groupLabel: groupLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(groupLabel),
      position: Value(position),
    );
  }

  factory RecipeIngredientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredientRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      ingredientId: serializer.fromJson<String?>(json['ingredientId']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      qualifier: serializer.fromJson<String?>(json['qualifier']),
      rawText: serializer.fromJson<String>(json['rawText']),
      groupLabel: serializer.fromJson<String?>(json['groupLabel']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'ingredientId': serializer.toJson<String?>(ingredientId),
      'quantity': serializer.toJson<double?>(quantity),
      'unitId': serializer.toJson<String?>(unitId),
      'qualifier': serializer.toJson<String?>(qualifier),
      'rawText': serializer.toJson<String>(rawText),
      'groupLabel': serializer.toJson<String?>(groupLabel),
      'position': serializer.toJson<int>(position),
    };
  }

  RecipeIngredientRow copyWith(
          {String? id,
          String? recipeId,
          Value<String?> ingredientId = const Value.absent(),
          Value<double?> quantity = const Value.absent(),
          Value<String?> unitId = const Value.absent(),
          Value<String?> qualifier = const Value.absent(),
          String? rawText,
          Value<String?> groupLabel = const Value.absent(),
          int? position}) =>
      RecipeIngredientRow(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        ingredientId:
            ingredientId.present ? ingredientId.value : this.ingredientId,
        quantity: quantity.present ? quantity.value : this.quantity,
        unitId: unitId.present ? unitId.value : this.unitId,
        qualifier: qualifier.present ? qualifier.value : this.qualifier,
        rawText: rawText ?? this.rawText,
        groupLabel: groupLabel.present ? groupLabel.value : this.groupLabel,
        position: position ?? this.position,
      );
  RecipeIngredientRow copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredientRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      qualifier: data.qualifier.present ? data.qualifier.value : this.qualifier,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      groupLabel:
          data.groupLabel.present ? data.groupLabel.value : this.groupLabel,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('qualifier: $qualifier, ')
          ..write('rawText: $rawText, ')
          ..write('groupLabel: $groupLabel, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, ingredientId, quantity, unitId,
      qualifier, rawText, groupLabel, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredientRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.ingredientId == this.ingredientId &&
          other.quantity == this.quantity &&
          other.unitId == this.unitId &&
          other.qualifier == this.qualifier &&
          other.rawText == this.rawText &&
          other.groupLabel == this.groupLabel &&
          other.position == this.position);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredientRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String?> ingredientId;
  final Value<double?> quantity;
  final Value<String?> unitId;
  final Value<String?> qualifier;
  final Value<String> rawText;
  final Value<String?> groupLabel;
  final Value<int> position;
  final Value<int> rowid;
  const RecipeIngredientsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.qualifier = const Value.absent(),
    this.rawText = const Value.absent(),
    this.groupLabel = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    required String id,
    required String recipeId,
    this.ingredientId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.qualifier = const Value.absent(),
    required String rawText,
    this.groupLabel = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recipeId = Value(recipeId),
        rawText = Value(rawText);
  static Insertable<RecipeIngredientRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? ingredientId,
    Expression<double>? quantity,
    Expression<String>? unitId,
    Expression<String>? qualifier,
    Expression<String>? rawText,
    Expression<String>? groupLabel,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (quantity != null) 'quantity': quantity,
      if (unitId != null) 'unit_id': unitId,
      if (qualifier != null) 'qualifier': qualifier,
      if (rawText != null) 'raw_text': rawText,
      if (groupLabel != null) 'group_label': groupLabel,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeIngredientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String?>? ingredientId,
      Value<double?>? quantity,
      Value<String?>? unitId,
      Value<String?>? qualifier,
      Value<String>? rawText,
      Value<String?>? groupLabel,
      Value<int>? position,
      Value<int>? rowid}) {
    return RecipeIngredientsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      qualifier: qualifier ?? this.qualifier,
      rawText: rawText ?? this.rawText,
      groupLabel: groupLabel ?? this.groupLabel,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (qualifier.present) {
      map['qualifier'] = Variable<String>(qualifier.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (groupLabel.present) {
      map['group_label'] = Variable<String>(groupLabel.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('qualifier: $qualifier, ')
          ..write('rawText: $rawText, ')
          ..write('groupLabel: $groupLabel, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeStepsTable extends RecipeSteps
    with TableInfo<$RecipeStepsTable, RecipeStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _instructionMeta =
      const VerificationMeta('instruction');
  @override
  late final GeneratedColumn<String> instruction = GeneratedColumn<String>(
      'instruction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupLabelMeta =
      const VerificationMeta('groupLabel');
  @override
  late final GeneratedColumn<String> groupLabel = GeneratedColumn<String>(
      'group_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, recipeId, instruction, groupLabel, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeStepRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('instruction')) {
      context.handle(
          _instructionMeta,
          instruction.isAcceptableOrUnknown(
              data['instruction']!, _instructionMeta));
    } else if (isInserting) {
      context.missing(_instructionMeta);
    }
    if (data.containsKey('group_label')) {
      context.handle(
          _groupLabelMeta,
          groupLabel.isAcceptableOrUnknown(
              data['group_label']!, _groupLabelMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStepRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      instruction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instruction'])!,
      groupLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_label']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $RecipeStepsTable createAlias(String alias) {
    return $RecipeStepsTable(attachedDatabase, alias);
  }
}

class RecipeStepRow extends DataClass implements Insertable<RecipeStepRow> {
  final String id;
  final String recipeId;
  final String instruction;
  final String? groupLabel;
  final int position;
  const RecipeStepRow(
      {required this.id,
      required this.recipeId,
      required this.instruction,
      this.groupLabel,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['instruction'] = Variable<String>(instruction);
    if (!nullToAbsent || groupLabel != null) {
      map['group_label'] = Variable<String>(groupLabel);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      instruction: Value(instruction),
      groupLabel: groupLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(groupLabel),
      position: Value(position),
    );
  }

  factory RecipeStepRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStepRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      instruction: serializer.fromJson<String>(json['instruction']),
      groupLabel: serializer.fromJson<String?>(json['groupLabel']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'instruction': serializer.toJson<String>(instruction),
      'groupLabel': serializer.toJson<String?>(groupLabel),
      'position': serializer.toJson<int>(position),
    };
  }

  RecipeStepRow copyWith(
          {String? id,
          String? recipeId,
          String? instruction,
          Value<String?> groupLabel = const Value.absent(),
          int? position}) =>
      RecipeStepRow(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        instruction: instruction ?? this.instruction,
        groupLabel: groupLabel.present ? groupLabel.value : this.groupLabel,
        position: position ?? this.position,
      );
  RecipeStepRow copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStepRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      instruction:
          data.instruction.present ? data.instruction.value : this.instruction,
      groupLabel:
          data.groupLabel.present ? data.groupLabel.value : this.groupLabel,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('instruction: $instruction, ')
          ..write('groupLabel: $groupLabel, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recipeId, instruction, groupLabel, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStepRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.instruction == this.instruction &&
          other.groupLabel == this.groupLabel &&
          other.position == this.position);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStepRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> instruction;
  final Value<String?> groupLabel;
  final Value<int> position;
  final Value<int> rowid;
  const RecipeStepsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.instruction = const Value.absent(),
    this.groupLabel = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    required String id,
    required String recipeId,
    required String instruction,
    this.groupLabel = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recipeId = Value(recipeId),
        instruction = Value(instruction);
  static Insertable<RecipeStepRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? instruction,
    Expression<String>? groupLabel,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (instruction != null) 'instruction': instruction,
      if (groupLabel != null) 'group_label': groupLabel,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeStepsCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String>? instruction,
      Value<String?>? groupLabel,
      Value<int>? position,
      Value<int>? rowid}) {
    return RecipeStepsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      instruction: instruction ?? this.instruction,
      groupLabel: groupLabel ?? this.groupLabel,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (instruction.present) {
      map['instruction'] = Variable<String>(instruction.value);
    }
    if (groupLabel.present) {
      map['group_label'] = Variable<String>(groupLabel.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('instruction: $instruction, ')
          ..write('groupLabel: $groupLabel, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<TagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final String name;
  const TagRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory TagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TagRow copyWith({String? id, String? name}) => TagRow(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith(
      {Value<String>? id, Value<String>? name, Value<int>? rowid}) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeTagsTable extends RecipeTags
    with TableInfo<$RecipeTagsTable, RecipeTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tags (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [recipeId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_tags';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, tagId};
  @override
  RecipeTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeTagRow(
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $RecipeTagsTable createAlias(String alias) {
    return $RecipeTagsTable(attachedDatabase, alias);
  }
}

class RecipeTagRow extends DataClass implements Insertable<RecipeTagRow> {
  final String recipeId;
  final String tagId;
  const RecipeTagRow({required this.recipeId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  RecipeTagsCompanion toCompanion(bool nullToAbsent) {
    return RecipeTagsCompanion(
      recipeId: Value(recipeId),
      tagId: Value(tagId),
    );
  }

  factory RecipeTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeTagRow(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  RecipeTagRow copyWith({String? recipeId, String? tagId}) => RecipeTagRow(
        recipeId: recipeId ?? this.recipeId,
        tagId: tagId ?? this.tagId,
      );
  RecipeTagRow copyWithCompanion(RecipeTagsCompanion data) {
    return RecipeTagRow(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagRow(')
          ..write('recipeId: $recipeId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeTagRow &&
          other.recipeId == this.recipeId &&
          other.tagId == this.tagId);
}

class RecipeTagsCompanion extends UpdateCompanion<RecipeTagRow> {
  final Value<String> recipeId;
  final Value<String> tagId;
  final Value<int> rowid;
  const RecipeTagsCompanion({
    this.recipeId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeTagsCompanion.insert({
    required String recipeId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : recipeId = Value(recipeId),
        tagId = Value(tagId);
  static Insertable<RecipeTagRow> custom({
    Expression<String>? recipeId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeTagsCompanion copyWith(
      {Value<String>? recipeId, Value<String>? tagId, Value<int>? rowid}) {
    return RecipeTagsCompanion(
      recipeId: recipeId ?? this.recipeId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealPlanEntriesTable extends MealPlanEntries
    with TableInfo<$MealPlanEntriesTable, MealPlanEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlanEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _servingsOverrideMeta =
      const VerificationMeta('servingsOverride');
  @override
  late final GeneratedColumn<int> servingsOverride = GeneratedColumn<int>(
      'servings_override', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
      'done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _spaceIdMeta =
      const VerificationMeta('spaceId');
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
      'space_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recipeId,
        date,
        mealType,
        servingsOverride,
        note,
        done,
        createdAt,
        updatedAt,
        syncedAt,
        spaceId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plan_entries';
  @override
  VerificationContext validateIntegrity(Insertable<MealPlanEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('servings_override')) {
      context.handle(
          _servingsOverrideMeta,
          servingsOverride.isAcceptableOrUnknown(
              data['servings_override']!, _servingsOverrideMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('done')) {
      context.handle(
          _doneMeta, done.isAcceptableOrUnknown(data['done']!, _doneMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('space_id')) {
      context.handle(_spaceIdMeta,
          spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPlanEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlanEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
      servingsOverride: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}servings_override']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      done: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}done'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      spaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}space_id']),
    );
  }

  @override
  $MealPlanEntriesTable createAlias(String alias) {
    return $MealPlanEntriesTable(attachedDatabase, alias);
  }
}

class MealPlanEntryRow extends DataClass
    implements Insertable<MealPlanEntryRow> {
  final String id;
  final String recipeId;
  final DateTime date;
  final String mealType;
  final int? servingsOverride;
  final String? note;
  final bool done;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Versão (`updated_at`) já sincronizada com a conta (H4); ver `Recipes`.
  final DateTime? syncedAt;

  /// Casa (espaço compartilhado) a que a refeição pertence; nulo = só da
  /// pessoa. Quem tem casa sincroniza com ela, não com a conta (v10).
  final String? spaceId;
  const MealPlanEntryRow(
      {required this.id,
      required this.recipeId,
      required this.date,
      required this.mealType,
      this.servingsOverride,
      this.note,
      required this.done,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.spaceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['date'] = Variable<DateTime>(date);
    map['meal_type'] = Variable<String>(mealType);
    if (!nullToAbsent || servingsOverride != null) {
      map['servings_override'] = Variable<int>(servingsOverride);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['done'] = Variable<bool>(done);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || spaceId != null) {
      map['space_id'] = Variable<String>(spaceId);
    }
    return map;
  }

  MealPlanEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealPlanEntriesCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      date: Value(date),
      mealType: Value(mealType),
      servingsOverride: servingsOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(servingsOverride),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      done: Value(done),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      spaceId: spaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(spaceId),
    );
  }

  factory MealPlanEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlanEntryRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      date: serializer.fromJson<DateTime>(json['date']),
      mealType: serializer.fromJson<String>(json['mealType']),
      servingsOverride: serializer.fromJson<int?>(json['servingsOverride']),
      note: serializer.fromJson<String?>(json['note']),
      done: serializer.fromJson<bool>(json['done']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      spaceId: serializer.fromJson<String?>(json['spaceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'date': serializer.toJson<DateTime>(date),
      'mealType': serializer.toJson<String>(mealType),
      'servingsOverride': serializer.toJson<int?>(servingsOverride),
      'note': serializer.toJson<String?>(note),
      'done': serializer.toJson<bool>(done),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'spaceId': serializer.toJson<String?>(spaceId),
    };
  }

  MealPlanEntryRow copyWith(
          {String? id,
          String? recipeId,
          DateTime? date,
          String? mealType,
          Value<int?> servingsOverride = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? done,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<String?> spaceId = const Value.absent()}) =>
      MealPlanEntryRow(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        servingsOverride: servingsOverride.present
            ? servingsOverride.value
            : this.servingsOverride,
        note: note.present ? note.value : this.note,
        done: done ?? this.done,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        spaceId: spaceId.present ? spaceId.value : this.spaceId,
      );
  MealPlanEntryRow copyWithCompanion(MealPlanEntriesCompanion data) {
    return MealPlanEntryRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      date: data.date.present ? data.date.value : this.date,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      servingsOverride: data.servingsOverride.present
          ? data.servingsOverride.value
          : this.servingsOverride,
      note: data.note.present ? data.note.value : this.note,
      done: data.done.present ? data.done.value : this.done,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanEntryRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('servingsOverride: $servingsOverride, ')
          ..write('note: $note, ')
          ..write('done: $done, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('spaceId: $spaceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, date, mealType,
      servingsOverride, note, done, createdAt, updatedAt, syncedAt, spaceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlanEntryRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.date == this.date &&
          other.mealType == this.mealType &&
          other.servingsOverride == this.servingsOverride &&
          other.note == this.note &&
          other.done == this.done &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.spaceId == this.spaceId);
}

class MealPlanEntriesCompanion extends UpdateCompanion<MealPlanEntryRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<DateTime> date;
  final Value<String> mealType;
  final Value<int?> servingsOverride;
  final Value<String?> note;
  final Value<bool> done;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> spaceId;
  final Value<int> rowid;
  const MealPlanEntriesCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.date = const Value.absent(),
    this.mealType = const Value.absent(),
    this.servingsOverride = const Value.absent(),
    this.note = const Value.absent(),
    this.done = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealPlanEntriesCompanion.insert({
    required String id,
    required String recipeId,
    required DateTime date,
    required String mealType,
    this.servingsOverride = const Value.absent(),
    this.note = const Value.absent(),
    this.done = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recipeId = Value(recipeId),
        date = Value(date),
        mealType = Value(mealType);
  static Insertable<MealPlanEntryRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<DateTime>? date,
    Expression<String>? mealType,
    Expression<int>? servingsOverride,
    Expression<String>? note,
    Expression<bool>? done,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? spaceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (servingsOverride != null) 'servings_override': servingsOverride,
      if (note != null) 'note': note,
      if (done != null) 'done': done,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (spaceId != null) 'space_id': spaceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealPlanEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<DateTime>? date,
      Value<String>? mealType,
      Value<int?>? servingsOverride,
      Value<String?>? note,
      Value<bool>? done,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<String?>? spaceId,
      Value<int>? rowid}) {
    return MealPlanEntriesCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      servingsOverride: servingsOverride ?? this.servingsOverride,
      note: note ?? this.note,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      spaceId: spaceId ?? this.spaceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (servingsOverride.present) {
      map['servings_override'] = Variable<int>(servingsOverride.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('servingsOverride: $servingsOverride, ')
          ..write('note: $note, ')
          ..write('done: $done, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('spaceId: $spaceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SharedMealsTable extends SharedMeals
    with TableInfo<$SharedMealsTable, SharedMealRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SharedMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _spaceIdMeta =
      const VerificationMeta('spaceId');
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
      'space_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _servingsOverrideMeta =
      const VerificationMeta('servingsOverride');
  @override
  late final GeneratedColumn<int> servingsOverride = GeneratedColumn<int>(
      'servings_override', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
      'done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recipeJsonMeta =
      const VerificationMeta('recipeJson');
  @override
  late final GeneratedColumn<String> recipeJson = GeneratedColumn<String>(
      'recipe_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorIdMeta =
      const VerificationMeta('authorId');
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
      'author_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _authorNameMeta =
      const VerificationMeta('authorName');
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
      'author_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        spaceId,
        date,
        mealType,
        servingsOverride,
        note,
        done,
        recipeJson,
        authorId,
        authorName,
        createdAt,
        updatedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared_meals';
  @override
  VerificationContext validateIntegrity(Insertable<SharedMealRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(_spaceIdMeta,
          spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta));
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('servings_override')) {
      context.handle(
          _servingsOverrideMeta,
          servingsOverride.isAcceptableOrUnknown(
              data['servings_override']!, _servingsOverrideMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('done')) {
      context.handle(
          _doneMeta, done.isAcceptableOrUnknown(data['done']!, _doneMeta));
    }
    if (data.containsKey('recipe_json')) {
      context.handle(
          _recipeJsonMeta,
          recipeJson.isAcceptableOrUnknown(
              data['recipe_json']!, _recipeJsonMeta));
    } else if (isInserting) {
      context.missing(_recipeJsonMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(_authorIdMeta,
          authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta));
    }
    if (data.containsKey('author_name')) {
      context.handle(
          _authorNameMeta,
          authorName.isAcceptableOrUnknown(
              data['author_name']!, _authorNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SharedMealRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedMealRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      spaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}space_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
      servingsOverride: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}servings_override']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      done: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}done'])!,
      recipeJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_json'])!,
      authorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_id'])!,
      authorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $SharedMealsTable createAlias(String alias) {
    return $SharedMealsTable(attachedDatabase, alias);
  }
}

class SharedMealRow extends DataClass implements Insertable<SharedMealRow> {
  final String id;
  final String spaceId;
  final DateTime date;
  final String mealType;
  final int? servingsOverride;
  final String? note;
  final bool done;
  final String recipeJson;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Versão (`updated_at`) já enviada à casa; nulo = mexida aqui e ainda não
  /// enviada (marcar como feita, mover, apagar a refeição de outra pessoa).
  final DateTime? syncedAt;
  const SharedMealRow(
      {required this.id,
      required this.spaceId,
      required this.date,
      required this.mealType,
      this.servingsOverride,
      this.note,
      required this.done,
      required this.recipeJson,
      required this.authorId,
      required this.authorName,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['space_id'] = Variable<String>(spaceId);
    map['date'] = Variable<DateTime>(date);
    map['meal_type'] = Variable<String>(mealType);
    if (!nullToAbsent || servingsOverride != null) {
      map['servings_override'] = Variable<int>(servingsOverride);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['done'] = Variable<bool>(done);
    map['recipe_json'] = Variable<String>(recipeJson);
    map['author_id'] = Variable<String>(authorId);
    map['author_name'] = Variable<String>(authorName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SharedMealsCompanion toCompanion(bool nullToAbsent) {
    return SharedMealsCompanion(
      id: Value(id),
      spaceId: Value(spaceId),
      date: Value(date),
      mealType: Value(mealType),
      servingsOverride: servingsOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(servingsOverride),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      done: Value(done),
      recipeJson: Value(recipeJson),
      authorId: Value(authorId),
      authorName: Value(authorName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SharedMealRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedMealRow(
      id: serializer.fromJson<String>(json['id']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      date: serializer.fromJson<DateTime>(json['date']),
      mealType: serializer.fromJson<String>(json['mealType']),
      servingsOverride: serializer.fromJson<int?>(json['servingsOverride']),
      note: serializer.fromJson<String?>(json['note']),
      done: serializer.fromJson<bool>(json['done']),
      recipeJson: serializer.fromJson<String>(json['recipeJson']),
      authorId: serializer.fromJson<String>(json['authorId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spaceId': serializer.toJson<String>(spaceId),
      'date': serializer.toJson<DateTime>(date),
      'mealType': serializer.toJson<String>(mealType),
      'servingsOverride': serializer.toJson<int?>(servingsOverride),
      'note': serializer.toJson<String?>(note),
      'done': serializer.toJson<bool>(done),
      'recipeJson': serializer.toJson<String>(recipeJson),
      'authorId': serializer.toJson<String>(authorId),
      'authorName': serializer.toJson<String>(authorName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SharedMealRow copyWith(
          {String? id,
          String? spaceId,
          DateTime? date,
          String? mealType,
          Value<int?> servingsOverride = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? done,
          String? recipeJson,
          String? authorId,
          String? authorName,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      SharedMealRow(
        id: id ?? this.id,
        spaceId: spaceId ?? this.spaceId,
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        servingsOverride: servingsOverride.present
            ? servingsOverride.value
            : this.servingsOverride,
        note: note.present ? note.value : this.note,
        done: done ?? this.done,
        recipeJson: recipeJson ?? this.recipeJson,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  SharedMealRow copyWithCompanion(SharedMealsCompanion data) {
    return SharedMealRow(
      id: data.id.present ? data.id.value : this.id,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      date: data.date.present ? data.date.value : this.date,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      servingsOverride: data.servingsOverride.present
          ? data.servingsOverride.value
          : this.servingsOverride,
      note: data.note.present ? data.note.value : this.note,
      done: data.done.present ? data.done.value : this.done,
      recipeJson:
          data.recipeJson.present ? data.recipeJson.value : this.recipeJson,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorName:
          data.authorName.present ? data.authorName.value : this.authorName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedMealRow(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('servingsOverride: $servingsOverride, ')
          ..write('note: $note, ')
          ..write('done: $done, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      spaceId,
      date,
      mealType,
      servingsOverride,
      note,
      done,
      recipeJson,
      authorId,
      authorName,
      createdAt,
      updatedAt,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedMealRow &&
          other.id == this.id &&
          other.spaceId == this.spaceId &&
          other.date == this.date &&
          other.mealType == this.mealType &&
          other.servingsOverride == this.servingsOverride &&
          other.note == this.note &&
          other.done == this.done &&
          other.recipeJson == this.recipeJson &&
          other.authorId == this.authorId &&
          other.authorName == this.authorName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class SharedMealsCompanion extends UpdateCompanion<SharedMealRow> {
  final Value<String> id;
  final Value<String> spaceId;
  final Value<DateTime> date;
  final Value<String> mealType;
  final Value<int?> servingsOverride;
  final Value<String?> note;
  final Value<bool> done;
  final Value<String> recipeJson;
  final Value<String> authorId;
  final Value<String> authorName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SharedMealsCompanion({
    this.id = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.date = const Value.absent(),
    this.mealType = const Value.absent(),
    this.servingsOverride = const Value.absent(),
    this.note = const Value.absent(),
    this.done = const Value.absent(),
    this.recipeJson = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SharedMealsCompanion.insert({
    required String id,
    required String spaceId,
    required DateTime date,
    required String mealType,
    this.servingsOverride = const Value.absent(),
    this.note = const Value.absent(),
    this.done = const Value.absent(),
    required String recipeJson,
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        spaceId = Value(spaceId),
        date = Value(date),
        mealType = Value(mealType),
        recipeJson = Value(recipeJson),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SharedMealRow> custom({
    Expression<String>? id,
    Expression<String>? spaceId,
    Expression<DateTime>? date,
    Expression<String>? mealType,
    Expression<int>? servingsOverride,
    Expression<String>? note,
    Expression<bool>? done,
    Expression<String>? recipeJson,
    Expression<String>? authorId,
    Expression<String>? authorName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spaceId != null) 'space_id': spaceId,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (servingsOverride != null) 'servings_override': servingsOverride,
      if (note != null) 'note': note,
      if (done != null) 'done': done,
      if (recipeJson != null) 'recipe_json': recipeJson,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SharedMealsCompanion copyWith(
      {Value<String>? id,
      Value<String>? spaceId,
      Value<DateTime>? date,
      Value<String>? mealType,
      Value<int?>? servingsOverride,
      Value<String?>? note,
      Value<bool>? done,
      Value<String>? recipeJson,
      Value<String>? authorId,
      Value<String>? authorName,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return SharedMealsCompanion(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      servingsOverride: servingsOverride ?? this.servingsOverride,
      note: note ?? this.note,
      done: done ?? this.done,
      recipeJson: recipeJson ?? this.recipeJson,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (servingsOverride.present) {
      map['servings_override'] = Variable<int>(servingsOverride.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (recipeJson.present) {
      map['recipe_json'] = Variable<String>(recipeJson.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedMealsCompanion(')
          ..write('id: $id, ')
          ..write('spaceId: $spaceId, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('servingsOverride: $servingsOverride, ')
          ..write('note: $note, ')
          ..write('done: $done, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CookLogsTable extends CookLogs
    with TableInfo<$CookLogsTable, CookLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CookLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _cookedAtMeta =
      const VerificationMeta('cookedAt');
  @override
  late final GeneratedColumn<DateTime> cookedAt = GeneratedColumn<DateTime>(
      'cooked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mealPlanEntryIdMeta =
      const VerificationMeta('mealPlanEntryId');
  @override
  late final GeneratedColumn<String> mealPlanEntryId = GeneratedColumn<String>(
      'meal_plan_entry_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recipeId,
        cookedAt,
        note,
        mealPlanEntryId,
        createdAt,
        rating,
        updatedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cook_logs';
  @override
  VerificationContext validateIntegrity(Insertable<CookLogRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('cooked_at')) {
      context.handle(_cookedAtMeta,
          cookedAt.isAcceptableOrUnknown(data['cooked_at']!, _cookedAtMeta));
    } else if (isInserting) {
      context.missing(_cookedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('meal_plan_entry_id')) {
      context.handle(
          _mealPlanEntryIdMeta,
          mealPlanEntryId.isAcceptableOrUnknown(
              data['meal_plan_entry_id']!, _mealPlanEntryIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CookLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CookLogRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      cookedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cooked_at'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      mealPlanEntryId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}meal_plan_entry_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $CookLogsTable createAlias(String alias) {
    return $CookLogsTable(attachedDatabase, alias);
  }
}

class CookLogRow extends DataClass implements Insertable<CookLogRow> {
  final String id;
  final String recipeId;
  final DateTime cookedAt;
  final String? note;
  final String? mealPlanEntryId;
  final DateTime createdAt;

  /// Estrelas de "como ficou", de 1 a 5; nulo quando a pessoa não avaliou.
  final int? rating;

  /// Última mudança (um gatilho do banco preenche ao inserir e ao editar) e a
  /// versão já sincronizada com a conta (H4).
  final DateTime? updatedAt;
  final DateTime? syncedAt;
  const CookLogRow(
      {required this.id,
      required this.recipeId,
      required this.cookedAt,
      this.note,
      this.mealPlanEntryId,
      required this.createdAt,
      this.rating,
      this.updatedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['cooked_at'] = Variable<DateTime>(cookedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || mealPlanEntryId != null) {
      map['meal_plan_entry_id'] = Variable<String>(mealPlanEntryId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  CookLogsCompanion toCompanion(bool nullToAbsent) {
    return CookLogsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      cookedAt: Value(cookedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      mealPlanEntryId: mealPlanEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(mealPlanEntryId),
      createdAt: Value(createdAt),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory CookLogRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CookLogRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      cookedAt: serializer.fromJson<DateTime>(json['cookedAt']),
      note: serializer.fromJson<String?>(json['note']),
      mealPlanEntryId: serializer.fromJson<String?>(json['mealPlanEntryId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      rating: serializer.fromJson<int?>(json['rating']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'cookedAt': serializer.toJson<DateTime>(cookedAt),
      'note': serializer.toJson<String?>(note),
      'mealPlanEntryId': serializer.toJson<String?>(mealPlanEntryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'rating': serializer.toJson<int?>(rating),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  CookLogRow copyWith(
          {String? id,
          String? recipeId,
          DateTime? cookedAt,
          Value<String?> note = const Value.absent(),
          Value<String?> mealPlanEntryId = const Value.absent(),
          DateTime? createdAt,
          Value<int?> rating = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      CookLogRow(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        cookedAt: cookedAt ?? this.cookedAt,
        note: note.present ? note.value : this.note,
        mealPlanEntryId: mealPlanEntryId.present
            ? mealPlanEntryId.value
            : this.mealPlanEntryId,
        createdAt: createdAt ?? this.createdAt,
        rating: rating.present ? rating.value : this.rating,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  CookLogRow copyWithCompanion(CookLogsCompanion data) {
    return CookLogRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      cookedAt: data.cookedAt.present ? data.cookedAt.value : this.cookedAt,
      note: data.note.present ? data.note.value : this.note,
      mealPlanEntryId: data.mealPlanEntryId.present
          ? data.mealPlanEntryId.value
          : this.mealPlanEntryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rating: data.rating.present ? data.rating.value : this.rating,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CookLogRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('cookedAt: $cookedAt, ')
          ..write('note: $note, ')
          ..write('mealPlanEntryId: $mealPlanEntryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rating: $rating, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, cookedAt, note, mealPlanEntryId,
      createdAt, rating, updatedAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookLogRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.cookedAt == this.cookedAt &&
          other.note == this.note &&
          other.mealPlanEntryId == this.mealPlanEntryId &&
          other.createdAt == this.createdAt &&
          other.rating == this.rating &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class CookLogsCompanion extends UpdateCompanion<CookLogRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<DateTime> cookedAt;
  final Value<String?> note;
  final Value<String?> mealPlanEntryId;
  final Value<DateTime> createdAt;
  final Value<int?> rating;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const CookLogsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.cookedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.mealPlanEntryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CookLogsCompanion.insert({
    required String id,
    required String recipeId,
    required DateTime cookedAt,
    this.note = const Value.absent(),
    this.mealPlanEntryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recipeId = Value(recipeId),
        cookedAt = Value(cookedAt);
  static Insertable<CookLogRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<DateTime>? cookedAt,
    Expression<String>? note,
    Expression<String>? mealPlanEntryId,
    Expression<DateTime>? createdAt,
    Expression<int>? rating,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (cookedAt != null) 'cooked_at': cookedAt,
      if (note != null) 'note': note,
      if (mealPlanEntryId != null) 'meal_plan_entry_id': mealPlanEntryId,
      if (createdAt != null) 'created_at': createdAt,
      if (rating != null) 'rating': rating,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CookLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<DateTime>? cookedAt,
      Value<String?>? note,
      Value<String?>? mealPlanEntryId,
      Value<DateTime>? createdAt,
      Value<int?>? rating,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return CookLogsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      cookedAt: cookedAt ?? this.cookedAt,
      note: note ?? this.note,
      mealPlanEntryId: mealPlanEntryId ?? this.mealPlanEntryId,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (cookedAt.present) {
      map['cooked_at'] = Variable<DateTime>(cookedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (mealPlanEntryId.present) {
      map['meal_plan_entry_id'] = Variable<String>(mealPlanEntryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CookLogsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('cookedAt: $cookedAt, ')
          ..write('note: $note, ')
          ..write('mealPlanEntryId: $mealPlanEntryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rating: $rating, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncTombstonesTable extends SyncTombstones
    with TableInfo<$SyncTombstonesTable, SyncTombstoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _spaceIdMeta =
      const VerificationMeta('spaceId');
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
      'space_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [kind, id, deletedAt, spaceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tombstones';
  @override
  VerificationContext validateIntegrity(Insertable<SyncTombstoneRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(_spaceIdMeta,
          spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, id};
  @override
  SyncTombstoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstoneRow(
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at'])!,
      spaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}space_id']),
    );
  }

  @override
  $SyncTombstonesTable createAlias(String alias) {
    return $SyncTombstonesTable(attachedDatabase, alias);
  }
}

class SyncTombstoneRow extends DataClass
    implements Insertable<SyncTombstoneRow> {
  /// `recipe` ou `folder`.
  final String kind;
  final String id;
  final DateTime deletedAt;

  /// Casa onde o item vivia; nulo = a conta da pessoa (v10).
  final String? spaceId;
  const SyncTombstoneRow(
      {required this.kind,
      required this.id,
      required this.deletedAt,
      this.spaceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['id'] = Variable<String>(id);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    if (!nullToAbsent || spaceId != null) {
      map['space_id'] = Variable<String>(spaceId);
    }
    return map;
  }

  SyncTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstonesCompanion(
      kind: Value(kind),
      id: Value(id),
      deletedAt: Value(deletedAt),
      spaceId: spaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(spaceId),
    );
  }

  factory SyncTombstoneRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstoneRow(
      kind: serializer.fromJson<String>(json['kind']),
      id: serializer.fromJson<String>(json['id']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
      spaceId: serializer.fromJson<String?>(json['spaceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'id': serializer.toJson<String>(id),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
      'spaceId': serializer.toJson<String?>(spaceId),
    };
  }

  SyncTombstoneRow copyWith(
          {String? kind,
          String? id,
          DateTime? deletedAt,
          Value<String?> spaceId = const Value.absent()}) =>
      SyncTombstoneRow(
        kind: kind ?? this.kind,
        id: id ?? this.id,
        deletedAt: deletedAt ?? this.deletedAt,
        spaceId: spaceId.present ? spaceId.value : this.spaceId,
      );
  SyncTombstoneRow copyWithCompanion(SyncTombstonesCompanion data) {
    return SyncTombstoneRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      id: data.id.present ? data.id.value : this.id,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstoneRow(')
          ..write('kind: $kind, ')
          ..write('id: $id, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('spaceId: $spaceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, id, deletedAt, spaceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstoneRow &&
          other.kind == this.kind &&
          other.id == this.id &&
          other.deletedAt == this.deletedAt &&
          other.spaceId == this.spaceId);
}

class SyncTombstonesCompanion extends UpdateCompanion<SyncTombstoneRow> {
  final Value<String> kind;
  final Value<String> id;
  final Value<DateTime> deletedAt;
  final Value<String?> spaceId;
  final Value<int> rowid;
  const SyncTombstonesCompanion({
    this.kind = const Value.absent(),
    this.id = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstonesCompanion.insert({
    required String kind,
    required String id,
    required DateTime deletedAt,
    this.spaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : kind = Value(kind),
        id = Value(id),
        deletedAt = Value(deletedAt);
  static Insertable<SyncTombstoneRow> custom({
    Expression<String>? kind,
    Expression<String>? id,
    Expression<DateTime>? deletedAt,
    Expression<String>? spaceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (id != null) 'id': id,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (spaceId != null) 'space_id': spaceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstonesCompanion copyWith(
      {Value<String>? kind,
      Value<String>? id,
      Value<DateTime>? deletedAt,
      Value<String?>? spaceId,
      Value<int>? rowid}) {
    return SyncTombstonesCompanion(
      kind: kind ?? this.kind,
      id: id ?? this.id,
      deletedAt: deletedAt ?? this.deletedAt,
      spaceId: spaceId ?? this.spaceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstonesCompanion(')
          ..write('kind: $kind, ')
          ..write('id: $id, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('spaceId: $spaceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingListRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _spaceIdMeta =
      const VerificationMeta('spaceId');
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
      'space_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, status, createdAt, updatedAt, syncedAt, spaceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(Insertable<ShoppingListRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('space_id')) {
      context.handle(_spaceIdMeta,
          spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      spaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}space_id']),
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingListRow extends DataClass implements Insertable<ShoppingListRow> {
  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Versão (`updated_at`) já sincronizada com a conta (H4).
  final DateTime? syncedAt;

  /// Casa a que a lista pertence (nulo = só da pessoa); os itens seguem a
  /// lista. Ver `MealPlanEntries.spaceId` (v10).
  final String? spaceId;
  const ShoppingListRow(
      {required this.id,
      required this.name,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.spaceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || spaceId != null) {
      map['space_id'] = Variable<String>(spaceId);
    }
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      id: Value(id),
      name: Value(name),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      spaceId: spaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(spaceId),
    );
  }

  factory ShoppingListRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      spaceId: serializer.fromJson<String?>(json['spaceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'spaceId': serializer.toJson<String?>(spaceId),
    };
  }

  ShoppingListRow copyWith(
          {String? id,
          String? name,
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<String?> spaceId = const Value.absent()}) =>
      ShoppingListRow(
        id: id ?? this.id,
        name: name ?? this.name,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        spaceId: spaceId.present ? spaceId.value : this.spaceId,
      );
  ShoppingListRow copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingListRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('spaceId: $spaceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, status, createdAt, updatedAt, syncedAt, spaceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.spaceId == this.spaceId);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingListRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> spaceId;
  final Value<int> rowid;
  const ShoppingListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    required String id,
    required String name,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<ShoppingListRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? spaceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (spaceId != null) 'space_id': spaceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<String?>? spaceId,
      Value<int>? rowid}) {
    return ShoppingListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      spaceId: spaceId ?? this.spaceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('spaceId: $spaceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListItemsTable extends ShoppingListItems
    with TableInfo<$ShoppingListItemsTable, ShoppingListItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
      'list_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES shopping_lists (id) ON DELETE CASCADE'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
      'ingredient_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ingredients (id) ON DELETE SET NULL'));
  static const VerificationMeta _manualNameMeta =
      const VerificationMeta('manualName');
  @override
  late final GeneratedColumn<String> manualName = GeneratedColumn<String>(
      'manual_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES units (id) ON DELETE SET NULL'));
  static const VerificationMeta _checkedMeta =
      const VerificationMeta('checked');
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
      'checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _addedByMeta =
      const VerificationMeta('addedBy');
  @override
  late final GeneratedColumn<String> addedBy = GeneratedColumn<String>(
      'added_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkedByMeta =
      const VerificationMeta('checkedBy');
  @override
  late final GeneratedColumn<String> checkedBy = GeneratedColumn<String>(
      'checked_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        listId,
        ingredientId,
        manualName,
        quantity,
        unitId,
        checked,
        note,
        position,
        updatedAt,
        syncedAt,
        addedBy,
        checkedBy
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShoppingListItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    }
    if (data.containsKey('manual_name')) {
      context.handle(
          _manualNameMeta,
          manualName.isAcceptableOrUnknown(
              data['manual_name']!, _manualNameMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('checked')) {
      context.handle(_checkedMeta,
          checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('added_by')) {
      context.handle(_addedByMeta,
          addedBy.isAcceptableOrUnknown(data['added_by']!, _addedByMeta));
    }
    if (data.containsKey('checked_by')) {
      context.handle(_checkedByMeta,
          checkedBy.isAcceptableOrUnknown(data['checked_by']!, _checkedByMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredient_id']),
      manualName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manual_name']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id']),
      checked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}checked'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      addedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}added_by']),
      checkedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checked_by']),
    );
  }

  @override
  $ShoppingListItemsTable createAlias(String alias) {
    return $ShoppingListItemsTable(attachedDatabase, alias);
  }
}

class ShoppingListItemRow extends DataClass
    implements Insertable<ShoppingListItemRow> {
  final String id;
  final String listId;
  final String? ingredientId;
  final String? manualName;
  final double? quantity;
  final String? unitId;
  final bool checked;
  final String? note;
  final int position;

  /// Última mudança (um gatilho do banco preenche ao inserir e ao editar — o
  /// item é alterado em muitos lugares e nenhum precisa lembrar disso) e a
  /// versão já sincronizada com a conta (H4).
  final DateTime? updatedAt;
  final DateTime? syncedAt;

  /// Quem adicionou e quem marcou o item (id da conta). Só têm valor em lista
  /// da casa: o sync preenche com a própria pessoa ao enviar e com quem veio
  /// no item ao receber (v12). Marcar ou desmarcar aqui zera `checkedBy`.
  final String? addedBy;
  final String? checkedBy;
  const ShoppingListItemRow(
      {required this.id,
      required this.listId,
      this.ingredientId,
      this.manualName,
      this.quantity,
      this.unitId,
      required this.checked,
      this.note,
      required this.position,
      this.updatedAt,
      this.syncedAt,
      this.addedBy,
      this.checkedBy});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    if (!nullToAbsent || ingredientId != null) {
      map['ingredient_id'] = Variable<String>(ingredientId);
    }
    if (!nullToAbsent || manualName != null) {
      map['manual_name'] = Variable<String>(manualName);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    map['checked'] = Variable<bool>(checked);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || addedBy != null) {
      map['added_by'] = Variable<String>(addedBy);
    }
    if (!nullToAbsent || checkedBy != null) {
      map['checked_by'] = Variable<String>(checkedBy);
    }
    return map;
  }

  ShoppingListItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListItemsCompanion(
      id: Value(id),
      listId: Value(listId),
      ingredientId: ingredientId == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredientId),
      manualName: manualName == null && nullToAbsent
          ? const Value.absent()
          : Value(manualName),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      checked: Value(checked),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      position: Value(position),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      addedBy: addedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(addedBy),
      checkedBy: checkedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedBy),
    );
  }

  factory ShoppingListItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListItemRow(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      ingredientId: serializer.fromJson<String?>(json['ingredientId']),
      manualName: serializer.fromJson<String?>(json['manualName']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      checked: serializer.fromJson<bool>(json['checked']),
      note: serializer.fromJson<String?>(json['note']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      addedBy: serializer.fromJson<String?>(json['addedBy']),
      checkedBy: serializer.fromJson<String?>(json['checkedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'ingredientId': serializer.toJson<String?>(ingredientId),
      'manualName': serializer.toJson<String?>(manualName),
      'quantity': serializer.toJson<double?>(quantity),
      'unitId': serializer.toJson<String?>(unitId),
      'checked': serializer.toJson<bool>(checked),
      'note': serializer.toJson<String?>(note),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'addedBy': serializer.toJson<String?>(addedBy),
      'checkedBy': serializer.toJson<String?>(checkedBy),
    };
  }

  ShoppingListItemRow copyWith(
          {String? id,
          String? listId,
          Value<String?> ingredientId = const Value.absent(),
          Value<String?> manualName = const Value.absent(),
          Value<double?> quantity = const Value.absent(),
          Value<String?> unitId = const Value.absent(),
          bool? checked,
          Value<String?> note = const Value.absent(),
          int? position,
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<String?> addedBy = const Value.absent(),
          Value<String?> checkedBy = const Value.absent()}) =>
      ShoppingListItemRow(
        id: id ?? this.id,
        listId: listId ?? this.listId,
        ingredientId:
            ingredientId.present ? ingredientId.value : this.ingredientId,
        manualName: manualName.present ? manualName.value : this.manualName,
        quantity: quantity.present ? quantity.value : this.quantity,
        unitId: unitId.present ? unitId.value : this.unitId,
        checked: checked ?? this.checked,
        note: note.present ? note.value : this.note,
        position: position ?? this.position,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        addedBy: addedBy.present ? addedBy.value : this.addedBy,
        checkedBy: checkedBy.present ? checkedBy.value : this.checkedBy,
      );
  ShoppingListItemRow copyWithCompanion(ShoppingListItemsCompanion data) {
    return ShoppingListItemRow(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      manualName:
          data.manualName.present ? data.manualName.value : this.manualName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      checked: data.checked.present ? data.checked.value : this.checked,
      note: data.note.present ? data.note.value : this.note,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      addedBy: data.addedBy.present ? data.addedBy.value : this.addedBy,
      checkedBy: data.checkedBy.present ? data.checkedBy.value : this.checkedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemRow(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('manualName: $manualName, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('checked: $checked, ')
          ..write('note: $note, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('addedBy: $addedBy, ')
          ..write('checkedBy: $checkedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      listId,
      ingredientId,
      manualName,
      quantity,
      unitId,
      checked,
      note,
      position,
      updatedAt,
      syncedAt,
      addedBy,
      checkedBy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListItemRow &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.ingredientId == this.ingredientId &&
          other.manualName == this.manualName &&
          other.quantity == this.quantity &&
          other.unitId == this.unitId &&
          other.checked == this.checked &&
          other.note == this.note &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.addedBy == this.addedBy &&
          other.checkedBy == this.checkedBy);
}

class ShoppingListItemsCompanion extends UpdateCompanion<ShoppingListItemRow> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String?> ingredientId;
  final Value<String?> manualName;
  final Value<double?> quantity;
  final Value<String?> unitId;
  final Value<bool> checked;
  final Value<String?> note;
  final Value<int> position;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> addedBy;
  final Value<String?> checkedBy;
  final Value<int> rowid;
  const ShoppingListItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.manualName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.checked = const Value.absent(),
    this.note = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.addedBy = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListItemsCompanion.insert({
    required String id,
    required String listId,
    this.ingredientId = const Value.absent(),
    this.manualName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.checked = const Value.absent(),
    this.note = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.addedBy = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        listId = Value(listId);
  static Insertable<ShoppingListItemRow> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? ingredientId,
    Expression<String>? manualName,
    Expression<double>? quantity,
    Expression<String>? unitId,
    Expression<bool>? checked,
    Expression<String>? note,
    Expression<int>? position,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? addedBy,
    Expression<String>? checkedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (manualName != null) 'manual_name': manualName,
      if (quantity != null) 'quantity': quantity,
      if (unitId != null) 'unit_id': unitId,
      if (checked != null) 'checked': checked,
      if (note != null) 'note': note,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (addedBy != null) 'added_by': addedBy,
      if (checkedBy != null) 'checked_by': checkedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? listId,
      Value<String?>? ingredientId,
      Value<String?>? manualName,
      Value<double?>? quantity,
      Value<String?>? unitId,
      Value<bool>? checked,
      Value<String?>? note,
      Value<int>? position,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<String?>? addedBy,
      Value<String?>? checkedBy,
      Value<int>? rowid}) {
    return ShoppingListItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      ingredientId: ingredientId ?? this.ingredientId,
      manualName: manualName ?? this.manualName,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      checked: checked ?? this.checked,
      note: note ?? this.note,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      addedBy: addedBy ?? this.addedBy,
      checkedBy: checkedBy ?? this.checkedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (manualName.present) {
      map['manual_name'] = Variable<String>(manualName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (addedBy.present) {
      map['added_by'] = Variable<String>(addedBy.value);
    }
    if (checkedBy.present) {
      map['checked_by'] = Variable<String>(checkedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('manualName: $manualName, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('checked: $checked, ')
          ..write('note: $note, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('addedBy: $addedBy, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingItemSourcesTable extends ShoppingItemSources
    with TableInfo<$ShoppingItemSourcesTable, ShoppingItemSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingItemSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES shopping_list_items (id) ON DELETE CASCADE'));
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES units (id) ON DELETE SET NULL'));
  @override
  List<GeneratedColumn> get $columns => [itemId, recipeId, quantity, unitId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_item_sources';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShoppingItemSourceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, recipeId};
  @override
  ShoppingItemSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingItemSourceRow(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id']),
    );
  }

  @override
  $ShoppingItemSourcesTable createAlias(String alias) {
    return $ShoppingItemSourcesTable(attachedDatabase, alias);
  }
}

class ShoppingItemSourceRow extends DataClass
    implements Insertable<ShoppingItemSourceRow> {
  final String itemId;
  final String recipeId;
  final double? quantity;
  final String? unitId;
  const ShoppingItemSourceRow(
      {required this.itemId,
      required this.recipeId,
      this.quantity,
      this.unitId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['recipe_id'] = Variable<String>(recipeId);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    return map;
  }

  ShoppingItemSourcesCompanion toCompanion(bool nullToAbsent) {
    return ShoppingItemSourcesCompanion(
      itemId: Value(itemId),
      recipeId: Value(recipeId),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
    );
  }

  factory ShoppingItemSourceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingItemSourceRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unitId: serializer.fromJson<String?>(json['unitId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'recipeId': serializer.toJson<String>(recipeId),
      'quantity': serializer.toJson<double?>(quantity),
      'unitId': serializer.toJson<String?>(unitId),
    };
  }

  ShoppingItemSourceRow copyWith(
          {String? itemId,
          String? recipeId,
          Value<double?> quantity = const Value.absent(),
          Value<String?> unitId = const Value.absent()}) =>
      ShoppingItemSourceRow(
        itemId: itemId ?? this.itemId,
        recipeId: recipeId ?? this.recipeId,
        quantity: quantity.present ? quantity.value : this.quantity,
        unitId: unitId.present ? unitId.value : this.unitId,
      );
  ShoppingItemSourceRow copyWithCompanion(ShoppingItemSourcesCompanion data) {
    return ShoppingItemSourceRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemSourceRow(')
          ..write('itemId: $itemId, ')
          ..write('recipeId: $recipeId, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, recipeId, quantity, unitId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingItemSourceRow &&
          other.itemId == this.itemId &&
          other.recipeId == this.recipeId &&
          other.quantity == this.quantity &&
          other.unitId == this.unitId);
}

class ShoppingItemSourcesCompanion
    extends UpdateCompanion<ShoppingItemSourceRow> {
  final Value<String> itemId;
  final Value<String> recipeId;
  final Value<double?> quantity;
  final Value<String?> unitId;
  final Value<int> rowid;
  const ShoppingItemSourcesCompanion({
    this.itemId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingItemSourcesCompanion.insert({
    required String itemId,
    required String recipeId,
    this.quantity = const Value.absent(),
    this.unitId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        recipeId = Value(recipeId);
  static Insertable<ShoppingItemSourceRow> custom({
    Expression<String>? itemId,
    Expression<String>? recipeId,
    Expression<double>? quantity,
    Expression<String>? unitId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (recipeId != null) 'recipe_id': recipeId,
      if (quantity != null) 'quantity': quantity,
      if (unitId != null) 'unit_id': unitId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingItemSourcesCompanion copyWith(
      {Value<String>? itemId,
      Value<String>? recipeId,
      Value<double?>? quantity,
      Value<String?>? unitId,
      Value<int>? rowid}) {
    return ShoppingItemSourcesCompanion(
      itemId: itemId ?? this.itemId,
      recipeId: recipeId ?? this.recipeId,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemSourcesCompanion(')
          ..write('itemId: $itemId, ')
          ..write('recipeId: $recipeId, ')
          ..write('quantity: $quantity, ')
          ..write('unitId: $unitId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NormalizerTermsTable extends NormalizerTerms
    with TableInfo<$NormalizerTermsTable, NormalizerTermRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NormalizerTermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
      'term', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, term, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'normalizer_terms';
  @override
  VerificationContext validateIntegrity(Insertable<NormalizerTermRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
          _termMeta, term.isAcceptableOrUnknown(data['term']!, _termMeta));
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NormalizerTermRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NormalizerTermRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      term: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}term'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
    );
  }

  @override
  $NormalizerTermsTable createAlias(String alias) {
    return $NormalizerTermsTable(attachedDatabase, alias);
  }
}

class NormalizerTermRow extends DataClass
    implements Insertable<NormalizerTermRow> {
  final String id;
  final String term;
  final String kind;
  const NormalizerTermRow(
      {required this.id, required this.term, required this.kind});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['term'] = Variable<String>(term);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  NormalizerTermsCompanion toCompanion(bool nullToAbsent) {
    return NormalizerTermsCompanion(
      id: Value(id),
      term: Value(term),
      kind: Value(kind),
    );
  }

  factory NormalizerTermRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NormalizerTermRow(
      id: serializer.fromJson<String>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'term': serializer.toJson<String>(term),
      'kind': serializer.toJson<String>(kind),
    };
  }

  NormalizerTermRow copyWith({String? id, String? term, String? kind}) =>
      NormalizerTermRow(
        id: id ?? this.id,
        term: term ?? this.term,
        kind: kind ?? this.kind,
      );
  NormalizerTermRow copyWithCompanion(NormalizerTermsCompanion data) {
    return NormalizerTermRow(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NormalizerTermRow(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, term, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NormalizerTermRow &&
          other.id == this.id &&
          other.term == this.term &&
          other.kind == this.kind);
}

class NormalizerTermsCompanion extends UpdateCompanion<NormalizerTermRow> {
  final Value<String> id;
  final Value<String> term;
  final Value<String> kind;
  final Value<int> rowid;
  const NormalizerTermsCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NormalizerTermsCompanion.insert({
    required String id,
    required String term,
    required String kind,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        term = Value(term),
        kind = Value(kind);
  static Insertable<NormalizerTermRow> custom({
    Expression<String>? id,
    Expression<String>? term,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NormalizerTermsCompanion copyWith(
      {Value<String>? id,
      Value<String>? term,
      Value<String>? kind,
      Value<int>? rowid}) {
    return NormalizerTermsCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NormalizerTermsCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $IngredientAliasesTable ingredientAliases =
      $IngredientAliasesTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $RecipeIngredientsTable recipeIngredients =
      $RecipeIngredientsTable(this);
  late final $RecipeStepsTable recipeSteps = $RecipeStepsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $RecipeTagsTable recipeTags = $RecipeTagsTable(this);
  late final $MealPlanEntriesTable mealPlanEntries =
      $MealPlanEntriesTable(this);
  late final $SharedMealsTable sharedMeals = $SharedMealsTable(this);
  late final $CookLogsTable cookLogs = $CookLogsTable(this);
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ShoppingListItemsTable shoppingListItems =
      $ShoppingListItemsTable(this);
  late final $ShoppingItemSourcesTable shoppingItemSources =
      $ShoppingItemSourcesTable(this);
  late final $NormalizerTermsTable normalizerTerms =
      $NormalizerTermsTable(this);
  late final RecipeDao recipeDao = RecipeDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final FolderDao folderDao = FolderDao(this as AppDatabase);
  late final IngredientDao ingredientDao = IngredientDao(this as AppDatabase);
  late final ShoppingListDao shoppingListDao =
      ShoppingListDao(this as AppDatabase);
  late final MealPlanDao mealPlanDao = MealPlanDao(this as AppDatabase);
  late final CookLogDao cookLogDao = CookLogDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        folders,
        recipes,
        categories,
        ingredients,
        ingredientAliases,
        units,
        recipeIngredients,
        recipeSteps,
        tags,
        recipeTags,
        mealPlanEntries,
        sharedMeals,
        cookLogs,
        syncTombstones,
        shoppingLists,
        shoppingListItems,
        shoppingItemSources,
        normalizerTerms
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('folders',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipes', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('ingredients', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('ingredients',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('ingredient_aliases', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_ingredients', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('units',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_ingredients', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_steps', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tags',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('meal_plan_entries', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('cook_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('shopping_lists',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_list_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('ingredients',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_list_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('units',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_list_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('shopping_list_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_item_sources', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_item_sources', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('units',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_item_sources', kind: UpdateKind.update),
            ],
          ),
        ],
      );
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  Value<String?> parentId,
  required String name,
  Value<String?> tileColor,
  Value<String?> tileMotif,
  Value<int> position,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastOpenedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> name,
  Value<String?> tileColor,
  Value<String?> tileMotif,
  Value<int> position,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastOpenedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, FolderRow> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _parentIdTable(_$AppDatabase db) =>
      db.folders.createAlias('folders__parent_id__folders__id');

  $$FoldersTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager($_db, $_db.folders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RecipesTable, List<RecipeRow>> _recipesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recipes,
          aliasName: 'folders__id__recipes__folder_id');

  $$RecipesTableProcessedTableManager get recipesRefs {
    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tileColor => $composableBuilder(
      column: $table.tileColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tileMotif => $composableBuilder(
      column: $table.tileMotif, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$FoldersTableFilterComposer get parentId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableFilterComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> recipesRefs(
      Expression<bool> Function($$RecipesTableFilterComposer f) f) {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tileColor => $composableBuilder(
      column: $table.tileColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tileMotif => $composableBuilder(
      column: $table.tileMotif, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$FoldersTableOrderingComposer get parentId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableOrderingComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get tileColor =>
      $composableBuilder(column: $table.tileColor, builder: (column) => column);

  GeneratedColumn<String> get tileMotif =>
      $composableBuilder(column: $table.tileMotif, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get parentId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> recipesRefs<T extends Object>(
      Expression<T> Function($$RecipesTableAnnotationComposer a) f) {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FoldersTable,
    FolderRow,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (FolderRow, $$FoldersTableReferences),
    FolderRow,
    PrefetchHooks Function({bool parentId, bool recipesRefs})> {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> tileColor = const Value.absent(),
            Value<String?> tileMotif = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersCompanion(
            id: id,
            parentId: parentId,
            name: name,
            tileColor: tileColor,
            tileMotif: tileMotif,
            position: position,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastOpenedAt: lastOpenedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parentId = const Value.absent(),
            required String name,
            Value<String?> tileColor = const Value.absent(),
            Value<String?> tileMotif = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersCompanion.insert(
            id: id,
            parentId: parentId,
            name: name,
            tileColor: tileColor,
            tileMotif: tileMotif,
            position: position,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastOpenedAt: lastOpenedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$FoldersTable, FolderRow>(table),
                    $$FoldersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({parentId = false, recipesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (recipesRefs) db.recipes],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (parentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentId,
                    referencedTable:
                        $$FoldersTableReferences._parentIdTable(db),
                    referencedColumn:
                        $$FoldersTableReferences._parentIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipesRefs)
                    await $_getPrefetchedData<FolderRow, $FoldersTable,
                            RecipeRow>(
                        currentTable: table,
                        referencedTable:
                            $$FoldersTableReferences._recipesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FoldersTableReferences(db, table, p0).recipesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.folderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FoldersTable,
    FolderRow,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (FolderRow, $$FoldersTableReferences),
    FolderRow,
    PrefetchHooks Function({bool parentId, bool recipesRefs})>;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  required String id,
  Value<String?> folderId,
  required String name,
  Value<String?> about,
  Value<int?> prepMinutes,
  Value<int?> cookMinutes,
  Value<int?> servings,
  Value<String?> imagePath,
  Value<String?> imageSyncedPath,
  Value<String?> sourceUrl,
  Value<String?> notes,
  Value<String?> tileColor,
  Value<String?> tileMotif,
  Value<bool> isFavorite,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastOpenedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<String?> folderId,
  Value<String> name,
  Value<String?> about,
  Value<int?> prepMinutes,
  Value<int?> cookMinutes,
  Value<int?> servings,
  Value<String?> imagePath,
  Value<String?> imageSyncedPath,
  Value<String?> sourceUrl,
  Value<String?> notes,
  Value<String?> tileColor,
  Value<String?> tileMotif,
  Value<bool> isFavorite,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime?> lastOpenedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) =>
      db.folders.createAlias('recipes__folder_id__folders__id');

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager($_db, $_db.folders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RecipeIngredientsTable, List<RecipeIngredientRow>>
      _recipeIngredientsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeIngredients,
              aliasName: 'recipes__id__recipe_ingredients__recipe_id');

  $$RecipeIngredientsTableProcessedTableManager get recipeIngredientsRefs {
    final manager = $$RecipeIngredientsTableTableManager(
            $_db, $_db.recipeIngredients)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recipeIngredientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecipeStepsTable, List<RecipeStepRow>>
      _recipeStepsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeSteps,
              aliasName: 'recipes__id__recipe_steps__recipe_id');

  $$RecipeStepsTableProcessedTableManager get recipeStepsRefs {
    final manager = $$RecipeStepsTableTableManager($_db, $_db.recipeSteps)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeStepsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecipeTagsTable, List<RecipeTagRow>>
      _recipeTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeTags,
              aliasName: 'recipes__id__recipe_tags__recipe_id');

  $$RecipeTagsTableProcessedTableManager get recipeTagsRefs {
    final manager = $$RecipeTagsTableTableManager($_db, $_db.recipeTags)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MealPlanEntriesTable, List<MealPlanEntryRow>>
      _mealPlanEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.mealPlanEntries,
              aliasName: 'recipes__id__meal_plan_entries__recipe_id');

  $$MealPlanEntriesTableProcessedTableManager get mealPlanEntriesRefs {
    final manager = $$MealPlanEntriesTableTableManager(
            $_db, $_db.mealPlanEntries)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_mealPlanEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CookLogsTable, List<CookLogRow>>
      _cookLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cookLogs,
              aliasName: 'recipes__id__cook_logs__recipe_id');

  $$CookLogsTableProcessedTableManager get cookLogsRefs {
    final manager = $$CookLogsTableTableManager($_db, $_db.cookLogs)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cookLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShoppingItemSourcesTable,
      List<ShoppingItemSourceRow>> _shoppingItemSourcesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shoppingItemSources,
          aliasName: 'recipes__id__shopping_item_sources__recipe_id');

  $$ShoppingItemSourcesTableProcessedTableManager get shoppingItemSourcesRefs {
    final manager = $$ShoppingItemSourcesTableTableManager(
            $_db, $_db.shoppingItemSources)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_shoppingItemSourcesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get about => $composableBuilder(
      column: $table.about, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get prepMinutes => $composableBuilder(
      column: $table.prepMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cookMinutes => $composableBuilder(
      column: $table.cookMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get servings => $composableBuilder(
      column: $table.servings, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageSyncedPath => $composableBuilder(
      column: $table.imageSyncedPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUrl => $composableBuilder(
      column: $table.sourceUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tileColor => $composableBuilder(
      column: $table.tileColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tileMotif => $composableBuilder(
      column: $table.tileMotif, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableFilterComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> recipeIngredientsRefs(
      Expression<bool> Function($$RecipeIngredientsTableFilterComposer f) f) {
    final $$RecipeIngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeIngredients,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeIngredientsTableFilterComposer(
              $db: $db,
              $table: $db.recipeIngredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recipeStepsRefs(
      Expression<bool> Function($$RecipeStepsTableFilterComposer f) f) {
    final $$RecipeStepsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeSteps,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeStepsTableFilterComposer(
              $db: $db,
              $table: $db.recipeSteps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recipeTagsRefs(
      Expression<bool> Function($$RecipeTagsTableFilterComposer f) f) {
    final $$RecipeTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeTags,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeTagsTableFilterComposer(
              $db: $db,
              $table: $db.recipeTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> mealPlanEntriesRefs(
      Expression<bool> Function($$MealPlanEntriesTableFilterComposer f) f) {
    final $$MealPlanEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealPlanEntries,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealPlanEntriesTableFilterComposer(
              $db: $db,
              $table: $db.mealPlanEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cookLogsRefs(
      Expression<bool> Function($$CookLogsTableFilterComposer f) f) {
    final $$CookLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cookLogs,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CookLogsTableFilterComposer(
              $db: $db,
              $table: $db.cookLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> shoppingItemSourcesRefs(
      Expression<bool> Function($$ShoppingItemSourcesTableFilterComposer f) f) {
    final $$ShoppingItemSourcesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingItemSources,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingItemSourcesTableFilterComposer(
              $db: $db,
              $table: $db.shoppingItemSources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get about => $composableBuilder(
      column: $table.about, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
      column: $table.prepMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cookMinutes => $composableBuilder(
      column: $table.cookMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get servings => $composableBuilder(
      column: $table.servings, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageSyncedPath => $composableBuilder(
      column: $table.imageSyncedPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
      column: $table.sourceUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tileColor => $composableBuilder(
      column: $table.tileColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tileMotif => $composableBuilder(
      column: $table.tileMotif, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableOrderingComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get about =>
      $composableBuilder(column: $table.about, builder: (column) => column);

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
      column: $table.prepMinutes, builder: (column) => column);

  GeneratedColumn<int> get cookMinutes => $composableBuilder(
      column: $table.cookMinutes, builder: (column) => column);

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get imageSyncedPath => $composableBuilder(
      column: $table.imageSyncedPath, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get tileColor =>
      $composableBuilder(column: $table.tileColor, builder: (column) => column);

  GeneratedColumn<String> get tileMotif =>
      $composableBuilder(column: $table.tileMotif, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> recipeIngredientsRefs<T extends Object>(
      Expression<T> Function($$RecipeIngredientsTableAnnotationComposer a) f) {
    final $$RecipeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recipeIngredients,
            getReferencedColumn: (t) => t.recipeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecipeIngredientsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recipeIngredients,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> recipeStepsRefs<T extends Object>(
      Expression<T> Function($$RecipeStepsTableAnnotationComposer a) f) {
    final $$RecipeStepsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeSteps,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeStepsTableAnnotationComposer(
              $db: $db,
              $table: $db.recipeSteps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recipeTagsRefs<T extends Object>(
      Expression<T> Function($$RecipeTagsTableAnnotationComposer a) f) {
    final $$RecipeTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeTags,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.recipeTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> mealPlanEntriesRefs<T extends Object>(
      Expression<T> Function($$MealPlanEntriesTableAnnotationComposer a) f) {
    final $$MealPlanEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.mealPlanEntries,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealPlanEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.mealPlanEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cookLogsRefs<T extends Object>(
      Expression<T> Function($$CookLogsTableAnnotationComposer a) f) {
    final $$CookLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cookLogs,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CookLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.cookLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> shoppingItemSourcesRefs<T extends Object>(
      Expression<T> Function($$ShoppingItemSourcesTableAnnotationComposer a)
          f) {
    final $$ShoppingItemSourcesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.shoppingItemSources,
            getReferencedColumn: (t) => t.recipeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingItemSourcesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingItemSources,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RecipesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipesTable,
    RecipeRow,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (RecipeRow, $$RecipesTableReferences),
    RecipeRow,
    PrefetchHooks Function(
        {bool folderId,
        bool recipeIngredientsRefs,
        bool recipeStepsRefs,
        bool recipeTagsRefs,
        bool mealPlanEntriesRefs,
        bool cookLogsRefs,
        bool shoppingItemSourcesRefs})> {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> about = const Value.absent(),
            Value<int?> prepMinutes = const Value.absent(),
            Value<int?> cookMinutes = const Value.absent(),
            Value<int?> servings = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> imageSyncedPath = const Value.absent(),
            Value<String?> sourceUrl = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> tileColor = const Value.absent(),
            Value<String?> tileMotif = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion(
            id: id,
            folderId: folderId,
            name: name,
            about: about,
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            servings: servings,
            imagePath: imagePath,
            imageSyncedPath: imageSyncedPath,
            sourceUrl: sourceUrl,
            notes: notes,
            tileColor: tileColor,
            tileMotif: tileMotif,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastOpenedAt: lastOpenedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> folderId = const Value.absent(),
            required String name,
            Value<String?> about = const Value.absent(),
            Value<int?> prepMinutes = const Value.absent(),
            Value<int?> cookMinutes = const Value.absent(),
            Value<int?> servings = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> imageSyncedPath = const Value.absent(),
            Value<String?> sourceUrl = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> tileColor = const Value.absent(),
            Value<String?> tileMotif = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion.insert(
            id: id,
            folderId: folderId,
            name: name,
            about: about,
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            servings: servings,
            imagePath: imagePath,
            imageSyncedPath: imageSyncedPath,
            sourceUrl: sourceUrl,
            notes: notes,
            tileColor: tileColor,
            tileMotif: tileMotif,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastOpenedAt: lastOpenedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecipesTable, RecipeRow>(table),
                    $$RecipesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {folderId = false,
              recipeIngredientsRefs = false,
              recipeStepsRefs = false,
              recipeTagsRefs = false,
              mealPlanEntriesRefs = false,
              cookLogsRefs = false,
              shoppingItemSourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipeIngredientsRefs) db.recipeIngredients,
                if (recipeStepsRefs) db.recipeSteps,
                if (recipeTagsRefs) db.recipeTags,
                if (mealPlanEntriesRefs) db.mealPlanEntries,
                if (cookLogsRefs) db.cookLogs,
                if (shoppingItemSourcesRefs) db.shoppingItemSources
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (folderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.folderId,
                    referencedTable:
                        $$RecipesTableReferences._folderIdTable(db),
                    referencedColumn:
                        $$RecipesTableReferences._folderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeIngredientsRefs)
                    await $_getPrefetchedData<RecipeRow, $RecipesTable,
                            RecipeIngredientRow>(
                        currentTable: table,
                        referencedTable: $$RecipesTableReferences
                            ._recipeIngredientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .recipeIngredientsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (recipeStepsRefs)
                    await $_getPrefetchedData<RecipeRow, $RecipesTable,
                            RecipeStepRow>(
                        currentTable: table,
                        referencedTable:
                            $$RecipesTableReferences._recipeStepsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .recipeStepsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (recipeTagsRefs)
                    await $_getPrefetchedData<RecipeRow, $RecipesTable,
                            RecipeTagRow>(
                        currentTable: table,
                        referencedTable:
                            $$RecipesTableReferences._recipeTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .recipeTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (mealPlanEntriesRefs)
                    await $_getPrefetchedData<RecipeRow, $RecipesTable,
                            MealPlanEntryRow>(
                        currentTable: table,
                        referencedTable: $$RecipesTableReferences
                            ._mealPlanEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .mealPlanEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (cookLogsRefs)
                    await $_getPrefetchedData<RecipeRow, $RecipesTable,
                            CookLogRow>(
                        currentTable: table,
                        referencedTable:
                            $$RecipesTableReferences._cookLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .cookLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (shoppingItemSourcesRefs)
                    await $_getPrefetchedData<RecipeRow, $RecipesTable,
                            ShoppingItemSourceRow>(
                        currentTable: table,
                        referencedTable: $$RecipesTableReferences
                            ._shoppingItemSourcesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .shoppingItemSourcesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecipesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipesTable,
    RecipeRow,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (RecipeRow, $$RecipesTableReferences),
    RecipeRow,
    PrefetchHooks Function(
        {bool folderId,
        bool recipeIngredientsRefs,
        bool recipeStepsRefs,
        bool recipeTagsRefs,
        bool mealPlanEntriesRefs,
        bool cookLogsRefs,
        bool shoppingItemSourcesRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientsTable, List<IngredientRow>>
      _ingredientsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ingredients,
              aliasName: 'categories__id__ingredients__category_id');

  $$IngredientsTableProcessedTableManager get ingredientsRefs {
    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ingredientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientsRefs(
      Expression<bool> Function($$IngredientsTableFilterComposer f) f) {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> ingredientsRefs<T extends Object>(
      Expression<T> Function($$IngredientsTableAnnotationComposer a) f) {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, $$CategoriesTableReferences),
    CategoryRow,
    PrefetchHooks Function({bool ingredientsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int sortOrder,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CategoriesTable, CategoryRow>(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ingredientsRefs) db.ingredients],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientsRefs)
                    await $_getPrefetchedData<CategoryRow, $CategoriesTable,
                            IngredientRow>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._ingredientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .ingredientsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, $$CategoriesTableReferences),
    CategoryRow,
    PrefetchHooks Function({bool ingredientsRefs})>;
typedef $$IngredientsTableCreateCompanionBuilder = IngredientsCompanion
    Function({
  required String id,
  required String displayName,
  required String normalizedKey,
  Value<String?> categoryId,
  Value<int> usageCount,
  Value<bool> inPantry,
  Value<DateTime?> pantryUpdatedAt,
  Value<DateTime?> pantrySyncedAt,
  Value<int?> priceCents,
  Value<String?> priceBasis,
  Value<double?> priceQty,
  Value<int> rowid,
});
typedef $$IngredientsTableUpdateCompanionBuilder = IngredientsCompanion
    Function({
  Value<String> id,
  Value<String> displayName,
  Value<String> normalizedKey,
  Value<String?> categoryId,
  Value<int> usageCount,
  Value<bool> inPantry,
  Value<DateTime?> pantryUpdatedAt,
  Value<DateTime?> pantrySyncedAt,
  Value<int?> priceCents,
  Value<String?> priceBasis,
  Value<double?> priceQty,
  Value<int> rowid,
});

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDatabase, $IngredientsTable, IngredientRow> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('ingredients__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IngredientAliasesTable, List<IngredientAliasRow>>
      _ingredientAliasesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ingredientAliases,
              aliasName: 'ingredients__id__ingredient_aliases__ingredient_id');

  $$IngredientAliasesTableProcessedTableManager get ingredientAliasesRefs {
    final manager = $$IngredientAliasesTableTableManager(
            $_db, $_db.ingredientAliases)
        .filter(
            (f) => f.ingredientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientAliasesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecipeIngredientsTable, List<RecipeIngredientRow>>
      _recipeIngredientsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeIngredients,
              aliasName: 'ingredients__id__recipe_ingredients__ingredient_id');

  $$RecipeIngredientsTableProcessedTableManager get recipeIngredientsRefs {
    final manager = $$RecipeIngredientsTableTableManager(
            $_db, $_db.recipeIngredients)
        .filter(
            (f) => f.ingredientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recipeIngredientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShoppingListItemsTable, List<ShoppingListItemRow>>
      _shoppingListItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.shoppingListItems,
              aliasName: 'ingredients__id__shopping_list_items__ingredient_id');

  $$ShoppingListItemsTableProcessedTableManager get shoppingListItemsRefs {
    final manager = $$ShoppingListItemsTableTableManager(
            $_db, $_db.shoppingListItems)
        .filter(
            (f) => f.ingredientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_shoppingListItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedKey => $composableBuilder(
      column: $table.normalizedKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get inPantry => $composableBuilder(
      column: $table.inPantry, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pantryUpdatedAt => $composableBuilder(
      column: $table.pantryUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pantrySyncedAt => $composableBuilder(
      column: $table.pantrySyncedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priceBasis => $composableBuilder(
      column: $table.priceBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceQty => $composableBuilder(
      column: $table.priceQty, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> ingredientAliasesRefs(
      Expression<bool> Function($$IngredientAliasesTableFilterComposer f) f) {
    final $$IngredientAliasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientAliases,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientAliasesTableFilterComposer(
              $db: $db,
              $table: $db.ingredientAliases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recipeIngredientsRefs(
      Expression<bool> Function($$RecipeIngredientsTableFilterComposer f) f) {
    final $$RecipeIngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeIngredients,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeIngredientsTableFilterComposer(
              $db: $db,
              $table: $db.recipeIngredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> shoppingListItemsRefs(
      Expression<bool> Function($$ShoppingListItemsTableFilterComposer f) f) {
    final $$ShoppingListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingListItems,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListItemsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingListItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedKey => $composableBuilder(
      column: $table.normalizedKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get inPantry => $composableBuilder(
      column: $table.inPantry, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pantryUpdatedAt => $composableBuilder(
      column: $table.pantryUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pantrySyncedAt => $composableBuilder(
      column: $table.pantrySyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priceBasis => $composableBuilder(
      column: $table.priceBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceQty => $composableBuilder(
      column: $table.priceQty, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get normalizedKey => $composableBuilder(
      column: $table.normalizedKey, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => column);

  GeneratedColumn<bool> get inPantry =>
      $composableBuilder(column: $table.inPantry, builder: (column) => column);

  GeneratedColumn<DateTime> get pantryUpdatedAt => $composableBuilder(
      column: $table.pantryUpdatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get pantrySyncedAt => $composableBuilder(
      column: $table.pantrySyncedAt, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => column);

  GeneratedColumn<String> get priceBasis => $composableBuilder(
      column: $table.priceBasis, builder: (column) => column);

  GeneratedColumn<double> get priceQty =>
      $composableBuilder(column: $table.priceQty, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> ingredientAliasesRefs<T extends Object>(
      Expression<T> Function($$IngredientAliasesTableAnnotationComposer a) f) {
    final $$IngredientAliasesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientAliases,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientAliasesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientAliases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> recipeIngredientsRefs<T extends Object>(
      Expression<T> Function($$RecipeIngredientsTableAnnotationComposer a) f) {
    final $$RecipeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recipeIngredients,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecipeIngredientsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recipeIngredients,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> shoppingListItemsRefs<T extends Object>(
      Expression<T> Function($$ShoppingListItemsTableAnnotationComposer a) f) {
    final $$ShoppingListItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.shoppingListItems,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingListItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingListItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$IngredientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientsTable,
    IngredientRow,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (IngredientRow, $$IngredientsTableReferences),
    IngredientRow,
    PrefetchHooks Function(
        {bool categoryId,
        bool ingredientAliasesRefs,
        bool recipeIngredientsRefs,
        bool shoppingListItemsRefs})> {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> normalizedKey = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<bool> inPantry = const Value.absent(),
            Value<DateTime?> pantryUpdatedAt = const Value.absent(),
            Value<DateTime?> pantrySyncedAt = const Value.absent(),
            Value<int?> priceCents = const Value.absent(),
            Value<String?> priceBasis = const Value.absent(),
            Value<double?> priceQty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientsCompanion(
            id: id,
            displayName: displayName,
            normalizedKey: normalizedKey,
            categoryId: categoryId,
            usageCount: usageCount,
            inPantry: inPantry,
            pantryUpdatedAt: pantryUpdatedAt,
            pantrySyncedAt: pantrySyncedAt,
            priceCents: priceCents,
            priceBasis: priceBasis,
            priceQty: priceQty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String displayName,
            required String normalizedKey,
            Value<String?> categoryId = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<bool> inPantry = const Value.absent(),
            Value<DateTime?> pantryUpdatedAt = const Value.absent(),
            Value<DateTime?> pantrySyncedAt = const Value.absent(),
            Value<int?> priceCents = const Value.absent(),
            Value<String?> priceBasis = const Value.absent(),
            Value<double?> priceQty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientsCompanion.insert(
            id: id,
            displayName: displayName,
            normalizedKey: normalizedKey,
            categoryId: categoryId,
            usageCount: usageCount,
            inPantry: inPantry,
            pantryUpdatedAt: pantryUpdatedAt,
            pantrySyncedAt: pantrySyncedAt,
            priceCents: priceCents,
            priceBasis: priceBasis,
            priceQty: priceQty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$IngredientsTable, IngredientRow>(table),
                    $$IngredientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              ingredientAliasesRefs = false,
              recipeIngredientsRefs = false,
              shoppingListItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientAliasesRefs) db.ingredientAliases,
                if (recipeIngredientsRefs) db.recipeIngredients,
                if (shoppingListItemsRefs) db.shoppingListItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$IngredientsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$IngredientsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientAliasesRefs)
                    await $_getPrefetchedData<IngredientRow, $IngredientsTable,
                            IngredientAliasRow>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._ingredientAliasesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .ingredientAliasesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items),
                  if (recipeIngredientsRefs)
                    await $_getPrefetchedData<IngredientRow, $IngredientsTable,
                            RecipeIngredientRow>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._recipeIngredientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .recipeIngredientsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items),
                  if (shoppingListItemsRefs)
                    await $_getPrefetchedData<IngredientRow, $IngredientsTable,
                            ShoppingListItemRow>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._shoppingListItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .shoppingListItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IngredientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IngredientsTable,
    IngredientRow,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (IngredientRow, $$IngredientsTableReferences),
    IngredientRow,
    PrefetchHooks Function(
        {bool categoryId,
        bool ingredientAliasesRefs,
        bool recipeIngredientsRefs,
        bool shoppingListItemsRefs})>;
typedef $$IngredientAliasesTableCreateCompanionBuilder
    = IngredientAliasesCompanion Function({
  required String id,
  required String ingredientId,
  required String normalizedAlias,
  Value<int> rowid,
});
typedef $$IngredientAliasesTableUpdateCompanionBuilder
    = IngredientAliasesCompanion Function({
  Value<String> id,
  Value<String> ingredientId,
  Value<String> normalizedAlias,
  Value<int> rowid,
});

final class $$IngredientAliasesTableReferences extends BaseReferences<
    _$AppDatabase, $IngredientAliasesTable, IngredientAliasRow> {
  $$IngredientAliasesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients
          .createAlias('ingredient_aliases__ingredient_id__ingredients__id');

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<String>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IngredientAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedAlias => $composableBuilder(
      column: $table.normalizedAlias,
      builder: (column) => ColumnFilters(column));

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedAlias => $composableBuilder(
      column: $table.normalizedAlias,
      builder: (column) => ColumnOrderings(column));

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get normalizedAlias => $composableBuilder(
      column: $table.normalizedAlias, builder: (column) => column);

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientAliasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientAliasesTable,
    IngredientAliasRow,
    $$IngredientAliasesTableFilterComposer,
    $$IngredientAliasesTableOrderingComposer,
    $$IngredientAliasesTableAnnotationComposer,
    $$IngredientAliasesTableCreateCompanionBuilder,
    $$IngredientAliasesTableUpdateCompanionBuilder,
    (IngredientAliasRow, $$IngredientAliasesTableReferences),
    IngredientAliasRow,
    PrefetchHooks Function({bool ingredientId})> {
  $$IngredientAliasesTableTableManager(
      _$AppDatabase db, $IngredientAliasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientAliasesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> ingredientId = const Value.absent(),
            Value<String> normalizedAlias = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientAliasesCompanion(
            id: id,
            ingredientId: ingredientId,
            normalizedAlias: normalizedAlias,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String ingredientId,
            required String normalizedAlias,
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientAliasesCompanion.insert(
            id: id,
            ingredientId: ingredientId,
            normalizedAlias: normalizedAlias,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$IngredientAliasesTable, IngredientAliasRow>(
                        table),
                    $$IngredientAliasesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable: $$IngredientAliasesTableReferences
                        ._ingredientIdTable(db),
                    referencedColumn: $$IngredientAliasesTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IngredientAliasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IngredientAliasesTable,
    IngredientAliasRow,
    $$IngredientAliasesTableFilterComposer,
    $$IngredientAliasesTableOrderingComposer,
    $$IngredientAliasesTableAnnotationComposer,
    $$IngredientAliasesTableCreateCompanionBuilder,
    $$IngredientAliasesTableUpdateCompanionBuilder,
    (IngredientAliasRow, $$IngredientAliasesTableReferences),
    IngredientAliasRow,
    PrefetchHooks Function({bool ingredientId})>;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  required String id,
  required String code,
  required String displayName,
  required String plural,
  required String kind,
  Value<String?> baseUnitId,
  Value<double?> factorToBase,
  Value<int> rowid,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> displayName,
  Value<String> plural,
  Value<String> kind,
  Value<String?> baseUnitId,
  Value<double?> factorToBase,
  Value<int> rowid,
});

final class $$UnitsTableReferences
    extends BaseReferences<_$AppDatabase, $UnitsTable, UnitRow> {
  $$UnitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _baseUnitIdTable(_$AppDatabase db) =>
      db.units.createAlias('units__base_unit_id__units__id');

  $$UnitsTableProcessedTableManager? get baseUnitId {
    final $_column = $_itemColumn<String>('base_unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RecipeIngredientsTable, List<RecipeIngredientRow>>
      _recipeIngredientsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeIngredients,
              aliasName: 'units__id__recipe_ingredients__unit_id');

  $$RecipeIngredientsTableProcessedTableManager get recipeIngredientsRefs {
    final manager =
        $$RecipeIngredientsTableTableManager($_db, $_db.recipeIngredients)
            .filter((f) => f.unitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recipeIngredientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShoppingListItemsTable, List<ShoppingListItemRow>>
      _shoppingListItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.shoppingListItems,
              aliasName: 'units__id__shopping_list_items__unit_id');

  $$ShoppingListItemsTableProcessedTableManager get shoppingListItemsRefs {
    final manager =
        $$ShoppingListItemsTableTableManager($_db, $_db.shoppingListItems)
            .filter((f) => f.unitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_shoppingListItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShoppingItemSourcesTable,
      List<ShoppingItemSourceRow>> _shoppingItemSourcesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shoppingItemSources,
          aliasName: 'units__id__shopping_item_sources__unit_id');

  $$ShoppingItemSourcesTableProcessedTableManager get shoppingItemSourcesRefs {
    final manager =
        $$ShoppingItemSourcesTableTableManager($_db, $_db.shoppingItemSources)
            .filter((f) => f.unitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_shoppingItemSourcesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plural => $composableBuilder(
      column: $table.plural, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get factorToBase => $composableBuilder(
      column: $table.factorToBase, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get baseUnitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> recipeIngredientsRefs(
      Expression<bool> Function($$RecipeIngredientsTableFilterComposer f) f) {
    final $$RecipeIngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeIngredients,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeIngredientsTableFilterComposer(
              $db: $db,
              $table: $db.recipeIngredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> shoppingListItemsRefs(
      Expression<bool> Function($$ShoppingListItemsTableFilterComposer f) f) {
    final $$ShoppingListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingListItems,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListItemsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingListItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> shoppingItemSourcesRefs(
      Expression<bool> Function($$ShoppingItemSourcesTableFilterComposer f) f) {
    final $$ShoppingItemSourcesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingItemSources,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingItemSourcesTableFilterComposer(
              $db: $db,
              $table: $db.shoppingItemSources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plural => $composableBuilder(
      column: $table.plural, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get factorToBase => $composableBuilder(
      column: $table.factorToBase,
      builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get baseUnitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get plural =>
      $composableBuilder(column: $table.plural, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get factorToBase => $composableBuilder(
      column: $table.factorToBase, builder: (column) => column);

  $$UnitsTableAnnotationComposer get baseUnitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> recipeIngredientsRefs<T extends Object>(
      Expression<T> Function($$RecipeIngredientsTableAnnotationComposer a) f) {
    final $$RecipeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recipeIngredients,
            getReferencedColumn: (t) => t.unitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecipeIngredientsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recipeIngredients,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> shoppingListItemsRefs<T extends Object>(
      Expression<T> Function($$ShoppingListItemsTableAnnotationComposer a) f) {
    final $$ShoppingListItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.shoppingListItems,
            getReferencedColumn: (t) => t.unitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingListItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingListItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> shoppingItemSourcesRefs<T extends Object>(
      Expression<T> Function($$ShoppingItemSourcesTableAnnotationComposer a)
          f) {
    final $$ShoppingItemSourcesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.shoppingItemSources,
            getReferencedColumn: (t) => t.unitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingItemSourcesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingItemSources,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UnitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitsTable,
    UnitRow,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (UnitRow, $$UnitsTableReferences),
    UnitRow,
    PrefetchHooks Function(
        {bool baseUnitId,
        bool recipeIngredientsRefs,
        bool shoppingListItemsRefs,
        bool shoppingItemSourcesRefs})> {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> plural = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> baseUnitId = const Value.absent(),
            Value<double?> factorToBase = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            code: code,
            displayName: displayName,
            plural: plural,
            kind: kind,
            baseUnitId: baseUnitId,
            factorToBase: factorToBase,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String displayName,
            required String plural,
            required String kind,
            Value<String?> baseUnitId = const Value.absent(),
            Value<double?> factorToBase = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion.insert(
            id: id,
            code: code,
            displayName: displayName,
            plural: plural,
            kind: kind,
            baseUnitId: baseUnitId,
            factorToBase: factorToBase,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$UnitsTable, UnitRow>(table),
                    $$UnitsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {baseUnitId = false,
              recipeIngredientsRefs = false,
              shoppingListItemsRefs = false,
              shoppingItemSourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipeIngredientsRefs) db.recipeIngredients,
                if (shoppingListItemsRefs) db.shoppingListItems,
                if (shoppingItemSourcesRefs) db.shoppingItemSources
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (baseUnitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseUnitId,
                    referencedTable:
                        $$UnitsTableReferences._baseUnitIdTable(db),
                    referencedColumn:
                        $$UnitsTableReferences._baseUnitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeIngredientsRefs)
                    await $_getPrefetchedData<UnitRow, $UnitsTable,
                            RecipeIngredientRow>(
                        currentTable: table,
                        referencedTable: $$UnitsTableReferences
                            ._recipeIngredientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .recipeIngredientsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items),
                  if (shoppingListItemsRefs)
                    await $_getPrefetchedData<UnitRow, $UnitsTable,
                            ShoppingListItemRow>(
                        currentTable: table,
                        referencedTable: $$UnitsTableReferences
                            ._shoppingListItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .shoppingListItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items),
                  if (shoppingItemSourcesRefs)
                    await $_getPrefetchedData<UnitRow, $UnitsTable,
                            ShoppingItemSourceRow>(
                        currentTable: table,
                        referencedTable: $$UnitsTableReferences
                            ._shoppingItemSourcesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .shoppingItemSourcesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UnitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UnitsTable,
    UnitRow,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (UnitRow, $$UnitsTableReferences),
    UnitRow,
    PrefetchHooks Function(
        {bool baseUnitId,
        bool recipeIngredientsRefs,
        bool shoppingListItemsRefs,
        bool shoppingItemSourcesRefs})>;
typedef $$RecipeIngredientsTableCreateCompanionBuilder
    = RecipeIngredientsCompanion Function({
  required String id,
  required String recipeId,
  Value<String?> ingredientId,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<String?> qualifier,
  required String rawText,
  Value<String?> groupLabel,
  Value<int> position,
  Value<int> rowid,
});
typedef $$RecipeIngredientsTableUpdateCompanionBuilder
    = RecipeIngredientsCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String?> ingredientId,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<String?> qualifier,
  Value<String> rawText,
  Value<String?> groupLabel,
  Value<int> position,
  Value<int> rowid,
});

final class $$RecipeIngredientsTableReferences extends BaseReferences<
    _$AppDatabase, $RecipeIngredientsTable, RecipeIngredientRow> {
  $$RecipeIngredientsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_ingredients__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients
          .createAlias('recipe_ingredients__ingredient_id__ingredients__id');

  $$IngredientsTableProcessedTableManager? get ingredientId {
    final $_column = $_itemColumn<String>('ingredient_id');
    if ($_column == null) return null;
    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitIdTable(_$AppDatabase db) =>
      db.units.createAlias('recipe_ingredients__unit_id__units__id');

  $$UnitsTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<String>('unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecipeIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qualifier => $composableBuilder(
      column: $table.qualifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupLabel => $composableBuilder(
      column: $table.groupLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qualifier => $composableBuilder(
      column: $table.qualifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawText => $composableBuilder(
      column: $table.rawText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupLabel => $composableBuilder(
      column: $table.groupLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get qualifier =>
      $composableBuilder(column: $table.qualifier, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get groupLabel => $composableBuilder(
      column: $table.groupLabel, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeIngredientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeIngredientsTable,
    RecipeIngredientRow,
    $$RecipeIngredientsTableFilterComposer,
    $$RecipeIngredientsTableOrderingComposer,
    $$RecipeIngredientsTableAnnotationComposer,
    $$RecipeIngredientsTableCreateCompanionBuilder,
    $$RecipeIngredientsTableUpdateCompanionBuilder,
    (RecipeIngredientRow, $$RecipeIngredientsTableReferences),
    RecipeIngredientRow,
    PrefetchHooks Function({bool recipeId, bool ingredientId, bool unitId})> {
  $$RecipeIngredientsTableTableManager(
      _$AppDatabase db, $RecipeIngredientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeIngredientsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String?> ingredientId = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<String?> qualifier = const Value.absent(),
            Value<String> rawText = const Value.absent(),
            Value<String?> groupLabel = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeIngredientsCompanion(
            id: id,
            recipeId: recipeId,
            ingredientId: ingredientId,
            quantity: quantity,
            unitId: unitId,
            qualifier: qualifier,
            rawText: rawText,
            groupLabel: groupLabel,
            position: position,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recipeId,
            Value<String?> ingredientId = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<String?> qualifier = const Value.absent(),
            required String rawText,
            Value<String?> groupLabel = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeIngredientsCompanion.insert(
            id: id,
            recipeId: recipeId,
            ingredientId: ingredientId,
            quantity: quantity,
            unitId: unitId,
            qualifier: qualifier,
            rawText: rawText,
            groupLabel: groupLabel,
            position: position,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecipeIngredientsTable, RecipeIngredientRow>(
                        table),
                    $$RecipeIngredientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {recipeId = false, ingredientId = false, unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$RecipeIngredientsTableReferences._recipeIdTable(db),
                    referencedColumn: $$RecipeIngredientsTableReferences
                        ._recipeIdTable(db)
                        .id,
                  ) as T;
                }
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable: $$RecipeIngredientsTableReferences
                        ._ingredientIdTable(db),
                    referencedColumn: $$RecipeIngredientsTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$RecipeIngredientsTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$RecipeIngredientsTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecipeIngredientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeIngredientsTable,
    RecipeIngredientRow,
    $$RecipeIngredientsTableFilterComposer,
    $$RecipeIngredientsTableOrderingComposer,
    $$RecipeIngredientsTableAnnotationComposer,
    $$RecipeIngredientsTableCreateCompanionBuilder,
    $$RecipeIngredientsTableUpdateCompanionBuilder,
    (RecipeIngredientRow, $$RecipeIngredientsTableReferences),
    RecipeIngredientRow,
    PrefetchHooks Function({bool recipeId, bool ingredientId, bool unitId})>;
typedef $$RecipeStepsTableCreateCompanionBuilder = RecipeStepsCompanion
    Function({
  required String id,
  required String recipeId,
  required String instruction,
  Value<String?> groupLabel,
  Value<int> position,
  Value<int> rowid,
});
typedef $$RecipeStepsTableUpdateCompanionBuilder = RecipeStepsCompanion
    Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String> instruction,
  Value<String?> groupLabel,
  Value<int> position,
  Value<int> rowid,
});

final class $$RecipeStepsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStepRow> {
  $$RecipeStepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_steps__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecipeStepsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupLabel => $composableBuilder(
      column: $table.groupLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupLabel => $composableBuilder(
      column: $table.groupLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => column);

  GeneratedColumn<String> get groupLabel => $composableBuilder(
      column: $table.groupLabel, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeStepsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeStepsTable,
    RecipeStepRow,
    $$RecipeStepsTableFilterComposer,
    $$RecipeStepsTableOrderingComposer,
    $$RecipeStepsTableAnnotationComposer,
    $$RecipeStepsTableCreateCompanionBuilder,
    $$RecipeStepsTableUpdateCompanionBuilder,
    (RecipeStepRow, $$RecipeStepsTableReferences),
    RecipeStepRow,
    PrefetchHooks Function({bool recipeId})> {
  $$RecipeStepsTableTableManager(_$AppDatabase db, $RecipeStepsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String> instruction = const Value.absent(),
            Value<String?> groupLabel = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeStepsCompanion(
            id: id,
            recipeId: recipeId,
            instruction: instruction,
            groupLabel: groupLabel,
            position: position,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recipeId,
            required String instruction,
            Value<String?> groupLabel = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeStepsCompanion.insert(
            id: id,
            recipeId: recipeId,
            instruction: instruction,
            groupLabel: groupLabel,
            position: position,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecipeStepsTable, RecipeStepRow>(table),
                    $$RecipeStepsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$RecipeStepsTableReferences._recipeIdTable(db),
                    referencedColumn:
                        $$RecipeStepsTableReferences._recipeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecipeStepsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeStepsTable,
    RecipeStepRow,
    $$RecipeStepsTableFilterComposer,
    $$RecipeStepsTableOrderingComposer,
    $$RecipeStepsTableAnnotationComposer,
    $$RecipeStepsTableCreateCompanionBuilder,
    $$RecipeStepsTableUpdateCompanionBuilder,
    (RecipeStepRow, $$RecipeStepsTableReferences),
    RecipeStepRow,
    PrefetchHooks Function({bool recipeId})>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeTagsTable, List<RecipeTagRow>>
      _recipeTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeTags,
              aliasName: 'tags__id__recipe_tags__tag_id');

  $$RecipeTagsTableProcessedTableManager get recipeTagsRefs {
    final manager = $$RecipeTagsTableTableManager($_db, $_db.recipeTags)
        .filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> recipeTagsRefs(
      Expression<bool> Function($$RecipeTagsTableFilterComposer f) f) {
    final $$RecipeTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeTagsTableFilterComposer(
              $db: $db,
              $table: $db.recipeTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> recipeTagsRefs<T extends Object>(
      Expression<T> Function($$RecipeTagsTableAnnotationComposer a) f) {
    final $$RecipeTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.recipeTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTable,
    TagRow,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (TagRow, $$TagsTableReferences),
    TagRow,
    PrefetchHooks Function({bool recipeTagsRefs})> {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion(
            id: id,
            name: name,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion.insert(
            id: id,
            name: name,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TagsTable, TagRow>(table),
                    $$TagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (recipeTagsRefs) db.recipeTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, RecipeTagRow>(
                        currentTable: table,
                        referencedTable:
                            $$TagsTableReferences._recipeTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagsTableReferences(db, table, p0).recipeTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTable,
    TagRow,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (TagRow, $$TagsTableReferences),
    TagRow,
    PrefetchHooks Function({bool recipeTagsRefs})>;
typedef $$RecipeTagsTableCreateCompanionBuilder = RecipeTagsCompanion Function({
  required String recipeId,
  required String tagId,
  Value<int> rowid,
});
typedef $$RecipeTagsTableUpdateCompanionBuilder = RecipeTagsCompanion Function({
  Value<String> recipeId,
  Value<String> tagId,
  Value<int> rowid,
});

final class $$RecipeTagsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTagRow> {
  $$RecipeTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_tags__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('recipe_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager($_db, $_db.tags)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecipeTagsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableFilterComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableOrderingComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableAnnotationComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeTagsTable,
    RecipeTagRow,
    $$RecipeTagsTableFilterComposer,
    $$RecipeTagsTableOrderingComposer,
    $$RecipeTagsTableAnnotationComposer,
    $$RecipeTagsTableCreateCompanionBuilder,
    $$RecipeTagsTableUpdateCompanionBuilder,
    (RecipeTagRow, $$RecipeTagsTableReferences),
    RecipeTagRow,
    PrefetchHooks Function({bool recipeId, bool tagId})> {
  $$RecipeTagsTableTableManager(_$AppDatabase db, $RecipeTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> recipeId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeTagsCompanion(
            recipeId: recipeId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String recipeId,
            required String tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeTagsCompanion.insert(
            recipeId: recipeId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecipeTagsTable, RecipeTagRow>(table),
                    $$RecipeTagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$RecipeTagsTableReferences._recipeIdTable(db),
                    referencedColumn:
                        $$RecipeTagsTableReferences._recipeIdTable(db).id,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable:
                        $$RecipeTagsTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$RecipeTagsTableReferences._tagIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecipeTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeTagsTable,
    RecipeTagRow,
    $$RecipeTagsTableFilterComposer,
    $$RecipeTagsTableOrderingComposer,
    $$RecipeTagsTableAnnotationComposer,
    $$RecipeTagsTableCreateCompanionBuilder,
    $$RecipeTagsTableUpdateCompanionBuilder,
    (RecipeTagRow, $$RecipeTagsTableReferences),
    RecipeTagRow,
    PrefetchHooks Function({bool recipeId, bool tagId})>;
typedef $$MealPlanEntriesTableCreateCompanionBuilder = MealPlanEntriesCompanion
    Function({
  required String id,
  required String recipeId,
  required DateTime date,
  required String mealType,
  Value<int?> servingsOverride,
  Value<String?> note,
  Value<bool> done,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> spaceId,
  Value<int> rowid,
});
typedef $$MealPlanEntriesTableUpdateCompanionBuilder = MealPlanEntriesCompanion
    Function({
  Value<String> id,
  Value<String> recipeId,
  Value<DateTime> date,
  Value<String> mealType,
  Value<int?> servingsOverride,
  Value<String?> note,
  Value<bool> done,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> spaceId,
  Value<int> rowid,
});

final class $$MealPlanEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $MealPlanEntriesTable, MealPlanEntryRow> {
  $$MealPlanEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('meal_plan_entries__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MealPlanEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlanEntriesTable> {
  $$MealPlanEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get servingsOverride => $composableBuilder(
      column: $table.servingsOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealPlanEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlanEntriesTable> {
  $$MealPlanEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get servingsOverride => $composableBuilder(
      column: $table.servingsOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealPlanEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlanEntriesTable> {
  $$MealPlanEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<int> get servingsOverride => $composableBuilder(
      column: $table.servingsOverride, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealPlanEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealPlanEntriesTable,
    MealPlanEntryRow,
    $$MealPlanEntriesTableFilterComposer,
    $$MealPlanEntriesTableOrderingComposer,
    $$MealPlanEntriesTableAnnotationComposer,
    $$MealPlanEntriesTableCreateCompanionBuilder,
    $$MealPlanEntriesTableUpdateCompanionBuilder,
    (MealPlanEntryRow, $$MealPlanEntriesTableReferences),
    MealPlanEntryRow,
    PrefetchHooks Function({bool recipeId})> {
  $$MealPlanEntriesTableTableManager(
      _$AppDatabase db, $MealPlanEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlanEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlanEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlanEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> mealType = const Value.absent(),
            Value<int?> servingsOverride = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> done = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> spaceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealPlanEntriesCompanion(
            id: id,
            recipeId: recipeId,
            date: date,
            mealType: mealType,
            servingsOverride: servingsOverride,
            note: note,
            done: done,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            spaceId: spaceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recipeId,
            required DateTime date,
            required String mealType,
            Value<int?> servingsOverride = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> done = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> spaceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealPlanEntriesCompanion.insert(
            id: id,
            recipeId: recipeId,
            date: date,
            mealType: mealType,
            servingsOverride: servingsOverride,
            note: note,
            done: done,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            spaceId: spaceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MealPlanEntriesTable, MealPlanEntryRow>(table),
                    $$MealPlanEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$MealPlanEntriesTableReferences._recipeIdTable(db),
                    referencedColumn:
                        $$MealPlanEntriesTableReferences._recipeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MealPlanEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealPlanEntriesTable,
    MealPlanEntryRow,
    $$MealPlanEntriesTableFilterComposer,
    $$MealPlanEntriesTableOrderingComposer,
    $$MealPlanEntriesTableAnnotationComposer,
    $$MealPlanEntriesTableCreateCompanionBuilder,
    $$MealPlanEntriesTableUpdateCompanionBuilder,
    (MealPlanEntryRow, $$MealPlanEntriesTableReferences),
    MealPlanEntryRow,
    PrefetchHooks Function({bool recipeId})>;
typedef $$SharedMealsTableCreateCompanionBuilder = SharedMealsCompanion
    Function({
  required String id,
  required String spaceId,
  required DateTime date,
  required String mealType,
  Value<int?> servingsOverride,
  Value<String?> note,
  Value<bool> done,
  required String recipeJson,
  Value<String> authorId,
  Value<String> authorName,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$SharedMealsTableUpdateCompanionBuilder = SharedMealsCompanion
    Function({
  Value<String> id,
  Value<String> spaceId,
  Value<DateTime> date,
  Value<String> mealType,
  Value<int?> servingsOverride,
  Value<String?> note,
  Value<bool> done,
  Value<String> recipeJson,
  Value<String> authorId,
  Value<String> authorName,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$SharedMealsTableFilterComposer
    extends Composer<_$AppDatabase, $SharedMealsTable> {
  $$SharedMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get servingsOverride => $composableBuilder(
      column: $table.servingsOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeJson => $composableBuilder(
      column: $table.recipeJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authorId => $composableBuilder(
      column: $table.authorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authorName => $composableBuilder(
      column: $table.authorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$SharedMealsTableOrderingComposer
    extends Composer<_$AppDatabase, $SharedMealsTable> {
  $$SharedMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get servingsOverride => $composableBuilder(
      column: $table.servingsOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeJson => $composableBuilder(
      column: $table.recipeJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authorId => $composableBuilder(
      column: $table.authorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authorName => $composableBuilder(
      column: $table.authorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$SharedMealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SharedMealsTable> {
  $$SharedMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<int> get servingsOverride => $composableBuilder(
      column: $table.servingsOverride, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<String> get recipeJson => $composableBuilder(
      column: $table.recipeJson, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
      column: $table.authorName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SharedMealsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SharedMealsTable,
    SharedMealRow,
    $$SharedMealsTableFilterComposer,
    $$SharedMealsTableOrderingComposer,
    $$SharedMealsTableAnnotationComposer,
    $$SharedMealsTableCreateCompanionBuilder,
    $$SharedMealsTableUpdateCompanionBuilder,
    (
      SharedMealRow,
      BaseReferences<_$AppDatabase, $SharedMealsTable, SharedMealRow>
    ),
    SharedMealRow,
    PrefetchHooks Function()> {
  $$SharedMealsTableTableManager(_$AppDatabase db, $SharedMealsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SharedMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SharedMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SharedMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> spaceId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> mealType = const Value.absent(),
            Value<int?> servingsOverride = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> done = const Value.absent(),
            Value<String> recipeJson = const Value.absent(),
            Value<String> authorId = const Value.absent(),
            Value<String> authorName = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SharedMealsCompanion(
            id: id,
            spaceId: spaceId,
            date: date,
            mealType: mealType,
            servingsOverride: servingsOverride,
            note: note,
            done: done,
            recipeJson: recipeJson,
            authorId: authorId,
            authorName: authorName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String spaceId,
            required DateTime date,
            required String mealType,
            Value<int?> servingsOverride = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> done = const Value.absent(),
            required String recipeJson,
            Value<String> authorId = const Value.absent(),
            Value<String> authorName = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SharedMealsCompanion.insert(
            id: id,
            spaceId: spaceId,
            date: date,
            mealType: mealType,
            servingsOverride: servingsOverride,
            note: note,
            done: done,
            recipeJson: recipeJson,
            authorId: authorId,
            authorName: authorName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SharedMealsTable, SharedMealRow>(table),
                    BaseReferences<_$AppDatabase, $SharedMealsTable,
                        SharedMealRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SharedMealsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SharedMealsTable,
    SharedMealRow,
    $$SharedMealsTableFilterComposer,
    $$SharedMealsTableOrderingComposer,
    $$SharedMealsTableAnnotationComposer,
    $$SharedMealsTableCreateCompanionBuilder,
    $$SharedMealsTableUpdateCompanionBuilder,
    (
      SharedMealRow,
      BaseReferences<_$AppDatabase, $SharedMealsTable, SharedMealRow>
    ),
    SharedMealRow,
    PrefetchHooks Function()>;
typedef $$CookLogsTableCreateCompanionBuilder = CookLogsCompanion Function({
  required String id,
  required String recipeId,
  required DateTime cookedAt,
  Value<String?> note,
  Value<String?> mealPlanEntryId,
  Value<DateTime> createdAt,
  Value<int?> rating,
  Value<DateTime?> updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$CookLogsTableUpdateCompanionBuilder = CookLogsCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<DateTime> cookedAt,
  Value<String?> note,
  Value<String?> mealPlanEntryId,
  Value<DateTime> createdAt,
  Value<int?> rating,
  Value<DateTime?> updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

final class $$CookLogsTableReferences
    extends BaseReferences<_$AppDatabase, $CookLogsTable, CookLogRow> {
  $$CookLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('cook_logs__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CookLogsTableFilterComposer
    extends Composer<_$AppDatabase, $CookLogsTable> {
  $$CookLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cookedAt => $composableBuilder(
      column: $table.cookedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealPlanEntryId => $composableBuilder(
      column: $table.mealPlanEntryId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CookLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CookLogsTable> {
  $$CookLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cookedAt => $composableBuilder(
      column: $table.cookedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealPlanEntryId => $composableBuilder(
      column: $table.mealPlanEntryId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CookLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CookLogsTable> {
  $$CookLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get cookedAt =>
      $composableBuilder(column: $table.cookedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get mealPlanEntryId => $composableBuilder(
      column: $table.mealPlanEntryId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CookLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CookLogsTable,
    CookLogRow,
    $$CookLogsTableFilterComposer,
    $$CookLogsTableOrderingComposer,
    $$CookLogsTableAnnotationComposer,
    $$CookLogsTableCreateCompanionBuilder,
    $$CookLogsTableUpdateCompanionBuilder,
    (CookLogRow, $$CookLogsTableReferences),
    CookLogRow,
    PrefetchHooks Function({bool recipeId})> {
  $$CookLogsTableTableManager(_$AppDatabase db, $CookLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CookLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CookLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CookLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<DateTime> cookedAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> mealPlanEntryId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CookLogsCompanion(
            id: id,
            recipeId: recipeId,
            cookedAt: cookedAt,
            note: note,
            mealPlanEntryId: mealPlanEntryId,
            createdAt: createdAt,
            rating: rating,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recipeId,
            required DateTime cookedAt,
            Value<String?> note = const Value.absent(),
            Value<String?> mealPlanEntryId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CookLogsCompanion.insert(
            id: id,
            recipeId: recipeId,
            cookedAt: cookedAt,
            note: note,
            mealPlanEntryId: mealPlanEntryId,
            createdAt: createdAt,
            rating: rating,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CookLogsTable, CookLogRow>(table),
                    $$CookLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$CookLogsTableReferences._recipeIdTable(db),
                    referencedColumn:
                        $$CookLogsTableReferences._recipeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CookLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CookLogsTable,
    CookLogRow,
    $$CookLogsTableFilterComposer,
    $$CookLogsTableOrderingComposer,
    $$CookLogsTableAnnotationComposer,
    $$CookLogsTableCreateCompanionBuilder,
    $$CookLogsTableUpdateCompanionBuilder,
    (CookLogRow, $$CookLogsTableReferences),
    CookLogRow,
    PrefetchHooks Function({bool recipeId})>;
typedef $$SyncTombstonesTableCreateCompanionBuilder = SyncTombstonesCompanion
    Function({
  required String kind,
  required String id,
  required DateTime deletedAt,
  Value<String?> spaceId,
  Value<int> rowid,
});
typedef $$SyncTombstonesTableUpdateCompanionBuilder = SyncTombstonesCompanion
    Function({
  Value<String> kind,
  Value<String> id,
  Value<DateTime> deletedAt,
  Value<String?> spaceId,
  Value<int> rowid,
});

class $$SyncTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnFilters(column));
}

class $$SyncTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnOrderings(column));
}

class $$SyncTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);
}

class $$SyncTombstonesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncTombstonesTable,
    SyncTombstoneRow,
    $$SyncTombstonesTableFilterComposer,
    $$SyncTombstonesTableOrderingComposer,
    $$SyncTombstonesTableAnnotationComposer,
    $$SyncTombstonesTableCreateCompanionBuilder,
    $$SyncTombstonesTableUpdateCompanionBuilder,
    (
      SyncTombstoneRow,
      BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstoneRow>
    ),
    SyncTombstoneRow,
    PrefetchHooks Function()> {
  $$SyncTombstonesTableTableManager(
      _$AppDatabase db, $SyncTombstonesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> kind = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<DateTime> deletedAt = const Value.absent(),
            Value<String?> spaceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncTombstonesCompanion(
            kind: kind,
            id: id,
            deletedAt: deletedAt,
            spaceId: spaceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String kind,
            required String id,
            required DateTime deletedAt,
            Value<String?> spaceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncTombstonesCompanion.insert(
            kind: kind,
            id: id,
            deletedAt: deletedAt,
            spaceId: spaceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncTombstonesTable, SyncTombstoneRow>(table),
                    BaseReferences<_$AppDatabase, $SyncTombstonesTable,
                        SyncTombstoneRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncTombstonesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncTombstonesTable,
    SyncTombstoneRow,
    $$SyncTombstonesTableFilterComposer,
    $$SyncTombstonesTableOrderingComposer,
    $$SyncTombstonesTableAnnotationComposer,
    $$SyncTombstonesTableCreateCompanionBuilder,
    $$SyncTombstonesTableUpdateCompanionBuilder,
    (
      SyncTombstoneRow,
      BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstoneRow>
    ),
    SyncTombstoneRow,
    PrefetchHooks Function()>;
typedef $$ShoppingListsTableCreateCompanionBuilder = ShoppingListsCompanion
    Function({
  required String id,
  required String name,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> spaceId,
  Value<int> rowid,
});
typedef $$ShoppingListsTableUpdateCompanionBuilder = ShoppingListsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> spaceId,
  Value<int> rowid,
});

final class $$ShoppingListsTableReferences extends BaseReferences<_$AppDatabase,
    $ShoppingListsTable, ShoppingListRow> {
  $$ShoppingListsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShoppingListItemsTable, List<ShoppingListItemRow>>
      _shoppingListItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.shoppingListItems,
              aliasName: 'shopping_lists__id__shopping_list_items__list_id');

  $$ShoppingListItemsTableProcessedTableManager get shoppingListItemsRefs {
    final manager =
        $$ShoppingListItemsTableTableManager($_db, $_db.shoppingListItems)
            .filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_shoppingListItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnFilters(column));

  Expression<bool> shoppingListItemsRefs(
      Expression<bool> Function($$ShoppingListItemsTableFilterComposer f) f) {
    final $$ShoppingListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingListItems,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListItemsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingListItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spaceId => $composableBuilder(
      column: $table.spaceId, builder: (column) => ColumnOrderings(column));
}

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  Expression<T> shoppingListItemsRefs<T extends Object>(
      Expression<T> Function($$ShoppingListItemsTableAnnotationComposer a) f) {
    final $$ShoppingListItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.shoppingListItems,
            getReferencedColumn: (t) => t.listId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingListItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingListItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ShoppingListsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingListsTable,
    ShoppingListRow,
    $$ShoppingListsTableFilterComposer,
    $$ShoppingListsTableOrderingComposer,
    $$ShoppingListsTableAnnotationComposer,
    $$ShoppingListsTableCreateCompanionBuilder,
    $$ShoppingListsTableUpdateCompanionBuilder,
    (ShoppingListRow, $$ShoppingListsTableReferences),
    ShoppingListRow,
    PrefetchHooks Function({bool shoppingListItemsRefs})> {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> spaceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListsCompanion(
            id: id,
            name: name,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            spaceId: spaceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> spaceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListsCompanion.insert(
            id: id,
            name: name,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            spaceId: spaceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShoppingListsTable, ShoppingListRow>(table),
                    $$ShoppingListsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({shoppingListItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shoppingListItemsRefs) db.shoppingListItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shoppingListItemsRefs)
                    await $_getPrefetchedData<ShoppingListRow,
                            $ShoppingListsTable, ShoppingListItemRow>(
                        currentTable: table,
                        referencedTable: $$ShoppingListsTableReferences
                            ._shoppingListItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShoppingListsTableReferences(db, table, p0)
                                .shoppingListItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.listId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ShoppingListsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingListsTable,
    ShoppingListRow,
    $$ShoppingListsTableFilterComposer,
    $$ShoppingListsTableOrderingComposer,
    $$ShoppingListsTableAnnotationComposer,
    $$ShoppingListsTableCreateCompanionBuilder,
    $$ShoppingListsTableUpdateCompanionBuilder,
    (ShoppingListRow, $$ShoppingListsTableReferences),
    ShoppingListRow,
    PrefetchHooks Function({bool shoppingListItemsRefs})>;
typedef $$ShoppingListItemsTableCreateCompanionBuilder
    = ShoppingListItemsCompanion Function({
  required String id,
  required String listId,
  Value<String?> ingredientId,
  Value<String?> manualName,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<bool> checked,
  Value<String?> note,
  Value<int> position,
  Value<DateTime?> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> addedBy,
  Value<String?> checkedBy,
  Value<int> rowid,
});
typedef $$ShoppingListItemsTableUpdateCompanionBuilder
    = ShoppingListItemsCompanion Function({
  Value<String> id,
  Value<String> listId,
  Value<String?> ingredientId,
  Value<String?> manualName,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<bool> checked,
  Value<String?> note,
  Value<int> position,
  Value<DateTime?> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> addedBy,
  Value<String?> checkedBy,
  Value<int> rowid,
});

final class $$ShoppingListItemsTableReferences extends BaseReferences<
    _$AppDatabase, $ShoppingListItemsTable, ShoppingListItemRow> {
  $$ShoppingListItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ShoppingListsTable _listIdTable(_$AppDatabase db) => db.shoppingLists
      .createAlias('shopping_list_items__list_id__shopping_lists__id');

  $$ShoppingListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$ShoppingListsTableTableManager($_db, $_db.shoppingLists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients
          .createAlias('shopping_list_items__ingredient_id__ingredients__id');

  $$IngredientsTableProcessedTableManager? get ingredientId {
    final $_column = $_itemColumn<String>('ingredient_id');
    if ($_column == null) return null;
    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitIdTable(_$AppDatabase db) =>
      db.units.createAlias('shopping_list_items__unit_id__units__id');

  $$UnitsTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<String>('unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ShoppingItemSourcesTable,
      List<ShoppingItemSourceRow>> _shoppingItemSourcesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shoppingItemSources,
          aliasName: 'shopping_list_items__id__shopping_item_sources__item_id');

  $$ShoppingItemSourcesTableProcessedTableManager get shoppingItemSourcesRefs {
    final manager =
        $$ShoppingItemSourcesTableTableManager($_db, $_db.shoppingItemSources)
            .filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_shoppingItemSourcesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShoppingListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manualName => $composableBuilder(
      column: $table.manualName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get checked => $composableBuilder(
      column: $table.checked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addedBy => $composableBuilder(
      column: $table.addedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkedBy => $composableBuilder(
      column: $table.checkedBy, builder: (column) => ColumnFilters(column));

  $$ShoppingListsTableFilterComposer get listId {
    final $$ShoppingListsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.shoppingLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> shoppingItemSourcesRefs(
      Expression<bool> Function($$ShoppingItemSourcesTableFilterComposer f) f) {
    final $$ShoppingItemSourcesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingItemSources,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingItemSourcesTableFilterComposer(
              $db: $db,
              $table: $db.shoppingItemSources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShoppingListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manualName => $composableBuilder(
      column: $table.manualName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get checked => $composableBuilder(
      column: $table.checked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addedBy => $composableBuilder(
      column: $table.addedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkedBy => $composableBuilder(
      column: $table.checkedBy, builder: (column) => ColumnOrderings(column));

  $$ShoppingListsTableOrderingComposer get listId {
    final $$ShoppingListsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.shoppingLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListsTableOrderingComposer(
              $db: $db,
              $table: $db.shoppingLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShoppingListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get manualName => $composableBuilder(
      column: $table.manualName, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get addedBy =>
      $composableBuilder(column: $table.addedBy, builder: (column) => column);

  GeneratedColumn<String> get checkedBy =>
      $composableBuilder(column: $table.checkedBy, builder: (column) => column);

  $$ShoppingListsTableAnnotationComposer get listId {
    final $$ShoppingListsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.shoppingLists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListsTableAnnotationComposer(
              $db: $db,
              $table: $db.shoppingLists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> shoppingItemSourcesRefs<T extends Object>(
      Expression<T> Function($$ShoppingItemSourcesTableAnnotationComposer a)
          f) {
    final $$ShoppingItemSourcesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.shoppingItemSources,
            getReferencedColumn: (t) => t.itemId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingItemSourcesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingItemSources,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ShoppingListItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingListItemsTable,
    ShoppingListItemRow,
    $$ShoppingListItemsTableFilterComposer,
    $$ShoppingListItemsTableOrderingComposer,
    $$ShoppingListItemsTableAnnotationComposer,
    $$ShoppingListItemsTableCreateCompanionBuilder,
    $$ShoppingListItemsTableUpdateCompanionBuilder,
    (ShoppingListItemRow, $$ShoppingListItemsTableReferences),
    ShoppingListItemRow,
    PrefetchHooks Function(
        {bool listId,
        bool ingredientId,
        bool unitId,
        bool shoppingItemSourcesRefs})> {
  $$ShoppingListItemsTableTableManager(
      _$AppDatabase db, $ShoppingListItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> listId = const Value.absent(),
            Value<String?> ingredientId = const Value.absent(),
            Value<String?> manualName = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<bool> checked = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> addedBy = const Value.absent(),
            Value<String?> checkedBy = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemsCompanion(
            id: id,
            listId: listId,
            ingredientId: ingredientId,
            manualName: manualName,
            quantity: quantity,
            unitId: unitId,
            checked: checked,
            note: note,
            position: position,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            addedBy: addedBy,
            checkedBy: checkedBy,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String listId,
            Value<String?> ingredientId = const Value.absent(),
            Value<String?> manualName = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<bool> checked = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> addedBy = const Value.absent(),
            Value<String?> checkedBy = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemsCompanion.insert(
            id: id,
            listId: listId,
            ingredientId: ingredientId,
            manualName: manualName,
            quantity: quantity,
            unitId: unitId,
            checked: checked,
            note: note,
            position: position,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            addedBy: addedBy,
            checkedBy: checkedBy,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShoppingListItemsTable, ShoppingListItemRow>(
                        table),
                    $$ShoppingListItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {listId = false,
              ingredientId = false,
              unitId = false,
              shoppingItemSourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shoppingItemSourcesRefs) db.shoppingItemSources
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (listId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listId,
                    referencedTable:
                        $$ShoppingListItemsTableReferences._listIdTable(db),
                    referencedColumn:
                        $$ShoppingListItemsTableReferences._listIdTable(db).id,
                  ) as T;
                }
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable: $$ShoppingListItemsTableReferences
                        ._ingredientIdTable(db),
                    referencedColumn: $$ShoppingListItemsTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$ShoppingListItemsTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$ShoppingListItemsTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shoppingItemSourcesRefs)
                    await $_getPrefetchedData<ShoppingListItemRow,
                            $ShoppingListItemsTable, ShoppingItemSourceRow>(
                        currentTable: table,
                        referencedTable: $$ShoppingListItemsTableReferences
                            ._shoppingItemSourcesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShoppingListItemsTableReferences(db, table, p0)
                                .shoppingItemSourcesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ShoppingListItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingListItemsTable,
    ShoppingListItemRow,
    $$ShoppingListItemsTableFilterComposer,
    $$ShoppingListItemsTableOrderingComposer,
    $$ShoppingListItemsTableAnnotationComposer,
    $$ShoppingListItemsTableCreateCompanionBuilder,
    $$ShoppingListItemsTableUpdateCompanionBuilder,
    (ShoppingListItemRow, $$ShoppingListItemsTableReferences),
    ShoppingListItemRow,
    PrefetchHooks Function(
        {bool listId,
        bool ingredientId,
        bool unitId,
        bool shoppingItemSourcesRefs})>;
typedef $$ShoppingItemSourcesTableCreateCompanionBuilder
    = ShoppingItemSourcesCompanion Function({
  required String itemId,
  required String recipeId,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<int> rowid,
});
typedef $$ShoppingItemSourcesTableUpdateCompanionBuilder
    = ShoppingItemSourcesCompanion Function({
  Value<String> itemId,
  Value<String> recipeId,
  Value<double?> quantity,
  Value<String?> unitId,
  Value<int> rowid,
});

final class $$ShoppingItemSourcesTableReferences extends BaseReferences<
    _$AppDatabase, $ShoppingItemSourcesTable, ShoppingItemSourceRow> {
  $$ShoppingItemSourcesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ShoppingListItemsTable _itemIdTable(_$AppDatabase db) => db
      .shoppingListItems
      .createAlias('shopping_item_sources__item_id__shopping_list_items__id');

  $$ShoppingListItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager =
        $$ShoppingListItemsTableTableManager($_db, $_db.shoppingListItems)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('shopping_item_sources__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitIdTable(_$AppDatabase db) =>
      db.units.createAlias('shopping_item_sources__unit_id__units__id');

  $$UnitsTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<String>('unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ShoppingItemSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingItemSourcesTable> {
  $$ShoppingItemSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  $$ShoppingListItemsTableFilterComposer get itemId {
    final $$ShoppingListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.shoppingListItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListItemsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingListItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShoppingItemSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingItemSourcesTable> {
  $$ShoppingItemSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  $$ShoppingListItemsTableOrderingComposer get itemId {
    final $$ShoppingListItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.shoppingListItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingListItemsTableOrderingComposer(
              $db: $db,
              $table: $db.shoppingListItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShoppingItemSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingItemSourcesTable> {
  $$ShoppingItemSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$ShoppingListItemsTableAnnotationComposer get itemId {
    final $$ShoppingListItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.itemId,
            referencedTable: $db.shoppingListItems,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ShoppingListItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.shoppingListItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShoppingItemSourcesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingItemSourcesTable,
    ShoppingItemSourceRow,
    $$ShoppingItemSourcesTableFilterComposer,
    $$ShoppingItemSourcesTableOrderingComposer,
    $$ShoppingItemSourcesTableAnnotationComposer,
    $$ShoppingItemSourcesTableCreateCompanionBuilder,
    $$ShoppingItemSourcesTableUpdateCompanionBuilder,
    (ShoppingItemSourceRow, $$ShoppingItemSourcesTableReferences),
    ShoppingItemSourceRow,
    PrefetchHooks Function({bool itemId, bool recipeId, bool unitId})> {
  $$ShoppingItemSourcesTableTableManager(
      _$AppDatabase db, $ShoppingItemSourcesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingItemSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingItemSourcesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingItemSourcesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemId = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingItemSourcesCompanion(
            itemId: itemId,
            recipeId: recipeId,
            quantity: quantity,
            unitId: unitId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemId,
            required String recipeId,
            Value<double?> quantity = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingItemSourcesCompanion.insert(
            itemId: itemId,
            recipeId: recipeId,
            quantity: quantity,
            unitId: unitId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShoppingItemSourcesTable,
                        ShoppingItemSourceRow>(table),
                    $$ShoppingItemSourcesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {itemId = false, recipeId = false, unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable:
                        $$ShoppingItemSourcesTableReferences._itemIdTable(db),
                    referencedColumn: $$ShoppingItemSourcesTableReferences
                        ._itemIdTable(db)
                        .id,
                  ) as T;
                }
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$ShoppingItemSourcesTableReferences._recipeIdTable(db),
                    referencedColumn: $$ShoppingItemSourcesTableReferences
                        ._recipeIdTable(db)
                        .id,
                  ) as T;
                }
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$ShoppingItemSourcesTableReferences._unitIdTable(db),
                    referencedColumn: $$ShoppingItemSourcesTableReferences
                        ._unitIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ShoppingItemSourcesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingItemSourcesTable,
    ShoppingItemSourceRow,
    $$ShoppingItemSourcesTableFilterComposer,
    $$ShoppingItemSourcesTableOrderingComposer,
    $$ShoppingItemSourcesTableAnnotationComposer,
    $$ShoppingItemSourcesTableCreateCompanionBuilder,
    $$ShoppingItemSourcesTableUpdateCompanionBuilder,
    (ShoppingItemSourceRow, $$ShoppingItemSourcesTableReferences),
    ShoppingItemSourceRow,
    PrefetchHooks Function({bool itemId, bool recipeId, bool unitId})>;
typedef $$NormalizerTermsTableCreateCompanionBuilder = NormalizerTermsCompanion
    Function({
  required String id,
  required String term,
  required String kind,
  Value<int> rowid,
});
typedef $$NormalizerTermsTableUpdateCompanionBuilder = NormalizerTermsCompanion
    Function({
  Value<String> id,
  Value<String> term,
  Value<String> kind,
  Value<int> rowid,
});

class $$NormalizerTermsTableFilterComposer
    extends Composer<_$AppDatabase, $NormalizerTermsTable> {
  $$NormalizerTermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));
}

class $$NormalizerTermsTableOrderingComposer
    extends Composer<_$AppDatabase, $NormalizerTermsTable> {
  $$NormalizerTermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));
}

class $$NormalizerTermsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NormalizerTermsTable> {
  $$NormalizerTermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$NormalizerTermsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NormalizerTermsTable,
    NormalizerTermRow,
    $$NormalizerTermsTableFilterComposer,
    $$NormalizerTermsTableOrderingComposer,
    $$NormalizerTermsTableAnnotationComposer,
    $$NormalizerTermsTableCreateCompanionBuilder,
    $$NormalizerTermsTableUpdateCompanionBuilder,
    (
      NormalizerTermRow,
      BaseReferences<_$AppDatabase, $NormalizerTermsTable, NormalizerTermRow>
    ),
    NormalizerTermRow,
    PrefetchHooks Function()> {
  $$NormalizerTermsTableTableManager(
      _$AppDatabase db, $NormalizerTermsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NormalizerTermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NormalizerTermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NormalizerTermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> term = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NormalizerTermsCompanion(
            id: id,
            term: term,
            kind: kind,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String term,
            required String kind,
            Value<int> rowid = const Value.absent(),
          }) =>
              NormalizerTermsCompanion.insert(
            id: id,
            term: term,
            kind: kind,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$NormalizerTermsTable, NormalizerTermRow>(
                        table),
                    BaseReferences<_$AppDatabase, $NormalizerTermsTable,
                        NormalizerTermRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NormalizerTermsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NormalizerTermsTable,
    NormalizerTermRow,
    $$NormalizerTermsTableFilterComposer,
    $$NormalizerTermsTableOrderingComposer,
    $$NormalizerTermsTableAnnotationComposer,
    $$NormalizerTermsTableCreateCompanionBuilder,
    $$NormalizerTermsTableUpdateCompanionBuilder,
    (
      NormalizerTermRow,
      BaseReferences<_$AppDatabase, $NormalizerTermsTable, NormalizerTermRow>
    ),
    NormalizerTermRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$IngredientAliasesTableTableManager get ingredientAliases =>
      $$IngredientAliasesTableTableManager(_db, _db.ingredientAliases);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(_db, _db.recipeIngredients);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db, _db.recipeSteps);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db, _db.recipeTags);
  $$MealPlanEntriesTableTableManager get mealPlanEntries =>
      $$MealPlanEntriesTableTableManager(_db, _db.mealPlanEntries);
  $$SharedMealsTableTableManager get sharedMeals =>
      $$SharedMealsTableTableManager(_db, _db.sharedMeals);
  $$CookLogsTableTableManager get cookLogs =>
      $$CookLogsTableTableManager(_db, _db.cookLogs);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(_db, _db.shoppingListItems);
  $$ShoppingItemSourcesTableTableManager get shoppingItemSources =>
      $$ShoppingItemSourcesTableTableManager(_db, _db.shoppingItemSources);
  $$NormalizerTermsTableTableManager get normalizerTerms =>
      $$NormalizerTermsTableTableManager(_db, _db.normalizerTerms);
}
