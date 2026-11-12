import 'audit_entry_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

// Keep the subscription stable while typing a filter. A scope or page-size
// change still creates a new, correctly scoped query.
final auditLogsStreamProvider = Provider.autoDispose
    .family<Stream<QuerySnapshot<Map<String, dynamic>>>, int>((ref, limit) {
      return ref
          .watch(appDatabaseProvider)
          .collection('audit_logs')
          .orderBy('at', descending: true)
          .limit(limit)
          .snapshots();
    });

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  int _limit = 100;
  String _filter = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Journal des actions')),
    body: !ref.watch(isAdminProvider)
        ? const Center(child: Text('Accès réservé aux administrateurs.'))
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText:
                        'Filtrer les entrées chargées : auteur, objet, action',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Heures locales. « En cours / résultat inconnu » peut indiquer une interruption du serveur. '
                  'Les choix des votes, mots de passe et jetons ne sont jamais affichés.',
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: ref.watch(auditLogsStreamProvider(_limit)),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Journal indisponible. Vérifie ta connexion puis réessaie.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs
                        .where(
                          (d) =>
                              [
                                'actorUid',
                                'actorName',
                                'actorRole',
                                'target',
                                'action',
                                auditActionLabel(d.data()),
                                auditSubjectLabel(d.data()),
                              ].any(
                                (k) => '${d.data()[k] ?? k}'
                                    .toLowerCase()
                                    .contains(_filter),
                              ),
                        )
                        .toList();
                    return ListView(
                      children: [
                        if (docs.isEmpty)
                          const ListTile(
                            title: Text('Aucune action correspondante.'),
                          ),
                        for (final doc in docs) _entry(doc.data()),
                        if (snapshot.data!.docs.length == _limit)
                          TextButton(
                            onPressed: () => setState(() => _limit += 100),
                            child: const Text(
                              'Charger 100 actions supplémentaires',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
  );
  Widget _entry(Map<String, dynamic> data) => AuditEntryCard(data: data);
}
