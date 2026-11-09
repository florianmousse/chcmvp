import 'package:chc_mvp/core/models/match_model.dart';

/// La saison du club commence le 1er septembre à minuit à Paris (UTC+2).
DateTime matchSeasonStart(int year) => DateTime.utc(year, 8, 31, 22);

List<MatchModel> sortMatchList(
  Iterable<MatchModel> matches, {
  MatchStatus? status,
}) {
  final result = matches
      .where((m) => status == null || m.status == status)
      .toList();
  result.sort((a, b) {
    final aOpen = a.status == MatchStatus.votingOpen;
    final bOpen = b.status == MatchStatus.votingOpen;
    if (aOpen != bOpen) return aOpen ? -1 : 1;
    final dateOrder = b.date.compareTo(a.date);
    return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
  });
  return result;
}
