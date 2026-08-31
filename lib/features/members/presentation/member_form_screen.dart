import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';

/// [existing] null = création (envoie une invitation par e-mail via Cloud
/// Function), sinon édition d'un profil déjà existant (mise à jour directe
/// Firestore, pas besoin de Cloud Function pour ces champs-là).
class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({super.key, this.existing});
  final UserModel? existing;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(
    text: widget.existing?.firstName,
  );
  late final _lastName = TextEditingController(text: widget.existing?.lastName);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _jerseyNumber = TextEditingController(
    text: widget.existing?.jerseyNumber?.toString(),
  );
  String? _selectedTeam;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.existing?.team;
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le membre' : 'Nouveau membre'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled:
                  !_isEditing, // l'e-mail est lié au compte Auth, non modifiable ici
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: _required,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            teamsAsync.when(
              data: (teams) => DropdownButtonFormField<String>(
                initialValue: teams.any((t) => t.name == _selectedTeam)
                    ? _selectedTeam
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Équipe',
                  border: OutlineInputBorder(),
                ),
                items: teams
                    .map(
                      (t) =>
                          DropdownMenuItem(value: t.name, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeam = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur chargement des équipes : $e'),
            ),
            if (teamsAsync.value?.isEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Aucune équipe créée pour l'instant — crée-en une depuis Administration > Équipes.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jerseyNumber,
              decoration: const InputDecoration(
                labelText: 'Numéro de maillot (optionnel)',
              ),
              keyboardType: TextInputType.number,
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
                  : Text(_isEditing ? 'Enregistrer' : "Envoyer l'invitation"),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 8),
              Text(
                "Un e-mail sera envoyé au membre pour qu'il définisse son mot de passe.",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Champ requis' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(membersRepositoryProvider);
    final jerseyNumber = int.tryParse(_jerseyNumber.text.trim());

    try {
      if (_isEditing) {
        await repo.updateProfile(widget.existing!.uid, {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'team': _selectedTeam,
          'jerseyNumber': jerseyNumber,
        });
      } else {
        await repo.inviteMember(
          email: _email.text.trim(),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          team: _selectedTeam!,
          jerseyNumber: jerseyNumber,
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
