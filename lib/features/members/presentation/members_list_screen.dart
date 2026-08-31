import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/members/presentation/member_form_screen.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersListProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MemberFormScreen())),
      ),
      body: membersAsync.when(
        data: (members) {
          // Admins en premier, puis ordre alphabétique dans chaque groupe —
          // tri côté app pour ne pas dépendre d'un index composite Firestore.
          final sorted = [...members]
            ..sort((a, b) {
              if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
              return a.lastName.compareTo(b.lastName);
            });

          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _MemberTile(member: sorted[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});
  final UserModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(membersRepositoryProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        child: member.photoUrl == null
            ? Text(member.firstName.isNotEmpty ? member.firstName[0] : '?')
            : null,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(member.fullName, overflow: TextOverflow.ellipsis),
          ),
          if (member.isAdmin) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.shield,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${member.team}'
        '${member.jerseyNumber != null ? " · #${member.jerseyNumber}" : ""}'
        '${!member.isActive ? " · désactivé" : ""}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          switch (action) {
            case 'toggle_active':
              await repo.setActive(member.uid, !member.isActive);
            case 'toggle_admin':
              await repo.setRole(
                member.uid,
                member.isAdmin ? UserRole.member : UserRole.admin,
              );
            case 'edit':
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemberFormScreen(existing: member),
                  ),
                );
              }
            case 'delete':
              final confirmed = await _confirmDelete(context, member);
              if (confirmed) await repo.deleteMember(member.uid);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
          PopupMenuItem(
            value: 'toggle_active',
            child: Text(member.isActive ? 'Désactiver' : 'Réactiver'),
          ),
          PopupMenuItem(
            value: 'toggle_admin',
            child: Text(
              member.isAdmin
                  ? "Retirer le rôle admin"
                  : 'Promouvoir administrateur',
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, UserModel member) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text(
          '${member.fullName} perdra définitivement son compte et son historique de vote sera anonymisé. Cette action est irréversible.',
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
