import 'package:flutter/material.dart';

/// Petit indicateur de taux de vote : barre de progression + pourcentage,
/// affiché dans la carte « Dernier résultat » ou n'importe quel contexte de
/// match clôturé.
class VoteRateIndicator extends StatelessWidget {
  const VoteRateIndicator({
    super.key,
    required this.totalVotes,
    required this.presentCount,
  });

  final int totalVotes;
  final int presentCount;

  @override
  Widget build(BuildContext context) {
    if (presentCount == 0) return const SizedBox.shrink();

    final rate = totalVotes / presentCount;
    final percent = (rate * 100).round();
    final theme = Theme.of(context);

    final color = percent >= 80
        ? Colors.green
        : percent >= 50
            ? Colors.orange
            : Colors.red;

    return Row(
      children: [
        Icon(Icons.how_to_vote_outlined, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRoundedRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent % de votes ($totalVotes/$presentCount)',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Wrapper car ClipRRect ne prend pas de const constructor facilement.
class ClipRoundedRect extends StatelessWidget {
  const ClipRoundedRect({
    super.key,
    required this.borderRadius,
    required this.child,
  });
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}
