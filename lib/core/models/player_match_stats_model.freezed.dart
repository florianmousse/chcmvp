// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_match_stats_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlayerMatchStats _$PlayerMatchStatsFromJson(Map<String, dynamic> json) {
  return _PlayerMatchStats.fromJson(json);
}

/// @nodoc
mixin _$PlayerMatchStats {
  String get playerId => throw _privateConstructorUsedError;
  int get goals => throw _privateConstructorUsedError;
  int get assists => throw _privateConstructorUsedError;
  int get greenCards => throw _privateConstructorUsedError;
  int get yellowCards => throw _privateConstructorUsedError;
  int get redCards => throw _privateConstructorUsedError;

  /// Serializes this PlayerMatchStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerMatchStatsCopyWith<PlayerMatchStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerMatchStatsCopyWith<$Res> {
  factory $PlayerMatchStatsCopyWith(
    PlayerMatchStats value,
    $Res Function(PlayerMatchStats) then,
  ) = _$PlayerMatchStatsCopyWithImpl<$Res, PlayerMatchStats>;
  @useResult
  $Res call({
    String playerId,
    int goals,
    int assists,
    int greenCards,
    int yellowCards,
    int redCards,
  });
}

/// @nodoc
class _$PlayerMatchStatsCopyWithImpl<$Res, $Val extends PlayerMatchStats>
    implements $PlayerMatchStatsCopyWith<$Res> {
  _$PlayerMatchStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? goals = null,
    Object? assists = null,
    Object? greenCards = null,
    Object? yellowCards = null,
    Object? redCards = null,
  }) {
    return _then(
      _value.copyWith(
            playerId: null == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String,
            goals: null == goals
                ? _value.goals
                : goals // ignore: cast_nullable_to_non_nullable
                      as int,
            assists: null == assists
                ? _value.assists
                : assists // ignore: cast_nullable_to_non_nullable
                      as int,
            greenCards: null == greenCards
                ? _value.greenCards
                : greenCards // ignore: cast_nullable_to_non_nullable
                      as int,
            yellowCards: null == yellowCards
                ? _value.yellowCards
                : yellowCards // ignore: cast_nullable_to_non_nullable
                      as int,
            redCards: null == redCards
                ? _value.redCards
                : redCards // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerMatchStatsImplCopyWith<$Res>
    implements $PlayerMatchStatsCopyWith<$Res> {
  factory _$$PlayerMatchStatsImplCopyWith(
    _$PlayerMatchStatsImpl value,
    $Res Function(_$PlayerMatchStatsImpl) then,
  ) = __$$PlayerMatchStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String playerId,
    int goals,
    int assists,
    int greenCards,
    int yellowCards,
    int redCards,
  });
}

/// @nodoc
class __$$PlayerMatchStatsImplCopyWithImpl<$Res>
    extends _$PlayerMatchStatsCopyWithImpl<$Res, _$PlayerMatchStatsImpl>
    implements _$$PlayerMatchStatsImplCopyWith<$Res> {
  __$$PlayerMatchStatsImplCopyWithImpl(
    _$PlayerMatchStatsImpl _value,
    $Res Function(_$PlayerMatchStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? goals = null,
    Object? assists = null,
    Object? greenCards = null,
    Object? yellowCards = null,
    Object? redCards = null,
  }) {
    return _then(
      _$PlayerMatchStatsImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        goals: null == goals
            ? _value.goals
            : goals // ignore: cast_nullable_to_non_nullable
                  as int,
        assists: null == assists
            ? _value.assists
            : assists // ignore: cast_nullable_to_non_nullable
                  as int,
        greenCards: null == greenCards
            ? _value.greenCards
            : greenCards // ignore: cast_nullable_to_non_nullable
                  as int,
        yellowCards: null == yellowCards
            ? _value.yellowCards
            : yellowCards // ignore: cast_nullable_to_non_nullable
                  as int,
        redCards: null == redCards
            ? _value.redCards
            : redCards // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerMatchStatsImpl implements _PlayerMatchStats {
  const _$PlayerMatchStatsImpl({
    required this.playerId,
    this.goals = 0,
    this.assists = 0,
    this.greenCards = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  factory _$PlayerMatchStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerMatchStatsImplFromJson(json);

  @override
  final String playerId;
  @override
  @JsonKey()
  final int goals;
  @override
  @JsonKey()
  final int assists;
  @override
  @JsonKey()
  final int greenCards;
  @override
  @JsonKey()
  final int yellowCards;
  @override
  @JsonKey()
  final int redCards;

  @override
  String toString() {
    return 'PlayerMatchStats(playerId: $playerId, goals: $goals, assists: $assists, greenCards: $greenCards, yellowCards: $yellowCards, redCards: $redCards)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerMatchStatsImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.goals, goals) || other.goals == goals) &&
            (identical(other.assists, assists) || other.assists == assists) &&
            (identical(other.greenCards, greenCards) ||
                other.greenCards == greenCards) &&
            (identical(other.yellowCards, yellowCards) ||
                other.yellowCards == yellowCards) &&
            (identical(other.redCards, redCards) ||
                other.redCards == redCards));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    playerId,
    goals,
    assists,
    greenCards,
    yellowCards,
    redCards,
  );

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerMatchStatsImplCopyWith<_$PlayerMatchStatsImpl> get copyWith =>
      __$$PlayerMatchStatsImplCopyWithImpl<_$PlayerMatchStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerMatchStatsImplToJson(this);
  }
}

abstract class _PlayerMatchStats implements PlayerMatchStats {
  const factory _PlayerMatchStats({
    required final String playerId,
    final int goals,
    final int assists,
    final int greenCards,
    final int yellowCards,
    final int redCards,
  }) = _$PlayerMatchStatsImpl;

  factory _PlayerMatchStats.fromJson(Map<String, dynamic> json) =
      _$PlayerMatchStatsImpl.fromJson;

  @override
  String get playerId;
  @override
  int get goals;
  @override
  int get assists;
  @override
  int get greenCards;
  @override
  int get yellowCards;
  @override
  int get redCards;

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerMatchStatsImplCopyWith<_$PlayerMatchStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
