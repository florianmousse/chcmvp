import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/matches/presentation/matches_admin_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_list_screen.dart';
import 'package:chc_mvp/features/teams/presentation/teams_list_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _rebuilding = false;
  String? _lastResultMessage;
  bool _lastResultWasError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            icon: Icons.group_outlined,
            title: 'Membres',
            subtitle: 'Inviter, modifier, désactiver, promouvoir',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MembersListScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.sports_hockey_outlined,
            title: 'Matchs',
            subtitle: 'Créer, modifier, ouvrir/fermer le vote',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MatchesAdminScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _AdminTile(
            icon: Icons.shield_outlined,
            title: 'Équipes',
            subtitle: 'Créer, renommer, supprimer',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TeamsListScreen())),
          ),
          const SizedBox(height: 24),
          _RankingsMaintenanceCard(
            rebuilding: _rebuilding,
            lastResultMessage: _lastResultMessage,
            lastResultWasError: _lastResultWasError,
            onRebuild: _rebuild,
          ),
        ],
      ),
    );
  }

  Future<void> _rebuild() async {
    setState(() {
      _rebuilding = true;
      _lastResultMessage = null;
    });
    try {
      final result = await ref
          .read(matchesRepositoryProvider)
          .rebuildRankings();
      if (mounted) {
        setState(() {
          _lastResultWasError = false;
          _lastResultMessage =
              '${result['matchesProcessed']} match(s) clôturé(s) recalculé(s) avec succès, à l\'instant.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastResultWasError = true;
          _lastResultMessage = 'Échec : $e';
        });
      }
    } finally {
      if (mounted) setState(() => _rebuilding = false);
    }
  }
}

class _RankingsMaintenanceCard extends StatelessWidget {
  const _RankingsMaintenanceCard({
    required this.rebuilding,
    required this.lastResultMessage,
    required this.lastResultWasError,
    required this.onRebuild,
  });

  final bool rebuilding;
  final String? lastResultMessage;
  final bool lastResultWasError;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Maintenance des classements',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recalcule entièrement les classements (général, mensuel, annuel) et les '
              'statistiques de chaque joueur, directement à partir des votes de chaque '
              'match clôturé. À utiliser si des chiffres semblent incohérents, ou après '
              'une mise à jour du calcul des résultats — sans risque, ça repart toujours '
              'des votes réels plutôt que d\'accumuler par-dessus les données existantes.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: rebuilding
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Reconstruire les classements maintenant'),
              onPressed: rebuilding ? null : onRebuild,
            ),
            if (lastResultMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    lastResultWasError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 18,
                    color: lastResultWasError
                        ? theme.colorScheme.error
                        : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastResultMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: lastResultWasError
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
