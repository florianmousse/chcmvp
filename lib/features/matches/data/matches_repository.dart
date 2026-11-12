import 'package:chc_mvp/core/services/paged_firestore.dart';
import 'package:chc_mvp/features/matches/domain/match_list.dart';
import 'package:chc_mvp/core/services/scoped_firestore.dart';
import 'package:chc_mvp/core/services/audited_data.dart';
import 'package:chc_mvp/core/models/match_reference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/player_match_stats_model.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';

/// Les écritures passent par le serveur pour contrôler les droits et journaliser.
/// La suppression et les recalculs passent par le serveur pour nettoyer aussi
/// les sous-collections et les classements.
class MatchesRepository {
  MatchesRepository(
    FirebaseFirestore firestore,
    this._server, {
    this.reviewerUid,
    String? reviewSpaceUid,
  }) : _firestore = ScopedFirestore(firestore, reviewSpaceUid);
  final String? reviewerUid;
  final ScopedFirestore _firestore;
  final ServerClient _server;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  DocumentReference<Map<String, dynamic>> _match(String id) =>
      _firestore.collection(matchCollection(id)).doc(id);

  Stream<List<MatchModel>> watchTestMatches() {
    Query<Map<String, dynamic>> query = _firestore.collection('test_matches');
    if (reviewerUid != null) {
      query = query.where('reviewCreatedBy', isEqualTo: reviewerUid);
    }
    return watchPagedQuery(query).map(
      (snap) =>
          snap
              .map(
                (d) => MatchModel.fromJson(
                  sanitizeFirestoreJson({...d.data(), 'id': d.id}),
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

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

  /// Un seul document lu par saison, en sautant directement à la précédente.
  Future<List<int>> loadMatchSeasons() async {
    final years = <int>[];
    DateTime? before;
    while (true) {
      Query<Map<String, dynamic>> query = _matches;
      if (before != null) {
        query = query.where('date', isLessThan: Timestamp.fromDate(before));
      }
      final snapshot = await query
          .orderBy('date', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 15));
      if (snapshot.docs.isEmpty) return years;
      final date = snapshot.docs.single.data()['date'];
      if (date is! Timestamp) {
        throw const FormatException('Date de match invalide.');
      }
      final instant = date.toDate().toUtc();
      final year = instant.isBefore(matchSeasonStart(instant.year))
          ? instant.year - 1
          : instant.year;
      years.add(year);
      before = matchSeasonStart(year);
    }
  }

  /// Ne charge que les matchs de la saison demandée, dans le même espace.
  Stream<List<MatchModel>> watchSeasonMatches(int startYear) => _matches
      .where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(matchSeasonStart(startYear)),
      )
      .where(
        'date',
        isLessThan: Timestamp.fromDate(matchSeasonStart(startYear + 1)),
      )
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => MatchModel.fromJson(
                sanitizeFirestoreJson({...doc.data(), 'id': doc.id}),
              ),
            )
            .toList(),
      );

  Stream<List<MatchModel>> watchMatches({String? team}) {
    Query<Map<String, dynamic>> query = _matches;
    if (team != null) query = query.where('team', isEqualTo: team);
    return watchPagedQuery(query).map(
      (snap) =>
          snap
              .map(
                (d) => MatchModel.fromJson(
                  sanitizeFirestoreJson({...d.data(), 'id': d.id}),
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)),
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
    MatchType matchType = MatchType.championship,
    String? eventName,
    String? city,
    int? matchDay,
    int? matchNumber,
  }) async {
    final target = isTest
        ? _firestore.collection('test_matches').doc('test:${_matches.doc().id}')
        : _matches.doc();
    await writeAuditedData(_server, target.path, 'create', {
      'date': Timestamp.fromDate(date),
      'civilDate':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'time': time,
      'opponent': opponent,
      'isHome': isHome,
      'team': team,
      'status': 'upcoming',
      'matchType': matchType.name,
      'eventName': eventName,
      'city': city,
      'matchDay': matchDay,
      'matchNumber': matchNumber,
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
    return writeAuditedData(_server, _match(matchId).path, 'update', fields);
  }

  /// Ouvre le vote : le serveur prend le relais pour calculer
  /// `votingClosesAt` et notifier les membres - ce repository ne fait que
  /// demander la transition d'état au serveur.
  Future<void> openVoting(String matchId) {
    return updateMatch(matchId, {
      'status': 'voting_open',
      'votingOpensAt': null,
      'votingClosesAt': null,
      'reminderSentAt': null,
    });
  }

  /// Fermeture manuelle anticipée par l'admin (en plus de la clôture auto
  /// après le délai configuré, gérée côté serveur).
  Future<void> closeVoting(String matchId) {
    return updateMatch(matchId, {'status': 'voting_closed'});
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
    return updateMatch(matchId, {
      'scoreHome': scoreHome,
      'scoreAway': scoreAway,
    });
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
    return writeAuditedData(
      _server,
      '${_match(matchId).path}/playerStats/$playerId',
      'merge',
      data,
    );
  }

  /// Sauvegarde les stats de tous les joueurs en batch (une écriture atomique).
  Future<void> saveAllPlayerMatchStats(
    String matchId,
    List<PlayerMatchStats> statsList,
  ) async {
    await _server.post('/data/stats', {
      'matchId': matchId,
      'stats': statsList.map((s) => s.toJson()).toList(),
    });
    final match = await _match(matchId).get();
    if (match.data()?['status'] == 'voting_closed') {
      await recomputeResults(matchId);
    }
  }
}
