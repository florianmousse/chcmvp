import 'package:flutter/material.dart';

/// Cartes « temps forts » affichées dans un PageView horizontal sur l'écran
/// d'accueil — chaque carte met en avant une stat-clé avec un design
/// visuel distinctif (gradient, grand emoji, nom du joueur, valeur).
class HighlightCardsSection extends StatelessWidget {
  const HighlightCardsSection({super.key, required this.cards});

  /// Liste des cartes à afficher. Si vide, le widget est invisible.
  final List<HighlightCardData> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Les temps forts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _HighlightCard(data: cards[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class HighlightCardData {
  const HighlightCardData({
    required this.emoji,
    required this.title,
    required this.playerName,
    required this.value,
    this.subtitle,
    this.gradientColors,
  });

  final String emoji;
  final String title;
  final String playerName;
  final String value;
  final String? subtitle;

  /// Deux couleurs pour le gradient de fond. Si null, utilise le thème.
  final List<Color>? gradientColors;
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.data});
  final HighlightCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = data.gradientColors ??
        [
          theme.colorScheme.primaryContainer,
          isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.secondaryContainer,
        ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Grand emoji à gauche
          Text(data.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.playerName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
                if (data.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
