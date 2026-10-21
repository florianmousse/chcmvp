import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

final voteParticipationProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, matchId) {
      if (!ref.watch(isAdminProvider)) return const Stream.empty();
      final server = ref.watch(serverClientProvider);
      final controller = StreamController<Map<String, dynamic>>();
      var disposed = false, busy = false;
      Future<void> refresh() async {
        if (busy || disposed) return;
        busy = true;
        try {
          final result = await server.get(
            '/matches/${Uri.encodeComponent(matchId)}/participation',
          );
          if (!disposed) controller.add(result);
        } catch (error, stack) {
          if (!disposed) controller.addError(error, stack);
        } finally {
          busy = false;
        }
      }

      final timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => refresh(),
      );
      refresh();
      ref.onDispose(() {
        disposed = true;
        timer.cancel();
        controller.close();
      });
      return controller.stream;
    });

/// Administrators see turnout, but cannot inspect anyone's real ballot choices.
class VoteParticipation extends ConsumerWidget {
  const VoteParticipation({super.key, required this.matchId});
  final String matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider) || !TickerMode.of(context)) {
      return const SizedBox.shrink();
    }
    final value = ref.watch(voteParticipationProvider(matchId));
    return value.when(
      loading: () => const Text('Chargement de la participation…'),
      error: (error, _) => TextButton.icon(
        onPressed: () => ref.invalidate(voteParticipationProvider(matchId)),
        icon: const Icon(Icons.refresh),
        label: const Text('Suivi indisponible · Réessayer'),
      ),
      data: (data) => TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.how_to_vote_outlined, size: 18),
        label: Text(
          '${data['votedCount']} / ${data['totalCount']} ont voté · Voir le suivi',
          softWrap: true,
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _ParticipationDialog(matchId: matchId),
        ),
      ),
    );
  }
}

class _ParticipationDialog extends ConsumerWidget {
  const _ParticipationDialog({required this.matchId});
  final String matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) {
      return const AlertDialog(content: Text('Réservé aux administrateurs.'));
    }
    final value = ref.watch(voteParticipationProvider(matchId));
    return AlertDialog(
      title: const Text('Suivi des votes'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text(
              "Impossible de charger le suivi. Réessaie dans un instant.",
            ),
            data: (data) {
              final pending = (data['pending'] as List)
                  .cast<Map<String, dynamic>>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data['votedCount']} / ${data['totalCount']} ont voté',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Total : joueurs inscrits comme présents, y compris ceux sans compte. Actualisation toutes les 30 secondes.",
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['status'] == 'voting_closed'
                        ? "N'ont pas voté"
                        : "N'ont pas encore voté",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (data['totalCount'] == 0)
                    const Text('Aucun joueur présent renseigné.')
                  else if (pending.isEmpty)
                    const Text('Tous les joueurs présents ont voté.'),
                  for (final player in pending)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(player['name'] as String),
                      subtitle: switch (player['accountStatus']) {
                        'no_account' => const Text(
                          "Sans compte · ne peut pas voter dans un match réel",
                        ),
                        'inactive' => const Text("Compte désactivé"),
                        'missing' => const Text("Fiche joueur supprimée"),
                        _ => null,
                      },
                    ),
                  const Text(
                    'Le contenu des bulletins réels reste confidentiel.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => ref.invalidate(voteParticipationProvider(matchId)),
          child: const Text('Actualiser'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
