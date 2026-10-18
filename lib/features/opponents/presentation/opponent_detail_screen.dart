import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/core/widgets/opponent_logo.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';

/// Écran de détail d'un adversaire - bilan des confrontations et historique.
class OpponentDetailScreen extends ConsumerWidget {
  const OpponentDetailScreen({super.key, required this.opponent});
  final OpponentModel opponent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider(null));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OpponentLogo(logoAssetPath: opponent.logoAsset, size: 28),
            const SizedBox(width: 8),
            Text(opponent.name),
          ],
        ),
      ),
      body: matchesAsync.when(
        data: (allMatches) {
          // Filtrer les matchs avec cet adversaire et un score
          final confrontations =
              allMatches
                  .where(
                    (m) =>
                        m.opponentId == opponent.id &&
                        m.scoreHome != null &&
                        m.scoreAway != null,
                  )
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          // Calculer le bilan
          var wins = 0;
          var draws = 0;
          var losses = 0;
          var goalsFor = 0;
          var goalsAgainst = 0;
          for (final m in confrontations) {
            goalsFor += m.scoreHome!;
            goalsAgainst += m.scoreAway!;
            if (m.scoreHome! > m.scoreAway!) {
              wins++;
            } else if (m.scoreHome! == m.scoreAway!) {
              draws++;
            } else {
              losses++;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Bilan ──
              _BilanCard(
                wins: wins,
                draws: draws,
                losses: losses,
                goalsFor: goalsFor,
                goalsAgainst: goalsAgainst,
                played: confrontations.length,
                theme: theme,
              ),
              const SizedBox(height: 24),

              // ── Historique ──
              Text(
                'Historique des confrontations',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (confrontations.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aucune confrontation enregistrée.',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
  final dynamic match;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scoreHome = match.scoreHome as int;
    final scoreAway = match.scoreAway as int;
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
          '${DateFormat('dd/MM/yyyy').format(match.date as DateTime)} • ${match.isHome ? "Domicile" : "Extérieur"}',
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
