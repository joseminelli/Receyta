// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ShoppingItemSource {
  String get recipeId => throw _privateConstructorUsedError;
  String get recipeName => throw _privateConstructorUsedError;
  double? get quantity => throw _privateConstructorUsedError;
  String? get unitId => throw _privateConstructorUsedError;

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShoppingItemSourceCopyWith<ShoppingItemSource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShoppingItemSourceCopyWith<$Res> {
  factory $ShoppingItemSourceCopyWith(
          ShoppingItemSource value, $Res Function(ShoppingItemSource) then) =
      _$ShoppingItemSourceCopyWithImpl<$Res, ShoppingItemSource>;
  @useResult
  $Res call(
      {String recipeId, String recipeName, double? quantity, String? unitId});
}

/// @nodoc
class _$ShoppingItemSourceCopyWithImpl<$Res, $Val extends ShoppingItemSource>
    implements $ShoppingItemSourceCopyWith<$Res> {
  _$ShoppingItemSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _value.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _value.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShoppingItemSourceImplCopyWith<$Res>
    implements $ShoppingItemSourceCopyWith<$Res> {
  factory _$$ShoppingItemSourceImplCopyWith(_$ShoppingItemSourceImpl value,
          $Res Function(_$ShoppingItemSourceImpl) then) =
      __$$ShoppingItemSourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String recipeId, String recipeName, double? quantity, String? unitId});
}

/// @nodoc
class __$$ShoppingItemSourceImplCopyWithImpl<$Res>
    extends _$ShoppingItemSourceCopyWithImpl<$Res, _$ShoppingItemSourceImpl>
    implements _$$ShoppingItemSourceImplCopyWith<$Res> {
  __$$ShoppingItemSourceImplCopyWithImpl(_$ShoppingItemSourceImpl _value,
      $Res Function(_$ShoppingItemSourceImpl) _then)
      : super(_value, _then);

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
    return _then(_$ShoppingItemSourceImpl(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _value.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _value.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ShoppingItemSourceImpl implements _ShoppingItemSource {
  const _$ShoppingItemSourceImpl(
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

  @override
  String toString() {
    return 'ShoppingItemSource(recipeId: $recipeId, recipeName: $recipeName, quantity: $quantity, unitId: $unitId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShoppingItemSourceImpl &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.recipeName, recipeName) ||
                other.recipeName == recipeName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitId, unitId) || other.unitId == unitId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, recipeId, recipeName, quantity, unitId);

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingItemSourceImplCopyWith<_$ShoppingItemSourceImpl> get copyWith =>
      __$$ShoppingItemSourceImplCopyWithImpl<_$ShoppingItemSourceImpl>(
          this, _$identity);
}

abstract class _ShoppingItemSource implements ShoppingItemSource {
  const factory _ShoppingItemSource(
      {required final String recipeId,
      required final String recipeName,
      final double? quantity,
      final String? unitId}) = _$ShoppingItemSourceImpl;

  @override
  String get recipeId;
  @override
  String get recipeName;
  @override
  double? get quantity;
  @override
  String? get unitId;

  /// Create a copy of ShoppingItemSource
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShoppingItemSourceImplCopyWith<_$ShoppingItemSourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ShoppingListItem {
  String get id => throw _privateConstructorUsedError;
  String get listId => throw _privateConstructorUsedError;
  String? get ingredientId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get manualName => throw _privateConstructorUsedError;

  /// Nulo quando nenhuma origem tinha quantidade numérica reconhecida —
  /// a tela mostra a unidade/nome sem número, não inventa um.
  double? get quantity => throw _privateConstructorUsedError;
  String? get unitId => throw _privateConstructorUsedError;
  bool get checked => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  List<ShoppingItemSource> get sources => throw _privateConstructorUsedError;

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShoppingListItemCopyWith<ShoppingListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShoppingListItemCopyWith<$Res> {
  factory $ShoppingListItemCopyWith(
          ShoppingListItem value, $Res Function(ShoppingListItem) then) =
      _$ShoppingListItemCopyWithImpl<$Res, ShoppingListItem>;
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
      List<ShoppingItemSource> sources});
}

/// @nodoc
class _$ShoppingListItemCopyWithImpl<$Res, $Val extends ShoppingListItem>
    implements $ShoppingListItemCopyWith<$Res> {
  _$ShoppingListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    Object? sources = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      listId: null == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String,
      ingredientId: freezed == ingredientId
          ? _value.ingredientId
          : ingredientId // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      manualName: freezed == manualName
          ? _value.manualName
          : manualName // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _value.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      sources: null == sources
          ? _value.sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<ShoppingItemSource>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShoppingListItemImplCopyWith<$Res>
    implements $ShoppingListItemCopyWith<$Res> {
  factory _$$ShoppingListItemImplCopyWith(_$ShoppingListItemImpl value,
          $Res Function(_$ShoppingListItemImpl) then) =
      __$$ShoppingListItemImplCopyWithImpl<$Res>;
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
      List<ShoppingItemSource> sources});
}

/// @nodoc
class __$$ShoppingListItemImplCopyWithImpl<$Res>
    extends _$ShoppingListItemCopyWithImpl<$Res, _$ShoppingListItemImpl>
    implements _$$ShoppingListItemImplCopyWith<$Res> {
  __$$ShoppingListItemImplCopyWithImpl(_$ShoppingListItemImpl _value,
      $Res Function(_$ShoppingListItemImpl) _then)
      : super(_value, _then);

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
    Object? sources = null,
  }) {
    return _then(_$ShoppingListItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      listId: null == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String,
      ingredientId: freezed == ingredientId
          ? _value.ingredientId
          : ingredientId // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      manualName: freezed == manualName
          ? _value.manualName
          : manualName // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unitId: freezed == unitId
          ? _value.unitId
          : unitId // ignore: cast_nullable_to_non_nullable
              as String?,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      sources: null == sources
          ? _value._sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<ShoppingItemSource>,
    ));
  }
}

/// @nodoc

class _$ShoppingListItemImpl implements _ShoppingListItem {
  const _$ShoppingListItemImpl(
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
      final List<ShoppingItemSource> sources = const <ShoppingItemSource>[]})
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
  final List<ShoppingItemSource> _sources;
  @override
  @JsonKey()
  List<ShoppingItemSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, listId: $listId, ingredientId: $ingredientId, displayName: $displayName, manualName: $manualName, quantity: $quantity, unitId: $unitId, checked: $checked, note: $note, position: $position, sources: $sources)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShoppingListItemImpl &&
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
            const DeepCollectionEquality().equals(other._sources, _sources));
  }

  @override
  int get hashCode => Object.hash(
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
      const DeepCollectionEquality().hash(_sources));

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingListItemImplCopyWith<_$ShoppingListItemImpl> get copyWith =>
      __$$ShoppingListItemImplCopyWithImpl<_$ShoppingListItemImpl>(
          this, _$identity);
}

abstract class _ShoppingListItem implements ShoppingListItem {
  const factory _ShoppingListItem(
      {required final String id,
      required final String listId,
      final String? ingredientId,
      required final String displayName,
      final String? manualName,
      final double? quantity,
      final String? unitId,
      final bool checked,
      final String? note,
      final int position,
      final List<ShoppingItemSource> sources}) = _$ShoppingListItemImpl;

  @override
  String get id;
  @override
  String get listId;
  @override
  String? get ingredientId;
  @override
  String get displayName;
  @override
  String? get manualName;

  /// Nulo quando nenhuma origem tinha quantidade numérica reconhecida —
  /// a tela mostra a unidade/nome sem número, não inventa um.
  @override
  double? get quantity;
  @override
  String? get unitId;
  @override
  bool get checked;
  @override
  String? get note;
  @override
  int get position;
  @override
  List<ShoppingItemSource> get sources;

  /// Create a copy of ShoppingListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShoppingListItemImplCopyWith<_$ShoppingListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
