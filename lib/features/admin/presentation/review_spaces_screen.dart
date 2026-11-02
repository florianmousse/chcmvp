import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

class ReviewSpacesScreen extends ConsumerWidget {
  const ReviewSpacesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Espaces de validation')),
    body: ref.watch(accountProfileProvider).value?.isAdmin != true
        ? const Center(child: Text('Accès réservé aux admins du club.'))
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ref
                .watch(firestoreProvider)
                .collection('users')
                .where('role', isEqualTo: 'reviewer')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Aucun compte de validation.'));
              }
              return ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Ouvre un espace pour consulter ou modifier ses données de démonstration. Les données du club restent séparées.',
                    ),
                  ),
                  for (final doc in snapshot.data!.docs)
                    ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(
                        '${doc.data()['firstName']} ${doc.data()['lastName']}',
                      ),
                      subtitle: Text(
                        '${doc.data()['email']} · Équipe de validation',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pop();
                        ref.read(inspectedReviewSpaceProvider.notifier).state =
                            doc.id;
                      },
                    ),
                ],
              );
            },
          ),
  );
}
