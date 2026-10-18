import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';

/// Sans e-mail : fiche joueur. Avec e-mail : invitation à créer son accès.
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
  bool get _canInvite => widget.existing?.hasAccount != true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _jerseyNumber.dispose();
    super.dispose();
  }

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
      body: ResponsiveContent(
        maxWidth: 720,
        child: Form(
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
                enabled: _canInvite,
                decoration: InputDecoration(
                  labelText: _canInvite ? 'E-mail (facultatif)' : 'E-mail',
                  helperText: _canInvite
                      ? 'Sans e-mail, le joueur pourra recevoir des votes.'
                      : null,
                  helperMaxLines: 2,
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  return email.isNotEmpty &&
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                      ? 'Adresse e-mail invalide'
                      : null;
                },
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
                        (t) => DropdownMenuItem(
                          value: t.name,
                          child: Text(t.name),
                        ),
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
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final number = int.tryParse(text);
                  return number == null || number < 0
                      ? 'Numéro de maillot invalide'
                      : null;
                },
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
                    : Text(
                        _canInvite && _email.text.trim().isNotEmpty
                            ? "Enregistrer et inviter"
                            : _isEditing
                            ? 'Enregistrer'
                            : 'Ajouter le joueur',
                      ),
              ),
              if (_canInvite) ...[
                const SizedBox(height: 8),
                Text(
                  _email.text.trim().isEmpty
                      ? "Tu pourras ajouter son e-mail plus tard sur cette fiche, sans perdre ses votes ni ses statistiques."
                      : "Un e-mail lui permettra de définir son mot de passe. Ses résultats seront conservés.",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Champ requis' : null;

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(membersRepositoryProvider);
    final jerseyNumber = int.tryParse(_jerseyNumber.text.trim());

    try {
      if (_isEditing) {
        final fields = <String, dynamic>{
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'team': _selectedTeam,
          'jerseyNumber': jerseyNumber,
        };
        if (_canInvite && _email.text.trim().isNotEmpty) {
          await repo.inviteExistingMember(widget.existing!.uid, {
            ...fields,
            'email': _email.text.trim(),
          });
        } else {
          await repo.updateProfile(widget.existing!.uid, fields);
        }
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
