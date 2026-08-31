import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/voting/domain/vote_model.dart';
import 'package:chc_mvp/features/voting/presentation/voting_controller.dart';

/// Écran de vote pour un match donné. Le contrôleur (Riverpod) gère l'appel
/// Firestore et propage les VoteValidationException sous forme de message.
class VoteScreen extends ConsumerStatefulWidget {
  const VoteScreen({super.key, required this.match, required this.candidates});

  final MatchModel match;
  final List<UserModel> candidates;

  @override
  ConsumerState<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends ConsumerState<VoteScreen> {
  String? _first;
  String? _second;
  String? _third;

  bool get _canSubmit => _first != null && _second != null && _third != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitting = ref.watch(voteSubmissionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Vote — ${widget.match.label}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sélectionne tes 3 meilleurs joueurs du match',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _rankSelector('🥇 Meilleur joueur', _first, (uid) {
            setState(() => _first = uid);
          }),
          const SizedBox(height: 12),
          _rankSelector('🥈 Deuxième meilleur joueur', _second, (uid) {
            setState(() => _second = uid);
          }),
          const SizedBox(height: 12),
          _rankSelector('🥉 Troisième meilleur joueur', _third, (uid) {
            setState(() => _third = uid);
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: !_canSubmit || submitting ? null : _submit,
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Valider mon vote'),
          ),
        ],
      ),
    );
  }

  Widget _rankSelector(
    String label,
    String? selectedUid,
    ValueChanged<String> onSelect,
  ) {
    // Un joueur déjà choisi à un autre rang est grisé pour empêcher
    // visuellement le doublon (la validation métier le bloque de toute façon).
    final takenElsewhere = {_first, _second, _third}
      ..remove(selectedUid)
      ..removeWhere((e) => e == null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedUid,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.candidates
                  .where(
                    (c) => widget.match.allowSelfVote || c.uid != _currentUid,
                  )
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.uid,
                      enabled: !takenElsewhere.contains(c.uid),
                      child: Text(
                        '${c.fullName}${c.jerseyNumber != null ? " (#${c.jerseyNumber})" : ""}',
                        style: TextStyle(
                          color: takenElsewhere.contains(c.uid)
                              ? Theme.of(context).disabledColor
                              : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (uid) {
                if (uid != null) onSelect(uid);
              },
            ),
          ],
        ),
      ),
    );
  }

  String? get _currentUid => ref.read(firebaseAuthProvider).currentUser?.uid;

  Future<void> _submit() async {
    try {
      VoteValidator.validate(
        voterUid: _currentUid ?? '',
        firstPlaceUid: _first!,
        secondPlaceUid: _second!,
        thirdPlaceUid: _third!,
        allowSelfVote: widget.match.allowSelfVote,
      );
      await ref
          .read(voteSubmissionControllerProvider.notifier)
          .submit(
            matchId: widget.match.id,
            firstPlaceUid: _first!,
            secondPlaceUid: _second!,
            thirdPlaceUid: _third!,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote enregistré, merci !')),
        );
        Navigator.of(context).pop();
      }
    } on VoteValidationException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}
