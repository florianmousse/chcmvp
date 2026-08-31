import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/team_model.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';

class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Équipes')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle équipe'),
        onPressed: () => _showTeamDialog(context, ref),
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(child: Text("Aucune équipe pour l'instant."));
          }
          return ListView.separated(
            itemCount: teams.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final team = teams[i];
              return ListTile(
                title: Text(team.name),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    final repo = ref.read(teamsRepositoryProvider);
                    if (action == 'rename') {
                      await _showTeamDialog(context, ref, existing: team);
                    } else if (action == 'delete') {
                      final confirmed = await _confirmDelete(context, team);
                      if (confirmed) await repo.deleteTeam(team.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Renommer'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  Future<void> _showTeamDialog(
    BuildContext context,
    WidgetRef ref, {
    TeamModel? existing,
  }) async {
    final controller = TextEditingController(text: existing?.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existing == null ? 'Nouvelle équipe' : 'Renommer l\'équipe',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de l\'équipe'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;
    final repo = ref.read(teamsRepositoryProvider);
    if (existing == null) {
      await repo.createTeam(controller.text.trim());
    } else {
      await repo.renameTeam(existing.id, controller.text.trim());
    }
  }

  Future<bool> _confirmDelete(BuildContext context, TeamModel team) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette équipe ?'),
        content: Text(
          'Les membres et matchs déjà associés à "${team.name}" garderont ce nom '
          "jusqu'à modification manuelle — rien n'est supprimé en cascade.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
