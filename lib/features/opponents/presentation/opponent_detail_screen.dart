import 'package:flutter/material.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/features/matches/domain/club_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/core/widgets/opponent_logo.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';

/// Écran de détail d'un adversaire - bilan des confrontations et historique.
class OpponentDetailScreen extends MatchHistoryScreen {
  const OpponentDetailScreen({super.key, required OpponentModel opponent})
    : super(opponent: opponent);
}

/// Bilan global si aucun adversaire n'est précisé.
class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key, this.opponent});
  final OpponentModel? opponent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider(null));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: opponent == null
            ? const Text('Bilan du club')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OpponentLogo(logoAssetPath: opponent!.logoAsset, size: 28),
                  const SizedBox(width: 8),
                  Flexible(child: Text(opponent!.name)),
                ],
              ),
      ),
      body: ResponsiveContent(
        maxWidth: 900,
        child: matchesAsync.when(
          data: (allMatches) {
            final record = ClubRecord.fromMatches(
              allMatches,
              opponent: opponent,
            );
            final confrontations = record.matches;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Toutes saisons · Matchs joués avec un score renseigné. Les matchs de test sont exclus.',
                ),
                const SizedBox(height: 12),
                // ── Bilan ──
                _BilanCard(
                  wins: record.wins,
                  draws: record.draws,
                  losses: record.losses,
                  goalsFor: record.goalsFor,
                  goalsAgainst: record.goalsAgainst,
                  played: confrontations.length,
                  theme: theme,
                ),
                const SizedBox(height: 24),

                // ── Historique ──
                Text(
                  opponent == null
                      ? 'Historique des matchs'
                      : 'Historique des confrontations',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (confrontations.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Aucun match joué avec un score renseigné.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  )
                else
                  ...confrontations.map(
                    (m) => _ConfrontationTile(match: m, theme: theme),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
        ),
      ),
    );
  }
}

class _BilanCard extends StatelessWidget {
  const _BilanCard({
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.played,
    required this.theme,
  });

  final int wins, draws, losses, goalsFor, goalsAgainst, played;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Bilan', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 16,
              children: [
                _statColumn('Matchs', '$played', theme),
                _statColumn('Victoires', '$wins', theme, color: Colors.green),
                _statColumn('Nuls', '$draws', theme, color: Colors.orange),
                _statColumn('Défaites', '$losses', theme, color: Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 16,
              children: [
                _statColumn(
                  'Buts marqués',
                  '$goalsFor',
                  theme,
                  color: Colors.green,
                ),
                _statColumn(
                  'Buts encaissés',
                  '$goalsAgainst',
                  theme,
                  color: Colors.red,
                ),
                _statColumn(
                  'Diff.',
                  '${goalsFor - goalsAgainst >= 0 ? '+' : ''}${goalsFor - goalsAgainst}',
                  theme,
                  color: goalsFor >= goalsAgainst ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ConfrontationTile extends StatelessWidget {
  const _ConfrontationTile({required this.match, required this.theme});
  final MatchModel match;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scoreHome = match.scoreHome!;
    final scoreAway = match.scoreAway!;
    final isWin = scoreHome > scoreAway;
    final isDraw = scoreHome == scoreAway;

    final resultIcon = isWin
        ? Icons.check_circle
        : isDraw
        ? Icons.remove_circle
        : Icons.cancel;
    final resultColor = isWin
        ? Colors.green
        : isDraw
        ? Colors.orange
        : Colors.red;
    final resultLabel = isWin
        ? 'V'
        : isDraw
        ? 'N'
        : 'D';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: resultColor.withValues(alpha: 0.15),
          child: Icon(resultIcon, color: resultColor),
        ),
        title: Text(
          'CHC $scoreHome - $scoreAway ${match.opponent}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy').format(match.date)} • ${match.isHome ? "Domicile" : "Extérieur"} • ${match.team}',
        ),
        trailing: Text(
          resultLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: resultColor,
          ),
        ),
      ),
    );
  }
}
