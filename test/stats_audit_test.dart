import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/player_match_stats_model.dart';
import 'package:chc_mvp/features/home/domain/advanced_stats_calculator.dart';
import 'package:chc_mvp/features/home/domain/badge_calculator.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';

PlayerHistoryPoint point(
  int points, {
  int? rank,
  int voters = 0,
  DateTime? date,
}) => PlayerHistoryPoint(
  matchDate: date ?? DateTime(2026, 10, 1),
  points: points,
  rank: rank,
  distinctVotersThisMatch: voters,
  presentCount: 10,
);
MatchModel match(
  String id, {
  DateTime? date,
  MatchStatus status = MatchStatus.votingClosed,
}) => MatchModel(
  id: id,
  date: date ?? DateTime(2026, 10, 1),
  time: '12:00',
  opponent: 'Rennes',
  isHome: false,
  team: 'Seniors',
  status: status,
  presentPlayerIds: ['a', 'b'],
);

void main() {
  test(
    'fair-play includes green, yellow and red; incomplete sheets cannot win',
    () {
      final stats = {
        'green': const GameStats(matchesPlayed: 15, greenCards: 4),
        'yellow': const GameStats(matchesPlayed: 15, yellowCards: 1),
        'red': const GameStats(matchesPlayed: 15, redCards: 1),
        'unknown': const GameStats(matchesPlayed: 20, hasCompleteStats: false),
        'clean': const GameStats(matchesPlayed: 6),
        'new': const GameStats(matchesPlayed: 1),
      };
      expect(fairPlayPlayers(stats).map((e) => e.key), ['clean']);
      for (final data in stats.entries) {
        final badges = BadgeCalculator.compute(
          uid: data.key,
          stats: const PlayerStats(),
          history: [],
          ranking: [],
          allHistories: {},
          seasonMatchCount: 0,
          playerMatchesEligibleCount: 0,
          playerVotedCount: 0,
          isSeasonFinished: false,
          gameStats: data.value,
        );
        expect(
          badges.any((b) => b.type == BadgeType.fairPlay),
          data.key == 'clean',
        );
      }
    },
  );

  test(
    'votes received count ballots even outside podium; points count match awards',
    () {
      final stats = statsFromHistory([
        point(5, rank: 1, voters: 8),
        point(0, voters: 2),
      ]);
      expect(stats.votesReceived, 10);
      expect(stats.firstCount, 1);
      expect(stats.totalPoints, 5);
      expect(stats.averagePointsPerMatch, 2.5);
    },
  );

  test(
    'popularity uses one-match distinct voters and streak stops outside top three',
    () {
      final histories = {
        'a': [
          point(5, rank: 1, voters: 8),
          point(3, rank: 2, voters: 7),
          point(0),
        ],
        'b': [point(1, rank: 3, voters: 5), point(5, rank: 1, voters: 6)],
      };
      expect(mostPopularPlayer(histories)!.uid, 'a');
      expect(mostPopularPlayer(histories)!.maxDistinct, 8);
      expect(currentTop3Streak(histories['a']!), 0);
      expect(bestTop3StreakEver(histories['a']!), 2);
      expect(bestCurrentStreakPlayer(histories)!.uid, 'b');
    },
  );

  test(
    'revelation compares first five with subsequent matches and handles zeros',
    () {
      expect(
        seasonRevelation({
          'a': [for (var i = 0; i < 5; i++) point(2), point(3)],
        })!.progressionPercent,
        50,
      );
      expect(
        seasonRevelation({
          'a': [for (var i = 0; i < 6; i++) point(0)],
        }),
        isNull,
      );
      expect(
        seasonRevelation({
          'a': [point(5)],
        }),
        isNull,
      );
    },
  );

  test(
    'weekly categories use ISO week and remain stable from Monday to Sunday',
    () {
      final ranking = [
        const RankingEntry(uid: 'a', points: 5),
        const RankingEntry(uid: 'b', points: 3),
      ];
      final games = {
        'a': const GameStats(
          goals: 5,
          assists: 4,
          greenCards: 1,
          matchesPlayed: 4,
        ),
        'b': const GameStats(matchesPlayed: 6),
      };
      const titles = [
        'Le saviez-vous ?',
        'Course serrée !',
        'Le fidèle du podium',
        'Meilleure moyenne',
        'Sans faute !',
        'Machine à buts',
        'Le stratège',
        'Ange du terrain',
        'Le buteur discret',
        'Le couteau suisse',
      ];
      for (var category = 0; category < 10; category++) {
        final monday = DateTime.utc(
          2026,
          1,
          5,
        ).add(Duration(days: (category + 8) * 7));
        for (final date in [
          monday,
          monday.add(const Duration(days: 6, hours: 23)),
        ]) {
          final fact = funFact(
            allStats: {
              'a': const PlayerStats(
                votesReceived: 7,
                thirdCount: 3,
                matchesPlayed: 4,
                totalPoints: 9,
              ),
            },
            allHistories: {
              'a': [point(1, rank: 3), point(1, rank: 3), point(1, rank: 3)],
            },
            ranking: ranking,
            nameOf: (uid) => uid,
            now: date,
            gameStats: games,
          )!;
          expect(fact.title, titles[category]);
          if (category == 0) expect(fact.body, contains('7 votes'));
          if (category == 7) expect(fact.body, startsWith('b '));
        }
      }
      expect(weeklyDuel(ranking, DateTime(2026, 10, 19))!.uid1, 'a');
      expect(weeklyDuel([], DateTime(2026)), isNull);
    },
  );

  test(
    'opponent records use CHC score, average vote rate is a match average',
    () {
      final matches = [
        MatchForOpponent(
          opponentId: 'x',
          opponentName: 'X',
          scoreHome: 3,
          scoreAway: 1,
          date: DateTime(2026),
        ),
        MatchForOpponent(
          opponentId: 'x',
          opponentName: 'X',
          scoreHome: 1,
          scoreAway: 1,
          date: DateTime(2026),
        ),
        MatchForOpponent(
          opponentId: 'y',
          opponentName: 'Y',
          scoreHome: 0,
          scoreAway: 2,
          date: DateTime(2026),
        ),
      ];
      expect(favoriteVictim(matches)!.opponentId, 'x');
      expect(nemesis(matches)!.opponentId, 'y');
      expect(opponentRecords(matches)['x']!.draws, 1);
      expect(
        averageVoteRate([
          (totalVotes: 2, presentCount: 4),
          (totalVotes: 8, presentCount: 8),
        ]),
        75,
      );
      expect(averageVoteRate([]), 0);
    },
  );

  test(
    'aggregation scopes seasons, includes every card and excludes absent players',
    () async {
      final container = ProviderContainer(
        overrides: [
          currentSeasonProvider.overrideWithValue('2026-2027'),
          matchesListProvider.overrideWith(
            (ref, team) => Stream.value([
              match('now'),
              match('old', date: DateTime(2026, 8, 31)),
              match('open', status: MatchStatus.votingOpen),
            ]),
          ),
          playerMatchStatsProvider.overrideWith(
            (ref, id) => Stream.value([
              PlayerMatchStats(
                playerId: 'a',
                goals: id == 'old' ? 20 : 2,
                greenCards: 1,
                yellowCards: 2,
                redCards: 3,
              ),
              const PlayerMatchStats(playerId: 'absent', goals: 99),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(seasonGameStatsProvider, (_, __) {});
      container.listen(aggregatedPlayerStatsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final season = container.read(seasonGameStatsProvider).requireValue;
      expect(season['a']!.goals, 2);
      expect(season['a']!.totalCards, 6);
      expect(season.containsKey('absent'), false);
      expect(
        container.read(aggregatedPlayerStatsProvider).requireValue['a']!.goals,
        22,
      );
    },
  );

  test(
    'aggregation never announces partial fair-play while a match is loading or failed',
    () async {
      final pending = StreamController<List<PlayerMatchStats>>();
      addTearDown(pending.close);
      final container = ProviderContainer(
        overrides: [
          matchesListProvider.overrideWith(
            (ref, team) => Stream.value([match('one'), match('two')]),
          ),
          playerMatchStatsProvider.overrideWith(
            (ref, id) => id == 'two'
                ? pending.stream
                : Stream.value([const PlayerMatchStats(playerId: 'a')]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(aggregatedPlayerStatsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(aggregatedPlayerStatsProvider).isLoading, true);
      pending.add([]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        container
            .read(aggregatedPlayerStatsProvider)
            .requireValue['a']!
            .isFairPlay,
        false,
      );
      pending.addError(StateError('network'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(aggregatedPlayerStatsProvider).hasError, true);
    },
  );

  test('season histories and records exclude prior seasons', () async {
    final container = ProviderContainer(
      overrides: [
        currentSeasonProvider.overrideWithValue('2026-2027'),
        allPlayerHistoriesProvider.overrideWith(
          (ref) => Stream.value({
            'a': [
              point(5, rank: 1, date: DateTime(2026, 8, 31)),
              point(1, rank: 3, voters: 2),
            ],
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(seasonPlayerStatsProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final stats = container.read(seasonPlayerStatsProvider).requireValue['a']!;
    expect(stats.matchesPlayed, 1);
    expect(stats.totalPoints, 1);
    expect(stats.firstCount, 0);
  });
}
