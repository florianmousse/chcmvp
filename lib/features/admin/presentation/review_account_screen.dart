import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

class ReviewAccountScreen extends ConsumerStatefulWidget {
  const ReviewAccountScreen({super.key});
  @override
  ConsumerState<ReviewAccountScreen> createState() =>
      _ReviewAccountScreenState();
}

class _ReviewAccountScreenState extends ConsumerState<ReviewAccountScreen> {
  final _email = TextEditingController(
    text: 'chcmvp.chateaubourghockeyclub@gmail.com',
  );
  bool _busy = false;
  Map<String, dynamic>? _credentials;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Compte de validation')),
    body: ref.watch(accountProfileProvider).value?.isAdmin != true
        ? const Center(child: Text('Accès réservé aux administrateurs.'))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Ce compte utilise toute l’application dans son propre espace de démonstration : matchs, cérémonies, votes, membres, équipes, classements et badges. Les notifications sont coupées et les invitations sont simulées. Aucun compte membre réel n’est créé.',
              ),
              const SizedBox(height: 16),
              if (_credentials == null) ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                  ),
                  enabled: !_busy,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _create,
                  child: Text(
                    _busy ? 'Création…' : 'Créer le compte de validation',
                  ),
                ),
              ] else ...[
                const Text(
                  'Compte créé. Conserve ces identifiants pour la rubrique « Accès à l’application » de Google Play Console. '
                  'Le mot de passe ne sera plus affiché après avoir quitté cet écran.',
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'E-mail : ${_credentials!['email']}\nMot de passe : ${_credentials!['password']}',
                ),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
  );
  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(serverClientProvider).post(
        '/members/review-account',
        {'email': _email.text},
      );
      if (mounted) setState(() => _credentials = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
