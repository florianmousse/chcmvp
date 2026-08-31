import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/utils/season.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/home/domain/badge_calculator.dart';
import 'package:chc_mvp/features/home/presentation/badges_section.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/player_stats_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:chc_mvp/features/voting/presentation/voting_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null)
            return const SizedBox.shrink(); // gardé par _AuthenticatedGate

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? Text(
                        profile.firstName.isNotEmpty
                            ? profile.firstName[0]
                            : '?',
                        style: const TextStyle(fontSize: 28),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(
                child: Text(
                  profile.team,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              // ── Badges ──
              _BadgesWrapper(uid: profile.uid),

              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('E-mail'),
                subtitle: Text(profile.email),
              ),
              if (profile.jerseyNumber != null)
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('Numéro de maillot'),
                  subtitle: Text('#${profile.jerseyNumber}'),
                ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Mes statistiques'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerStatsScreen(
                      uid: profile.uid,
                      playerName: profile.fullName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

/// Charge les données nécessaires au calcul des badges et les affiche.
class _BadgesWrapper extends ConsumerWidget {
  const _BadgesWrapper({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsProvider(uid));
    final historyAsync = ref.watch(playerHistoryProvider(uid));
    final rankingAsync = ref.watch(rankingProvider('general'));
    final allHistoriesAsync = ref.watch(allPlayerHistoriesProvider);
    final matchesAsync = ref.watch(matchesListProvider(null));

    if (statsAsync.isLoading ||
        historyAsync.isLoading ||
        rankingAsync.isLoading ||
        allHistoriesAsync.isLoading ||
        matchesAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final stats = statsAsync.value;
    final history = historyAsync.value ?? [];
    final ranking = rankingAsync.value ?? [];
    final allHistories = allHistoriesAsync.value ?? {};
    final allMatches = matchesAsync.value ?? [];

    if (stats == null) return const SizedBox.shrink();

    // Compter les matchs clôturés de la saison et la participation au vote
    final closedMatches = allMatches
        .where((m) => m.status == MatchStatus.votingClosed)
        .toList();
    final eligible = closedMatches
        .where((m) => m.presentPlayerIds.contains(uid))
        .toList();

    var votedCount = 0;
    for (final m in eligible) {
      final hasVotedAsync = ref.watch(hasVotedProvider(m.id));
      if (hasVotedAsync.value == true) votedCount++;
    }

    // La saison est « finie » si on est en septembre (début de la saison
    // suivante) et que les matchs affichés appartiennent à la saison
    // précédente, OU si un admin a explicitement marqué la saison comme close.
    // Pour l'instant, heuristique simple : la saison est finie quand la date
    // courante est en septembre ou après, ET la date du dernier match clôturé
    // est avant septembre de la même année (= saison précédente terminée).
    final now = DateTime.now();
    final currentSeason = seasonId(now);
    final matchSeasons = closedMatches
        .map((m) => seasonId(m.date))
        .toSet();
    // On considère qu'une saison passée est terminée — seule la saison en
    // cours n'est pas « finie ».
    final isSeasonFinished = matchSeasons.isNotEmpty &&
        !matchSeasons.contains(currentSeason);

    final badges = BadgeCalculator.compute(
      uid: uid,
      stats: stats,
      history: history,
      ranking: ranking,
      allHistories: allHistories,
      seasonMatchCount: closedMatches.length,
      playerMatchesEligibleCount: eligible.length,
      playerVotedCount: votedCount,
      isSeasonFinished: isSeasonFinished,
    );

    return BadgesSection(earnedBadges: badges);
  }
}
