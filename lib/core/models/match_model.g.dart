// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointsScaleImpl _$$PointsScaleImplFromJson(Map<String, dynamic> json) =>
    _$PointsScaleImpl(
      first: (json['first'] as num?)?.toInt() ?? 5,
      second: (json['second'] as num?)?.toInt() ?? 3,
      third: (json['third'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$PointsScaleImplToJson(_$PointsScaleImpl instance) =>
    <String, dynamic>{
      'first': instance.first,
      'second': instance.second,
      'third': instance.third,
    };

_$MatchModelImpl _$$MatchModelImplFromJson(Map<String, dynamic> json) =>
    _$MatchModelImpl(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      opponent: json['opponent'] as String,
      isHome: json['isHome'] as bool,
      team: json['team'] as String,
      status:
          $enumDecodeNullable(_$MatchStatusEnumMap, json['status']) ??
          MatchStatus.upcoming,
      presentPlayerIds:
          (json['presentPlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      votingOpensAt: const TimestampConverter().fromJson(json['votingOpensAt']),
      votingClosesAt: const TimestampConverter().fromJson(
        json['votingClosesAt'],
      ),
      pointsScale: json['pointsScale'] == null
          ? const PointsScale()
          : PointsScale.fromJson(json['pointsScale'] as Map<String, dynamic>),
      allowSelfVote: json['allowSelfVote'] as bool? ?? false,
      opponentLogoAsset: json['opponentLogoAsset'] as String?,
    );

Map<String, dynamic> _$$MatchModelImplToJson(
  _$MatchModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'time': instance.time,
  'opponent': instance.opponent,
  'isHome': instance.isHome,
  'team': instance.team,
  'status': _$MatchStatusEnumMap[instance.status]!,
  'presentPlayerIds': instance.presentPlayerIds,
  'votingOpensAt': const TimestampConverter().toJson(instance.votingOpensAt),
  'votingClosesAt': const TimestampConverter().toJson(instance.votingClosesAt),
  'pointsScale': instance.pointsScale,
  'allowSelfVote': instance.allowSelfVote,
  'opponentLogoAsset': instance.opponentLogoAsset,
};

const _$MatchStatusEnumMap = {
  MatchStatus.upcoming: 'upcoming',
  MatchStatus.votingOpen: 'voting_open',
  MatchStatus.votingClosed: 'voting_closed',
};
