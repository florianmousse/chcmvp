import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'matches_providers.dart';

/// Explicit simulation UI: never writes a real player's production ballot.
class TestMatchScreen extends ConsumerStatefulWidget {
  const TestMatchScreen({super.key, required this.match});
  final MatchModel match;
  @override
  ConsumerState<TestMatchScreen> createState() => _TestMatchScreenState();
}

class _TestMatchScreenState extends ConsumerState<TestMatchScreen> {
  String? _voter, _first, _second, _third;
  bool _busy = false;
  String? _message;
  bool _failed = false;

  Future<void> _run(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() {
          _message = message;
          _failed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString();
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _selectVoter(String? uid, List<Map<String, dynamic>> votes) {
    final vote = votes.where((v) => v['voterUid'] == uid).firstOrNull;
    setState(() {
      _voter = uid;
      _first = vote?['firstPlaceUid'] as String?;
      _second = vote?['secondPlaceUid'] as String?;
      _third = vote?['thirdPlaceUid'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminProvider) || !widget.match.isTest) {
      return const Scaffold(
        body: Center(child: Text('Réservé aux administrateurs.')),
      );
    }
    final matches = ref.watch(testMatchesListProvider);
    if (matches.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match de test')),
        body: const Center(
          child: Text('Impossible de charger le match de test.'),
        ),
      );
    }
    if (matches.hasValue &&
        !matches.value!.any((m) => m.id == widget.match.id)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match de test')),
        body: const Center(child: Text('Ce match de test a été supprimé.')),
      );
    }
    final match =
        matches.value?.where((m) => m.id == widget.match.id).firstOrNull ??
        widget.match;
    final members = ref.watch(membersListProvider(null)).value ?? [];
    final names = {for (final m in members) m.uid: m.fullName};
    String name(String uid) => names[uid] ?? uid;
    final votesAsync = ref.watch(testVotesProvider(match.id));
    final votes = votesAsync.value ?? [];
    final result = ref.watch(matchResultProvider(match.id));
    final repo = ref.read(matchesRepositoryProvider);
    final open = match.status == MatchStatus.votingOpen;
    final closed = match.status == MatchStatus.votingClosed;
    final present = match.presentPlayerIds.toSet().toList();
    final candidates = present
        .where((uid) => match.allowSelfVote || uid != _voter)
        .toList();
    Widget choice(
      String label,
      String? value,
      List<String> ids,
      ValueChanged<String?> onChanged,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label:$value:${ids.join(',')}'),
        initialValue: ids.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: ids
            .map(
              (uid) => DropdownMenuItem(
                value: uid,
                child: Text(name(uid), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _busy || !open ? null : onChanged,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Match de test')),
      body: ResponsiveContent(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(match.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Simulation réservée aux admins. Les notifications restent entre admins et les résultats ne comptent pas pour le club.',
            ),
            const SizedBox(height: 16),
            if (!open)
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => repo.openVoting(match.id),
                        'Vote de test ouvert.',
                      ),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  closed ? 'Rouvrir le vote de test' : 'Ouvrir le vote de test',
                ),
              ),
            if (open)
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await repo.closeVoting(match.id);
                        await repo.recomputeResults(match.id);
                      }, 'Vote de test clôturé et résultats calculés.'),
                icon: const Icon(Icons.stop),
                label: const Text('Clôturer et calculer les résultats'),
              ),
            const SizedBox(height: 24),
            Text(
              'Choisir le vote d’un joueur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            choice(
              'Joueur qui vote',
              _voter,
              present,
              (uid) => _selectVoter(uid, votes),
            ),
            choice(
              '1er choix',
              _first,
              candidates,
              (uid) => setState(() => _first = uid),
            ),
            choice(
              '2e choix',
              _second,
              candidates,
              (uid) => setState(() => _second = uid),
            ),
            choice(
              '3e choix',
              _third,
              candidates,
              (uid) => setState(() => _third = uid),
            ),
            FilledButton(
              onPressed: _busy || !open
                  ? null
                  : () {
                      final selected = [_first, _second, _third];
                      if (!present.contains(_voter) ||
                          selected.any((uid) => !candidates.contains(uid)) ||
                          selected.toSet().length != 3) {
                        setState(() {
                          _failed = true;
                          _message =
                              'Choisis un votant et trois candidats différents, en respectant le vote pour soi-même.';
                        });
                        return;
                      }
                      _run(
                        () => repo.saveTestVote(
                          match.id,
                          voterUid: _voter!,
                          firstPlaceUid: _first!,
                          secondPlaceUid: _second!,
                          thirdPlaceUid: _third!,
                        ),
                        'Bulletin de test enregistré.',
                      );
                    },
              child: Text(
                _busy ? 'En cours…' : 'Enregistrer le bulletin de test',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un nouvel enregistrement remplace le bulletin de ce votant pour ce test uniquement.',
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _failed ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Bulletins simulés (${votes.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (votesAsync.isLoading) const LinearProgressIndicator(),
            if (votesAsync.hasError)
              const Text('Impossible de charger les bulletins.'),
            for (final vote in votes)
              ListTile(
                title: Text(name(vote['voterUid'] as String)),
                subtitle: Text(
                  '1. ${name(vote['firstPlaceUid'] as String)} · 2. ${name(vote['secondPlaceUid'] as String)} · 3. ${name(vote['thirdPlaceUid'] as String)}',
                ),
                onTap: _busy || !open
                    ? null
                    : () => _selectVoter(vote['voterUid'] as String, votes),
              ),
            if (closed) ...[
              const Divider(),
              Text(
                'Résultats du test',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              result.when(
                data: (summary) {
                  if (summary == null) return const Text('Calcul en cours…');
                  final entries =
                      (summary['entries'] as Map<String, dynamic>? ?? {})
                          .entries
                          .toList()
                        ..sort(
                          (a, b) => (b.value['points'] as num).compareTo(
                            a.value['points'] as num,
                          ),
                        );
                  return Column(
                    children: [
                      Text('${summary['totalVotes'] ?? 0} bulletin(s)'),
                      for (final entry in entries)
                        ListTile(
                          title: Text(name(entry.key)),
                          trailing: Text('${entry.value['points']} pts'),
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur : $e'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
