import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';

/// Toutes ces opérations sont limitées aux admins par les règles Firestore
/// (voir firestore/firestore.rules) — pas besoin de Cloud Function ici, ce
/// sont de simples écritures de document.
class MatchesRepository {
  MatchesRepository(this._firestore, this._server);
  final FirebaseFirestore _firestore;
  final ServerClient _server;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

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
  }) async {
    await _matches.add({
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
    });
  }

  Future<void> updateMatch(String matchId, Map<String, dynamic> fields) {
    return _matches.doc(matchId).update(fields);
  }

  /// Ouvre le vote : le serveur prend le relais pour calculer
  /// `votingClosesAt` et notifier les membres — ce repository ne fait que
  /// déclencher la transition d'état.
  Future<void> openVoting(String matchId) {
    return _matches.doc(matchId).update({'status': 'voting_open'});
  }

  /// Fermeture manuelle anticipée par l'admin (en plus de la clôture auto
  /// après le délai configuré, gérée côté serveur).
  Future<void> closeVoting(String matchId) {
    return _matches.doc(matchId).update({'status': 'voting_closed'});
  }

  Future<void> deleteMatch(String matchId) {
    return _matches.doc(matchId).delete();
  }

  /// Recalcule results/summary + rankings_cache + player_stats pour un match
  /// déjà clôturé, sans dépendre du listener du serveur. Sûr à rappeler
  /// plusieurs fois, le calcul serveur est idempotent.
  Future<void> recomputeResults(String matchId) {
    return _server.post('/matches/$matchId/recompute', {});
  }

  /// Reconstruit entièrement rankings_cache et player_stats à partir de tous
  /// les results/summary existants — l'outil de récupération à utiliser
  /// après un pépin sur le cache.
  Future<Map<String, dynamic>> rebuildRankings() {
    return _server.post('/matches/rankings/rebuild', {});
  }
}
