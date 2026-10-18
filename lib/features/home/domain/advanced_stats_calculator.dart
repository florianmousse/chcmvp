import 'dart:math';

import 'package:chc_mvp/features/ranking/data/ranking_repository.dart';

/// Fonctions pures (sans dépendance Firebase) pour calculer les statistiques
/// avancées affichées sur l'écran d'accueil — testables unitairement avec
/// des données fictives.

/// Stats de jeu agrégées d'un joueur — utilisé par [funFact] et les sections
/// d'accueil. Découplé du provider pour rester dans le domaine pur.
class GameStats {
  const GameStats({
    this.goals = 0,
    this.assists = 0,
    this.greenCards = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.matchesPlayed = 0,
  });
  final int goals;
  final int assists;
  final int greenCards;
  final int yellowCards;
  final int redCards;
  final int matchesPlayed;
  int get totalCards => greenCards + yellowCards + redCards;
}

// ---------------------------------------------------------------------------
// Joueur le plus plébiscité
// ---------------------------------------------------------------------------

/// Retourne l'UID du joueur ayant reçu des votes du plus grand nombre de
/// coéquipiers *distincts sur un seul match* — le max de
/// `distinctVotersThisMatch` parmi tous les matchs de la saison. On ne peut
/// pas cumuler les votants distincts sur plusieurs matchs car les mêmes
/// votants reviennent d'un match à l'autre, ce qui donnerait un total
/// supérieur au nombre réel de coéquipiers.
({String uid, int maxDistinct, int? presentCount})? mostPopularPlayer(
  Map<String, List<PlayerHistoryPoint>> allHistories,
) {
  String? bestUid;
  var bestCount = 0;
  int? bestPresent;
  for (final e in allHistories.entries) {
    for (final h in e.value) {
      final dv = h.distinctVotersThisMatch ?? 0;
      if (dv > bestCount) {
        bestCount = dv;
        bestUid = e.key;
        bestPresent = h.presentCount;
      }
    }
  }
  if (bestUid == null || bestCount == 0) return null;
  return (uid: bestUid, maxDistinct: bestCount, presentCount: bestPresent);
}

// ---------------------------------------------------------------------------
// Série top 3
// ---------------------------------------------------------------------------

/// Série actuelle (depuis le dernier match) de matchs consécutifs dans le
/// top 3. La liste doit être triée par date croissante.
int currentTop3Streak(List<PlayerHistoryPoint> history) {
  var streak = 0;
  for (final h in history.reversed) {
    if (h.rank != null && h.rank! <= 3) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

/// Meilleure série de top 3 consécutifs dans toute la saison.
int bestTop3StreakEver(List<PlayerHistoryPoint> history) {
  var best = 0;
  var current = 0;
  for (final h in history) {
    if (h.rank != null && h.rank! <= 3) {
      current++;
      if (current > best) best = current;
    } else {
      current = 0;
    }
  }
  return best;
}

/// Retourne (uid, sérieCourante, meilleureSerié) du joueur ayant la plus
/// longue série *actuelle* de top 3.
({String uid, int current, int best})? bestCurrentStreakPlayer(
  Map<String, List<PlayerHistoryPoint>> allHistories,
) {
  String? bestUid;
  var bestCurrent = 0;
  var bestOfBest = 0;
  for (final e in allHistories.entries) {
    final c = currentTop3Streak(e.value);
    if (c > bestCurrent) {
      bestCurrent = c;
      bestUid = e.key;
      bestOfBest = bestTop3StreakEver(e.value);
    }
  }
  if (bestUid == null || bestCurrent == 0) return null;
  return (uid: bestUid, current: bestCurrent, best: bestOfBest);
}

// ---------------------------------------------------------------------------
// Révélation de la saison
// ---------------------------------------------------------------------------

/// Retourne (uid, pourcentageProgression) du joueur ayant le plus progressé
/// entre ses 5 premiers matchs et la suite — null si personne n'a assez de
/// matchs ou si aucune progression.
({String uid, double progressionPercent})? seasonRevelation(
  Map<String, List<PlayerHistoryPoint>> allHistories,
) {
  String? bestUid;
  var bestProgression = 0.0;

  for (final e in allHistories.entries) {
    final history = e.value;
    if (history.length < 6) continue; // besoin d'au moins 6 matchs

    final first5 = history.take(5).toList();
    final rest = history.skip(5).toList();

    final avgFirst5 = first5.map((h) => h.points).reduce((a, b) => a + b) / 5.0;
    final avgRest =
        rest.map((h) => h.points).reduce((a, b) => a + b) / rest.length;

    if (avgFirst5 <= 0) continue; // pas de division par zéro
    final progression = ((avgRest - avgFirst5) / avgFirst5) * 100;

    if (progression > bestProgression) {
      bestProgression = progression;
      bestUid = e.key;
    }
  }

  if (bestUid == null || bestProgression <= 0) return null;
  return (uid: bestUid, progressionPercent: bestProgression);
}

// ---------------------------------------------------------------------------
// Duel de la semaine
// ---------------------------------------------------------------------------

/// Retourne une paire de joueurs proches au classement, déterminée de
/// manière déterministe par le numéro de semaine ISO. Null si le classement
/// a moins de 2 joueurs.
({String uid1, int pts1, String uid2, int pts2})? weeklyDuel(
  List<RankingEntry> ranking,
  DateTime now,
) {
  if (ranking.length < 2) return null;

  // On ne prend que les paires consécutives (1-2, 2-3, 3-4, ...) pour
  // que le duel reste intéressant (joueurs proches au classement).
  final pairCount = ranking.length - 1;
  final weekNumber = _isoWeekNumber(now);
  final pairIndex = weekNumber % pairCount;

  final a = ranking[pairIndex];
  final b = ranking[pairIndex + 1];
  return (uid1: a.uid, pts1: a.points, uid2: b.uid, pts2: b.points);
}

// ---------------------------------------------------------------------------
// Stat insolite de la semaine
// ---------------------------------------------------------------------------

/// Génère une stat insolite/amusante à partir des données, avec rotation
/// hebdomadaire (change chaque lundi). Retourne un record (emoji, titre,
/// description) ou null si pas assez de données.
({String emoji, String title, String body})? funFact({
  required Map<String, PlayerStats> allStats,
  required Map<String, List<PlayerHistoryPoint>> allHistories,
  required List<RankingEntry> ranking,
  required String Function(String uid) nameOf,
  required DateTime now,
  Map<String, GameStats>? gameStats,
}) {
  final weekNumber = _isoWeekNumber(now);

  // 10 catégories fixes — on en choisit une par numéro de semaine.
  // Même si les données évoluent en cours de semaine, la catégorie
  // sélectionnée ne change pas jusqu'au lundi suivant.
  final category = weekNumber % 10;

  switch (category) {
    // Catégorie 0 : joueur avec beaucoup de votes mais jamais 1er
    case 0:
      for (final e in allStats.entries) {
        if (e.value.votesReceived >= 5 && e.value.firstCount == 0) {
          return (
            emoji: '🧙‍♂️',
            title: 'Le saviez-vous ?',
            body:
                '${nameOf(e.key)} a reçu des votes lors de ${e.value.votesReceived} matchs cette saison, mais n\'a jamais terminé 1er.',
          );
        }
      }
      return (
        emoji: '🤷‍♂️',
        title: 'Pas de stat insolite cette semaine',
        body:
            'Aucun joueur n\'a reçu beaucoup de votes sans jamais finir 1er cette saison.',
      );

    // Catégorie 1 : deux joueurs séparés de 3 points ou moins
    case 1:
      for (var i = 0; i < ranking.length - 1; i++) {
        final diff = ranking[i].points - ranking[i + 1].points;
        if (diff > 0 && diff <= 3) {
          return (
            emoji: '⚡',
            title: 'Course serrée !',
            body:
                '${nameOf(ranking[i].uid)} et ${nameOf(ranking[i + 1].uid)} ne sont séparés que de $diff point${diff > 1 ? 's' : ''} !',
          );
        }
      }
      return (
        emoji: '😴',
        title: 'Pas de stat insolite cette semaine',
        body:
            'Aucun duo de joueurs n\'est séparé de 3 points ou moins au classement cette saison.',
      );

    // Catégorie 2 : joueur avec le plus de 3èmes places
    case 2:
      final maxThird =
          allStats.entries.where((e) => e.value.thirdCount >= 3).toList()
            ..sort((a, b) => b.value.thirdCount.compareTo(a.value.thirdCount));
      if (maxThird.isNotEmpty) {
        final e = maxThird.first;
        return (
          emoji: '🥉',
          title: 'Le fidèle du podium',
          body:
              '${nameOf(e.key)} a terminé 3e pas moins de ${e.value.thirdCount} fois cette saison !',
        );
      }
      return (
        emoji: '😴',
        title: 'Pas de stat insolite cette semaine',
        body: 'Aucun joueur n\'a terminé 3e au moins 3 fois cette saison.',
      );

    // Catégorie 3 : meilleur ratio points/match
    case 3:
      final byAvg =
          allStats.entries.where((e) => e.value.matchesPlayed >= 3).toList()
            ..sort(
              (a, b) => b.value.averagePointsPerMatch.compareTo(
                a.value.averagePointsPerMatch,
              ),
            );
      if (byAvg.isNotEmpty) {
        final e = byAvg.first;
        return (
          emoji: '📈',
          title: 'Le plus régulier',
          body:
              '${nameOf(e.key)} affiche une moyenne de ${e.value.averagePointsPerMatch.toStringAsFixed(1)} pts/match sur ${e.value.matchesPlayed} matchs.',
        );
      }
      return (
        emoji: '😴',
        title: 'Pas de stat insolite cette semaine',
        body:
            'Aucun joueur n\'a joué au moins 3 matchs cette saison pour calculer un ratio points/match.',
      );

    // Catégorie 4 : sans-faute top 3 sur les 3 derniers matchs
    case 4:
      for (final e in allHistories.entries) {
        if (e.value.length >= 3) {
          final last3 = e.value.reversed.take(3).toList();
          if (last3.every((h) => h.rank != null && h.rank! <= 3)) {
            return (
              emoji: '🎯',
              title: 'Sans faute !',
              body:
                  '${nameOf(e.key)} est sur le podium à chacun de ses 3 derniers matchs !',
            );
          }
        }
      }
      return (
        emoji: '😴',
        title: 'Pas de stat insolite cette semaine',
        body:
            'Aucun joueur n\'a terminé dans le top 3 lors de ses 3 derniers matchs.',
      );

    // ─── Nouvelles catégories basées sur les stats de jeu ───

    // Catégorie 5 : meilleur buteur de la saison
    case 5:
      if (gameStats != null && gameStats.isNotEmpty) {
        final sorted = gameStats.entries
            .where((e) => e.value.goals > 0)
            .toList()
          ..sort((a, b) => b.value.goals.compareTo(a.value.goals));
        if (sorted.isNotEmpty) {
          final e = sorted.first;
          final ratio = e.value.matchesPlayed > 0
              ? (e.value.goals / e.value.matchesPlayed).toStringAsFixed(2)
              : '0';
          return (
            emoji: '⚽',
            title: 'Machine à buts',
            body:
                '${nameOf(e.key)} mène le classement des buteurs avec ${e.value.goals} but${e.value.goals > 1 ? 's' : ''} en ${e.value.matchesPlayed} match${e.value.matchesPlayed > 1 ? 's' : ''} ($ratio but/match).',
          );
        }
      }
      return (
        emoji: '⚽',
        title: 'En attente de buts',
        body: 'Aucun but enregistré cette saison. Le premier buteur se fera remarquer !',
      );

    // Catégorie 6 : meilleur passeur
    case 6:
      if (gameStats != null && gameStats.isNotEmpty) {
        final sorted = gameStats.entries
            .where((e) => e.value.assists > 0)
            .toList()
          ..sort((a, b) => b.value.assists.compareTo(a.value.assists));
        if (sorted.isNotEmpty) {
          final e = sorted.first;
          return (
            emoji: '🅰️',
            title: 'Le stratège',
            body:
                '${nameOf(e.key)} est le roi de la passe décisive avec ${e.value.assists} assist${e.value.assists > 1 ? 's' : ''} cette saison !',
          );
        }
      }
      return (
        emoji: '🅰️',
        title: 'En attente de passes',
        body: 'Aucune passe décisive enregistrée cette saison.',
      );

    // Catégorie 7 : joueur le plus fair-play (0 carton jaune/rouge)
    case 7:
      if (gameStats != null && gameStats.isNotEmpty) {
        final fairPlayers = gameStats.entries
            .where((e) =>
                e.value.matchesPlayed >= 3 &&
                e.value.greenCards == 0 &&
                e.value.yellowCards == 0 &&
                e.value.redCards == 0)
            .toList();
        if (fairPlayers.isNotEmpty) {
          final best = fairPlayers
            ..sort((a, b) => b.value.matchesPlayed.compareTo(a.value.matchesPlayed));
          return (
            emoji: '😇',
            title: 'Ange du terrain',
            body:
                '${nameOf(best.first.key)} n\'a reçu aucun carton en ${best.first.value.matchesPlayed} matchs !',
          );
        }
      }
      return (
        emoji: '😇',
        title: 'Fair-play',
        body: 'Pas encore assez de données pour élire le joueur le plus fair-play.',
      );

    // Catégorie 8 : buteur mais pas sur le podium des votes
    case 8:
      if (gameStats != null && gameStats.isNotEmpty) {
        for (final e in gameStats.entries) {
          if (e.value.goals >= 3) {
            final stats = allStats[e.key];
            if (stats != null && stats.firstCount == 0) {
              return (
                emoji: '🤔',
                title: 'Le buteur discret',
                body:
                    '${nameOf(e.key)} a marqué ${e.value.goals} buts cette saison mais n\'a jamais fini 1er aux votes !',
              );
            }
          }
        }
      }
      return (
        emoji: '🤔',
        title: 'Pas de stat insolite cette semaine',
        body: 'Aucun buteur n\'est passé sous les radars du podium cette saison.',
      );

    // Catégorie 9 : joueur le plus polyvalent (buts + passes + cartons verts)
    case 9:
      if (gameStats != null && gameStats.isNotEmpty) {
        final polyvalent = gameStats.entries
            .where((e) => e.value.goals > 0 && e.value.assists > 0 && e.value.greenCards > 0)
            .toList();
        if (polyvalent.isNotEmpty) {
          polyvalent.sort((a, b) =>
              (b.value.goals + b.value.assists + b.value.greenCards)
                  .compareTo(a.value.goals + a.value.assists + a.value.greenCards));
          final e = polyvalent.first;
          return (
            emoji: '🦸',
            title: 'Le couteau suisse',
            body:
                '${nameOf(e.key)} cumule ${e.value.goals} but${e.value.goals > 1 ? 's' : ''}, ${e.value.assists} passe${e.value.assists > 1 ? 's' : ''} D. et ${e.value.greenCards} carton${e.value.greenCards > 1 ? 's' : ''} vert${e.value.greenCards > 1 ? 's' : ''} !',
          );
        }
      }
      return (
        emoji: '🦸',
        title: 'Le couteau suisse',
        body: 'Aucun joueur n\'a encore combiné buts, passes et cartons verts cette saison.',
      );
  }

  return null;
}

// ---------------------------------------------------------------------------
// Taux de vote moyen de la saison
// ---------------------------------------------------------------------------

/// Taux de vote moyen sur tous les matchs clôturés, en pourcentage.
double averageVoteRate(List<({int totalVotes, int presentCount})> matches) {
  if (matches.isEmpty) return 0;
  final rates = matches.map(
    (m) => m.presentCount > 0 ? m.totalVotes / m.presentCount * 100 : 0.0,
  );
  return rates.reduce((a, b) => a + b) / matches.length;
}

// ---------------------------------------------------------------------------
// Stats par adversaire
// ---------------------------------------------------------------------------

/// Bilan d'un adversaire : victoires, nuls, défaites.
class OpponentRecord {
  const OpponentRecord({
    required this.opponentId,
    required this.opponentName,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
  });
  final String opponentId;
  final String opponentName;
  final int wins;
  final int draws;
  final int losses;
  int get played => wins + draws + losses;
}

/// Données minimales d'un match pour le calcul des stats adversaire.
class MatchForOpponent {
  const MatchForOpponent({
    required this.opponentId,
    required this.opponentName,
    required this.scoreHome,
    required this.scoreAway,
    required this.date,
  });
  final String opponentId;
  final String opponentName;
  final int scoreHome;
  final int scoreAway;
  final DateTime date;

  String get result {
    if (scoreHome > scoreAway) return 'win';
    if (scoreHome < scoreAway) return 'loss';
    return 'draw';
  }
}

/// Calcule le bilan par adversaire à partir d'une liste de matchs terminés.
Map<String, OpponentRecord> opponentRecords(List<MatchForOpponent> matches) {
  final map = <String, OpponentRecord>{};
  for (final m in matches) {
    final existing = map[m.opponentId] ??
        OpponentRecord(opponentId: m.opponentId, opponentName: m.opponentName);
    map[m.opponentId] = OpponentRecord(
      opponentId: m.opponentId,
      opponentName: m.opponentName,
      wins: existing.wins + (m.result == 'win' ? 1 : 0),
      draws: existing.draws + (m.result == 'draw' ? 1 : 0),
      losses: existing.losses + (m.result == 'loss' ? 1 : 0),
    );
  }
  return map;
}

/// Adversaire le plus battu (victime favorite).
OpponentRecord? favoriteVictim(List<MatchForOpponent> matches) {
  final records = opponentRecords(matches);
  final sorted = records.values.where((r) => r.wins > 0).toList()
    ..sort((a, b) => b.wins.compareTo(a.wins));
  return sorted.isNotEmpty ? sorted.first : null;
}

/// Adversaire qui nous bat le plus (bourreau).
OpponentRecord? nemesis(List<MatchForOpponent> matches) {
  final records = opponentRecords(matches);
  final sorted = records.values.where((r) => r.losses > 0).toList()
    ..sort((a, b) => b.losses.compareTo(a.losses));
  return sorted.isNotEmpty ? sorted.first : null;
}

// ---------------------------------------------------------------------------
// Utilitaire
// ---------------------------------------------------------------------------

int _isoWeekNumber(DateTime date) {
  // Calcul ISO 8601 du numéro de semaine.
  final thursday = date.add(Duration(days: 4 - (date.weekday)));
  final jan1 = DateTime(thursday.year, 1, 1);
  return ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
}

/// Écart-type d'une liste de nombres (pour le badge Régularité).
double standardDeviation(List<int> values) {
  if (values.length < 2) return double.infinity;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final sumSqDiff = values.fold<double>(0, (sum, v) => sum + pow(v - mean, 2));
  return sqrt(sumSqDiff / values.length);
}
