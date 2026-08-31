import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/config/team_logos_catalog.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
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
  late final _opponent = TextEditingController(text: widget.existing?.opponent);
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late TimeOfDay _time =
      _parseTime(widget.existing?.time) ?? const TimeOfDay(hour: 15, minute: 0);
  String? _selectedTeam;
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
      body: Form(
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
            TextFormField(
              controller: _opponent,
              decoration: const InputDecoration(labelText: 'Adversaire'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            Text(
              'Logo de l\'adversaire (optionnel)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _LogoPicker(
              selected: _selectedLogoAsset,
              onSelected: (path) => setState(() => _selectedLogoAsset = path),
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
                      (t) =>
                          DropdownMenuItem(value: t.name, child: Text(t.name)),
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
                      child: Text('Aucun membre actif dans "$_selectedTeam".'),
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
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Champ requis' : null;

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

    try {
      if (_isEditing) {
        await repo.updateMatch(widget.existing!.id, {
          'date': Timestamp.fromDate(_date),
          'time': _formattedTime,
          'opponent': _opponent.text.trim(),
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
          opponent: _opponent.text.trim(),
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

/// Rangée horizontale de vignettes sélectionnables — "Aucun" en premier,
/// puis chaque logo du catalogue (core/config/team_logos_catalog.dart).
class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (teamLogosCatalog.isEmpty) {
      return Text(
        'Aucun logo disponible pour l\'instant — ajoute-en dans '
        'lib/core/config/team_logos_catalog.dart.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _LogoOption(
            label: 'Aucun',
            selected: selected == null,
            onTap: () => onSelected(null),
            child: const Icon(Icons.block),
          ),
          for (final option in teamLogosCatalog)
            _LogoOption(
              label: option.name,
              selected: selected == option.assetPath,
              onTap: () => onSelected(option.assetPath),
              child: Image.asset(option.assetPath, fit: BoxFit.contain),
            ),
        ],
      ),
    );
  }
}

class _LogoOption extends StatelessWidget {
  const _LogoOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                height: 52,
                width: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: child,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
