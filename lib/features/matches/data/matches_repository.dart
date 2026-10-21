import 'package:chc_mvp/core/models/match_reference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/player_match_stats_model.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';

/// Les écritures directes sont réservées aux admins par les règles Firestore.
/// La suppression et les recalculs passent par le serveur pour nettoyer aussi
/// les sous-collections et les classements.
class MatchesRepository {
  MatchesRepository(this._firestore, this._server);
  final FirebaseFirestore _firestore;
  final ServerClient _server;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  DocumentReference<Map<String, dynamic>> _match(String id) =>
      _firestore.collection(matchCollection(id)).doc(id);

  Stream<List<MatchModel>> watchTestMatches() => _firestore
      .collection('test_matches')
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map(
              (d) => MatchModel.fromJson(
                sanitizeFirestoreJson({...d.data(), 'id': d.id}),
              ),
            )
            .toList(),
      );

  Future<void> saveTestVote(
    String matchId, {
    required String voterUid,
    required String firstPlaceUid,
    required String secondPlaceUid,
    required String thirdPlaceUid,
  }) => _server.post('/matches/$matchId/test-vote', {
    'voterUid': voterUid,
    'firstPlaceUid': firstPlaceUid,
    'secondPlaceUid': secondPlaceUid,
    'thirdPlaceUid': thirdPlaceUid,
  });

  Stream<List<MatchModel>> watchMatches({String? team}) {
    Query<Map<String, dynamic>> query = _matches.orderBy(
      'date',
      descending: true,
    );
    if (team != null) query = query.where('team', isEqualTo: team);
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => MatchModel.fromJson(
              sanitizeFirestoreJson({...d.data(), 'id': d.id}),
            ),
          )
          .toList(),
    );
  }

  Future<void> createMatch({
    required DateTime date,
    required String time,
    required String opponent,
    required bool isHome,
    required String team,
    required List<String> presentPlayerIds,
    required PointsScale pointsScale,
    required bool allowSelfVote,
    String? opponentLogoAsset,
    String? opponentId,
    bool isTest = false,
  }) async {
    final target = isTest
        ? _firestore.collection('test_matches').doc('test:${_matches.doc().id}')
        : _matches.doc();
    await target.set({
      'date': Timestamp.fromDate(date),
      'time': time,
      'opponent': opponent,
      'isHome': isHome,
      'team': team,
      'status': 'upcoming',
      'presentPlayerIds': presentPlayerIds,
      'votingOpensAt': null,
      'votingClosesAt': null,
      'reminderSentAt': null,
      'pointsScale': pointsScale.toJson(),
      'allowSelfVote': allowSelfVote,
      'opponentLogoAsset': opponentLogoAsset,
      if (opponentId != null) 'opponentId': opponentId,
    });
  }

  Future<void> updateMatch(String matchId, Map<String, dynamic> fields) {
    return _match(matchId).update(fields);
  }

  /// Ouvre le vote : le serveur prend le relais pour calculer
  /// `votingClosesAt` et notifier les membres - ce repository ne fait que
  /// déclencher la transition d'état.
  Future<void> openVoting(String matchId) {
    return _match(matchId).update({
      'status': 'voting_open',
      'votingOpensAt': null,
      'votingClosesAt': null,
      'reminderSentAt': null,
    });
  }

  /// Fermeture manuelle anticipée par l'admin (en plus de la clôture auto
  /// après le délai configuré, gérée côté serveur).
  Future<void> closeVoting(String matchId) {
    return _match(matchId).update({'status': 'voting_closed'});
  }

  /// Conserve les bulletins et retire les anciens totaux jusqu'à la clôture manuelle.
  Future<void> reopenVoting(String matchId) =>
      _server.post('/matches/$matchId/reopen', {});

  Future<void> deleteMatch(String matchId) {
    return _server.delete('/matches/$matchId');
  }

  /// Recalcule results/summary + rankings_cache + player_stats pour un match
  /// déjà clôturé, sans dépendre du listener du serveur. Sûr à rappeler
  /// plusieurs fois, le calcul serveur est idempotent.
  Future<void> recomputeResults(String matchId) {
    return _server.post('/matches/$matchId/recompute', {});
  }

  /// Reconstruit entièrement rankings_cache et player_stats à partir de tous
  /// les votes des matchs clôturés existants, en nettoyant les matchs supprimés.
  /// après un pépin sur le cache.
  Future<Map<String, dynamic>> rebuildRankings() {
    return _server.post('/matches/rankings/rebuild', {});
  }

  // ─── Stats individuelles par match ───────────────────────────────────

  /// Met à jour le score global du match.
  Future<void> updateMatchScore(
    String matchId, {
    required int scoreHome,
    required int scoreAway,
  }) {
    return _match(
      matchId,
    ).update({'scoreHome': scoreHome, 'scoreAway': scoreAway});
  }

  /// Stream des stats individuelles d'un match.
  Stream<List<PlayerMatchStats>> watchPlayerMatchStats(String matchId) {
    return _match(matchId)
        .collection('playerStats')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    PlayerMatchStats.fromJson({...d.data(), 'playerId': d.id}),
              )
              .toList(),
        );
  }

  /// Sauvegarde les stats d'un joueur pour un match (upsert).
  Future<void> savePlayerMatchStats(
    String matchId,
    String playerId,
    PlayerMatchStats stats,
  ) {
    final data = stats.toJson()..remove('playerId');
    return _match(matchId)
        .collection('playerStats')
        .doc(playerId)
        .set(data, SetOptions(merge: true));
  }

  /// Sauvegarde les stats de tous les joueurs en batch (une écriture atomique).
  Future<void> saveAllPlayerMatchStats(
    String matchId,
    List<PlayerMatchStats> statsList,
  ) async {
    final batch = _firestore.batch();
    final col = _match(matchId).collection('playerStats');
    for (final stats in statsList) {
      final data = stats.toJson()..remove('playerId');
      batch.set(col.doc(stats.playerId), data, SetOptions(merge: true));
    }
    await batch.commit();
    final match = await _match(matchId).get();
    if (match.data()?['status'] == 'voting_closed') {
      await recomputeResults(matchId);
    }
  }
}
