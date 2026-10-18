// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opponent_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OpponentModel _$OpponentModelFromJson(Map<String, dynamic> json) {
  return _OpponentModel.fromJson(json);
}

/// @nodoc
mixin _$OpponentModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Chemin asset local du logo (ex: 'assets/team_logos/nantes.png').
  String? get logoAsset => throw _privateConstructorUsedError;

  /// Serializes this OpponentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpponentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpponentModelCopyWith<OpponentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpponentModelCopyWith<$Res> {
  factory $OpponentModelCopyWith(
    OpponentModel value,
    $Res Function(OpponentModel) then,
  ) = _$OpponentModelCopyWithImpl<$Res, OpponentModel>;
  @useResult
  $Res call({String id, String name, String? logoAsset});
}

/// @nodoc
class _$OpponentModelCopyWithImpl<$Res, $Val extends OpponentModel>
    implements $OpponentModelCopyWith<$Res> {
  _$OpponentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpponentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? logoAsset = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            logoAsset: freezed == logoAsset
                ? _value.logoAsset
                : logoAsset // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OpponentModelImplCopyWith<$Res>
    implements $OpponentModelCopyWith<$Res> {
  factory _$$OpponentModelImplCopyWith(
    _$OpponentModelImpl value,
    $Res Function(_$OpponentModelImpl) then,
  ) = __$$OpponentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? logoAsset});
}

/// @nodoc
class __$$OpponentModelImplCopyWithImpl<$Res>
    extends _$OpponentModelCopyWithImpl<$Res, _$OpponentModelImpl>
    implements _$$OpponentModelImplCopyWith<$Res> {
  __$$OpponentModelImplCopyWithImpl(
    _$OpponentModelImpl _value,
    $Res Function(_$OpponentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpponentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? logoAsset = freezed,
  }) {
    return _then(
      _$OpponentModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        logoAsset: freezed == logoAsset
            ? _value.logoAsset
            : logoAsset // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpponentModelImpl implements _OpponentModel {
  const _$OpponentModelImpl({
    required this.id,
    required this.name,
    this.logoAsset,
  });

  factory _$OpponentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpponentModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  /// Chemin asset local du logo (ex: 'assets/team_logos/nantes.png').
  @override
  final String? logoAsset;

  @override
  String toString() {
    return 'OpponentModel(id: $id, name: $name, logoAsset: $logoAsset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpponentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.logoAsset, logoAsset) ||
                other.logoAsset == logoAsset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, logoAsset);

  /// Create a copy of OpponentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpponentModelImplCopyWith<_$OpponentModelImpl> get copyWith =>
      __$$OpponentModelImplCopyWithImpl<_$OpponentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpponentModelImplToJson(this);
  }
}

abstract class _OpponentModel implements OpponentModel {
  const factory _OpponentModel({
    required final String id,
    required final String name,
    final String? logoAsset,
  }) = _$OpponentModelImpl;

  factory _OpponentModel.fromJson(Map<String, dynamic> json) =
      _$OpponentModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Chemin asset local du logo (ex: 'assets/team_logos/nantes.png').
  @override
  String? get logoAsset;

  /// Create a copy of OpponentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpponentModelImplCopyWith<_$OpponentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
