// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking_calculator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlayerRankingEntry {
  String get uid => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  int get firstCount => throw _privateConstructorUsedError;
  int get secondCount => throw _privateConstructorUsedError;
  int get thirdCount => throw _privateConstructorUsedError;

  /// Create a copy of PlayerRankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerRankingEntryCopyWith<PlayerRankingEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerRankingEntryCopyWith<$Res> {
  factory $PlayerRankingEntryCopyWith(
    PlayerRankingEntry value,
    $Res Function(PlayerRankingEntry) then,
  ) = _$PlayerRankingEntryCopyWithImpl<$Res, PlayerRankingEntry>;
  @useResult
  $Res call({
    String uid,
    int points,
    int firstCount,
    int secondCount,
    int thirdCount,
  });
}

/// @nodoc
class _$PlayerRankingEntryCopyWithImpl<$Res, $Val extends PlayerRankingEntry>
    implements $PlayerRankingEntryCopyWith<$Res> {
  _$PlayerRankingEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerRankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? points = null,
    Object? firstCount = null,
    Object? secondCount = null,
    Object? thirdCount = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            firstCount: null == firstCount
                ? _value.firstCount
                : firstCount // ignore: cast_nullable_to_non_nullable
                      as int,
            secondCount: null == secondCount
                ? _value.secondCount
                : secondCount // ignore: cast_nullable_to_non_nullable
                      as int,
            thirdCount: null == thirdCount
                ? _value.thirdCount
                : thirdCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerRankingEntryImplCopyWith<$Res>
    implements $PlayerRankingEntryCopyWith<$Res> {
  factory _$$PlayerRankingEntryImplCopyWith(
    _$PlayerRankingEntryImpl value,
    $Res Function(_$PlayerRankingEntryImpl) then,
  ) = __$$PlayerRankingEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    int points,
    int firstCount,
    int secondCount,
    int thirdCount,
  });
}

/// @nodoc
class __$$PlayerRankingEntryImplCopyWithImpl<$Res>
    extends _$PlayerRankingEntryCopyWithImpl<$Res, _$PlayerRankingEntryImpl>
    implements _$$PlayerRankingEntryImplCopyWith<$Res> {
  __$$PlayerRankingEntryImplCopyWithImpl(
    _$PlayerRankingEntryImpl _value,
    $Res Function(_$PlayerRankingEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerRankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? points = null,
    Object? firstCount = null,
    Object? secondCount = null,
    Object? thirdCount = null,
  }) {
    return _then(
      _$PlayerRankingEntryImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        firstCount: null == firstCount
            ? _value.firstCount
            : firstCount // ignore: cast_nullable_to_non_nullable
                  as int,
        secondCount: null == secondCount
            ? _value.secondCount
            : secondCount // ignore: cast_nullable_to_non_nullable
                  as int,
        thirdCount: null == thirdCount
            ? _value.thirdCount
            : thirdCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$PlayerRankingEntryImpl implements _PlayerRankingEntry {
  const _$PlayerRankingEntryImpl({
    required this.uid,
    this.points = 0,
    this.firstCount = 0,
    this.secondCount = 0,
    this.thirdCount = 0,
  });

  @override
  final String uid;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final int firstCount;
  @override
  @JsonKey()
  final int secondCount;
  @override
  @JsonKey()
  final int thirdCount;

  @override
  String toString() {
    return 'PlayerRankingEntry(uid: $uid, points: $points, firstCount: $firstCount, secondCount: $secondCount, thirdCount: $thirdCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerRankingEntryImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.firstCount, firstCount) ||
                other.firstCount == firstCount) &&
            (identical(other.secondCount, secondCount) ||
                other.secondCount == secondCount) &&
            (identical(other.thirdCount, thirdCount) ||
                other.thirdCount == thirdCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    points,
    firstCount,
    secondCount,
    thirdCount,
  );

  /// Create a copy of PlayerRankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerRankingEntryImplCopyWith<_$PlayerRankingEntryImpl> get copyWith =>
      __$$PlayerRankingEntryImplCopyWithImpl<_$PlayerRankingEntryImpl>(
        this,
        _$identity,
      );
}

abstract class _PlayerRankingEntry implements PlayerRankingEntry {
  const factory _PlayerRankingEntry({
    required final String uid,
    final int points,
    final int firstCount,
    final int secondCount,
    final int thirdCount,
  }) = _$PlayerRankingEntryImpl;

  @override
  String get uid;
  @override
  int get points;
  @override
  int get firstCount;
  @override
  int get secondCount;
  @override
  int get thirdCount;

  /// Create a copy of PlayerRankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerRankingEntryImplCopyWith<_$PlayerRankingEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
