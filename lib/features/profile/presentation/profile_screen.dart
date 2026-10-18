import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/foundation.dart';
import 'package:chc_mvp/core/widgets/legal_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/utils/season.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'package:chc_mvp/core/theme/theme_provider.dart';
import 'package:chc_mvp/features/home/domain/advanced_stats_calculator.dart';
import 'package:chc_mvp/features/home/domain/badge_calculator.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
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
              const Divider(height: 32),

              // ── Thème ──
              _ThemeSelector(),

              if (kIsWeb) ...[
                const SizedBox(height: 24),
                const Text(
                  'Sur le web, consulte les votes et résultats dans l'application. '
                  'Les notifications push et les widgets d'écran d'accueil restent disponibles dans l'application mobile.',
                ),
                const SizedBox(height: 12),
                const LegalLinks(),
              ],

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

/// Charge les données nécessaires au calcul des badges, synchronise avec
/// Firestore et affiche les badges avec les dates d'obtention.
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
    final storedBadgesAsync = ref.watch(userBadgesProvider(uid));

    if (statsAsync.isLoading ||
        historyAsync.isLoading ||
        rankingAsync.isLoading ||
        allHistoriesAsync.isLoading ||
        matchesAsync.isLoading ||
        storedBadgesAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final stats = statsAsync.value;
    final history = historyAsync.value ?? [];
    final ranking = rankingAsync.value ?? [];
    final allHistories = allHistoriesAsync.value ?? {};
    final allMatches = matchesAsync.value ?? [];
    final storedDates = storedBadgesAsync.value ?? {};

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

    final now = DateTime.now();
    final currentSeason = seasonId(now);
    final matchSeasons = closedMatches
        .map((m) => seasonId(m.date))
        .toSet();
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
      gameStats: _lookupGameStats(ref, uid),
    );

    // Synchroniser avec Firestore (n'écrit que les nouveaux badges)
    final computedTypes = badges.map((b) => b.type.name).toList();
    final newTypes = computedTypes.where((t) => !storedDates.containsKey(t)).toList();
    if (newTypes.isNotEmpty) {
      // Déclencher la sync en post-frame pour ne pas écrire pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final written = await ref.read(badgesRepositoryProvider).syncBadges(
          userId: uid,
          computedBadgeTypes: computedTypes,
        );
        if (written.isNotEmpty && context.mounted) {
          _showBadgeCelebration(context, written);
        }
      });
    }

    return BadgesSection(
      earnedBadges: badges,
      earnedDates: storedDates,
    );
  }

  /// Récupère les GameStats agrégées pour un joueur depuis le provider.
  GameStats? _lookupGameStats(WidgetRef ref, String uid) {
    final aggAsync = ref.watch(aggregatedPlayerStatsProvider);
    final aggData = aggAsync.value;
    if (aggData == null) return null;
    final data = aggData[uid];
    if (data == null) return null;
    return GameStats(
      goals: data.goals,
      assists: data.assists,
      greenCards: data.greenCards,
      yellowCards: data.yellowCards,
      redCards: data.redCards,
      matchesPlayed: data.matchesPlayed,
    );
  }

  void _showBadgeCelebration(BuildContext context, List<String> newBadgeTypes) {
    final theme = Theme.of(context);
    final badgeInfos = <Badge>[];
    for (final typeName in newBadgeTypes) {
      try {
        final type = BadgeType.values.byName(typeName);
        final badge = Badge.allDefinitions[type];
        if (badge != null) badgeInfos.add(badge);
      } catch (_) {}
    }
    if (badgeInfos.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              badgeInfos.length == 1
                  ? 'Nouveau badge débloqué !'
                  : '${badgeInfos.length} nouveaux badges !',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...badgeInfos.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(b.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              b.description,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Super ! 🙌'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur de thème (Système / Clair / Sombre) avec un SegmentedButton.
class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Text('Thème', style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Système'),
                  icon: Icon(Icons.settings_brightness),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {current},
              onSelectionChanged: (selected) {
                ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
