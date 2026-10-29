import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';

/// Scores du club, indépendamment de la clôture des votes MVP.
class ClubRecord {
  ClubRecord.fromMatches(Iterable<MatchModel> source, {OpponentModel? opponent})
    : matches = source.where((match) {
        if (match.isTest ||
            match.status == MatchStatus.upcoming ||
            match.scoreHome == null ||
            match.scoreAway == null ||
            match.scoreHome! < 0 ||
            match.scoreAway! < 0) {
          return false;
        }
        if (opponent == null) return true;
        if (match.opponentId?.isNotEmpty == true && opponent.id.isNotEmpty) {
          return match.opponentId == opponent.id;
        }
        // Anciens matchs enregistrés avant la création du catalogue adverse.
        return match.opponent.trim().toLowerCase() ==
            opponent.name.trim().toLowerCase();
      }).toList()..sort((a, b) => b.date.compareTo(a.date));

  final List<MatchModel> matches;
  int get played => matches.length;
  int get wins => matches.where((m) => m.scoreHome! > m.scoreAway!).length;
  int get draws => matches.where((m) => m.scoreHome == m.scoreAway).length;
  int get losses => played - wins - draws;
  // Dans les données existantes, scoreHome est toujours CHC, même à l'extérieur.
  int get goalsFor => matches.fold(0, (sum, m) => sum + m.scoreHome!);
  int get goalsAgainst => matches.fold(0, (sum, m) => sum + m.scoreAway!);
}
