// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Recipe {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get folderId => throw _privateConstructorUsedError;
  String? get about => throw _privateConstructorUsedError;
  int? get prepMinutes => throw _privateConstructorUsedError;
  int? get cookMinutes => throw _privateConstructorUsedError;
  int? get servings => throw _privateConstructorUsedError;
  String? get imagePath => throw _privateConstructorUsedError;
  String? get sourceUrl => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Aparência do azulejo escolhida pelo usuário (§9.4). Nulo em qualquer um
  /// = deriva do id / pareamento padrão.
  TileColor? get tileColor => throw _privateConstructorUsedError;
  TileMotif? get tileMotif => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;

  /// Preenchido só nas linhas da lixeira (RF-01.6). `null` = receita ativa.
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Última abertura ou criação — ordena a prateleira "Recentes" da home.
  DateTime? get lastOpenedAt => throw _privateConstructorUsedError;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeCopyWith<Recipe> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeCopyWith<$Res> {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) then) =
      _$RecipeCopyWithImpl<$Res, Recipe>;
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
      String? sourceUrl,
      String? notes,
      TileColor? tileColor,
      TileMotif? tileMotif,
      bool isFavorite,
      DateTime? deletedAt,
      DateTime? lastOpenedAt});
}

/// @nodoc
class _$RecipeCopyWithImpl<$Res, $Val extends Recipe>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    Object? sourceUrl = freezed,
    Object? notes = freezed,
    Object? tileColor = freezed,
    Object? tileMotif = freezed,
    Object? isFavorite = null,
    Object? deletedAt = freezed,
    Object? lastOpenedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      about: freezed == about
          ? _value.about
          : about // ignore: cast_nullable_to_non_nullable
              as String?,
      prepMinutes: freezed == prepMinutes
          ? _value.prepMinutes
          : prepMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      cookMinutes: freezed == cookMinutes
          ? _value.cookMinutes
          : cookMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: freezed == servings
          ? _value.servings
          : servings // ignore: cast_nullable_to_non_nullable
              as int?,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceUrl: freezed == sourceUrl
          ? _value.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      tileColor: freezed == tileColor
          ? _value.tileColor
          : tileColor // ignore: cast_nullable_to_non_nullable
              as TileColor?,
      tileMotif: freezed == tileMotif
          ? _value.tileMotif
          : tileMotif // ignore: cast_nullable_to_non_nullable
              as TileMotif?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastOpenedAt: freezed == lastOpenedAt
          ? _value.lastOpenedAt
          : lastOpenedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeImplCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$$RecipeImplCopyWith(
          _$RecipeImpl value, $Res Function(_$RecipeImpl) then) =
      __$$RecipeImplCopyWithImpl<$Res>;
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
      String? sourceUrl,
      String? notes,
      TileColor? tileColor,
      TileMotif? tileMotif,
      bool isFavorite,
      DateTime? deletedAt,
      DateTime? lastOpenedAt});
}

/// @nodoc
class __$$RecipeImplCopyWithImpl<$Res>
    extends _$RecipeCopyWithImpl<$Res, _$RecipeImpl>
    implements _$$RecipeImplCopyWith<$Res> {
  __$$RecipeImplCopyWithImpl(
      _$RecipeImpl _value, $Res Function(_$RecipeImpl) _then)
      : super(_value, _then);

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
    Object? sourceUrl = freezed,
    Object? notes = freezed,
    Object? tileColor = freezed,
    Object? tileMotif = freezed,
    Object? isFavorite = null,
    Object? deletedAt = freezed,
    Object? lastOpenedAt = freezed,
  }) {
    return _then(_$RecipeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      about: freezed == about
          ? _value.about
          : about // ignore: cast_nullable_to_non_nullable
              as String?,
      prepMinutes: freezed == prepMinutes
          ? _value.prepMinutes
          : prepMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      cookMinutes: freezed == cookMinutes
          ? _value.cookMinutes
          : cookMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: freezed == servings
          ? _value.servings
          : servings // ignore: cast_nullable_to_non_nullable
              as int?,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceUrl: freezed == sourceUrl
          ? _value.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      tileColor: freezed == tileColor
          ? _value.tileColor
          : tileColor // ignore: cast_nullable_to_non_nullable
              as TileColor?,
      tileMotif: freezed == tileMotif
          ? _value.tileMotif
          : tileMotif // ignore: cast_nullable_to_non_nullable
              as TileMotif?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastOpenedAt: freezed == lastOpenedAt
          ? _value.lastOpenedAt
          : lastOpenedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$RecipeImpl implements _Recipe {
  const _$RecipeImpl(
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

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, folderId: $folderId, about: $about, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, servings: $servings, imagePath: $imagePath, sourceUrl: $sourceUrl, notes: $notes, tileColor: $tileColor, tileMotif: $tileMotif, isFavorite: $isFavorite, deletedAt: $deletedAt, lastOpenedAt: $lastOpenedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeImpl &&
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
  int get hashCode => Object.hash(
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
      sourceUrl,
      notes,
      tileColor,
      tileMotif,
      isFavorite,
      deletedAt,
      lastOpenedAt);

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      __$$RecipeImplCopyWithImpl<_$RecipeImpl>(this, _$identity);
}

abstract class _Recipe implements Recipe {
  const factory _Recipe(
      {required final String id,
      required final String name,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? folderId,
      final String? about,
      final int? prepMinutes,
      final int? cookMinutes,
      final int? servings,
      final String? imagePath,
      final String? sourceUrl,
      final String? notes,
      final TileColor? tileColor,
      final TileMotif? tileMotif,
      final bool isFavorite,
      final DateTime? deletedAt,
      final DateTime? lastOpenedAt}) = _$RecipeImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get folderId;
  @override
  String? get about;
  @override
  int? get prepMinutes;
  @override
  int? get cookMinutes;
  @override
  int? get servings;
  @override
  String? get imagePath;
  @override
  String? get sourceUrl;
  @override
  String? get notes;

  /// Aparência do azulejo escolhida pelo usuário (§9.4). Nulo em qualquer um
  /// = deriva do id / pareamento padrão.
  @override
  TileColor? get tileColor;
  @override
  TileMotif? get tileMotif;
  @override
  bool get isFavorite;

  /// Preenchido só nas linhas da lixeira (RF-01.6). `null` = receita ativa.
  @override
  DateTime? get deletedAt;

  /// Última abertura ou criação — ordena a prateleira "Recentes" da home.
  @override
  DateTime? get lastOpenedAt;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
