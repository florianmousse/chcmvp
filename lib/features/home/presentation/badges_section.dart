import 'package:flutter/material.dart' hide Badge;
import 'package:chc_mvp/features/home/domain/badge_model.dart';

/// Section badges — affiche TOUS les badges (gagnés + non gagnés).
/// Les badges gagnés sont mis en valeur. Les badges non gagnés apparaissent
/// avec un « ? » et une opacité réduite pour montrer ce qu'il y a à débloquer.
/// Tap sur n'importe quel badge → BottomSheet avec le détail et l'état.
class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key, required this.earnedBadges});

  /// Badges effectivement gagnés par le joueur.
  final List<Badge> earnedBadges;

  @override
  Widget build(BuildContext context) {
    final allBadges = Badge.allDefinitions.values.toList();
    final earnedTypes = earnedBadges.map((b) => b.type).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mes badges', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text(
              '${earnedBadges.length}/${allBadges.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allBadges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final earned = earnedTypes.contains(badge.type);
              return _BadgeChip(badge: badge, earned: earned);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.earned});
  final Badge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge, earned),
      child: Opacity(
        opacity: earned ? 1.0 : 0.35,
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: earned
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: earned
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Si non gagné → icône cadenas/question à la place de l'emoji
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 32,
                      // Filtre gris si non gagné
                      color: earned ? null : theme.colorScheme.outline,
                    ),
                  ),
                  if (!earned)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                badge.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: earned ? null : theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Badge badge, bool earned) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge avec opacité si non gagné
            Opacity(
              opacity: earned ? 1.0 : 0.4,
              child: Text(badge.emoji, style: const TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 8),
            // Pastille statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: earned
                    ? Colors.green.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                earned ? '✅ Obtenu' : '🔒 Non débloqué',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: earned ? Colors.green : theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
