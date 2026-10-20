// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeDetail {
  Recipe get recipe;
  List<RecipeIngredient> get ingredients;
  List<RecipeStep> get steps;
  List<Tag> get tags;

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecipeDetailCopyWith<RecipeDetail> get copyWith =>
      _$RecipeDetailCopyWithImpl<RecipeDetail>(
          this as RecipeDetail, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as RecipeDetail;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecipeDetail &&
            (identical(other.recipe, _this.recipe) ||
                other.recipe == _this.recipe) &&
            const DeepCollectionEquality()
                .equals(other.ingredients, _this.ingredients) &&
            const DeepCollectionEquality().equals(other.steps, _this.steps) &&
            const DeepCollectionEquality().equals(other.tags, _this.tags));
  }

  @override
  int get hashCode {
    final _this = this as RecipeDetail;
    return Object.hash(
        runtimeType,
        _this.recipe,
        const DeepCollectionEquality().hash(_this.ingredients),
        const DeepCollectionEquality().hash(_this.steps),
        const DeepCollectionEquality().hash(_this.tags));
  }

  @override
  String toString() {
    final _this = this as RecipeDetail;
    return 'RecipeDetail(recipe: ${_this.recipe}, ingredients: ${_this.ingredients}, steps: ${_this.steps}, tags: ${_this.tags})';
  }
}

/// @nodoc
abstract mixin class $RecipeDetailCopyWith<$Res> {
  factory $RecipeDetailCopyWith(
          RecipeDetail value, $Res Function(RecipeDetail) _then) =
      _$RecipeDetailCopyWithImpl;
  @useResult
  $Res call(
      {Recipe recipe,
      List<RecipeIngredient> ingredients,
      List<RecipeStep> steps,
      List<Tag> tags});

  $RecipeCopyWith<$Res> get recipe;
}

/// @nodoc
class _$RecipeDetailCopyWithImpl<$Res> implements $RecipeDetailCopyWith<$Res> {
  _$RecipeDetailCopyWithImpl(this._self, this._then);

  final RecipeDetail _self;
  final $Res Function(RecipeDetail) _then;

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
    return _then(RecipeDetail(
      recipe: null == recipe
          ? _self.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
      ingredients: null == ingredients
          ? _self.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      steps: null == steps
          ? _self.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RecipeStep>,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
    ));
  }

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecipeCopyWith<$Res> get recipe {
    return $RecipeCopyWith<$Res>(_self.recipe, (value) {
      return _then(_self.copyWith(recipe: value));
    });
  }
}

/// Adds pattern-matching-related methods to [RecipeDetail].
extension RecipeDetailPatterns on RecipeDetail {
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
    TResult Function(_RecipeDetail value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecipeDetail() when $default != null:
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
    TResult Function(_RecipeDetail value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeDetail():
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
    TResult? Function(_RecipeDetail value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeDetail() when $default != null:
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
    TResult Function(Recipe recipe, List<RecipeIngredient> ingredients,
            List<RecipeStep> steps, List<Tag> tags)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecipeDetail() when $default != null:
        return $default(
            _that.recipe, _that.ingredients, _that.steps, _that.tags);
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
    TResult Function(Recipe recipe, List<RecipeIngredient> ingredients,
            List<RecipeStep> steps, List<Tag> tags)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeDetail():
        return $default(
            _that.recipe, _that.ingredients, _that.steps, _that.tags);
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
    TResult? Function(Recipe recipe, List<RecipeIngredient> ingredients,
            List<RecipeStep> steps, List<Tag> tags)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeDetail() when $default != null:
        return $default(
            _that.recipe, _that.ingredients, _that.steps, _that.tags);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RecipeDetail implements RecipeDetail {
  const _RecipeDetail(
      {required this.recipe,
      List<RecipeIngredient> ingredients = const <RecipeIngredient>[],
      List<RecipeStep> steps = const <RecipeStep>[],
      List<Tag> tags = const <Tag>[]})
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

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecipeDetailCopyWith<_RecipeDetail> get copyWith =>
      __$RecipeDetailCopyWithImpl<_RecipeDetail>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecipeDetail &&
            (identical(other.recipe, recipe) || other.recipe == recipe) &&
            const DeepCollectionEquality()
                .equals(other.ingredients, _ingredients) &&
            const DeepCollectionEquality().equals(other.steps, _steps) &&
            const DeepCollectionEquality().equals(other.tags, _tags));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        recipe,
        const DeepCollectionEquality().hash(_ingredients),
        const DeepCollectionEquality().hash(_steps),
        const DeepCollectionEquality().hash(_tags));
  }

  @override
  String toString() {
    return 'RecipeDetail(recipe: $recipe, ingredients: $ingredients, steps: $steps, tags: $tags)';
  }
}

/// @nodoc
abstract mixin class _$RecipeDetailCopyWith<$Res>
    implements $RecipeDetailCopyWith<$Res> {
  factory _$RecipeDetailCopyWith(
          _RecipeDetail value, $Res Function(_RecipeDetail) _then) =
      __$RecipeDetailCopyWithImpl;
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
class __$RecipeDetailCopyWithImpl<$Res>
    implements _$RecipeDetailCopyWith<$Res> {
  __$RecipeDetailCopyWithImpl(this._self, this._then);

  final _RecipeDetail _self;
  final $Res Function(_RecipeDetail) _then;

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? recipe = null,
    Object? ingredients = null,
    Object? steps = null,
    Object? tags = null,
  }) {
    return _then(_RecipeDetail(
      recipe: null == recipe
          ? _self.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
      ingredients: null == ingredients
          ? _self._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      steps: null == steps
          ? _self._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RecipeStep>,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<Tag>,
    ));
  }

  /// Create a copy of RecipeDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecipeCopyWith<$Res> get recipe {
    return $RecipeCopyWith<$Res>(_self.recipe, (value) {
      return _then(_self.copyWith(recipe: value));
    });
  }
}

// dart format on
