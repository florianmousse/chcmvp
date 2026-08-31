// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PointsScale _$PointsScaleFromJson(Map<String, dynamic> json) {
  return _PointsScale.fromJson(json);
}

/// @nodoc
mixin _$PointsScale {
  int get first => throw _privateConstructorUsedError;
  int get second => throw _privateConstructorUsedError;
  int get third => throw _privateConstructorUsedError;

  /// Serializes this PointsScale to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointsScale
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointsScaleCopyWith<PointsScale> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointsScaleCopyWith<$Res> {
  factory $PointsScaleCopyWith(
    PointsScale value,
    $Res Function(PointsScale) then,
  ) = _$PointsScaleCopyWithImpl<$Res, PointsScale>;
  @useResult
  $Res call({int first, int second, int third});
}

/// @nodoc
class _$PointsScaleCopyWithImpl<$Res, $Val extends PointsScale>
    implements $PointsScaleCopyWith<$Res> {
  _$PointsScaleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointsScale
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? first = null,
    Object? second = null,
    Object? third = null,
  }) {
    return _then(
      _value.copyWith(
            first: null == first
                ? _value.first
                : first // ignore: cast_nullable_to_non_nullable
                      as int,
            second: null == second
                ? _value.second
                : second // ignore: cast_nullable_to_non_nullable
                      as int,
            third: null == third
                ? _value.third
                : third // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PointsScaleImplCopyWith<$Res>
    implements $PointsScaleCopyWith<$Res> {
  factory _$$PointsScaleImplCopyWith(
    _$PointsScaleImpl value,
    $Res Function(_$PointsScaleImpl) then,
  ) = __$$PointsScaleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int first, int second, int third});
}

/// @nodoc
class __$$PointsScaleImplCopyWithImpl<$Res>
    extends _$PointsScaleCopyWithImpl<$Res, _$PointsScaleImpl>
    implements _$$PointsScaleImplCopyWith<$Res> {
  __$$PointsScaleImplCopyWithImpl(
    _$PointsScaleImpl _value,
    $Res Function(_$PointsScaleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PointsScale
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? first = null,
    Object? second = null,
    Object? third = null,
  }) {
    return _then(
      _$PointsScaleImpl(
        first: null == first
            ? _value.first
            : first // ignore: cast_nullable_to_non_nullable
                  as int,
        second: null == second
            ? _value.second
            : second // ignore: cast_nullable_to_non_nullable
                  as int,
        third: null == third
            ? _value.third
            : third // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PointsScaleImpl implements _PointsScale {
  const _$PointsScaleImpl({this.first = 5, this.second = 3, this.third = 1});

  factory _$PointsScaleImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointsScaleImplFromJson(json);

  @override
  @JsonKey()
  final int first;
  @override
  @JsonKey()
  final int second;
  @override
  @JsonKey()
  final int third;

  @override
  String toString() {
    return 'PointsScale(first: $first, second: $second, third: $third)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointsScaleImpl &&
            (identical(other.first, first) || other.first == first) &&
            (identical(other.second, second) || other.second == second) &&
            (identical(other.third, third) || other.third == third));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, first, second, third);

  /// Create a copy of PointsScale
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointsScaleImplCopyWith<_$PointsScaleImpl> get copyWith =>
      __$$PointsScaleImplCopyWithImpl<_$PointsScaleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointsScaleImplToJson(this);
  }
}

abstract class _PointsScale implements PointsScale {
  const factory _PointsScale({
    final int first,
    final int second,
    final int third,
  }) = _$PointsScaleImpl;

  factory _PointsScale.fromJson(Map<String, dynamic> json) =
      _$PointsScaleImpl.fromJson;

  @override
  int get first;
  @override
  int get second;
  @override
  int get third;

  /// Create a copy of PointsScale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointsScaleImplCopyWith<_$PointsScaleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) {
  return _MatchModel.fromJson(json);
}

/// @nodoc
mixin _$MatchModel {
  String get id => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get date => throw _privateConstructorUsedError;
  String get time => throw _privateConstructorUsedError;
  String get opponent => throw _privateConstructorUsedError;
  bool get isHome => throw _privateConstructorUsedError;
  String get team => throw _privateConstructorUsedError;
  MatchStatus get status => throw _privateConstructorUsedError;
  List<String> get presentPlayerIds => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get votingOpensAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get votingClosesAt => throw _privateConstructorUsedError;
  PointsScale get pointsScale => throw _privateConstructorUsedError;
  bool get allowSelfVote => throw _privateConstructorUsedError;

  /// Chemin de l'asset local choisi dans le formulaire de match (voir
  /// core/config/team_logos_catalog.dart) — null si aucun logo choisi,
  /// auquel cas une icône de secours s'affiche à la place.
  String? get opponentLogoAsset => throw _privateConstructorUsedError;

  /// Serializes this MatchModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchModelCopyWith<MatchModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchModelCopyWith<$Res> {
  factory $MatchModelCopyWith(
    MatchModel value,
    $Res Function(MatchModel) then,
  ) = _$MatchModelCopyWithImpl<$Res, MatchModel>;
  @useResult
  $Res call({
    String id,
    @TimestampConverter() DateTime date,
    String time,
    String opponent,
    bool isHome,
    String team,
    MatchStatus status,
    List<String> presentPlayerIds,
    @TimestampConverter() DateTime? votingOpensAt,
    @TimestampConverter() DateTime? votingClosesAt,
    PointsScale pointsScale,
    bool allowSelfVote,
    String? opponentLogoAsset,
  });

  $PointsScaleCopyWith<$Res> get pointsScale;
}

/// @nodoc
class _$MatchModelCopyWithImpl<$Res, $Val extends MatchModel>
    implements $MatchModelCopyWith<$Res> {
  _$MatchModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? time = null,
    Object? opponent = null,
    Object? isHome = null,
    Object? team = null,
    Object? status = null,
    Object? presentPlayerIds = null,
    Object? votingOpensAt = freezed,
    Object? votingClosesAt = freezed,
    Object? pointsScale = null,
    Object? allowSelfVote = null,
    Object? opponentLogoAsset = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            time: null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as String,
            opponent: null == opponent
                ? _value.opponent
                : opponent // ignore: cast_nullable_to_non_nullable
                      as String,
            isHome: null == isHome
                ? _value.isHome
                : isHome // ignore: cast_nullable_to_non_nullable
                      as bool,
            team: null == team
                ? _value.team
                : team // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as MatchStatus,
            presentPlayerIds: null == presentPlayerIds
                ? _value.presentPlayerIds
                : presentPlayerIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            votingOpensAt: freezed == votingOpensAt
                ? _value.votingOpensAt
                : votingOpensAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            votingClosesAt: freezed == votingClosesAt
                ? _value.votingClosesAt
                : votingClosesAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pointsScale: null == pointsScale
                ? _value.pointsScale
                : pointsScale // ignore: cast_nullable_to_non_nullable
                      as PointsScale,
            allowSelfVote: null == allowSelfVote
                ? _value.allowSelfVote
                : allowSelfVote // ignore: cast_nullable_to_non_nullable
                      as bool,
            opponentLogoAsset: freezed == opponentLogoAsset
                ? _value.opponentLogoAsset
                : opponentLogoAsset // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of MatchModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PointsScaleCopyWith<$Res> get pointsScale {
    return $PointsScaleCopyWith<$Res>(_value.pointsScale, (value) {
      return _then(_value.copyWith(pointsScale: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MatchModelImplCopyWith<$Res>
    implements $MatchModelCopyWith<$Res> {
  factory _$$MatchModelImplCopyWith(
    _$MatchModelImpl value,
    $Res Function(_$MatchModelImpl) then,
  ) = __$$MatchModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @TimestampConverter() DateTime date,
    String time,
    String opponent,
    bool isHome,
    String team,
    MatchStatus status,
    List<String> presentPlayerIds,
    @TimestampConverter() DateTime? votingOpensAt,
    @TimestampConverter() DateTime? votingClosesAt,
    PointsScale pointsScale,
    bool allowSelfVote,
    String? opponentLogoAsset,
  });

  @override
  $PointsScaleCopyWith<$Res> get pointsScale;
}

/// @nodoc
class __$$MatchModelImplCopyWithImpl<$Res>
    extends _$MatchModelCopyWithImpl<$Res, _$MatchModelImpl>
    implements _$$MatchModelImplCopyWith<$Res> {
  __$$MatchModelImplCopyWithImpl(
    _$MatchModelImpl _value,
    $Res Function(_$MatchModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MatchModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? time = null,
    Object? opponent = null,
    Object? isHome = null,
    Object? team = null,
    Object? status = null,
    Object? presentPlayerIds = null,
    Object? votingOpensAt = freezed,
    Object? votingClosesAt = freezed,
    Object? pointsScale = null,
    Object? allowSelfVote = null,
    Object? opponentLogoAsset = freezed,
  }) {
    return _then(
      _$MatchModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        time: null == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as String,
        opponent: null == opponent
            ? _value.opponent
            : opponent // ignore: cast_nullable_to_non_nullable
                  as String,
        isHome: null == isHome
            ? _value.isHome
            : isHome // ignore: cast_nullable_to_non_nullable
                  as bool,
        team: null == team
            ? _value.team
            : team // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as MatchStatus,
        presentPlayerIds: null == presentPlayerIds
            ? _value._presentPlayerIds
            : presentPlayerIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        votingOpensAt: freezed == votingOpensAt
            ? _value.votingOpensAt
            : votingOpensAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        votingClosesAt: freezed == votingClosesAt
            ? _value.votingClosesAt
            : votingClosesAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pointsScale: null == pointsScale
            ? _value.pointsScale
            : pointsScale // ignore: cast_nullable_to_non_nullable
                  as PointsScale,
        allowSelfVote: null == allowSelfVote
            ? _value.allowSelfVote
            : allowSelfVote // ignore: cast_nullable_to_non_nullable
                  as bool,
        opponentLogoAsset: freezed == opponentLogoAsset
            ? _value.opponentLogoAsset
            : opponentLogoAsset // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchModelImpl extends _MatchModel {
  const _$MatchModelImpl({
    required this.id,
    @TimestampConverter() required this.date,
    required this.time,
    required this.opponent,
    required this.isHome,
    required this.team,
    this.status = MatchStatus.upcoming,
    final List<String> presentPlayerIds = const <String>[],
    @TimestampConverter() this.votingOpensAt,
    @TimestampConverter() this.votingClosesAt,
    this.pointsScale = const PointsScale(),
    this.allowSelfVote = false,
    this.opponentLogoAsset,
  }) : _presentPlayerIds = presentPlayerIds,
       super._();

  factory _$MatchModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchModelImplFromJson(json);

  @override
  final String id;
  @override
  @TimestampConverter()
  final DateTime date;
  @override
  final String time;
  @override
  final String opponent;
  @override
  final bool isHome;
  @override
  final String team;
  @override
  @JsonKey()
  final MatchStatus status;
  final List<String> _presentPlayerIds;
  @override
  @JsonKey()
  List<String> get presentPlayerIds {
    if (_presentPlayerIds is EqualUnmodifiableListView)
      return _presentPlayerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_presentPlayerIds);
  }

  @override
  @TimestampConverter()
  final DateTime? votingOpensAt;
  @override
  @TimestampConverter()
  final DateTime? votingClosesAt;
  @override
  @JsonKey()
  final PointsScale pointsScale;
  @override
  @JsonKey()
  final bool allowSelfVote;

  /// Chemin de l'asset local choisi dans le formulaire de match (voir
  /// core/config/team_logos_catalog.dart) — null si aucun logo choisi,
  /// auquel cas une icône de secours s'affiche à la place.
  @override
  final String? opponentLogoAsset;

  @override
  String toString() {
    return 'MatchModel(id: $id, date: $date, time: $time, opponent: $opponent, isHome: $isHome, team: $team, status: $status, presentPlayerIds: $presentPlayerIds, votingOpensAt: $votingOpensAt, votingClosesAt: $votingClosesAt, pointsScale: $pointsScale, allowSelfVote: $allowSelfVote, opponentLogoAsset: $opponentLogoAsset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.opponent, opponent) ||
                other.opponent == opponent) &&
            (identical(other.isHome, isHome) || other.isHome == isHome) &&
            (identical(other.team, team) || other.team == team) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._presentPlayerIds,
              _presentPlayerIds,
            ) &&
            (identical(other.votingOpensAt, votingOpensAt) ||
                other.votingOpensAt == votingOpensAt) &&
            (identical(other.votingClosesAt, votingClosesAt) ||
                other.votingClosesAt == votingClosesAt) &&
            (identical(other.pointsScale, pointsScale) ||
                other.pointsScale == pointsScale) &&
            (identical(other.allowSelfVote, allowSelfVote) ||
                other.allowSelfVote == allowSelfVote) &&
            (identical(other.opponentLogoAsset, opponentLogoAsset) ||
                other.opponentLogoAsset == opponentLogoAsset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    time,
    opponent,
    isHome,
    team,
    status,
    const DeepCollectionEquality().hash(_presentPlayerIds),
    votingOpensAt,
    votingClosesAt,
    pointsScale,
    allowSelfVote,
    opponentLogoAsset,
  );

  /// Create a copy of MatchModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchModelImplCopyWith<_$MatchModelImpl> get copyWith =>
      __$$MatchModelImplCopyWithImpl<_$MatchModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchModelImplToJson(this);
  }
}

abstract class _MatchModel extends MatchModel {
  const factory _MatchModel({
    required final String id,
    @TimestampConverter() required final DateTime date,
    required final String time,
    required final String opponent,
    required final bool isHome,
    required final String team,
    final MatchStatus status,
    final List<String> presentPlayerIds,
    @TimestampConverter() final DateTime? votingOpensAt,
    @TimestampConverter() final DateTime? votingClosesAt,
    final PointsScale pointsScale,
    final bool allowSelfVote,
    final String? opponentLogoAsset,
  }) = _$MatchModelImpl;
  const _MatchModel._() : super._();

  factory _MatchModel.fromJson(Map<String, dynamic> json) =
      _$MatchModelImpl.fromJson;

  @override
  String get id;
  @override
  @TimestampConverter()
  DateTime get date;
  @override
  String get time;
  @override
  String get opponent;
  @override
  bool get isHome;
  @override
  String get team;
  @override
  MatchStatus get status;
  @override
  List<String> get presentPlayerIds;
  @override
  @TimestampConverter()
  DateTime? get votingOpensAt;
  @override
  @TimestampConverter()
  DateTime? get votingClosesAt;
  @override
  PointsScale get pointsScale;
  @override
  bool get allowSelfVote;

  /// Chemin de l'asset local choisi dans le formulaire de match (voir
  /// core/config/team_logos_catalog.dart) — null si aucun logo choisi,
  /// auquel cas une icône de secours s'affiche à la place.
  @override
  String? get opponentLogoAsset;

  /// Create a copy of MatchModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchModelImplCopyWith<_$MatchModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
