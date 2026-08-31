import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_repository.freezed.dart';

@freezed
class RankingEntry with _$RankingEntry {
  const factory RankingEntry({
    required String uid,
    @Default(0) int points,
    @Default(0) int firstCount,
    @Default(0) int secondCount,
    @Default(0) int thirdCount,
  }) = _RankingEntry;
}

@freezed
class PlayerStats with _$PlayerStats {
  const factory PlayerStats({
    @Default(0) int matchesPlayed,
    @Default(0) int totalPoints,
    @Default(0) int votesReceived,
    @Default(0) int firstCount,
    @Default(0) int secondCount,
    @Default(0) int thirdCount,
    @Default(0) int distinctVoters,
  }) = _PlayerStats;

  const PlayerStats._();

  double get averagePointsPerMatch =>
      matchesPlayed == 0 ? 0 : totalPoints / matchesPlayed;
}

class PlayerHistoryPoint {
  PlayerHistoryPoint({
    required this.matchDate,
    required this.points,
    this.rank,
    this.distinctVotersThisMatch,
    this.presentCount,
  });
  final DateTime matchDate;
  final int points;
  final int? rank;

  /// Nombre de coéquipiers distincts ayant voté pour ce joueur lors de ce
  /// match — écrit par le serveur, null si le serveur n'a pas encore été
  /// mis à jour.
  final int? distinctVotersThisMatch;

  /// Nombre de joueurs présents lors de ce match — permet de calculer le
  /// ratio pour le badge « plébiscité ».
  final int? presentCount;
}

/// scope : "general", une année ("2026"), ou un mois ("2026-08") — construit
/// par le sélecteur des écrans, correspond aux clés écrites par
/// `computeMatchResults` côté Cloud Function.
class RankingRepository {
  RankingRepository(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<List<RankingEntry>> watchRanking(String scope) {
    return _firestore.collection('rankings_cache').doc(scope).snapshots().map((
      doc,
    ) {
      final entries = (doc.data()?['entries'] as Map<String, dynamic>?) ?? {};
      final list = entries.entries.map((e) {
        final v = e.value as Map<String, dynamic>;
        return RankingEntry(
          uid: e.key,
          points: (v['points'] ?? 0) as int,
          firstCount: (v['firstCount'] ?? 0) as int,
          secondCount: (v['secondCount'] ?? 0) as int,
          thirdCount: (v['thirdCount'] ?? 0) as int,
        );
      }).toList();
      list.sort((a, b) {
        if (b.points != a.points) return b.points.compareTo(a.points);
        if (b.firstCount != a.firstCount)
          return b.firstCount.compareTo(a.firstCount);
        return b.secondCount.compareTo(a.secondCount);
      });
      return list;
    });
  }

  Stream<PlayerStats> watchPlayerStats(String uid) {
    return _firestore.collection('player_stats').doc(uid).snapshots().map((
      doc,
    ) {
      final d = doc.data();
      if (d == null) return const PlayerStats();
      return PlayerStats(
        matchesPlayed: (d['matchesPlayed'] ?? 0) as int,
        totalPoints: (d['totalPoints'] ?? 0) as int,
        votesReceived: (d['votesReceived'] ?? 0) as int,
        firstCount: (d['firstCount'] ?? 0) as int,
        secondCount: (d['secondCount'] ?? 0) as int,
        thirdCount: (d['thirdCount'] ?? 0) as int,
        distinctVoters: (d['distinctVoters'] ?? 0) as int,
      );
    });
  }

  Stream<List<PlayerHistoryPoint>> watchPlayerHistory(String uid) {
    return _firestore
        .collection('player_stats')
        .doc(uid)
        .collection('history')
        .orderBy('matchDate')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return PlayerHistoryPoint(
              matchDate: (data['matchDate'] as Timestamp).toDate(),
              points: (data['points'] ?? 0) as int,
              rank: data['rank'] as int?,
              distinctVotersThisMatch:
                  data['distinctVotersThisMatch'] as int?,
              presentCount: data['presentCount'] as int?,
            );
          }).toList(),
        );
  }

  /// Stats agrégées de TOUS les joueurs — utilisé par l'écran d'accueil pour
  /// calculer le joueur le plus plébiscité, la révélation, etc. sans charger
  /// un provider par joueur.
  Stream<Map<String, PlayerStats>> watchAllPlayerStats() {
    return _firestore.collection('player_stats').snapshots().map((snap) {
      final map = <String, PlayerStats>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        map[doc.id] = PlayerStats(
          matchesPlayed: (d['matchesPlayed'] ?? 0) as int,
          totalPoints: (d['totalPoints'] ?? 0) as int,
          votesReceived: (d['votesReceived'] ?? 0) as int,
          firstCount: (d['firstCount'] ?? 0) as int,
          secondCount: (d['secondCount'] ?? 0) as int,
          thirdCount: (d['thirdCount'] ?? 0) as int,
          distinctVoters: (d['distinctVoters'] ?? 0) as int,
        );
      }
      return map;
    });
  }

  /// Historiques de TOUS les joueurs — utilisé par l'écran d'accueil pour
  /// les séries top 3, la révélation, les stats insolites, etc.
  Stream<Map<String, List<PlayerHistoryPoint>>> watchAllPlayerHistories() {
    return _firestore.collection('player_stats').snapshots().asyncMap((
      snap,
    ) async {
      final map = <String, List<PlayerHistoryPoint>>{};
      for (final doc in snap.docs) {
        final histSnap = await doc.reference
            .collection('history')
            .orderBy('matchDate')
            .get();
        map[doc.id] = histSnap.docs.map((d) {
          final data = d.data();
          return PlayerHistoryPoint(
            matchDate: (data['matchDate'] as Timestamp).toDate(),
            points: (data['points'] ?? 0) as int,
            rank: data['rank'] as int?,
            distinctVotersThisMatch: data['distinctVotersThisMatch'] as int?,
            presentCount: data['presentCount'] as int?,
          );
        }).toList();
      }
      return map;
    });
  }

  /// Tous les scopes (mois "YYYY-MM" et années "YYYY") ayant au moins une
  /// entrée — sert à savoir vers quelle période sauter quand l'utilisateur
  /// navigue vers un mois/année vide plutôt que d'afficher une liste vide.
  Stream<List<String>> watchAvailableScopes() {
    return _firestore.collection('rankings_cache').snapshots().map((snap) {
      return snap.docs
          .where((d) {
            final entries = d.data()['entries'] as Map<String, dynamic>?;
            return entries != null && entries.isNotEmpty;
          })
          .map((d) => d.id)
          .toList();
    });
  }
}
