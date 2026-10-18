import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/player_match_stats_model.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';

/// Écran admin pour saisir le score du match et les stats individuelles
/// (buts, passes décisives, cartons) de chaque joueur présent.
class MatchStatsFormScreen extends ConsumerStatefulWidget {
  const MatchStatsFormScreen({super.key, required this.match});
  final MatchModel match;

  @override
  ConsumerState<MatchStatsFormScreen> createState() =>
      _MatchStatsFormScreenState();
}

class _MatchStatsFormScreenState extends ConsumerState<MatchStatsFormScreen> {
  late final _scoreHomeCtrl = TextEditingController(
    text: widget.match.scoreHome?.toString() ?? '',
  );
  late final _scoreAwayCtrl = TextEditingController(
    text: widget.match.scoreAway?.toString() ?? '',
  );
  final Map<String, _PlayerStatsData> _stats = {};
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _scoreHomeCtrl.dispose();
    _scoreAwayCtrl.dispose();
    super.dispose();
  }

  void _initFromFirestore(List<PlayerMatchStats> existing) {
    if (_initialized) return;
    _initialized = true;
    for (final s in existing) {
      _stats[s.playerId] = _PlayerStatsData()
        ..goals = s.goals
        ..assists = s.assists
        ..greenCards = s.greenCards
        ..yellowCards = s.yellowCards
        ..redCards = s.redCards;
    }
    // Assurer une entrée pour chaque joueur présent
    for (final uid in widget.match.presentPlayerIds) {
      _stats.putIfAbsent(uid, _PlayerStatsData.new);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersListProvider(null));
    final existingStatsAsync = ref.watch(
      playerMatchStatsProvider(widget.match.id),
    );

    // Initialiser depuis Firestore au premier chargement
    existingStatsAsync.whenData(_initFromFirestore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats du match'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1000,
        child: membersAsync.when(
          data: (members) {
            final nameOf = <String, String>{
              for (final m in members) m.uid: m.fullName,
            };

            // Assurer une entrée pour chaque joueur présent
            for (final uid in widget.match.presentPlayerIds) {
              _stats.putIfAbsent(uid, _PlayerStatsData.new);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Score du match ───
                Text(
                  'Score du match',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scoreHomeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'CHC',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('—', style: TextStyle(fontSize: 24)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _scoreAwayCtrl,
                        decoration: InputDecoration(
                          labelText: widget.match.opponent,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                // ─── Stats par joueur ───
                Text(
                  'Stats individuelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.match.presentPlayerIds.map((uid) {
                  final data = _stats.putIfAbsent(uid, _PlayerStatsData.new);
                  return _PlayerStatsRow(
                    playerName: nameOf[uid] ?? 'Joueur inconnu',
                    data: data,
                    onChanged: () => setState(() {}),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(matchesRepositoryProvider);

    try {
      // Sauvegarder le score
      final home = int.tryParse(_scoreHomeCtrl.text.trim());
      final away = int.tryParse(_scoreAwayCtrl.text.trim());
      if (home != null && away != null) {
        await repo.updateMatchScore(
          widget.match.id,
          scoreHome: home,
          scoreAway: away,
        );
      }

      // Sauvegarder les stats en batch
      final statsList = _stats.entries.map((e) {
        return PlayerMatchStats(
          playerId: e.key,
          goals: e.value.goals,
          assists: e.value.assists,
          greenCards: e.value.greenCards,
          yellowCards: e.value.yellowCards,
          redCards: e.value.redCards,
        );
      }).toList();

      await repo.saveAllPlayerMatchStats(widget.match.id, statsList);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stats enregistrées !')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PlayerStatsData {
  int goals = 0;
  int assists = 0;
  int greenCards = 0;
  int yellowCards = 0;
  int redCards = 0;
}

class _PlayerStatsRow extends StatelessWidget {
  const _PlayerStatsRow({
    required this.playerName,
    required this.data,
    required this.onChanged,
  });
  final String playerName;
  final _PlayerStatsData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatCounter(
                  icon: '⚽',
                  label: 'Buts',
                  value: data.goals,
                  onChanged: (v) {
                    data.goals = v;
                    onChanged();
                  },
                ),
                _StatCounter(
                  icon: '🅰️',
                  label: 'Passes D.',
                  value: data.assists,
                  onChanged: (v) {
                    data.assists = v;
                    onChanged();
                  },
                ),
                _StatCounter(
                  icon: '🟢',
                  label: 'Vert',
                  value: data.greenCards,
                  onChanged: (v) {
                    data.greenCards = v;
                    onChanged();
                  },
                ),
                _StatCounter(
                  icon: '🟡',
                  label: 'Jaune',
                  value: data.yellowCards,
                  onChanged: (v) {
                    data.yellowCards = v;
                    onChanged();
                  },
                ),
                _StatCounter(
                  icon: '🔴',
                  label: 'Rouge',
                  value: data.redCards,
                  onChanged: (v) {
                    data.redCards = v;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compteur +/- compact pour une stat.
class _StatCounter extends StatelessWidget {
  const _StatCounter({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          InkWell(
            onTap: value > 0 ? () => onChanged(value - 1) : null,
            child: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: value > 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: () => onChanged(value + 1),
            child: Icon(
              Icons.add_circle_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
