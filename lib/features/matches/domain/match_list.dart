import 'package:chc_mvp/core/models/match_model.dart';

/// La saison du club commence le 1er septembre à minuit à Paris (UTC+2).
DateTime matchSeasonStart(int year) => DateTime.utc(year, 8, 31, 22);

List<MatchModel> sortMatchList(
  Iterable<MatchModel> matches, {
  MatchStatus? status,
  Set<String> pendingVoteMatchIds = const {},
}) {
  final result = matches
      .where((m) => status == null || m.status == status)
      .toList();
  result.sort((a, b) {
    final aOpen =
        a.status == MatchStatus.votingOpen &&
        pendingVoteMatchIds.contains(a.id);
    final bOpen =
        b.status == MatchStatus.votingOpen &&
        pendingVoteMatchIds.contains(b.id);
    if (aOpen != bOpen) return aOpen ? -1 : 1;
    // Comparer le jour affiché, puis l'heure saisie séparément. Les anciens
    // timestamps peuvent contenir une heure différente pour un même jour.
    final aDay = DateTime.utc(a.date.year, a.date.month, a.date.day);
    final bDay = DateTime.utc(b.date.year, b.date.month, b.date.day);
    final dayOrder = bDay.compareTo(aDay);
    if (dayOrder != 0) return dayOrder;
    final dateOrder = b.time.compareTo(a.time);
    return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
  });
  return result;
}
