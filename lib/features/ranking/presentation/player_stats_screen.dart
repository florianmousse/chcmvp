import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/ranking/data/ranking_repository.dart';
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
      body: statsAsync.when(
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                _StatCard(label: 'Total points', value: '${stats.totalPoints}'),
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
                    _ => '—',
                  };
                  return ListTile(
                    leading: Text(medal, style: const TextStyle(fontSize: 20)),
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
