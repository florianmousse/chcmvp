import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/utils/season.dart' as season_util;
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/ranking/data/ranking_repository.dart';
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
  late final _tabController = TabController(length: 3, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RankingList(scope: 'general'),
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
                onPrevious: () =>
                    _jumpToAdjacentMonth(availableMonths, currentMonthKey, -1),
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
        ],
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

  /// Idem pour les saisons — une saison va de septembre à août (voir
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
            // joueurs strictement devant en points — deux joueurs à égalité
            // de points affichent donc le MÊME rang (ex: 1er, 1er, 3e), et
            // pas des rangs consécutifs comme le ferait l'index brut de la
            // liste. Même logique que pour le classement d'un match (voir
            // matchTally.ts côté serveur), appliquée ici au total de points.
            final rank =
                1 + entries.where((e) => e.points > entry.points).length;
            return ListTile(
              leading: CircleAvatar(child: Text('$rank')),
              title: Text(member?.fullName ?? 'Joueur inconnu'),
              subtitle: Text(
                '🥇 ${entry.firstCount}  🥈 ${entry.secondCount}  🥉 ${entry.thirdCount}',
              ),
              trailing: Text(
                '${entry.points} pts',
                style: Theme.of(context).textTheme.titleMedium,
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
