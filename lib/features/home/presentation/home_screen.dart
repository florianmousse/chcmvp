import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/config/club_config.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/widgets/opponent_logo.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/home/domain/advanced_stats_calculator.dart';
import 'package:chc_mvp/features/home/presentation/fun_stat_card.dart';
import 'package:chc_mvp/features/home/presentation/highlight_cards.dart';
import 'package:chc_mvp/features/home/presentation/season_records_section.dart';
import 'package:chc_mvp/features/home/presentation/vote_rate_indicator.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/player_stats_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:chc_mvp/features/voting/presentation/vote_screen.dart';
import 'package:chc_mvp/features/voting/presentation/voting_providers.dart';
import 'package:intl/intl.dart';

/// Tableau de bord perso — volontairement différent de l'onglet Matchs (qui
/// liste tout) : ici, seulement ce qui demande une action ou donne un aperçu
/// rapide (vote en attente, ma position au classement, ma participation,
/// forme de l'équipe, progression, prochain match, dernier résultat).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final matchesAsync = ref.watch(matchesListProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const _ClubLogo(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile != null
                      ? 'Salut ${profile.firstName} 👋'
                      : 'Salut 👋',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          matchesAsync.when(
            data: (matches) {
              final votingOpen = matches
                  .where((m) => m.status == MatchStatus.votingOpen)
                  .toList();
              final upcoming =
                  matches
                      .where((m) => m.status == MatchStatus.upcoming)
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));
              final closed =
                  matches
                      .where((m) => m.status == MatchStatus.votingClosed)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
              final recentClosed = closed
                  .take(3)
                  .toList(); // du plus récent au plus ancien

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Section 1 : Mon classement ──
                  if (profile != null) _MyRankingCard(uid: profile.uid),

                  // ── Section 2 : À l'affiche (vote ouvert + prochain match + dernier résultat) ──
                  _ActionCardsSection(
                    votingOpen: votingOpen,
                    upcoming: upcoming,
                    closed: closed,
                    profile: profile,
                  ),

                  // ── Section 3 : Le coin des stats (stat insolite + duel) ──
                  const _FunStatWrapper(),

                  // ── Section 4 : Les temps forts ──
                  _HighlightCardsWrapper(recentMatches: recentClosed),

                  // ── Section 5 : Records de la saison ──
                  _SeasonRecordsWrapper(closedMatches: closed),

                  // ── Section 6 : Ma participation aux votes ──
                  if (profile != null)
                    _VotingParticipationCard(
                      uid: profile.uid,
                      allMatches: matches,
                    ),

                  if (votingOpen.isEmpty && upcoming.isEmpty && closed.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Aucun match pour le moment.'),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur : $e'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper : section avec titre + PageView swipable + indicateur de points
// ═══════════════════════════════════════════════════════════════════════════

/// Widget utilitaire qui affiche un titre de section puis les [pages] dans
/// un PageView horizontal avec un indicateur de points en bas.
class _SwipableSection extends StatefulWidget {
  const _SwipableSection({
    required this.title,
    required this.pages,
    this.pageHeight = 140,
  });

  final String title;
  final List<Widget> pages;
  final double pageHeight;

  @override
  State<_SwipableSection> createState() => _SwipableSectionState();
}

class _SwipableSectionState extends State<_SwipableSection> {
  late PageController _pageController;
  late int _lastPageCount;

  @override
  void initState() {
    super.initState();
    _lastPageCount = widget.pages.length;
    _pageController = PageController(
      viewportFraction: _lastPageCount > 1 ? 0.88 : 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant _SwipableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages.length != _lastPageCount) {
      _lastPageCount = widget.pages.length;
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: _lastPageCount > 1 ? 0.88 : 1.0,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.pageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: widget.pages.length > 1 ? 12 : 0),
              child: widget.pages[i],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 2 — À l'affiche (votes ouverts + prochain match + dernier résultat)
// ═══════════════════════════════════════════════════════════════════════════

class _ActionCardsSection extends ConsumerWidget {
  const _ActionCardsSection({
    required this.votingOpen,
    required this.upcoming,
    required this.closed,
    required this.profile,
  });

  final List<MatchModel> votingOpen;
  final List<MatchModel> upcoming;
  final List<MatchModel> closed;
  final dynamic profile; // UserProfile?

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = <Widget>[];

    // Votes ouverts — on n'ajoute que ceux pour lesquels le joueur
    // n'a PAS encore voté (sinon on a un bloc vide dans le PageView).
    for (final match in votingOpen) {
      final hasVoted = ref.watch(hasVotedProvider(match.id)).value ?? true;
      if (!hasVoted) {
        pages.add(_VoteCallToAction(match: match));
      }
    }

    // Prochain match
    if (upcoming.isNotEmpty) {
      pages.add(_NextMatchCard(match: upcoming.first));
    }

    // Dernier résultat
    if (closed.isNotEmpty) {
      pages.add(_LastResultCard(match: closed.first));
    }

    if (pages.isEmpty) return const SizedBox.shrink();

    return _SwipableSection(
      title: 'À l\'affiche',
      pages: pages,
      pageHeight: 170,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 4 — Les temps forts
// ═══════════════════════════════════════════════════════════════════════════

class _HighlightCardsWrapper extends ConsumerWidget {
  const _HighlightCardsWrapper({required this.recentMatches});
  final List<MatchModel> recentMatches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersListProvider(null));
    final allHistoriesAsync = ref.watch(allPlayerHistoriesProvider);

    if (allHistoriesAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final members = membersAsync.value ?? [];
    final allHistories = allHistoriesAsync.value ?? {};
    final nameOf = <String, String>{for (final m in members) m.uid: m.fullName};
    String name(String uid) => nameOf[uid] ?? 'Joueur inconnu';

    final cards = <HighlightCardData>[];

    // 🔥 Joueur en forme (meilleure somme sur les 3 derniers matchs)
    if (recentMatches.isNotEmpty) {
      final pointsByPlayer = <String, int>{};
      for (final match in recentMatches) {
        final resultAsync = ref.watch(matchResultProvider(match.id));
        final entries = resultAsync.value?['entries'] as Map<String, dynamic>?;
        if (entries == null) continue;
        for (final e in entries.entries) {
          final pts = ((e.value as Map<String, dynamic>)['points'] ?? 0) as int;
          pointsByPlayer[e.key] = (pointsByPlayer[e.key] ?? 0) + pts;
        }
      }
      if (pointsByPlayer.isNotEmpty) {
        final sorted = pointsByPlayer.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        cards.add(
          HighlightCardData(
            emoji: '🔥',
            title: 'Joueur en forme',
            playerName: name(sorted.first.key),
            value:
                '${sorted.first.value} pts sur ${recentMatches.length} matchs',
          ),
        );
      }
    }

    // 🚀 Meilleure progression (existant — plus grand écart par rapport à
    //     la moyenne personnelle au dernier match)
    if (recentMatches.isNotEmpty) {
      final latestMatch = recentMatches.first;
      final resultAsync = ref.watch(matchResultProvider(latestMatch.id));
      final entries =
          (resultAsync.value?['entries'] as Map<String, dynamic>?) ?? {};
      String? bestUid;
      var bestDelta = 0.0;
      for (final uid in latestMatch.presentPlayerIds) {
        final statsAsync = ref.watch(playerStatsProvider(uid));
        final stats = statsAsync.value;
        if (stats == null || stats.matchesPlayed == 0) continue;
        final latestPoints =
            ((entries[uid] as Map<String, dynamic>?)?['points'] ?? 0) as int;
        final priorPlayed = stats.matchesPlayed - 1;
        final priorTotal = stats.totalPoints - latestPoints;
        final priorAvg = priorPlayed > 0 ? priorTotal / priorPlayed : 0.0;
        final delta = latestPoints - priorAvg;
        if (delta > bestDelta) {
          bestDelta = delta;
          bestUid = uid;
        }
      }
      if (bestUid != null) {
        cards.add(
          HighlightCardData(
            emoji: '🚀',
            title: 'Meilleure progression',
            playerName: name(bestUid),
            value: '+${bestDelta.toStringAsFixed(1)} pts vs sa moyenne',
          ),
        );
      }
    }

    // 🤝 Le plus plébiscité
    // 🤝 Le plus plébiscité (max de votants distincts sur un seul match)
    final popular = mostPopularPlayer(allHistories);
    if (popular != null) {
      final suffix = popular.presentCount != null
          ? ' sur ${popular.presentCount} présents'
          : '';
      cards.add(
        HighlightCardData(
          emoji: '🤝',
          title: 'Le plus plébiscité',
          playerName: name(popular.uid),
          value: 'Votes de ${popular.maxDistinct} coéquipiers$suffix',
        ),
      );
    }

    // ⚡ Meilleure série en cours
    final streakData = bestCurrentStreakPlayer(allHistories);
    if (streakData != null && streakData.current >= 2) {
      cards.add(
        HighlightCardData(
          emoji: '⚡',
          title: 'Meilleure série en cours',
          playerName: name(streakData.uid),
          value: '${streakData.current} matchs consécutifs dans le top 3',
          subtitle: streakData.best > streakData.current
              ? 'Record saison : ${streakData.best}'
              : streakData.current == streakData.best
              ? '🏅 Égale le record de la saison !'
              : null,
        ),
      );
    }

    return HighlightCardsSection(cards: cards);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 5 — Records de la saison
// ═══════════════════════════════════════════════════════════════════════════

class _SeasonRecordsWrapper extends ConsumerWidget {
  const _SeasonRecordsWrapper({required this.closedMatches});
  final List<MatchModel> closedMatches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider('general'));
    final allHistoriesAsync = ref.watch(allPlayerHistoriesProvider);
    final membersAsync = ref.watch(membersListProvider(null));

    if (rankingAsync.isLoading || allHistoriesAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final ranking = rankingAsync.value ?? [];
    final allHistories = allHistoriesAsync.value ?? {};
    final members = membersAsync.value ?? [];
    final nameOf = <String, String>{for (final m in members) m.uid: m.fullName};
    String name(String uid) => nameOf[uid] ?? '?';

    final records = <SeasonRecord>[];

    // 🏆 Joueur avec le plus de points
    if (ranking.isNotEmpty) {
      records.add(
        SeasonRecord(
          emoji: '🏆',
          label: 'Plus de points',
          value: name(ranking.first.uid),
          detail: '${ranking.first.points} pts',
        ),
      );
    }

    // 🔥 Plus longue série top 3
    String? bestStreakUid;
    var bestStreak = 0;
    for (final e in allHistories.entries) {
      final s = bestTop3StreakEver(e.value);
      if (s > bestStreak) {
        bestStreak = s;
        bestStreakUid = e.key;
      }
    }
    if (bestStreakUid != null && bestStreak >= 2) {
      records.add(
        SeasonRecord(
          emoji: '🔥',
          label: 'Plus longue série',
          value: '$bestStreak matchs top 3',
          detail: name(bestStreakUid),
        ),
      );
    }

    // 🚀 Révélation de la saison
    final rev = seasonRevelation(allHistories);
    if (rev != null) {
      records.add(
        SeasonRecord(
          emoji: '🚀',
          label: 'Révélation',
          value: name(rev.uid),
          detail: '+${rev.progressionPercent.toStringAsFixed(0)} % de moyenne',
        ),
      );
    }

    // 🗳️ Taux de vote moyen
    final voteRateData = <({int totalVotes, int presentCount})>[];
    for (final match in closedMatches) {
      final resultAsync = ref.watch(matchResultProvider(match.id));
      final result = resultAsync.value;
      if (result == null) continue;
      final totalVotes = (result['totalVotes'] ?? 0) as int;
      voteRateData.add((
        totalVotes: totalVotes,
        presentCount: match.presentPlayerIds.length,
      ));
    }
    if (voteRateData.isNotEmpty) {
      final avgRate = averageVoteRate(voteRateData);
      records.add(
        SeasonRecord(
          emoji: '🗳️',
          label: 'Taux de vote moyen',
          value: '${avgRate.toStringAsFixed(0)} %',
          detail: '${voteRateData.length} matchs',
        ),
      );
    }

    return SeasonRecordsSection(records: records);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 3 — Stat insolite + duel de la semaine
// ═══════════════════════════════════════════════════════════════════════════

class _FunStatWrapper extends ConsumerWidget {
  const _FunStatWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStatsAsync = ref.watch(allPlayerStatsProvider);
    final allHistoriesAsync = ref.watch(allPlayerHistoriesProvider);
    final rankingAsync = ref.watch(rankingProvider('general'));
    final membersAsync = ref.watch(membersListProvider(null));

    if (allStatsAsync.isLoading ||
        allHistoriesAsync.isLoading ||
        rankingAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final allStats = allStatsAsync.value ?? {};
    final allHistories = allHistoriesAsync.value ?? {};
    final ranking = rankingAsync.value ?? [];
    final members = membersAsync.value ?? [];
    final nameOf = <String, String>{for (final m in members) m.uid: m.fullName};
    String name(String uid) => nameOf[uid] ?? 'Joueur inconnu';

    final now = DateTime.now();
    final pages = <Widget>[];

    // Stat insolite
    final fact = funFact(
      allStats: allStats,
      allHistories: allHistories,
      ranking: ranking,
      nameOf: name,
      now: now,
    );
    if (fact != null) {
      pages.add(
        FunStatCard(emoji: fact.emoji, title: fact.title, body: fact.body),
      );
    }

    // Duel de la semaine
    final duel = weeklyDuel(ranking, now);
    if (duel != null) {
      pages.add(
        WeeklyDuelCard(
          name1: name(duel.uid1),
          pts1: duel.pts1,
          name2: name(duel.uid2),
          pts2: duel.pts2,
        ),
      );
    }

    if (pages.isEmpty) return const SizedBox.shrink();

    return _SwipableSection(
      title: 'Le coin des stats',
      pages: pages,
      pageHeight: 160,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets existants (conservés / légèrement modifiés)
// ═══════════════════════════════════════════════════════════════════════════

class _VoteCallToAction extends ConsumerWidget {
  const _VoteCallToAction({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            // Icône décorative en arrière-plan
            Positioned(
              left: -8,
              bottom: -12,
              child: Icon(
                Icons.how_to_vote_rounded,
                size: 80,
                color: colors.onPrimaryContainer.withValues(alpha: 0.16),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.onPrimaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.how_to_vote_rounded,
                        size: 22,
                        color: colors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'VOTE OUVERT',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Text(
                  match.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.onPrimary,
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final members = await ref.read(
                        membersListProvider(null).future,
                      );

                      final candidates = members
                          .where((m) => match.presentPlayerIds.contains(m.uid))
                          .toList();

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VoteScreen(
                              match: match,
                              candidates: candidates,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.how_to_vote_outlined),
                    label: const Text(
                      'Voter maintenant',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRankingCard extends ConsumerWidget {
  const _MyRankingCard({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider('general'));

    return rankingAsync.when(
      data: (entries) {
        final matches = entries.where((e) => e.uid == uid).toList();
        if (matches.isEmpty) return const SizedBox.shrink();
        final entry = matches.first;
        final rank = 1 + entries.where((e) => e.points > entry.points).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text('$rank')),
            title: const Text('Mon classement général'),
            subtitle: Text(
              '🥇 ${entry.firstCount}  🥈 ${entry.secondCount}  🥉 ${entry.thirdCount}',
            ),
            trailing: Text(
              '${entry.points} pts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PlayerStatsScreen(uid: uid, playerName: 'Mes statistiques'),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

/// Combien de fois l'utilisateur a voté sur les matchs où il a été présent
/// (et où le vote a au moins été ouvert — impossible de voter avant), avec
/// un petit 🔥 si au moins 2 votes d'affilée sans en rater un.
class _VotingParticipationCard extends ConsumerWidget {
  const _VotingParticipationCard({required this.uid, required this.allMatches});
  final String uid;
  final List<MatchModel> allMatches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = allMatches
        .where(
          (m) =>
              m.presentPlayerIds.contains(uid) &&
              m.status != MatchStatus.upcoming,
        )
        .toList();
    if (eligible.isEmpty) return const SizedBox.shrink();

    var votedCount = 0;
    var currentStreak = 0;
    var streakBroken = false;
    final sortedEligible = [...eligible]
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final m in sortedEligible) {
      final hasVotedAsync = ref.watch(hasVotedProvider(m.id));
      if (hasVotedAsync.isLoading) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(),
        );
      }
      final voted = hasVotedAsync.value == true;
      if (voted) {
        votedCount++;
        if (!streakBroken) currentStreak++;
      } else {
        streakBroken = true;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.how_to_vote_outlined,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: const Text('Ma participation aux votes'),
        subtitle: Text(
          currentStreak >= 2
              ? '$votedCount vote(s) sur ${eligible.length} match(s) joué(s) · 🔥 série de $currentStreak'
              : '$votedCount vote(s) sur ${eligible.length} match(s) joué(s)',
        ),
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  const _NextMatchCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Logo adversaire
            OpponentLogo(logoAssetPath: match.opponentLogoAsset, size: 60),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PROCHAIN MATCH',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    match.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${DateFormat('EEEE dd MMMM', 'fr_FR').format(match.date)} à ${match.time}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastResultCard extends ConsumerWidget {
  const _LastResultCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(matchResultProvider(match.id));
    final membersAsync = ref.watch(membersListProvider(null));

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: resultAsync.when(
          data: (result) {
            final mvpUids =
                (result?['mvpUids'] as List?)?.cast<String>() ?? const [];

            final totalVotes = (result?['totalVotes'] ?? 0) as int;

            final members = membersAsync.value ?? [];

            final nameOf = <String, String>{
              for (final m in members) m.uid: m.fullName,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        size: 20,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'DERNIER RÉSULTAT',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Match ──
                Text(
                  match.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // ── MVP ──
                if (mvpUids.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.emoji_events,
                          size: 20,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          mvpUids.length > 1
                              ? 'MVP ex æquo : ${mvpUids.map((u) => nameOf[u] ?? 'Joueur inconnu').join(', ')}'
                              : 'MVP : ${nameOf[mvpUids.first] ?? 'Joueur inconnu'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // ── Taux de vote ──
                if (totalVotes > 0 || match.presentPlayerIds.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  VoteRateIndicator(
                    totalVotes: totalVotes,
                    presentCount: match.presentPlayerIds.length,
                  ),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Affiche le logo du club depuis les assets locaux (core/config/
/// club_config.dart) — chargement instantané, pas de requête réseau.
class _ClubLogo extends StatelessWidget {
  const _ClubLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Image.asset(
        clubLogoAssetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(context),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.sports_hockey,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
