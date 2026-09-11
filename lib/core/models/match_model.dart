import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chc_mvp/core/models/user_model.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

enum MatchStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('voting_open')
  votingOpen,
  @JsonValue('voting_closed')
  votingClosed,
}

@freezed
class PointsScale with _$PointsScale {
  const factory PointsScale({
    @Default(5) int first,
    @Default(3) int second,
    @Default(1) int third,
  }) = _PointsScale;

  factory PointsScale.fromJson(Map<String, dynamic> json) =>
      _$PointsScaleFromJson(json);
}

@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @TimestampConverter() required DateTime date,
    required String time,
    required String opponent,
    required bool isHome,
    required String team,
    @Default(MatchStatus.upcoming) MatchStatus status,
    @Default(<String>[]) List<String> presentPlayerIds,
    @TimestampConverter() DateTime? votingOpensAt,
    @TimestampConverter() DateTime? votingClosesAt,
    @Default(PointsScale()) PointsScale pointsScale,
    @Default(false) bool allowSelfVote,

    /// Chemin de l'asset local choisi dans le formulaire de match (voir
    /// core/config/team_logos_catalog.dart) — null si aucun logo choisi,
    /// auquel cas une icône de secours s'affiche à la place.
    String? opponentLogoAsset,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  const MatchModel._();

  String get label => 'CHC vs $opponent';
}
