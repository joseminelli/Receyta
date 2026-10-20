// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_plan_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealPlanEntry {
  String get id;
  Recipe get recipe;
  DateTime get date;
  MealType get mealType;
  int? get servingsOverride;
  String? get note;
  bool get done;

  /// Casa em que a refeição é compartilhada (nulo = só da pessoa).
  String? get spaceId;

  /// Nome de quem planejou, quando foi OUTRA pessoa da casa; nulo nas
  /// refeições da própria pessoa. Refeição de outra pessoa carrega só um
  /// resumo da receita (não existe na biblioteca daqui).
  String? get sharedBy;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MealPlanEntryCopyWith<MealPlanEntry> get copyWith =>
      _$MealPlanEntryCopyWithImpl<MealPlanEntry>(
          this as MealPlanEntry, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as MealPlanEntry;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MealPlanEntry &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.recipe, _this.recipe) ||
                other.recipe == _this.recipe) &&
            (identical(other.date, _this.date) || other.date == _this.date) &&
            (identical(other.mealType, _this.mealType) ||
                other.mealType == _this.mealType) &&
            (identical(other.servingsOverride, _this.servingsOverride) ||
                other.servingsOverride == _this.servingsOverride) &&
            (identical(other.note, _this.note) || other.note == _this.note) &&
            (identical(other.done, _this.done) || other.done == _this.done) &&
            (identical(other.spaceId, _this.spaceId) ||
                other.spaceId == _this.spaceId) &&
            (identical(other.sharedBy, _this.sharedBy) ||
                other.sharedBy == _this.sharedBy));
  }

  @override
  int get hashCode {
    final _this = this as MealPlanEntry;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.recipe,
        _this.date,
        _this.mealType,
        _this.servingsOverride,
        _this.note,
        _this.done,
        _this.spaceId,
        _this.sharedBy);
  }

  @override
  String toString() {
    final _this = this as MealPlanEntry;
    return 'MealPlanEntry(id: ${_this.id}, recipe: ${_this.recipe}, date: ${_this.date}, mealType: ${_this.mealType}, servingsOverride: ${_this.servingsOverride}, note: ${_this.note}, done: ${_this.done}, spaceId: ${_this.spaceId}, sharedBy: ${_this.sharedBy})';
  }
}

/// @nodoc
abstract mixin class $MealPlanEntryCopyWith<$Res> {
  factory $MealPlanEntryCopyWith(
          MealPlanEntry value, $Res Function(MealPlanEntry) _then) =
      _$MealPlanEntryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      Recipe recipe,
      DateTime date,
      MealType mealType,
      int? servingsOverride,
      String? note,
      bool done,
      String? spaceId,
      String? sharedBy});

  $RecipeCopyWith<$Res> get recipe;
}

/// @nodoc
class _$MealPlanEntryCopyWithImpl<$Res>
    implements $MealPlanEntryCopyWith<$Res> {
  _$MealPlanEntryCopyWithImpl(this._self, this._then);

  final MealPlanEntry _self;
  final $Res Function(MealPlanEntry) _then;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipe = null,
    Object? date = null,
    Object? mealType = null,
    Object? servingsOverride = freezed,
    Object? note = freezed,
    Object? done = null,
    Object? spaceId = freezed,
    Object? sharedBy = freezed,
  }) {
    return _then(MealPlanEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipe: null == recipe
          ? _self.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mealType: null == mealType
          ? _self.mealType
          : mealType // ignore: cast_nullable_to_non_nullable
              as MealType,
      servingsOverride: freezed == servingsOverride
          ? _self.servingsOverride
          : servingsOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      done: null == done
          ? _self.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
      spaceId: freezed == spaceId
          ? _self.spaceId
          : spaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      sharedBy: freezed == sharedBy
          ? _self.sharedBy
          : sharedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecipeCopyWith<$Res> get recipe {
    return $RecipeCopyWith<$Res>(_self.recipe, (value) {
      return _then(_self.copyWith(recipe: value));
    });
  }
}

/// Adds pattern-matching-related methods to [MealPlanEntry].
extension MealPlanEntryPatterns on MealPlanEntry {
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
    TResult Function(_MealPlanEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MealPlanEntry() when $default != null:
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
    TResult Function(_MealPlanEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MealPlanEntry():
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
    TResult? Function(_MealPlanEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MealPlanEntry() when $default != null:
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
            Recipe recipe,
            DateTime date,
            MealType mealType,
            int? servingsOverride,
            String? note,
            bool done,
            String? spaceId,
            String? sharedBy)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MealPlanEntry() when $default != null:
        return $default(
            _that.id,
            _that.recipe,
            _that.date,
            _that.mealType,
            _that.servingsOverride,
            _that.note,
            _that.done,
            _that.spaceId,
            _that.sharedBy);
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
            Recipe recipe,
            DateTime date,
            MealType mealType,
            int? servingsOverride,
            String? note,
            bool done,
            String? spaceId,
            String? sharedBy)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MealPlanEntry():
        return $default(
            _that.id,
            _that.recipe,
            _that.date,
            _that.mealType,
            _that.servingsOverride,
            _that.note,
            _that.done,
            _that.spaceId,
            _that.sharedBy);
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
            Recipe recipe,
            DateTime date,
            MealType mealType,
            int? servingsOverride,
            String? note,
            bool done,
            String? spaceId,
            String? sharedBy)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MealPlanEntry() when $default != null:
        return $default(
            _that.id,
            _that.recipe,
            _that.date,
            _that.mealType,
            _that.servingsOverride,
            _that.note,
            _that.done,
            _that.spaceId,
            _that.sharedBy);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MealPlanEntry extends MealPlanEntry {
  const _MealPlanEntry(
      {required this.id,
      required this.recipe,
      required this.date,
      required this.mealType,
      this.servingsOverride,
      this.note,
      this.done = false,
      this.spaceId,
      this.sharedBy})
      : super._();

  @override
  final String id;
  @override
  final Recipe recipe;
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

  /// Casa em que a refeição é compartilhada (nulo = só da pessoa).
  @override
  final String? spaceId;

  /// Nome de quem planejou, quando foi OUTRA pessoa da casa; nulo nas
  /// refeições da própria pessoa. Refeição de outra pessoa carrega só um
  /// resumo da receita (não existe na biblioteca daqui).
  @override
  final String? sharedBy;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MealPlanEntryCopyWith<_MealPlanEntry> get copyWith =>
      __$MealPlanEntryCopyWithImpl<_MealPlanEntry>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MealPlanEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.recipe, recipe) || other.recipe == recipe) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.mealType, mealType) ||
                other.mealType == mealType) &&
            (identical(other.servingsOverride, servingsOverride) ||
                other.servingsOverride == servingsOverride) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.done, done) || other.done == done) &&
            (identical(other.spaceId, spaceId) || other.spaceId == spaceId) &&
            (identical(other.sharedBy, sharedBy) ||
                other.sharedBy == sharedBy));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, recipe, date, mealType,
        servingsOverride, note, done, spaceId, sharedBy);
  }

  @override
  String toString() {
    return 'MealPlanEntry(id: $id, recipe: $recipe, date: $date, mealType: $mealType, servingsOverride: $servingsOverride, note: $note, done: $done, spaceId: $spaceId, sharedBy: $sharedBy)';
  }
}

/// @nodoc
abstract mixin class _$MealPlanEntryCopyWith<$Res>
    implements $MealPlanEntryCopyWith<$Res> {
  factory _$MealPlanEntryCopyWith(
          _MealPlanEntry value, $Res Function(_MealPlanEntry) _then) =
      __$MealPlanEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      Recipe recipe,
      DateTime date,
      MealType mealType,
      int? servingsOverride,
      String? note,
      bool done,
      String? spaceId,
      String? sharedBy});

  @override
  $RecipeCopyWith<$Res> get recipe;
}

/// @nodoc
class __$MealPlanEntryCopyWithImpl<$Res>
    implements _$MealPlanEntryCopyWith<$Res> {
  __$MealPlanEntryCopyWithImpl(this._self, this._then);

  final _MealPlanEntry _self;
  final $Res Function(_MealPlanEntry) _then;

  /// Create a copy of MealPlanEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? recipe = null,
    Object? date = null,
    Object? mealType = null,
    Object? servingsOverride = freezed,
    Object? note = freezed,
    Object? done = null,
    Object? spaceId = freezed,
    Object? sharedBy = freezed,
  }) {
    return _then(_MealPlanEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipe: null == recipe
          ? _self.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mealType: null == mealType
          ? _self.mealType
          : mealType // ignore: cast_nullable_to_non_nullable
              as MealType,
      servingsOverride: freezed == servingsOverride
          ? _self.servingsOverride
          : servingsOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      done: null == done
          ? _self.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
      spaceId: freezed == spaceId
          ? _self.spaceId
          : spaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      sharedBy: freezed == sharedBy
          ? _self.sharedBy
          : sharedBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of MealPlanEntry
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
