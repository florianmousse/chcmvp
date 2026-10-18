import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/home/presentation/badges_section.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:intl/intl.dart';

class PlayerStatsScreen extends ConsumerWidget {
  const PlayerStatsScreen({
    super.key,
    required this.uid,
    required this.playerName,
  });
  final String uid;
  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsProvider(uid));
    final historyAsync = ref.watch(playerHistoryProvider(uid));

    return Scaffold(
      appBar: AppBar(title: Text(playerName)),
      body: ResponsiveContent(
        maxWidth: 1000,
        child: statsAsync.when(
          data: (stats) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Badges du joueur (lus depuis Firestore) ──
              _PublicBadgesSection(uid: uid, playerName: playerName),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatCard(
                    label: 'Matchs joués',
                    value: '${stats.matchesPlayed}',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Votes reçus',
                    value: '${stats.votesReceived}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'Moy. points/match',
                    value: stats.averagePointsPerMatch.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Total points',
                    value: '${stats.totalPoints}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: '🥇 1ères places',
                    value: '${stats.firstCount}',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: '🥈🥉 2e/3e places',
                    value: '${stats.secondCount + stats.thirdCount}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // ─── Stats de jeu ───
              Text(
                'Stats de jeu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _GameStatsSection(uid: uid),
              const SizedBox(height: 24),
              Text(
                'Évolution des performances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              historyAsync.when(
                data: (history) => history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Pas encore de match comptabilisé.'),
                      )
                    : _EvolutionChart(history: history),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur : $e'),
              ),
              const SizedBox(height: 24),
              Text(
                'Historique des votes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              historyAsync.when(
                data: (history) => Column(
                  children: history.reversed.map((h) {
                    final medal = switch (h.rank) {
                      1 => '🥇',
                      2 => '🥈',
                      3 => '🥉',
                      _ => '-',
                    };
                    return ListTile(
                      leading: Text(
                        medal,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(DateFormat('dd/MM/yyyy').format(h.matchDate)),
                      trailing: Text('${h.points} pts'),
                    );
                  }).toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Erreur : $e'),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sparkline maison (pas de dépendance de graphique supplémentaire) montrant
/// les points marqués match après match, dans l'ordre chronologique.
class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.history});
  final List<PlayerHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(
        size: const Size(double.infinity, 120),
        painter: _SparklinePainter(
          points: history.map((h) => h.points.toDouble()).toList(),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxY = points
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity);
    final stepX = points.length > 1 ? size.width / (points.length - 1) : 0.0;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = color;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = stepX * i;
      final y = size.height - (points[i] / maxY) * (size.height - 12) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}

/// Affiche buts, passes, cartons agrégés pour un joueur.
class _GameStatsSection extends ConsumerWidget {
  const _GameStatsSection({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggAsync = ref.watch(aggregatedPlayerStatsProvider);

    return aggAsync.when(
      data: (statsMap) {
        final stats = statsMap[uid];
        if (stats == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune stat de jeu enregistrée.'),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                _StatCard(label: '⚽ Buts', value: '${stats.goals}'),
                const SizedBox(width: 12),
                _StatCard(label: '🅰️ Passes D.', value: '${stats.assists}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(label: '🟢 Verts', value: '${stats.greenCards}'),
                const SizedBox(width: 12),
                _StatCard(label: '🟡 Jaunes', value: '${stats.yellowCards}'),
                const SizedBox(width: 12),
                _StatCard(label: '🔴 Rouges', value: '${stats.redCards}'),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur : $e'),
    );
  }
}

/// Affiche les badges d'un joueur lus depuis Firestore - utilisé pour
/// les profils publics (quand on consulte les stats d'un autre joueur).
class _PublicBadgesSection extends ConsumerWidget {
  const _PublicBadgesSection({required this.uid, required this.playerName});
  final String uid;
  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(uid));

    return badgesAsync.when(
      data: (earnedDates) {
        if (earnedDates.isEmpty) return const SizedBox.shrink();

        // Reconstruire la liste de Badge à partir des types stockés
        final badges = <Badge>[];
        for (final typeName in earnedDates.keys) {
          try {
            final type = BadgeType.values.byName(typeName);
            final badge = Badge.allDefinitions[type];
            if (badge != null) badges.add(badge);
          } catch (_) {
            // Type inconnu (badge supprimé ou renommé) - on l'ignore
          }
        }

        return BadgesSection(
          earnedBadges: badges,
          earnedDates: earnedDates,
          title: 'Badges de $playerName',
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
