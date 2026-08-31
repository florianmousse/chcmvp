import 'package:flutter/material.dart';

/// Carte « stat insolite de la semaine » — rotation hebdomadaire (change
/// chaque lundi). Design amusant avec un fond teinté et une icône fun.
class FunStatCard extends StatelessWidget {
  const FunStatCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.tertiaryContainer.withValues(
                alpha: isDark ? 0.3 : 0.5,
              ),
              isDark
                  ? theme.colorScheme.surface
                  : Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Chaque lundi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « duel de la semaine » — deux joueurs proches au classement
/// mis en compétition avec un design versus.
class WeeklyDuelCard extends StatelessWidget {
  const WeeklyDuelCard({
    super.key,
    required this.name1,
    required this.pts1,
    required this.name2,
    required this.pts2,
  });

  final String name1;
  final int pts1;
  final String name2;
  final int pts2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final leader = pts1 >= pts2 ? name1 : name2;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withValues(
                alpha: isDark ? 0.3 : 0.6,
              ),
              theme.colorScheme.secondaryContainer.withValues(
                alpha: isDark ? 0.3 : 0.6,
              ),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('🆚', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Le duel de la semaine',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DuelSide(
                    name: name1,
                    pts: pts1,
                    isLeading: pts1 >= pts2,
                    theme: theme,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: _DuelSide(
                    name: name2,
                    pts: pts2,
                    isLeading: pts2 > pts1,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pts1 == pts2
                  ? 'Égalité parfaite !'
                  : '$leader prend la tête !',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuelSide extends StatelessWidget {
  const _DuelSide({
    required this.name,
    required this.pts,
    required this.isLeading,
    required this.theme,
  });
  final String name;
  final int pts;
  final bool isLeading;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$pts pts',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isLeading ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
