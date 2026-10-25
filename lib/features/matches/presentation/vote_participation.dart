import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/services/server_client.dart';
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

class _ParticipationDialog extends ConsumerStatefulWidget {
  const _ParticipationDialog({required this.matchId});
  final String matchId;
  @override
  ConsumerState<_ParticipationDialog> createState() =>
      _ParticipationDialogState();
}

class _ParticipationDialogState extends ConsumerState<_ParticipationDialog> {
  bool _showVoted = false;
  String? _busyUid;
  String? _message;
  bool _failed = false;

  Future<void> _resetPlayer(Map<String, dynamic> player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Réinitialiser ce vote ?'),
        content: Text(
          'Le bulletin de ${player['name']} sera supprimé pour ce match uniquement. '
          'Ce joueur pourra choisir à nouveau son top 3 tant que le vote reste ouvert. '
          'Les autres bulletins seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busyUid != null) return;
    setState(() {
      _busyUid = player['uid'] as String;
      _message = null;
    });
    try {
      await ref
          .read(serverClientProvider)
          .post(
            '/matches/${Uri.encodeComponent(widget.matchId)}/votes/${Uri.encodeComponent(player['uid'] as String)}/reset',
            {'voteVersion': player['voteVersion']},
          )
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() {
        _showVoted = false;
        _failed = false;
        _message =
            'Vote de ${player['name']} réinitialisé. Ce joueur peut voter à nouveau.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = error is ServerException
            ? error.message
            : 'La réinitialisation ne peut pas être confirmée. Actualise le suivi pour vérifier le bulletin avant de réessayer.';
      });
    } finally {
      if (mounted) {
        ref.invalidate(voteParticipationProvider(widget.matchId));
        setState(() => _busyUid = null);
      }
    }
  }

  Widget _playerCard(Map<String, dynamic> player, {required bool canReset}) {
    final theme = Theme.of(context);
    final subtitle = switch (player['accountStatus']) {
      'no_account' => 'Ne peut pas voter dans un match réel',
      'inactive' => 'Compte désactivé',
      'missing' => 'Fiche joueur supprimée',
      _ => _showVoted ? 'Bulletin enregistré' : 'Vote attendu',
    };
    return Container(
      key: ValueKey('participation-${player['uid']}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player['name'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          if (_showVoted && canReset && player['voteVersion'] != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busyUid == null ? () => _resetPlayer(player) : null,
              icon: _busyUid == player['uid']
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restart_alt),
              label: const Text('Réinitialiser le vote'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminProvider)) {
      return const AlertDialog(content: Text('Réservé aux administrateurs.'));
    }
    final value = ref.watch(voteParticipationProvider(widget.matchId));
    final theme = Theme.of(context);
    return PopScope(
      canPop: _busyUid == null,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Suivi des votes'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _failed
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                value.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Text(
                    'Impossible de charger le suivi. Réessaie dans un instant.',
                  ),
                  data: (data) {
                    final pending = (data['pending'] as List)
                        .cast<Map<String, dynamic>>();
                    final voted = (data['voted'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    final withAccount = pending
                        .where((p) => p['accountStatus'] != 'no_account')
                        .toList();
                    final withoutAccount = pending
                        .where((p) => p['accountStatus'] == 'no_account')
                        .toList();
                    final total = (data['totalCount'] as num).toInt();
                    final count = (data['votedCount'] as num).toInt();
                    final canReset =
                        data['status'] == 'voting_open' &&
                        data['canReset'] == true;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$count / $total ont voté',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: total == 0 ? 0 : (count / total).clamp(0, 1),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total : joueurs présents, y compris ceux sans compte. Actualisation toutes les 30 secondes.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ChoiceChip(
                              label: Text('En attente (${pending.length})'),
                              selected: !_showVoted,
                              onSelected: _busyUid != null
                                  ? null
                                  : (_) => setState(() => _showVoted = false),
                            ),
                            ChoiceChip(
                              label: Text('Ont voté ($count)'),
                              selected: _showVoted,
                              onSelected: _busyUid != null
                                  ? null
                                  : (_) => setState(() => _showVoted = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_showVoted) ...[
                          if (!canReset)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'La réinitialisation est disponible uniquement pendant la période de vote ouverte.',
                              ),
                            ),
                          if (voted.isEmpty)
                            Text(
                              count == 0
                                  ? 'Aucun bulletin enregistré.'
                                  : 'Liste des votants indisponible. Réessaie après actualisation.',
                            ),
                          for (final player in voted)
                            _playerCard(player, canReset: canReset),
                        ] else ...[
                          Text(
                            data['status'] == 'voting_closed'
                                ? "N'ont pas voté"
                                : "N'ont pas encore voté",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (total == 0)
                            const Text('Aucun joueur présent renseigné.')
                          else if (pending.isEmpty)
                            const Text('Tous les joueurs présents ont voté.'),
                          for (final player in withAccount)
                            _playerCard(player, canReset: false),
                          if (withoutAccount.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Sans compte (${withoutAccount.length})',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final player in withoutAccount)
                              _playerCard(player, canReset: false),
                          ],
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Le contenu des bulletins réels reste confidentiel.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busyUid == null
                ? () =>
                      ref.invalidate(voteParticipationProvider(widget.matchId))
                : null,
            child: const Text('Actualiser'),
          ),
          TextButton(
            onPressed: _busyUid == null
                ? () => Navigator.of(context).pop()
                : null,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
