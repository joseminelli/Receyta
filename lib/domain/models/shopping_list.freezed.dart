// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShoppingList {
  String get id;
  String get name;
  String get status;
  DateTime get createdAt;
  DateTime get updatedAt;

  /// Casa em que a lista é compartilhada; nulo = só da pessoa.
  String? get spaceId;

  /// Create a copy of ShoppingList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShoppingListCopyWith<ShoppingList> get copyWith =>
      _$ShoppingListCopyWithImpl<ShoppingList>(
          this as ShoppingList, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as ShoppingList;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShoppingList &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.spaceId, _this.spaceId) ||
                other.spaceId == _this.spaceId));
  }

  @override
  int get hashCode {
    final _this = this as ShoppingList;
    return Object.hash(runtimeType, _this.id, _this.name, _this.status,
        _this.createdAt, _this.updatedAt, _this.spaceId);
  }

  @override
  String toString() {
    final _this = this as ShoppingList;
    return 'ShoppingList(id: ${_this.id}, name: ${_this.name}, status: ${_this.status}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, spaceId: ${_this.spaceId})';
  }
}

/// @nodoc
abstract mixin class $ShoppingListCopyWith<$Res> {
  factory $ShoppingListCopyWith(
          ShoppingList value, $Res Function(ShoppingList) _then) =
      _$ShoppingListCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String status,
      DateTime createdAt,
      DateTime updatedAt,
      String? spaceId});
}

/// @nodoc
class _$ShoppingListCopyWithImpl<$Res> implements $ShoppingListCopyWith<$Res> {
  _$ShoppingListCopyWithImpl(this._self, this._then);

  final ShoppingList _self;
  final $Res Function(ShoppingList) _then;

  /// Create a copy of ShoppingList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? spaceId = freezed,
  }) {
    return _then(ShoppingList(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      spaceId: freezed == spaceId
          ? _self.spaceId
          : spaceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ShoppingList].
extension ShoppingListPatterns on ShoppingList {
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
    TResult Function(_ShoppingList value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingList() when $default != null:
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
    TResult Function(_ShoppingList value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingList():
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
    TResult? Function(_ShoppingList value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingList() when $default != null:
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
    TResult Function(String id, String name, String status, DateTime createdAt,
            DateTime updatedAt, String? spaceId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingList() when $default != null:
        return $default(_that.id, _that.name, _that.status, _that.createdAt,
            _that.updatedAt, _that.spaceId);
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
    TResult Function(String id, String name, String status, DateTime createdAt,
            DateTime updatedAt, String? spaceId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingList():
        return $default(_that.id, _that.name, _that.status, _that.createdAt,
            _that.updatedAt, _that.spaceId);
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
    TResult? Function(String id, String name, String status, DateTime createdAt,
            DateTime updatedAt, String? spaceId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingList() when $default != null:
        return $default(_that.id, _that.name, _that.status, _that.createdAt,
            _that.updatedAt, _that.spaceId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShoppingList implements ShoppingList {
  const _ShoppingList(
      {required this.id,
      required this.name,
      this.status = 'active',
      required this.createdAt,
      required this.updatedAt,
      this.spaceId});

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  /// Casa em que a lista é compartilhada; nulo = só da pessoa.
  @override
  final String? spaceId;

  /// Create a copy of ShoppingList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShoppingListCopyWith<_ShoppingList> get copyWith =>
      __$ShoppingListCopyWithImpl<_ShoppingList>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShoppingList &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.spaceId, spaceId) || other.spaceId == spaceId));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, id, name, status, createdAt, updatedAt, spaceId);
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, spaceId: $spaceId)';
  }
}

/// @nodoc
abstract mixin class _$ShoppingListCopyWith<$Res>
    implements $ShoppingListCopyWith<$Res> {
  factory _$ShoppingListCopyWith(
          _ShoppingList value, $Res Function(_ShoppingList) _then) =
      __$ShoppingListCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String status,
      DateTime createdAt,
      DateTime updatedAt,
      String? spaceId});
}

/// @nodoc
class __$ShoppingListCopyWithImpl<$Res>
    implements _$ShoppingListCopyWith<$Res> {
  __$ShoppingListCopyWithImpl(this._self, this._then);

  final _ShoppingList _self;
  final $Res Function(_ShoppingList) _then;

  /// Create a copy of ShoppingList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? spaceId = freezed,
  }) {
    return _then(_ShoppingList(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      spaceId: freezed == spaceId
          ? _self.spaceId
          : spaceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
