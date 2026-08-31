// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RankingEntry {
  String get uid => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  int get firstCount => throw _privateConstructorUsedError;
  int get secondCount => throw _privateConstructorUsedError;
  int get thirdCount => throw _privateConstructorUsedError;

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RankingEntryCopyWith<RankingEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankingEntryCopyWith<$Res> {
  factory $RankingEntryCopyWith(
    RankingEntry value,
    $Res Function(RankingEntry) then,
  ) = _$RankingEntryCopyWithImpl<$Res, RankingEntry>;
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
class _$RankingEntryCopyWithImpl<$Res, $Val extends RankingEntry>
    implements $RankingEntryCopyWith<$Res> {
  _$RankingEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RankingEntry
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
abstract class _$$RankingEntryImplCopyWith<$Res>
    implements $RankingEntryCopyWith<$Res> {
  factory _$$RankingEntryImplCopyWith(
    _$RankingEntryImpl value,
    $Res Function(_$RankingEntryImpl) then,
  ) = __$$RankingEntryImplCopyWithImpl<$Res>;
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
class __$$RankingEntryImplCopyWithImpl<$Res>
    extends _$RankingEntryCopyWithImpl<$Res, _$RankingEntryImpl>
    implements _$$RankingEntryImplCopyWith<$Res> {
  __$$RankingEntryImplCopyWithImpl(
    _$RankingEntryImpl _value,
    $Res Function(_$RankingEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RankingEntry
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
      _$RankingEntryImpl(
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

class _$RankingEntryImpl implements _RankingEntry {
  const _$RankingEntryImpl({
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
    return 'RankingEntry(uid: $uid, points: $points, firstCount: $firstCount, secondCount: $secondCount, thirdCount: $thirdCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankingEntryImpl &&
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

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RankingEntryImplCopyWith<_$RankingEntryImpl> get copyWith =>
      __$$RankingEntryImplCopyWithImpl<_$RankingEntryImpl>(this, _$identity);
}

abstract class _RankingEntry implements RankingEntry {
  const factory _RankingEntry({
    required final String uid,
    final int points,
    final int firstCount,
    final int secondCount,
    final int thirdCount,
  }) = _$RankingEntryImpl;

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

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RankingEntryImplCopyWith<_$RankingEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PlayerStats {
  int get matchesPlayed => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;
  int get votesReceived => throw _privateConstructorUsedError;
  int get firstCount => throw _privateConstructorUsedError;
  int get secondCount => throw _privateConstructorUsedError;
  int get thirdCount => throw _privateConstructorUsedError;
  int get distinctVoters => throw _privateConstructorUsedError;

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerStatsCopyWith<PlayerStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStatsCopyWith<$Res> {
  factory $PlayerStatsCopyWith(
    PlayerStats value,
    $Res Function(PlayerStats) then,
  ) = _$PlayerStatsCopyWithImpl<$Res, PlayerStats>;
  @useResult
  $Res call({
    int matchesPlayed,
    int totalPoints,
    int votesReceived,
    int firstCount,
    int secondCount,
    int thirdCount,
    int distinctVoters,
  });
}

/// @nodoc
class _$PlayerStatsCopyWithImpl<$Res, $Val extends PlayerStats>
    implements $PlayerStatsCopyWith<$Res> {
  _$PlayerStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchesPlayed = null,
    Object? totalPoints = null,
    Object? votesReceived = null,
    Object? firstCount = null,
    Object? secondCount = null,
    Object? thirdCount = null,
    Object? distinctVoters = null,
  }) {
    return _then(
      _value.copyWith(
            matchesPlayed: null == matchesPlayed
                ? _value.matchesPlayed
                : matchesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPoints: null == totalPoints
                ? _value.totalPoints
                : totalPoints // ignore: cast_nullable_to_non_nullable
                      as int,
            votesReceived: null == votesReceived
                ? _value.votesReceived
                : votesReceived // ignore: cast_nullable_to_non_nullable
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
            distinctVoters: null == distinctVoters
                ? _value.distinctVoters
                : distinctVoters // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerStatsImplCopyWith<$Res>
    implements $PlayerStatsCopyWith<$Res> {
  factory _$$PlayerStatsImplCopyWith(
    _$PlayerStatsImpl value,
    $Res Function(_$PlayerStatsImpl) then,
  ) = __$$PlayerStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int matchesPlayed,
    int totalPoints,
    int votesReceived,
    int firstCount,
    int secondCount,
    int thirdCount,
    int distinctVoters,
  });
}

/// @nodoc
class __$$PlayerStatsImplCopyWithImpl<$Res>
    extends _$PlayerStatsCopyWithImpl<$Res, _$PlayerStatsImpl>
    implements _$$PlayerStatsImplCopyWith<$Res> {
  __$$PlayerStatsImplCopyWithImpl(
    _$PlayerStatsImpl _value,
    $Res Function(_$PlayerStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchesPlayed = null,
    Object? totalPoints = null,
    Object? votesReceived = null,
    Object? firstCount = null,
    Object? secondCount = null,
    Object? thirdCount = null,
    Object? distinctVoters = null,
  }) {
    return _then(
      _$PlayerStatsImpl(
        matchesPlayed: null == matchesPlayed
            ? _value.matchesPlayed
            : matchesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPoints: null == totalPoints
            ? _value.totalPoints
            : totalPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        votesReceived: null == votesReceived
            ? _value.votesReceived
            : votesReceived // ignore: cast_nullable_to_non_nullable
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
        distinctVoters: null == distinctVoters
            ? _value.distinctVoters
            : distinctVoters // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$PlayerStatsImpl extends _PlayerStats {
  const _$PlayerStatsImpl({
    this.matchesPlayed = 0,
    this.totalPoints = 0,
    this.votesReceived = 0,
    this.firstCount = 0,
    this.secondCount = 0,
    this.thirdCount = 0,
    this.distinctVoters = 0,
  }) : super._();

  @override
  @JsonKey()
  final int matchesPlayed;
  @override
  @JsonKey()
  final int totalPoints;
  @override
  @JsonKey()
  final int votesReceived;
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
  @JsonKey()
  final int distinctVoters;

  @override
  String toString() {
    return 'PlayerStats(matchesPlayed: $matchesPlayed, totalPoints: $totalPoints, votesReceived: $votesReceived, firstCount: $firstCount, secondCount: $secondCount, thirdCount: $thirdCount, distinctVoters: $distinctVoters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStatsImpl &&
            (identical(other.matchesPlayed, matchesPlayed) ||
                other.matchesPlayed == matchesPlayed) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.votesReceived, votesReceived) ||
                other.votesReceived == votesReceived) &&
            (identical(other.firstCount, firstCount) ||
                other.firstCount == firstCount) &&
            (identical(other.secondCount, secondCount) ||
                other.secondCount == secondCount) &&
            (identical(other.thirdCount, thirdCount) ||
                other.thirdCount == thirdCount) &&
            (identical(other.distinctVoters, distinctVoters) ||
                other.distinctVoters == distinctVoters));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    matchesPlayed,
    totalPoints,
    votesReceived,
    firstCount,
    secondCount,
    thirdCount,
    distinctVoters,
  );

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStatsImplCopyWith<_$PlayerStatsImpl> get copyWith =>
      __$$PlayerStatsImplCopyWithImpl<_$PlayerStatsImpl>(this, _$identity);
}

abstract class _PlayerStats extends PlayerStats {
  const factory _PlayerStats({
    final int matchesPlayed,
    final int totalPoints,
    final int votesReceived,
    final int firstCount,
    final int secondCount,
    final int thirdCount,
    final int distinctVoters,
  }) = _$PlayerStatsImpl;
  const _PlayerStats._() : super._();

  @override
  int get matchesPlayed;
  @override
  int get totalPoints;
  @override
  int get votesReceived;
  @override
  int get firstCount;
  @override
  int get secondCount;
  @override
  int get thirdCount;
  @override
  int get distinctVoters;

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerStatsImplCopyWith<_$PlayerStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
