import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'ceremony_model.dart';
import 'ceremonies_screen.dart';

class CeremonyForm extends ConsumerStatefulWidget {
  const CeremonyForm({super.key, this.ceremony});
  final Ceremony? ceremony;
  @override
  ConsumerState<CeremonyForm> createState() => _CeremonyFormState();
}

class _CeremonyFormState extends ConsumerState<CeremonyForm> {
  final _title = TextEditingController();
  String _category = 'ballon_or';
  int _top = 5;
  bool _self = false, _busy = false, _initialized = false;
  final _nominees = <Map<String, dynamic>>[];
  final _voters = <String>{};
  @override
  void initState() {
    super.initState();
    final event = widget.ceremony;
    if (event != null) {
      _title.text = event.title;
      _category = event.category;
      _top = event.topSize;
      _self = event.allowSelfVote;
      _voters.addAll(event.voterIds);
      _nominees.addAll(
        event.nominees.map(
          (n) => {
            'uid': n.uid,
            'name': n.name,
            'label': n.label,
            'videoUrl': n.videoId ?? '',
          },
        ),
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _nominate(List<UserModel> members, [int? index]) async {
    final value = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _NominationDialog(
        members: members,
        playerAward: ['ballon_or', 'golden_boy'].contains(_category),
        initial: index == null ? null : _nominees[index],
      ),
    );
    if (value != null && mounted) {
      setState(() {
        if (index == null) {
          _nominees.add(value);
        } else {
          _nominees[index] = value;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty ||
        _nominees.map((n) => n['uid']).toSet().length < _top ||
        _voters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Renseigne un titre, assez de joueurs différents et au moins un votant.',
          ),
        ),
      );
      return;
    }
    final event = widget.ceremony;
    if (event != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modifier la cérémonie ?'),
          content: const Text(
            'Enregistrer ces modifications remet tous les votes à zéro et retire les résultats et trophées. La cérémonie repasse en brouillon : il faudra ouvrir le vote et chacun devra voter à nouveau.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Modifier et remettre à zéro'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final response = await ref.read(serverClientProvider).post(
        event == null ? '/ceremonies' : '/ceremonies/${event.id}/update',
        {
          'title': _title.text.trim(),
          'category': _category,
          'topSize': _top,
          'allowSelfVote': _self,
          'nominees': _nominees,
          'voterIds': _voters.toList(),
          if (event != null) 'expectedRevision': event.revision,
          if (event != null) 'resetVotes': true,
        },
      );
      if (mounted) {
        if (event != null) {
          Navigator.pop(context);
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CeremonyDetailScreen(id: response['id'] as String),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.ceremony == null
            ? 'Créer une cérémonie'
            : 'Modifier la cérémonie',
      ),
    ),
    body: !ref.watch(isAdminProvider)
        ? const Center(child: Text('Réservé aux admins.'))
        : ResponsiveContent(
            maxWidth: 900,
            child: ref
                .watch(membersListProvider(null))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (all) {
                    final members = all.where((m) => m.isActive).toList()
                      ..sort((a, b) => a.fullName.compareTo(b.fullName));
                    final voters = members.where((m) => m.hasAccount).toList();
                    if (!_initialized) {
                      _voters.addAll(voters.map((m) => m.uid));
                      _initialized = true;
                    }
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Prépare le prix, puis ouvre le vote depuis sa fiche. Pour plusieurs prix lors d’une soirée, crée une cérémonie par prix avec le même nom d’édition.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _title,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText:
                                'Titre et édition (ex. Ballon d’or 2026)',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                          ),
                          items: ceremonyCategories.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                        DropdownButtonFormField<int>(
                          initialValue: _top,
                          decoration: const InputDecoration(
                            labelText: 'Taille du classement à voter',
                          ),
                          items: List.generate(
                            10,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('Top ${i + 1}'),
                            ),
                          ),
                          onChanged: (v) => setState(() => _top = v!),
                        ),
                        SwitchListTile(
                          title: const Text('Autoriser le vote pour soi-même'),
                          value: _self,
                          onChanged: (v) => setState(() => _self = v),
                        ),
                        const Text(
                          'Le barème attribue N points au premier choix, puis N−1, jusqu’à 1. Le trophée revient au lauréat ; les égalités parfaites sont partagées. Golden Boy : sélectionne toi-même les joueurs éligibles.',
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nominations (${_nominees.length}/50)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Les joueurs sans compte peuvent être nommés. Pour un but ou une passe, ajoute un lien YouTube public ou non répertorié autorisant l’intégration. Plusieurs actions d’un joueur peuvent être nommées.',
                        ),
                        for (var i = 0; i < _nominees.length; i++)
                          ListTile(
                            title: Text(_nominees[i]['name']),
                            subtitle:
                                ['ballon_or', 'golden_boy'].contains(_category)
                                ? null
                                : Text(_nominees[i]['label']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Modifier la nomination',
                                  onPressed: _busy
                                      ? null
                                      : () => _nominate(members, i),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Retirer la nomination',
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                          () => _nominees.removeAt(i),
                                        ),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed:
                              _busy || members.isEmpty || _nominees.length >= 50
                              ? null
                              : () => _nominate(members),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une nomination'),
                        ),
                        const SizedBox(height: 20),
                        ExpansionTile(
                          title: Text(
                            'Votants (${_voters.length}/${voters.length})',
                          ),
                          children: [
                            Wrap(
                              children: [
                                TextButton(
                                  onPressed: () => setState(() {
                                    _voters.clear();
                                    _voters.addAll(voters.map((m) => m.uid));
                                  }),
                                  child: const Text('Tous'),
                                ),
                                TextButton(
                                  onPressed: () => setState(_voters.clear),
                                  child: const Text('Aucun'),
                                ),
                              ],
                            ),
                            for (final m in voters)
                              CheckboxListTile(
                                title: Text(m.fullName),
                                value: _voters.contains(m.uid),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _voters.add(m.uid);
                                  } else {
                                    _voters.remove(m.uid);
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _save,
                          child: Text(
                            _busy
                                ? 'Enregistrement…'
                                : widget.ceremony == null
                                ? 'Créer le brouillon'
                                : 'Enregistrer les modifications',
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
  );
}

class _NominationDialog extends StatefulWidget {
  const _NominationDialog({
    required this.members,
    required this.playerAward,
    this.initial,
  });
  final List<UserModel> members;
  final bool playerAward;
  final Map<String, dynamic>? initial;
  @override
  State<_NominationDialog> createState() => _NominationDialogState();
}

class _NominationDialogState extends State<_NominationDialog> {
  String? _uid;
  final _label = TextEditingController(), _video = TextEditingController();
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _uid = widget.members.any((m) => m.uid == initial['uid'])
          ? initial['uid'] as String
          : null;
      _label.text = initial['label'] as String;
      _video.text = initial['videoUrl'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initial == null ? 'Nouvelle nomination' : 'Modifier la nomination',
    ),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _uid,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Joueur'),
              items: widget.members
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.uid,
                      child: Text(m.fullName, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _uid = v),
            ),
            if (!widget.playerAward)
              TextField(
                controller: _label,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nomination (ex. But contre Rennes)',
                ),
              ),
            TextField(
              controller: _video,
              decoration: const InputDecoration(
                labelText: 'Lien YouTube (facultatif)',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _uid == null
            ? null
            : () {
                final member = widget.members.firstWhere((m) => m.uid == _uid);
                Navigator.pop(context, {
                  'uid': _uid,
                  'name': member.fullName,
                  'label': widget.playerAward || _label.text.trim().isEmpty
                      ? member.fullName
                      : _label.text.trim(),
                  'videoUrl': _video.text.trim(),
                });
              },
        child: Text(widget.initial == null ? 'Ajouter' : 'Enregistrer'),
      ),
    ],
  );
}
