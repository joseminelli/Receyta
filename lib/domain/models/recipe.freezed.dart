// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recipe {
  String get id;
  String get name;
  DateTime get createdAt;
  DateTime get updatedAt;
  String? get folderId;
  String? get about;
  int? get prepMinutes;
  int? get cookMinutes;
  int? get servings;
  String? get imagePath;

  /// Foto já enviada ao Storage (ver `Recipes.imageSyncedPath`). Só o
  /// serviço de envio mexe nisso; precisa viajar no modelo pra o salvar da
  /// receita não zerar o campo.
  String? get imageSyncedPath;
  String? get sourceUrl;
  String? get notes;

  /// Aparência do azulejo escolhida pelo usuário (§9.4). Nulo em qualquer um
  /// = deriva do id / pareamento padrão.
  TileColor? get tileColor;
  TileMotif? get tileMotif;
  bool get isFavorite;

  /// Preenchido só nas linhas da lixeira (RF-01.6). `null` = receita ativa.
  DateTime? get deletedAt;

  /// Última abertura ou criação — ordena a prateleira "Recentes" da home.
  DateTime? get lastOpenedAt;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecipeCopyWith<Recipe> get copyWith =>
      _$RecipeCopyWithImpl<Recipe>(this as Recipe, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as Recipe;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Recipe &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.folderId, _this.folderId) ||
                other.folderId == _this.folderId) &&
            (identical(other.about, _this.about) ||
                other.about == _this.about) &&
            (identical(other.prepMinutes, _this.prepMinutes) ||
                other.prepMinutes == _this.prepMinutes) &&
            (identical(other.cookMinutes, _this.cookMinutes) ||
                other.cookMinutes == _this.cookMinutes) &&
            (identical(other.servings, _this.servings) ||
                other.servings == _this.servings) &&
            (identical(other.imagePath, _this.imagePath) ||
                other.imagePath == _this.imagePath) &&
            (identical(other.imageSyncedPath, _this.imageSyncedPath) ||
                other.imageSyncedPath == _this.imageSyncedPath) &&
            (identical(other.sourceUrl, _this.sourceUrl) ||
                other.sourceUrl == _this.sourceUrl) &&
            (identical(other.notes, _this.notes) ||
                other.notes == _this.notes) &&
            (identical(other.tileColor, _this.tileColor) ||
                other.tileColor == _this.tileColor) &&
            (identical(other.tileMotif, _this.tileMotif) ||
                other.tileMotif == _this.tileMotif) &&
            (identical(other.isFavorite, _this.isFavorite) ||
                other.isFavorite == _this.isFavorite) &&
            (identical(other.deletedAt, _this.deletedAt) ||
                other.deletedAt == _this.deletedAt) &&
            (identical(other.lastOpenedAt, _this.lastOpenedAt) ||
                other.lastOpenedAt == _this.lastOpenedAt));
  }

  @override
  int get hashCode {
    final _this = this as Recipe;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.name,
        _this.createdAt,
        _this.updatedAt,
        _this.folderId,
        _this.about,
        _this.prepMinutes,
        _this.cookMinutes,
        _this.servings,
        _this.imagePath,
        _this.imageSyncedPath,
        _this.sourceUrl,
        _this.notes,
        _this.tileColor,
        _this.tileMotif,
        _this.isFavorite,
        _this.deletedAt,
        _this.lastOpenedAt);
  }

  @override
  String toString() {
    final _this = this as Recipe;
    return 'Recipe(id: ${_this.id}, name: ${_this.name}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, folderId: ${_this.folderId}, about: ${_this.about}, prepMinutes: ${_this.prepMinutes}, cookMinutes: ${_this.cookMinutes}, servings: ${_this.servings}, imagePath: ${_this.imagePath}, imageSyncedPath: ${_this.imageSyncedPath}, sourceUrl: ${_this.sourceUrl}, notes: ${_this.notes}, tileColor: ${_this.tileColor}, tileMotif: ${_this.tileMotif}, isFavorite: ${_this.isFavorite}, deletedAt: ${_this.deletedAt}, lastOpenedAt: ${_this.lastOpenedAt})';
  }
}

/// @nodoc
abstract mixin class $RecipeCopyWith<$Res> {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) _then) =
      _$RecipeCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      DateTime createdAt,
      DateTime updatedAt,
      String? folderId,
      String? about,
      int? prepMinutes,
      int? cookMinutes,
      int? servings,
      String? imagePath,
      String? imageSyncedPath,
      String? sourceUrl,
      String? notes,
      TileColor? tileColor,
      TileMotif? tileMotif,
      bool isFavorite,
      DateTime? deletedAt,
      DateTime? lastOpenedAt});
}

/// @nodoc
class _$RecipeCopyWithImpl<$Res> implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._self, this._then);

  final Recipe _self;
  final $Res Function(Recipe) _then;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? folderId = freezed,
    Object? about = freezed,
    Object? prepMinutes = freezed,
    Object? cookMinutes = freezed,
    Object? servings = freezed,
    Object? imagePath = freezed,
    Object? imageSyncedPath = freezed,
    Object? sourceUrl = freezed,
    Object? notes = freezed,
    Object? tileColor = freezed,
    Object? tileMotif = freezed,
    Object? isFavorite = null,
    Object? deletedAt = freezed,
    Object? lastOpenedAt = freezed,
  }) {
    return _then(Recipe(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      folderId: freezed == folderId
          ? _self.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      about: freezed == about
          ? _self.about
          : about // ignore: cast_nullable_to_non_nullable
              as String?,
      prepMinutes: freezed == prepMinutes
          ? _self.prepMinutes
          : prepMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      cookMinutes: freezed == cookMinutes
          ? _self.cookMinutes
          : cookMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: freezed == servings
          ? _self.servings
          : servings // ignore: cast_nullable_to_non_nullable
              as int?,
      imagePath: freezed == imagePath
          ? _self.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      imageSyncedPath: freezed == imageSyncedPath
          ? _self.imageSyncedPath
          : imageSyncedPath // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceUrl: freezed == sourceUrl
          ? _self.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      tileColor: freezed == tileColor
          ? _self.tileColor
          : tileColor // ignore: cast_nullable_to_non_nullable
              as TileColor?,
      tileMotif: freezed == tileMotif
          ? _self.tileMotif
          : tileMotif // ignore: cast_nullable_to_non_nullable
              as TileMotif?,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastOpenedAt: freezed == lastOpenedAt
          ? _self.lastOpenedAt
          : lastOpenedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Recipe].
extension RecipePatterns on Recipe {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Recipe value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Recipe() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Recipe value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recipe():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Recipe value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recipe() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String name,
            DateTime createdAt,
            DateTime updatedAt,
            String? folderId,
            String? about,
            int? prepMinutes,
            int? cookMinutes,
            int? servings,
            String? imagePath,
            String? imageSyncedPath,
            String? sourceUrl,
            String? notes,
            TileColor? tileColor,
            TileMotif? tileMotif,
            bool isFavorite,
            DateTime? deletedAt,
            DateTime? lastOpenedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Recipe() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.createdAt,
            _that.updatedAt,
            _that.folderId,
            _that.about,
            _that.prepMinutes,
            _that.cookMinutes,
            _that.servings,
            _that.imagePath,
            _that.imageSyncedPath,
            _that.sourceUrl,
            _that.notes,
            _that.tileColor,
            _that.tileMotif,
            _that.isFavorite,
            _that.deletedAt,
            _that.lastOpenedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String name,
            DateTime createdAt,
            DateTime updatedAt,
            String? folderId,
            String? about,
            int? prepMinutes,
            int? cookMinutes,
            int? servings,
            String? imagePath,
            String? imageSyncedPath,
            String? sourceUrl,
            String? notes,
            TileColor? tileColor,
            TileMotif? tileMotif,
            bool isFavorite,
            DateTime? deletedAt,
            DateTime? lastOpenedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recipe():
        return $default(
            _that.id,
            _that.name,
            _that.createdAt,
            _that.updatedAt,
            _that.folderId,
            _that.about,
            _that.prepMinutes,
            _that.cookMinutes,
            _that.servings,
            _that.imagePath,
            _that.imageSyncedPath,
            _that.sourceUrl,
            _that.notes,
            _that.tileColor,
            _that.tileMotif,
            _that.isFavorite,
            _that.deletedAt,
            _that.lastOpenedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String name,
            DateTime createdAt,
            DateTime updatedAt,
            String? folderId,
            String? about,
            int? prepMinutes,
            int? cookMinutes,
            int? servings,
            String? imagePath,
            String? imageSyncedPath,
            String? sourceUrl,
            String? notes,
            TileColor? tileColor,
            TileMotif? tileMotif,
            bool isFavorite,
            DateTime? deletedAt,
            DateTime? lastOpenedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recipe() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.createdAt,
            _that.updatedAt,
            _that.folderId,
            _that.about,
            _that.prepMinutes,
            _that.cookMinutes,
            _that.servings,
            _that.imagePath,
            _that.imageSyncedPath,
            _that.sourceUrl,
            _that.notes,
            _that.tileColor,
            _that.tileMotif,
            _that.isFavorite,
            _that.deletedAt,
            _that.lastOpenedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Recipe implements Recipe {
  const _Recipe(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.updatedAt,
      this.folderId,
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
      this.isFavorite = false,
      this.deletedAt,
      this.lastOpenedAt});

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? folderId;
  @override
  final String? about;
  @override
  final int? prepMinutes;
  @override
  final int? cookMinutes;
  @override
  final int? servings;
  @override
  final String? imagePath;

  /// Foto já enviada ao Storage (ver `Recipes.imageSyncedPath`). Só o
  /// serviço de envio mexe nisso; precisa viajar no modelo pra o salvar da
  /// receita não zerar o campo.
  @override
  final String? imageSyncedPath;
  @override
  final String? sourceUrl;
  @override
  final String? notes;

  /// Aparência do azulejo escolhida pelo usuário (§9.4). Nulo em qualquer um
  /// = deriva do id / pareamento padrão.
  @override
  final TileColor? tileColor;
  @override
  final TileMotif? tileMotif;
  @override
  @JsonKey()
  final bool isFavorite;

  /// Preenchido só nas linhas da lixeira (RF-01.6). `null` = receita ativa.
  @override
  final DateTime? deletedAt;

  /// Última abertura ou criação — ordena a prateleira "Recentes" da home.
  @override
  final DateTime? lastOpenedAt;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecipeCopyWith<_Recipe> get copyWith =>
      __$RecipeCopyWithImpl<_Recipe>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Recipe &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.about, about) || other.about == about) &&
            (identical(other.prepMinutes, prepMinutes) ||
                other.prepMinutes == prepMinutes) &&
            (identical(other.cookMinutes, cookMinutes) ||
                other.cookMinutes == cookMinutes) &&
            (identical(other.servings, servings) ||
                other.servings == servings) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.imageSyncedPath, imageSyncedPath) ||
                other.imageSyncedPath == imageSyncedPath) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.tileColor, tileColor) ||
                other.tileColor == tileColor) &&
            (identical(other.tileMotif, tileMotif) ||
                other.tileMotif == tileMotif) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.lastOpenedAt, lastOpenedAt) ||
                other.lastOpenedAt == lastOpenedAt));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        name,
        createdAt,
        updatedAt,
        folderId,
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
        deletedAt,
        lastOpenedAt);
  }

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, folderId: $folderId, about: $about, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, servings: $servings, imagePath: $imagePath, imageSyncedPath: $imageSyncedPath, sourceUrl: $sourceUrl, notes: $notes, tileColor: $tileColor, tileMotif: $tileMotif, isFavorite: $isFavorite, deletedAt: $deletedAt, lastOpenedAt: $lastOpenedAt)';
  }
}

/// @nodoc
abstract mixin class _$RecipeCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$RecipeCopyWith(_Recipe value, $Res Function(_Recipe) _then) =
      __$RecipeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      DateTime createdAt,
      DateTime updatedAt,
      String? folderId,
      String? about,
      int? prepMinutes,
      int? cookMinutes,
      int? servings,
      String? imagePath,
      String? imageSyncedPath,
      String? sourceUrl,
      String? notes,
      TileColor? tileColor,
      TileMotif? tileMotif,
      bool isFavorite,
      DateTime? deletedAt,
      DateTime? lastOpenedAt});
}

/// @nodoc
class __$RecipeCopyWithImpl<$Res> implements _$RecipeCopyWith<$Res> {
  __$RecipeCopyWithImpl(this._self, this._then);

  final _Recipe _self;
  final $Res Function(_Recipe) _then;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? folderId = freezed,
    Object? about = freezed,
    Object? prepMinutes = freezed,
    Object? cookMinutes = freezed,
    Object? servings = freezed,
    Object? imagePath = freezed,
    Object? imageSyncedPath = freezed,
    Object? sourceUrl = freezed,
    Object? notes = freezed,
    Object? tileColor = freezed,
    Object? tileMotif = freezed,
    Object? isFavorite = null,
    Object? deletedAt = freezed,
    Object? lastOpenedAt = freezed,
  }) {
    return _then(_Recipe(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      folderId: freezed == folderId
          ? _self.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      about: freezed == about
          ? _self.about
          : about // ignore: cast_nullable_to_non_nullable
              as String?,
      prepMinutes: freezed == prepMinutes
          ? _self.prepMinutes
          : prepMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      cookMinutes: freezed == cookMinutes
          ? _self.cookMinutes
          : cookMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: freezed == servings
          ? _self.servings
          : servings // ignore: cast_nullable_to_non_nullable
              as int?,
      imagePath: freezed == imagePath
          ? _self.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      imageSyncedPath: freezed == imageSyncedPath
          ? _self.imageSyncedPath
          : imageSyncedPath // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceUrl: freezed == sourceUrl
          ? _self.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      tileColor: freezed == tileColor
          ? _self.tileColor
          : tileColor // ignore: cast_nullable_to_non_nullable
              as TileColor?,
      tileMotif: freezed == tileMotif
          ? _self.tileMotif
          : tileMotif // ignore: cast_nullable_to_non_nullable
              as TileMotif?,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastOpenedAt: freezed == lastOpenedAt
          ? _self.lastOpenedAt
          : lastOpenedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
