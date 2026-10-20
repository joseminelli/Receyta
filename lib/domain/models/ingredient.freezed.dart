// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ingredient {
  String get id;
  String get displayName;
  String get normalizedKey;
  String? get categoryId;
  int get usageCount;

  /// "Sempre tenho" (G11): fica fora das listas de compras geradas.
  bool get inPantry;

  /// Preço que a pessoa informou. Nulo = sem preço.
  IngredientPrice? get price;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $IngredientCopyWith<Ingredient> get copyWith =>
      _$IngredientCopyWithImpl<Ingredient>(this as Ingredient, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as Ingredient;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Ingredient &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.displayName, _this.displayName) ||
                other.displayName == _this.displayName) &&
            (identical(other.normalizedKey, _this.normalizedKey) ||
                other.normalizedKey == _this.normalizedKey) &&
            (identical(other.categoryId, _this.categoryId) ||
                other.categoryId == _this.categoryId) &&
            (identical(other.usageCount, _this.usageCount) ||
                other.usageCount == _this.usageCount) &&
            (identical(other.inPantry, _this.inPantry) ||
                other.inPantry == _this.inPantry) &&
            (identical(other.price, _this.price) ||
                other.price == _this.price));
  }

  @override
  int get hashCode {
    final _this = this as Ingredient;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.displayName,
        _this.normalizedKey,
        _this.categoryId,
        _this.usageCount,
        _this.inPantry,
        _this.price);
  }

  @override
  String toString() {
    final _this = this as Ingredient;
    return 'Ingredient(id: ${_this.id}, displayName: ${_this.displayName}, normalizedKey: ${_this.normalizedKey}, categoryId: ${_this.categoryId}, usageCount: ${_this.usageCount}, inPantry: ${_this.inPantry}, price: ${_this.price})';
  }
}

/// @nodoc
abstract mixin class $IngredientCopyWith<$Res> {
  factory $IngredientCopyWith(
          Ingredient value, $Res Function(Ingredient) _then) =
      _$IngredientCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String displayName,
      String normalizedKey,
      String? categoryId,
      int usageCount,
      bool inPantry,
      IngredientPrice? price});
}

/// @nodoc
class _$IngredientCopyWithImpl<$Res> implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._self, this._then);

  final Ingredient _self;
  final $Res Function(Ingredient) _then;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? normalizedKey = null,
    Object? categoryId = freezed,
    Object? usageCount = null,
    Object? inPantry = null,
    Object? price = freezed,
  }) {
    return _then(Ingredient(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      normalizedKey: null == normalizedKey
          ? _self.normalizedKey
          : normalizedKey // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: freezed == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      usageCount: null == usageCount
          ? _self.usageCount
          : usageCount // ignore: cast_nullable_to_non_nullable
              as int,
      inPantry: null == inPantry
          ? _self.inPantry
          : inPantry // ignore: cast_nullable_to_non_nullable
              as bool,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as IngredientPrice?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Ingredient].
extension IngredientPatterns on Ingredient {
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
    TResult Function(_Ingredient value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Ingredient() when $default != null:
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
    TResult Function(_Ingredient value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Ingredient():
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
    TResult? Function(_Ingredient value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Ingredient() when $default != null:
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
            String displayName,
            String normalizedKey,
            String? categoryId,
            int usageCount,
            bool inPantry,
            IngredientPrice? price)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Ingredient() when $default != null:
        return $default(_that.id, _that.displayName, _that.normalizedKey,
            _that.categoryId, _that.usageCount, _that.inPantry, _that.price);
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
            String displayName,
            String normalizedKey,
            String? categoryId,
            int usageCount,
            bool inPantry,
            IngredientPrice? price)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Ingredient():
        return $default(_that.id, _that.displayName, _that.normalizedKey,
            _that.categoryId, _that.usageCount, _that.inPantry, _that.price);
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
            String displayName,
            String normalizedKey,
            String? categoryId,
            int usageCount,
            bool inPantry,
            IngredientPrice? price)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Ingredient() when $default != null:
        return $default(_that.id, _that.displayName, _that.normalizedKey,
            _that.categoryId, _that.usageCount, _that.inPantry, _that.price);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Ingredient implements Ingredient {
  const _Ingredient(
      {required this.id,
      required this.displayName,
      required this.normalizedKey,
      this.categoryId,
      this.usageCount = 0,
      this.inPantry = false,
      this.price});

  @override
  final String id;
  @override
  final String displayName;
  @override
  final String normalizedKey;
  @override
  final String? categoryId;
  @override
  @JsonKey()
  final int usageCount;

  /// "Sempre tenho" (G11): fica fora das listas de compras geradas.
  @override
  @JsonKey()
  final bool inPantry;

  /// Preço que a pessoa informou. Nulo = sem preço.
  @override
  final IngredientPrice? price;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$IngredientCopyWith<_Ingredient> get copyWith =>
      __$IngredientCopyWithImpl<_Ingredient>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Ingredient &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.normalizedKey, normalizedKey) ||
                other.normalizedKey == normalizedKey) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.usageCount, usageCount) ||
                other.usageCount == usageCount) &&
            (identical(other.inPantry, inPantry) ||
                other.inPantry == inPantry) &&
            (identical(other.price, price) || other.price == price));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, displayName, normalizedKey, categoryId,
        usageCount, inPantry, price);
  }

  @override
  String toString() {
    return 'Ingredient(id: $id, displayName: $displayName, normalizedKey: $normalizedKey, categoryId: $categoryId, usageCount: $usageCount, inPantry: $inPantry, price: $price)';
  }
}

/// @nodoc
abstract mixin class _$IngredientCopyWith<$Res>
    implements $IngredientCopyWith<$Res> {
  factory _$IngredientCopyWith(
          _Ingredient value, $Res Function(_Ingredient) _then) =
      __$IngredientCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String displayName,
      String normalizedKey,
      String? categoryId,
      int usageCount,
      bool inPantry,
      IngredientPrice? price});
}

/// @nodoc
class __$IngredientCopyWithImpl<$Res> implements _$IngredientCopyWith<$Res> {
  __$IngredientCopyWithImpl(this._self, this._then);

  final _Ingredient _self;
  final $Res Function(_Ingredient) _then;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? normalizedKey = null,
    Object? categoryId = freezed,
    Object? usageCount = null,
    Object? inPantry = null,
    Object? price = freezed,
  }) {
    return _then(_Ingredient(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      normalizedKey: null == normalizedKey
          ? _self.normalizedKey
          : normalizedKey // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: freezed == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      usageCount: null == usageCount
          ? _self.usageCount
          : usageCount // ignore: cast_nullable_to_non_nullable
              as int,
      inPantry: null == inPantry
          ? _self.inPantry
          : inPantry // ignore: cast_nullable_to_non_nullable
              as bool,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as IngredientPrice?,
    ));
  }
}

// dart format on
