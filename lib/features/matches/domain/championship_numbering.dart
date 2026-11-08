import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/utils/season.dart';

/// Suggest numbers without renumbering saved fixtures, including legacy matches.
({int day, int match}) suggestChampionshipNumbers({
  required Iterable<MatchModel> matches,
  required String team,
  required DateTime date,
  bool isTest = false,
}) {
  DateTime calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  final target = calendarDate(date);
  final relevant =
      matches
          .where(
            (m) =>
                m.team == team &&
                m.isTest == isTest &&
                m.matchType == MatchType.championship &&
                seasonId(m.date) == seasonId(date) &&
                !calendarDate(m.date).isAfter(target),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final byDate = <DateTime, List<MatchModel>>{};
  for (final match in relevant) {
    byDate.putIfAbsent(calendarDate(match.date), () => []).add(match);
  }
  // Match numbers continue across all championship days of this season.
  var lastMatch = relevant.length;
  for (final match in relevant) {
    if ((match.matchNumber ?? 0) > lastMatch) {
      lastMatch = match.matchNumber!;
    }
  }
  var lastDay = 0;
  for (final entry in byDate.entries) {
    final explicitDays = entry.value.map((m) => m.matchDay).whereType<int>();
    final day = explicitDays.isEmpty
        ? lastDay + 1
        : explicitDays.reduce((a, b) => a > b ? a : b);
    if (entry.key == target) {
      return (day: day, match: lastMatch + 1);
    }
    if (day > lastDay) lastDay = day;
  }
  return (day: lastDay + 1, match: lastMatch + 1);
}
