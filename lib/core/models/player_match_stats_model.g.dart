// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_match_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerMatchStatsImpl _$$PlayerMatchStatsImplFromJson(
  Map<String, dynamic> json,
) => _$PlayerMatchStatsImpl(
  playerId: json['playerId'] as String,
  goals: (json['goals'] as num?)?.toInt() ?? 0,
  assists: (json['assists'] as num?)?.toInt() ?? 0,
  greenCards: (json['greenCards'] as num?)?.toInt() ?? 0,
  yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
  redCards: (json['redCards'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$PlayerMatchStatsImplToJson(
  _$PlayerMatchStatsImpl instance,
) => <String, dynamic>{
  'playerId': instance.playerId,
  'goals': instance.goals,
  'assists': instance.assists,
  'greenCards': instance.greenCards,
  'yellowCards': instance.yellowCards,
  'redCards': instance.redCards,
};
