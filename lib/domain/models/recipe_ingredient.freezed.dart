// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeIngredient {
  String get id;
  String get recipeId;
  String get rawText;
  int get position;
  String? get groupLabel;
  String? get ingredientId;

  /// `displayName` do catálogo (`Ingredient`) na hora em que a receita foi
  /// carregada — é o nome de verdade pra EXIBIR (já normalizado, Title
  /// Case). `null` quando `ingredientId` também é nulo (linha nunca
  /// resolvida). Quem preenche é `RecipeRepository._detail`; nunca é
  /// gravado no banco (`rawText`/`ingredientId` continuam sendo a fonte
  /// de verdade salva).
  String? get ingredientName;
  double? get quantity;
  String? get unitId;
  String? get qualifier;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecipeIngredientCopyWith<RecipeIngredient> get copyWith =>
      _$RecipeIngredientCopyWithImpl<RecipeIngredient>(
          this as RecipeIngredient, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as RecipeIngredient;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecipeIngredient &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.recipeId, _this.recipeId) ||
                other.recipeId == _this.recipeId) &&
            (identical(other.rawText, _this.rawText) ||
                other.rawText == _this.rawText) &&
            (identical(other.position, _this.position) ||
                other.position == _this.position) &&
            (identical(other.groupLabel, _this.groupLabel) ||
                other.groupLabel == _this.groupLabel) &&
            (identical(other.ingredientId, _this.ingredientId) ||
                other.ingredientId == _this.ingredientId) &&
            (identical(other.ingredientName, _this.ingredientName) ||
                other.ingredientName == _this.ingredientName) &&
            (identical(other.quantity, _this.quantity) ||
                other.quantity == _this.quantity) &&
            (identical(other.unitId, _this.unitId) ||
                other.unitId == _this.unitId) &&
            (identical(other.qualifier, _this.qualifier) ||
                other.qualifier == _this.qualifier));
  }

  @override
  int get hashCode {
    final _this = this as RecipeIngredient;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.recipeId,
        _this.rawText,
        _this.position,
        _this.groupLabel,
        _this.ingredientId,
        _this.ingredientName,
        _this.quantity,
        _this.unitId,
        _this.qualifier);
  }

  @override
  String toString() {
    final _this = this as RecipeIngredient;
    return 'RecipeIngredient(id: ${_this.id}, recipeId: ${_this.recipeId}, rawText: ${_this.rawText}, position: ${_this.position}, groupLabel: ${_this.groupLabel}, ingredientId: ${_this.ingredientId}, ingredientName: ${_this.ingredientName}, quantity: ${_this.quantity}, unitId: ${_this.unitId}, qualifier: ${_this.qualifier})';
  }
}

/// @nodoc
abstract mixin class $RecipeIngredientCopyWith<$Res> {
  factory $RecipeIngredientCopyWith(
          RecipeIngredient value, $Res Function(RecipeIngredient) _then) =
      _$RecipeIngredientCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String recipeId,
      String rawText,
      int position,
      String? groupLabel,
      String? ingredientId,
      String? ingredientName,
      double? quantity,
      String? unitId,
      String? qualifier});
}

/// @nodoc
class _$RecipeIngredientCopyWithImpl<$Res>
    implements $RecipeIngredientCopyWith<$Res> {
  _$RecipeIngredientCopyWithImpl(this._self, this._then);

  final RecipeIngredient _self;
  final $Res Function(RecipeIngredient) _then;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipeId = null,
    Object? rawText = null,
    Object? position = null,
    Object? groupLabel = freezed,
    Object? ingredientId = freezed,
    Object? ingredientName = freezed,
    Object? quantity = freezed,
    Object? unitId = freezed,
    Object? qualifier = freezed,
  }) {
    return _then(RecipeIngredient(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipeId: null == recipeId
          ? _self.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      rawText: null == rawText
          ? _self.rawText
          : rawText // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      groupLabel: freezed == groupLabel
          ? _self.groupLabel
          : groupLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredientId: freezed == ingredientId
          ? _self.ingredientId
          : ingredientId // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredientName: freezed == ingredientName
          ? _self.ingredientName
          : ingredientName // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _self.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
      qualifier: freezed == qualifier
          ? _self.qualifier
          : qualifier // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [RecipeIngredient].
extension RecipeIngredientPatterns on RecipeIngredient {
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
    TResult Function(_RecipeIngredient value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecipeIngredient() when $default != null:
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
    TResult Function(_RecipeIngredient value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeIngredient():
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
    TResult? Function(_RecipeIngredient value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeIngredient() when $default != null:
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
            String recipeId,
            String rawText,
            int position,
            String? groupLabel,
            String? ingredientId,
            String? ingredientName,
            double? quantity,
            String? unitId,
            String? qualifier)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecipeIngredient() when $default != null:
        return $default(
            _that.id,
            _that.recipeId,
            _that.rawText,
            _that.position,
            _that.groupLabel,
            _that.ingredientId,
            _that.ingredientName,
            _that.quantity,
            _that.unitId,
            _that.qualifier);
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
            String recipeId,
            String rawText,
            int position,
            String? groupLabel,
            String? ingredientId,
            String? ingredientName,
            double? quantity,
            String? unitId,
            String? qualifier)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeIngredient():
        return $default(
            _that.id,
            _that.recipeId,
            _that.rawText,
            _that.position,
            _that.groupLabel,
            _that.ingredientId,
            _that.ingredientName,
            _that.quantity,
            _that.unitId,
            _that.qualifier);
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
            String recipeId,
            String rawText,
            int position,
            String? groupLabel,
            String? ingredientId,
            String? ingredientName,
            double? quantity,
            String? unitId,
            String? qualifier)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecipeIngredient() when $default != null:
        return $default(
            _that.id,
            _that.recipeId,
            _that.rawText,
            _that.position,
            _that.groupLabel,
            _that.ingredientId,
            _that.ingredientName,
            _that.quantity,
            _that.unitId,
            _that.qualifier);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RecipeIngredient implements RecipeIngredient {
  const _RecipeIngredient(
      {required this.id,
      required this.recipeId,
      required this.rawText,
      required this.position,
      this.groupLabel,
      this.ingredientId,
      this.ingredientName,
      this.quantity,
      this.unitId,
      this.qualifier});

  @override
  final String id;
  @override
  final String recipeId;
  @override
  final String rawText;
  @override
  final int position;
  @override
  final String? groupLabel;
  @override
  final String? ingredientId;

  /// `displayName` do catálogo (`Ingredient`) na hora em que a receita foi
  /// carregada — é o nome de verdade pra EXIBIR (já normalizado, Title
  /// Case). `null` quando `ingredientId` também é nulo (linha nunca
  /// resolvida). Quem preenche é `RecipeRepository._detail`; nunca é
  /// gravado no banco (`rawText`/`ingredientId` continuam sendo a fonte
  /// de verdade salva).
  @override
  final String? ingredientName;
  @override
  final double? quantity;
  @override
  final String? unitId;
  @override
  final String? qualifier;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecipeIngredientCopyWith<_RecipeIngredient> get copyWith =>
      __$RecipeIngredientCopyWithImpl<_RecipeIngredient>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecipeIngredient &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.groupLabel, groupLabel) ||
                other.groupLabel == groupLabel) &&
            (identical(other.ingredientId, ingredientId) ||
                other.ingredientId == ingredientId) &&
            (identical(other.ingredientName, ingredientName) ||
                other.ingredientName == ingredientName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.qualifier, qualifier) ||
                other.qualifier == qualifier));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, recipeId, rawText, position, groupLabel,
        ingredientId, ingredientName, quantity, unitId, qualifier);
  }

  @override
  String toString() {
    return 'RecipeIngredient(id: $id, recipeId: $recipeId, rawText: $rawText, position: $position, groupLabel: $groupLabel, ingredientId: $ingredientId, ingredientName: $ingredientName, quantity: $quantity, unitId: $unitId, qualifier: $qualifier)';
  }
}

/// @nodoc
abstract mixin class _$RecipeIngredientCopyWith<$Res>
    implements $RecipeIngredientCopyWith<$Res> {
  factory _$RecipeIngredientCopyWith(
          _RecipeIngredient value, $Res Function(_RecipeIngredient) _then) =
      __$RecipeIngredientCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String recipeId,
      String rawText,
      int position,
      String? groupLabel,
      String? ingredientId,
      String? ingredientName,
      double? quantity,
      String? unitId,
      String? qualifier});
}

/// @nodoc
class __$RecipeIngredientCopyWithImpl<$Res>
    implements _$RecipeIngredientCopyWith<$Res> {
  __$RecipeIngredientCopyWithImpl(this._self, this._then);

  final _RecipeIngredient _self;
  final $Res Function(_RecipeIngredient) _then;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? recipeId = null,
    Object? rawText = null,
    Object? position = null,
    Object? groupLabel = freezed,
    Object? ingredientId = freezed,
    Object? ingredientName = freezed,
    Object? quantity = freezed,
    Object? unitId = freezed,
    Object? qualifier = freezed,
  }) {
    return _then(_RecipeIngredient(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipeId: null == recipeId
          ? _self.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      rawText: null == rawText
          ? _self.rawText
          : rawText // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      groupLabel: freezed == groupLabel
          ? _self.groupLabel
          : groupLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredientId: freezed == ingredientId
          ? _self.ingredientId
          : ingredientId // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredientName: freezed == ingredientName
          ? _self.ingredientName
          : ingredientName // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _self.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
      qualifier: freezed == qualifier
          ? _self.qualifier
          : qualifier // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
