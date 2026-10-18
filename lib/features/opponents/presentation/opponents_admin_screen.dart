import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/config/team_logos_catalog.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/core/widgets/opponent_logo.dart';
import 'package:chc_mvp/features/opponents/presentation/opponent_detail_screen.dart';
import 'package:chc_mvp/features/opponents/presentation/opponents_providers.dart';

class OpponentsAdminScreen extends ConsumerWidget {
  const OpponentsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponentsAsync = ref.watch(opponentsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adversaires')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOpponentDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: opponentsAsync.when(
        data: (opponents) {
          if (opponents.isEmpty) {
            return const Center(
              child: Text('Aucun adversaire enregistré.\nAppuyez sur + pour en ajouter.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: opponents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final opp = opponents[index];
              return ListTile(
                leading: opp.logoAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          opp.logoAsset!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const OpponentLogo(logoAssetPath: null, size: 40),
                        ),
                      )
                    : const OpponentLogo(logoAssetPath: null, size: 40),
                title: Text(opp.name),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OpponentDetailScreen(opponent: opp),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showOpponentDialog(context, ref, existing: opp);
                    } else if (action == 'delete') {
                      _confirmDelete(context, ref, opp);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
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

  void _showOpponentDialog(
    BuildContext context,
    WidgetRef ref, {
    OpponentModel? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name);
    String? selectedLogo = existing?.logoAsset;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(existing != null ? 'Modifier' : 'Nouvel adversaire'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Logo (optionnel)',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Option "pas de logo"
                          GestureDetector(
                            onTap: () => setDialogState(() => selectedLogo = null),
                            child: Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedLogo == null
                                      ? Theme.of(ctx).colorScheme.primary
                                      : Colors.grey,
                                  width: selectedLogo == null ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.block, color: Colors.grey),
                              ),
                            ),
                          ),
                          ...teamLogosCatalog
                              .where((l) => l.name != 'CHC')
                              .map(
                                (logo) => GestureDetector(
                                  onTap: () => setDialogState(
                                      () => selectedLogo = logo.assetPath),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedLogo == logo.assetPath
                                            ? Theme.of(ctx).colorScheme.primary
                                            : Colors.grey,
                                        width:
                                            selectedLogo == logo.assetPath ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Image.asset(
                                        logo.assetPath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final repo = ref.read(opponentsRepositoryProvider);
                  if (existing != null) {
                    await repo.updateOpponent(
                      id: existing.id,
                      name: name,
                      logoAsset: selectedLogo,
                    );
                  } else {
                    await repo.addOpponent(
                      name: name,
                      logoAsset: selectedLogo,
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(existing != null ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, OpponentModel opp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer l\'adversaire « ${opp.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              await ref.read(opponentsRepositoryProvider).deleteOpponent(opp.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
