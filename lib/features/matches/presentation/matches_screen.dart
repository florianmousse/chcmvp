import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/widgets/opponent_logo.dart';
import 'package:chc_mvp/features/home/presentation/vote_rate_indicator.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/voting/presentation/vote_screen.dart';
import 'package:chc_mvp/features/voting/presentation/voting_providers.dart';
import 'package:intl/intl.dart';

/// Vue membre (lecture + vote) — distincte de MatchesAdminScreen qui gère la
/// création/édition et n'a pas vocation à être utilisée pour voter.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Matchs')),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(child: Text('Aucun match pour le moment.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _MatchCard(match: matches[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(match.label, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(status: match.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEEE dd MMMM', 'fr_FR').format(match.date)} à ${match.time}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Le logo se place à droite de ce qui suit — le classement des
            // joueurs pour un match terminé, le bouton de vote pour un vote
            // ouvert, ou rien pour un match à venir — jamais dans l'en-tête.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: switch (match.status) {
                    MatchStatus.votingOpen => _VoteAction(match: match),
                    MatchStatus.votingClosed => _TopThree(match: match),
                    MatchStatus.upcoming => const SizedBox.shrink(),
                  },
                ),
                const SizedBox(width: 12),
                OpponentLogo(logoAssetPath: match.opponentLogoAsset, size: 56),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteAction extends ConsumerWidget {
  const _VoteAction({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVotedAsync = ref.watch(hasVotedProvider(match.id));

    return hasVotedAsync.when(
      data: (hasVoted) {
        if (hasVoted) {
          return const Chip(
            avatar: Icon(Icons.check_circle, size: 18),
            label: Text('Déjà voté'),
          );
        }
        return FilledButton.icon(
          icon: const Icon(Icons.how_to_vote),
          label: const Text('Voter pour les 3 meilleurs joueurs'),
          onPressed: () async {
            final membersList = await ref.read(
              membersListProvider(null).future,
            );
            final candidates = membersList
                .where((m) => match.presentPlayerIds.contains(m.uid))
                .toList();
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      VoteScreen(match: match, candidates: candidates),
                ),
              );
            }
          },
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Text('Erreur : $e'),
    );
  }
}

class _TopThree extends ConsumerWidget {
  const _TopThree({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(matchResultProvider(match.id));
    final membersAsync = ref.watch(membersListProvider(null));

    return resultAsync.when(
      data: (result) {
        final entries = result?['entries'] as Map<String, dynamic>?;
        if (entries == null || entries.isEmpty) {
          return Text(
            'Aucun vote reçu pour ce match.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final members = membersAsync.value ?? [];
        final nameOf = <String, String>{
          for (final m in members) m.uid: m.fullName,
        };

        final golds = <String>[];
        final silvers = <String>[];
        final bronzes = <String>[];
        for (final e in entries.entries) {
          final v = e.value as Map<String, dynamic>;
          if (((v['firstCount'] ?? 0) as int) > 0) {
            golds.add(e.key);
          } else if (((v['secondCount'] ?? 0) as int) > 0) {
            silvers.add(e.key);
          } else if (((v['thirdCount'] ?? 0) as int) > 0) {
            bronzes.add(e.key);
          }
        }

        Widget medalLine(String medal, List<String> uids) {
          if (uids.isEmpty) return const SizedBox.shrink();
          final names = uids
              .map((u) => nameOf[u] ?? 'Joueur inconnu')
              .join(', ');
          return Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$medal $names',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final totalVotes = (result?['totalVotes'] ?? 0) as int;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            medalLine('🥇', golds),
            medalLine('🥈', silvers),
            medalLine('🥉', bronzes),
            if (totalVotes > 0 || match.presentPlayerIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: VoteRateIndicator(
                  totalVotes: totalVotes,
                  presentCount: match.presentPlayerIds.length,
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Text('Erreur : $e'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bgColor, fgColor) = switch (status) {
      MatchStatus.upcoming => (
        'À venir',
        Icons.schedule_outlined,
        Colors.grey.withValues(alpha: 0.15),
        Colors.grey.shade600,
      ),
      MatchStatus.votingOpen => (
        'Vote ouvert',
        Icons.how_to_vote_outlined,
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        Theme.of(context).colorScheme.primary,
      ),
      MatchStatus.votingClosed => (
        'Terminé',
        Icons.check_circle_outline,
        Colors.green.withValues(alpha: 0.12),
        Colors.green.shade700,
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 14, color: fgColor),
      label: Text(
        label,
        style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bgColor,
      side: BorderSide(color: fgColor.withValues(alpha: 0.3), width: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}

