// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteModelImpl _$$VoteModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteModelImpl(
      voterUid: json['voterUid'] as String,
      firstPlaceUid: json['firstPlaceUid'] as String,
      secondPlaceUid: json['secondPlaceUid'] as String,
      thirdPlaceUid: json['thirdPlaceUid'] as String,
      votedAt: const TimestampConverter().fromJson(json['votedAt']),
    );

Map<String, dynamic> _$$VoteModelImplToJson(_$VoteModelImpl instance) =>
    <String, dynamic>{
      'voterUid': instance.voterUid,
      'firstPlaceUid': instance.firstPlaceUid,
      'secondPlaceUid': instance.secondPlaceUid,
      'thirdPlaceUid': instance.thirdPlaceUid,
      'votedAt': const TimestampConverter().toJson(instance.votedAt),
    };
