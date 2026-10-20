// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShoppingItemSource {
  String get recipeId;
  String get recipeName;
  double? get quantity;
  String? get unitId;

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShoppingItemSourceCopyWith<ShoppingItemSource> get copyWith =>
      _$ShoppingItemSourceCopyWithImpl<ShoppingItemSource>(
          this as ShoppingItemSource, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as ShoppingItemSource;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShoppingItemSource &&
            (identical(other.recipeId, _this.recipeId) ||
                other.recipeId == _this.recipeId) &&
            (identical(other.recipeName, _this.recipeName) ||
                other.recipeName == _this.recipeName) &&
            (identical(other.quantity, _this.quantity) ||
                other.quantity == _this.quantity) &&
            (identical(other.unitId, _this.unitId) ||
                other.unitId == _this.unitId));
  }

  @override
  int get hashCode {
    final _this = this as ShoppingItemSource;
    return Object.hash(runtimeType, _this.recipeId, _this.recipeName,
        _this.quantity, _this.unitId);
  }

  @override
  String toString() {
    final _this = this as ShoppingItemSource;
    return 'ShoppingItemSource(recipeId: ${_this.recipeId}, recipeName: ${_this.recipeName}, quantity: ${_this.quantity}, unitId: ${_this.unitId})';
  }
}

/// @nodoc
abstract mixin class $ShoppingItemSourceCopyWith<$Res> {
  factory $ShoppingItemSourceCopyWith(
          ShoppingItemSource value, $Res Function(ShoppingItemSource) _then) =
      _$ShoppingItemSourceCopyWithImpl;
  @useResult
  $Res call(
      {String recipeId, String recipeName, double? quantity, String? unitId});
}

/// @nodoc
class _$ShoppingItemSourceCopyWithImpl<$Res>
    implements $ShoppingItemSourceCopyWith<$Res> {
  _$ShoppingItemSourceCopyWithImpl(this._self, this._then);

  final ShoppingItemSource _self;
  final $Res Function(ShoppingItemSource) _then;

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? recipeName = null,
    Object? quantity = freezed,
    Object? unitId = freezed,
  }) {
    return _then(ShoppingItemSource(
      recipeId: null == recipeId
          ? _self.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _self.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _self.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ShoppingItemSource].
extension ShoppingItemSourcePatterns on ShoppingItemSource {
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
    TResult Function(_ShoppingItemSource value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemSource() when $default != null:
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
    TResult Function(_ShoppingItemSource value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemSource():
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
    TResult? Function(_ShoppingItemSource value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemSource() when $default != null:
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
    TResult Function(String recipeId, String recipeName, double? quantity,
            String? unitId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemSource() when $default != null:
        return $default(
            _that.recipeId, _that.recipeName, _that.quantity, _that.unitId);
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
    TResult Function(String recipeId, String recipeName, double? quantity,
            String? unitId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemSource():
        return $default(
            _that.recipeId, _that.recipeName, _that.quantity, _that.unitId);
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
    TResult? Function(String recipeId, String recipeName, double? quantity,
            String? unitId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItemSource() when $default != null:
        return $default(
            _that.recipeId, _that.recipeName, _that.quantity, _that.unitId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShoppingItemSource implements ShoppingItemSource {
  const _ShoppingItemSource(
      {required this.recipeId,
      required this.recipeName,
      this.quantity,
      this.unitId});

  @override
  final String recipeId;
  @override
  final String recipeName;
  @override
  final double? quantity;
  @override
  final String? unitId;

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShoppingItemSourceCopyWith<_ShoppingItemSource> get copyWith =>
      __$ShoppingItemSourceCopyWithImpl<_ShoppingItemSource>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShoppingItemSource &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.recipeName, recipeName) ||
                other.recipeName == recipeName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitId, unitId) || other.unitId == unitId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, recipeId, recipeName, quantity, unitId);
  }

  @override
  String toString() {
    return 'ShoppingItemSource(recipeId: $recipeId, recipeName: $recipeName, quantity: $quantity, unitId: $unitId)';
  }
}

/// @nodoc
abstract mixin class _$ShoppingItemSourceCopyWith<$Res>
    implements $ShoppingItemSourceCopyWith<$Res> {
  factory _$ShoppingItemSourceCopyWith(
          _ShoppingItemSource value, $Res Function(_ShoppingItemSource) _then) =
      __$ShoppingItemSourceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String recipeId, String recipeName, double? quantity, String? unitId});
}

/// @nodoc
class __$ShoppingItemSourceCopyWithImpl<$Res>
    implements _$ShoppingItemSourceCopyWith<$Res> {
  __$ShoppingItemSourceCopyWithImpl(this._self, this._then);

  final _ShoppingItemSource _self;
  final $Res Function(_ShoppingItemSource) _then;

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? recipeId = null,
    Object? recipeName = null,
    Object? quantity = freezed,
    Object? unitId = freezed,
  }) {
    return _then(_ShoppingItemSource(
      recipeId: null == recipeId
          ? _self.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _self.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _self.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$ShoppingListItem {
  String get id;
  String get listId;
  String? get ingredientId;
  String get displayName;
  String? get manualName;

  /// Nulo quando nenhuma origem tinha quantidade numérica reconhecida —
  /// a tela mostra a unidade/nome sem número, não inventa um.
  double? get quantity;
  String? get unitId;
  bool get checked;
  String? get note;
  int get position;

  /// Corredor do mercado (slug de `kSeedCategories`, RF-05.7) — do
  /// catálogo quando o ingrediente tem categoria, senão inferido do nome.
  String get categorySlug;

  /// Quem adicionou e quem marcou o item (id da conta); só em listas da casa.
  String? get addedBy;
  String? get checkedBy;
  List<ShoppingItemSource> get sources;

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShoppingListItemCopyWith<ShoppingListItem> get copyWith =>
      _$ShoppingListItemCopyWithImpl<ShoppingListItem>(
          this as ShoppingListItem, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as ShoppingListItem;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShoppingListItem &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.listId, _this.listId) ||
                other.listId == _this.listId) &&
            (identical(other.ingredientId, _this.ingredientId) ||
                other.ingredientId == _this.ingredientId) &&
            (identical(other.displayName, _this.displayName) ||
                other.displayName == _this.displayName) &&
            (identical(other.manualName, _this.manualName) ||
                other.manualName == _this.manualName) &&
            (identical(other.quantity, _this.quantity) ||
                other.quantity == _this.quantity) &&
            (identical(other.unitId, _this.unitId) ||
                other.unitId == _this.unitId) &&
            (identical(other.checked, _this.checked) ||
                other.checked == _this.checked) &&
            (identical(other.note, _this.note) || other.note == _this.note) &&
            (identical(other.position, _this.position) ||
                other.position == _this.position) &&
            (identical(other.categorySlug, _this.categorySlug) ||
                other.categorySlug == _this.categorySlug) &&
            (identical(other.addedBy, _this.addedBy) ||
                other.addedBy == _this.addedBy) &&
            (identical(other.checkedBy, _this.checkedBy) ||
                other.checkedBy == _this.checkedBy) &&
            const DeepCollectionEquality()
                .equals(other.sources, _this.sources));
  }

  @override
  int get hashCode {
    final _this = this as ShoppingListItem;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.listId,
        _this.ingredientId,
        _this.displayName,
        _this.manualName,
        _this.quantity,
        _this.unitId,
        _this.checked,
        _this.note,
        _this.position,
        _this.categorySlug,
        _this.addedBy,
        _this.checkedBy,
        const DeepCollectionEquality().hash(_this.sources));
  }

  @override
  String toString() {
    final _this = this as ShoppingListItem;
    return 'ShoppingListItem(id: ${_this.id}, listId: ${_this.listId}, ingredientId: ${_this.ingredientId}, displayName: ${_this.displayName}, manualName: ${_this.manualName}, quantity: ${_this.quantity}, unitId: ${_this.unitId}, checked: ${_this.checked}, note: ${_this.note}, position: ${_this.position}, categorySlug: ${_this.categorySlug}, addedBy: ${_this.addedBy}, checkedBy: ${_this.checkedBy}, sources: ${_this.sources})';
  }
}

/// @nodoc
abstract mixin class $ShoppingListItemCopyWith<$Res> {
  factory $ShoppingListItemCopyWith(
          ShoppingListItem value, $Res Function(ShoppingListItem) _then) =
      _$ShoppingListItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String listId,
      String? ingredientId,
      String displayName,
      String? manualName,
      double? quantity,
      String? unitId,
      bool checked,
      String? note,
      int position,
      String categorySlug,
      String? addedBy,
      String? checkedBy,
      List<ShoppingItemSource> sources});
}

/// @nodoc
class _$ShoppingListItemCopyWithImpl<$Res>
    implements $ShoppingListItemCopyWith<$Res> {
  _$ShoppingListItemCopyWithImpl(this._self, this._then);

  final ShoppingListItem _self;
  final $Res Function(ShoppingListItem) _then;

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listId = null,
    Object? ingredientId = freezed,
    Object? displayName = null,
    Object? manualName = freezed,
    Object? quantity = freezed,
    Object? unitId = freezed,
    Object? checked = null,
    Object? note = freezed,
    Object? position = null,
    Object? categorySlug = null,
    Object? addedBy = freezed,
    Object? checkedBy = freezed,
    Object? sources = null,
  }) {
    return _then(ShoppingListItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      listId: null == listId
          ? _self.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String,
      ingredientId: freezed == ingredientId
          ? _self.ingredientId
          : ingredientId // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      manualName: freezed == manualName
          ? _self.manualName
          : manualName // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _self.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
      checked: null == checked
          ? _self.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      categorySlug: null == categorySlug
          ? _self.categorySlug
          : categorySlug // ignore: cast_nullable_to_non_nullable
              as String,
      addedBy: freezed == addedBy
          ? _self.addedBy
          : addedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      checkedBy: freezed == checkedBy
          ? _self.checkedBy
          : checkedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      sources: null == sources
          ? _self.sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<ShoppingItemSource>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ShoppingListItem].
extension ShoppingListItemPatterns on ShoppingListItem {
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
    TResult Function(_ShoppingListItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingListItem() when $default != null:
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
    TResult Function(_ShoppingListItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListItem():
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
    TResult? Function(_ShoppingListItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListItem() when $default != null:
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
            String listId,
            String? ingredientId,
            String displayName,
            String? manualName,
            double? quantity,
            String? unitId,
            bool checked,
            String? note,
            int position,
            String categorySlug,
            String? addedBy,
            String? checkedBy,
            List<ShoppingItemSource> sources)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingListItem() when $default != null:
        return $default(
            _that.id,
            _that.listId,
            _that.ingredientId,
            _that.displayName,
            _that.manualName,
            _that.quantity,
            _that.unitId,
            _that.checked,
            _that.note,
            _that.position,
            _that.categorySlug,
            _that.addedBy,
            _that.checkedBy,
            _that.sources);
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
            String listId,
            String? ingredientId,
            String displayName,
            String? manualName,
            double? quantity,
            String? unitId,
            bool checked,
            String? note,
            int position,
            String categorySlug,
            String? addedBy,
            String? checkedBy,
            List<ShoppingItemSource> sources)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListItem():
        return $default(
            _that.id,
            _that.listId,
            _that.ingredientId,
            _that.displayName,
            _that.manualName,
            _that.quantity,
            _that.unitId,
            _that.checked,
            _that.note,
            _that.position,
            _that.categorySlug,
            _that.addedBy,
            _that.checkedBy,
            _that.sources);
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
            String listId,
            String? ingredientId,
            String displayName,
            String? manualName,
            double? quantity,
            String? unitId,
            bool checked,
            String? note,
            int position,
            String categorySlug,
            String? addedBy,
            String? checkedBy,
            List<ShoppingItemSource> sources)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingListItem() when $default != null:
        return $default(
            _that.id,
            _that.listId,
            _that.ingredientId,
            _that.displayName,
            _that.manualName,
            _that.quantity,
            _that.unitId,
            _that.checked,
            _that.note,
            _that.position,
            _that.categorySlug,
            _that.addedBy,
            _that.checkedBy,
            _that.sources);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShoppingListItem implements ShoppingListItem {
  const _ShoppingListItem(
      {required this.id,
      required this.listId,
      this.ingredientId,
      required this.displayName,
      this.manualName,
      this.quantity,
      this.unitId,
      this.checked = false,
      this.note,
      this.position = 0,
      this.categorySlug = 'outros',
      this.addedBy,
      this.checkedBy,
      List<ShoppingItemSource> sources = const <ShoppingItemSource>[]})
      : _sources = sources;

  @override
  final String id;
  @override
  final String listId;
  @override
  final String? ingredientId;
  @override
  final String displayName;
  @override
  final String? manualName;

  /// Nulo quando nenhuma origem tinha quantidade numérica reconhecida —
  /// a tela mostra a unidade/nome sem número, não inventa um.
  @override
  final double? quantity;
  @override
  final String? unitId;
  @override
  @JsonKey()
  final bool checked;
  @override
  final String? note;
  @override
  @JsonKey()
  final int position;

  /// Corredor do mercado (slug de `kSeedCategories`, RF-05.7) — do
  /// catálogo quando o ingrediente tem categoria, senão inferido do nome.
  @override
  @JsonKey()
  final String categorySlug;

  /// Quem adicionou e quem marcou o item (id da conta); só em listas da casa.
  @override
  final String? addedBy;
  @override
  final String? checkedBy;
  final List<ShoppingItemSource> _sources;
  @override
  @JsonKey()
  List<ShoppingItemSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShoppingListItemCopyWith<_ShoppingListItem> get copyWith =>
      __$ShoppingListItemCopyWithImpl<_ShoppingListItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShoppingListItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.listId, listId) || other.listId == listId) &&
            (identical(other.ingredientId, ingredientId) ||
                other.ingredientId == ingredientId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.manualName, manualName) ||
                other.manualName == manualName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.categorySlug, categorySlug) ||
                other.categorySlug == categorySlug) &&
            (identical(other.addedBy, addedBy) || other.addedBy == addedBy) &&
            (identical(other.checkedBy, checkedBy) ||
                other.checkedBy == checkedBy) &&
            const DeepCollectionEquality().equals(other.sources, _sources));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        listId,
        ingredientId,
        displayName,
        manualName,
        quantity,
        unitId,
        checked,
        note,
        position,
        categorySlug,
        addedBy,
        checkedBy,
        const DeepCollectionEquality().hash(_sources));
  }

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, listId: $listId, ingredientId: $ingredientId, displayName: $displayName, manualName: $manualName, quantity: $quantity, unitId: $unitId, checked: $checked, note: $note, position: $position, categorySlug: $categorySlug, addedBy: $addedBy, checkedBy: $checkedBy, sources: $sources)';
  }
}

/// @nodoc
abstract mixin class _$ShoppingListItemCopyWith<$Res>
    implements $ShoppingListItemCopyWith<$Res> {
  factory _$ShoppingListItemCopyWith(
          _ShoppingListItem value, $Res Function(_ShoppingListItem) _then) =
      __$ShoppingListItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String listId,
      String? ingredientId,
      String displayName,
      String? manualName,
      double? quantity,
      String? unitId,
      bool checked,
      String? note,
      int position,
      String categorySlug,
      String? addedBy,
      String? checkedBy,
      List<ShoppingItemSource> sources});
}

/// @nodoc
class __$ShoppingListItemCopyWithImpl<$Res>
    implements _$ShoppingListItemCopyWith<$Res> {
  __$ShoppingListItemCopyWithImpl(this._self, this._then);

  final _ShoppingListItem _self;
  final $Res Function(_ShoppingListItem) _then;

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? listId = null,
    Object? ingredientId = freezed,
    Object? displayName = null,
    Object? manualName = freezed,
    Object? quantity = freezed,
    Object? unitId = freezed,
    Object? checked = null,
    Object? note = freezed,
    Object? position = null,
    Object? categorySlug = null,
    Object? addedBy = freezed,
    Object? checkedBy = freezed,
    Object? sources = null,
  }) {
    return _then(_ShoppingListItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      listId: null == listId
          ? _self.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String,
      ingredientId: freezed == ingredientId
          ? _self.ingredientId
          : ingredientId // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      manualName: freezed == manualName
          ? _self.manualName
          : manualName // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _self.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
      checked: null == checked
          ? _self.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      categorySlug: null == categorySlug
          ? _self.categorySlug
          : categorySlug // ignore: cast_nullable_to_non_nullable
              as String,
      addedBy: freezed == addedBy
          ? _self.addedBy
          : addedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      checkedBy: freezed == checkedBy
          ? _self.checkedBy
          : checkedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      sources: null == sources
          ? _self._sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<ShoppingItemSource>,
    ));
  }
}

// dart format on
