import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:chc_mvp/features/voting/presentation/voting_providers.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'package:chc_mvp/core/theme/theme_provider.dart';

const demoMember = UserModel(
  uid: 'camille',
  firstName: 'Camille',
  lastName: 'Martin',
  email: 'camille@example.test',
  team: 'Seniors',
);
final demoMatches = [
  MatchModel(
    id: 'open',
    date: DateTime(2026, 10, 18),
    time: '15:00',
    opponent: 'Rennes',
    isHome: true,
    team: 'Seniors',
    status: MatchStatus.votingOpen,
    presentPlayerIds: ['camille', 'guest', 'a', 'b'],
  ),
  MatchModel(
    id: 'next',
    date: DateTime(2026, 10, 25),
    time: '14:30',
    opponent: 'Nantes',
    isHome: false,
    team: 'Seniors',
  ),
  MatchModel(
    id: 'closed',
    date: DateTime(2026, 10, 11),
    time: '15:00',
    opponent: 'Angers',
    isHome: true,
    team: 'Seniors',
    status: MatchStatus.votingClosed,
    scoreHome: 3,
    scoreAway: 1,
    presentPlayerIds: ['camille', 'guest', 'a', 'b'],
  ),
];
final demoOverrides = [
  testMatchesListProvider.overrideWith((ref) => Stream.value([])),
  currentUserProfileProvider.overrideWith((ref) => Stream.value(demoMember)),
  matchesListProvider.overrideWith((ref, team) => Stream.value(demoMatches)),
  membersListProvider.overrideWith(
    (ref, team) => Stream.value([
      demoMember,
      demoMember.copyWith(uid: 'guest', firstName: 'Alex', email: ''),
    ]),
  ),
  rankingProvider.overrideWith(
    (ref, scope) => Stream.value([
      const RankingEntry(uid: 'camille', points: 24, firstCount: 3),
      const RankingEntry(uid: 'guest', points: 12, secondCount: 4),
    ]),
  ),
  availableRankingScopesProvider.overrideWith(
    (ref) => Stream.value(['general']),
  ),
  allPlayerStatsProvider.overrideWith(
    (ref) => Stream.value({
      'camille': const PlayerStats(matchesPlayed: 4, totalPoints: 24),
    }),
  ),
  allPlayerHistoriesProvider.overrideWith((ref) => Stream.value({})),
  playerStatsProvider.overrideWith(
    (ref, uid) => Stream.value(const PlayerStats()),
  ),
  playerHistoryProvider.overrideWith((ref, uid) => Stream.value([])),
  hasVotedProvider.overrideWith((ref, id) => Stream.value(id == 'closed')),
  matchResultProvider.overrideWith(
    (ref, id) => Stream.value({
      'totalVotes': 3,
      'entries': {
        'camille': {
          'points': 10,
          'firstCount': 2,
          'secondCount': 0,
          'thirdCount': 0,
        },
      },
    }),
  ),
  seasonGameStatsProvider.overrideWith(
    (ref) => const AsyncValue.data(<String, AggregatedPlayerStats>{}),
  ),
  aggregatedPlayerStatsProvider.overrideWith(
    (ref) => const AsyncValue.data(<String, AggregatedPlayerStats>{}),
  ),
  userBadgesProvider.overrideWith(
    (ref, uid) => Stream.value({
      'buteur': DateTime(2026, 10, 18),
      'fairPlay': DateTime(2026, 9, 18),
    }),
  ),
  themeModeProvider.overrideWith(() => DemoTheme()),
];

class DemoTheme extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}
