// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vote_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VoteModel _$VoteModelFromJson(Map<String, dynamic> json) {
  return _VoteModel.fromJson(json);
}

/// @nodoc
mixin _$VoteModel {
  String get voterUid => throw _privateConstructorUsedError;
  String get firstPlaceUid => throw _privateConstructorUsedError;
  String get secondPlaceUid => throw _privateConstructorUsedError;
  String get thirdPlaceUid => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get votedAt => throw _privateConstructorUsedError;

  /// Serializes this VoteModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteModelCopyWith<VoteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteModelCopyWith<$Res> {
  factory $VoteModelCopyWith(VoteModel value, $Res Function(VoteModel) then) =
      _$VoteModelCopyWithImpl<$Res, VoteModel>;
  @useResult
  $Res call({
    String voterUid,
    String firstPlaceUid,
    String secondPlaceUid,
    String thirdPlaceUid,
    @TimestampConverter() DateTime? votedAt,
  });
}

/// @nodoc
class _$VoteModelCopyWithImpl<$Res, $Val extends VoteModel>
    implements $VoteModelCopyWith<$Res> {
  _$VoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voterUid = null,
    Object? firstPlaceUid = null,
    Object? secondPlaceUid = null,
    Object? thirdPlaceUid = null,
    Object? votedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            voterUid: null == voterUid
                ? _value.voterUid
                : voterUid // ignore: cast_nullable_to_non_nullable
                      as String,
            firstPlaceUid: null == firstPlaceUid
                ? _value.firstPlaceUid
                : firstPlaceUid // ignore: cast_nullable_to_non_nullable
                      as String,
            secondPlaceUid: null == secondPlaceUid
                ? _value.secondPlaceUid
                : secondPlaceUid // ignore: cast_nullable_to_non_nullable
                      as String,
            thirdPlaceUid: null == thirdPlaceUid
                ? _value.thirdPlaceUid
                : thirdPlaceUid // ignore: cast_nullable_to_non_nullable
                      as String,
            votedAt: freezed == votedAt
                ? _value.votedAt
                : votedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VoteModelImplCopyWith<$Res>
    implements $VoteModelCopyWith<$Res> {
  factory _$$VoteModelImplCopyWith(
    _$VoteModelImpl value,
    $Res Function(_$VoteModelImpl) then,
  ) = __$$VoteModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String voterUid,
    String firstPlaceUid,
    String secondPlaceUid,
    String thirdPlaceUid,
    @TimestampConverter() DateTime? votedAt,
  });
}

/// @nodoc
class __$$VoteModelImplCopyWithImpl<$Res>
    extends _$VoteModelCopyWithImpl<$Res, _$VoteModelImpl>
    implements _$$VoteModelImplCopyWith<$Res> {
  __$$VoteModelImplCopyWithImpl(
    _$VoteModelImpl _value,
    $Res Function(_$VoteModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voterUid = null,
    Object? firstPlaceUid = null,
    Object? secondPlaceUid = null,
    Object? thirdPlaceUid = null,
    Object? votedAt = freezed,
  }) {
    return _then(
      _$VoteModelImpl(
        voterUid: null == voterUid
            ? _value.voterUid
            : voterUid // ignore: cast_nullable_to_non_nullable
                  as String,
        firstPlaceUid: null == firstPlaceUid
            ? _value.firstPlaceUid
            : firstPlaceUid // ignore: cast_nullable_to_non_nullable
                  as String,
        secondPlaceUid: null == secondPlaceUid
            ? _value.secondPlaceUid
            : secondPlaceUid // ignore: cast_nullable_to_non_nullable
                  as String,
        thirdPlaceUid: null == thirdPlaceUid
            ? _value.thirdPlaceUid
            : thirdPlaceUid // ignore: cast_nullable_to_non_nullable
                  as String,
        votedAt: freezed == votedAt
            ? _value.votedAt
            : votedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteModelImpl implements _VoteModel {
  const _$VoteModelImpl({
    required this.voterUid,
    required this.firstPlaceUid,
    required this.secondPlaceUid,
    required this.thirdPlaceUid,
    @TimestampConverter() this.votedAt,
  });

  factory _$VoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteModelImplFromJson(json);

  @override
  final String voterUid;
  @override
  final String firstPlaceUid;
  @override
  final String secondPlaceUid;
  @override
  final String thirdPlaceUid;
  @override
  @TimestampConverter()
  final DateTime? votedAt;

  @override
  String toString() {
    return 'VoteModel(voterUid: $voterUid, firstPlaceUid: $firstPlaceUid, secondPlaceUid: $secondPlaceUid, thirdPlaceUid: $thirdPlaceUid, votedAt: $votedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteModelImpl &&
            (identical(other.voterUid, voterUid) ||
                other.voterUid == voterUid) &&
            (identical(other.firstPlaceUid, firstPlaceUid) ||
                other.firstPlaceUid == firstPlaceUid) &&
            (identical(other.secondPlaceUid, secondPlaceUid) ||
                other.secondPlaceUid == secondPlaceUid) &&
            (identical(other.thirdPlaceUid, thirdPlaceUid) ||
                other.thirdPlaceUid == thirdPlaceUid) &&
            (identical(other.votedAt, votedAt) || other.votedAt == votedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    voterUid,
    firstPlaceUid,
    secondPlaceUid,
    thirdPlaceUid,
    votedAt,
  );

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteModelImplCopyWith<_$VoteModelImpl> get copyWith =>
      __$$VoteModelImplCopyWithImpl<_$VoteModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteModelImplToJson(this);
  }
}

abstract class _VoteModel implements VoteModel {
  const factory _VoteModel({
    required final String voterUid,
    required final String firstPlaceUid,
    required final String secondPlaceUid,
    required final String thirdPlaceUid,
    @TimestampConverter() final DateTime? votedAt,
  }) = _$VoteModelImpl;

  factory _VoteModel.fromJson(Map<String, dynamic> json) =
      _$VoteModelImpl.fromJson;

  @override
  String get voterUid;
  @override
  String get firstPlaceUid;
  @override
  String get secondPlaceUid;
  @override
  String get thirdPlaceUid;
  @override
  @TimestampConverter()
  DateTime? get votedAt;

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteModelImplCopyWith<_$VoteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
