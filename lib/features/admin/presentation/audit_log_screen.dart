import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

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
                  stream: ref
                      .watch(appDatabaseProvider)
                      .collection('audit_logs')
                      .orderBy('at', descending: true)
                      .limit(_limit)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Journal indisponible : ${snapshot.error}'),
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
                              ].any(
                                (k) => '${d.data()[k] ?? ''}'
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
  Widget _entry(Map<String, dynamic> data) {
    final at = data['at'];
    final time = at is Timestamp
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(at.toDate().toLocal())
        : 'Date inconnue';
    final status = switch (data['status']) {
      'success' => 'Réussie',
      'failed' => 'Échec (effets partiels possibles)',
      _ => 'En cours / résultat inconnu',
    };
    final name = (data['actorName'] as String?)?.trim();
    String pretty(Object? value) =>
        const JsonEncoder.withIndent('  ').convert(value);
    Object? readable(Object? value) {
      if (value is Timestamp) return value.toDate().toLocal().toIso8601String();
      if (value is Map) return value.map((k, v) => MapEntry(k, readable(v)));
      if (value is List) return value.map(readable).toList();
      return value;
    }

    return ExpansionTile(
      title: Text('${data['action']} · ${data['target']}'),
      subtitle: Text(
        '$time · ${name?.isNotEmpty == true ? name : data['actorUid']} · $status'
        '${data['reviewSpaceUid'] != null || data['actorRole'] == 'reviewer' ? ' · Équipe de validation' : ''}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'Auteur : ${data['actorUid']}\nSource : ${data['source']}\n'
            '${data.containsKey('before') ? 'Avant :\n${pretty(readable(data['before']))}\nAprès :\n${pretty(readable(data['after']))}' : 'Action serveur - aucun contenu sensible conservé.'}',
          ),
        ),
      ],
    );
  }
}
