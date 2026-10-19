import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/features/opponents/presentation/quick_add_opponent_dialog.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/opponents/presentation/opponents_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';
import 'package:intl/intl.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({super.key, this.existing});
  final MatchModel? existing;

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date = widget.existing?.date ?? _nextSunday();
  late TimeOfDay _time =
      _parseTime(widget.existing?.time) ?? const TimeOfDay(hour: 9, minute: 0);
  String? _selectedTeam;
  String? _selectedOpponentId;
  OpponentModel? _newOpponent;
  late bool _isHome = widget.existing?.isHome ?? true;
  late bool _allowSelfVote = widget.existing?.allowSelfVote ?? false;
  final Set<String> _presentPlayerIds = {};
  String? _selectedLogoAsset;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _presentPlayerIds.addAll(widget.existing?.presentPlayerIds ?? []);
    _selectedTeam = widget.existing?.team;
    _selectedLogoAsset = widget.existing?.opponentLogoAsset;
    _selectedOpponentId = widget.existing?.opponentId;
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String get _formattedTime =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersListProvider(null));
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le match' : 'Nouveau match'),
      ),
      body: ResponsiveContent(
        maxWidth: 900,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Heure'),
                subtitle: Text(_formattedTime),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),
              // ── Adversaire (dropdown depuis Firestore) ──
              ref
                  .watch(opponentsListProvider)
                  .when(
                    data: (loadedOpponents) {
                      final opponents = [...loadedOpponents];
                      final added = _newOpponent;
                      if (added != null &&
                          !opponents.any((o) => o.id == added.id)) {
                        opponents.add(added);
                      }
                      // Vérifie que l'id sélectionné existe toujours
                      final validId =
                          opponents.any((o) => o.id == _selectedOpponentId)
                          ? _selectedOpponentId
                          : null;
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(validId),
                              initialValue: validId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Adversaire',
                                border: OutlineInputBorder(),
                              ),
                              items: opponents
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o.id,
                                      child: Row(
                                        children: [
                                          if (o.logoAsset != null) ...[
                                            Image.asset(
                                              o.logoAsset!,
                                              width: 24,
                                              height: 24,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox(width: 24),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Text(
                                              o.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                setState(() {
                                  _selectedOpponentId = id;
                                  // Auto-set logo de l'adversaire
                                  final opp = opponents.firstWhere(
                                    (o) => o.id == id,
                                  );
                                  _selectedLogoAsset = opp.logoAsset;
                                });
                              },
                              validator: (v) =>
                                  v == null ? 'Champ requis' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add),
                            tooltip: 'Ajouter un adversaire',
                            onPressed: () async {
                              final opponent = await showDialog<OpponentModel>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const QuickAddOpponentDialog(),
                              );
                              if (opponent != null && mounted) {
                                setState(() {
                                  _newOpponent = opponent;
                                  _selectedOpponentId = opponent.id;
                                  _selectedLogoAsset = opponent.logoAsset;
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur chargement adversaires : $e'),
                  ),
              const SizedBox(height: 16),
              teamsAsync.when(
                data: (teams) => DropdownButtonFormField<String>(
                  initialValue: teams.any((t) => t.name == _selectedTeam)
                      ? _selectedTeam
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Équipe concernée',
                    border: OutlineInputBorder(),
                  ),
                  items: teams
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.name,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedTeam = v;
                    _presentPlayerIds.clear();
                  }),
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur chargement des équipes : $e'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Match à domicile'),
                value: _isHome,
                onChanged: (v) => setState(() => _isHome = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Autoriser le vote pour soi-même'),
                value: _allowSelfVote,
                onChanged: (v) => setState(() => _allowSelfVote = v),
              ),
              const SizedBox(height: 12),
              Text(
                'Joueurs présents',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_selectedTeam == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Choisis une équipe pour voir ses joueurs.'),
                )
              else
                membersAsync.when(
                  data: (members) {
                    final teamMembers = members
                        .where((m) => m.isActive && m.team == _selectedTeam)
                        .toList();
                    if (teamMembers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Aucun membre actif dans "$_selectedTeam".',
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      children: teamMembers
                          .map(
                            (m) => FilterChip(
                              label: Text(m.fullName),
                              selected: _presentPlayerIds.contains(m.uid),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _presentPlayerIds.add(m.uid);
                                } else {
                                  _presentPlayerIds.remove(m.uid);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Erreur chargement membres : $e'),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Enregistrer' : 'Créer le match'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _nextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_presentPlayerIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne au moins 3 joueurs présents.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(matchesRepositoryProvider);

    // Résoudre le nom de l'adversaire depuis l'ID
    final opponents = ref.read(opponentsListProvider).value ?? [];
    final selectedOpp =
        opponents.where((o) => o.id == _selectedOpponentId).firstOrNull ??
        (_newOpponent?.id == _selectedOpponentId ? _newOpponent : null);
    final opponentName = selectedOpp?.name ?? '';

    try {
      if (_isEditing) {
        await repo.updateMatch(widget.existing!.id, {
          'date': Timestamp.fromDate(_date),
          'time': _formattedTime,
          'opponent': opponentName,
          'opponentId': _selectedOpponentId,
          'isHome': _isHome,
          'team': _selectedTeam,
          'presentPlayerIds': _presentPlayerIds.toList(),
          'allowSelfVote': _allowSelfVote,
          'opponentLogoAsset': _selectedLogoAsset,
        });
      } else {
        await repo.createMatch(
          date: _date,
          time: _formattedTime,
          opponent: opponentName,
          opponentId: _selectedOpponentId,
          isHome: _isHome,
          team: _selectedTeam!,
          presentPlayerIds: _presentPlayerIds.toList(),
          pointsScale: const PointsScale(),
          allowSelfVote: _allowSelfVote,
          opponentLogoAsset: _selectedLogoAsset,
        );
      }
      if (mounted) Navigator.of(context).pop();
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
