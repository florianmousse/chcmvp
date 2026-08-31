import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/features/matches/presentation/match_form_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:intl/intl.dart';

class MatchesAdminScreen extends ConsumerWidget {
  const MatchesAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Matchs')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Créer un match'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MatchFormScreen())),
      ),
      body: matchesAsync.when(
        data: (matches) => ListView.separated(
          itemCount: matches.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _MatchTile(match: matches[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _MatchTile extends ConsumerStatefulWidget {
  const _MatchTile({required this.match});
  final MatchModel match;

  @override
  ConsumerState<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends ConsumerState<_MatchTile> {
  bool _recomputing = false;

  MatchModel get match => widget.match;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(matchesRepositoryProvider);

    return ListTile(
      leading: _recomputing
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_statusIcon, color: _statusColor(context)),
      title: Text(match.label),
      subtitle: Text(
        '${DateFormat('dd/MM/yyyy').format(match.date)} à ${match.time} · ${match.team} · $_statusLabel',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          try {
            switch (action) {
              case 'edit':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MatchFormScreen(existing: match),
                  ),
                );
              case 'open_voting':
                await repo.openVoting(match.id);
              case 'close_voting':
                await repo.closeVoting(match.id);
              case 'recompute':
                setState(() => _recomputing = true);
                await repo.recomputeResults(match.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Résultats recalculés.')),
                  );
                }
              case 'delete':
                await repo.deleteMatch(match.id);
            }
          } catch (e) {
            if (context.mounted) {
              final message = e is ServerException ? e.message : 'Erreur : $e';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          } finally {
            if (mounted) setState(() => _recomputing = false);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
          if (match.status == MatchStatus.upcoming)
            const PopupMenuItem(
              value: 'open_voting',
              child: Text('Ouvrir le vote'),
            ),
          if (match.status == MatchStatus.votingOpen)
            const PopupMenuItem(
              value: 'close_voting',
              child: Text('Clôturer le vote'),
            ),
          if (match.status == MatchStatus.votingClosed)
            const PopupMenuItem(
              value: 'recompute',
              child: Text('Recalculer les résultats'),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (match.status) {
    MatchStatus.upcoming => Icons.schedule,
    MatchStatus.votingOpen => Icons.how_to_vote,
    MatchStatus.votingClosed => Icons.check_circle,
  };

  Color _statusColor(BuildContext context) => switch (match.status) {
    MatchStatus.upcoming => Theme.of(context).colorScheme.outline,
    MatchStatus.votingOpen => Theme.of(context).colorScheme.primary,
    MatchStatus.votingClosed => Theme.of(context).colorScheme.tertiary,
  };

  String get _statusLabel => switch (match.status) {
    MatchStatus.upcoming => 'À venir',
    MatchStatus.votingOpen => 'Vote ouvert',
    MatchStatus.votingClosed => 'Vote terminé',
  };
}
