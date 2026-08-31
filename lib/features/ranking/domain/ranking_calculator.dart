import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chc_mvp/core/models/match_model.dart';

part 'ranking_calculator.freezed.dart';

/// Entrée : le résumé déjà agrégé d'UN match (voir results/summary dans
/// ARCHITECTURE.md), pas les votes bruts — ceux-ci ne sont jamais exposés
/// côté client pour préserver l'anonymat.
class MatchResultSummary {
  MatchResultSummary({
    required this.matchId,
    required this.matchDate,
    required this.firstPlaceUid,
    required this.secondPlaceUid,
    required this.thirdPlaceUid,
  });

  final String matchId;
  final DateTime matchDate;
  final String firstPlaceUid;
  final String secondPlaceUid;
  final String thirdPlaceUid;
}

@freezed
class PlayerRankingEntry with _$PlayerRankingEntry {
  const factory PlayerRankingEntry({
    required String uid,
    @Default(0) int points,
    @Default(0) int firstCount,
    @Default(0) int secondCount,
    @Default(0) int thirdCount,
  }) = _PlayerRankingEntry;
}

/// Pure Dart, sans dépendance Firebase : peut tourner côté client pour un
/// aperçu instantané ET côté Cloud Function pour le calcul officiel —
/// même code, un seul endroit à faire évoluer si le barème change.
class RankingCalculator {
  static List<PlayerRankingEntry> compute({
    required List<MatchResultSummary> results,
    PointsScale pointsScale = const PointsScale(),
    DateTime? from,
    DateTime? to,
  }) {
    final filtered = results.where((r) {
      if (from != null && r.matchDate.isBefore(from)) return false;
      if (to != null && r.matchDate.isAfter(to)) return false;
      return true;
    });

    final byPlayer = <String, PlayerRankingEntry>{};

    void addPoints(
      String uid,
      int points, {
      int firstDelta = 0,
      int secondDelta = 0,
      int thirdDelta = 0,
    }) {
      final current = byPlayer[uid] ?? PlayerRankingEntry(uid: uid);
      byPlayer[uid] = current.copyWith(
        points: current.points + points,
        firstCount: current.firstCount + firstDelta,
        secondCount: current.secondCount + secondDelta,
        thirdCount: current.thirdCount + thirdDelta,
      );
    }

    for (final r in filtered) {
      addPoints(r.firstPlaceUid, pointsScale.first, firstDelta: 1);
      addPoints(r.secondPlaceUid, pointsScale.second, secondDelta: 1);
      addPoints(r.thirdPlaceUid, pointsScale.third, thirdDelta: 1);
    }

    final list = byPlayer.values.toList()
      ..sort((a, b) {
        // Tri : points desc, puis nb de 1ères places desc, puis nb de 2èmes desc
        // (départage naturel en cas d'égalité de points).
        if (b.points != a.points) return b.points.compareTo(a.points);
        if (b.firstCount != a.firstCount) {
          return b.firstCount.compareTo(a.firstCount);
        }
        return b.secondCount.compareTo(a.secondCount);
      });

    return list;
  }
}
