import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'ceremonies_providers.dart';
import 'ceremonies_screen.dart';

class TrophiesSection extends ConsumerWidget {
  const TrophiesSection({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Trophées de cérémonie',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Text(
        'Des prix décernés par les votes du club, distincts des badges de progression.',
      ),
      ref
          .watch(ceremoniesProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) =>
                const Text('Trophées indisponibles pour le moment.'),
            data: (events) {
              final won = events.where((e) => e.winners.contains(uid)).toList();
              if (won.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucun trophée pour le moment.'),
                );
              }
              return Column(
                children: [
                  for (final e in won)
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(
                          Icons.emoji_events,
                          color: Color(0xffb68b22),
                          size: 36,
                        ),
                        title: Text(e.title),
                        subtitle: Text(
                          e.results
                              .where((r) => r.rank == 1 && r.nominee.uid == uid)
                              .map((r) => r.nominee.label)
                              .join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CeremonyDetailScreen(id: e.id),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    ],
  );
}

class PlayerAwardMarks extends ConsumerWidget {
  const PlayerAwardMarks({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(allBadgesProvider).value?[uid] ?? {};
    final badges = BadgeType.values
        .where((type) => earned.containsKey(type.name))
        .map((type) => Badge.forEarned(type, earned.keys))
        .toList();
    final trophies =
        ref
            .watch(ceremoniesProvider)
            .value
            ?.where((e) => e.winners.contains(uid))
            .toList() ??
        [];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final b in badges)
          Tooltip(
            message: 'Badge : ${b.label}',
            child: Semantics(
              label: 'Badge ${b.label}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${b.emoji}${b.tier == 'Or'
                      ? '🥇'
                      : b.tier == 'Argent'
                      ? '🥈'
                      : b.tier == 'Bronze'
                      ? '🥉'
                      : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        for (final e in trophies)
          Tooltip(
            message: 'Trophée : ${e.title}',
            child: Semantics(
              label: 'Trophée ${e.title}',
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xffb68b22),
                size: 22,
              ),
            ),
          ),
      ],
    );
  }
}
