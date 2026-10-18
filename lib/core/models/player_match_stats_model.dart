import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_match_stats_model.freezed.dart';
part 'player_match_stats_model.g.dart';

/// Stats individuelles d'un joueur sur un match donné.
/// Stocké dans Firestore : matches/{matchId}/playerStats/{playerId}
@freezed
class PlayerMatchStats with _$PlayerMatchStats {
  const factory PlayerMatchStats({
    required String playerId,
    @Default(0) int goals,
    @Default(0) int assists,
    @Default(0) int greenCards,
    @Default(0) int yellowCards,
    @Default(0) int redCards,
  }) = _PlayerMatchStats;

  factory PlayerMatchStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerMatchStatsFromJson(json);
}
