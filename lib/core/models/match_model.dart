import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chc_mvp/core/models/user_model.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

enum MatchType { championship, friendly, tournament, playoff }

extension MatchTypeLabel on MatchType {
  String get label => switch (this) {
    MatchType.championship => 'Championnat',
    MatchType.friendly => 'Amical',
    MatchType.tournament => 'Tournoi',
    MatchType.playoff => 'Playoff',
  };
}

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

    /// ID du document dans la collection `opponents`.
    String? opponentId,
    String? eventName,
    String? city,
    int? matchDay,
    int? matchNumber,
    String? reviewCreatedBy,
    required bool isHome,
    required String team,
    @Default(MatchStatus.upcoming) MatchStatus status,
    @Default(MatchType.championship) MatchType matchType,
    @Default(<String>[]) List<String> presentPlayerIds,
    @TimestampConverter() DateTime? votingOpensAt,
    @TimestampConverter() DateTime? votingClosesAt,
    @Default(false) bool manualCloseRequired,
    @Default(PointsScale()) PointsScale pointsScale,
    @Default(false) bool allowSelfVote,

    /// Chemin de l'asset local choisi dans le formulaire de match (voir
    /// core/config/team_logos_catalog.dart) - null si aucun logo choisi,
    /// auquel cas une icône de secours s'affiche à la place.
    String? opponentLogoAsset,

    /// Score du match - saisi par l'admin après le match.
    int? scoreHome,
    int? scoreAway,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final civilDate = json['civilDate'];
    // A calendar day is not a timezone-dependent instant. Older documents
    // retain the previous timestamp conversion until explicitly edited.
    return _$MatchModelFromJson({
      ...json,
      if (civilDate is String &&
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(civilDate))
        'date': '${civilDate}T12:00:00',
    });
  }

  const MatchModel._();

  /// Les matchs de test ont un identifiant réservé et une collection séparée.
  bool get isTest => id.startsWith('test:');

  bool get isFriendly => matchType == MatchType.friendly;
  bool get isExhibition => isFriendly || matchType == MatchType.tournament;
  bool get countsForStats => !isTest && !isExhibition;

  String get competitionLabel {
    if (isExhibition && (eventName?.trim().isNotEmpty ?? false)) {
      return eventName!.trim();
    }
    if (matchType == MatchType.championship &&
        matchDay != null &&
        matchNumber != null) {
      return 'J$matchDay - M$matchNumber';
    }
    return matchType.label;
  }

  String get label => 'CHC vs $opponent';

  /// Ex: "3 - 2" - null si le score n'a pas été saisi.
  String? get scoreLabel =>
      scoreHome != null && scoreAway != null ? '$scoreHome - $scoreAway' : null;
}
