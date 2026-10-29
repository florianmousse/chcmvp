import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/utils/season.dart' as season_util;
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/player_stats_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:intl/intl.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

final _monthPattern = RegExp(r'^\d{4}-\d{2}$');
final _seasonPattern = RegExp(r'^\d{4}-\d{4}$');

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 4, vsync: this);
  DateTime _monthCursor = DateTime.now();
  int _seasonStartYear = season_util.currentSeasonStartYear();

  @override
  Widget build(BuildContext context) {
    final availableScopes =
        ref.watch(availableRankingScopesProvider).value ?? [];
    final availableMonths =
        availableScopes.where(_monthPattern.hasMatch).toList()..sort();
    final availableSeasons =
        availableScopes.where(_seasonPattern.hasMatch).toList()..sort();

    final currentMonthKey =
        '${_monthCursor.year}-${_monthCursor.month.toString().padLeft(2, '0')}';
    final currentSeasonKey = '$_seasonStartYear-${_seasonStartYear + 1}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Général'),
            Tab(text: 'Mensuel'),
            Tab(text: 'Saison'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 1000,
        child: TabBarView(
          controller: _tabController,
          children: [
            const _RankingList(scope: 'general'),
            Column(
              children: [
                _MonthPicker(
                  cursor: _monthCursor,
                  hasPrevious: availableMonths.any(
                    (m) => m.compareTo(currentMonthKey) < 0,
                  ),
                  hasNext: availableMonths.any(
                    (m) => m.compareTo(currentMonthKey) > 0,
                  ),
                  onPrevious: () => _jumpToAdjacentMonth(
                    availableMonths,
                    currentMonthKey,
                    -1,
                  ),
                  onNext: () =>
                      _jumpToAdjacentMonth(availableMonths, currentMonthKey, 1),
                ),
                Expanded(child: _RankingList(scope: currentMonthKey)),
              ],
            ),
            Column(
              children: [
                _SeasonPicker(
                  startYear: _seasonStartYear,
                  hasPrevious: availableSeasons.any(
                    (s) => s.compareTo(currentSeasonKey) < 0,
                  ),
                  hasNext: availableSeasons.any(
                    (s) => s.compareTo(currentSeasonKey) > 0,
                  ),
                  onPrevious: () => _jumpToAdjacentSeason(
                    availableSeasons,
                    currentSeasonKey,
                    -1,
                  ),
                  onNext: () => _jumpToAdjacentSeason(
                    availableSeasons,
                    currentSeasonKey,
                    1,
                  ),
                ),
                Expanded(child: _RankingList(scope: currentSeasonKey)),
              ],
            ),
            const _StatsRankingTab(),
          ],
        ),
      ),
    );
  }

  /// Saute directement au mois disponible le plus proche dans la direction
  /// demandée, plutôt que d'avancer d'un mois à la fois et de tomber sur des
  /// périodes vides ("Aucun résultat pour cette période").
  void _jumpToAdjacentMonth(
    List<String> availableMonths,
    String current,
    int direction,
  ) {
    final target = direction > 0
        ? availableMonths.where((m) => m.compareTo(current) > 0).firstOrNull
        : availableMonths.where((m) => m.compareTo(current) < 0).lastOrNull;
    if (target == null) return;
    final parts = target.split('-');
    setState(
      () => _monthCursor = DateTime(int.parse(parts[0]), int.parse(parts[1])),
    );
  }

  /// Idem pour les saisons - une saison va de septembre à août (voir
  /// core/utils/season.dart), pas de l'année civile.
  void _jumpToAdjacentSeason(
    List<String> availableSeasons,
    String current,
    int direction,
  ) {
    final target = direction > 0
        ? availableSeasons.where((s) => s.compareTo(current) > 0).firstOrNull
        : availableSeasons.where((s) => s.compareTo(current) < 0).lastOrNull;
    if (target == null) return;
    setState(() => _seasonStartYear = int.parse(target.split('-')[0]));
  }
}

extension _FirstLastOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.cursor,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime cursor;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: hasPrevious ? onPrevious : null,
          ),
          Text(
            DateFormat.yMMMM('fr_FR').format(cursor),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _SeasonPicker extends StatelessWidget {
  const _SeasonPicker({
    required this.startYear,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });
  final int startYear;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: hasPrevious ? onPrevious : null,
          ),
          Text(
            'Saison $startYear-${startYear + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _RankingList extends ConsumerWidget {
  const _RankingList({required this.scope});
  final String scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider(scope));
    final membersAsync = ref.watch(membersListProvider(null));

    return rankingAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('Aucun résultat pour cette période.'),
          );
        }
        final membersByUid = {
          for (final m in membersAsync.value ?? []) m.uid: m,
        };

        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final entry = entries[i];
            final member = membersByUid[entry.uid];
            // Classement "olympique" : le rang affiché est 1 + le nombre de
            // joueurs strictement devant en points - deux joueurs à égalité
            // de points affichent donc le MÊME rang (ex: 1er, 1er, 3e), et
            // pas des rangs consécutifs comme le ferait l'index brut de la
            // liste. Même logique que pour le classement d'un match (voir
            // matchTally.ts côté serveur), appliquée ici au total de points.
            final rank =
                1 + entries.where((e) => e.points > entry.points).length;
            return ListTile(
              leading: CircleAvatar(child: Text('$rank')),
              title: Text(member?.fullName ?? 'Joueur inconnu'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🥇 ${entry.firstCount}  🥈 ${entry.secondCount}  🥉 ${entry.thirdCount}',
                  ),
                  const _ProfileHint(),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.points} pts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(
                    uid: entry.uid,
                    playerName: member?.fullName ?? 'Joueur',
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Onglet Stats - classement des buteurs, passeurs, fair-play
// ═══════════════════════════════════════════════════════════════════════════

enum _StatSort { goals, assists, fairPlay }

class _StatsRankingTab extends ConsumerStatefulWidget {
  const _StatsRankingTab();

  @override
  ConsumerState<_StatsRankingTab> createState() => _StatsRankingTabState();
}

class _StatsRankingTabState extends ConsumerState<_StatsRankingTab> {
  _StatSort _sort = _StatSort.goals;

  @override
  Widget build(BuildContext context) {
    final aggAsync = ref.watch(aggregatedPlayerStatsProvider);
    final membersAsync = ref.watch(membersListProvider(null));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<_StatSort>(
            segments: const [
              ButtonSegment(value: _StatSort.goals, label: Text('⚽ Buteurs')),
              ButtonSegment(
                value: _StatSort.assists,
                label: Text('🅰️ Passeurs'),
              ),
              ButtonSegment(
                value: _StatSort.fairPlay,
                label: Text('🤝 Fair-play'),
              ),
            ],
            selected: {_sort},
            onSelectionChanged: (s) => setState(() => _sort = s.first),
          ),
        ),
        Expanded(
          child: aggAsync.when(
            data: (statsMap) {
              if (statsMap.isEmpty) {
                return const Center(
                  child: Text('Aucune stat disponible pour le moment.'),
                );
              }

              final members = membersAsync.value ?? [];
              final nameOf = <String, String>{
                for (final m in members) m.uid: m.fullName,
              };

              // Trier selon le mode sélectionné
              final entries = statsMap.entries
                  .where(
                    (e) =>
                        _sort != _StatSort.fairPlay || e.value.hasCompleteStats,
                  )
                  .toList();
              entries.sort((a, b) {
                switch (_sort) {
                  case _StatSort.goals:
                    return b.value.goals.compareTo(a.value.goals);
                  case _StatSort.assists:
                    return b.value.assists.compareTo(a.value.assists);
                  case _StatSort.fairPlay:
                    // Moins de cartons = mieux → tri ascendant
                    final cards = a.value.totalCards.compareTo(
                      b.value.totalCards,
                    );
                    return cards != 0
                        ? cards
                        : b.value.matchesPlayed.compareTo(
                            a.value.matchesPlayed,
                          );
                }
              });

              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final uid = entries[i].key;
                  final stats = entries[i].value;
                  final name = nameOf[uid] ?? 'Joueur inconnu';
                  final rank =
                      1 +
                      entries
                          .where(
                            (e) => switch (_sort) {
                              _StatSort.goals => e.value.goals > stats.goals,
                              _StatSort.assists =>
                                e.value.assists > stats.assists,
                              _StatSort.fairPlay =>
                                e.value.totalCards < stats.totalCards ||
                                    (e.value.totalCards == stats.totalCards &&
                                        e.value.matchesPlayed >
                                            stats.matchesPlayed),
                            },
                          )
                          .length;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: rank <= 3
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats.matchesPlayed} match${stats.matchesPlayed > 1 ? 's' : ''} renseigné${stats.matchesPlayed > 1 ? 's' : ''}',
                        ),
                        const _ProfileHint(),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatValue(stats: stats, sort: _sort),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PlayerStatsScreen(uid: uid, playerName: name),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
          ),
        ),
      ],
    );
  }
}

class _ProfileHint extends StatelessWidget {
  const _ProfileHint();

  @override
  Widget build(BuildContext context) => Text(
    'Voir le profil',
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _StatValue extends StatelessWidget {
  const _StatValue({required this.stats, required this.sort});
  final AggregatedPlayerStats stats;
  final _StatSort sort;

  @override
  Widget build(BuildContext context) {
    switch (sort) {
      case _StatSort.goals:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${stats.goals}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Text('⚽'),
            if (stats.assists > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${stats.assists}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Text(' 🅰️'),
            ],
          ],
        );
      case _StatSort.assists:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${stats.assists}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Text('🅰️'),
            if (stats.goals > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${stats.goals}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Text(' ⚽'),
            ],
          ],
        );
      case _StatSort.fairPlay:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stats.greenCards > 0)
              Text(
                '${stats.greenCards} 🟢 ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (stats.yellowCards > 0)
              Text(
                '${stats.yellowCards} 🟡 ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (stats.redCards > 0)
              Text(
                '${stats.redCards} 🔴',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (stats.totalCards == 0)
              Text('✅', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    }
  }
}
