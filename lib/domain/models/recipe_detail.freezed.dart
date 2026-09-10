// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RecipeDetail {
  Recipe get recipe => throw _privateConstructorUsedError;
  List<RecipeIngredient> get ingredients => throw _privateConstructorUsedError;
  List<RecipeStep> get steps => throw _privateConstructorUsedError;
  List<Tag> get tags => throw _privateConstructorUsedError;

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeDetailCopyWith<RecipeDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeDetailCopyWith<$Res> {
  factory $RecipeDetailCopyWith(
          RecipeDetail value, $Res Function(RecipeDetail) then) =
      _$RecipeDetailCopyWithImpl<$Res, RecipeDetail>;
  @useResult
  $Res call(
      {Recipe recipe,
      List<RecipeIngredient> ingredients,
      List<RecipeStep> steps,
      List<Tag> tags});

  $RecipeCopyWith<$Res> get recipe;
}

/// @nodoc
class _$RecipeDetailCopyWithImpl<$Res, $Val extends RecipeDetail>
    implements $RecipeDetailCopyWith<$Res> {
  _$RecipeDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
    Object? ingredients = null,
    Object? steps = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RecipeStep>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
    ) as $Val);
  }

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecipeCopyWith<$Res> get recipe {
    return $RecipeCopyWith<$Res>(_value.recipe, (value) {
      return _then(_value.copyWith(recipe: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RecipeDetailImplCopyWith<$Res>
    implements $RecipeDetailCopyWith<$Res> {
  factory _$$RecipeDetailImplCopyWith(
          _$RecipeDetailImpl value, $Res Function(_$RecipeDetailImpl) then) =
      __$$RecipeDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Recipe recipe,
      List<RecipeIngredient> ingredients,
      List<RecipeStep> steps,
      List<Tag> tags});

  @override
  $RecipeCopyWith<$Res> get recipe;
}

/// @nodoc
class __$$RecipeDetailImplCopyWithImpl<$Res>
    extends _$RecipeDetailCopyWithImpl<$Res, _$RecipeDetailImpl>
    implements _$$RecipeDetailImplCopyWith<$Res> {
  __$$RecipeDetailImplCopyWithImpl(
      _$RecipeDetailImpl _value, $Res Function(_$RecipeDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
    Object? ingredients = null,
    Object? steps = null,
    Object? tags = null,
  }) {
    return _then(_$RecipeDetailImpl(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      steps: null == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RecipeStep>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
    ));
  }
}

/// @nodoc

class _$RecipeDetailImpl implements _RecipeDetail {
  const _$RecipeDetailImpl(
      {required this.recipe,
      final List<RecipeIngredient> ingredients = const <RecipeIngredient>[],
      final List<RecipeStep> steps = const <RecipeStep>[],
      final List<Tag> tags = const <Tag>[]})
      : _ingredients = ingredients,
        _steps = steps,
        _tags = tags;

  @override
  final Recipe recipe;
  final List<RecipeIngredient> _ingredients;
  @override
  @JsonKey()
  List<RecipeIngredient> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  final List<RecipeStep> _steps;
  @override
  @JsonKey()
  List<RecipeStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  final List<Tag> _tags;
  @override
  @JsonKey()
  List<Tag> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'RecipeDetail(recipe: $recipe, ingredients: $ingredients, steps: $steps, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeDetailImpl &&
            (identical(other.recipe, recipe) || other.recipe == recipe) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      recipe,
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_steps),
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeDetailImplCopyWith<_$RecipeDetailImpl> get copyWith =>
      __$$RecipeDetailImplCopyWithImpl<_$RecipeDetailImpl>(this, _$identity);
}

abstract class _RecipeDetail implements RecipeDetail {
  const factory _RecipeDetail(
      {required final Recipe recipe,
      final List<RecipeIngredient> ingredients,
      final List<RecipeStep> steps,
      final List<Tag> tags}) = _$RecipeDetailImpl;

  @override
  Recipe get recipe;
  @override
  List<RecipeIngredient> get ingredients;
  @override
  List<RecipeStep> get steps;
  @override
  List<Tag> get tags;

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeDetailImplCopyWith<_$RecipeDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
