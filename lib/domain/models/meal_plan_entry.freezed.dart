// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_plan_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MealPlanEntry {
  String get id => throw _privateConstructorUsedError;
  String get recipeId => throw _privateConstructorUsedError;
  String get recipeName => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  MealType get mealType => throw _privateConstructorUsedError;
  int? get servingsOverride => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  bool get done => throw _privateConstructorUsedError;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealPlanEntryCopyWith<MealPlanEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealPlanEntryCopyWith<$Res> {
  factory $MealPlanEntryCopyWith(
          MealPlanEntry value, $Res Function(MealPlanEntry) then) =
      _$MealPlanEntryCopyWithImpl<$Res, MealPlanEntry>;
  @useResult
  $Res call(
      {String id,
      String recipeId,
      String recipeName,
      DateTime date,
      MealType mealType,
      int? servingsOverride,
      String? note,
      bool done});
}

/// @nodoc
class _$MealPlanEntryCopyWithImpl<$Res, $Val extends MealPlanEntry>
    implements $MealPlanEntryCopyWith<$Res> {
  _$MealPlanEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipeId = null,
    Object? recipeName = null,
    Object? date = null,
    Object? mealType = null,
    Object? servingsOverride = freezed,
    Object? note = freezed,
    Object? done = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _value.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mealType: null == mealType
          ? _value.mealType
          : mealType // ignore: cast_nullable_to_non_nullable
              as MealType,
      servingsOverride: freezed == servingsOverride
          ? _value.servingsOverride
          : servingsOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      done: null == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealPlanEntryImplCopyWith<$Res>
    implements $MealPlanEntryCopyWith<$Res> {
  factory _$$MealPlanEntryImplCopyWith(
          _$MealPlanEntryImpl value, $Res Function(_$MealPlanEntryImpl) then) =
      __$$MealPlanEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String recipeId,
      String recipeName,
      DateTime date,
      MealType mealType,
      int? servingsOverride,
      String? note,
      bool done});
}

/// @nodoc
class __$$MealPlanEntryImplCopyWithImpl<$Res>
    extends _$MealPlanEntryCopyWithImpl<$Res, _$MealPlanEntryImpl>
    implements _$$MealPlanEntryImplCopyWith<$Res> {
  __$$MealPlanEntryImplCopyWithImpl(
      _$MealPlanEntryImpl _value, $Res Function(_$MealPlanEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipeId = null,
    Object? recipeName = null,
    Object? date = null,
    Object? mealType = null,
    Object? servingsOverride = freezed,
    Object? note = freezed,
    Object? done = null,
  }) {
    return _then(_$MealPlanEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _value.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mealType: null == mealType
          ? _value.mealType
          : mealType // ignore: cast_nullable_to_non_nullable
              as MealType,
      servingsOverride: freezed == servingsOverride
          ? _value.servingsOverride
          : servingsOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      done: null == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$MealPlanEntryImpl implements _MealPlanEntry {
  const _$MealPlanEntryImpl(
      {required this.id,
      required this.recipeId,
      required this.recipeName,
      required this.date,
      required this.mealType,
      this.servingsOverride,
      this.note,
      this.done = false});

  @override
  final String id;
  @override
  final String recipeId;
  @override
  final String recipeName;
  @override
  final DateTime date;
  @override
  final MealType mealType;
  @override
  final int? servingsOverride;
  @override
  final String? note;
  @override
  @JsonKey()
  final bool done;

  @override
  String toString() {
    return 'MealPlanEntry(id: $id, recipeId: $recipeId, recipeName: $recipeName, date: $date, mealType: $mealType, servingsOverride: $servingsOverride, note: $note, done: $done)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealPlanEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.recipeName, recipeName) ||
                other.recipeName == recipeName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.mealType, mealType) ||
                other.mealType == mealType) &&
            (identical(other.servingsOverride, servingsOverride) ||
                other.servingsOverride == servingsOverride) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.done, done) || other.done == done));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, recipeId, recipeName, date,
      mealType, servingsOverride, note, done);

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealPlanEntryImplCopyWith<_$MealPlanEntryImpl> get copyWith =>
      __$$MealPlanEntryImplCopyWithImpl<_$MealPlanEntryImpl>(this, _$identity);
}

abstract class _MealPlanEntry implements MealPlanEntry {
  const factory _MealPlanEntry(
      {required final String id,
      required final String recipeId,
      required final String recipeName,
      required final DateTime date,
      required final MealType mealType,
      final int? servingsOverride,
      final String? note,
      final bool done}) = _$MealPlanEntryImpl;

  @override
  String get id;
  @override
  String get recipeId;
  @override
  String get recipeName;
  @override
  DateTime get date;
  @override
  MealType get mealType;
  @override
  int? get servingsOverride;
  @override
  String? get note;
  @override
  bool get done;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealPlanEntryImplCopyWith<_$MealPlanEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
