import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/config/team_logos_catalog.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'opponents_providers.dart';

class QuickAddOpponentDialog extends ConsumerStatefulWidget {
  const QuickAddOpponentDialog({super.key});

  @override
  ConsumerState<QuickAddOpponentDialog> createState() =>
      _QuickAddOpponentDialogState();
}

class _QuickAddOpponentDialogState
    extends ConsumerState<QuickAddOpponentDialog> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _logo;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final name = _name.text.trim();
    try {
      final id = await ref
          .read(opponentsRepositoryProvider)
          .addOpponent(name: name, logoAsset: _logo);
      if (mounted) {
        Navigator.of(
          context,
        ).pop(OpponentModel(id: id, name: name, logoAsset: _logo));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Ajout impossible : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Nouvel adversaire'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 16),
                const Text('Logo (optionnel)'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      IconButton(
                        tooltip: 'Sans logo',
                        isSelected: _logo == null,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _logo = null),
                        icon: const Icon(Icons.block),
                      ),
                      for (final logo in teamLogosCatalog.where(
                        (l) => l.name != 'CHC',
                      ))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            tooltip: logo.name,
                            isSelected: _logo == logo.assetPath,
                            onPressed: _saving
                                ? null
                                : () => setState(() => _logo = logo.assetPath),
                            icon: Image.asset(
                              logo.assetPath,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Ajout…' : 'Ajouter'),
        ),
      ],
    ),
  );
}
